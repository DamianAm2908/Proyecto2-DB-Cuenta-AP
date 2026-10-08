USE CuentaAhorrosDB;
GO

-- Variable para almacenar el contenido del XML
DECLARE @xmlData XML = '
<Datos>
  <!-- Catalogos -->
  <Tipo_Doc>
    <TipoDocuIdentidad Id="1" Nombre="Cedula Nacional"/>
    <TipoDocuIdentidad Id="2" Nombre="Cedula Residente"/>
    <TipoDocuIdentidad Id="3" Nombre="Pasaporte"/>
    <TipoDocuIdentidad Id="4" Nombre="Cedula Juridica"/>
    <TipoDocuIdentidad Id="5" Nombre="Permiso de Trabajo"/>
    <TipoDocuIdentidad Id="6" Nombre="Cedula Extranjera"/>
  </Tipo_Doc>
  
  <Tipo_Moneda>
    <TipoMoneda Id="1" Nombre="Colones" Simbolo="₡"/>
    <TipoMoneda Id="2" Nombre="Dolares" Simbolo="$"/>
    <TipoMoneda Id="3" Nombre="Euros" Simbolo="€"/>
  </Tipo_Moneda>
  
  <Parentezcos>
    <Parentezco Id="1" Nombre="Padre"/>
    <Parentezco Id="2" Nombre="Madre"/>
    <Parentezco Id="3" Nombre="Hijo"/>
    <Parentezco Id="4" Nombre="Hija"/>
    <Parentezco Id="5" Nombre="Hermano"/>
    <Parentezco Id="6" Nombre="Hermana"/>
    <Parentezco Id="7" Nombre="amigo"/>
    <Parentezco Id="8" Nombre="amiga"/>
  </Parentezcos>
  
  <Tipo_Cuenta_Ahorros>
    <TipoCuentaAhorro Id="1" Nombre="Proletario" IdTipoMoneda="1" SaldoMinimo="25000.00" MultaSaldoMin="3000.00" CargoAnual="5000" NumRetirosHumano="5" NumRetirosAutomatico="8" comisionHumano="300" comisionAutomatico="300" interes="10" />
    <TipoCuentaAhorro Id="2" Nombre="Profesional" IdTipoMoneda="1" SaldoMinimo="5000.00" MultaSaldoMin="3000.00" CargoAnual="15000" NumRetirosHumano="5" NumRetirosAutomatico="8" comisionHumano="500" comisionAutomatico="500" interes="15" />
    <TipoCuentaAhorro Id="3" Nombre="Exclusivo" IdTipoMoneda="1" SaldoMinimo="10000.00" MultaSaldoMin="3000.00" CargoAnual="3000" NumRetirosHumano="5" NumRetirosAutomatico="8" comisionHumano="1000" comisionAutomatico="1000" interes="20" />
  </Tipo_Cuenta_Ahorros>
  
  <TipoOperacionesBitacora>
    <TipoOperacion id="1" nombre="Login"/>
    <TipoOperacion id="2" nombre="Logout"/>
    <TipoOperacion id="3" nombre="Agregar beneficiario"/>
    <TipoOperacion id="4" nombre="Actualizar beneficiario"/>
    <TipoOperacion id="5" nombre="Eliminar beneficiario"/>
    <TipoOperacion id="6" nombre="Actualizar porcentaje de beneficiario"/>
    <TipoOperacion id="7" nombre="Consultar estado de cuenta"/>
  </TipoOperacionesBitacora>

  <!-- Entidades No-Catalogos -->
  <Personas>
    <Persona TipoDocuIdentidad="1" Nombre="Javith Aguero Hernandez" ValorDocumentoIdentidad="117370445" FechaNacimiento="1999-03-20" Email="aguerojavith@gmail.com" telefono1="85343403" telefono2="24197636"/>
    <Persona TipoDocuIdentidad="1" Nombre="Osvaldo Aguero Hernandez" ValorDocumentoIdentidad="12738545" FechaNacimiento="1994-10-13" Email="osadage@gmail.com" telefono1="87541766" telefono2="24197545"/>
    <Persona TipoDocuIdentidad="1" Nombre="Franco Quiros Ramirez" ValorDocumentoIdentidad="130004000" FechaNacimiento="1994-10-13" Email="osadage@gmail.com" telefono1="87541766" telefono2="24197545"/>
  </Personas>

  <Cuentas>
    <Cuenta ValorDocumentoIdentidadDelCliente="117370445" TipoCuentaId="1" NumeroCuenta="11000001" FechaCreacion="2020-10-13" Saldo="100000.00"/>
  </Cuentas>

  <Beneficiarios>
    <Beneficiario NumeroCuenta="11000001" ValorDocumentoIdentidadBeneficiario="117370445" IdParentezco="5" Porcentaje="25"/>
  </Beneficiarios>

  <Estados_de_Cuenta>
    <Estado_de_Cuenta NumeroCuenta="11000001" fechaInicio="2020-10-13" fechafin="2020-11-12" saldoinicial="1000000.00" saldoMinimo="2000.00" saldo_final="1250000.00"/>
  </Estados_de_Cuenta>

  <Usuarios>
    <Usuario User="jaguero" Pass="LaFacil" EsAdministrador="0" ValorDocId="117370445"/>
    <Usuario User="fquiros" Pass="MyPass123*" EsAdministrador="1" ValorDocId="130004000"/>
  </Usuarios>

  <Usuarios_Ver>
    <UsuarioPuedeVer User="jaguero" NumeroCuenta="11000001"/>
  </Usuarios_Ver>
