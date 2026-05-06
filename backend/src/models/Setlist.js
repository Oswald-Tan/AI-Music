import { DataTypes } from "sequelize";
import sequelize from "../config/database.js";
import User from "./User.js";

const Setlist = sequelize.define(
  "Setlist",
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
  },
  {
    timestamps: true,
    tableName: "setlists",
  }
);

User.hasMany(Setlist, { foreignKey: "userId" });
Setlist.belongsTo(User, { foreignKey: "userId" });

export default Setlist;
