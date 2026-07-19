const express = require("express");

const authRoutes = require("./routes/authRoutes");
const tareaRoutes = require("./routes/tareaRoutes");

const app = express();

app.use(express.json());

app.get("/", (req, res) => {
    res.json({
        mensaje: "API Gestión de Tareas - Semana 7"
    });
});

app.use("/api/auth", authRoutes);
app.use("/api/tareas", tareaRoutes);

module.exports = app;