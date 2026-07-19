const express = require("express");
const router = express.Router();

const tareaController = require("../controllers/tareaController");
const auth = require("../middleware/auth");
console.log("RUTA TAREAS CARGADA");
router.get("/", auth, tareaController.obtenerTareas);
router.post("/", auth, tareaController.crearTarea);
router.put("/:id", auth, tareaController.actualizarTarea);
router.delete("/:id", auth, tareaController.eliminarTarea);

module.exports = router;
