const express = require('express');
const sequelize = require('./config/database');
const authRoutes = require('./src/routes/authRoutes');
const playerProfileRoutes = require('./src/routes/playerprofileRoutes');
const videoRoutes = require('./src/routes/videoRoutes');
const favoriteRoutes = require('./src/routes/favoriteRoutes');
cloudinary = require('./config/cloudinary');
require('dotenv').config();

const app = express();
app.use(express.json());
app.use('/api/auth', authRoutes);
app.use('/api/v1/players', playerProfileRoutes);
app.use('/api/v1/videos', videoRoutes);
app.use('/api/v1/favorites', favoriteRoutes);

app.use((err, req, res, next) => {
  console.error('=== Erreur non gérée ===');
  console.error('Route:', req.method, req.originalUrl);
  console.error('Nom:', err?.name);
  console.error('Message:', err?.message);
  console.error('Objet complet:', JSON.stringify(err, Object.getOwnPropertyNames(err), 2));
  console.error('========================');
  const message = err?.message || err?.error?.message || 'Erreur serveur inattendue.';
  res.status(err?.status || err?.http_code || 500).json({ error: message });
});



sequelize
.sync()
.then(()=> {
    console.log('Database synced');
    app.listen( process.env.PORT, ()=> {
        console.log(`server running on port ${process.env.PORT}`);
    })
}).catch(console.error);