const { DataTypes } = require('sequelize');
const sequelize = require('../../config/database');

const Report = sequelize.define('Report', {

  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },

  reporterId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },

  targetUserId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },

  reason: {
    type: DataTypes.ENUM('FAKE_PROFILE', 'SUSPICIOUS_CONTACT', 'INAPPROPRIATE_CONTENT', 'OTHER'),
    allowNull: false,
  },

  details: {
    type: DataTypes.TEXT,
    allowNull: true,
  },

  status: {
    type: DataTypes.ENUM('OPEN', 'REVIEWED', 'DISMISSED'),
    allowNull: false,
    defaultValue: 'OPEN',
  },

}, {
  tableName: 'reports',
  timestamps: true,
});

module.exports = Report;
