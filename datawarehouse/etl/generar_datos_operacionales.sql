/*
Generación de datos sintéticos para el esquema transaccional de pedidos
Pensado para Azure SQL Database.
- 10 proveedores
- 5 empleados
- 20 clientes
- 5 categorías
- 200 productos (100 con IVA 15%, 100 con IVA 0%)
- 100 000 pedidos entre 2020-01-01 y 2025-12-31 con 3 a 10 productos por pedido
*/

-- Catálogo básico
CREATE TABLE dbo.Proveedor (
    ProveedorID INT IDENTITY(1,1) PRIMARY KEY,
    RazonSocial NVARCHAR(150) NOT NULL,
    Ciudad NVARCHAR(80),
    Region NVARCHAR(80),
    Pais NVARCHAR(80)
);

CREATE TABLE dbo.Empleado (
    EmpleadoID INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(120) NOT NULL,
    Cargo NVARCHAR(60),
    Ciudad NVARCHAR(80),
    Region NVARCHAR(80)
);

CREATE TABLE dbo.Cliente (
    ClienteID INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(120) NOT NULL,
    Segmento NVARCHAR(40),
    Ciudad NVARCHAR(80),
    Region NVARCHAR(80),
    Pais NVARCHAR(80)
);

CREATE TABLE dbo.CategoriaProducto (
    CategoriaID INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(80) NOT NULL
);

CREATE TABLE dbo.Pago (
    PagoID INT IDENTITY(1,1) PRIMARY KEY,
    TipoPago NVARCHAR(30) NOT NULL,
    NumeroCuotas TINYINT NULL,
    Descripcion NVARCHAR(100)
);

CREATE TABLE dbo.Producto (
    ProductoID INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(120) NOT NULL,
    CategoriaID INT NOT NULL,
    ProveedorID INT NOT NULL,
    PrecioUnitario DECIMAL(12,2) NOT NULL,
    TasaIVA DECIMAL(5,2) NOT NULL,
    FOREIGN KEY (CategoriaID) REFERENCES dbo.CategoriaProducto(CategoriaID),
    FOREIGN KEY (ProveedorID) REFERENCES dbo.Proveedor(ProveedorID)
);

CREATE TABLE dbo.Pedido (
    PedidoID INT IDENTITY(1,1) PRIMARY KEY,
    ClienteID INT NOT NULL,
    EmpleadoID INT NOT NULL,
    ProveedorID INT NOT NULL,
    PagoID INT NOT NULL,
    TipoPago NVARCHAR(30) NOT NULL,
    NumeroCuotas TINYINT NULL,
    FechaPedido DATETIME2 NOT NULL,
    CiudadEnvio NVARCHAR(80) NOT NULL,
    RegionEnvio NVARCHAR(80) NULL,
    PaisEnvio NVARCHAR(80) NOT NULL,
    FOREIGN KEY (ClienteID) REFERENCES dbo.Cliente(ClienteID),
    FOREIGN KEY (EmpleadoID) REFERENCES dbo.Empleado(EmpleadoID),
    FOREIGN KEY (ProveedorID) REFERENCES dbo.Proveedor(ProveedorID),
    FOREIGN KEY (PagoID) REFERENCES dbo.Pago(PagoID)
);

CREATE TABLE dbo.DetallePedido (
    PedidoID INT NOT NULL,
    Linea INT NOT NULL,
    ProductoID INT NOT NULL,
    Cantidad INT NOT NULL,
    PRIMARY KEY (PedidoID, Linea),
    FOREIGN KEY (PedidoID) REFERENCES dbo.Pedido(PedidoID),
    FOREIGN KEY (ProductoID) REFERENCES dbo.Producto(ProductoID)
);

-- Semillas
INSERT INTO dbo.Proveedor (RazonSocial, Ciudad, Region, Pais)
SELECT CONCAT('Proveedor ', v.n), 'Quito', 'Pichincha', 'Ecuador'
FROM (SELECT TOP (10) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.all_objects) v;

INSERT INTO dbo.Empleado (Nombre, Cargo, Ciudad, Region)
SELECT CONCAT('Empleado ', v.n), 'Ventas', 'Quito', 'Pichincha'
FROM (SELECT TOP (5) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.all_objects) v;

