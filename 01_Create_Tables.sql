-- Crear la base de datos si no existe
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'CuentaAhorrosDB')
BEGIN
    CREATE DATABASE CuentaAhorrosDB;
END
GO

USE CuentaAhorrosDB;
GO

-- ==========================================
-- 1. TABLAS CATÁLOGO (Sin IDENTITY)
-- ==========================================

CREATE TABLE TipoDocuIdentidad (
    Id INT PRIMARY KEY,
    Nombre VARCHAR(64) NOT NULL
);

CREATE TABLE TipoMoneda (
    Id INT PRIMARY KEY,
    Nombre VARCHAR(32) NOT NULL,
    Simbolo VARCHAR(8) NOT NULL
);

CREATE TABLE Parentezco (
    Id INT PRIMARY KEY,
    Nombre VARCHAR(32) NOT NULL
);

CREATE TABLE TipoCuentaAhorro (
    Id INT PRIMARY KEY,
    Nombre VARCHAR(64) NOT NULL,
    IdTipoMoneda INT NOT NULL FOREIGN KEY REFERENCES TipoMoneda(Id),
    SaldoMinimo MONEY NOT NULL,
    MultaSaldoMin MONEY NOT NULL,
    CargoAnual MONEY NOT NULL,
    NumRetirosHumano INT NOT NULL,
    NumRetirosAutomatico INT NOT NULL,
    ComisionHumano MONEY NOT NULL,
    ComisionAutomatico MONEY NOT NULL,
    Interes DECIMAL(5,2) NOT NULL
);

CREATE TABLE TipoOperacionesBitacora (
    Id INT PRIMARY KEY,
    Nombre VARCHAR(64) NOT NULL
);

-- ==========================================
-- 2. TABLAS NO-CATÁLOGO (Con IDENTITY)
-- ==========================================

CREATE TABLE Persona (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    TipoDocuIdentidad INT NOT NULL FOREIGN KEY REFERENCES TipoDocuIdentidad(Id),
    ValorDocumentoIdentidad VARCHAR(32) NOT NULL UNIQUE, -- Llave alterna
    Nombre VARCHAR(64) NOT NULL,
    FechaNacimiento DATE NOT NULL,
    Email VARCHAR(128) NOT NULL,
    Telefono1 VARCHAR(16) NOT NULL,
    Telefono2 VARCHAR(16) NOT NULL
);

CREATE TABLE Cuenta (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    NumeroCuenta VARCHAR(32) NOT NULL UNIQUE, -- Llave alterna
    IdPersonaCliente INT NOT NULL FOREIGN KEY REFERENCES Persona(Id),
    TipoCuentaId INT NOT NULL FOREIGN KEY REFERENCES TipoCuentaAhorro(Id),
    FechaCreacion DATE NOT NULL,
    Saldo MONEY NOT NULL
);

CREATE TABLE Beneficiario (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    IdCuenta INT NOT NULL FOREIGN KEY REFERENCES Cuenta(Id),
    IdPersonaBeneficiario INT NOT NULL FOREIGN KEY REFERENCES Persona(Id),
    IdParentezco INT NOT NULL FOREIGN KEY REFERENCES Parentezco(Id),
    Porcentaje INT NOT NULL,
    FlagActivo BIT NOT NULL DEFAULT 1,
    FechaDesactivacion DATETIME NULL
);

CREATE TABLE EstadoCuenta (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    IdCuenta INT NOT NULL FOREIGN KEY REFERENCES Cuenta(Id),
    FechaInicio DATE NOT NULL,
    FechaFin DATE NOT NULL,
    SaldoInicial MONEY NOT NULL,
    SaldoMinimo MONEY NOT NULL,
    SaldoFinal MONEY NOT NULL
);

CREATE TABLE Usuario (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    IdPersona INT NOT NULL FOREIGN KEY REFERENCES Persona(Id),
    Username VARCHAR(32) NOT NULL UNIQUE,
    PasswordHash VARCHAR(64) NOT NULL,
    EsAdministrador BIT NOT NULL DEFAULT 0
);

CREATE TABLE UsuarioPuedeVer (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    IdUsuario INT NOT NULL FOREIGN KEY REFERENCES Usuario(Id),
    IdCuenta INT NOT NULL FOREIGN KEY REFERENCES Cuenta(Id)
);

CREATE TABLE Bitacora (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    IdUsuario INT NOT NULL FOREIGN KEY REFERENCES Usuario(Id),
    IdTipoOperacion INT NOT NULL FOREIGN KEY REFERENCES TipoOperacionesBitacora(Id),
    IP VARCHAR(45) NULL,
    JsonAntes NVARCHAR(MAX) NULL,
    JsonDespues NVARCHAR(MAX) NULL,
    FechaHora DATETIME NOT NULL DEFAULT GETDATE()
);
GO