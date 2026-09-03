const { RecruiterProfile, User } = require('../models/index');

const ALLOWED_PROFILE_FIELDS = [
  'organizationName', 'organizationType', 'jobTitle', 'recruitmentZone', 'bio',
];

/**
 * GET /api/v1/recruiter/me
 */
exports.getMe = async (req, res) => {
  try {
    const profile = await RecruiterProfile.findOne({
      where: { userId: req.user.userId },
      include: [{ model: User, attributes: { exclude: ['password', 'refreshToken'] } }],
    });

    if (!profile) {
      return res.status(404).json({ error: 'Profil recruteur introuvable.' });
    }

    return res.status(200).json({ data: profile });
  } catch (error) {
    console.error('Erreur getMe (recruteur):', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * PUT/PATCH /api/v1/recruiter/me
 */
exports.updateMe = async (req, res) => {
  try {
    let profile = await RecruiterProfile.findOne({ where: { userId: req.user.userId } });

    if (!profile) {
      // Crée le profil s'il n'existe pas encore (premier remplissage après inscription)
      profile = await RecruiterProfile.create({ userId: req.user.userId });
    }

    for (const field of ALLOWED_PROFILE_FIELDS) {
      if (req.body[field] !== undefined) {
        profile[field] = req.body[field];
      }
    }

    // Marque le profil comme complet si les champs essentiels sont remplis
    profile.isProfileComplete = Boolean(profile.organizationName && profile.organizationType);

    await profile.save();

    return res.status(200).json({
      message: 'Profil mis à jour.',
      data: profile,
    });
  } catch (error) {
    console.error('Erreur updateMe (recruteur):', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};
