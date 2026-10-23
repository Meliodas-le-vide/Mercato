const multer = require('multer');
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const cloudinary = require('../../config/cloudinary')

const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'mercato/kyc_documents',
    resource_type: 'auto', // Permet de gérer automatiquement les images et les PDF
    allowed_formats: ['jpg', 'jpeg', 'png', 'pdf'],
  },
});

const uploadKycDocument = multer({
  storage: storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // Limite de 10 Mo
  fileFilter: (req, file, cb) => {
    const allowedMimes = ['image/jpeg', 'image/png', 'application/pdf'];
    if (allowedMimes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Format non supporté. Utilisez un fichier JPG, PNG ou PDF.'), false);
    }
  },
});

module.exports = uploadKycDocument;