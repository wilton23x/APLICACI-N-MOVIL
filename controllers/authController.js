const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

const usuarios = [];

exports.register = async (req, res) => {

    const { nombre, correo, password } = req.body;

    if (!nombre || !correo || !password) {
        return res.status(400).json({
            mensaje: "Todos los campos son obligatorios"
        });
    }

    const existe = usuarios.find(u => u.correo === correo);

    if (existe) {
        return res.status(400).json({
            mensaje: "El usuario ya existe"
        });
    }

    const passwordHash = await bcrypt.hash(password, 10);

    usuarios.push({
        nombre,
        correo,
        password: passwordHash,
        rol: "usuario"
    });

    res.status(201).json({
        mensaje: "Usuario registrado correctamente"
    });

};

exports.login = async (req, res) => {

    const { correo, password } = req.body;

    const usuario = usuarios.find(u => u.correo === correo);

    if (!usuario) {
        return res.status(401).json({
            mensaje: "Credenciales incorrectas"
        });
    }

    const valido = await bcrypt.compare(password, usuario.password);

    if (!valido) {
        return res.status(401).json({
            mensaje: "Credenciales incorrectas"
        });
    }

    const token = jwt.sign(

        {
            correo: usuario.correo,
            rol: usuario.rol
        },

        "CLAVESECRETA",

        {
            expiresIn: "1h"
        }

    );

    res.json({

        mensaje: "Inicio de sesión correcto",

        token

    });

};