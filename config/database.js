const mysql = require("mysql2");

const usarSSL = process.env.DB_SSL === "true";

const conexion = mysql.createConnection({
    host: process.env.DB_HOST || "localhost",
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER || "root",
    password: process.env.DB_PASSWORD || "",
    database: process.env.DB_NAME || "tareas_db",
    connectTimeout: 15000,

    ...(usarSSL && {
        ssl: {
            rejectUnauthorized: false
        }
    })
});

conexion.connect((err) => {
    if (err) {
        console.error("Error de conexion:", err.message);
    } else {
        console.log(
            usarSSL
                ? "Conectado a MySQL remoto mediante SSL"
                : "Conectado a MySQL"
        );
    }
});

module.exports = conexion;