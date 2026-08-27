const sequelize = require('../../config/database');
const User = require('./User');
const PlayerProfile = require('./Playerprofile');
const Video = require('./Video');
const VideoLike = require('./Videolike');
const VideoComment = require('./Videocomment');
const Favorite = require('./Favorite');

// --- User <-> PlayerProfile (1-to-1) ---
User.hasOne(PlayerProfile, { foreignKey: 'userId', onDelete: 'CASCADE' });
PlayerProfile.belongsTo(User, { foreignKey: 'userId' });

// --- User <-> Video (1-to-many) ---
User.hasMany(Video, { foreignKey: 'userId', as: 'videos', onDelete: 'CASCADE' });
Video.belongsTo(User, { foreignKey: 'userId', as: 'author' });

// --- Video <-> VideoLike (1-to-many) ---
Video.hasMany(VideoLike, { foreignKey: 'videoId', onDelete: 'CASCADE' });
VideoLike.belongsTo(Video, { foreignKey: 'videoId' });
User.hasMany(VideoLike, { foreignKey: 'userId', onDelete: 'CASCADE' });
VideoLike.belongsTo(User, { foreignKey: 'userId' });

// --- Video <-> VideoComment (1-to-many) ---
Video.hasMany(VideoComment, { foreignKey: 'videoId', as: 'comments', onDelete: 'CASCADE' });
VideoComment.belongsTo(Video, { foreignKey: 'videoId' });
User.hasMany(VideoComment, { foreignKey: 'userId', onDelete: 'CASCADE' });
VideoComment.belongsTo(User, { foreignKey: 'userId', as: 'author' });

// --- User <-> Favorite (1-to-many) ---
User.hasMany(Favorite, { foreignKey: 'userId', onDelete: 'CASCADE' });
Favorite.belongsTo(User, { foreignKey: 'userId' });

module.exports = {
  sequelize,
  User,
  PlayerProfile,
  Video,
  VideoLike,
  VideoComment,
  Favorite
};