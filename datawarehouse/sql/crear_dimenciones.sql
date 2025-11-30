-- DIM PRODUCTO
CREATE TABLE Dim_Producto (
    ProductoID INT PRIMARY KEY,
    Descripcion VARCHAR2(100),
    PrecioUnitario NUMBER(10,2),
    IVA NUMBER(5,2)
);

-- DIM TIEMPO
CREATE TABLE Dim_Tiempo (
    TiempoID INT PRIMARY KEY,
    Fecha DATE,
    Año INT,
    Mes INT,
    Trimestre INT,
    DiaSemana VARCHAR2(15)
);

-- DIM PAGO
CREATE TABLE Dim_Pago (
    PagoID INT PRIMARY KEY,
    TipoPago VARCHAR2(20),
    NumeroCuotas INT
);

-- DIM PEDIDOS
CREATEREATE TABLE Dim_Pedidos (
    PedidoID INT PRIMARY KEY,
    ClienteID INT,
    EmpleadoID INT,
    ProveedorID INT,
    FechaPedido DATE,
    Descuento NUMBER(5,2),
    PagoID INT,
    FOREIGN KEY (PagoID) REFERENCES Dim_Pago(PagoID)
);
