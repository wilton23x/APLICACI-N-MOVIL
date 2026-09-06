require('dotenv').config();
const mysql = require('mysql2/promise');

async function run() {
  const db = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '123456',
    database: process.env.DB_NAME || 'tareas_db',
  });

  const changes = [
    `ALTER TABLE tareas ADD COLUMN client_operation_id VARCHAR(36) NULL`,
    `ALTER TABLE tareas ADD COLUMN created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP`,
    `ALTER TABLE tareas ADD COLUMN updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP`,
    `CREATE UNIQUE INDEX uq_tareas_client_operation ON tareas(client_operation_id)`,
  ];

  for (const sql of changes) {
    try { await db.query(sql); console.log('OK:', sql); }
    catch (e) {
      if ([1060, 1061].includes(e.errno)) console.log('Ya existe, se omite:', sql);
      else throw e;
    }
  }

  await db.end();
  console.log('Migración Semana 12 completada.');
}

run().catch((e) => {
  console.error('Error en migración Semana 12:', e.message);
  process.exit(1);
});
