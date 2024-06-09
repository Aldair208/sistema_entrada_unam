------------------------------------------------------------------------------------------
--CREAR Y ACCEDER A BASE DE DATOS "AsistenciaUNAM2024"
CREATE DATABASE AsistenciaUNAM2024;
GO


USE AsistenciaUNAM2024;
GO




-------------- ------- -------  creacion de tablas -------------- ------- -------

------------------------------------------------------------------------------------

CREATE SCHEMA USUARIO;
GO

-- -- -- -- -- -- ESQUEMA USUARIO -- -- -- -- -- -- -- 

CREATE TABLE estudiante (
	estudiante_ID INT PRIMARY KEY IDENTITY, 
    codigo INT,
    dni VARCHAR(10),
    apellidos VARCHAR(100),
    nombres VARCHAR(100),
    facultad VARCHAR(100),
    carrera VARCHAR(100)
);


CREATE TABLE individuo(
	individuo_ID INT PRIMARY KEY IDENTITY, 
    dni VARCHAR(10)
);


ALTER SCHEMA USUARIO TRANSFER dbo.estudiante;
GO
ALTER SCHEMA USUARIO TRANSFER dbo.individuo;
GO


-- -- -- -- -- -- ESQUEMA USUARIO DE LA UNAM -- -- -- -- -- -- -- 
CREATE SCHEMA USUARIO_UNAM;
GO

-- Crear tabla Usuario
CREATE TABLE Usuario (
    Usuario_ID INT PRIMARY KEY IDENTITY,
    tipo_usuario VARCHAR(50)
);

-- Crear tabla Usuario_UNAM
CREATE TABLE Usuario_UNAM (
    Usuario_UNAM_ID INT PRIMARY KEY IDENTITY,
    usuario VARCHAR(50),
    contraseña VARCHAR(50),
    DNI VARCHAR(10),
    nombre VARCHAR(100),
    apellido VARCHAR(100),
    horario VARCHAR(50),
    tipo_usuario_fk INT,
    FOREIGN KEY (tipo_usuario_fk) REFERENCES Usuario(Usuario_ID)
);


-- Crear tabla Administrador
CREATE TABLE Administrador (
    Administrador_ID INT PRIMARY KEY IDENTITY,
    area_responsabilidad VARCHAR(100),
    Usuario_UNAM_fk INT,
    FOREIGN KEY (Usuario_UNAM_fk) REFERENCES Usuario_UNAM(Usuario_UNAM_ID)
);

-- Crear tabla Personal_Servicio_General
CREATE TABLE Personal_Servicio_General (
    Personal_Servicio_General_ID INT PRIMARY KEY IDENTITY,
    Usuario_UNAM_fk INT,
    FOREIGN KEY (Usuario_UNAM_fk) REFERENCES Usuario_UNAM(Usuario_UNAM_ID)
);


ALTER SCHEMA USUARIO_UNAM TRANSFER dbo.Administrador;
GO
ALTER SCHEMA USUARIO_UNAM TRANSFER dbo.Personal_Servicio_General;
GO
ALTER SCHEMA USUARIO_UNAM TRANSFER dbo.Usuario;
GO
ALTER SCHEMA USUARIO_UNAM TRANSFER dbo.Usuario_UNAM;
GO




-- -- -- -- -- -- ESQUEMA ASISTENCIA -- -- -- -- -- -- -- 
CREATE SCHEMA ASISTENCIA;
GO


CREATE TABLE Estado_Ingreso(
	Estado_Asistencia_ID INT PRIMARY KEY IDENTITY, 
    Estado VARCHAR(10)
);

-- Crear tabla registro_estudiante con columna de estado de ingreso como clave foránea
CREATE TABLE registro_estudiante (
    registro_ID INT PRIMARY KEY IDENTITY,
    estudiante_ID INT,
    fecha_hora_Registro DATETIME,
    estado_ingreso INT,
    FOREIGN KEY (estudiante_ID) REFERENCES estudiante(estudiante_ID),
    FOREIGN KEY (estado_ingreso) REFERENCES Estado_Ingreso(Estado_Asistencia_ID)
);

-- Crear tabla registro_individuo con columna de estado de ingreso como clave foránea
CREATE TABLE registro_individuo (
    registro_ID INT PRIMARY KEY IDENTITY,
    individuo_ID INT,
    fecha_hora_Registro DATETIME,
    estado_ingreso INT,
    FOREIGN KEY (individuo_ID) REFERENCES individuo(individuo_ID),
    FOREIGN KEY (estado_ingreso) REFERENCES Estado_Ingreso(Estado_Asistencia_ID)
);


