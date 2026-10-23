const { DataTypes } = require('sequelize');
const sequelize = require('../../config/database');

const User = sequelize.define('User', {

  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true
  },

  lastname: {
    type: DataTypes.STRING,
    allowNull: false
  },

  firstname: {
    type: DataTypes.STRING,
    allowNull: false
  },

  email: {
    type: DataTypes.STRING(191),
    allowNull: false,
    unique: true,
    validate: {
      isEmail: true
    },
      set(value) {
        this.setDataValue('email', value?.toLowerCase().trim());
      },
  },
  password: {
    type: DataTypes.STRING(255),
    allowNull: false
  },

  phone: {
    type: DataTypes.STRING(30)
  },

  role: {
    type: DataTypes.ENUM('PLAYER', 'RECRUITER', 'USER', 'CLUB_AGENT', 'ADMIN'),
    allowNull: false
  },

  Profile_image: {
    type: DataTypes.STRING(255),
    allowNull: true
  },

  refreshToken: {
    type: DataTypes.TEXT,
    allowNull: true
  },

  is_verified: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  },

  avatarPublicId: {
    type: DataTypes.STRING(255),
    allowNull: true
  },

  isBanned: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false,
  },

  bannedReason: {
    type: DataTypes.STRING(255),
    allowNull: true,
  },

  // ---- Réinitialisation du mot de passe (code à 6 chiffres, haché) ----
  resetPasswordCode: {
    type: DataTypes.STRING(255),
    allowNull: true,
  },

  resetPasswordExpires: {
    type: DataTypes.DATE,
    allowNull: true,
  },

  resetPasswordAttempts: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },

}, {
  tableName: 'users',
  timestamps: true
});

module.exports = User;