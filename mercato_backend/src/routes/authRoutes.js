const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController')
const { verifyToken } = require('../middlewares/authMiddleware');


router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/logout', authController.logout);
router.post('/forgotPassword', authController.forgotPassword);
router.post('/refreshToken', authController.refreshToken);

module.exports = router;