ALTER SCHEMA ASISTENCIA TRANSFER dbo.Estado_Ingreso;
GO
ALTER SCHEMA ASISTENCIA TRANSFER dbo.registro_estudiante;
GO
ALTER SCHEMA ASISTENCIA TRANSFER dbo.registro_individuo;
GO



-- -- -- -- -- -- ESQUEMA REPORTE -- -- -- -- -- -- -- 

CREATE SCHEMA REPORTE;
GO

CREATE TABLE REPORTE.Reporte (
    Reporte_ID INT PRIMARY KEY IDENTITY,
    registro_estudiante_ID INT,
    registro_individuo_ID INT,
    fecha_reporte DATETIME DEFAULT GETDATE(),
    descripcion VARCHAR(255),
    FOREIGN KEY (registro_estudiante_ID) REFERENCES ASISTENCIA.registro_estudiante(registro_ID),
    FOREIGN KEY (registro_individuo_ID) REFERENCES ASISTENCIA.registro_individuo(registro_ID)
);
GO

ALTER SCHEMA REPORTE TRANSFER dbo.Reporte;
GO



---------------------------------------------------------------------------------
--------------------------- ACTIVADORES  ---------------------------------------
---------------------------------------------------------------------------------


CREATE OR ALTER TRIGGER TRG_Agregar_Individuo
ON estudiante
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @codigo INT,
            @dni VARCHAR(10),
            @estudiante_ID INT,
            @existente INT;

    SELECT @codigo = i.codigo, @dni = i.dni FROM inserted i;

    -- Verificar si el estudiante ya existe en la tabla individuo
    SELECT @existente = COUNT(*) FROM individuo WHERE dni = @dni;

    -- Si el estudiante no existe, se agrega a la tabla individuo
    IF @existente = 0
    BEGIN
        INSERT INTO individuo (dni) VALUES (@dni);
    END
END;





---------------------------------------------------------------------------------
--------------------------------PROCEDIMIENTOS ALMACENADOS-------------------------------------
---------------------------------------------------------------------------------





-- Procedimiento almacenado para borrar y reiniciar tabla estudiante
CREATE OR ALTER PROCEDURE Reset_Estudiante
AS
BEGIN
    SET NOCOUNT ON;

    -- Borrar todo el contenido de la tabla estudiante
    DELETE FROM Estudiante;

    -- Reiniciar la numeración de la tabla estudiante
    DBCC CHECKIDENT ('Estudiante', RESEED, 0);
END;
GO

-- Procedimiento almacenado para borrar y reiniciar tabla individuo
CREATE OR ALTER PROCEDURE Reset_Individuo
AS
BEGIN
    SET NOCOUNT ON;

    -- Borrar todo el contenido de la tabla individuo
    DELETE FROM Individuo;

    -- Reiniciar la numeración de la tabla individuo
    DBCC CHECKIDENT ('Individuo', RESEED, 0);
END;




-- Procedimiento almacenado para borrar y reiniciar tabla Registro_estudiante
CREATE OR ALTER PROCEDURE Reset_Registro_Estudiante
AS
BEGIN
    SET NOCOUNT ON;

    -- Borrar todo el contenido de la tabla estudiante
    DELETE FROM registro_estudiante;

    -- Reiniciar la numeración de la tabla estudiante
    DBCC CHECKIDENT ('registro_estudiante', RESEED, 0);
END;
GO

-- Procedimiento almacenado para borrar y reiniciar tabla Registro_individuo
CREATE OR ALTER PROCEDURE Reset_Registro_Individuo
AS
BEGIN
    SET NOCOUNT ON;

    -- Borrar todo el contenido de la tabla individuo
    DELETE FROM registro_individuo;

    -- Reiniciar la numeración de la tabla individuo
    DBCC CHECKIDENT ('registro_individuo', RESEED, 0);
END;
GO








--------------------------------------------------------------------------------------------
-- Procedimiento almacenado para gestionar el escaneo del ID y el registro de entrada/salida
--------------------------------------------------------------------------------------------



