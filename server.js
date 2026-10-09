const express = require("express");
const cors = require("cors");
const { sql, poolPromise } = require("./db");
require("dotenv").config();

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static("public")); // Para servir HTML/JS estáticos

// Route 1: Login
app.post("/api/login", async (req, res) => {
  const { username, password } = req.body;
  const clientIp = req.ip || req.connection.remoteAddress;

  try {
    const pool = await poolPromise;
    const result = await pool
      .request()
      .input("Username", sql.VarChar(32), username)
      .input("Password", sql.VarChar(64), password)
      .input("IP", sql.VarChar(45), clientIp)
      .execute("sp_AutenticarUsuario");

    const user = result.recordset[0];
    if (user && user.ErrorCode === 1) {
      res.json({ success: true, user });
    } else {
      res
        .status(401)
        .json({
          success: false,
          message: user.Message || "Credenciales inválidas",
        });
    }
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Route 2: Obtener Beneficiarios
app.get("/api/beneficiarios/:idCuenta", async (req, res) => {
  const { idCuenta } = req.params;

  try {
    const pool = await poolPromise;
    const result = await pool
      .request()
      .input("IdCuenta", sql.Int, idCuenta)
      .execute("sp_ObtenerBeneficiariosPorCuenta");

    res.json({ success: true, beneficiarios: result.recordset });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Route 3: Obtener Estados de Cuenta (Últimos 8)
app.get("/api/estados-cuenta/:idCuenta", async (req, res) => {
  const { idCuenta } = req.params;
  const { idUsuario } = req.query;

  try {
    const pool = await poolPromise;
    const result = await pool
      .request()
      .input("IdUsuario", sql.Int, idUsuario || 1)
      .input("IdCuenta", sql.Int, idCuenta)
      .execute("sp_ObtenerUltimosEstadosCuenta");

    res.json({ success: true, estadosCuenta: result.recordset });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
});
