const redis = require("redis");


const clienteRedis = redis.createClient({
    url: "redis://localhost:6379"
});


clienteRedis.on("connect", () => {
    console.log("Redis conectado");
});


clienteRedis.on("error", (error) => {
    console.log("Error Redis:", error);
});


clienteRedis.connect();


module.exports = clienteRedis;