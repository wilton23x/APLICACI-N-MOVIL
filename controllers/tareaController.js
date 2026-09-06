const conexion = require("../config/database");

exports.obtenerTareas = (req, res) => {
  const sql = `SELECT id, titulo, descripcion, estado, usuario_id, updated_at
               FROM tareas WHERE usuario_id = ? ORDER BY id DESC`;
  conexion.query(sql, [req.usuario.id], (error, resultados) => {
    if (error) return res.status(500).json({ mensaje: "Error al obtener las tareas" });
    res.status(200).json({ mensaje: "Tareas obtenidas correctamente", tareas: resultados });
  });
};

exports.crearTarea = (req, res) => {
  const { titulo, descripcion, client_operation_id } = req.body;
  if (!titulo) return res.status(400).json({ mensaje: "El título es obligatorio" });

  const insertar = () => {
    const sql = `INSERT INTO tareas
      (titulo, descripcion, estado, usuario_id, client_operation_id)
      VALUES (?, ?, ?, ?, ?)`;
    conexion.query(sql, [titulo, descripcion || null, "Pendiente", req.usuario.id, client_operation_id || null],
      (error, resultado) => {
        if (error) return res.status(500).json({ mensaje: "Error al crear la tarea" });
        res.status(201).json({ mensaje: "Tarea creada correctamente", id: resultado.insertId });
      });
  };

  // Idempotencia: si el móvil reintenta la misma operación UUID, no duplica la tarea.
  if (!client_operation_id) return insertar();
  conexion.query(
    `SELECT id FROM tareas WHERE client_operation_id = ? AND usuario_id = ? LIMIT 1`,
    [client_operation_id, req.usuario.id],
    (error, rows) => {
      if (error) return res.status(500).json({ mensaje: "Error al validar operación" });
      if (rows.length) return res.status(200).json({ mensaje: "Operación ya procesada", id: rows[0].id });
      insertar();
    }
  );
};

exports.actualizarTarea = (req, res) => {
  const { titulo, descripcion, estado } = req.body;
  if (!titulo) return res.status(400).json({ mensaje: "El título es obligatorio" });
  const sql = `UPDATE tareas SET titulo=?, descripcion=?, estado=? WHERE id=? AND usuario_id=?`;
  conexion.query(sql, [titulo, descripcion || null, estado || "Pendiente", req.params.id, req.usuario.id],
    (error, resultado) => {
      if (error) return res.status(500).json({ mensaje: "Error al actualizar la tarea" });
      if (!resultado.affectedRows) return res.status(404).json({ mensaje: "Tarea no encontrada" });
      res.status(200).json({ mensaje: "Tarea actualizada correctamente" });
    });
};

exports.eliminarTarea = (req, res) => {
  conexion.query(`DELETE FROM tareas WHERE id=? AND usuario_id=?`, [req.params.id, req.usuario.id],
    (error, resultado) => {
      if (error) return res.status(500).json({ mensaje: "Error al eliminar la tarea" });
      if (!resultado.affectedRows) return res.status(404).json({ mensaje: "Tarea no encontrada" });
      res.status(200).json({ mensaje: "Tarea eliminada correctamente" });
    });
};
