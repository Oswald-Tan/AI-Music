import AudioJob from "../models/AudioJob.js";

export const uploadAudio = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: "No audio file uploaded" });
    }

    const { type } = req.body;

    if (
      !type ||
      !["separate", "chord", "beat", "voice", "analyze", "process"].includes(
        type,
      )
    ) {
      return res.status(400).json({ error: "Invalid process type specified" });
    }

    // Create job record
    const job = await AudioJob.create({
      userId: req.user.id,
      originalFileName: req.file.originalname,
      filePath: req.file.path,
      type: type,
      status: "pending",
    });

    res.status(201).json({
      message: "File uploaded and job created successfully",
      jobId: job.id,
      filePath: job.filePath,
    });
  } catch (error) {
    console.error("Upload error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const reuseJobFile = async (req, res) => {
  try {
    const { originalJobId, type } = req.body;

    if (!originalJobId || !type) {
      return res
        .status(400)
        .json({ error: "originalJobId and type are required" });
    }

    const originalJob = await AudioJob.findOne({
      where: { id: originalJobId, userId: req.user.id },
    });
    if (!originalJob) {
      return res.status(404).json({ error: "Original job not found" });
    }

    const newJob = await AudioJob.create({
      userId: req.user.id,
      originalFileName: originalJob.originalFileName,
      filePath: originalJob.filePath,
      type: type,
      status: "pending",
    });

    res.status(201).json({
      message: "Job created using existing file",
      jobId: newJob.id,
    });
  } catch (error) {
    console.error("Reuse error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};
