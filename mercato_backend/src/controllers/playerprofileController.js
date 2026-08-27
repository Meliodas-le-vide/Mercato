const { PlayerProfile, User, Video, VideoLike, VideoComment, Favorite, sequelize} = require('../models/index');
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


const { Op, Sequelize } = require('sequelize');
/**
 * GET /api/v1/players/search
 * Query params: q, position, level, city, country, minAge, maxAge,
 *               minHeight, maxHeight, minWeight, maxWeight, page, limit
 *
 * - Sans aucun filtre : retourne tous les joueurs complets, en ordre aléatoire.
 * - Chaque filtre avancé (position, level, city, country, age, height, weight)
 *   est indépendant et combiné en AND avec les autres.
 * - `q` (barre de recherche unique) cherche dans prénom OU nom OU poste (OR interne).
 */
exports.searchPlayers = async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 20;
    const offset = (page - 1) * limit;

    const {
      q,
      position,
      level,
      city,
      country,
      minAge,
      maxAge,
      minHeight,
      maxHeight,
      minWeight,
      maxWeight,
    } = req.query;

    const where = { isProfileComplete: true };

    if (position) where.position = position;
    if (level) where.level = level;
    if (city) where.city = { [Op.like]: `%${city.trim()}%` };
    if (country) where.country = { [Op.like]: `%${country.trim()}%` };

    if (minHeight || maxHeight) {
      where.height = {};
      if (minHeight) where.height[Op.gte] = parseInt(minHeight, 10);
      if (maxHeight) where.height[Op.lte] = parseInt(maxHeight, 10);
    }

    if (minWeight || maxWeight) {
      where.weight = {};
      if (minWeight) where.weight[Op.gte] = parseInt(minWeight, 10);
      if (maxWeight) where.weight[Op.lte] = parseInt(maxWeight, 10);
    }

    if (minAge || maxAge) {
      const today = new Date();
      where.birthDate = {};
      if (maxAge) {
        const minBirthDate = new Date(today);
        minBirthDate.setFullYear(today.getFullYear() - parseInt(maxAge, 10) - 1);
        where.birthDate[Op.gte] = minBirthDate;
      }
      if (minAge) {
        const maxBirthDate = new Date(today);
        maxBirthDate.setFullYear(today.getFullYear() - parseInt(minAge, 10));
        where.birthDate[Op.lte] = maxBirthDate;
      }
    }

    // Barre de recherche unique : prénom OU nom OU poste
    let includeRequired = false;
    if (q && q.trim() !== '') {
      const searchTerm = `%${q.trim()}%`;
      includeRequired = true;
      where[Op.and] = [
        {
          [Op.or]: [
            { position: { [Op.like]: searchTerm } },
            { '$User.firstname$': { [Op.like]: searchTerm } },
            { '$User.lastname$': { [Op.like]: searchTerm } },
          ],
        },
      ];
    }

    // Tri aléatoire, compatible MySQL et PostgreSQL
    const dialect = sequelize.getDialect();
    const randomOrder =
      dialect === 'postgres'
        ? Sequelize.literal('RANDOM()')
        : Sequelize.literal('RAND()');

    const { count, rows } = await PlayerProfile.findAndCountAll({
      where,
      include: [
        {
          model: User,
          required: includeRequired,
          attributes: ['id', 'firstname', 'lastname', 'Profile_image'],
        },
      ],
      limit,
      offset,
      order: randomOrder,
      distinct: true,
      subQuery: false,
    });

    let favoriteIds = new Set();
    if (req.user && req.user.userId) {
      const myFavorites = await Favorite.findAll({
        where: { userId: req.user.userId },
        attributes: ['playerId'],
      });
      favoriteIds = new Set(myFavorites.map((f) => f.playerId));
    }

    const data = rows.map((profile) => ({
      id: profile.id,
      userId: profile.userId,
      position: profile.position,
      strongFoot: profile.strongFoot,
      birthDate: profile.birthDate,
      level: profile.level,
      currentClub: profile.currentClub,
      city: profile.city,
      country: profile.country,
      bio: profile.bio,
      height: profile.height,
      weight: profile.weight,
      goals: profile.goals || 0,
      assists: profile.assists || 0,
      matchesPlayed: profile.matchesPlayed || 0,
      cardsYellow: profile.cardsYellow || 0,
      cardsRed: profile.cardsRed || 0,
      isProfileComplete: profile.isProfileComplete,
      User: profile.User
        ? {
            id: profile.User.id,
            firstname: profile.User.firstname,
            lastname: profile.User.lastname,
            Profile_image: profile.User.Profile_image,
          }
        : {},
      isFavorited: favoriteIds.has(profile.userId),
    }));

    return res.status(200).json({
      data,
      pagination: { total: count, page, limit, totalPages: Math.ceil(count / limit) },
    });
  } catch (error) {
    console.error('Erreur searchPlayers:', error);
    return res.status(500).json({ error: 'Erreur serveur lors de la recherche.' });
  }
};