const express = require('express');
const router = express.Router();

const { verifyToken, authorizeRoles } = require('../middlewares/authMiddleware');
const adminController = require('../controllers/adminController');

const adminOnly = authorizeRoles('ADMIN');

router.get('/recruiters', verifyToken, adminOnly, adminController.listRecruiters);
router.patch('/recruiters/:id/verify', verifyToken, adminOnly, adminController.verifyRecruiter);

router.get('/reports', verifyToken, adminOnly, adminController.listReports);
router.patch('/reports/:id', verifyToken, adminOnly, adminController.reviewReport);

module.exports = router;
