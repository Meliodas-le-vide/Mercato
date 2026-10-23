const express = require('express');
const sequelize = require('./config/database');
const authRoutes = require('./src/routes/authRoutes');
const playerProfileRoutes = require('./src/routes/playerprofileRoutes');
const recruiterProfileRoutes = require('./src/routes/recruiterProfileRoutes');
const videoRoutes = require('./src/routes/videoRoutes');
const favoriteRoutes = require('./src/routes/favoriteRoutes');
const notificationRoutes = require('./src/routes/notificationRoutes');
const reportRoutes = require('./src/routes/reportRoutes');
const adminRoutes = require('./src/routes/adminRoutes');
const messageRoutes = require('./src/routes/messageRoutes');
const eventRoutes = require('./src/routes/eventRoutes')
const cloudinary = require('./config/cloudinary');
require('dotenv').config();
const cors = require('cors');  


const app = express();

app.use(cors({
  origin: ['http://localhost:5173', 'http://localhost:5000'],
  credentials: true,
}));

app.use(express.json());


app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/players', playerProfileRoutes);
app.use('/api/v1/recruiter', recruiterProfileRoutes);
app.use('/api/v1/videos', videoRoutes);
app.use('/api/v1/favorites', favoriteRoutes);
app.use('/api/v1/notifications', notificationRoutes);
app.use('/api/v1/reports', reportRoutes);
app.use('/api/v1/admin', adminRoutes);
app.use('/api/v1/messages', messageRoutes);
app.use('/api/v1/events', eventRoutes);




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

const PORT = process.env.PORT || 5000;


sequelize
.sync({alter:true})
.then(()=> {
    console.log('Database synced');
    const http = require('http');
    const { initSocket } = require('./src/utils/socket');
    const server = http.createServer(app);
    initSocket(server);
    server.listen(PORT, () => console.log(`Server running on ${PORT}`));
})
.catch(console.error);