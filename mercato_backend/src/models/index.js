const sequelize = require('../../config/database');
const User = require('./User');
const PlayerProfile = require('./Playerprofile');
const RecruiterProfile = require('./RecruiterProfile');
const Video = require('./Video');
const VideoLike = require('./Videolike');
const VideoComment = require('./Videocomment');
const Favorite = require('./Favorite');
const Notification = require('./Notification');
const Report = require('./Report');

// --- User <-> PlayerProfile (1-to-1) ---
User.hasOne(PlayerProfile, { foreignKey: 'userId', onDelete: 'CASCADE' });
PlayerProfile.belongsTo(User, { foreignKey: 'userId' });

// --- User <-> RecruiterProfile (1-to-1) ---
User.hasOne(RecruiterProfile, { foreignKey: 'userId', onDelete: 'CASCADE' });
RecruiterProfile.belongsTo(User, { foreignKey: 'userId' });

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

// --- User <-> Notification (1-to-many, en tant que destinataire ou acteur) ---
User.hasMany(Notification, { foreignKey: 'recipientId', as: 'notifications', onDelete: 'CASCADE' });
Notification.belongsTo(User, { foreignKey: 'recipientId', as: 'recipient' });
Notification.belongsTo(User, { foreignKey: 'actorId', as: 'actor' });
Notification.belongsTo(Video, { foreignKey: 'videoId', as: 'video' });

// --- User <-> Report (signalement, deux FK vers User) ---
User.hasMany(Report, { foreignKey: 'reporterId', as: 'reportsMade', onDelete: 'CASCADE' });
Report.belongsTo(User, { foreignKey: 'reporterId', as: 'reporter' });
User.hasMany(Report, { foreignKey: 'targetUserId', as: 'reportsReceived', onDelete: 'CASCADE' });
Report.belongsTo(User, { foreignKey: 'targetUserId', as: 'target' });

module.exports = {
  sequelize,
  User,
  PlayerProfile,
  RecruiterProfile,
  Video,
  VideoLike,
  VideoComment,
  Favorite,
  Notification,
  Report,
};