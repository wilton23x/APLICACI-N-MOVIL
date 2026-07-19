const Queue = require("bull");


const tareaQueue = new Queue(
    "procesamiento_tareas",
    {
        redis: {
            host: "127.0.0.1",
            port: 6379
        }
    }
);


module.exports = tareaQueue;