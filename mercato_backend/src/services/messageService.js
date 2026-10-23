const { Message, User } = require('../models/index.js');

const PUBLIC_SENDER_ATTRS = ['id', 'firstname', 'lastname', 'Profile_image', 'role'];

/**
 * Crée un message en base et le retourne avec les infos de l'expéditeur incluses.
 * Utilisé à la fois par le contrôleur REST (fallback) et le handler Socket.io.
 */
async function createMessage(senderId, { receiverId, content, messageType, relatedVideoId }) {
  if (!receiverId || !content || !content.trim()) {
    const err = new Error('receiverId et content sont requis.');
    err.status = 400;
    throw err;
  }

  if (Number(receiverId) === Number(senderId)) {
    const err = new Error('Vous ne pouvez pas vous envoyer un message à vous-même.');
    err.status = 400;
    throw err;
  }

  const receiver = await User.findByPk(receiverId);
  if (!receiver) {
    const err = new Error('Destinataire introuvable.');
    err.status = 404;
    throw err;
  }

  const message = await Message.create({
    senderId,
    receiverId,
    content: content.trim(),
    messageType: messageType || 'text',
    relatedVideoId: relatedVideoId || null,
  });

  const withSender = await Message.findByPk(message.id, {
    include: [{ model: User, as: 'sender', attributes: PUBLIC_SENDER_ATTRS }],
  });

  return withSender;
}

/**
 * Retourne la liste des conversations d'un utilisateur : pour chaque
 * interlocuteur distinct, le dernier message échangé + le nombre de non-lus.
 *
 * Note : approche simple par scan des messages, adaptée à un volume MVP.
 * Si le volume de messages devient très important, il faudra migrer vers
 * une table Conversation dédiée mise à jour à chaque envoi.
 */
async function getConversations(userId) {
  const { Op } = require('sequelize');

  const messages = await Message.findAll({
    where: {
      [Op.or]: [{ senderId: userId }, { receiverId: userId }],
    },
    order: [['createdAt', 'DESC']],
    limit: 1000, // garde-fou pour éviter de charger un historique énorme
  });

  const conversationsMap = new Map(); // otherUserId -> { lastMessage, unreadCount }

  for (const msg of messages) {
    const otherUserId = msg.senderId === userId ? msg.receiverId : msg.senderId;

    if (!conversationsMap.has(otherUserId)) {
      conversationsMap.set(otherUserId, { lastMessage: msg, unreadCount: 0 });
    }

    const isUnreadForMe = msg.receiverId === userId && !msg.isRead;
    if (isUnreadForMe) {
      conversationsMap.get(otherUserId).unreadCount += 1;
    }
  }

  const otherUserIds = [...conversationsMap.keys()];
  if (otherUserIds.length === 0) return [];

  const users = await User.findAll({
    where: { id: otherUserIds },
    attributes: PUBLIC_SENDER_ATTRS,
  });
  const usersById = new Map(users.map((u) => [u.id, u]));

  return otherUserIds
    .map((id) => ({
      user: usersById.get(id) || null,
      lastMessage: conversationsMap.get(id).lastMessage,
      unreadCount: conversationsMap.get(id).unreadCount,
    }))
    .filter((c) => c.user !== null)
    .sort((a, b) => new Date(b.lastMessage.createdAt) - new Date(a.lastMessage.createdAt));
}

/**
 * Historique des messages entre deux utilisateurs, paginé.
 */
async function getConversationMessages(userId, otherUserId, { page = 1, limit = 30 } = {}) {
  const { Op } = require('sequelize');

  const offset = (page - 1) * limit;

  const { rows, count } = await Message.findAndCountAll({
    where: {
      [Op.or]: [
        { senderId: userId, receiverId: otherUserId },
        { senderId: otherUserId, receiverId: userId },
      ],
    },
    include: [{ model: User, as: 'sender', attributes: PUBLIC_SENDER_ATTRS }],
    order: [['createdAt', 'DESC']],
    limit,
    offset,
  });

  return {
    items: rows.reverse(), // du plus ancien au plus récent pour l'affichage chat
    total: count,
    page,
    hasMore: offset + rows.length < count,
  };
}

/**
 * Marque comme lus tous les messages envoyés par `fromUserId` et reçus par `userId`.
 * Retourne le nombre de messages mis à jour.
 */
async function markConversationAsRead(userId, fromUserId) {
  const [updatedCount] = await Message.update(
    { isRead: true },
    { where: { senderId: fromUserId, receiverId: userId, isRead: false } },
  );
  return updatedCount;
}

module.exports = {
  createMessage,
  getConversations,
  getConversationMessages,
  markConversationAsRead,
};