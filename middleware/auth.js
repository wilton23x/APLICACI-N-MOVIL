const jwt = require("jsonwebtoken");

const verificarToken = (req, res, next) => {

    const authHeader = req.headers.authorization;

    if (!authHeader) {
        return res.status(403).json({
            mensaje: "No existe token de acceso"
        });
    }

    const token = authHeader.split(" ")[1];

    jwt.verify(token, process.env.JWT_SECRET, (error, usuario) => {

        if (error) {
            return res.status(401).json({
                mensaje: "Token inválido o expirado"
            });
        }

        req.usuario = usuario;
        next();
    });
};

module.exports = verificarToken;