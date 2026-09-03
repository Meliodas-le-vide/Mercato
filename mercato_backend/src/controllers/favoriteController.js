const { Favorite, User, PlayerProfile, Notification } = require('../models/index');

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

      const fan = await User.findByPk(userId, { attributes: ['id', 'firstname', 'lastname'] });
      await Notification.create({
        recipientId: playerId,
        actorId: userId,
        type: 'NEW_FAVORITE',
        message: `${fan?.firstname ?? 'Un fan'} ${fan?.lastname ?? ''}`.trim() + ' t\'a ajouté à ses favoris.',
      });

      return res.status(201).json({ favorited: true });
    }
  } catch (error) {
    console.error('Erreur toggleFavorite:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * GET /api/v1/favorites
 * Liste paginée des joueurs mis en favori par l'utilisateur connecté,
 * plus récemment ajoutés en premier.
 */
exports.getMyFavorites = async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 20;
    const offset = (page - 1) * limit;

    const { count, rows: favorites } = await Favorite.findAndCountAll({
      where: { userId: req.user.userId },
      order: [['createdAt', 'DESC']],
      limit,
      offset,
    });

    const playerIds = favorites.map((f) => f.playerId);

    const profiles = await PlayerProfile.findAll({
      where: { userId: playerIds },
      include: [{ model: User, attributes: ['id', 'firstname', 'lastname', 'Profile_image'] }],
    });

    // PlayerProfile.findAll(IN ...) ne garantit pas l'ordre : on retrie selon
    // l'ordre des favoris (plus récent en premier) avant de renvoyer la page.
    const profileByUserId = new Map(profiles.map((p) => [p.userId, p]));
    const orderedProfiles = playerIds
      .map((id) => profileByUserId.get(id))
      .filter(Boolean);

    const data = orderedProfiles.map((profile) => ({
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
      User: {
        id: profile.User.id,
        firstname: profile.User.firstname,
        lastname: profile.User.lastname,
        Profile_image: profile.User.Profile_image,
      },
      isFavorited: true,
    }));

    return res.status(200).json({
      data,
      pagination: { total: count, page, limit, totalPages: Math.ceil(count / limit) },
    });
  } catch (error) {
    console.error('Erreur getMyFavorites:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};