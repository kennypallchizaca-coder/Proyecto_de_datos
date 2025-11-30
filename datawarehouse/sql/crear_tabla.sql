-- TABLA DE HECHOS
CREATE TABLE Fact_Ventas (
    VentaID INT PRIMARY KEY,
    ProductoID INT,
    TiempoID INT,
    PedidoID INT,
    CantidadVendida INT,

    FOREIGN KEY (ProductoID) REFERENCES Dim_Producto(ProductoID),
    FOREIGN KEY (TiempoID) REFERENCES Dim_Tiempo(TiempoID),
    FOREIGN KEY (PedidoID) REFERENCES Dim_Pedidos(PedidoID)
);
