const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { generateAccessToken, generateRefreshToken } = require('../utils/token');

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
        email: user.email,
        role: user.role
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(404).json({ message: 'Utilisateur non trouvé' });
    }

    // Ici, vous pouvez générer un token de réinitialisation et l'envoyer par email à l'utilisateur.
    // Pour simplifier, nous allons juste renvoyer un message de succès.
    res.json({ message: 'Un email de réinitialisation a été envoyé si l\'utilisateur existe.' });
  } catch (error) {
    res.status(500).json({ error: error.message });
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