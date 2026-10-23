const { DataTypes } = require('sequelize');
const sequelize = require('../../config/database');

const Message = sequelize.define('Message', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  senderId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    
  },
  receiverId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  
  },
  content: {
    type: DataTypes.TEXT,
    allowNull: false,
  
  },
  isRead: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
    
  },
  messageType: {
    type: DataTypes.ENUM('text', 'video_share', 'offer', 'trial_request'),
    defaultValue: 'text',
    // Permet d'envoyer directement une vidéo du feed ou une proposition d'essai
  },
  relatedVideoId: {
    type: DataTypes.INTEGER,
    allowNull: true,
    // Si l'utilisateur partage une vidéo spécifique de la plateforme
  },
}, {
  tableName: 'messages',
  timestamps: true,
  indexes: [
    // Accélère "récupérer tous les messages entre A et B"
    { fields: ['senderId', 'receiverId'] },
    { fields: ['receiverId', 'senderId'] },
    // Accélère "compter les non-lus reçus par un utilisateur"
    { fields: ['receiverId', 'isRead'] },
  ],
});

module.exports = Message;