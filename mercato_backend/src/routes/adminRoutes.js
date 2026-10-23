const express = require('express');
const router = express.Router();
const { verifyToken, authorizeRoles } = require('../middlewares/authMiddleware');

const adminController = require('../controllers/adminController');
const statsController = require('../controllers/statsController'); 

const adminOnly = authorizeRoles('ADMIN');

router.use(verifyToken);
router.use(adminOnly);

router.get('/stats', statsController.getDashboardStats);
router.get('/stats/views-chart', statsController.getViewsChart);
router.get('/stats/top-players', statsController.getTopPlayers);

router.get('/users', adminController.listUsers);
router.patch('/users/:id/ban', adminController.setUserBanned);
router.delete('/users/:id', adminController.deleteUser);
router.get('/users/:id', adminController.getUserById);

router.get('/recruiters/kyc/pending', adminController.listRecruiters);
router.get('/recruiters', adminController.listRecruiters);
router.patch('/recruiters/:id/verify', adminController.verifyRecruiter);
router.get('/recruiters/:id', adminController.getRecruiterById);

router.get('/reports', adminController.listReports);
router.patch('/reports/:id', adminController.reviewReport);

router.get('/videos', adminController.listVideos);
router.delete('/videos/:id', adminController.deleteVideo);

router.get('/events', adminController.listEvents);
router.delete('/events/:id', adminController.deleteEvent);

module.exports = router;