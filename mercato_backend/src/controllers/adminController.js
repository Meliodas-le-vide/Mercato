// src/controllers/adminController.js
const { Op } = require('sequelize');
const { RecruiterProfile, User, Report, Event, Video } = require('../models/index');

const RECRUITER_STATUSES = ['PENDING', 'VERIFIED', 'REJECTED'];
const REPORT_STATUSES = ['OPEN', 'REVIEWED', 'DISMISSED'];
const USER_ROLES = ['PLAYER', 'RECRUITER', 'USER', 'CLUB_AGENT', 'ADMIN'];

// ============================================================
// UTILISATEURS
// ============================================================

exports.listUsers = async (req, res) => {
  try {
    const { role, search } = req.query;
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 20;
    const offset = (page - 1) * limit;

    const where = {};
    if (role) {
      if (!USER_ROLES.includes(role)) {
        return res.status(400).json({ error: 'Rôle invalide.' });
      }
      where.role = role;
    }
    if (search && search.trim()) {
      const term = `%${search.trim()}%`;
      where[Op.or] = [
        { firstname: { [Op.like]: term } },
        { lastname: { [Op.like]: term } },
        { email: { [Op.like]: term } },
      ];
    }

    const { count, rows } = await User.findAndCountAll({
      where,
      attributes: { exclude: ['password', 'refreshToken'] },
      order: [['createdAt', 'DESC']],
      limit,
      offset,
    });

    return res.status(200).json({
      data: rows,
      pagination: {
        total: count,
        page,
        limit,
        totalPages: Math.ceil(count / limit),
      },
    });
  } catch (error) {
    console.error('Erreur listUsers:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

exports.getUserById = async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id, {
      attributes: { exclude: ['password', 'refreshToken'] },
    });

    if (!user) {
      return res.status(404).json({ error: 'Utilisateur introuvable.' });
    }

    return res.status(200).json({ data: user });
  } catch (error) {
    console.error('Erreur getUserById:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

exports.setUserBanned = async (req, res) => {
  try {
    const targetUserId = parseInt(req.params.id, 10);
    const currentAdminId = Number(req.user.userId);   
    const { banned, reason } = req.body;

    if (typeof banned !== 'boolean') {
      return res.status(400).json({ error: 'Le champ "banned" (booléen) est requis.' });
    }

    // Protection : on ne peut pas se bannir soi-même
    if (targetUserId === currentAdminId) {
      return res.status(403).json({
        error: 'Action interdite : vous ne pouvez pas vous bannir vous-même.',
      });
    }

    const user = await User.findByPk(targetUserId);
    if (!user) {
      return res.status(404).json({ error: 'Utilisateur introuvable.' });
    }

    if (user.role === 'ADMIN') {
      return res.status(400).json({
        error: 'Impossible de bannir un compte administrateur.',
      });
    }

    user.isBanned = banned;
    user.bannedReason = banned ? (reason?.trim() || null) : null;
    await user.save();

    return res.status(200).json({
      message: banned ? 'Utilisateur banni.' : 'Bannissement levé.',
      data: {
        id: user.id,
        firstname: user.firstname,
        lastname: user.lastname,
        email: user.email,
        role: user.role,
        isBanned: user.isBanned,
        bannedReason: user.bannedReason,
      },
    });
  } catch (error) {
    console.error('Erreur setUserBanned:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

exports.deleteUser = async (req, res) => {
  try {
    const targetUserId = parseInt(req.params.id, 10);
    const currentAdminId = Number(req.user.userId);  

    if (Number.isNaN(targetUserId)) {
      return res.status(400).json({ error: 'ID invalide.' });
    }

    // Protection : auto-suppression interdite
    if (targetUserId === currentAdminId) {
      return res.status(403).json({
        error: 'Action interdite : vous ne pouvez pas supprimer votre propre compte.',
      });
    }

    const user = await User.findByPk(targetUserId);
    if (!user) {
      return res.status(404).json({ error: 'Utilisateur introuvable.' });
    }

    if (user.role === 'ADMIN') {
      return res.status(403).json({
        error: 'Impossible de supprimer un compte administrateur.',
      });
    }

    await user.destroy();
    return res.status(200).json({ message: 'Utilisateur supprimé avec succès.' });
  } catch (error) {
    console.error('Erreur deleteUser:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};



exports.listRecruiters = async (req, res) => {
  try {
    const { status } = req.query;
    const where = {};
    if (status) {
      if (!RECRUITER_STATUSES.includes(status)) {
        return res.status(400).json({ error: 'Statut invalide.' });
      }
      where.verificationStatus = status;
    }

    const profiles = await RecruiterProfile.findAll({
      where,
      order: [['createdAt', 'ASC']],
      include: [
        {
          model: User,
          as: 'user',   //  alias cohérent avec index.js
          attributes: ['id', 'firstname', 'lastname', 'email', 'phone'],
        },
      ],
    });

    return res.status(200).json({ data: profiles });
  } catch (error) {
    console.error('Erreur listRecruiters:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

exports.getRecruiterById = async (req, res) => {
  try {
    const profile = await RecruiterProfile.findByPk(req.params.id, {
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'firstname', 'lastname', 'email', 'phone', 'Profile_image'],  // nom corrigé
        },
      ],
    });

    if (!profile) {
      return res.status(404).json({ error: 'Profil recruteur introuvable.' });
    }

    return res.status(200).json({ data: profile });
  } catch (error) {
    console.error('Erreur getRecruiterById:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

exports.verifyRecruiter = async (req, res) => {
  try {
    const { status, rejectionReason } = req.body;
    if (!['VERIFIED', 'REJECTED'].includes(status)) {
      return res.status(400).json({ error: 'Statut invalide, attendu VERIFIED ou REJECTED.' });
    }

    // Motif obligatoire si refus
    if (status === 'REJECTED' && (!rejectionReason || !rejectionReason.trim())) {
      return res.status(400).json({ error: 'Un motif de refus est requis.' });
    }

    const profile = await RecruiterProfile.findByPk(req.params.id);
    if (!profile) {
      return res.status(404).json({ error: 'Profil recruteur introuvable.' });
    }

    profile.verificationStatus = status;

    //  Trace qui a validé/refusé et quand
    if (status === 'VERIFIED') {
      profile.verifiedAt = new Date();
      profile.verifiedBy = req.user.userId;
      profile.rejectionReason = null;
    } else {
      profile.rejectedAt = new Date();
      profile.rejectedBy = req.user.userId;
      profile.rejectionReason = rejectionReason.trim();
    }

    await profile.save();

    return res.status(200).json({ message: 'Statut de vérification mis à jour.', data: profile });
  } catch (error) {
    console.error('Erreur verifyRecruiter:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

// ============================================================
// SIGNALEMENTS
// ============================================================

exports.listReports = async (req, res) => {
  try {
    const { status } = req.query;
    const where = {};
    if (status) {
      if (!REPORT_STATUSES.includes(status)) {
        return res.status(400).json({ error: 'Statut invalide.' });
      }
      where.status = status;
    }

    const reports = await Report.findAll({
      where,
      order: [['createdAt', 'DESC']],
      include: [
        { model: User, as: 'reporter', attributes: ['id', 'firstname', 'lastname', 'email'] },
        { model: User, as: 'target', attributes: ['id', 'firstname', 'lastname', 'email', 'role'] },
      ],
    });

    return res.status(200).json({ data: reports });
  } catch (error) {
    console.error('Erreur listReports:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

exports.reviewReport = async (req, res) => {
  try {
    const { status } = req.body;
    if (!['REVIEWED', 'DISMISSED'].includes(status)) {
      return res.status(400).json({ error: 'Statut invalide, attendu REVIEWED ou DISMISSED.' });
    }

    const report = await Report.findByPk(req.params.id);
    if (!report) {
      return res.status(404).json({ error: 'Signalement introuvable.' });
    }

    report.status = status;
    await report.save();

    return res.status(200).json({ message: 'Signalement mis à jour.', data: report });
  } catch (error) {
    console.error('Erreur reviewReport:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

// ============================================================
// VIDÉOS
// ============================================================

exports.listVideos = async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 20;
    const offset = (page - 1) * limit;

    const { count, rows } = await Video.findAndCountAll({
      order: [['createdAt', 'DESC']],
      limit,
      offset,
      include: [
        {
          model: User,
          as: 'author',
          attributes: ['id', 'firstname', 'lastname', 'Profile_image'],  
        },
      ],
    });

    return res.status(200).json({
      data: rows,
      pagination: {
        total: count,
        page,
        limit,
        totalPages: Math.ceil(count / limit),
      },
    });
  } catch (error) {
    console.error('Erreur listVideos:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

exports.deleteVideo = async (req, res) => {
  try {
    const video = await Video.findByPk(req.params.id);
    if (!video) {
      return res.status(404).json({ error: 'Vidéo introuvable.' });
    }

    // TODO : Supprimer de Cloudinary
    // const cloudinary = require('../config/cloudinary');
    // await cloudinary.uploader.destroy(video.videoPublicId, { resource_type: 'video' });

    await video.destroy();
    return res.status(200).json({ message: 'Vidéo supprimée.' });
  } catch (error) {
    console.error('Erreur deleteVideo:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

// ============================================================
// ÉVÉNEMENTS
// ============================================================

exports.listEvents = async (req, res) => {
  try {
    const events = await Event.findAll({
      order: [['eventDate', 'ASC']],
      include: [
        {
          model: User,
          as: 'organizer',
          attributes: ['id', 'firstname', 'lastname', 'email'],
        },
      ],
    });

    return res.status(200).json({ data: events });
  } catch (error) {
    console.error('Erreur listEvents:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

exports.deleteEvent = async (req, res) => {
  try {
    const event = await Event.findByPk(req.params.id);
    if (!event) {
      return res.status(404).json({ error: 'Événement introuvable.' });
    }

    await event.destroy();
    return res.status(200).json({ message: 'Événement supprimé.' });
  } catch (error) {
    console.error('Erreur deleteEvent:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};