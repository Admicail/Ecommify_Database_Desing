# ⚡ Estrategia de Indexación Avanzada - PostgreSQL (Supabase)
**Carlos Alfonso Muñoz Agudelo - Esteban Giovanny Garay Cano - Carlos Sebastian Castillo Silva**  
*Proyecto Integrador: Módulo Transaccional ACID*

Este módulo detalla el despliegue físico de los índices especializados implementados en el motor relacional de **Ecommify**. La estrategia se diseñó a partir del análisis de los planes de ejecución (`EXPLAIN`) para erradicar los escaneos secuenciales (`Seq Scan`), garantizando la escalabilidad del sistema por encima de los 100,000 registros históricos.

---

## 📑 1. Catálogo e Inventario de Índices Desplegados

### A. Índices B-Tree para Llaves Foráneas (Optimización de JOINs)
Las llaves foráneas no se indexan de forma automática en PostgreSQL. Sin estos elementos, el motor realiza lecturas secuenciales completas al amarrar tablas.
*   `idx_order_details_order_id`: Aplica una estructura de árbol balanceada sobre la tabla de detalles. Agiliza de forma drástica la confirmación de compra y el desglose de productos al realizar cruces operativos (`JOIN`).
*   `idx_orders_customer_id`: Optimiza las búsquedas del historial de compras y la interacción del perfil del cliente en el frontend.

### B. Índices Parciales Condicionales (Estados Activos y Bodega)
Aplica la técnica de indexación selectiva sobre columnas con baja cardinalidad y datos desbalanceados. Dado que el 97% de las órdenes históricas ya fueron entregadas (`delivered`), guardar esos registros es ineficiente. Estos índices restringen su tamaño físico en disco a menos de 16 KB.
*   `idx_orders_status_created`: Registra única y exclusivamente las órdenes que acaban de ingresar y esperan validación de pago.
*   `idx_orders_status_approved`: Indexa los pedidos listos para el flujo de empaque (*Pick & Pack*) en los almacenes.
*   `idx_orders_status_shipped`: Soporta de forma directa el flujo logístico de despacho y control de rutas en tránsito.

### C. Índices GIN para Datos Complejos (JSONB y Texto Completo)
Las estructuras tradicionales no pueden inspeccionar el contenido interno de campos no atómicos ni búsquedas de texto parcial de forma óptima.
*   `idx_order_details_payment_path_jsonb`: Utiliza un índice invertido generalizado (`GIN`) con la clase de operadores `jsonb_path_ops`. Permite realizar auditorías instantáneas dentro del objeto semiestructurado de la pasarela de pagos (ej. validar si `payment_type = 'credit_card'`) sin desempaquetar la fila en memoria. Redujo la latencia de 2.7 segundos a 0.22 milisegundos.
*   `idx_products_category_fts`: Indexa mediante vectores de texto (`to_tsvector`) en idioma español las categorías del catálogo. Elimina el uso ineficiente del operador `LIKE %text%` y acelera los reportes de inteligencia de negocio (OLAP).

### D. Índice Compuesto Funcional (Métricas Logísticas)
*   `idx_orders_delivery_metrics`: Pre-calcula y almacena físicamente en el árbol los límites de la línea de tiempo temporal (`lower` y `upper` sobre el tipo de dato `tsrange`) junto con el estado del pedido. Evita que el procesador ejecute fórmulas matemáticas dinámicas fila por fila, permitiendo resolver los indicadores de tiempos promedio de entrega mediante un **Index-Only Scan** instantáneo.

---

## ⚡ 2. Matriz Cuantitativa de Impacto Técnico

A través de las herramientas de diagnóstico `EXPLAIN (ANALYZE, BUFFERS)` en la base de datos productiva de Supabase, se validaron los siguientes incrementos de velocidad:

| Caso de Uso Evaluado | Operación Inicial (Línea Base) | Operación Optimizada | Reducción de Tiempo (%) | Disminución de Bloques Leídos |
| :--- | :--- | :--- | :--- | :--- |
| **Detalle de Orden** | `Seq Scan` (~150 ms) | `Index Scan` (~12.5 ms) | **91.6%** | **85%** de ahorro en memoria. |
| **Auditoría de Pagos** | `Seq Scan` (2768.1 ms) | `Bitmap Index Scan` (0.22 ms) | **99.9%** | Pasó de 5,019 bloques a solo 4. |
| **Control Financiero** | `Seq Scan` (1146.2 ms) | `Index Scan Parcial` (10.5 ms) | **99.0%** | Pasó de 1,715 bloques a solo 6. |
| **Indicador Logístico** | `Seq Scan` (~450 ms) | `Index-Only Scan` (~40.0 ms) | **91.1%** | **80%** de liberación en CPU. |

---

## 🚀 3. Instrucciones de Despliegue

1. Conectarse a la consola de administración de **Supabase** o ejecutar el cliente SQL preferido en el entorno transaccional.
2. Cargar el script de base de datos adjunto en esta carpeta.
3. Ejecutar el comando para inicializar el compendio de índices de soporte. El motor relacional re-estructurará los punteros y optimizará de forma interna la ruta de acceso de los microservicios de manera transparente.
