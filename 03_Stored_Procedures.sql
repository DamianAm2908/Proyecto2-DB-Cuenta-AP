USE CuentaAhorrosDB;
GO

-- ==========================================
-- 1. AUTENTICACIÓN Y BITÁCORA
-- ==========================================

CREATE OR ALTER PROCEDURE sp_AutenticarUsuario
    @Username VARCHAR(32),
    @Password VARCHAR(64),
    @IP VARCHAR(45)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @IdUsuario INT;
    DECLARE @EsAdmin BIT;

    SELECT @IdUsuario = Id, @EsAdmin = EsAdministrador
    FROM Usuario
    WHERE Username = @Username AND PasswordHash = @Password;

    IF @IdUsuario IS NOT NULL
    BEGIN
        -- Registrar Login exitoso en Bitácora (IdTipoOperacion 1 = Login)
        INSERT INTO Bitacora (IdUsuario, IdTipoOperacion, IP, FechaHora)
        VALUES (@IdUsuario, 1, @IP, GETDATE());

        SELECT @IdUsuario AS IdUsuario, @Username AS Username, @EsAdmin AS EsAdministrador, 1 AS ErrorCode, 'Login exitoso' AS Message;
    END
    ELSE
    BEGIN
        SELECT NULL AS IdUsuario, NULL AS Username, NULL AS EsAdministrador, -1 AS ErrorCode, 'Usuario o contraseña incorrectos' AS Message;
    END
END;
GO

CREATE OR ALTER PROCEDURE sp_RegistrarLogout
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Registrar Logout en Bitácora (IdTipoOperacion 2 = Logout)
    INSERT INTO Bitacora (IdUsuario, IdTipoOperacion, FechaHora)
    VALUES (@IdUsuario, 2, GETDATE());

    SELECT 1 AS ErrorCode, 'Logout registrado' AS Message;
END;
GO

-- ==========================================
-- 2. MANTENIMIENTO DE BENEFICIARIOS
-- ==========================================

CREATE OR ALTER PROCEDURE sp_ObtenerBeneficiariosPorCuenta
    @IdCuenta INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        b.Id AS IdBeneficiario,
        p.Nombre,
        p.ValorDocumentoIdentidad,
        p.TipoDocuIdentidad,
        td.Nombre AS TipoDocumentoNombre,
        p.FechaNacimiento,
        p.Email,
        p.Telefono1,
        p.Telefono2,
        b.IdParentezco,
        par.Nombre AS ParentezcoNombre,
        b.Porcentaje
    FROM Beneficiario b
    INNER JOIN Persona p ON p.Id = b.IdPersonaBeneficiario
    INNER JOIN TipoDocuIdentidad td ON td.Id = p.TipoDocuIdentidad
    INNER JOIN Parentezco par ON par.Id = b.IdParentezco
    WHERE b.IdCuenta = @IdCuenta AND b.FlagActivo = 1;
END;
GO

CREATE OR ALTER PROCEDURE sp_AgregarBeneficiario
    @IdUsuario INT,
    @IdCuenta INT,
    @TipoDocId INT,
    @ValorDocId VARCHAR(32),
    @Nombre VARCHAR(64),
    @FechaNacimiento DATE,
    @Email VARCHAR(128),
    @Telefono1 VARCHAR(16),
    @Telefono2 VARCHAR(16),
    @IdParentezco INT,
    @Porcentaje INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Validar máximo 3 beneficiarios activos
        DECLARE @CantidadActivos INT;
        SELECT @CantidadActivos = COUNT(*) FROM Beneficiario WHERE IdCuenta = @IdCuenta AND FlagActivo = 1;

        IF @CantidadActivos >= 3
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT -1 AS ErrorCode, 'No se pueden registrar más de 3 beneficiarios activos.' AS Message;
            RETURN;
        END

        -- Buscar o insertar la persona
        DECLARE @IdPersona INT;
        SELECT @IdPersona = Id FROM Persona WHERE ValorDocumentoIdentidad = @ValorDocId;

        IF @IdPersona IS NULL
        BEGIN
            INSERT INTO Persona (TipoDocuIdentidad, ValorDocumentoIdentidad, Nombre, FechaNacimiento, Email, Telefono1, Telefono2)
            VALUES (@TipoDocId, @ValorDocId, @Nombre, @FechaNacimiento, @Email, @Telefono1, @Telefono2);
            
            SET @IdPersona = SCOPE_IDENTITY();
        END

        -- Insertar Beneficiario
        INSERT INTO Beneficiario (IdCuenta, IdPersonaBeneficiario, IdParentezco, Porcentaje, FlagActivo)
        VALUES (@IdCuenta, @IdPersona, @IdParentezco, @Porcentaje, 1);

        DECLARE @IdBeneficiario INT = SCOPE_IDENTITY();

        -- JSON para la Bitácora
        DECLARE @JsonNuevo NVARCHAR(MAX) = (
            SELECT @IdBeneficiario AS IdBeneficiario, @Nombre AS Nombre, @ValorDocId AS ValorDocId, @Porcentaje AS Porcentaje
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        -- Registrar en Bitácora (Tipo 3 = Agregar beneficiario)
        INSERT INTO Bitacora (IdUsuario, IdTipoOperacion, JsonDespues, FechaHora)
        VALUES (@IdUsuario, 3, @JsonNuevo, GETDATE());

        COMMIT TRANSACTION;
        SELECT 1 AS ErrorCode, 'Beneficiario agregado exitosamente.' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT -2 AS ErrorCode, ERROR_MESSAGE() AS Message;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_EliminarBeneficiarioLogico
    @IdUsuario INT,
    @IdBeneficiario INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Obtener JSON antes de la eliminación
        DECLARE @JsonAntes NVARCHAR(MAX) = (
            SELECT b.Id, p.Nombre, b.Porcentaje, b.FlagActivo
            FROM Beneficiario b
            INNER JOIN Persona p ON p.Id = b.IdPersonaBeneficiario
            WHERE b.Id = @IdBeneficiario
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        -- Borrado Lógico
        UPDATE Beneficiario
        SET FlagActivo = 0, FechaDesactivacion = GETDATE()
        WHERE Id = @IdBeneficiario;

        -- Registrar en Bitácora (Tipo 5 = Eliminar beneficiario)
        INSERT INTO Bitacora (IdUsuario, IdTipoOperacion, JsonAntes, FechaHora)
        VALUES (@IdUsuario, 5, @JsonAntes, GETDATE());

        COMMIT TRANSACTION;
        SELECT 1 AS ErrorCode, 'Beneficiario eliminado lógicamente.' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT -2 AS ErrorCode, ERROR_MESSAGE() AS Message;
    END CATCH
END;
GO

-- ==========================================
-- 3. CONSULTA DE ESTADOS DE CUENTA
-- ==========================================

CREATE OR ALTER PROCEDURE sp_ObtenerUltimosEstadosCuenta
    @IdUsuario INT,
    @IdCuenta INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Registrar consulta en Bitácora (Tipo 7 = Consultar estado de cuenta)
    INSERT INTO Bitacora (IdUsuario, IdTipoOperacion, FechaHora)
    VALUES (@IdUsuario, 7, GETDATE());

    -- Retornar los últimos 8 estados de cuenta
    SELECT TOP 8
        ec.Id,
        ec.FechaInicio,
        ec.FechaFin,
        ec.SaldoInicial,
        ec.SaldoMinimo,
        ec.SaldoFinal
    FROM EstadoCuenta ec
    WHERE ec.IdCuenta = @IdCuenta
    ORDER BY ec.FechaFin DESC;
END;
GO