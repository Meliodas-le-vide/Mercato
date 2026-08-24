const { PlayerProfile, User, Video, VideoLike, VideoComment } = require('../models/index');
const cloudinary = require('../../config/cloudinary');

const ALLOWED_PROFILE_FIELDS = [
  'position', 'strongFoot', 'birthDate', 'level', 'currentClub',
  'city', 'country', 'bio', 'height', 'weight',
];

const ALLOWED_STATS_FIELDS = ['goals', 'assists', 'matchesPlayed', 'cardsYellow', 'cardsRed'];

/**
 * GET /api/v1/players/me
 */
exports.getMe = async (req, res) => {
  try {
    const profile = await PlayerProfile.findOne({
      where: { userId: req.user.userId },
      include: [{ model: User, attributes: { exclude: ['password', 'refreshToken'] } }],
    });

    if (!profile) {
      return res.status(404).json({ error: 'Profil joueur introuvable.' });
    }

    return res.status(200).json({ data: profile });
  } catch (error) {
    console.error('Erreur getMe:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * PUT/PATCH /api/v1/players/me
 */
exports.updateMe = async (req, res) => {
  try {
    let profile = await PlayerProfile.findOne({ where: { userId: req.user.userId } });

    if (!profile) {
      // Crée le profil s'il n'existe pas encore (premier remplissage après inscription)
      profile = await PlayerProfile.create({ userId: req.user.userId });
    }

    for (const field of ALLOWED_PROFILE_FIELDS) {
      if (req.body[field] !== undefined) {
        profile[field] = req.body[field];
      }
    }

    // Marque le profil comme complet si les champs essentiels sont remplis
    profile.isProfileComplete = Boolean(
      profile.position && profile.level && profile.birthDate && profile.city
    );

    await profile.save();

    return res.status(200).json({ message: 'Profil mis à jour.', data: profile });
  } catch (error) {
    console.error('Erreur updateMe:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * POST /api/v1/players/me/avatar
 * Champ multipart "avatar"
 */
exports.uploadAvatar = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Aucune image reçue.' });
    }

    const user = await User.findByPk(req.user.userId);
    if (!user) {
      await cloudinary.uploader.destroy(req.file.filename, { resource_type: 'image' });
      return res.status(404).json({ error: 'Utilisateur introuvable.' });
    }

    if (user.avatarPublicId) {
      await cloudinary.uploader.destroy(user.avatarPublicId, { resource_type: 'image' });
    }

    user.Profile_image = req.file.path;
    user.avatarPublicId = req.file.filename;
    await user.save();

    return res.status(200).json({
      message: 'Photo de profil mise à jour.',
      profileImage: user.Profile_image,
    });
  } catch (error) {
    console.error('Erreur uploadAvatar:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * GET /api/v1/players/me/videos
 */
exports.getMyVideos = async (req, res) => {
  try {
    const videos = await Video.findAll({
      where: { userId: req.user.userId },
      order: [['createdAt', 'DESC']],
    });

    return res.status(200).json({ data: videos });
  } catch (error) {
    console.error('Erreur getMyVideos:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * GET /api/v1/players/me/stats
 */
exports.getStats = async (req, res) => {
  try {
    const profile = await PlayerProfile.findOne({
      where: { userId: req.user.userId },
      attributes: ALLOWED_STATS_FIELDS,
    });

    if (!profile) {
      return res.status(404).json({ error: 'Profil joueur introuvable.' });
    }

    return res.status(200).json({ data: profile });
  } catch (error) {
    console.error('Erreur getStats:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * PUT /api/v1/players/me/stats
 */
exports.updateStats = async (req, res) => {
  try {
    const profile = await PlayerProfile.findOne({ where: { userId: req.user.userId } });
    if (!profile) {
      return res.status(404).json({ error: 'Profil joueur introuvable.' });
    }

    for (const field of ALLOWED_STATS_FIELDS) {
      if (req.body[field] !== undefined) {
        profile[field] = req.body[field];
      }
    }

    await profile.save();

    return res.status(200).json({ message: 'Statistiques mises à jour.', data: profile });
  } catch (error) {
    console.error('Erreur updateStats:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * GET /api/v1/players/me/analytics
 * Vue d'ensemble de la performance des vidéos du joueur
 */
exports.getAnalytics = async (req, res) => {
  try {
    const videos = await Video.findAll({ where: { userId: req.user.userId } });

    const totals = videos.reduce(
      (acc, v) => {
        acc.totalViews += v.viewsCount;
        acc.totalLikes += v.likesCount;
        acc.totalComments += v.commentsCount;
        return acc;
      },
      { totalViews: 0, totalLikes: 0, totalComments: 0 }
    );

    const topVideo = videos.length
      ? videos.reduce((best, v) => (v.viewsCount > best.viewsCount ? v : best))
      : null;

    return res.status(200).json({
      data: {
        videosCount: videos.length,
        ...totals,
        topVideo: topVideo ? { id: topVideo.id, title: topVideo.title, viewsCount: topVideo.viewsCount } : null,
      },
    });
  } catch (error) {
    console.error('Erreur getAnalytics:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};