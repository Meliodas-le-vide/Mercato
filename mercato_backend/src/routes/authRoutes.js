const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController')
const { verifyToken } = require('../middlewares/authMiddleware');
const rateLimit = require('express-rate-limit');

// Limite les abus sur la réinitialisation (spam d'e-mails, force brute du code).
const resetLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 10,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: { message: 'Trop de demandes. Réessaie dans quelques minutes.' },
});


router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/logout', authController.logout);
router.post('/forgotPassword', resetLimiter, authController.forgotPassword);
router.post('/verifyResetCode', resetLimiter, authController.verifyResetCode);
router.post('/resetPassword', resetLimiter, authController.resetPassword);
router.post('/refreshToken', authController.refreshToken);

module.exports = router;