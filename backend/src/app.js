import express from "express";
import cors from "cors";
import helmet from "helmet";
import compression from "compression";
import dotenv from "dotenv";
import path from "path";
import { fileURLToPath } from "url";
import fs from "fs";

import sequelize from "./config/database.js";
import routes from "./routes/index.js";

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 8087;

// Security & Middlewares
app.use(
  helmet({
    crossOriginResourcePolicy: { policy: "cross-origin" },
  }),
);
app.use(
  cors({
    origin: process.env.ALLOWED_ORIGINS
      ? process.env.ALLOWED_ORIGINS.split(",")
      : "*",
    credentials: true,
  }),
);
app.use(compression());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve uploads statically (including AI stems)
app.use(
  "/uploads",
  (req, res, next) => {
    const decodedUrl = decodeURIComponent(req.url);
    if (req.url.includes("separated")) {
      const fullPath = path.join(__dirname, "../uploads", decodedUrl);
      if (fs.existsSync(fullPath)) {
        const stats = fs.statSync(fullPath);
        console.log(`[GET] Serving AI Stem: ${decodedUrl} (${(stats.size / 1024 / 1024).toFixed(2)} MB)`);
      } else {
        console.log(`[404] AI Stem NOT FOUND: ${decodedUrl} at ${fullPath}`);
      }
    }

    // Ensure .mp3 and .wav files have correct content-type for mobile players
    if (decodedUrl.endsWith(".mp3")) {
      res.set("Content-Type", "audio/mpeg");
    } else if (decodedUrl.endsWith(".wav")) {
      res.set("Content-Type", "audio/wav");
    }

    next();
  },
  express.static(path.join(__dirname, "../uploads")),
);

// Routes
app.use("/api", routes);

// Health check
app.get("/health", (req, res) => {
  res.status(200).json({ status: "OK", message: "Voxora Backend is running" });
});

// Database connection & Server start
const startServer = async () => {
  try {
    await sequelize.authenticate();
    console.log("Database connected successfully.");

    // Sync models (creates tables if they don't exist)
    // Be careful with force: true in production, it drops tables!
    await sequelize.sync({ alter: true });
    console.log("Database models synced.");

    app.listen(PORT, () => {
      console.log(`Server is running on port ${PORT}`);
    });
  } catch (error) {
    console.error("Unable to connect to the database:", error);
    process.exit(1);
  }
};

startServer();
