// middleware/upload.js (diperbarui)
import multer from "multer";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import crypto from "crypto";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Fungsi untuk membuat middleware upload dinamis
const createUploader = (folderName, fileSizeLimit = 50 * 1024 * 1024) => {
  // Buat direktori jika belum ada
  const uploadDir = path.join(__dirname, `../../uploads/${folderName}`);

  if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
  }

  const storage = multer.diskStorage({
    destination: (req, file, cb) => {
      cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
      // Generate nama file unik dengan hash
      const uniquePrefix = crypto.randomBytes(8).toString("hex");
      const ext = path.extname(file.originalname);
      const basename = path
        .basename(file.originalname, ext)
        .normalize("NFD")
        .replace(/[\u0300-\u036f]/g, "") // Remove accents
        .replace(/\s+/g, "-") // Replace spaces with hyphens
        .replace(/[^\w\-]+/g, "") // Remove all non-word chars
        .toLowerCase();

      // Format: [timestamp]-[hash]-[normalized-name]
      cb(null, `${Date.now()}-${uniquePrefix}-${basename}${ext}`);
    },
  });

  const fileFilter = (req, file, cb) => {
    const allowedTypes = [
      // Documents
      "application/pdf",
      "application/msword",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      "application/vnd.ms-excel",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "application/vnd.ms-powerpoint",
      "application/vnd.openxmlformats-officedocument.presentationml.presentation",
      "text/plain",
      "application/zip",
      "application/x-rar-compressed",

      // Images
      "image/jpeg",
      "image/png",
      "image/gif",
      "image/webp",
      "image/svg+xml",

      // Videos
      "video/mp4",
      "video/mpeg",
      "video/quicktime",
      "video/x-msvideo",
    ];

    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(
        new Error(
          `Jenis file tidak diizinkan. Hanya dokumen, gambar, dan video yang diperbolehkan. File type: ${file.mimetype}`,
        ),
        false,
      );
    }
  };

  return multer({
    storage: storage,
    fileFilter: fileFilter,
    limits: {
      fileSize: fileSizeLimit,
    },
  });
};

// Buat dan ekspor instance multer untuk setiap jenis upload
export const bioProfileUpload = createUploader("bio-profile", 5 * 1024 * 1024); // 5MB limit
export const affiliateProductUpload = createUploader(
  "affiliate-product",
  5 * 1024 * 1024,
); // 5MB limit
export const rateCardProfileUpload = createUploader("rate-card", 2 * 1024 * 1024); // 2MB limit as it's compressed on frontend
export const qrLogoUpload = createUploader("qr-logos", 2 * 1024 * 1024); // 2MB limit

// Middleware error handling untuk upload
export const handleUploadError = (err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    if (err.code === "LIMIT_FILE_SIZE") {
      return res.status(400).json({
        success: false,
        error: "File terlalu besar. Ukuran maksimal adalah 50MB",
      });
    }
  }

  if (err.message.includes("Jenis file tidak diizinkan")) {
    return res.status(400).json({
      success: false,
      error: err.message,
    });
  }

  next(err);
};

export default createUploader;