</Datos>';

DECLARE @hDoc INT;
EXEC sp_xml_preparedocument @hDoc OUTPUT, @xmlData;

-- 1. Insertar Catálogos (Llaves explicitas del XML)
INSERT INTO TipoDocuIdentidad (Id, Nombre)
SELECT Id, Nombre FROM OPENXML(@hDoc, '/Datos/Tipo_Doc/TipoDocuIdentidad', 1) WITH (Id INT, Nombre VARCHAR(64));

INSERT INTO TipoMoneda (Id, Nombre, Simbolo)
SELECT Id, Nombre, Simbolo FROM OPENXML(@hDoc, '/Datos/Tipo_Moneda/TipoMoneda', 1) WITH (Id INT, Nombre VARCHAR(32), Simbolo VARCHAR(8));

INSERT INTO Parentezco (Id, Nombre)
SELECT Id, Nombre FROM OPENXML(@hDoc, '/Datos/Parentezcos/Parentezco', 1) WITH (Id INT, Nombre VARCHAR(32));

INSERT INTO TipoCuentaAhorro (Id, Nombre, IdTipoMoneda, SaldoMinimo, MultaSaldoMin, CargoAnual, NumRetirosHumano, NumRetirosAutomatico, ComisionHumano, ComisionAutomatico, Interes)
SELECT Id, Nombre, IdTipoMoneda, SaldoMinimo, MultaSaldoMin, CargoAnual, NumRetirosHumano, NumRetirosAutomatico, comisionHumano, comisionAutomatico, interes
FROM OPENXML(@hDoc, '/Datos/Tipo_Cuenta_Ahorros/TipoCuentaAhorro', 1) 
WITH (Id INT, Nombre VARCHAR(64), IdTipoMoneda INT, SaldoMinimo MONEY, MultaSaldoMin MONEY, CargoAnual MONEY, NumRetirosHumano INT, NumRetirosAutomatico INT, comisionHumano MONEY, comisionAutomatico MONEY, interes DECIMAL(5,2));

INSERT INTO TipoOperacionesBitacora (Id, Nombre)
SELECT id, nombre FROM OPENXML(@hDoc, '/Datos/TipoOperacionesBitacora/TipoOperacion', 1) WITH (id INT, nombre VARCHAR(64));

