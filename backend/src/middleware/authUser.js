import User from "../models/User.js";
import Role from "../models/role.js";

export const verifyUser = async (req, res, next) => {
  if (!req.session.userId) {
    return res.status(401).json({ message: "Mohon login ke akun Anda!" });
  }

  const user = await User.findOne({
    where: { id: req.session.userId },
    include: {
      model: Role,
      as: "userRole",
      attributes: ["role_name"],
    },
  });
  if (!user) return res.status(404).json({ message: "User not found" });
  req.userId = user.id;
  req.role = user.userRole.role_name;
  next();
};

export const adminOnly = async (req, res, next) => {
  const user = await User.findOne({
    where: { id: req.session.userId },
    include: {
      model: Role,
      as: "userRole",
      attributes: ["role_name"],
    },
  });
  if (!user) return res.status(404).json({ message: "User not found" });

  //cek role name untuk akses admin
  if (
    user.userRole.role_name !== "admin" &&
    user.userRole.role_name !== "super_admin"
  )
    return res.status(403).json({ message: "Akses terlarang" });
  next();
};
