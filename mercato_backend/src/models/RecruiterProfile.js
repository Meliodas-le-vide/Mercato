const { DataTypes } = require('sequelize');
const sequelize = require('../../config/database');

const RecruiterProfile = sequelize.define('RecruiterProfile', {

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

  organizationName: {
    // Nom du club, de l'agence ou du centre de formation
    type: DataTypes.STRING(150),
    allowNull: true,
  },

  organizationType: {
    type: DataTypes.ENUM('CLUB', 'AGENCE', 'CENTRE_FORMATION', 'INDEPENDANT'),
    allowNull: true,
  },

  jobTitle: {
    // Fonction occupée (ex: Recruteur, Directeur sportif, Agent FIFA...)
    type: DataTypes.STRING(100),
    allowNull: true,
  },

  recruitmentZone: {
    // Zone géographique de recrutement (ex: "Côte d'Ivoire, Afrique de l'Ouest")
    type: DataTypes.STRING(150),
    allowNull: true,
  },

  bio: {
    type: DataTypes.TEXT,
    allowNull: true,
  },

  isProfileComplete: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },

  // Confiance progressive : un recruteur peut s'inscrire et compléter son
  // profil librement (pas de friction à l'inscription), mais reste PENDING
  // tant qu'un admin n'a pas confirmé son organisation. Le contact d'un
  // joueur est bloqué côté frontend tant que ce statut n'est pas VERIFIED.
  verificationStatus: {
    type: DataTypes.ENUM('PENDING', 'VERIFIED', 'REJECTED'),
    allowNull: false,
    defaultValue: 'PENDING',
  },

}, {
  tableName: 'recruiter_profiles',
  timestamps: true,
});

module.exports = RecruiterProfile;
