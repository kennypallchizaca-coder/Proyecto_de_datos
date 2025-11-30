-- Carga tipo SCD1 para Dim_Cliente desde la tabla operacional dbo.Cliente
-- Supone las columnas: ClienteID, Nombre, Segmento, Ciudad, Region, Pais

MERGE Dim_Cliente AS dim
USING (
    SELECT c.ClienteID,
           c.Nombre,
           c.Segmento,
           c.Ciudad,
           c.Region,
           c.Pais
    FROM dbo.Cliente c
) AS src
ON dim.ClienteID = src.ClienteID
WHEN MATCHED AND (
        ISNULL(dim.Nombre, '') <> ISNULL(src.Nombre, '') OR
        ISNULL(dim.Segmento, '') <> ISNULL(src.Segmento, '') OR
        ISNULL(dim.Ciudad, '') <> ISNULL(src.Ciudad, '') OR
        ISNULL(dim.Region, '') <> ISNULL(src.Region, '') OR
        ISNULL(dim.Pais, '') <> ISNULL(src.Pais, '')
    ) THEN
    UPDATE SET
        Nombre = src.Nombre,
        Segmento = src.Segmento,
        Ciudad = src.Ciudad,
        Region = src.Region,
        Pais = src.Pais
WHEN NOT MATCHED THEN
    INSERT (ClienteID, Nombre, Segmento, Ciudad, Region, Pais)
    VALUES (src.ClienteID, src.Nombre, src.Segmento, src.Ciudad, src.Region, src.Pais);

-- Registrar cuántas filas se modificaron para trazabilidad de la ejecución
DECLARE @filas INT = @@ROWCOUNT;
PRINT CONCAT('Dim_Cliente cargada. Filas procesadas: ', @filas);
