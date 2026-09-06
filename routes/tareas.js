const express = require("express");
const router = express.Router();

const tareaController = require("../controllers/tareaController");

// Obtener todas las tareas
router.get("/", tareaController.obtenerTareas);

// Crear una tarea
router.post("/", tareaController.crearTarea);

// Actualizar una tarea
router.put("/:id", tareaController.actualizarTarea);

// Eliminar una tarea
router.delete("/:id", tareaController.eliminarTarea);

module.exports = router;