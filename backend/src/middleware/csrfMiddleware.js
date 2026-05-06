import crypto from "crypto";

export const csrfProtection = (req, res, next) => {
  // Generate token if not exists in session
  if (!req.session.csrfToken) {
    req.session.csrfToken = crypto.randomBytes(32).toString("hex");
  }

  // Skip validation for safe methods
  const safeMethods = ["GET", "HEAD", "OPTIONS"];
  if (safeMethods.includes(req.method)) {
    return next();
  }

  // Check token in header
  const tokenFromHeader = req.headers["x-csrf-token"];
  
  if (!tokenFromHeader || tokenFromHeader !== req.session.csrfToken) {
    return res.status(403).json({
      success: false,
      message: "Invalid or missing CSRF token",
    });
  }

  next();
};
