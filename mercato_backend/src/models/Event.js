const { DataTypes } = require('sequelize');
const sequelize = require('../../config/database');

/**
 * Événement publié par un recruteur (essai, test, détection, etc.),
 * consultable par les joueurs. organizerId identifie le recruteur qui a
 * créé l'événement (pour les permissions) ; organizerName est le nom
 * affiché publiquement (club, structure...), saisi librement par le
 * recruteur au moment de la création.
 */
const Event = sequelize.define('Event', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },

  organizerId: {
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

  eventDate: {
    type: DataTypes.DATE,
    allowNull: false,
  },

  location: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },

  organizerName: {
    type: DataTypes.STRING(150),
    allowNull: false,
  },

   imageUrl: {
     type: DataTypes.STRING(500),
     allowNull: true,
  },

}, {
  tableName: 'events',
  timestamps: true,
});

module.exports = Event;