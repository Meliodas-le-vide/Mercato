const { Op } = require('sequelize');
const { Video, VideoLike, VideoComment, User, Favorite, Notification, PlayerProfile } = require('../models/index');
const cloudinary = require('../../config/cloudinary');

const PUBLIC_AUTHOR_ATTRS = ['id', 'firstname', 'lastname', 'Profile_image', 'role'];

/**
 * Inclusion de l'auteur avec le poste de son profil joueur.
 * Si `positions` est fourni, seules les vidéos dont l'auteur occupe
 * l'un de ces postes sont gardées (jointure obligatoire).
 */
function authorInclude(positions) {
  const filtered = Array.isArray(positions) && positions.length > 0;
  return {
    model: User,
    as: 'author',
    attributes: PUBLIC_AUTHOR_ATTRS,
    required: filtered,
    include: [
      {
        model: PlayerProfile,
        as: 'playerProfile',
        attributes: ['position'],
        required: filtered,
        ...(filtered ? { where: { position: { [Op.in]: positions } } } : {}),
      },
    ],
  };
}

/**
 * Ajoute `isLiked` (bool) à une liste de vidéos, calculé pour l'utilisateur courant,
 * en une seule requête plutôt qu'un aller-retour par vidéo.
 */
async function attachIsLiked(videos, userId) {
  const list = Array.isArray(videos) ? videos : [videos];
  if (list.length === 0) return Array.isArray(videos) ? [] : videos;

  const likes = await VideoLike.findAll({
    where: { userId, videoId: { [Op.in]: list.map((v) => v.id) } },
    attributes: ['videoId'],
  });
  const likedIds = new Set(likes.map((l) => l.videoId));

  const withFlag = list.map((v) => {
    const plain = v.toJSON();
    plain.isLiked = likedIds.has(v.id);
    // Le poste affiché/filtré est celui du profil actuel de l'auteur.
    const authorPosition = plain.author?.playerProfile?.position;
    if (authorPosition) plain.position = authorPosition;
    if (plain.author) delete plain.author.playerProfile;
    return plain;
  });

  return Array.isArray(videos) ? withFlag : withFlag[0];
}

/**
 * Notifie tous les utilisateurs ayant mis l'auteur de la vidéo en favori.
 */
async function notifyFansOfNewVideo(video) {
  const fans = await Favorite.findAll({ where: { playerId: video.userId } });
  if (fans.length === 0) return;

  const author = await User.findByPk(video.userId, { attributes: ['firstname', 'lastname'] });
  const authorName = author ? `${author.firstname} ${author.lastname}`.trim() : 'Un joueur que tu suis';

  await Notification.bulkCreate(
    fans.map((fan) => ({
      recipientId: fan.userId,
      actorId: video.userId,
      type: 'NEW_VIDEO',
      videoId: video.id,
      message: `${authorName} a publié une nouvelle vidéo : "${video.title}"`,
    })),
  );
}

/**
 * GET /api/v1/videos/feed
 * Query params: filter=trending|recent, page, limit,
 *   position=<ENUM> ou liste séparée par des virgules (ex : LATERAL_DROIT,LATERAL_GAUCHE)
 *   → vidéos dont l'AUTEUR occupe ce poste dans son profil joueur.
 */
exports.getFeed = async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const offset = (page - 1) * limit;
    const { filter, position } = req.query;

    // Filtre sur le poste du profil de l'auteur (et non sur la vidéo).
    const positions = position
      ? String(position).split(',').map((p) => p.trim()).filter(Boolean)
      : [];

    let order = [['createdAt', 'DESC']]; // défaut : récent
    if (filter === 'trending') {
      order = [['likesCount', 'DESC'], ['viewsCount', 'DESC']];
    }

    const { count, rows } = await Video.findAndCountAll({
      order,
      limit,
      offset,
      distinct: true,
      include: [authorInclude(positions)],
    });

    const data = await attachIsLiked(rows, req.user.userId);

    return res.status(200).json({
      data,
      pagination: {
        total: count,
        page,
        limit,
        totalPages: Math.ceil(count / limit),
      },
    });
  } catch (error) {
    console.error('Erreur getFeed:', error);
    return res.status(500).json({ error: 'Erreur serveur lors du chargement du feed.' });
  }
};

