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
const Message = require('./Message');
const Event = require('./Event');


User.hasOne(PlayerProfile, { foreignKey: 'userId', as: 'playerProfile', onDelete: 'CASCADE' });
PlayerProfile.belongsTo(User, { foreignKey: 'userId', as: 'user' });

// --- User <-> RecruiterProfile (1-to-1) ---
User.hasOne(RecruiterProfile, { foreignKey: 'userId', as: 'recruiterProfile', onDelete: 'CASCADE' });
RecruiterProfile.belongsTo(User, { foreignKey: 'userId', as: 'user' });

// --- User <-> Video (1-to-many) ---
//  Alias 'author' (pas 'user')
User.hasMany(Video, { foreignKey: 'userId', as: 'videos', onDelete: 'CASCADE' });
Video.belongsTo(User, { foreignKey: 'userId', as: 'author' });

// --- Video <-> VideoLike (1-to-many) ---
Video.hasMany(VideoLike, { foreignKey: 'videoId', as: 'likes', onDelete: 'CASCADE' });
VideoLike.belongsTo(Video, { foreignKey: 'videoId', as: 'video' });
User.hasMany(VideoLike, { foreignKey: 'userId', as: 'likes', onDelete: 'CASCADE' });
VideoLike.belongsTo(User, { foreignKey: 'userId', as: 'user' });

// --- Video <-> VideoComment (1-to-many) ---
//  Alias 'author' pour User, 'video' pour Video
Video.hasMany(VideoComment, { foreignKey: 'videoId', as: 'comments', onDelete: 'CASCADE' });
VideoComment.belongsTo(Video, { foreignKey: 'videoId', as: 'video' });
User.hasMany(VideoComment, { foreignKey: 'userId', as: 'comments', onDelete: 'CASCADE' });
VideoComment.belongsTo(User, { foreignKey: 'userId', as: 'author' });

// --- User <-> Favorite (1-to-many) ---
User.hasMany(Favorite, { foreignKey: 'userId', as: 'favorites', onDelete: 'CASCADE' });
Favorite.belongsTo(User, { foreignKey: 'userId', as: 'user' });

// --- User <-> Notification ---
//  Deux alias différents vers User : 'recipient' et 'actor'
User.hasMany(Notification, { foreignKey: 'recipientId', as: 'notifications', onDelete: 'CASCADE' });
Notification.belongsTo(User, { foreignKey: 'recipientId', as: 'recipient' });
Notification.belongsTo(User, { foreignKey: 'actorId', as: 'actor' });
Notification.belongsTo(Video, { foreignKey: 'videoId', as: 'video' });

// --- User <-> Report ---
// Alias 'reporter' et 'target'
User.hasMany(Report, { foreignKey: 'reporterId', as: 'reportsMade', onDelete: 'CASCADE' });
Report.belongsTo(User, { foreignKey: 'reporterId', as: 'reporter' });
User.hasMany(Report, { foreignKey: 'targetUserId', as: 'reportsReceived', onDelete: 'CASCADE' });
Report.belongsTo(User, { foreignKey: 'targetUserId', as: 'target' });

// --- User <-> Message ---
//  Alias 'sender' et 'receiver'
Message.belongsTo(User, { as: 'sender', foreignKey: 'senderId' });
Message.belongsTo(User, { as: 'receiver', foreignKey: 'receiverId' });
User.hasMany(Message, { as: 'sentMessages', foreignKey: 'senderId' });
User.hasMany(Message, { as: 'receivedMessages', foreignKey: 'receiverId' });

// --- User <-> Event ---
//  Alias 'organizer'
User.hasMany(Event, { foreignKey: 'organizerId', as: 'events', onDelete: 'CASCADE' });
Event.belongsTo(User, { foreignKey: 'organizerId', as: 'organizer' });

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
  Message,
  Event,
};