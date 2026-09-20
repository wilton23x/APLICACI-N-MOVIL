const conexion = require("../config/database");

exports.obtenerTareas = (req, res) => {
  const sql = `
    SELECT
      id,
      titulo,
      descripcion,
      foto_path,
      latitud,
      longitud,
      estado,
      usuario_id,
      updated_at
    FROM tareas
    WHERE usuario_id = ?
    ORDER BY id DESC
  `;

  conexion.query(sql, [req.usuario.id], (error, resultados) => {
    if (error) {
      console.error("Error al obtener tareas:", error);

      return res.status(500).json({
        mensaje: "Error al obtener las tareas",
      });
    }

    return res.status(200).json({
      mensaje: "Tareas obtenidas correctamente",
      tareas: resultados,
    });
  });
};

exports.crearTarea = (req, res) => {
  console.log("SEMANA14 BODY:", req.body);
  console.log("SEMANA14 FILE:", req.file);
  const {
    titulo,
    descripcion,
    client_operation_id,
    latitud,
    longitud,
  } = req.body;

  const errores = {};

  if (!titulo || titulo.trim().length < 3) {
    errores.titulo = [
      "El tÃ­tulo debe contener al menos 3 caracteres",
    ];
  }

  if (descripcion && descripcion.trim().length > 255) {
    errores.descripcion = [
      "La descripciÃ³n no puede superar los 255 caracteres",
    ];
  }

  if (Object.keys(errores).length > 0) {
    return res.status(422).json({
      mensaje: "Error de validaciÃ³n",
      errores,
    });
  }

  const tituloLimpio = titulo.trim();
  const descripcionLimpia = descripcion?.trim() || null;

  // Si Multer recibiÃ³ una fotografÃ­a, guardamos su ruta relativa.
  const fotoPath = req.file
    ? `/uploads/tareas/${req.file.filename}`
    : null;

  const latitudLimpia =
    latitud !== undefined &&
    latitud !== null &&
    latitud !== ""
      ? Number(latitud)
      : null;

  const longitudLimpia =
    longitud !== undefined &&
    longitud !== null &&
    longitud !== ""
      ? Number(longitud)
      : null;

  if (
    latitudLimpia !== null &&
    (!Number.isFinite(latitudLimpia) ||
      latitudLimpia < -90 ||
      latitudLimpia > 90)
  ) {
    errores.latitud = ["La latitud no es vÃ¡lida"];
  }

  if (
    longitudLimpia !== null &&
    (!Number.isFinite(longitudLimpia) ||
      longitudLimpia < -180 ||
      longitudLimpia > 180)
  ) {
    errores.longitud = ["La longitud no es vÃ¡lida"];
  }

  if (Object.keys(errores).length > 0) {
    return res.status(422).json({
      mensaje: "Error de validaciÃ³n",
      errores,
    });
  }

  const insertar = () => {
    const sql = `
      INSERT INTO tareas
      (
        titulo,
        descripcion,
        foto_path,
        latitud,
        longitud,
        estado,
        usuario_id,
        client_operation_id
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `;

    conexion.query(
      sql,
      [
        tituloLimpio,
        descripcionLimpia,
        fotoPath,
        latitudLimpia,
        longitudLimpia,
        "Pendiente",
        req.usuario.id,
        client_operation_id || null,
      ],
      (error, resultado) => {
        if (error) {
          console.error("Error al crear tarea:", error);

          return res.status(500).json({
            mensaje: "Error al crear la tarea",
          });
        }

        return res.status(201).json({
          mensaje: "Tarea creada correctamente",
          id: resultado.insertId,
          foto_path: fotoPath,
          latitud: latitudLimpia,
          longitud: longitudLimpia,
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
    [client_operation_id, req.usuario.id],
    (error, rows) => {
      if (error) {
        console.error(
          "Error al validar client_operation_id:",
          error,
        );

        return res.status(500).json({
          mensaje: "Error al validar operaciÃ³n",
        });
      }

      if (rows.length) {
        return res.status(200).json({
          mensaje: "OperaciÃ³n ya procesada",
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
    latitud,
    longitud,
  } = req.body;

  const errores = {};

  if (!titulo || titulo.trim().length < 3) {
    errores.titulo = [
      "El tÃ­tulo debe contener al menos 3 caracteres",
    ];
  }

  if (descripcion && descripcion.trim().length > 255) {
    errores.descripcion = [
      "La descripciÃ³n no puede superar los 255 caracteres",
    ];
  }

  const tituloLimpio = titulo?.trim();
  const descripcionLimpia = descripcion?.trim() || null;

  const latitudLimpia =
    latitud !== undefined &&
    latitud !== null &&
    latitud !== ""
      ? Number(latitud)
      : null;

  const longitudLimpia =
    longitud !== undefined &&
    longitud !== null &&
    longitud !== ""
      ? Number(longitud)
      : null;

  if (
    latitudLimpia !== null &&
    (!Number.isFinite(latitudLimpia) ||
      latitudLimpia < -90 ||
      latitudLimpia > 90)
  ) {
    errores.latitud = ["La latitud no es vÃ¡lida"];
  }

  if (
    longitudLimpia !== null &&
    (!Number.isFinite(longitudLimpia) ||
      longitudLimpia < -180 ||
      longitudLimpia > 180)
  ) {
    errores.longitud = ["La longitud no es vÃ¡lida"];
  }

  if (Object.keys(errores).length > 0) {
    return res.status(422).json({
      mensaje: "Error de validaciÃ³n",
      errores,
    });
  }

  // Si llega una foto nueva se reemplaza foto_path.
  // Si no llega foto, se conserva la anterior.
  const fotoPath = req.file
    ? `/uploads/tareas/${req.file.filename}`
    : null;

  const sql = `
    UPDATE tareas
    SET titulo = ?,
        descripcion = ?,
        estado = ?,
        latitud = ?,
        longitud = ?,
        foto_path = COALESCE(?, foto_path)
    WHERE id = ?
    AND usuario_id = ?
  `;

  conexion.query(
    sql,
    [
      tituloLimpio,
      descripcionLimpia,
      estado || "Pendiente",
      latitudLimpia,
      longitudLimpia,
      fotoPath,
      req.params.id,
      req.usuario.id,
    ],
    (error, resultado) => {
      if (error) {
        console.error("Error al actualizar tarea:", error);

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
        foto_path: fotoPath,
        latitud: latitudLimpia,
        longitud: longitudLimpia,
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
    [req.params.id, req.usuario.id],
    (error, resultado) => {
      if (error) {
        console.error("Error al eliminar tarea:", error);

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

