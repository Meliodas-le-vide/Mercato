const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { generateAccessToken, generateRefreshToken } = require('../utils/token');
const { sendMail } = require('../utils/mailer');

// register
exports.register = async (req, res) => {
  try {
    const { lastname, firstname, email, password, role, phone } = req.body;

    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ message: 'Cet email est déjà utilisé' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await User.create({
      lastname,
      firstname,
      email,
      password: hashedPassword,
      role,
      phone
    });

    res.status(201).json({
      message: 'Utilisateur créé avec succès ',
      userId: user.id
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};



//login
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(401).json({ message: 'Identifiants invalides' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Identifiants invalides' });
    }

    if (user.isBanned) {
      return res.status(403).json({
        message: user.bannedReason
          ? `Compte suspendu : ${user.bannedReason}`
          : 'Ce compte a été suspendu.',
      });
    }

    // Génération des tokens
    const accessToken = generateAccessToken(user);
    const refreshToken = generateRefreshToken(user);

    // Enregistrement du Refresh Token en BDD
    user.refreshToken = refreshToken;
    await user.save();

    res.json({
      message: 'Connexion réussie',
      accessToken,
      refreshToken,
      user: {
        id: user.id,
        lastname: user.lastname,
        firstname: user.firstname,
        email: user.email,
        role: user.role,
        phone: user.phone,
        ProfileImage: user.Profile_image
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const RESET_CODE_TTL_MINUTES = 15;
const RESET_CODE_MAX_ATTEMPTS = 5;
const MIN_PASSWORD_LENGTH = 6;
const GENERIC_FORGOT_MESSAGE =
  'Si un compte existe pour cet e-mail, un code de réinitialisation vient d\'être envoyé.';

function normalizeEmail(email) {
  return typeof email === 'string' ? email.toLowerCase().trim() : '';
}

/**
 * Vérifie le code de réinitialisation d'un utilisateur.
 * Renvoie null si le code est valide, sinon le message d'erreur à afficher.
 * Chaque échec consomme un essai ; au-delà du maximum, le code est invalidé.
 */
async function checkResetCode(user, code) {
  if (!user || !user.resetPasswordCode || !user.resetPasswordExpires) {
    return 'Code invalide ou expiré. Demande un nouveau code.';
  }
  if (user.resetPasswordExpires.getTime() < Date.now()) {
    return 'Ce code a expiré. Demande un nouveau code.';
  }
  if (user.resetPasswordAttempts >= RESET_CODE_MAX_ATTEMPTS) {
    return 'Trop de tentatives. Demande un nouveau code.';
  }

  const isValid = await bcrypt.compare(String(code || ''), user.resetPasswordCode);
  if (!isValid) {
    user.resetPasswordAttempts += 1;
    await user.save();
    const left = RESET_CODE_MAX_ATTEMPTS - user.resetPasswordAttempts;
    return left > 0
      ? `Code incorrect. Il te reste ${left} essai${left > 1 ? 's' : ''}.`
      : 'Trop de tentatives. Demande un nouveau code.';
  }
  return null;
}

/**
 * POST /auth/forgotPassword  { email }
 * Génère un code à 6 chiffres valable 15 min et l'envoie par e-mail.
 * Réponse identique que le compte existe ou non (pas de fuite d'information).
 */
exports.forgotPassword = async (req, res) => {
  try {
    const email = normalizeEmail(req.body.email);
    if (!email) {
      return res.status(400).json({ message: 'L\'e-mail est obligatoire.' });
    }

    const user = await User.findOne({ where: { email } });
    if (user && !user.isBanned) {
      const code = String(crypto.randomInt(100000, 1000000));

      user.resetPasswordCode = await bcrypt.hash(code, 10);
      user.resetPasswordExpires = new Date(Date.now() + RESET_CODE_TTL_MINUTES * 60 * 1000);
      user.resetPasswordAttempts = 0;
      await user.save();

      await sendMail({
        to: user.email,
        subject: 'Ton code de réinitialisation Mercato',
        text:
          `Bonjour ${user.firstname},\n\n` +
          `Voici ton code pour réinitialiser ton mot de passe : ${code}\n\n` +
          `Il est valable ${RESET_CODE_TTL_MINUTES} minutes. ` +
          'Si tu n\'es pas à l\'origine de cette demande, ignore cet e-mail.',
        html:
          `<p>Bonjour ${user.firstname},</p>` +
          '<p>Voici ton code pour réinitialiser ton mot de passe :</p>' +
          `<p style="font-size:28px;font-weight:bold;letter-spacing:6px">${code}</p>` +
          `<p>Il est valable ${RESET_CODE_TTL_MINUTES} minutes. ` +
          'Si tu n\'es pas à l\'origine de cette demande, ignore cet e-mail.</p>',
      });
    }

    return res.json({ message: GENERIC_FORGOT_MESSAGE });
  } catch (error) {
    console.error('Erreur forgotPassword:', error);
    return res.status(500).json({ message: 'Impossible d\'envoyer le code pour le moment.' });
  }
};

/**
 * POST /auth/verifyResetCode  { email, code }
 * Vérifie le code avant d'afficher le formulaire du nouveau mot de passe.
 */
exports.verifyResetCode = async (req, res) => {
  try {
    const user = await User.findOne({ where: { email: normalizeEmail(req.body.email) } });
    const error = await checkResetCode(user, req.body.code);
    if (error) return res.status(400).json({ message: error });

    return res.json({ message: 'Code valide.' });
  } catch (error) {
    console.error('Erreur verifyResetCode:', error);
    return res.status(500).json({ message: 'Erreur serveur.' });
  }
};

/**
 * POST /auth/resetPassword  { email, code, newPassword }
 * Change le mot de passe, invalide le code et déconnecte les autres sessions.
 */
exports.resetPassword = async (req, res) => {
  try {
    const { code, newPassword } = req.body;

    if (typeof newPassword !== 'string' || newPassword.length < MIN_PASSWORD_LENGTH) {
      return res.status(400).json({
        message: `Le mot de passe doit contenir au moins ${MIN_PASSWORD_LENGTH} caractères.`,
      });
    }

    const user = await User.findOne({ where: { email: normalizeEmail(req.body.email) } });
    const error = await checkResetCode(user, code);
    if (error) return res.status(400).json({ message: error });

    user.password = await bcrypt.hash(newPassword, 10);
    user.resetPasswordCode = null;
    user.resetPasswordExpires = null;
    user.resetPasswordAttempts = 0;
    user.refreshToken = null; // déconnecte les sessions existantes
    await user.save();

    return res.json({ message: 'Mot de passe modifié. Tu peux te connecter.' });
  } catch (error) {
    console.error('Erreur resetPassword:', error);
    return res.status(500).json({ message: 'Erreur serveur.' });
  }
};




exports.refreshToken = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(401).json({ message: 'Refresh token requis' });
    }

    
    const user = await User.findOne({ where: { refreshToken } });
    if (!user) {
      return res.status(403).json({ message: 'Refresh token invalide ou révoqué' });
    }

    // 2. Vérifier la validité du token avec la clé secrète
    jwt.verify(
      refreshToken,
      process.env.JWT_REFRESH_SECRET,
      async (err, decoded) => {
        if (err) {
          // Token expiré ou altéré -> suppression de la BDD
          user.refreshToken = null;
          await user.save();
          return res.status(403).json({ message: 'Refresh token expiré' });
        }

        // 3. Rotation des tokens (sécurité renforcée)
        const newAccessToken = generateAccessToken(user);
        const newRefreshToken = generateRefreshToken(user);

        user.refreshToken = newRefreshToken;
        await user.save();

        res.json({
          accessToken: newAccessToken,
          refreshToken: newRefreshToken
        });
      }
    );
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// logout
exports.logout = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (refreshToken) {
      const user = await User.findOne({ where: { refreshToken } });
      if (user) {
        user.refreshToken = null;
        await user.save();
      }
    }

    res.json({ message: 'déconnexion réussie' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};


