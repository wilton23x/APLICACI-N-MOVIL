const mysql = require("mysql2");

const conexion = mysql.createConnection({
    host: process.env.DB_HOST || "localhost",
    user: process.env.DB_USER || "root",
    password: process.env.DB_PASSWORD || "",
    database: process.env.DB_NAME || "tareas_db"
});

conexion.connect((err) => {
    if (err) {
        console.error("Error de conexion:", err.message);
    } else {
        console.log("Conectado a MySQL");
    }
});

module.exports = conexion;
