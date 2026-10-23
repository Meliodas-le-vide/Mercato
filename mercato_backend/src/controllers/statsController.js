const { Op, fn, col, literal } = require('sequelize');
const {
  sequelize,        
  User,
  Video,
  Report,
  RecruiterProfile,
  Event,
} = require('../models/index');

/**
 * GET /api/v1/admin/stats
 */
exports.getDashboardStats = async (req, res) => {
  try {
    const [
      totalPlayers,
      totalRecruiters,
      totalVideos,
      totalReports,
      pendingKyc,
      upcomingEvents,
    ] = await Promise.all([
      User.count({ where: { role: 'PLAYER' } }),
      User.count({ where: { role: 'RECRUITER' } }),
      Video.count(),
      Report.count({ where: { status: 'OPEN' } }),
      RecruiterProfile.count({ where: { verificationStatus: 'PENDING' } }),
      Event.count({ where: { eventDate: { [Op.gt]: new Date() } } }),
    ]);

    return res.status(200).json({
      data: {
        totalPlayers,
        totalRecruiters,
        totalVideos,
        totalReports,
        pendingKyc,
        upcomingEvents,
      },
    });
  } catch (error) {
    console.error('Erreur getDashboardStats:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * GET /api/v1/admin/stats/views-chart?period=30d
 */
exports.getViewsChart = async (req, res) => {
  try {
    const period = req.query.period || '30d';

    const days =
      { '7d': 7, '30d': 30, '90d': 90, '365d': 365 }[period] || 30;

    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const videos = await Video.findAll({
      attributes: ['createdAt', 'viewsCount'],
      where: { createdAt: { [Op.gte]: startDate } },
      order: [['createdAt', 'ASC']],
    });

    // Agrégation par jour
    const dayMap = {};
    videos.forEach((video) => {
      const day = new Date(video.createdAt).toISOString().split('T')[0];
      dayMap[day] = (dayMap[day] || 0) + video.viewsCount;
    });

    // Construction des labels/valeurs
    const labels = [];
    const values = [];
    const currentDate = new Date(startDate);

    while (currentDate <= new Date()) {
      const key = currentDate.toISOString().split('T')[0];
      const dayLabel = currentDate.toLocaleDateString('fr-FR', {
        day: '2-digit',
        month: 'short',
      });

      labels.push(dayLabel);
      values.push(dayMap[key] || 0);

      currentDate.setDate(currentDate.getDate() + 1);
    }

    return res.status(200).json({ data: { labels, values } });
  } catch (error) {
    console.error('Erreur getViewsChart:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * GET /api/v1/admin/stats/top-players
 * Top 5 des joueurs avec le plus de vues cumulées.
 * Utilise une requête SQL brute pour éviter les conflits d'alias Sequelize.
 */
exports.getTopPlayers = async (req, res) => {
  try {
    const [results] = await sequelize.query(`
      SELECT
        u.id,
        u.firstname,
        u.lastname,
        u.Profile_image AS profileImage,
        SUM(v.viewsCount) AS totalViews,
        COUNT(v.id) AS videoCount
      FROM users u
      INNER JOIN videos v ON v.userId = u.id
      WHERE u.role = 'PLAYER'
      GROUP BY u.id
      ORDER BY totalViews DESC
      LIMIT 5
    `);

    return res.status(200).json({ data: results });
  } catch (error) {
    console.error('Erreur getTopPlayers:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};