const sql = require("mssql");
require("dotenv").config();

console.log("--- DIAGNÓSTICO DE CONEXIÓN ---");
console.log("Servidor:", process.env.DB_SERVER);
console.log("Usuario:", process.env.DB_USER);
console.log("Password cargado:", process.env.DB_PASSWORD);
console.log("Base de datos:", process.env.DB_DATABASE);
console.log("-------------------------------");

const dbConfig = {
  user: process.env.DB_USER || "sa",
  password: process.env.DB_PASSWORD || "Bd2026Segura!",
  server: process.env.DB_SERVER || "127.0.0.1",
  database: process.env.DB_DATABASE || "CuentaAhorrosDB",
  port: parseInt(process.env.DB_PORT, 10) || 1433,
  options: {
    encrypt: false,
    trustServerCertificate: true,
  },
};

const poolPromise = new sql.ConnectionPool(dbConfig)
  .connect()
  .then((pool) => {
    console.log("✅ Conectado a SQL Server correctamente.");
    return pool;
  })
  .catch((err) => {
    console.error("❌ Error de conexión a la Base de Datos:", err.message);
    process.exit(1);
  });

module.exports = { sql, poolPromise };
