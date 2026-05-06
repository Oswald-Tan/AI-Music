import { DataTypes } from "sequelize";
import sequelize from "../config/database.js";
import Setlist from "./Setlist.js";
import AudioJob from "./AudioJob.js";

const SetlistSong = sequelize.define(
  "SetlistSong",
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    setlistId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: Setlist,
        key: "id",
      },
    },
    audioJobId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: AudioJob,
        key: "id",
      },
    },
    order: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
    },
  },
  {
    timestamps: true,
    tableName: "setlist_songs",
  }
);

Setlist.belongsToMany(AudioJob, { through: SetlistSong, foreignKey: "setlistId", as: "songs" });
AudioJob.belongsToMany(Setlist, { through: SetlistSong, foreignKey: "audioJobId", as: "setlists" });

export default SetlistSong;
