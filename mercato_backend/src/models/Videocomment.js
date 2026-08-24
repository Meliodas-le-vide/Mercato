const { DataTypes } = require('sequelize');
const sequelize = require('../../config/database');

const VideoComment = sequelize.define('VideoComment', {

  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },

  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },

  videoId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },

  content: {
    type: DataTypes.TEXT,
    allowNull: false,
    validate: {
      notEmpty: true,
      len: [1, 500],
    },
  },

}, {
  tableName: 'video_comments',
  timestamps: true,
});

module.exports = VideoComment;