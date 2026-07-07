--¿cual es el ingreso recurrente generado por las suscripciones activas entre 5 mayo y 5 de julio del 2026?
SELECT 
    p.Descripcion AS NombrePlan,
    p.Precio AS PrecioPlan,
    COUNT(*) AS TotalSuscripciones,
    SUM(CASE WHEN f.FlgEstado = 1 THEN p.Precio ELSE 0 END) AS MRR_Generado
FROM FactSuscripcion f
INNER JOIN DimPlan p ON p.idPlan = f.idPlan
WHERE f.FecSuscrip BETWEEN '2026-05-05' AND '2026-07-05'
GROUP BY p.Descripcion, p.Precio
ORDER BY MRR_Generado DESC;

--¿cual es la tasa de retencion de los planes entre 5 mayo y 5 julio del 2026 

SELECT 
    p.Descripcion AS NombrePlan,
    COUNT(*) AS TotalSuscripciones,
    SUM(CASE WHEN f.FlgEstado = 1 THEN 1 ELSE 0 END) AS Activas,
    SUM(CASE WHEN f.FlgEstado = 0 THEN 1 ELSE 0 END) AS Canceladas,
    CAST(SUM(CASE WHEN f.FlgEstado = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS TasaCancelacion
FROM FactSuscripcion f
INNER JOIN DimPlan p ON p.idPlan = f.idPlan
WHERE f.FecSuscrip BETWEEN '2026-05-05' AND '2026-07-05'
GROUP BY p.Descripcion
ORDER BY TasaCancelacion DESC;


--: ¿Cómo se distribuye el catálogo por género?

SELECT Genero, COUNT(*) AS TotalTitulos
FROM DimPelicula
GROUP BY Genero
ORDER BY TotalTitulos DESC;

-- ¿Cuál es la duración promedio del contenido por género (o por tipo: Película vs Serie)?


SELECT Genero, Tipo, AVG(Duracion) AS DuracionPromedio, COUNT(*) AS TotalTitulos
FROM DimPelicula
GROUP BY Genero, Tipo
ORDER BY DuracionPromedio DESC;


--"¿Cuál es la rentabilidad anual generada por cada plan de suscripción
--entre el 6 de julio de 2026 y el 6 de julio de 2027, diferenciando el 
--ingreso efectivo (suscripciones activas) del ingreso perdido por cancelaciones?

SELECT
    pl.Descripcion                                                              AS NombrePlan,
    pl.Precio,
    COUNT(fs.idSuscrip)                                                         AS TotalSuscripciones,
    SUM(CASE WHEN fs.FlgEstado = 1 THEN pl.Precio ELSE 0 END)                   AS IngresoActivas,
    SUM(CASE WHEN fs.FlgEstado = 0 THEN pl.Precio ELSE 0 END)                   AS IngresoPerdidoCancelaciones,
    SUM(CASE WHEN fs.FlgEstado = 1 THEN pl.Precio ELSE 0 END)                   AS IngresoTotalAnual,
    ROUND(
        100.0 * SUM(CASE WHEN fs.FlgEstado = 0 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(fs.idSuscrip), 0), 2
    ) AS TasaCancelacionPct
FROM FactSuscripcion fs
JOIN DimPlan pl ON fs.idPlan = pl.idPlan
WHERE fs.FecSuscrip BETWEEN '2026-07-06' AND '2027-07-06'
GROUP BY pl.Descripcion, pl.Precio
ORDER BY IngresoTotalAnual DESC;


