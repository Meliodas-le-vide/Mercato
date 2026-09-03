const { Notification, User, Video } = require('../models/index');

const ACTOR_ATTRS = ['id', 'firstname', 'lastname', 'Profile_image'];

/**
 * GET /api/v1/notifications
 * Liste paginée des notifications de l'utilisateur connecté, plus récentes en premier.
 */
exports.getMyNotifications = async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 20;
    const offset = (page - 1) * limit;

    const { count, rows } = await Notification.findAndCountAll({
      where: { recipientId: req.user.userId },
      order: [['createdAt', 'DESC']],
      limit,
      offset,
      include: [
        { model: User, as: 'actor', attributes: ACTOR_ATTRS },
        { model: Video, as: 'video', attributes: ['id', 'title', 'thumbnailUrl'] },
      ],
    });

    return res.status(200).json({
      data: rows,
      pagination: { total: count, page, limit, totalPages: Math.ceil(count / limit) },
    });
  } catch (error) {
    console.error('Erreur getMyNotifications:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * GET /api/v1/notifications/unread-count
 */
exports.getUnreadCount = async (req, res) => {
  try {
    const count = await Notification.count({
      where: { recipientId: req.user.userId, isRead: false },
    });
    return res.status(200).json({ count });
  } catch (error) {
    console.error('Erreur getUnreadCount:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * PATCH /api/v1/notifications/:id/read
 */
exports.markAsRead = async (req, res) => {
  try {
    const notification = await Notification.findOne({
      where: { id: req.params.id, recipientId: req.user.userId },
    });
    if (!notification) {
      return res.status(404).json({ error: 'Notification introuvable.' });
    }

    if (!notification.isRead) {
      notification.isRead = true;
      await notification.save();
    }

    return res.status(200).json({ data: notification });
  } catch (error) {
    console.error('Erreur markAsRead:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * PATCH /api/v1/notifications/read-all
 */
exports.markAllAsRead = async (req, res) => {
  try {
    await Notification.update(
      { isRead: true },
      { where: { recipientId: req.user.userId, isRead: false } },
    );
    return res.status(200).json({ message: 'Notifications marquées comme lues.' });
  } catch (error) {
    console.error('Erreur markAllAsRead:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};
