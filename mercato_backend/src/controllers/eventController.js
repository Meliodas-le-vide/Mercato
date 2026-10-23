const { Event, User } = require('../models/index');

const ORGANIZER_ATTRIBUTES = ['id', 'firstname', 'lastname', 'Profile_image'];

/**
 * POST /api/v1/events
 * Réservé aux recruteurs/agents de club.
 * Body: { title, description?, eventDate, location, organizerName }
 */
exports.createEvent = async (req, res) => {
  try {
    const userId = req.user.userId;

    const user = await User.findByPk(userId);
    if (!user || !['RECRUITER', 'CLUB_AGENT'].includes(user.role)) {
      return res.status(403).json({
        error: 'Seuls les recruteurs peuvent publier des événements.',
      });
    }

    // Récupération des champs du body
    const { title, description, eventDate, location, organizerName } = req.body;
    
    // Récupération de l'URL de l'image renvoyée par Cloudinary via Multer
    const imageUrl = req.file ? req.file.path : null;

    // Vérification des champs obligatoires (on vérifie imageUrl et non plus req.body.imageUrl)
    if (!title || !imageUrl || !eventDate || !location || !organizerName) {
      return res.status(400).json({
        error: 'title, image, eventDate, location et organizerName sont requis.',
      });
    }

    const parsedDate = new Date(eventDate);
    if (Number.isNaN(parsedDate.getTime())) {
      return res.status(400).json({ error: 'eventDate invalide.' });
    }

    const event = await Event.create({
      organizerId: userId,
      title: title.trim(),
      imageUrl, // Stockage de l'URL Cloudinary
      description: description ? description.trim() : null,
      eventDate: parsedDate,
      location: location.trim(),
      organizerName: organizerName.trim(),
    });

    return res.status(201).json({ message: 'Événement publié.', data: event });
  } catch (error) {
    console.error('Erreur createEvent:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * GET /api/v1/events
 * Liste paginée des événements à venir, triés du plus proche au plus
 * lointain. Accessible à tout utilisateur authentifié (joueurs, recruteurs).
 */
exports.getEvents = async (req, res) => {
  try {
    const { Op } = require('sequelize');
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const offset = (page - 1) * limit;

    const { count, rows } = await Event.findAndCountAll({
      where: { eventDate: { [Op.gte]: new Date() } },
      include: [{ model: User, as: 'organizer', attributes: ORGANIZER_ATTRIBUTES }],
      order: [['eventDate', 'ASC']],
      limit,
      offset,
    });

    return res.status(200).json({
      data: rows,
      pagination: { total: count, page, limit, totalPages: Math.ceil(count / limit) },
    });
  } catch (error) {
    console.error('Erreur getEvents:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * GET /api/v1/events/me
 * Événements publiés par le recruteur connecté (passés et à venir).
 */
exports.getMyEvents = async (req, res) => {
  try {
    const userId = req.user.userId;

    const events = await Event.findAll({
      where: { organizerId: userId },
      order: [['eventDate', 'DESC']],
    });

    return res.status(200).json({ data: events });
  } catch (error) {
    console.error('Erreur getMyEvents:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * GET /api/v1/events/:id
 */
exports.getEventById = async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);
    if (Number.isNaN(id)) {
      return res.status(400).json({ error: 'Identifiant invalide.' });
    }

    const event = await Event.findByPk(id, {
      include: [{ model: User, as: 'organizer', attributes: ORGANIZER_ATTRIBUTES }],
    });

    if (!event) {
      return res.status(404).json({ error: 'Événement introuvable.' });
    }

    return res.status(200).json({ data: event });
  } catch (error) {
    console.error('Erreur getEventById:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};