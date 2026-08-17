const jwt = require('jsonwebtoken');

exports.generateAccessToken = (user) => {
  return jwt.sign(
    { userId: user.id, role: user.role },
    process.env.JWT_SECRET || 'your_access_secret',
    { expiresIn: '15m' }
  );
};


exports.generateRefreshToken = (user) => {
  return jwt.sign(
    { userId: user.id },
    process.env.JWT_REFRESH_SECRET || 'your_refresh_secret',
    { expiresIn: '7d' }
  );
};