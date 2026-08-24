const { DataTypes } = require('sequelize');
const sequelize = require('../../config/database');

const VideoLike = sequelize.define('VideoLike', {

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

}, {
  tableName: 'video_likes',
  timestamps: true,
  indexes: [
    {
      // Un utilisateur ne peut liker la même vidéo qu'une seule fois
      unique: true,
      fields: ['userId', 'videoId'],
    },
  ],
});

module.exports = VideoLike;