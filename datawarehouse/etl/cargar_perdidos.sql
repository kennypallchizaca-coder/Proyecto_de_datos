-- Carga de la tabla de hechos Fact_Ventas a partir del esquema transaccional
-- Se asume la existencia de las tablas operacionales: Pedido, DetallePedido, Producto y Pago
-- Calcula el IVA usando la tasa de la dimensión de productos

-- Paso 1: poblar Dim_Tiempo
INSERT INTO Dim_Tiempo (Fecha, Anio, Trimestre, Mes, NombreMes, DiaSemana, EsFinDeSemana)
SELECT DISTINCT
       CAST(p.FechaPedido AS DATE) AS Fecha,
       DATEPART(YEAR, p.FechaPedido) AS Anio,
       DATEPART(QUARTER, p.FechaPedido) AS Trimestre,
       DATEPART(MONTH, p.FechaPedido) AS Mes,
       DATENAME(MONTH, p.FechaPedido) AS NombreMes,
       DATENAME(WEEKDAY, p.FechaPedido) AS DiaSemana,
       CASE WHEN DATENAME(WEEKDAY, p.FechaPedido) IN ('Saturday', 'Sunday', 'sábado', 'domingo') THEN 1 ELSE 0 END AS EsFinDeSemana
FROM dbo.Pedido p
LEFT JOIN Dim_Tiempo t ON t.Fecha = CAST(p.FechaPedido AS DATE)
WHERE t.TiempoKey IS NULL;

-- Paso 2: poblar Dim_Pago
INSERT INTO Dim_Pago (TipoPago, NumeroCuotas, Descripcion)
SELECT DISTINCT
       pg.TipoPago,
       pg.NumeroCuotas,
       pg.Descripcion
FROM dbo.Pago pg
LEFT JOIN Dim_Pago d ON d.TipoPago = pg.TipoPago AND ISNULL(d.NumeroCuotas, 0) = ISNULL(pg.NumeroCuotas, 0)
WHERE d.PagoKey IS NULL;

-- Paso 3: poblar Dim_Proveedor
INSERT INTO Dim_Proveedor (ProveedorID, RazonSocial, Ciudad, Region, Pais)
SELECT DISTINCT
       pr.ProveedorID,
       pr.RazonSocial,
       pr.Ciudad,
       pr.Region,
       pr.Pais
FROM dbo.Proveedor pr
LEFT JOIN Dim_Proveedor d ON d.ProveedorID = pr.ProveedorID
WHERE d.ProveedorKey IS NULL;

-- Paso 4: poblar Dim_Producto (depende de Dim_Proveedor)
INSERT INTO Dim_Producto (ProductoID, Nombre, Categoria, PrecioUnitario, TasaIVA, ProveedorKey)
SELECT prd.ProductoID,
       prd.Nombre,
       cat.Nombre AS Categoria,
       prd.PrecioUnitario,
       prd.TasaIVA,
       dp.ProveedorKey
FROM dbo.Producto prd
INNER JOIN dbo.CategoriaProducto cat ON cat.CategoriaID = prd.CategoriaID
INNER JOIN Dim_Proveedor dp ON dp.ProveedorID = prd.ProveedorID
LEFT JOIN Dim_Producto dprod ON dprod.ProductoID = prd.ProductoID
WHERE dprod.ProductoKey IS NULL;

-- Paso 5: poblar Dim_Empleado
INSERT INTO Dim_Empleado (EmpleadoID, Nombre, Cargo, Ciudad, Region)
SELECT DISTINCT e.EmpleadoID, e.Nombre, e.Cargo, e.Ciudad, e.Region
FROM dbo.Empleado e
LEFT JOIN Dim_Empleado d ON d.EmpleadoID = e.EmpleadoID
WHERE d.EmpleadoKey IS NULL;

-- Paso 6: poblar Dim_Cliente (SCD1)
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

-- Paso 7: poblar Dim_Ubicacion con las ubicaciones de envío de los pedidos
INSERT INTO Dim_Ubicacion (Ciudad, Region, Pais)
SELECT DISTINCT
       p.CiudadEnvio,
       p.RegionEnvio,
       p.PaisEnvio