INSERT INTO dbo.Cliente (Nombre, Segmento, Ciudad, Region, Pais)
SELECT CONCAT('Cliente ', v.n), CASE WHEN v.n % 2 = 0 THEN 'Empresarial' ELSE 'Residencial' END, 'Guayaquil', 'Guayas', 'Ecuador'
FROM (SELECT TOP (20) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.all_objects) v;

INSERT INTO dbo.CategoriaProducto (Nombre)
VALUES ('Electrónica'), ('Hogar'), ('Deportes'), ('Ropa'), ('Alimentos');

INSERT INTO dbo.Pago (TipoPago, NumeroCuotas, Descripcion)
VALUES ('Efectivo', NULL, 'Pago inmediato'),
       ('Transferencia', NULL, 'Transferencia bancaria'),
       ('Tarjeta de crédito', 3, 'Tarjeta 3 cuotas'),
       ('Tarjeta de crédito', 6, 'Tarjeta 6 cuotas'),
       ('Tarjeta de crédito', 12, 'Tarjeta 12 cuotas');

-- 200 productos: 100 con IVA 0, 100 con IVA 15
;WITH nums AS (
    SELECT TOP (200) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.Producto (Nombre, CategoriaID, ProveedorID, PrecioUnitario, TasaIVA)
SELECT CONCAT('Producto ', n),
       ((n - 1) / 40) + 1 AS CategoriaID,
       ((n - 1) % 10) + 1 AS ProveedorID,
       CAST((ABS(CHECKSUM(NEWID())) % 9000) / 100.0 + 10 AS DECIMAL(12,2)) AS PrecioUnitario,
       CASE WHEN n <= 100 THEN 0.15 ELSE 0 END AS TasaIVA
FROM nums;

-- Generar 100k pedidos con fechas aleatorias
;WITH pedidos AS (
    SELECT TOP (100000)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n,
           DATEADD(DAY, ABS(CHECKSUM(NEWID())) % DATEDIFF(DAY, '2020-01-01', '2025-12-31'), '2020-01-01') AS FechaAleatoria,
           ABS(CHECKSUM(NEWID())) % 20 + 1 AS ClienteID,
           ABS(CHECKSUM(NEWID())) % 5 + 1 AS EmpleadoID,
           ABS(CHECKSUM(NEWID())) % 10 + 1 AS ProveedorID,
           ABS(CHECKSUM(NEWID())) % 5 + 1 AS PagoID,
           ABS(CHECKSUM(NEWID())) % 5 + 1 AS CiudadRandom
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.Pedido (ClienteID, EmpleadoID, ProveedorID, PagoID, TipoPago, NumeroCuotas, FechaPedido, CiudadEnvio, RegionEnvio, PaisEnvio)
SELECT p.ClienteID,
       p.EmpleadoID,
       p.ProveedorID,
       p.PagoID,
       pg.TipoPago,
       pg.NumeroCuotas,
       p.FechaAleatoria,
       CASE p.CiudadRandom WHEN 1 THEN 'Quito' WHEN 2 THEN 'Guayaquil' WHEN 3 THEN 'Cuenca' WHEN 4 THEN 'Manta' ELSE 'Loja' END,
       CASE p.CiudadRandom WHEN 1 THEN 'Pichincha' WHEN 2 THEN 'Guayas' WHEN 3 THEN 'Azuay' WHEN 4 THEN 'Manabí' ELSE 'Loja' END,
       'Ecuador'
FROM pedidos p
INNER JOIN dbo.Pago pg ON pg.PagoID = p.PagoID;

-- Generar entre 3 y 10 líneas por pedido
;WITH ctePedidos AS (
    SELECT PedidoID, ABS(CHECKSUM(NEWID())) % 8 + 3 AS TotalLineas
    FROM dbo.Pedido
),
N AS (
    SELECT TOP (10) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.all_objects
)
INSERT INTO dbo.DetallePedido (PedidoID, Linea, ProductoID, Cantidad)
SELECT p.PedidoID,
       ROW_NUMBER() OVER (PARTITION BY p.PedidoID ORDER BY NEWID()) AS Linea,
       ABS(CHECKSUM(NEWID())) % 200 + 1 AS ProductoID,
       ABS(CHECKSUM(NEWID())) % 50 + 1 AS Cantidad
FROM ctePedidos p
CROSS JOIN N
WHERE N.n <= p.TotalLineas;

PRINT 'Generación de datos completada';
