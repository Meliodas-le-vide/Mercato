const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middlewares/authMiddleware');
const favoriteController = require('../controllers/favoriteController');

router.get('/', verifyToken, favoriteController.getMyFavorites);
router.post('/:playerId', verifyToken, favoriteController.toggleFavorite);

module.exports = router;