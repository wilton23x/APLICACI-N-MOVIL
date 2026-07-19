const express = require("express");
const router = express.Router();

const usuarioController = require("../controllers/usuarioController");
const auth = require("../middleware/auth");


router.get(
    "/con-tareas",
    auth,
    usuarioController.obtenerUsuariosConTareas
);


module.exports = router;