-- Creación de dimensiones para el modelo estrella de pedidos
-- Todas las tablas usan claves sustitutas para simplificar los procesos ETL

-- Dimensión de tiempo
CREATE TABLE Dim_Tiempo (
    TiempoKey INT IDENTITY(1,1) PRIMARY KEY,
    Fecha DATE NOT NULL UNIQUE,
    Anio SMALLINT NOT NULL,
    Trimestre TINYINT NOT NULL,
    Mes TINYINT NOT NULL,
    NombreMes NVARCHAR(20) NOT NULL,
    DiaSemana NVARCHAR(20) NOT NULL,
    EsFinDeSemana BIT NOT NULL
);

-- Dimensión de modalidades de pago
CREATE TABLE Dim_Pago (
    PagoKey INT IDENTITY(1,1) PRIMARY KEY,
    TipoPago NVARCHAR(30) NOT NULL,
    NumeroCuotas TINYINT NULL,
    Descripcion NVARCHAR(100) NULL,
    CONSTRAINT UQ_Dim_Pago UNIQUE (TipoPago, ISNULL(NumeroCuotas, 0))
);

-- Dimensión de clientes
CREATE TABLE Dim_Cliente (
    ClienteKey INT IDENTITY(1,1) PRIMARY KEY,
    ClienteID INT NOT NULL,
    Nombre NVARCHAR(120) NOT NULL,
    Segmento NVARCHAR(40) NULL,
    Ciudad NVARCHAR(80) NULL,
    Region NVARCHAR(80) NULL,
    Pais NVARCHAR(80) NULL,
    CONSTRAINT UQ_Dim_Cliente UNIQUE (ClienteID)
);

-- Dimensión de empleados (vendedores)
CREATE TABLE Dim_Empleado (
    EmpleadoKey INT IDENTITY(1,1) PRIMARY KEY,
    EmpleadoID INT NOT NULL,
    Nombre NVARCHAR(120) NOT NULL,
    Cargo NVARCHAR(60) NULL,
    Ciudad NVARCHAR(80) NULL,
    Region NVARCHAR(80) NULL,
    CONSTRAINT UQ_Dim_Empleado UNIQUE (EmpleadoID)
);

-- Dimensión de proveedores
CREATE TABLE Dim_Proveedor (
    ProveedorKey INT IDENTITY(1,1) PRIMARY KEY,
    ProveedorID INT NOT NULL,
    RazonSocial NVARCHAR(150) NOT NULL,
    Ciudad NVARCHAR(80) NULL,
    Region NVARCHAR(80) NULL,
    Pais NVARCHAR(80) NULL,
    CONSTRAINT UQ_Dim_Proveedor UNIQUE (ProveedorID)
);

-- Dimensión de productos
CREATE TABLE Dim_Producto (
    ProductoKey INT IDENTITY(1,1) PRIMARY KEY,
    ProductoID INT NOT NULL,
    Nombre NVARCHAR(120) NOT NULL,
    Categoria NVARCHAR(80) NOT NULL,
    PrecioUnitario DECIMAL(12,2) NOT NULL,
    TasaIVA DECIMAL(5,2) NOT NULL,
    ProveedorKey INT NOT NULL,
    CONSTRAINT UQ_Dim_Producto UNIQUE (ProductoID),
    CONSTRAINT FK_Dim_Producto_Proveedor FOREIGN KEY (ProveedorKey) REFERENCES Dim_Proveedor(ProveedorKey)
);

-- Dimensión de ubicación (separada para facilitar análisis geográfico)
CREATE TABLE Dim_Ubicacion (
    UbicacionKey INT IDENTITY(1,1) PRIMARY KEY,
    Ciudad NVARCHAR(80) NOT NULL,
    Region NVARCHAR(80) NULL,
    Pais NVARCHAR(80) NOT NULL,
    CONSTRAINT UQ_Dim_Ubicacion UNIQUE (Ciudad, ISNULL(Region, ''), Pais)
);

-- Dimensión de pedidos (cabecera del pedido)
CREATE TABLE Dim_Pedido (
    PedidoKey INT IDENTITY(1,1) PRIMARY KEY,
    PedidoID INT NOT NULL,
    ClienteKey INT NOT NULL,
    EmpleadoKey INT NOT NULL,
    ProveedorKey INT NOT NULL,
    PagoKey INT NOT NULL,
    UbicacionKey INT NOT NULL,
    CONSTRAINT UQ_Dim_Pedido UNIQUE (PedidoID),
    CONSTRAINT FK_Dim_Pedido_Cliente FOREIGN KEY (ClienteKey) REFERENCES Dim_Cliente(ClienteKey),
    CONSTRAINT FK_Dim_Pedido_Empleado FOREIGN KEY (EmpleadoKey) REFERENCES Dim_Empleado(EmpleadoKey),
    CONSTRAINT FK_Dim_Pedido_Proveedor FOREIGN KEY (ProveedorKey) REFERENCES Dim_Proveedor(ProveedorKey),
    CONSTRAINT FK_Dim_Pedido_Pago FOREIGN KEY (PagoKey) REFERENCES Dim_Pago(PagoKey),
    CONSTRAINT FK_Dim_Pedido_Ubicacion FOREIGN KEY (UbicacionKey) REFERENCES Dim_Ubicacion(UbicacionKey)
);
