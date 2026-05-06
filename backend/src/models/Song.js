import { DataTypes } from "sequelize";
import sequelize from "../config/database.js";
import User from "./User.js";

const Song = sequelize.define(
  "Song",
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
    title: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    filePath: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    bpm: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },
    key: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    duration: {
      type: DataTypes.FLOAT,
      allowNull: true,
    },
    chordsJson: {
      type: DataTypes.JSON,
      allowNull: true,
    },
  },
  {
    timestamps: true,
    tableName: "songs",
  },
);

User.hasMany(Song, { foreignKey: "userId" });
Song.belongsTo(User, { foreignKey: "userId" });

export default Song;
