const multer = require('multer');
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const cloudinary = require('../../config/cloudinary')

const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'mercato/player_videos',
    resource_type: 'video', // important : Cloudinary traite vidéos différemment des images
    allowed_formats: ['mp4', 'mov', 'avi', 'webm'],
    // Optionnel : limite la durée/qualité pour économiser le quota gratuit
    transformation: [{ quality: 'auto' }],
  },
});

// Limite de taille : 50 Mo par vidéo (ajuste selon ton besoin/quota Cloudinary gratuit)
const uploadVideo = multer({
  storage: storage,
  limits: { fileSize: 50 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowedMimes = ['video/mp4', 'video/quicktime', 'video/x-msvideo', 'video/webm'];
    if (allowedMimes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Format vidéo non supporté. Utilisez mp4, mov, avi ou webm.'), false);
    }
  },
});

module.exports = uploadVideo;