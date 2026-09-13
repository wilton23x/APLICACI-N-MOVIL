const conexion = require("../config/database");

exports.obtenerTareas = (req, res) => {
  const sql = `
    SELECT id, titulo, descripcion, estado, usuario_id, updated_at
    FROM tareas
    WHERE usuario_id = ?
    ORDER BY id DESC
  `;

  conexion.query(
    sql,
    [req.usuario.id],
    (error, resultados) => {
      if (error) {
        return res.status(500).json({
          mensaje: "Error al obtener las tareas",
        });
      }

      return res.status(200).json({
        mensaje: "Tareas obtenidas correctamente",
        tareas: resultados,
      });
    },
  );
};

exports.crearTarea = (req, res) => {
  const {
    titulo,
    descripcion,
    client_operation_id,
  } = req.body;

  const errores = {};

  if (!titulo || titulo.trim().length < 3) {
    errores.titulo = [
      "El título debe contener al menos 3 caracteres",
    ];
  }

  if (
    descripcion &&
    descripcion.trim().length > 255
  ) {
    errores.descripcion = [
      "La descripción no puede superar los 255 caracteres",
    ];
  }

  if (Object.keys(errores).length > 0) {
    return res.status(422).json({
      mensaje: "Error de validación",
      errores,
    });
  }

  const tituloLimpio = titulo.trim();

  const descripcionLimpia =
    descripcion?.trim() || null;

  const insertar = () => {
    const sql = `
      INSERT INTO tareas
      (
        titulo,
        descripcion,
        estado,
        usuario_id,
        client_operation_id
      )
      VALUES (?, ?, ?, ?, ?)
    `;

    conexion.query(
      sql,
      [
        tituloLimpio,
        descripcionLimpia,
        "Pendiente",
        req.usuario.id,
        client_operation_id || null,
      ],
      (error, resultado) => {
        if (error) {
          return res.status(500).json({
            mensaje: "Error al crear la tarea",
          });
        }

        return res.status(201).json({
          mensaje: "Tarea creada correctamente",
          id: resultado.insertId,
        });
      },
    );
  };

  if (!client_operation_id) {
    return insertar();
  }

  conexion.query(
    `
      SELECT id
      FROM tareas
      WHERE client_operation_id = ?
      AND usuario_id = ?
      LIMIT 1
    `,
    [
      client_operation_id,
      req.usuario.id,
    ],
    (error, rows) => {
      if (error) {
        return res.status(500).json({
          mensaje: "Error al validar operación",
        });
      }

      if (rows.length) {
        return res.status(200).json({
          mensaje: "Operación ya procesada",
          id: rows[0].id,
        });
      }

      insertar();
    },
  );
};

exports.actualizarTarea = (req, res) => {
  const {
    titulo,
    descripcion,
    estado,
  } = req.body;

  const errores = {};

  if (!titulo || titulo.trim().length < 3) {
    errores.titulo = [
      "El título debe contener al menos 3 caracteres",
    ];
  }

  if (
    descripcion &&
    descripcion.trim().length > 255
  ) {
    errores.descripcion = [
      "La descripción no puede superar los 255 caracteres",
    ];
  }

  if (Object.keys(errores).length > 0) {
    return res.status(422).json({
      mensaje: "Error de validación",
      errores,
    });
  }

  const tituloLimpio = titulo.trim();

  const descripcionLimpia =
    descripcion?.trim() || null;

  const sql = `
    UPDATE tareas
    SET titulo = ?,
        descripcion = ?,
        estado = ?
    WHERE id = ?
    AND usuario_id = ?
  `;

  conexion.query(
    sql,
    [
      tituloLimpio,
      descripcionLimpia,
      estado || "Pendiente",
      req.params.id,
      req.usuario.id,
    ],
    (error, resultado) => {
      if (error) {
        return res.status(500).json({
          mensaje: "Error al actualizar la tarea",
        });
      }

      if (!resultado.affectedRows) {
        return res.status(404).json({
          mensaje: "Tarea no encontrada",
        });
      }

      return res.status(200).json({
        mensaje: "Tarea actualizada correctamente",
      });
    },
  );
};

exports.eliminarTarea = (req, res) => {
  const sql = `
    DELETE FROM tareas
    WHERE id = ?
    AND usuario_id = ?
  `;

  conexion.query(
    sql,
    [
      req.params.id,
      req.usuario.id,
    ],
    (error, resultado) => {
      if (error) {
        return res.status(500).json({
          mensaje: "Error al eliminar la tarea",
        });
      }

      if (!resultado.affectedRows) {
        return res.status(404).json({
          mensaje: "Tarea no encontrada",
        });
      }

      return res.status(200).json({
        mensaje: "Tarea eliminada correctamente",
      });
    },
  );
};