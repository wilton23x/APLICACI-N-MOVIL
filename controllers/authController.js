const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const conexion = require("../config/database");


// REGISTRO DE USUARIO
exports.register = async (req, res) => {

    const { nombre, correo, password } = req.body;


    if (!nombre || !correo || !password) {
        return res.status(400).json({
            mensaje: "Todos los campos son obligatorios"
        });
    }


    const passwordHash = await bcrypt.hash(password, 10);


    const sql = `
        INSERT INTO usuarios
        (nombre, correo, password, rol)
        VALUES (?, ?, ?, ?)
    `;


    conexion.query(
        sql,
        [nombre, correo, passwordHash, "usuario"],
        (error, resultado) => {

            if (error) {
                return res.status(500).json(error);
            }


            res.status(201).json({
                mensaje: "Usuario registrado correctamente",
                id: resultado.insertId
            });

        }
    );

};



// LOGIN DE USUARIO
exports.login = async (req, res) => {

    const { correo, password } = req.body;


    const sql = "SELECT * FROM usuarios WHERE correo = ?";


    conexion.query(
        sql,
        [correo],
        async (error, resultados) => {

            if (error) {
                return res.status(500).json(error);
            }


            if (resultados.length === 0) {
                return res.status(401).json({
                    mensaje: "Credenciales incorrectas"
                });
            }


            const usuario = resultados[0];


            const valido = await bcrypt.compare(
                password,
                usuario.password
            );


            if (!valido) {
                return res.status(401).json({
                    mensaje: "Credenciales incorrectas"
                });
            }


           const accessToken = jwt.sign(
    {
        id: usuario.id,
        correo: usuario.correo,
        rol: usuario.rol
    },
    process.env.JWT_SECRET,
    {
        expiresIn: process.env.ACCESS_TOKEN_EXPIRES || "1m"
    }
);


const refreshToken = jwt.sign(
    {
        id: usuario.id,
        correo: usuario.correo,
        rol: usuario.rol
    },
    process.env.JWT_REFRESH_SECRET,
    {
        expiresIn: "7d"
    }
);


res.json({
    mensaje: "Inicio de sesión correcto",
    access_token: accessToken,
    refresh_token: refreshToken
});

        }
    );

};
// RENOVAR ACCESS TOKEN
exports.refresh = (req, res) => {

    const { refresh_token } = req.body;

    if (!refresh_token) {
        return res.status(401).json({
            mensaje: "Refresh token requerido"
        });
    }

    jwt.verify(
        refresh_token,
        process.env.JWT_REFRESH_SECRET,
        (error, usuario) => {

            if (error) {
                return res.status(401).json({
                    mensaje: "Refresh token inválido o expirado"
                });
            }

            const nuevoAccessToken = jwt.sign(
                {
                    id: usuario.id,
                    correo: usuario.correo,
                    rol: usuario.rol
                },
                process.env.JWT_SECRET,
                {
                    expiresIn: process.env.ACCESS_TOKEN_EXPIRES || "1m"
                }
            );

            return res.status(200).json({
                access_token: nuevoAccessToken
            });
        }
    );
};