const express = require('express');
const router = express.Router();

const { verifyToken, authorizeRoles } = require('../middlewares/authMiddleware');
const recruiterController = require('../controllers/recruiterProfileController');

const recruiterOnly = authorizeRoles('RECRUITER', 'CLUB_AGENT');

router.get('/me', verifyToken, recruiterOnly, recruiterController.getMe);
router.put('/me', verifyToken, recruiterOnly, recruiterController.updateMe);
router.patch('/me', verifyToken, recruiterOnly, recruiterController.updateMe);

module.exports = router;
