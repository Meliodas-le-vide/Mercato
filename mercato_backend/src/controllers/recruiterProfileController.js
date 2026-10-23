const { RecruiterProfile, User } = require('../models/index');
const cloudinary = require('../../config/cloudinary');

const USER_ALIAS = 'user'; 

const ALLOWED_PROFILE_FIELDS = [
  'organizationName',
  'organizationType',
  'jobTitle',
  'recruitmentZone',
  'bio',
  'licenseNumber',
  'identityDocumentUrl',
];

/**
 * GET /api/v1/recruiter/me
 */
exports.getMe = async (req, res) => {
  try {
    const profile = await RecruiterProfile.findOne({
      where: { userId: req.user.userId },
      include: [
        {
          model: User,
          as: USER_ALIAS,
          attributes: { exclude: ['password', 'refreshToken'] },
        },
      ],
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
      profile = await RecruiterProfile.create({ userId: req.user.userId });
    }

    let hasKycUpdated = false; //déclaré AVANT la boucle

    for (const field of ALLOWED_PROFILE_FIELDS) {
      if (req.body[field] !== undefined) {
        profile[field] = req.body[field];
        if (field === 'identityDocumentUrl' || field === 'licenseNumber') {
          hasKycUpdated = true;
        }
      }
    }

    // Si le recruteur fournit ses documents KYC, son statut passe en examen (PENDING)
    if (hasKycUpdated && profile.identityDocumentUrl) {
      profile.verificationStatus = 'PENDING';
      profile.kycSubmittedAt = new Date();
      profile.rejectionReason = null; // Réinitialise l'erreur précédente si existante
    }

    profile.isProfileComplete = Boolean(
      profile.organizationName &&
      profile.organizationType &&
      profile.identityDocumentUrl
    );

    await profile.save();

    return res.status(200).json({
      message: 'Profil mis à jour.',
      data: profile,
    });
  } catch (error) {
    console.error('Erreur updateMe :', error);
    return res.status(500).json({ error: 'Erreur serveur.' });
  }
};

/**
 * POST /api/v1/recruiter/upload-kyc
 * Upload le fichier KYC sur Cloudinary et retourne l'URL publique.
 * (Le client enverra ensuite cette URL dans identityDocumentUrl via updateMe)
 */
exports.uploadKycDocument = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Aucun fichier transmis.' });
    }

    // URL du fichier hébergé sur Cloudinary (fournie par multer-storage-cloudinary)
    const fileUrl = req.file.path;

    return res.status(200).json({
      message: 'Document téléversé avec succès.',
      url: fileUrl,
      publicId: req.file.filename, 
    });
  } catch (error) {
    console.error('Erreur uploadKycDocument:', error);
    return res.status(500).json({ error: 'Erreur lors du téléversement.' });
  }
};