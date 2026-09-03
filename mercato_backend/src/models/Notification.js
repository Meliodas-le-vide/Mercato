const { DataTypes } = require('sequelize');
const sequelize = require('../../config/database');

const Notification = sequelize.define('Notification', {

  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },

  recipientId: {
    // L'utilisateur qui reçoit la notification
    type: DataTypes.INTEGER,
    allowNull: false,
  },

  actorId: {
    // L'utilisateur à l'origine de l'événement (ex: le joueur qui a posté)
    type: DataTypes.INTEGER,
    allowNull: true,
  },

  type: {
    type: DataTypes.ENUM('NEW_VIDEO', 'NEW_FAVORITE'),
    allowNull: false,
  },

  message: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },

  videoId: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },

  isRead: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },

}, {
  tableName: 'notifications',
  timestamps: true,
  indexes: [
    { fields: ['recipientId', 'createdAt'] },
  ],
});

module.exports = Notification;