FROM dbo.Pedido p
LEFT JOIN Dim_Ubicacion du ON du.Ciudad = p.CiudadEnvio AND ISNULL(du.Region, '') = ISNULL(p.RegionEnvio, '') AND du.Pais = p.PaisEnvio
WHERE du.UbicacionKey IS NULL;

-- Paso 8: poblar Dim_Pedido (cabeceras)
INSERT INTO Dim_Pedido (PedidoID, ClienteKey, EmpleadoKey, ProveedorKey, PagoKey, UbicacionKey)
SELECT DISTINCT
       p.PedidoID,
       dc.ClienteKey,
       de.EmpleadoKey,
       dp.ProveedorKey,
       pgd.PagoKey,
       du.UbicacionKey
FROM dbo.Pedido p
INNER JOIN Dim_Cliente dc ON dc.ClienteID = p.ClienteID
INNER JOIN Dim_Empleado de ON de.EmpleadoID = p.EmpleadoID
INNER JOIN Dim_Proveedor dp ON dp.ProveedorID = p.ProveedorID
INNER JOIN Dim_Pago pgd ON pgd.TipoPago = p.TipoPago AND ISNULL(pgd.NumeroCuotas, 0) = ISNULL(p.NumeroCuotas, 0)
INNER JOIN Dim_Ubicacion du ON du.Ciudad = p.CiudadEnvio AND ISNULL(du.Region, '') = ISNULL(p.RegionEnvio, '') AND du.Pais = p.PaisEnvio
LEFT JOIN Dim_Pedido dped ON dped.PedidoID = p.PedidoID
WHERE dped.PedidoKey IS NULL;

-- Paso 9: poblar Fact_Ventas con los detalles
INSERT INTO Fact_Ventas (
    PedidoID, Linea, TiempoKey, ProductoKey, ClienteKey, EmpleadoKey, ProveedorKey, PagoKey, UbicacionKey,
    Cantidad, PrecioUnitario, ImporteBruto, ImporteIVA, ImporteTotal)
SELECT d.PedidoID,
       d.Linea,
       t.TiempoKey,
       prd.ProductoKey,
       dc.ClienteKey,
       de.EmpleadoKey,
       dpr.ProveedorKey,
       pgd.PagoKey,
       du.UbicacionKey,
       d.Cantidad,
       prd.PrecioUnitario,
       d.Cantidad * prd.PrecioUnitario AS ImporteBruto,
       d.Cantidad * prd.PrecioUnitario * prd.TasaIVA AS ImporteIVA,
       d.Cantidad * prd.PrecioUnitario * (1 + prd.TasaIVA) AS ImporteTotal
FROM dbo.DetallePedido d
INNER JOIN dbo.Pedido p ON p.PedidoID = d.PedidoID
INNER JOIN Dim_Tiempo t ON t.Fecha = CAST(p.FechaPedido AS DATE)
INNER JOIN Dim_Producto prd ON prd.ProductoID = d.ProductoID
INNER JOIN Dim_Proveedor dpr ON dpr.ProveedorKey = prd.ProveedorKey
INNER JOIN Dim_Cliente dc ON dc.ClienteID = p.ClienteID
INNER JOIN Dim_Empleado de ON de.EmpleadoID = p.EmpleadoID
INNER JOIN Dim_Pago pgd ON pgd.TipoPago = p.TipoPago AND ISNULL(pgd.NumeroCuotas, 0) = ISNULL(p.NumeroCuotas, 0)
INNER JOIN Dim_Ubicacion du ON du.Ciudad = p.CiudadEnvio AND ISNULL(du.Region, '') = ISNULL(p.RegionEnvio, '') AND du.Pais = p.PaisEnvio
LEFT JOIN Fact_Ventas f ON f.PedidoID = d.PedidoID AND f.Linea = d.Linea
WHERE f.FactVentaKey IS NULL;

PRINT 'Carga de Fact_Ventas completada';
