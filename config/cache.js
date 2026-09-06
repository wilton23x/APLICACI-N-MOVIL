const cache = require("./cache");

exports.obtenerTareas = (req, res) => {

    const cacheKey = "lista_tareas";

    const datosCache = cache.get(cacheKey);

    if (datosCache) {
        return res.json({
            origen: "cache",
            datos: datosCache
        });
    }

    const tareas = {
        mensaje: "Lista de tareas"
    };

    cache.set(cacheKey, tareas);

    res.json({
        origen: "base de datos",
        datos: tareas
    });
};

exports.crearTarea = (req, res) => {

    cache.del("lista_tareas");

    res.json({
        mensaje: "Tarea creada correctamente"
    });
};

exports.actualizarTarea = (req, res) => {

    cache.del("lista_tareas");

    res.json({
        mensaje: "Tarea actualizada"
    });
};

exports.eliminarTarea = (req, res) => {

    cache.del("lista_tareas");

    res.json({
        mensaje: "Tarea eliminada"
    });
};