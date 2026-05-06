// Simpan token blacklist dalam memory untuk sementara (gunakan database untuk produksi)
const tokenBlacklist = new Set();

// Fungsi untuk menambahkan token ke dalam blacklist
export const addTokenToBlacklist = (token) => {
  tokenBlacklist.add(token); // Menambahkan token ke dalam Set
};

// Middleware untuk memeriksa apakah token ada di blacklist
export const checkTokenBlacklist = (req, res, next) => {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];

  if (!token) {
    return res.status(401).json({
      message: "Unauthorized, token required.",
    });
  }

  if (tokenBlacklist.has(token)) {
    return res.status(403).json({
      message: "Token has been invalidated. Please log in again.",
    });
  }

  next(); // Jika token tidak ada di blacklist, lanjutkan ke middleware berikutnya
};
