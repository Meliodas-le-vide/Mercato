const { Favorite, User, PlayerProfile } = require('../models/index');

/**
 * POST /api/v1/favorites/:playerId
 * Toggle favori/défavori
 */
exports.toggleFavorite = async (req, res) => {
  try {
    const playerId = parseInt(req.params.playerId, 10);
    const userId = req.user.userId;

    if (playerId === userId) {
      return res.status(400).json({ error: 'Tu ne peux pas te mettre toi-même en favori.' });
    }

    const player = await User.findByPk(playerId);
    if (!player) {
      return res.status(404).json({ error: 'Joueur introuvable.' });
    }

    const existing = await Favorite.findOne({ where: { userId, playerId } });

    if (existing) {
      await existing.destroy();
      return res.status(200).json({ favorited: false });
    } else {
      await Favorite.create({ userId, playerId });
      return res.status(201).json({ favorited: true });
    }
  } catch (error) {
    console.error('Erreur toggleFavorite:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * GET /api/v1/favorites
 * Liste des joueurs mis en favori par l'utilisateur connecté
 */
exports.getMyFavorites = async (req, res) => {
  try {
    const favorites = await Favorite.findAll({
      where: { userId: req.user.userId },
      order: [['createdAt', 'DESC']],
    });

    const playerIds = favorites.map((f) => f.playerId);

    const profiles = await PlayerProfile.findAll({
      where: { userId: playerIds },
      include: [{ model: User, attributes: ['id', 'firstname', 'lastname', 'Profile_image'] }],
    });

    const data = profiles.map((profile) => ({
      userId: profile.userId,
      firstname: profile.User.firstname,
      lastname: profile.User.lastname,
      Profile_image: profile.User.Profile_image,
      position: profile.position,
      level: profile.level,
      city: profile.city,
      country: profile.country,
      currentClub: profile.currentClub,
      birthDate: profile.birthDate,
      isFavorited: true,
    }));

    return res.status(200).json({ data });
  } catch (error) {
    console.error('Erreur getMyFavorites:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};