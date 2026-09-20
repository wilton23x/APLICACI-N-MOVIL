const multer = require("multer");
const path = require("path");
const fs = require("fs");

const uploadDir = path.join(__dirname, "..", "uploads", "tareas");

if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },

  filename: (req, file, cb) => {
    const extension = path.extname(file.originalname).toLowerCase();

    const nombreArchivo =
      `tarea-${Date.now()}-${Math.round(Math.random() * 1e9)}${extension}`;

    cb(null, nombreArchivo);
  },
});

const fileFilter = (req, file, cb) => {
  const tiposPermitidos = [
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/webp",
  ];

  if (tiposPermitidos.includes(file.mimetype)) {
    return cb(null, true);
  }

  cb(new Error("Solo se permiten archivos de imagen"));
};

const uploadTarea = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024,
  },
});

module.exports = uploadTarea;