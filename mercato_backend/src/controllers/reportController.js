const { Report, User } = require('../models/index');

const VALID_REASONS = ['FAKE_PROFILE', 'SUSPICIOUS_CONTACT', 'INAPPROPRIATE_CONTENT', 'OTHER'];

/**
 * POST /api/v1/reports
 * Body: { targetUserId, reason, details? }
 * Accessible à tout utilisateur connecté (joueur, recruteur, fan) pour
 * signaler un profil suspect.
 */
exports.createReport = async (req, res) => {
  try {
    const { targetUserId, reason, details } = req.body;
    const reporterId = req.user.userId;

    const parsedTargetId = parseInt(targetUserId, 10);
    if (!Number.isInteger(parsedTargetId)) {
      return res.status(400).json({ error: 'Profil ciblé invalide.' });
    }

    if (parsedTargetId === reporterId) {
      return res.status(400).json({ error: 'Tu ne peux pas te signaler toi-même.' });
    }

    if (!VALID_REASONS.includes(reason)) {
      return res.status(400).json({ error: 'Motif de signalement invalide.' });
    }

    const target = await User.findByPk(parsedTargetId, { attributes: ['id'] });
    if (!target) {
      return res.status(404).json({ error: 'Profil introuvable.' });
    }

    const report = await Report.create({
      reporterId,
      targetUserId: parsedTargetId,
      reason,
      details: details && details.trim() ? details.trim() : null,
    });

    return res.status(201).json({ message: 'Signalement envoyé, merci.', data: report });
  } catch (error) {
    console.error('Erreur createReport:', error);
    return res.status(500).json({ error: 'Erreur serveur lors de l\'envoi du signalement.' });
  }
};
