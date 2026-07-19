const tareaQueue = require("./tareaQueue");


tareaQueue.process((job) => {

    console.log(
        "Procesando tarea asíncrona:",
        job.data
    );

});