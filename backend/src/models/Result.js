import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';
import AudioJob from './AudioJob.js';

const Result = sequelize.define('Result', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  jobId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: AudioJob,
      key: 'id',
    },
  },
  resultJson: {
    type: DataTypes.TEXT('long'),
    allowNull: true,
    get() {
      const rawValue = this.getDataValue('resultJson');
      return rawValue ? JSON.parse(rawValue) : null;
    },
    set(value) {
      this.setDataValue('resultJson', value ? JSON.stringify(value) : null);
    }
  },
  fileUrls: {
    type: DataTypes.TEXT('long'),
    allowNull: true,
    get() {
      const rawValue = this.getDataValue('fileUrls');
      return rawValue ? JSON.parse(rawValue) : null;
    },
    set(value) {
      this.setDataValue('fileUrls', value ? JSON.stringify(value) : null);
    }
  },
}, {
  timestamps: true,
  tableName: 'results',
});

AudioJob.hasOne(Result, { foreignKey: 'jobId' });
Result.belongsTo(AudioJob, { foreignKey: 'jobId' });

export default Result;
