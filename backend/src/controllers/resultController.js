import AudioJob from "../models/AudioJob.js";
import Result from "../models/Result.js";

const fixJobUrl = (job) => {
  if (!job) return job;
  const backendUrl = process.env.BACKEND_URL || "http://localhost:8087";
  const jobData = job.toJSON ? job.toJSON() : { ...job };

  if (jobData.filePath && !jobData.filePath.startsWith("http")) {
    const normalizedPath = jobData.filePath.replace(/\\/g, "/");
    jobData.filePath = `${backendUrl}/${normalizedPath}`;
  }
  return jobData;
};

export const getResult = async (req, res) => {
  try {
    const { jobId } = req.params;

    const job = await AudioJob.findOne({
      where: { id: jobId, userId: req.user.id },
    });

    if (!job) {
      return res.status(404).json({ error: "Job not found" });
    }

    if (job.status !== "done") {
      return res.status(400).json({
        message: "Result is not ready yet",
        status: job.status,
      });
    }

    const result = await Result.findOne({ where: { jobId } });

    if (!result) {
      return res.status(404).json({
        error: "Result not found even though job is done (unexpected error)",
      });
    }

    res.json({
      job: fixJobUrl(job),
      result,
    });
  } catch (error) {
    console.error("Get result error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const getMyJobs = async (req, res) => {
  try {
    const jobs = await AudioJob.findAll({
      where: { userId: req.user.id },
      order: [["createdAt", "DESC"]],
    });

    res.json(jobs.map(fixJobUrl));
  } catch (error) {
    console.error("Get jobs error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const getJobStatus = async (req, res) => {
  try {
    const { id } = req.params;

    const job = await AudioJob.findOne({
      where: { id, userId: req.user.id },
      attributes: [
        "id",
        "userId",
        "originalFileName",
        "status",
        "type",
        "filePath",
        "createdAt",
      ],
    });

    if (!job) {
      return res.status(404).json({ error: "Job not found" });
    }

    res.json(fixJobUrl(job));
  } catch (error) {
    console.error("Get job status error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};
