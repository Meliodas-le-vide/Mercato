const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const messageService = require('../services/messageService');

let io = null;

/**
 * À appeler UNE FOIS dans ton server.js, en remplaçant :
 *
 *   const server = app.listen(PORT, ...)
 *
 * par :
 *
 *   const http = require('http');
 *   const { initSocket } = require('./sockets/socketManager');
 *   const server = http.createServer(app);
 *   initSocket(server);
 *   server.listen(PORT, ...);
 */
function initSocket(httpServer) {
  io = new Server(httpServer, {
    cors: {
      origin: '*', //à restreindre à ton domaine en production
      methods: ['GET', 'POST'],
    },
  });

  // --- Authentification du socket via le JWT (même secret que verifyToken) ---
  io.use((socket, next) => {
    try {
      const token = socket.handshake.auth?.token || socket.handshake.headers?.authorization?.replace('Bearer ', '');
      if (!token) return next(new Error('Token manquant.'));

      // Adapte le nom de la variable d'env pour qu'elle corresponde
      // exactement à celle utilisée dans middlewares/authMiddleware.js
      const decoded = jwt.verify(token, process.env.JWT_ACCESS_SECRET);
      socket.userId = decoded.id || decoded.sub || decoded.userId;

      if (!socket.userId) return next(new Error('Token invalide : ID introuvable.'));
      next();
    } catch (err) {
      next(new Error('Authentification échouée.'));
    }
  });

  io.on('connection', (socket) => {
    const userId = socket.userId;
    console.log(`Socket connecté: user ${userId} (${socket.id})`);

    // Chaque utilisateur rejoint sa propre room -> permet d'émettre
    // "à cet utilisateur" sans connaître son socket.id précis.
    socket.join(`user_${userId}`);

    // --- Envoi d'un message ---
    socket.on('send_message', async (payload, callback) => {
      try {
        const message = await messageService.createMessage(userId, payload);

        // Confirmation à l'expéditeur (utile pour remplacer le message "optimiste" côté UI)
        if (typeof callback === 'function') callback({ success: true, message });

        // Notification au destinataire s'il est connecté
        io.to(`user_${message.receiverId}`).emit('new_message', message);
      } catch (err) {
        if (typeof callback === 'function') {
          callback({ success: false, error: err.message || 'Erreur serveur.' });
        }
      }
    });

    // --- Marquer une conversation comme lue ---
    socket.on('mark_read', async ({ fromUserId }) => {
      try {
        await messageService.markConversationAsRead(userId, fromUserId);
        // Informe l'expéditeur que ses messages ont été lus (accusé de lecture)
        io.to(`user_${fromUserId}`).emit('messages_read', { by: userId });
      } catch (err) {
        console.error('Erreur mark_read socket:', err);
      }
    });

    // --- Indicateur "en train d'écrire" (optionnel mais simple à ajouter) ---
    socket.on('typing', ({ receiverId }) => {
      io.to(`user_${receiverId}`).emit('typing', { from: userId });
    });
    socket.on('stop_typing', ({ receiverId }) => {
      io.to(`user_${receiverId}`).emit('stop_typing', { from: userId });
    });

    socket.on('disconnect', () => {
      console.log(`Socket déconnecté: user ${userId}`);
    });
  });

  return io;
}

/**
 * Permet d'émettre un événement à un utilisateur depuis n'importe où dans le
 * backend (ex: depuis le contrôleur REST en fallback).
 */
function emitToUser(userId, event, data) {
  if (!io) return;
  io.to(`user_${userId}`).emit(event, data);
}

module.exports = { initSocket, emitToUser };