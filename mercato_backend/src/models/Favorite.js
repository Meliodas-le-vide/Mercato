const { DataTypes } = require('sequelize');
const sequelize = require('../../config/database');

const Favorite = sequelize.define('Favorite', {

  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },

  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },

  playerId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },

}, {
  tableName: 'favorites',
  timestamps: true,
  indexes: [
    {
      // Un utilisateur ne peut mettre le même joueur en favori qu'une seule fois
      unique: true,
      fields: ['userId', 'playerId'],
    },
  ],
});

module.exports = Favorite;