const express = require('express');
const router = express.Router();

const { verifyToken } = require('../middlewares/authMiddleware');
const reportController = require('../controllers/reportController');

router.post('/', verifyToken, reportController.createReport);

module.exports = router;
