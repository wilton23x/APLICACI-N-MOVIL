const app = require("./app");

// Iniciar worker de Bull para procesamiento asincrono
require("./jobs/worker");

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(`Servidor ejecutándose en http://localhost:${PORT}`);
});
