# Diseño del sistema OLAP de pedidos

Este proyecto implementa un modelo estrella orientado a analizar pedidos, pagos y comportamiento de clientes y proveedores sobre Azure SQL Database + Azure Analysis Services/Power BI.

## Modelo estrella
- **Hecho**: `Fact_Ventas` granularidad línea de pedido.
- **Dimensiones**: `Dim_Tiempo`, `Dim_Pago`, `Dim_Cliente`, `Dim_Empleado`, `Dim_Proveedor`, `Dim_Producto`, `Dim_Ubicacion`, `Dim_Pedido`.
- Se eligió **modelo estrella** para simplificar los cruces frecuentes (producto, tiempo, vendedor, ubicación, pago) y acelerar agregaciones sin joins innecesarios entre jerarquías normalizadas. Los atributos jerárquicos (ciudad → región → país, categoría de producto) se alojan en la misma dimensión para facilitar la navegación en cubos y modelos tabulares.

## Casos analíticos cubiertos
1. Producto más vendido por proveedor y ubicación en el tiempo (año, trimestre, mes, día de semana) usando `Fact_Ventas` + `Dim_Tiempo` + `Dim_Proveedor` + `Dim_Ubicacion` + `Dim_Producto`.
2. Forma de pago preferida por región y periodo con `Dim_Pago`, `Dim_Ubicacion` y `Dim_Tiempo`.
3. Mejores clientes por volumen o valor de compras, filtrando por modalidad de pago (`Dim_Pago`) y fechas (`Dim_Tiempo`).
4. Mejor vendedor por categoría, tiempo y ubicación, combinando `Dim_Empleado`, `Dim_Producto`, `Dim_Tiempo` y `Dim_Ubicacion`.

## Elección de herramientas
- **Azure SQL Database** como almacén relacional escalable y compatible con T-SQL para los procesos ETL y generación de datos masivos.
- **Azure Data Factory** (o SQL Agent) para orquestar la ejecución de los scripts de generación y carga.
- **Azure Analysis Services** o modelo tabular de **Power BI** para definir las perspectivas OLAP y servirlas a Tableau/Power BI Desktop.
- **Tableau** como consumidor de reportes: se conecta al modelo tabular o vistas materializadas para construir dashboards.

## Configuración sugerida
1. Crear una base de datos `operacional_pedidos` y ejecutar `etl/generar_datos_operacionales.sql` para sembrar el esquema OLTP.
2. En la base `dw_pedidos`, ejecutar `sql/crear_dimenciones.sql` y `sql/crear_tabla.sql`.
3. Configurar credenciales dedicadas de solo lectura para consultas OLAP.
4. Publicar un modelo tabular en Azure Analysis Services/Power BI tomando las tablas del DW como fuente; definir medidas DAX de ventas brutas, IVA y totales.

## Proceso ETL
1. **Extracción**: leer tablas `Pedido`, `DetallePedido`, `Producto`, `Proveedor`, `Cliente`, `Empleado` y `Pago` desde `operacional_pedidos`.
2. **Transformación**: calcular jerarquías de tiempo (`Dim_Tiempo`), desnormalizar atributos de producto y ubicación, y calcular montos de IVA por línea.
3. **Carga**: ejecutar los pasos descritos en `etl/cargar_perdidos.sql` (incluye actualización SCD1 de clientes), luego poblar `Fact_Ventas`.

## Consultas con Tableau
- Conectar Tableau al modelo tabular o directamente a `Fact_Ventas` y dimensiones.
- Dimensiones recomendadas en filtros/segmentos: Tiempo, Ubicación, Pago, Categoría de producto, Vendedor.
- Métricas: `ImporteBruto`, `ImporteIVA`, `ImporteTotal`, `Cantidad`.

## Usuario de consulta
Crear un usuario dedicado (ej. `olap_reader`) con permisos `SELECT` sobre el esquema de DW y usarlo en Tableau para evitar escrituras accidentales.
