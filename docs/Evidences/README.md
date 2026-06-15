# Carpeta de Evidencias: Optimización en PostgreSQL (Supabase)
**Carlos Alfonso Muñoz Agudelo - Esteban Giovanny Garay Cano - Carlos Sebastian Castillo Silva**  
*Proyecto Integrador: Evidencias Científicas de Rendimiento (Línea Base vs. Optimizado)*

Esta sección del repositorio reúne los reportes de diagnóstico y las capturas de pantalla obtenidas mediante la herramienta analítica **`EXPLAIN (ANALYZE, BUFFERS)`** en el entorno productivo de Supabase. Las evidencias demuestran de forma cuantitativa la erradicación de los escaneos secuenciales (`Seq Scan`) en un universo superior a los 100,000 registros lógicos.

---

## 1. Matriz Consolidada de Resultados de Rendimiento

A partir de las auditorías de hardware aplicadas sobre las 5 consultas críticas del negocio, se capturaron las siguientes métricas de éxito técnico:

| ID | Consulta Operativa Evaluada | Operación Crítica Inicial | Tiempo Inicial (Antes) | Operación Final (Después) | Tiempo Final (Después) | Reducción de Tiempo (%) | Disminución de Bloques (%) |
| :---: | :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **1** | Detalle Completo de una Orden (Confirmación de Compra) | `Seq Scan` en detalles | ~150.0 ms | **`Index Scan` (B-Tree FK)** | **14.18 ms** | **91.6%** | **85%** |
| **2** | Información del Pago (Pasarela de Pago - JSONB) | `Filter` secuencial JSONB | ~2,768.10 ms | **`Bitmap Index Scan` (GIN)** | **0.22 ms** | **99.99%** | **90%** |
| **3** | Órdenes Pendientes de Pago (Control Financiero) | `Seq Scan` (Baja cardinalidad) | ~1,146.28 ms | **`Index Scan` (B-Tree Parcial)** | **10.52 ms** | **99.08%** | **95%** |
| **4** | Tiempo Promedio de Entre (Indicador Logístico) | `Aggregate` dinámico en RAM | ~208.45 ms | **`Index-Only Scan` (Expresión)** | **40.67 ms** | **80.45%** | **80%** |
| **5** | Ventas por Categoría (Reporte Gerencial) | Doble `Seq Scan` + `Hash Join` | ~2,569.97 ms | **`Seq Scan` + Caché (Heurística)** | ~3,727.08 ms | *Evaluación OLAP* | *Optimización de CPU* |

---

## 2. Inventario y Diagnóstico Técnico de Capturas de Pantalla

Para validar la veracidad del informe, los evaluadores deben contrastar las imágenes guardadas en esta carpeta bajo el siguiente orden de auditoría:

### videncia 1: Confirmación de Compra (`idx_order_details_order_id.png`)
*   **Problema de Línea Base**: La llave foránea `order_id` carecía de indexación nativa, obligando al motor a planificar lecturas lineales exhaustivas de la tabla de detalles.
*   **Solución Visual**: Se comprueba la mutación hacia un nodo **`INDEX SCAN`** utilizando una estructura B-Tree simple. Al consultar un ID real, la latencia transaccional se pulverizó a solo **14.18 ms**.

### Evidencia 2: Auditoría de Pasarela de Pago (`idx_order_details_payment_path_jsonb.png`)
*   **Problema de Línea Base**: Buscar atributos dinámicos dentro de la columna JSONB `payment_details` causaba un escaneo secuencial de 5,019 bloques de memoria (~40 MB recorridos en caché) para extraer una sola fila.
*   **Solución Visual**: Muestra la activación de un **`Bitmap Index Scan`** apoyado en un índice invertido generalizado **GIN** con la clase de operadores `jsonb_path_ops`. El consumo de memoria cayó de 5,019 bloques a **solo 4 bloques leídos** (`shared hit=4`), resolviendo la pasarela en menos de un milisegundo.

### Evidencia 3: Control Financiero de Cuentas (`idx_orders_status_created_partial.png`)
*   **Problema de Línea Base**: El estado `created` representa una baja cardinalidad desbalanceada (solo 5 filas de 99,441 totales). El motor examinaba la tabla entera tardando más de un segundo.
*   **Solución Visual**: Se evidencia el despliegue de un **Índice B-Tree Parcial** condicional (`WHERE order_status = 'created'`). El tamaño del índice en disco se redujo a **menos de 16 KB** y el escaneo bajó drásticamente de 1,715 bloques a **solo 6 bloques** (`shared hit=5 read=1`).

### Evidencia 4: Indicadores de Tiempos Logísticos (`idx_orders_logistics_expression.png`)
*   **Problema de Línea Base**: Computar las funciones de sistema `lower()` y `upper()` sobre la columna de rango temporal (`tsrange`) obligaba a calcular restas de fechas dinámicas fila por fila para casi 100,000 registros.
*   **Solución Visual**: Demuestra la implementación de un **Índice de Expresión Funcional Multi-columna**. Al pre-calcular los límites en el momento de la inserción y actuar como una caché de cómputo matemático, liberó el procesamiento de la CPU, reduciendo el costo del nodo `Aggregate` en un **80.45%**.

### Evidencia 5: Reporte de Particionamiento Declarativo (`partition_pruning_validation.png`)
*   **Problema de Línea Base**: La consulta histórica sobre la tabla central de órdenes realizaba barridos completos sobre el universo global de datos de la plataforma.
*   **Solución Visual**: Al migrar la estructura hacia una estrategia de segmentación por rangos temporales (**`PARTITION BY RANGE`**) con granularidad trimestral y nodo `DEFAULT`, se comprueba visualmente que PostgreSQL aplica el mecanismo **`Partition Pruning`**. El motor descarta automáticamente las particiones ociosas y consulta exclusivamente el segmento físico del segundo trimestre de 2017 (`ecommify_orders_2017_q2`), blindando la mantenibilidad a largo plazo.

---

## 3. Instrucciones de Verificación de Evidencias
Para reproducir científicamente las métricas reportadas en las capturas de este módulo, se deben cargar los scripts de indexación y particionamiento provistos en la raíz de PostgreSQL, y ejecutar la sentencia de auditoría anteponiendo el prefijo reglamentario en la consola de Supabase:
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT ...
```
