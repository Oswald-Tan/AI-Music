import { DataTypes } from "sequelize";
import sequelize from "../config/database.js";
import User from "./User.js";

const AudioJob = sequelize.define(
  "AudioJob",
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    userId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: User,
        key: "id",
      },
    },
    originalFileName: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    filePath: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    type: {
      type: DataTypes.ENUM("separate", "chord", "beat", "voice", "analyze", "process"),
      allowNull: false,
    },
    status: {
      type: DataTypes.ENUM("pending", "processing", "done", "failed"),
      defaultValue: "pending",
    },
    progress: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
    },
    statusMessage: {
      type: DataTypes.STRING,
      allowNull: true,
    },
  },
  {
    timestamps: true,
    tableName: "audio_jobs",
  },
);

User.hasMany(AudioJob, { foreignKey: "userId" });
AudioJob.belongsTo(User, { foreignKey: "userId" });

export default AudioJob;
