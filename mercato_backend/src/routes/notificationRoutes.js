const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middlewares/authMiddleware');
const notificationController = require('../controllers/notificationController');

router.get('/', verifyToken, notificationController.getMyNotifications);
router.get('/unread-count', verifyToken, notificationController.getUnreadCount);
router.patch('/read-all', verifyToken, notificationController.markAllAsRead);
router.patch('/:id/read', verifyToken, notificationController.markAsRead);

module.exports = router;
