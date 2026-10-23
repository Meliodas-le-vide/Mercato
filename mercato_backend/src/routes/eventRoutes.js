const express = require('express');
const router = express.Router();

const { verifyToken } = require('../middlewares/authMiddleware');
const eventController = require('../controllers/eventController');
const uploadEventImage = require('../middlewares/uploadEventMiddleware');

router.post('/', verifyToken, uploadEventImage, eventController.createEvent);
router.get('/', verifyToken, eventController.getEvents);
router.get('/me', verifyToken, eventController.getMyEvents);
router.get('/:id', verifyToken, eventController.getEventById);

module.exports = router;