# 🔍 Consultas del Núcleo Transaccional (SQL Queries)
**Carlos Alfonso Muñoz Agudelo - Esteban Giovanny Garay Cano - Carlos Sebastian Castillo Silva**  
*Proyecto Integrador: Operaciones de Negocio y Reportes Relacionales*

Este módulo agrupa las 15 consultas críticas que orquestan los flujos de negocio y las métricas operativas de **Ecommify**. Cada una de estas sentencias fue analizada y optimizada para trabajar de forma armónica con la estrategia de indexación avanzada, eliminando los costosos escaneos secuenciales en disco.

---

## 1. Clasificación de Consultas por Proceso de Negocio

Las consultas se encuentran agrupadas según su rol operativo dentro del ciclo de vida del e-commerce:

###  Bloque A: Flujo Operativo y de Cara al Cliente (OLTP)
Consultas de alta frecuencia que impactan directamente la experiencia de navegación y compra del usuario:
*   **1. Detalle completo de una orden**: Recupera el desglose de productos y la información del cliente para la confirmación de compra. *Soportada en el índice B-Tree de llaves foráneas.*
*   **2. Información del pago de una orden**: Extrae los subdocumentos estructurados de la pasarela de pagos. *Soportada en el índice invertido GIN con jsonb_path_ops.*
*   **3. Calcular valor total de una compra**: Proceso central de facturación que totaliza precios y costos de fletes por pedido.
*   **5. Historial de compras de un cliente**: Resuelve de forma instantánea las consultas de la sección "Mis Pedidos" del perfil de usuario. *Soportada en el índice B-Tree de customer_id.*

###  Bloque B: Control Financiero y Métricas Comerciales (KPIs)
Consultas analíticas orientadas al monitoreo interno de ingresos y rendimiento de los oferentes:
*   **4. Consultas de órdenes pendientes de pago**: Lista las transacciones en estado `created` para procesos de auditoría financiera. *Soportada en el índice B-Tree Parcial condicional.*
*   **6. Productos vendidos por vendedor**: Reporte consolidado de unidades colocadas y montos recaudados por cada proveedor.
*   **7. Top 10 vendedores**: Tablero gerencial parametrizado mediante cláusulas `LIMIT` para premiar el volumen comercial.
*   **8. Top 10 productos más vendidos**: Métrica crítica de inteligencia de negocio para el control y rotación de inventarios en el catálogo.

###  Bloque C: Gestión y Operación Logística de Bodega (Pick & Pack)
Consultas quirúrgicas diseñadas para guiar el trabajo de los operarios de almacenamiento sin leer datos históricos ociosos:
*   **9. Órdenes listas para Pick & Pack**: Muestra los pedidos aprobados (`approved`) que deben ingresar a las líneas de empaque. *Soportada en el índice parcial.*
*   **10. Productos que deben prepararse para despacho**: Muestra las categorías específicas de una orden para acelerar el embalaje físico.
*   **11. Órdenes despachadas**: Control de rutas en tránsito para transportistas y etiquetado (`order_status = 'shipped'`).

###  Bloque D: Seguimiento, Entrega e Indicadores Gerenciales (OLAP)
Reportes pesados de consolidación que evalúan los niveles de servicio y las ventas históricas de la plataforma:
*   **12. Seguimiento de envíos (Tracking)**: Extrae los límites inferior (compra) y superior (entrega) del tipo de dato de rango `tsrange` de la línea de tiempo.
*   **13. Pedidos entregados**: Muestra el histórico completo de órdenes finalizadas con éxito (`delivered`).
*   **14. Tiempo promedio de entrega**: Indicador logístico clave de desempeño que promedia la diferencia horaria de las entregas. *Soportada en el índice compuesto funcional, permitiendo un Index-Only Scan.*
*   **15. Ventas por categoría**: Reporte gerencial de alto costo computacional que cruza el 100% de los detalles y productos para mapear el Market Share de la plataforma. *Optimizado mediante la reescritura de cruces e indexación por fuerza bruta secuencial en memoria caché.*

---

##  2. Guía de Reproducción del Entorno

Los scripts de las consultas se encuentran consolidados en el archivo `queries.sql` dentro de esta misma carpeta. Para verificar el impacto de la optimización en Supabase:

1.  Asegurar que las tablas cuenten con datos importados (112,000 líneas de detalle y 99,000 órdenes).
2.  Para auditar el comportamiento del hardware, anteponer la instrucción **`EXPLAIN (ANALYZE, BUFFERS)`** antes de cualquier consulta en el editor de Supabase.
3.  El sistema arrojará el reporte real de milisegundos y bloques de memoria caché consultados, confirmando la desaparición de los cuellos de botella iniciales.
