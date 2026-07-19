const conexion = require("../config/database");


exports.obtenerUsuariosConTareas = (req, res) => {

    const sql = `
        SELECT 
            u.id,
            u.nombre,
            u.correo,
            t.id AS tarea_id,
            t.titulo,
            t.estado

        FROM usuarios u

        LEFT JOIN tareas t
        ON u.id = t.usuario_id
    `;


    conexion.query(sql, (error, resultados) => {

        if(error){
            return res.status(500).json(error);
        }


        res.json(resultados);

    });

};