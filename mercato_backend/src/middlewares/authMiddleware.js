const jwt = require('jsonwebtoken');
const User = require('../models/User');

exports.verifyToken = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Accès non autorisé. Token manquant.' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;

    // Vérifié à chaque requête (et pas seulement au login) pour qu'un
    // bannissement prononcé par un admin coupe l'accès immédiatement, sans
    // attendre l'expiration du token déjà émis.
    const account = await User.findByPk(decoded.userId, { attributes: ['isBanned', 'bannedReason'] });
    if (!account) {
      return res.status(401).json({ message: 'Compte introuvable.' });
    }
    if (account.isBanned) {
      return res.status(403).json({
        message: account.bannedReason
          ? `Compte suspendu : ${account.bannedReason}`
          : 'Ce compte a été suspendu.',
      });
    }

    next();
  } catch (error) {
    return res.status(401).json({ message: 'Token invalide ou expiré.' });
  }
};


exports.authorizeRoles = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        message: `Accès refusé. Le rôle ${req.user.role} n'a pas les autorisations nécessaires.`
      });
    }
    next();
  };
};