const express = require('express');
const router = express.Router();
 
const uploadVideo = require('../middlewares/uploadMiddleware');
const { verifyToken } = require('../middlewares/authMiddleware');
const videoController = require('../controllers/videoController');
 
// --- Routes fixes en premier (évite les collisions avec /:id) ---
router.get('/feed', verifyToken, videoController.getFeed);
router.post('/upload', verifyToken, uploadVideo.single('video'), videoController.uploadVideo);
router.get('/my-videos', verifyToken, videoController.getMyVideos);
router.get('/player/:userId', verifyToken, videoController.getVideosByPlayer);
 
// --- Routes avec :id ---
router.get('/:id', verifyToken, videoController.getVideoById);
router.post('/:id/like', verifyToken, videoController.toggleLike);
router.post('/:id/views', verifyToken, videoController.incrementViews);
router.get('/:id/comments', verifyToken, videoController.getComments);
router.post('/:id/comments', verifyToken, videoController.addComment);
router.delete('/:id', verifyToken, videoController.deleteVideo);
router.patch('/:id', verifyToken, videoController.updateVideo);
 
module.exports = router;