/**
 * GET /api/v1/videos/:id
 */
exports.getVideoById = async (req, res) => {
  try {
    const video = await Video.findByPk(req.params.id, {
      include: [authorInclude()],
    });

    if (!video) {
      return res.status(404).json({ error: 'Vidéo introuvable.' });
    }

    const data = await attachIsLiked(video, req.user.userId);

    return res.status(200).json({ data });
  } catch (error) {
    console.error('Erreur getVideoById:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * POST /api/v1/videos/:id/like
 * Toggle : like si pas encore liké, unlike sinon.
 */
exports.toggleLike = async (req, res) => {
  try {
    const videoId = req.params.id;
    const userId = req.user.userId;

    const video = await Video.findByPk(videoId);
    if (!video) {
      return res.status(404).json({ error: 'Vidéo introuvable.' });
    }

    const existingLike = await VideoLike.findOne({ where: { userId, videoId } });

    if (existingLike) {
      await existingLike.destroy();
      await video.decrement('likesCount');
      return res.status(200).json({ liked: false, likesCount: video.likesCount - 1 });
    } else {
      await VideoLike.create({ userId, videoId });
      await video.increment('likesCount');
      return res.status(200).json({ liked: true, likesCount: video.likesCount + 1 });
    }
  } catch (error) {
    console.error('Erreur toggleLike:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * POST /api/v1/videos/:id/views
 */
exports.incrementViews = async (req, res) => {
  try {
    const video = await Video.findByPk(req.params.id);
    if (!video) {
      return res.status(404).json({ error: 'Vidéo introuvable.' });
    }

    await video.increment('viewsCount');

    return res.status(200).json({ viewsCount: video.viewsCount + 1 });
  } catch (error) {
    console.error('Erreur incrementViews:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * GET /api/v1/videos/:id/comments
 */
exports.getComments = async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 20;
    const offset = (page - 1) * limit;

    const { count, rows } = await VideoComment.findAndCountAll({
      where: { videoId: req.params.id },
      order: [['createdAt', 'DESC']],
      limit,
      offset,
      include: [{ model: User, as: 'author', attributes: PUBLIC_AUTHOR_ATTRS }],
    });

    return res.status(200).json({
      data: rows,
      pagination: { total: count, page, limit, totalPages: Math.ceil(count / limit) },
    });
  } catch (error) {
    console.error('Erreur getComments:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * POST /api/v1/videos/:id/comments
 * Body: { content }
 */
exports.addComment = async (req, res) => {
  try {
    const { content } = req.body;
    if (!content || !content.trim()) {
      return res.status(400).json({ error: 'Le commentaire ne peut pas être vide.' });
    }

    const video = await Video.findByPk(req.params.id);
    if (!video) {
      return res.status(404).json({ error: 'Vidéo introuvable.' });
    }

    const comment = await VideoComment.create({
      userId: req.user.userId,
      videoId: video.id,
      content: content.trim(),
    });

    await video.increment('commentsCount');

    const fullComment = await VideoComment.findByPk(comment.id, {
      include: [{ model: User, as: 'author', attributes: PUBLIC_AUTHOR_ATTRS }],
    });

    return res.status(201).json({ data: fullComment });
  } catch (error) {
    console.error('Erreur addComment:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * POST /api/v1/videos/upload
 * Champ multipart "video" + body: title, description, tags (JSON string ou CSV), position
 */
exports.uploadVideo = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Aucun fichier vidéo reçu.' });
    }

    const { title, description, tags, position } = req.body;
    if (!title || !title.trim()) {
      // Le fichier est déjà sur Cloudinary à ce stade : on le supprime pour éviter un déchet
      await cloudinary.uploader.destroy(req.file.filename, { resource_type: 'video' });
      return res.status(400).json({ error: 'Le titre est obligatoire.' });
    }

    let parsedTags = [];
    if (tags) {
      try {
        parsedTags = typeof tags === 'string' ? JSON.parse(tags) : tags;
      } catch {
        parsedTags = String(tags).split(',').map((t) => t.trim()).filter(Boolean);
      }
    }

    const video = await Video.create({
      userId: req.user.userId,
      title: title.trim(),
      description: description ? description.trim() : null,
      tags: parsedTags,
      position: position || null,
      videoUrl: req.file.path,
      videoPublicId: req.file.filename,
    });

    await notifyFansOfNewVideo(video);

    return res.status(201).json({ message: 'Vidéo publiée avec succès.', data: video });
  } catch (error) {
    console.error('Erreur uploadVideo:', error);
    return res.status(500).json({ error: 'Erreur serveur lors de l\'upload.' });
  }
};

/**
 * DELETE /api/v1/videos/:id
 */
exports.deleteVideo = async (req, res) => {
  try {
    const video = await Video.findByPk(req.params.id);
    if (!video) {
      return res.status(404).json({ error: 'Vidéo introuvable.' });
    }

    if (video.userId !== req.user.userId) {
      return res.status(403).json({ error: 'Tu ne peux pas supprimer la vidéo d\'un autre joueur.' });
    }

    await cloudinary.uploader.destroy(video.videoPublicId, { resource_type: 'video' });
    await video.destroy(); // les likes/commentaires liés sont supprimés en cascade

    return res.status(200).json({ message: 'Vidéo supprimée.' });
  } catch (error) {
    console.error('Erreur deleteVideo:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * PATCH /api/v1/videos/:id
 * Body: { description?, tags? }
 */
exports.updateVideo = async (req, res) => {
  try {
    const video = await Video.findByPk(req.params.id);
    if (!video) {
      return res.status(404).json({ error: 'Vidéo introuvable.' });
    }

    if (video.userId !== req.user.userId) {
      return res.status(403).json({ error: 'Tu ne peux pas modifier la vidéo d\'un autre joueur.' });
    }

    const { description, tags } = req.body;
    if (description !== undefined) video.description = description;
    if (tags !== undefined) {
      video.tags = typeof tags === 'string' ? JSON.parse(tags) : tags;
    }

    await video.save();

    return res.status(200).json({ message: 'Vidéo mise à jour.', data: video });
  } catch (error) {
    console.error('Erreur updateVideo:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};


/**
 * GET /api/v1/videos/player/:userId
 * Vidéos publiées par un joueur donné, consultables par n'importe quel
 * utilisateur authentifié (fan, joueur ou recruteur) — permet notamment aux
 * recruteurs de visionner la vidéothèque d'un joueur repéré via la recherche.
 */
exports.getVideosByPlayer = async (req, res) => {
  try {
    const targetUserId = parseInt(req.params.userId, 10);
    if (!Number.isInteger(targetUserId)) {
      return res.status(400).json({ error: 'Identifiant de joueur invalide.' });
    }

    const player = await User.findByPk(targetUserId, { attributes: PUBLIC_AUTHOR_ATTRS });
    if (!player) {
      return res.status(404).json({ error: 'Joueur introuvable.' });
    }

    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 20;
    const offset = (page - 1) * limit;

    const { count, rows } = await Video.findAndCountAll({
      where: { userId: targetUserId },
      order: [['createdAt', 'DESC']],
      limit,
      offset,
      include: [authorInclude()],
    });

    const data = await attachIsLiked(rows, req.user.userId);

    return res.status(200).json({
      data,
      pagination: { total: count, page, limit, totalPages: Math.ceil(count / limit) },
    });
  } catch (error) {
    console.error('Erreur getVideosByPlayer:', error);
    return res.status(500).json({ error: 'Erreur serveur lors du chargement des vidéos du joueur.' });
  }
};

/**
 * GET /api/v1/videos/my-videos
 * Vidéos du joueur connecté (via le token, pas d'userId dans l'URL -> évite l'IDOR)
 */
exports.getMyVideos = async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const offset = (page - 1) * limit;

    const { count, rows } = await Video.findAndCountAll({
      where: { userId: req.user.userId },
      order: [['createdAt', 'DESC']],
      limit,
      offset,
      include: [
        {
          model: User,
          as: 'author',
          attributes: { exclude: ['password', 'refreshToken'] },
        },
      ],
    });

    const data = await attachIsLiked(rows, req.user.userId);

    return res.status(200).json({
      data,
      pagination: {
        total: count,
        page,
        limit,
        totalPages: Math.ceil(count / limit),
      },
    });
  } catch (error) {
    console.error('Erreur getMyVideos:', error);
    return res.status(500).json({ error: 'Erreur serveur lors du chargement de tes vidéos.' });
  }
};