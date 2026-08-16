const conexion = require("../config/database");

exports.obtenerTareas = (req, res) => {
    const usuario_id = req.usuario.id;

    conexion.query(
        `SELECT id, titulo, descripcion, estado, usuario_id
         FROM tareas
         WHERE usuario_id = ?
         ORDER BY id DESC`,
        [usuario_id],
        (error, resultados) => {
            if (error) {
                console.error("Error al obtener tareas:", error);
                return res.status(500).json({
                    mensaje: "Error al obtener las tareas"
                });
            }

            res.json({
                mensaje: "Tareas obtenidas correctamente",
                tareas: resultados
            });
        }
    );
};

exports.crearTarea = (req, res) => {
    const { titulo, descripcion } = req.body;

    if (!titulo) {
        return res.status(400).json({
            mensaje: "El título es obligatorio"
        });
    }

    const usuario_id = req.usuario.id;

    conexion.query(
        `INSERT INTO tareas
         (titulo, descripcion, estado, usuario_id)
         VALUES (?, ?, ?, ?)`,
        [titulo, descripcion || null, "Pendiente", usuario_id],
        (error, resultado) => {
            if (error) {
                console.error("Error al crear tarea:", error);
                return res.status(500).json({
                    mensaje: "Error al crear la tarea"
                });
            }

            res.status(201).json({
                mensaje: "Tarea creada correctamente",
                id: resultado.insertId
            });
        }
    );
};

exports.actualizarTarea = (req, res) => {
    const id = req.params.id;
    const { titulo, descripcion, estado } = req.body;
    const usuario_id = req.usuario.id;

    if (!titulo) {
        return res.status(400).json({
            mensaje: "El título es obligatorio"
        });
    }

    conexion.query(
        `UPDATE tareas
         SET titulo = ?, descripcion = ?, estado = ?
         WHERE id = ? AND usuario_id = ?`,
        [
            titulo,
            descripcion || null,
            estado || "Pendiente",
            id,
            usuario_id
        ],
        (error, resultado) => {
            if (error) {
                console.error("Error al actualizar tarea:", error);
                return res.status(500).json({
                    mensaje: "Error al actualizar la tarea"
                });
            }

            if (resultado.affectedRows === 0) {
                return res.status(404).json({
                    mensaje: "Tarea no encontrada"
                });
            }

            res.json({
                mensaje: "Tarea actualizada correctamente"
            });
        }
    );
};

exports.eliminarTarea = (req, res) => {
    const id = req.params.id;
    const usuario_id = req.usuario.id;

    conexion.query(
        `DELETE FROM tareas
         WHERE id = ? AND usuario_id = ?`,
        [id, usuario_id],
        (error, resultado) => {
            if (error) {
                console.error("Error al eliminar tarea:", error);
                return res.status(500).json({
                    mensaje: "Error al eliminar la tarea"
                });
            }

            if (resultado.affectedRows === 0) {
                return res.status(404).json({
                    mensaje: "Tarea no encontrada"
                });
            }

            res.json({
                mensaje: "Tarea eliminada correctamente"
            });
        }
    );
};
