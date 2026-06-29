-- ============================================================
-- PASO 2: CREAR TABLAS TMP, IMPORTAR CSVs Y CARGAR DATOS
-- Ejecutar DESPUES de:
--   1. Haber ejecutado PASO1_CREAR_TABLAS.sql
--   2. Haber importado los 8 CSVs en sus tablas _tmp
--
-- ORDEN DE IMPORTACION DE CSVs (Import Flat File en SSMS):
--   Clic derecho en PELICULAS_SERIES -> Tasks -> Import Flat File
--   1. DimCalendario.csv  -> DimCalendario_tmp
--   2. DimPlan.csv        -> DimPlan_tmp
--   3. DimTipoEvento.csv  -> DimTipoEvento_tmp
--   4. DimPelicula.csv    -> DimPelicula_tmp
--   5. DimDispositivo.csv -> DimDispositivo_tmp
--   6. DimUsuario.csv     -> DimUsuario_tmp
--   7. FactSuscripcion.csv-> FactSuscripcion_tmp
--   8. FacEventos.csv     -> FacEventos_tmp
-- ============================================================

USE PELICULAS_SERIES;
GO

-- ============================================================
-- PARTE A: CREAR TABLAS TMP
-- Ejecutar esto ANTES de importar los CSVs
-- ============================================================

IF OBJECT_ID('DimCalendario_tmp','U') IS NOT NULL DROP TABLE DimCalendario_tmp;
CREATE TABLE DimCalendario_tmp (
    Fecha      DATE        NOT NULL,
    Anio       INT         NOT NULL,
    Mes        INT         NOT NULL,
    NombreMes  VARCHAR(20) NOT NULL,
    Dia        INT         NOT NULL,
    NombreDia  VARCHAR(20) NOT NULL,
    Trimestre  INT         NOT NULL
);
GO

IF OBJECT_ID('DimPlan_tmp','U') IS NOT NULL DROP TABLE DimPlan_tmp;
CREATE TABLE DimPlan_tmp (
    idPlan        INT          NOT NULL,
    Descripcion   VARCHAR(100) NOT NULL,
    Precio        DECIMAL(8,2) NOT NULL,
    CantPantallas INT          NOT NULL,
    CalidadMax    VARCHAR(10)  NOT NULL,
    FlgEstado     BIT          NOT NULL
);
GO

IF OBJECT_ID('DimTipoEvento_tmp','U') IS NOT NULL DROP TABLE DimTipoEvento_tmp;
CREATE TABLE DimTipoEvento_tmp (
    idTipEven   INT          NOT NULL,
    Descrip     VARCHAR(100) NOT NULL,
    Categoria   VARCHAR(50)  NOT NULL,
    Plataforma  VARCHAR(50)  NOT NULL,
    Importancia VARCHAR(20)  NOT NULL
);
GO

IF OBJECT_ID('DimPelicula_tmp','U') IS NOT NULL DROP TABLE DimPelicula_tmp;
CREATE TABLE DimPelicula_tmp (
    idPelicula  INT          NOT NULL,
    Nombre      VARCHAR(200) NOT NULL,
    Genero      VARCHAR(50)  NOT NULL,
    Tipo        VARCHAR(20)  NOT NULL,
    Duracion    INT          NOT NULL,
    AnioEstreno INT          NOT NULL
);
GO

IF OBJECT_ID('DimDispositivo_tmp','U') IS NOT NULL DROP TABLE DimDispositivo_tmp;
CREATE TABLE DimDispositivo_tmp (
    idDispositivo    INT         NOT NULL,
    TipoDispositivo  VARCHAR(50) NOT NULL,
    SistemaOperativo VARCHAR(50) NULL
);
GO

IF OBJECT_ID('DimUsuario_tmp','U') IS NOT NULL DROP TABLE DimUsuario_tmp;
CREATE TABLE DimUsuario_tmp (
    idUsuario INT          NOT NULL,
    Nombre    VARCHAR(100) NOT NULL,
    ApePat    VARCHAR(100) NOT NULL,
    ApeMat    VARCHAR(100) NULL,
    Correo    VARCHAR(200) NOT NULL,
    Distrito  VARCHAR(100) NULL,
    FecAlta   DATE         NOT NULL,
    FecBaja   VARCHAR(20)  NULL
);
GO

IF OBJECT_ID('FactSuscripcion_tmp','U') IS NOT NULL DROP TABLE FactSuscripcion_tmp;
CREATE TABLE FactSuscripcion_tmp (
    idSuscrip  INT         NOT NULL,
    idUsuario  INT         NOT NULL,
    idPlan     INT         NOT NULL,
    FecSuscrip DATE        NOT NULL,
    FlgEstado  BIT         NOT NULL,
    MetodoPago VARCHAR(50) NOT NULL
);
GO

