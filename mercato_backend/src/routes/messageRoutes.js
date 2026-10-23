const express = require('express');
const router = express.Router();

const { verifyToken } = require('../middlewares/authMiddleware');
const messageController = require('../controllers/messageController');

// Toutes les routes de messagerie nécessitent d'être authentifié (n'importe quel rôle)
router.get('/conversations', verifyToken, messageController.getConversations);
router.get('/conversations/:userId', verifyToken, messageController.getConversationMessages);
router.patch('/conversations/:userId/read', verifyToken, messageController.markAsRead);
router.post('/', verifyToken, messageController.sendMessage);

module.exports = router;