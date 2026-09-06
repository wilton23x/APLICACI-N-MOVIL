# Taller práctico Semana 12 – Persistencia local y almacenamiento seguro

## 1. Clasificación de datos

| Dato | Clasificación | Mecanismo | Motivo |
|---|---|---|---|
| JWT de sesión | Sensible / credencial | `flutter_secure_storage` | Usa el almacenamiento cifrado del sistema; no se guarda en SQLite ni preferencias. |
| Título, descripción y estado de tareas | Datos funcionales | SQLite con `sqflite` | Se requieren consultas estructuradas y funcionamiento sin conexión. |
| Cola de operaciones pendientes | Datos operativos | SQLite | Necesita persistencia, contador de intentos, UUID y procesamiento ordenado. |
| Última sincronización | Metadato | SQLite | Permite informar al usuario de la antigüedad de la copia local. |

## 2. Elección de SQLite
Se utiliza `sqflite` porque el proyecto necesita datos relacionales, persistencia transaccional y consultas locales. Es más apropiado que un almacén clave-valor para tareas y una cola de sincronización. El token se mantiene separado en `flutter_secure_storage`.

## 3. Esquema local
La base local contiene `tasks`, `pending_operations` y `metadata`. `pending_operations` incluye `client_operation_id` UUID, tipo de operación, payload, número de intentos, fecha de creación y último error. El servidor mantiene `updated_at`, generado por MySQL.

## 4. Lectura sin conexión
Cuando la consulta HTTP falla, la aplicación lee las tareas de SQLite. La pantalla muestra `MODO SIN CONEXIÓN` y la antigüedad de la última sincronización.

## 5. Escritura sin conexión y reintentos
Una tarea creada sin conectividad se guarda en `pending_operations`. Cada operación recibe un UUID. Al recuperar conexión, la cola se procesa con máximo 5 intentos y espera creciente de 2, 4, 8 y 16 segundos. El backend comprueba `client_operation_id` para hacer la creación idempotente y evitar duplicados.

## 6. Estrategia de conflictos
Se adopta **server wins** para los registros existentes: después de sincronizar, la copia recibida del servidor sustituye la caché local. La marca `updated_at` procede del servidor. Esta estrategia prioriza consistencia y simplicidad, pero sacrifica posibles cambios locales sobre registros existentes que no hayan sido enviados. En esta entrega, la escritura offline demostrada es la creación de tareas, que se conserva mediante la cola pendiente.

## 7. Datos personales y conservación
Se almacenan localmente únicamente los campos de tarea necesarios para mostrarlos y el token de sesión. La finalidad es permitir continuidad de sesión y uso offline. Se conservan mientras exista una sesión activa. Al cerrar sesión se elimina el JWT del almacenamiento seguro y se vacían las tablas locales de tareas, cola y metadatos.

## 8. Evidencia para el video
1. Iniciar sesión, cerrar completamente la app y abrirla: debe entrar directamente a TaskManager.
2. Cargar tareas con Internet, activar modo avión y actualizar: debe aparecer `MODO SIN CONEXIÓN` con la antigüedad.
3. En modo avión, crear una tarea: debe aparecer el mensaje de que quedó en cola y aumentar `Pendientes`.
4. Desactivar modo avión y pulsar sincronizar: la tarea debe enviarse y `Pendientes` volver a 0.
5. Cerrar sesión: volver al login. Al iniciar nuevamente sin haber sincronizado previamente no deben sobrevivir datos de la sesión anterior.

## 9. Repositorio
Agregar aquí el enlace del repositorio del proyecto antes de entregar.