IF OBJECT_ID('FacEventos_tmp','U') IS NOT NULL DROP TABLE FacEventos_tmp;
CREATE TABLE FacEventos_tmp (
    idEventos     INT  NOT NULL,
    idUsuario     INT  NOT NULL,
    idTipEven     INT  NOT NULL,
    idPelicula    INT  NOT NULL,
    idDispositivo INT  NOT NULL,
    FecEve        DATE NOT NULL
);
GO

-- ============================================================
-- VERIFICACION: confirmar que las 8 tablas _tmp fueron creadas
-- ============================================================
SELECT TABLE_NAME AS TablaTmp
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME LIKE '%_tmp'
ORDER BY TABLE_NAME;
GO

-- ============================================================
-- ** PAUSA AQUI **
-- Importa los 8 CSVs en sus tablas _tmp correspondientes
-- usando Import Flat File en SSMS
-- Luego ejecuta la PARTE B de este script
-- ============================================================

-- ============================================================
-- PARTE B: CARGAR DATOS DE _TMP A TABLAS DEFINITIVAS
-- Ejecutar DESPUES de importar todos los CSVs
-- ============================================================

-- 1. DimCalendario
INSERT INTO DimCalendario (Fecha,Anio,Mes,NombreMes,Dia,NombreDia,Trimestre)
SELECT Fecha,Anio,Mes,NombreMes,Dia,NombreDia,Trimestre FROM DimCalendario_tmp;
DROP TABLE DimCalendario_tmp;
GO

-- 2. DimPlan
INSERT INTO DimPlan (idPlan,Descripcion,Precio,CantPantallas,CalidadMax,FlgEstado)
SELECT idPlan,Descripcion,Precio,CantPantallas,CalidadMax,FlgEstado FROM DimPlan_tmp;
DROP TABLE DimPlan_tmp;
GO

-- 3. DimTipoEvento
INSERT INTO DimTipoEvento (idTipEven,Descrip,Categoria,Plataforma,Importancia)
SELECT idTipEven,Descrip,Categoria,Plataforma,Importancia FROM DimTipoEvento_tmp;
DROP TABLE DimTipoEvento_tmp;
GO

-- 4. DimPelicula
INSERT INTO DimPelicula (idPelicula,Nombre,Genero,Tipo,Duracion,AnioEstreno)
SELECT idPelicula,Nombre,Genero,Tipo,Duracion,AnioEstreno FROM DimPelicula_tmp;
DROP TABLE DimPelicula_tmp;
GO

-- 5. DimDispositivo
INSERT INTO DimDispositivo (idDispositivo,TipoDispositivo,SistemaOperativo)
SELECT idDispositivo,TipoDispositivo,SistemaOperativo FROM DimDispositivo_tmp;
DROP TABLE DimDispositivo_tmp;
GO

-- 6. DimUsuario
INSERT INTO DimUsuario (idUsuario,Nombre,ApePat,ApeMat,Correo,Distrito,FecAlta,FecBaja)
SELECT idUsuario,Nombre,ApePat,ApeMat,Correo,Distrito,FecAlta,NULLIF(FecBaja,'')
FROM DimUsuario_tmp;
DROP TABLE DimUsuario_tmp;
GO

-- 7. FactSuscripcion
INSERT INTO FactSuscripcion (idSuscrip,idUsuario,idPlan,FecSuscrip,FlgEstado,MetodoPago)
SELECT idSuscrip,idUsuario,idPlan,FecSuscrip,FlgEstado,MetodoPago FROM FactSuscripcion_tmp;
DROP TABLE FactSuscripcion_tmp;
GO

-- 8. FacEventos
INSERT INTO FacEventos (idEventos,idUsuario,idTipEven,idPelicula,idDispositivo,FecEve)
SELECT idEventos,idUsuario,idTipEven,idPelicula,idDispositivo,FecEve FROM FacEventos_tmp;
DROP TABLE FacEventos_tmp;
GO

-- ============================================================
-- VERIFICACION FINAL: deben aparecer los 60 registros en cada tabla
-- ============================================================
SELECT 'DimCalendario'  AS Tabla, COUNT(*) AS Registros FROM DimCalendario
UNION ALL SELECT 'DimPlan',               COUNT(*) FROM DimPlan
UNION ALL SELECT 'DimTipoEvento',         COUNT(*) FROM DimTipoEvento
UNION ALL SELECT 'DimPelicula',           COUNT(*) FROM DimPelicula
UNION ALL SELECT 'DimDispositivo',        COUNT(*) FROM DimDispositivo
UNION ALL SELECT 'DimUsuario',            COUNT(*) FROM DimUsuario
UNION ALL SELECT 'FactSuscripcion',       COUNT(*) FROM FactSuscripcion
UNION ALL SELECT 'FacEventos',            COUNT(*) FROM FacEventos;
GO
