// Cargar variables del archivo .env
require("dotenv").config();

const express = require("express");
const conexion = require("./config/database");


// Importar rutas
const authRoutes = require("./routes/authRoutes");
const tareaRoutes = require("./routes/tareaRoutes");
const usuarioRoutes = require("./routes/usuarioRoutes");


const app = express();


app.use(express.json());


// Ruta principal
app.get("/", (req, res) => {

    res.json({
        mensaje: "API Gestión de Tareas - Semana 8 funcionando correctamente"
    });

});


// Rutas
app.use("/api/auth", authRoutes);

app.use("/api/tareas", tareaRoutes);

app.use("/api/usuarios", usuarioRoutes);



module.exports = app;