import path from "path";
import AudioJob from "../models/AudioJob.js";
import Result from "../models/Result.js";
import Song from "../models/Song.js";
import * as pythonService from "../services/pythonService.js";
import fs from "fs";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const processJobWrapper = async (req, res, processFunction) => {
  const { jobId } = req.body;

  if (!jobId) {
    return res.status(400).json({ error: "Job ID is required" });
  }

  try {
    const job = await AudioJob.findOne({
      where: { id: jobId, userId: req.user.id },
    });

    if (!job) {
      return res.status(404).json({ error: "Job not found" });
    }

    if (job.status !== "pending") {
      return res
        .status(400)
        .json({ error: "Job is already processed or processing" });
    }

    // Update status to processing
    await job.update({ status: "processing" });

    // Respond immediately so frontend doesn't wait
    res.json({ message: "Processing started", jobId: job.id });

    try {
      const absolutePath = path.resolve(job.filePath);
      console.log(`Sending absolute path to Python: ${absolutePath}`);

      // Call Python service async
      const resultData = await processFunction(absolutePath, job.id);

      // Save result
      await Result.create({
        jobId: job.id,
        resultJson: resultData.resultJson || resultData,
        fileUrls: resultData.fileUrls || (resultData.url ? [resultData.url] : []),
      });

      // Special handling for analyze: create Song entry
      if (job.type === "analyze") {
        const analyzeResult = resultData.resultJson || resultData;
        await Song.create({
          userId: job.userId,
          title: job.originalFileName,
          filePath: job.filePath,
          bpm: analyzeResult.bpm,
          key: analyzeResult.key,
          chordsJson: analyzeResult,
        });
      }

      // Update job status
      await job.update({ status: "done" });
    } catch (processError) {
      console.error(`Processing error for job ${job.id}:`, processError);
      await job.update({ status: "failed" });
    }
  } catch (error) {
    console.error("Error starting process:", error);
    if (!res.headersSent) {
      res.status(500).json({ error: "Internal server error" });
    }
  }
};

export const analyzeSong = async (req, res) => {
  await processJobWrapper(req, res, (filePath, jobId) =>
    pythonService.analyzeAudio(filePath, jobId),
  );
};

export const processAudio = async (req, res) => {
  await processJobWrapper(req, res, (filePath, jobId, body) =>
    pythonService.processAudio(filePath, body.tempo, body.pitch),
  );
};

export const processSeparate = async (req, res) => {
  await processJobWrapper(req, res, (filePath, jobId) =>
    pythonService.separateAudio(filePath, jobId),
  );
};

export const processChord = async (req, res) => {
  await processJobWrapper(req, res, (filePath, jobId) =>
    pythonService.detectChord(filePath, jobId),
  );
};

export const processBeat = async (req, res) => {
  await processJobWrapper(req, res, (_, jobId, body) =>
    pythonService.generateBeat(body.prompt),
  );
};

export const processVoice = async (req, res) => {
  await processJobWrapper(req, res, (filePath, jobId, body) =>
    pythonService.convertVoice(filePath, body.modelId),
  );
};
export const updateProgress = async (req, res) => {
  const { jobId, progress, statusMessage } = req.body;
  try {
    const job = await AudioJob.findByPk(jobId);
    if (job) {
      const updateData = { progress };
      if (statusMessage) updateData.statusMessage = statusMessage;
      await job.update(updateData);
      return res.json({ success: true });
    }
    res.status(404).json({ error: "Job not found" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

export const deleteJob = async (req, res) => {
  const { id } = req.params;
  try {
    const job = await AudioJob.findOne({
      where: { id, userId: req.user.id },
    });

    if (!job) {
      return res.status(404).json({ error: "Job not found" });
    }

    // 1. Physical File Deletion
    const originalPath = path.resolve(job.filePath);
    const fileName = path.basename(job.filePath, path.extname(job.filePath));
    
    // Path to separated folder in backend/uploads/separated/htdemucs/<filename>
    const separatedPath = path.join(__dirname, "../../uploads/separated/htdemucs", fileName);
    
    // Path to machine_py outputs just in case (as requested)
    const machinePyPath = path.join(__dirname, "../../../machine_py/outputs/separated/htdemucs", fileName);

    // Delete original file
    if (fs.existsSync(originalPath)) {
      fs.unlinkSync(originalPath);
      console.log(`Deleted original file: ${originalPath}`);
    }

    // Delete separated folders (recursive)
    if (fs.existsSync(separatedPath)) {
      fs.rmSync(separatedPath, { recursive: true, force: true });
      console.log(`Deleted separated folder: ${separatedPath}`);
    }
    
    if (fs.existsSync(machinePyPath)) {
      fs.rmSync(machinePyPath, { recursive: true, force: true });
      console.log(`Deleted machine_py folder: ${machinePyPath}`);
    }

    // 2. Database Deletion
    // Delete Result first
    await Result.destroy({ where: { jobId: job.id } });
    
    // Delete Song if it exists (for analyze type)
    await Song.destroy({ where: { userId: req.user.id, title: job.originalFileName } });

    // Finally delete the job
    await job.destroy();

    res.json({ success: true, message: "Job and files deleted successfully" });
  } catch (error) {
    console.error("Delete Job Error:", error);
    res.status(500).json({ error: "Failed to delete job and files" });
  }
};
