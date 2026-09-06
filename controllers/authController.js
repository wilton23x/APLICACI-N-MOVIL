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


            const token = jwt.sign(
                {
                    id: usuario.id,
                    correo: usuario.correo,
                    rol: usuario.rol
                },

                process.env.JWT_SECRET,

                {
                    expiresIn: "1h"
                }
            );


            res.json({
                mensaje: "Inicio de sesión correcto",
                token
            });

        }
    );

};