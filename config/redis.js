const redis = require("redis");

const redisUrl = process.env.REDIS_URL || "redis://localhost:6379";

const clienteRedis = redis.createClient({
    url: redisUrl
});

clienteRedis.on("connect", () => {
    console.log("Redis conectado");
});

clienteRedis.on("error", (error) => {
    console.log("Error Redis:", error.message);
});

clienteRedis.connect().catch((error) => {
    console.log("No se pudo conectar a Redis:", error.message);
});

module.exports = clienteRedis;
