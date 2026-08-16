const conexion = require("../config/database");
const tareaQueue = require("../jobs/tareaQueue");
const redis = require("../config/redis");


// ======================================
// Obtener todas las tareas
// Con caché Cache-Aside (Redis)
// ======================================

exports.obtenerTareas = async (req, res) => {

    const claveCache = "lista_tareas";


    try {

        // 1. Buscar primero en Redis
        const datosCache = await redis.get(claveCache);


        if (datosCache) {

            console.log("Respuesta desde Redis");

            return res.json(JSON.parse(datosCache));

        }


        // 2. Si no existe, consultar MySQL
        conexion.query(
            "SELECT * FROM tareas",

            async (error, resultados) => {


                if(error){

                    return res.status(500).json(error);

                }


                // 3. Guardar resultado en Redis por 60 segundos

                await redis.setEx(
                    claveCache,
                    60,
                    JSON.stringify(resultados)
                );


                console.log("Respuesta desde MySQL");


                res.json(resultados);


            }
        );


    } catch(error){

        res.status(500).json({
            mensaje:"Error en caché",
            error
        });

    }

};



// ======================================
// Crear tarea
// ======================================

exports.crearTarea = (req, res) => {


    const {
        titulo,
        descripcion
    } = req.body;



    if(!titulo){

        return res.status(400).json({

            mensaje:"El título es obligatorio"

        });

    }



    const estado = "Pendiente";


    // Usuario desde JWT

    const usuario_id = req.usuario.id;



    const sql = `

        INSERT INTO tareas

        (
            titulo,
            descripcion,
            estado,
            usuario_id
        )

        VALUES (?, ?, ?, ?)

    `;



    conexion.query(

        sql,

        [
            titulo,
            descripcion,
            estado,
            usuario_id
        ],


        async(error, resultado)=>{


            if(error){

                return res.status(500).json(error);

            }



            // Invalidar caché

            await redis.del("lista_tareas");



            // Enviar trabajo a cola

            tareaQueue.add({

                tareaId:resultado.insertId,

                mensaje:"Nueva tarea creada"

            });



            res.status(201).json({

                mensaje:"Tarea creada correctamente",

                id:resultado.insertId

            });


        }

    );


};



// ======================================
// Actualizar tarea
// ======================================

exports.actualizarTarea = (req,res)=>{


    const id = req.params.id;


    const {
        titulo,
        descripcion,
        estado
    } = req.body;



    const sql = `

        UPDATE tareas

        SET

        titulo=?,

        descripcion=?,

        estado=?


        WHERE id=?

    `;



    conexion.query(

        sql,

        [
            titulo,
            descripcion,
            estado,
            id
        ],


        async(error)=>{


            if(error){

                return res.status(500).json(error);

            }



            // Actualización del caché

            await redis.del("lista_tareas");



            res.json({

                mensaje:"Tarea actualizada correctamente"

            });


        }

    );


};




// ======================================
// Eliminar tarea
// ======================================

exports.eliminarTarea = (req,res)=>{


    const id = req.params.id;



    const sql = `

        DELETE FROM tareas

        WHERE id=?

    `;



    conexion.query(

        sql,

        [id],


        async(error)=>{


            if(error){

                return res.status(500).json(error);

            }



            // Eliminar caché

            await redis.del("lista_tareas");



            res.json({

                mensaje:"Tarea eliminada correctamente"

            });



        }

    );


};