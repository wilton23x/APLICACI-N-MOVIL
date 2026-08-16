const mysql = require("mysql2");

const conexion = mysql.createConnection({
    host: "localhost",
    user: "root",
    password: "123456",
    database: "tareas_db"
});

conexion.connect((error) => {
    if (error) {
        console.error("ERROR MYSQL:", error.message);
        return;
    }

    console.log("Conectado a MySQL");

    const sql = `
        CREATE TABLE IF NOT EXISTS categorias (
            id INT AUTO_INCREMENT PRIMARY KEY,
            nombre VARCHAR(100) NOT NULL,
            descripcion VARCHAR(255),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    `;

    conexion.query(sql, (error) => {
        if (error) {
            console.error("ERROR CREANDO CATEGORIAS:", error.message);
        } else {
            console.log("CATEGORIAS CREADA CORRECTAMENTE");
        }

        conexion.end();
    });
});
