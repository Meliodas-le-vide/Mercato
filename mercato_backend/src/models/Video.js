const { DataTypes } = require('sequelize');
const sequelize = require('../../config/database');

const Video = sequelize.define('Video', {

  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },

  userId: {
    // Le joueur qui a publié la vidéo
    type: DataTypes.INTEGER,
    allowNull: false,
  },

  title: {
    type: DataTypes.STRING(150),
    allowNull: false,
  },

  description: {
    type: DataTypes.TEXT,
    allowNull: true,
  },

  tags: {
    // ex: ["dribble", "but", "finale"]
    type: DataTypes.JSON,
    allowNull: true,
  },

  position: {
    // Poste concerné par l'action montrée dans la vidéo (filtrable dans le feed)
    type: DataTypes.ENUM(
      'GARDIEN',
      'DEFENSEUR_CENTRAL',
      'LATERAL_DROIT',
      'LATERAL_GAUCHE',
      'MILIEU_DEFENSIF',
      'MILIEU_CENTRAL',
      'MILIEU_OFFENSIF',
      'AILIER_DROIT',
      'AILIER_GAUCHE',
      'ATTAQUANT'
    ),
    allowNull: true,
  },

  videoUrl: {
    type: DataTypes.STRING(500),
    allowNull: false,
  },

  videoPublicId: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },

  thumbnailUrl: {
    type: DataTypes.STRING(500),
    allowNull: true,
  },

  // --- Compteurs dénormalisés pour éviter des COUNT() coûteux à chaque lecture du feed ---
  viewsCount: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },

  likesCount: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },

  commentsCount: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },

}, {
  tableName: 'videos',
  timestamps: true,
});

module.exports = Video;