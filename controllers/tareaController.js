exports.obtenerTareas = (req, res) => {
    res.json({
        mensaje: "Lista de tareas"
    });
};

exports.crearTarea = (req, res) => {
    res.json({
        mensaje: "Tarea creada correctamente"
    });
};

exports.actualizarTarea = (req, res) => {
    res.json({
        mensaje: "Tarea actualizada"
    });
};

exports.eliminarTarea = (req, res) => {
    res.json({
        mensaje: "Tarea eliminada"
    });
};