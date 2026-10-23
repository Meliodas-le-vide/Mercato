const { Op } = require('sequelize');
const Message = require('../models/Message');
const User = require('../models/User'); 

/**
 * Lit l'ID utilisateur depuis req.user peu importe le nom du champ utilisé
 * dans le payload JWT (id, userId, ou sub selon comment le token a été signé).
 * Idéalement, corrige plutôt authMiddleware pour toujours exposer req.user.id
 * de façon cohérente — ce helper est un filet de sécurité en attendant.
 */
function getUserId(req) {
  const raw = req.user?.id ?? req.user?.userId ?? req.user?.sub;
  const id = Number(raw);
  return Number.isNaN(id) ? null : id;
}

/**
 * GET /api/messages/conversations
 * Liste les conversations de l'utilisateur connecté : dernier message,
 * interlocuteur, et nombre de messages non lus.
 */
exports.getConversations = async (req, res) => {
  try {
    const userId = getUserId(req);
    if (!userId) {
      return res.status(401).json({ error: 'Utilisateur non authentifié.' });
    }

    //  Récupère tous les messages impliquant l'utilisateur, triés du plus récent au plus ancien
    const messages = await Message.findAll({
      where: {
        [Op.or]: [{ senderId: userId }, { receiverId: userId }],
      },
      order: [['createdAt', 'DESC']],
      include: [
        { model: User, as: 'sender', attributes: ['id', 'firstname', 'lastname', 'Profile_image'] },
        { model: User, as: 'receiver', attributes: ['id', 'firstname', 'lastname', 'Profile_image'] },
      ],
    });

    // Regroupe par interlocuteur (garde uniquement le message le plus récent par conversation)
    const conversationsMap = new Map();

    for (const msg of messages) {
      const otherUser = msg.senderId === userId ? msg.receiver : msg.sender;
      if (!otherUser) continue;

      if (!conversationsMap.has(otherUser.id)) {
        conversationsMap.set(otherUser.id, {
          otherUser: {
            id: otherUser.id,
            firstname: otherUser.firstname,
            lastname: otherUser.lastname,
            profileImage: otherUser.Profile_image,
          },
          lastMessage: {
            id: msg.id,
            content: msg.content,
            messageType: msg.messageType,
            senderId: msg.senderId,
            createdAt: msg.createdAt,
          },
          unreadCount: 0,
        });
      }

      // Compte les non-lus : messages reçus par userId et pas encore lus
      if (msg.receiverId === userId && !msg.isRead) {
        conversationsMap.get(otherUser.id).unreadCount += 1;
      }
    }

    const conversations = Array.from(conversationsMap.values()).sort(
      (a, b) => new Date(b.lastMessage.createdAt) - new Date(a.lastMessage.createdAt)
    );

    return res.status(200).json({ data: conversations });
  } catch (error) {
    console.error('Erreur getConversations:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * GET /api/messages/:otherUserId
 * Historique des messages entre l'utilisateur connecté et otherUserId.
 * Supporte la pagination via ?page=1&limit=30
 */
exports.getConversationMessages = async (req, res) => {
  try {
    const userId = getUserId(req);
    if (!userId) {
      return res.status(401).json({ error: 'Utilisateur non authentifié.' });
    }
    const otherUserId = parseInt(req.params.userId, 10);
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 30;

    if (Number.isNaN(otherUserId)) {
      return res.status(400).json({ error: 'ID utilisateur invalide.' });
    }

    const messages = await Message.findAll({
      where: {
        [Op.or]: [
          { senderId: userId, receiverId: otherUserId },
          { senderId: otherUserId, receiverId: userId },
        ],
      },
      order: [['createdAt', 'DESC']],
      limit,
      offset: (page - 1) * limit,
    });

    // On renvoie du plus ancien au plus récent pour l'affichage du chat
    return res.status(200).json({ data: messages.reverse() });
  } catch (error) {
    console.error('Erreur getConversationHistory:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * POST /api/messages
 * Envoie un message (fallback REST, utilisé aussi en parallèle du Socket.io
 * si tu veux garantir la persistance même si le socket est déconnecté).
 * Body: { receiverId, content, messageType?, relatedVideoId? }
 */
exports.sendMessage = async (req, res) => {
  try {
    const senderId = getUserId(req);
    if (!senderId) {
      return res.status(401).json({ error: 'Utilisateur non authentifié.' });
    }
    const { receiverId, content, messageType, relatedVideoId } = req.body;

    if (!receiverId || !content || !content.trim()) {
      return res.status(400).json({ error: 'receiverId et content sont requis.' });
    }

    if (Number(receiverId) === senderId) {
      return res.status(400).json({ error: 'Vous ne pouvez pas vous envoyer un message à vous-même.' });
    }

    const receiver = await User.findByPk(receiverId);
    if (!receiver) {
      return res.status(404).json({ error: 'Destinataire introuvable.' });
    }

    const message = await Message.create({
      senderId,
      receiverId: Number(receiverId),
      content: content.trim(),
      messageType: messageType || 'text',
      relatedVideoId: relatedVideoId || null,
    });

    return res.status(201).json({ data: message });
  } catch (error) {
    console.error('Erreur sendMessage:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * PATCH /api/messages/:otherUserId/read
 * Marque comme lus tous les messages reçus de otherUserId.
 */
exports.markAsRead = async (req, res) => {
  try {
    const userId = getUserId(req);
    if (!userId) {
      return res.status(401).json({ error: 'Utilisateur non authentifié.' });
    }
    const otherUserId = parseInt(req.params.userId, 10); 

    await Message.update(
      { isRead: true },
      {
        where: {
          senderId: otherUserId,
          receiverId: userId,
          isRead: false,
        },
      }
    );

    return res.status(200).json({ message: 'Conversation marquée comme lue.' });
  } catch (error) {
    console.error('Erreur markConversationAsRead:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};