CREATE OR ALTER PROCEDURE Registrar_Ingreso
    @codigo VARCHAR(10), -- Cambiar el tipo de dato de INT a VARCHAR
    @fecha_hora DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @estudiante_existente INT, @individuo_existente INT, @ultimo_estado_ingreso INT;

    -- Verificar si el código corresponde a un estudiante
    SELECT @estudiante_existente = COUNT(*) FROM estudiante WHERE codigo = @codigo OR dni = @codigo;

    -- Verificar si el código corresponde a un individuo
    SELECT @individuo_existente = COUNT(*) FROM individuo WHERE dni = @codigo;

    -- Obtener el estado del último registro de ingreso
    SELECT TOP 1 @ultimo_estado_ingreso = estado_ingreso
    FROM (
        SELECT estado_ingreso, ROW_NUMBER() OVER (ORDER BY fecha_hora_registro DESC) AS rn
        FROM registro_estudiante 
        WHERE estudiante_ID = (
            SELECT estudiante_ID 
            FROM estudiante 
            WHERE codigo = @codigo OR dni = @codigo
        )
        UNION ALL
        SELECT estado_ingreso, ROW_NUMBER() OVER (ORDER BY fecha_hora_registro DESC) AS rn
        FROM registro_individuo 
        WHERE individuo_ID = (
            SELECT individuo_ID 
            FROM individuo 
            WHERE dni = @codigo
        )
    ) AS LastEntry
    WHERE rn = 1;

    -- Si el código corresponde a un estudiante
    IF @estudiante_existente > 0
    BEGIN
        -- Insertar registro en la tabla registro_estudiante
        INSERT INTO registro_estudiante (estudiante_ID, fecha_hora_registro, estado_ingreso)
        VALUES (
            (SELECT estudiante_ID FROM estudiante WHERE codigo = @codigo OR dni = @codigo),
            @fecha_hora,
            CASE @ultimo_estado_ingreso
                WHEN 1 THEN 2 -- Si el último estado fue "entrada", establecer "salida" para el nuevo registro
                ELSE 1 -- Si el último estado fue "salida" o no hay registros anteriores, establecer "entrada"
            END
        );
    END
    ELSE
    BEGIN
        -- Si el código corresponde a un individuo
        IF @individuo_existente > 0
        BEGIN
            -- Insertar registro en la tabla registro_individuo
            INSERT INTO registro_individuo (individuo_ID, fecha_hora_registro, estado_ingreso)
            VALUES (
                (SELECT individuo_ID FROM individuo WHERE dni = @codigo),
                @fecha_hora,
                CASE @ultimo_estado_ingreso
                    WHEN 1 THEN 2 -- Si el último estado fue "entrada", establecer "salida" para el nuevo registro
                    ELSE 1 -- Si el último estado fue "salida" o no hay registros anteriores, establecer "entrada"
                END
            );
        END
        ELSE
        BEGIN
            -- Si no existe el individuo, agregarlo primero
            INSERT INTO individuo (dni) VALUES (@codigo);
            -- Obtener el ID del individuo recién creado
            DECLARE @nuevo_individuo_id INT;
            SET @nuevo_individuo_id = SCOPE_IDENTITY();
            -- Insertar registro en la tabla registro_individuo
            INSERT INTO registro_individuo (individuo_ID, fecha_hora_registro, estado_ingreso)
            VALUES (
                @nuevo_individuo_id,
                @fecha_hora,
                1
            );
        END
    END;
END;
GO




-- -- -- -- -- -- -- -- -- -- -- -- 


DECLARE @codigo INT = 73092522; -- Este sería el código escaneado
DECLARE @fecha_hora DATETIME = GETDATE(); -- Esto obtiene la fecha y hora actual

EXEC Registrar_Ingreso @codigo, @fecha_hora;


-- -- -- -- -- -- -- -- -- -- -- -- 


DECLARE @codigo INT = 1234567890; -- Este sería el código escaneado
DECLARE @fecha_hora DATETIME = GETDATE(); -- Esto obtiene la fecha y hora actual

EXEC Registrar_Ingreso @codigo, @fecha_hora;







-- MOSTRAR VALORES DE ESTUDIANTES E INDIVIDUOS	

SELECT * FROM estudiante;
SELECT * FROM individuo;

-- MOSTRAR REGISTROS DE ESTUDIANTES E INDIVIDUOS
	

SELECT * FROM registro_estudiante ORDER BY fecha_hora_registro DESC;
SELECT * FROM registro_individuo ORDER BY fecha_hora_registro DESC;


-- REINICIAR DE CERO LOS REGISTROS Y VALORES DE ESTUDIANTES E INDIVIDUOS

EXEC Reset_Registro_Estudiante
EXEC Reset_Registro_Individuo;

EXEC Reset_Estudiante
EXEC Reset_Individuo;





