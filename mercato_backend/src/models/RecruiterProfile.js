const { DataTypes } = require('sequelize');
const sequelize = require('../../config/database');

const RecruiterProfile = sequelize.define(
  'RecruiterProfile',
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },

    userId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      unique: true,
    },

    organizationName: {
      type: DataTypes.STRING(150),
      allowNull: true,
      validate: { len: [0, 150] },
    },

    organizationType: {
      type: DataTypes.ENUM('CLUB', 'AGENCE', 'CENTRE_FORMATION', 'INDEPENDANT'),
      allowNull: true,
    },

    jobTitle: {
      type: DataTypes.STRING(100),
      allowNull: true,
      validate: { len: [0, 100] },
    },

    recruitmentZone: {
      type: DataTypes.STRING(150),
      allowNull: true,
      validate: { len: [0, 150] },
    },

    bio: {
      type: DataTypes.TEXT,
      allowNull: true,
      validate: { len: [0, 1000] },
    },

    isProfileComplete: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },

    verificationStatus: {
      type: DataTypes.ENUM('PENDING', 'VERIFIED', 'REJECTED'),
      allowNull: false,
      defaultValue: 'PENDING',
    },

    identityDocumentType: {
      type: DataTypes.ENUM(
        'CNI',
        'PASSEPORT',
        'SIRET',
        'RCS',
        'CARTE_AGENT_FIFA',
        'ATTESTATION_CLUB',
        'AUTRE'
      ),
      allowNull: true,
    },

    identityDocumentNumber: {
      type: DataTypes.STRING(50),
      allowNull: true,
      comment: 'Numéro du document (ex: numéro CNI, passeport)',
    },

    identityDocumentUrl: {
      type: DataTypes.STRING(500),
      allowNull: true,
      validate: { isUrl: true },
    },

    identityDocumentPublicId: {
      type: DataTypes.STRING(255),
      allowNull: true,
      comment: 'Public ID Cloudinary pour suppression',
    },

    licenseNumber: {
      type: DataTypes.STRING(100),
      allowNull: true,
      validate: { len: [3, 100] },
    },

    businessProofUrl: {
      type: DataTypes.STRING(500),
      allowNull: true,
      validate: { isUrl: true },
    },

    businessProofPublicId: {
      type: DataTypes.STRING(255),
      allowNull: true,
    },


    kycSubmittedAt: {
      type: DataTypes.DATE,
      allowNull: true,
      comment: 'Date de soumission initiale',
    },

    verifiedAt: {
      type: DataTypes.DATE,
      allowNull: true,
      comment: 'Date de validation par un admin',
    },

    verifiedBy: {
      type: DataTypes.INTEGER,
      allowNull: true,
      comment: 'ID de l admin qui a validé',
    },

    rejectedAt: {
      type: DataTypes.DATE,
      allowNull: true,
      comment: 'Date de refus',
    },
    
    rejectedBy: {
      type: DataTypes.INTEGER,
      allowNull: true,
      comment: 'ID de l admin qui a refusé',
    },

    rejectionReason: {
      type: DataTypes.STRING(500),
      allowNull: true,
      comment: 'Motif du refus (visible par le recruteur)',
    },
  },
  {
    tableName: 'recruiter_profiles',
    timestamps: true,
    indexes: [
      { fields: ['verificationStatus'] }, 
      { fields: ['userId'] },
    ],
  }
);

module.exports = RecruiterProfile;