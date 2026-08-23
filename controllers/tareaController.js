const conexion = require("../config/database");

// ======================================
// Obtener todas las tareas
// ======================================

exports.obtenerTareas = (req, res) => {

    const sql = `
        SELECT 
            id,
            titulo,
            descripcion,
            estado,
            usuario_id
        FROM tareas
        WHERE usuario_id = ?
        ORDER BY id DESC
    `;

    const usuario_id = req.usuario.id;

    conexion.query(
        sql,
        [usuario_id],
        (error, resultados) => {

            if (error) {
                console.error("Error al obtener tareas:", error);

                return res.status(500).json({
                    mensaje: "Error al obtener las tareas"
                });
            }

            res.status(200).json({
                mensaje: "Tareas obtenidas correctamente",
                tareas: resultados
            });
        }
    );
};


// ======================================
// Crear tarea
// ======================================

exports.crearTarea = (req, res) => {

    const {
        titulo,
        descripcion
    } = req.body;

    if (!titulo) {
        return res.status(400).json({
            mensaje: "El título es obligatorio"
        });
    }

    const usuario_id = req.usuario.id;

    const sql = `
        INSERT INTO tareas
        (
            titulo,
            descripcion,
            estado,
            usuario_id
        )
        VALUES (?, ?, ?, ?)
    `;

    conexion.query(
        sql,
        [
            titulo,
            descripcion || null,
            "Pendiente",
            usuario_id
        ],
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


// ======================================
// Actualizar tarea
// ======================================

exports.actualizarTarea = (req, res) => {

    const id = req.params.id;

    const {
        titulo,
        descripcion,
        estado
    } = req.body;

    const usuario_id = req.usuario.id;

    if (!titulo) {
        return res.status(400).json({
            mensaje: "El título es obligatorio"
        });
    }

    const sql = `
        UPDATE tareas
        SET
            titulo = ?,
            descripcion = ?,
            estado = ?
        WHERE id = ?
        AND usuario_id = ?
    `;

    conexion.query(
        sql,
        [
            titulo,
            descripcion || null,
            estado || "Pendiente",
            id,
            usuario_id
        ],
        (error, resultado) => {

            if (error) {
                console.error("Error al actualizar:", error);

                return res.status(500).json({
                    mensaje: "Error al actualizar la tarea"
                });
            }

            if (resultado.affectedRows === 0) {
                return res.status(404).json({
                    mensaje: "Tarea no encontrada"
                });
            }

            res.status(200).json({
                mensaje: "Tarea actualizada correctamente"
            });
        }
    );
};


// ======================================
// Eliminar tarea
// ======================================

exports.eliminarTarea = (req, res) => {

    const id = req.params.id;

    const usuario_id = req.usuario.id;

    const sql = `
        DELETE FROM tareas
        WHERE id = ?
        AND usuario_id = ?
    `;

    conexion.query(
        sql,
        [id, usuario_id],
        (error, resultado) => {

            if (error) {
                console.error("Error al eliminar:", error);

                return res.status(500).json({
                    mensaje: "Error al eliminar la tarea"
                });
            }

            if (resultado.affectedRows === 0) {
                return res.status(404).json({
                    mensaje: "Tarea no encontrada"
                });
            }

            res.status(200).json({
                mensaje: "Tarea eliminada correctamente"
            });
        }
    );
};