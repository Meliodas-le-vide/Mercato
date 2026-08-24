const { DataTypes } = require('sequelize');
const sequelize = require('../../config/database');

const PlayerProfile = sequelize.define('PlayerProfile', {

  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },

  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    unique: true, // garantit la relation 1-to-1 : un seul profil par user
  },

  position: {
  
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

  strongFoot: {
    type: DataTypes.ENUM('DROIT', 'GAUCHE', 'AMBIDEXTRE'),
    allowNull: true,
  },

  birthDate: {
    type: DataTypes.DATEONLY,
    allowNull: true,
  },

  level: {
    type: DataTypes.ENUM('AMATEUR', 'SEMI_PRO', 'PRO'),
    allowNull: true,
  },

  currentClub: {
    type: DataTypes.STRING(150),
    allowNull: true,
  },

  height: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },

  weight: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },

  city: {
    type: DataTypes.STRING(100),
    allowNull: true,
  },

  country: {
    type: DataTypes.STRING(100),
    allowNull: true,
  },

  bio: {
    type: DataTypes.TEXT,
    allowNull: true,
  },

  goals: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },

  assists: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },

  matchesPlayed: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },

  cardsYellow: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },

  cardsRed: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },

 
  videoUrl: {
    // URL sécurisée renvoyée par Cloudinary après upload
    type: DataTypes.STRING(500),
    allowNull: true,
  },

  videoPublicId: {
    // public_id Cloudinary, nécessaire pour pouvoir supprimer/remplacer la vidéo plus tard
    type: DataTypes.STRING(255),
    allowNull: true,
  },

  isProfileComplete: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },


}, {
  tableName: 'player_profiles',
  timestamps: true,
});

module.exports = PlayerProfile;


