const express = require("express");
const router = express.Router();

const tareaController = require("../controllers/tareaController");
const auth = require("../middleware/auth");
const uploadTarea = require("../middleware/uploadTarea");

console.log("RUTA TAREAS CARGADA");

// Obtener tareas
router.get(
  "/",
  auth,
  tareaController.obtenerTareas
);

// Crear tarea con fotografía opcional
router.post(
  "/",
  auth,
  uploadTarea.single("foto"),
  tareaController.crearTarea
);

// Actualizar tarea con fotografía opcional
router.put(
  "/:id",
  auth,
  uploadTarea.single("foto"),
  tareaController.actualizarTarea
);

// Eliminar tarea
router.delete(
  "/:id",
  auth,
  tareaController.eliminarTarea
);

module.exports = router;