const { RecruiterProfile, User, Report } = require('../models/index');

const RECRUITER_STATUSES = ['PENDING', 'VERIFIED', 'REJECTED'];
const REPORT_STATUSES = ['OPEN', 'REVIEWED', 'DISMISSED'];

/**
 * GET /api/v1/admin/recruiters?status=PENDING
 */
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
      include: [{ model: User, attributes: ['id', 'firstname', 'lastname', 'email', 'phone'] }],
    });

    return res.status(200).json({ data: profiles });
  } catch (error) {
    console.error('Erreur listRecruiters:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * PATCH /api/v1/admin/recruiters/:id/verify
 * Body: { status: 'VERIFIED' | 'REJECTED' }
 * :id est l'id du RecruiterProfile (pas l'userId).
 */
exports.verifyRecruiter = async (req, res) => {
  try {
    const { status } = req.body;
    if (!['VERIFIED', 'REJECTED'].includes(status)) {
      return res.status(400).json({ error: 'Statut invalide, attendu VERIFIED ou REJECTED.' });
    }

    const profile = await RecruiterProfile.findByPk(req.params.id);
    if (!profile) {
      return res.status(404).json({ error: 'Profil recruteur introuvable.' });
    }

    profile.verificationStatus = status;
    await profile.save();

    return res.status(200).json({ message: 'Statut de vérification mis à jour.', data: profile });
  } catch (error) {
    console.error('Erreur verifyRecruiter:', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * GET /api/v1/admin/reports?status=OPEN
 */
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

/**
 * PATCH /api/v1/admin/reports/:id
 * Body: { status: 'REVIEWED' | 'DISMISSED' }
 */
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
