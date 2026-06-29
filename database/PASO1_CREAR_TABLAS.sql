-- ============================================================
-- PASO 1: CREAR BASE DE DATOS Y TABLAS
-- Ejecutar primero en SQL Server Management Studio
-- Abrir con: Archivo -> Abrir -> seleccionar este archivo
-- Luego presionar F5 o clic en Ejecutar
-- ============================================================

-- Crear la base de datos
CREATE DATABASE PELICULAS_SERIES;
GO

USE PELICULAS_SERIES;
GO

-- ============================================================
-- TABLAS DIMENSION
-- ============================================================

-- 1. DimCalendario
CREATE TABLE DimCalendario(
    Fecha      DATE         NOT NULL,
    Anio       INT          NOT NULL,
    Mes        INT          NOT NULL,
    NombreMes  VARCHAR(20)  NOT NULL,
    Dia        INT          NOT NULL,
    NombreDia  VARCHAR(20)  NOT NULL,
    Trimestre  INT          NOT NULL,
    CONSTRAINT PK_DimCalendario PRIMARY KEY (Fecha)
);
GO

-- 2. DimDispositivo
CREATE TABLE DimDispositivo(
    idDispositivo    INT         NOT NULL,
    TipoDispositivo  VARCHAR(50) NOT NULL,
    SistemaOperativo VARCHAR(50) NULL,
    CONSTRAINT PK_DimDispositivo PRIMARY KEY (idDispositivo)
);
GO

-- 3. DimPelicula
CREATE TABLE DimPelicula(
    idPelicula  INT          NOT NULL,
    Nombre      VARCHAR(200) NOT NULL,
    Genero      VARCHAR(50)  NOT NULL,
    Tipo        VARCHAR(20)  NOT NULL,
    Duracion    INT          NOT NULL,
    AnioEstreno INT          NOT NULL,
    CONSTRAINT PK_DimPelicula PRIMARY KEY (idPelicula)
);
GO

-- 4. DimPlan
CREATE TABLE DimPlan(
    idPlan        INT          NOT NULL,
    Descripcion   VARCHAR(100) NOT NULL,
    Precio        DECIMAL(8,2) NOT NULL,
    CantPantallas INT          NOT NULL,
    CalidadMax    VARCHAR(10)  NOT NULL,
    FlgEstado     BIT          NOT NULL,
    CONSTRAINT PK_DimPlan PRIMARY KEY (idPlan)
);
GO

-- 5. DimTipoEvento
CREATE TABLE DimTipoEvento(
    idTipEven   INT          NOT NULL,
    Descrip     VARCHAR(100) NOT NULL,
    Categoria   VARCHAR(50)  NOT NULL,
    Plataforma  VARCHAR(50)  NOT NULL,
    Importancia VARCHAR(20)  NOT NULL,
    CONSTRAINT PK_DimTipoEvento PRIMARY KEY (idTipEven)
);
GO

-- 6. DimUsuario
CREATE TABLE DimUsuario(
    idUsuario INT          NOT NULL,
    Nombre    VARCHAR(100) NOT NULL,
    ApePat    VARCHAR(100) NOT NULL,
    ApeMat    VARCHAR(100) NULL,
    Correo    VARCHAR(200) NOT NULL,
    Distrito  VARCHAR(100) NULL,
    FecAlta   DATE         NOT NULL,
    FecBaja   DATE         NULL,
    CONSTRAINT PK_DimUsuario PRIMARY KEY (idUsuario)
);
GO

-- ============================================================
-- TABLAS DE HECHOS
-- ============================================================

-- 7. FacEventos
CREATE TABLE FacEventos(
    idEventos     INT  NOT NULL,
    idUsuario     INT  NOT NULL,
    idTipEven     INT  NOT NULL,
    idPelicula    INT  NOT NULL,
    idDispositivo INT  NOT NULL,
    FecEve        DATE NOT NULL,
    CONSTRAINT PK_FacEventos PRIMARY KEY (idEventos)
);
GO

-- 8. FactSuscripcion
CREATE TABLE FactSuscripcion(
    idSuscrip  INT         NOT NULL,
    idUsuario  INT         NOT NULL,
    idPlan     INT         NOT NULL,
    FecSuscrip DATE        NOT NULL,
    FlgEstado  BIT         NOT NULL,
    MetodoPago VARCHAR(50) NOT NULL,
    CONSTRAINT PK_FactSuscripcion PRIMARY KEY (idSuscrip)
);
GO

-- ============================================================
-- CLAVES FORANEAS (FK)
-- ============================================================

-- FK de FacEventos
ALTER TABLE FacEventos ADD CONSTRAINT FK_FacEve_Calendario
    FOREIGN KEY (FecEve) REFERENCES DimCalendario (Fecha);
GO
ALTER TABLE FacEventos ADD CONSTRAINT FK_FacEve_Dispositivo
    FOREIGN KEY (idDispositivo) REFERENCES DimDispositivo (idDispositivo);
GO
ALTER TABLE FacEventos ADD CONSTRAINT FK_FacEve_Pelicula
    FOREIGN KEY (idPelicula) REFERENCES DimPelicula (idPelicula);
GO
ALTER TABLE FacEventos ADD CONSTRAINT FK_FacEve_TipoEvento
    FOREIGN KEY (idTipEven) REFERENCES DimTipoEvento (idTipEven);
GO
ALTER TABLE FacEventos ADD CONSTRAINT FK_FacEve_Usuario
    FOREIGN KEY (idUsuario) REFERENCES DimUsuario (idUsuario);
GO

-- FK de FactSuscripcion
ALTER TABLE FactSuscripcion ADD CONSTRAINT FK_FactSusc_Calendario
    FOREIGN KEY (FecSuscrip) REFERENCES DimCalendario (Fecha);
GO
ALTER TABLE FactSuscripcion ADD CONSTRAINT FK_FactSusc_Plan
    FOREIGN KEY (idPlan) REFERENCES DimPlan (idPlan);
GO
ALTER TABLE FactSuscripcion ADD CONSTRAINT FK_FactSusc_Usuario
    FOREIGN KEY (idUsuario) REFERENCES DimUsuario (idUsuario);
GO

-- ============================================================
-- VERIFICACION: deben aparecer las 8 tablas
-- ============================================================
SELECT TABLE_NAME AS Tabla
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
GO
