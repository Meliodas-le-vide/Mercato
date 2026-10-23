const multer = require('multer');
const { CloudinaryStorage } = require('multer-storage-cloudinary');
// On importe une seule fois ton instance configurée de cloudinary
const cloudinary = require('../../config/cloudinary'); 

const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'mercato_events',
    allowed_formats: ['jpg', 'png', 'jpeg', 'webp'],
    transformation: [{ width: 1000, height: 500, crop: 'limit' }],
  },
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, 
  fileFilter: (req, file, cb) => {
    const allowedMimes = ['image/jpeg', 'image/png', 'image/webp'];
    if (allowedMimes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Format image non supporté. Utilisez jpg, png ou webp.'), false);
    }
  },
});

// On exporte directement le middleware pour un seul fichier nommé 'image'
module.exports = upload.single('image');