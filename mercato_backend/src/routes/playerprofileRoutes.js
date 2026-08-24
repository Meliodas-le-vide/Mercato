const express = require('express');
const router = express.Router();

const uploadImage = require('../middlewares/uploadimageMidlware');
const { verifyToken } = require('../middlewares/authMiddleware');
const playerController = require('../controllers/playerprofileController');

router.get('/me', verifyToken, playerController.getMe);
router.put('/me', verifyToken, playerController.updateMe);
router.patch('/me', verifyToken, playerController.updateMe); 
router.post('/me/avatar', verifyToken, uploadImage.single('avatar'), playerController.uploadAvatar);
router.get('/me/videos', verifyToken, playerController.getMyVideos);
router.get('/me/stats', verifyToken, playerController.getStats);
router.put('/me/stats', verifyToken, playerController.updateStats);
router.get('/me/analytics', verifyToken, playerController.getAnalytics);

module.exports = router;