-- 2. Insertar Personas
INSERT INTO Persona (TipoDocuIdentidad, ValorDocumentoIdentidad, Nombre, FechaNacimiento, Email, Telefono1, Telefono2)
SELECT TipoDocuIdentidad, ValorDocumentoIdentidad, Nombre, FechaNacimiento, Email, telefono1, telefono2
FROM OPENXML(@hDoc, '/Datos/Personas/Persona', 1)
WITH (TipoDocuIdentidad INT, ValorDocumentoIdentidad VARCHAR(32), Nombre VARCHAR(64), FechaNacimiento DATE, Email VARCHAR(128), telefono1 VARCHAR(16), telefono2 VARCHAR(16));

-- 3. Insertar Cuentas (Resolviendo FK mediante ValorDocumentoIdentidad)
INSERT INTO Cuenta (NumeroCuenta, IdPersonaCliente, TipoCuentaId, FechaCreacion, Saldo)
SELECT x.NumeroCuenta, p.Id, x.TipoCuentaId, x.FechaCreacion, x.Saldo
FROM OPENXML(@hDoc, '/Datos/Cuentas/Cuenta', 1)
WITH (ValorDocumentoIdentidadDelCliente VARCHAR(32), TipoCuentaId INT, NumeroCuenta VARCHAR(32), FechaCreacion DATE, Saldo MONEY) x
INNER JOIN Persona p ON p.ValorDocumentoIdentidad = x.ValorDocumentoIdentidadDelCliente;

-- 4. Insertar Beneficiarios (Resolviendo FKs)
INSERT INTO Beneficiario (IdCuenta, IdPersonaBeneficiario, IdParentezco, Porcentaje, FlagActivo)
SELECT c.Id, p.Id, x.IdParentezco, x.Porcentaje, 1
FROM OPENXML(@hDoc, '/Datos/Beneficiarios/Beneficiario', 1)
WITH (NumeroCuenta VARCHAR(32), ValorDocumentoIdentidadBeneficiario VARCHAR(32), IdParentezco INT, Porcentaje INT) x
INNER JOIN Cuenta c ON c.NumeroCuenta = x.NumeroCuenta
INNER JOIN Persona p ON p.ValorDocumentoIdentidad = x.ValorDocumentoIdentidadBeneficiario;

-- 5. Insertar Estados de Cuenta (Resolviendo FK)
INSERT INTO EstadoCuenta (IdCuenta, FechaInicio, FechaFin, SaldoInicial, SaldoMinimo, SaldoFinal)
SELECT c.Id, x.fechaInicio, x.fechafin, x.saldoinicial, x.saldoMinimo, x.saldo_final
FROM OPENXML(@hDoc, '/Datos/Estados_de_Cuenta/Estado_de_Cuenta', 1)
WITH (NumeroCuenta VARCHAR(32), fechaInicio DATE, fechafin DATE, saldoinicial MONEY, saldoMinimo MONEY, saldo_final MONEY) x
INNER JOIN Cuenta c ON c.NumeroCuenta = x.NumeroCuenta;

-- 6. Insertar Usuarios
INSERT INTO Usuario (IdPersona, Username, PasswordHash, EsAdministrador)
SELECT p.Id, x.[User], x.Pass, x.EsAdministrador
FROM OPENXML(@hDoc, '/Datos/Usuarios/Usuario', 1)
WITH ([User] VARCHAR(32), Pass VARCHAR(64), EsAdministrador BIT, ValorDocId VARCHAR(32)) x
INNER JOIN Persona p ON p.ValorDocumentoIdentidad = x.ValorDocId;

-- 7. Insertar UsuarioPuedeVer
INSERT INTO UsuarioPuedeVer (IdUsuario, IdCuenta)
SELECT u.Id, c.Id
FROM OPENXML(@hDoc, '/Datos/Usuarios_Ver/UsuarioPuedeVer', 1)
WITH ([User] VARCHAR(32), NumeroCuenta VARCHAR(32)) x
INNER JOIN Usuario u ON u.Username = x.[User]
INNER JOIN Cuenta c ON c.NumeroCuenta = x.NumeroCuenta;

EXEC sp_xml_removedocument @hDoc;
GO