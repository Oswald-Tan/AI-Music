import { DataTypes } from "sequelize";
import db from "../config/database.js";
import User from "./User.js";

const Role = db.define(
  "role",
  {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    role_name: {
      type: DataTypes.ENUM(
        "super_admin",
        "admin",
        "premium_user",
        "user",
        "viewer"
      ),
      allowNull: false,
    },
  },
  {
    timestamps: false,
    tableName: "roles",
    indexes: [
      {
        unique: true,
        fields: ["role_name"],
      },
    ],
  }
);

User.belongsTo(Role, { foreignKey: "role_id", as: "userRole" });
Role.hasMany(User, { foreignKey: "role_id", as: "userRole" });

export default Role;
