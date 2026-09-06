const conexion = require("../config/database");

const Tarea = {

    obtenerTodas: (usuarioId, callback) => {
        const sql = `
            SELECT 
                t.id,
                t.titulo,
                t.descripcion,
                t.prioridad,
                t.estado,
                t.fecha_vencimiento,
                t.created_at,
                t.updated_at,
                c.nombre AS categoria
            FROM tareas t
            LEFT JOIN categorias c ON t.categoria_id = c.id
            WHERE t.usuario_id = ?
            ORDER BY t.fecha_vencimiento ASC
        `;

        conexion.query(sql, [usuarioId], callback);
    },

    obtenerPorId: (id, usuarioId, callback) => {
        const sql = `
            SELECT 
                t.id,
                t.titulo,
                t.descripcion,
                t.prioridad,
                t.estado,
                t.fecha_vencimiento,
                c.nombre AS categoria
            FROM tareas t
            LEFT JOIN categorias c ON t.categoria_id = c.id
            WHERE t.id = ? AND t.usuario_id = ?
        `;

        conexion.query(sql, [id, usuarioId], callback);
    },

    crear: (datos, callback) => {
        const sql = `
            INSERT INTO tareas
            (usuario_id, categoria_id, titulo, descripcion, prioridad, estado, fecha_vencimiento)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        `;

        const valores = [
            datos.usuario_id,
            datos.categoria_id || null,
            datos.titulo,
            datos.descripcion || null,
            datos.prioridad || "media",
            datos.estado || "pendiente",
            datos.fecha_vencimiento || null
        ];

        conexion.query(sql, valores, callback);
    },

    actualizar: (id, usuarioId, datos, callback) => {
        const sql = `
            UPDATE tareas
            SET titulo = ?,
                descripcion = ?,
                categoria_id = ?,
                prioridad = ?,
                estado = ?,
                fecha_vencimiento = ?
            WHERE id = ? AND usuario_id = ?
        `;

        const valores = [
            datos.titulo,
            datos.descripcion || null,
            datos.categoria_id || null,
            datos.prioridad,
            datos.estado,
            datos.fecha_vencimiento || null,
            id,
            usuarioId
        ];

        conexion.query(sql, valores, callback);
    },

    eliminar: (id, usuarioId, callback) => {
        const sql = `
            DELETE FROM tareas
            WHERE id = ? AND usuario_id = ?
        `;

        conexion.query(sql, [id, usuarioId], callback);
    }
};

module.exports = Tarea;