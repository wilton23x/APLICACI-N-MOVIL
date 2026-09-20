require("dotenv").config();

const express = require("express");
const cors = require("cors");
const conexion = require("./config/database");

const authRoutes = require("./routes/authRoutes");
const tareaRoutes = require("./routes/tareaRoutes");
const usuarioRoutes = require("./routes/usuarioRoutes");

const app = express();

app.use(cors());
app.use(express.json());
app.use("/uploads", express.static("uploads"));

app.get("/", (req, res) => {
    res.json({
        mensaje: "API Gestion de Tareas - Semana 10 funcionando correctamente"
    });
});

app.use("/api/auth", authRoutes);
app.use("/api/tareas", tareaRoutes);
app.use("/api/usuarios", usuarioRoutes);

module.exports = app;
