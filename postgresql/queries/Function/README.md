# Lógica de Negocio y Funciones Almacenadas - PostgreSQL (PL/pgSQL)
**Carlos Alfonso Muñoz Agudelo - Esteban Giovanny Garay Cano - Carlos Sebastian Castillo Silva**  
*Proyecto Integrador: Módulo Transaccional Automatizado*

Este módulo encapsula las reglas, indicadores de rendimiento (KPIs) y flujos operativos de **Ecommify** directamente en el motor relacional de Supabase. A través de funciones optimizadas en `PL/pgSQL`, se reducen los viajes de red (*network round-trips*) entre la aplicación y la base de datos, garantizando operaciones instantáneas bajo el soporte de la estrategia de indexación avanzada.

---

##  1. Catálogo de Funciones Almacenadas por Proceso

Las funciones se encuentran estructuradas siguiendo el ciclo de vida del negocio, desde la confirmación de la compra hasta el seguimiento logístico:

###  Proceso: Confirmación de Compra y Facturación
*   `fn_obtener_detalle_orden(p_order_id)`: Recupera el desglose completo de una orden uniendo el núcleo transaccional, clientes y detalles. Trabaja directamente sobre el índice B-Tree clásico de llaves foráneas.
*   `fn_calcular_total_compra(p_order_id)`: Calcula el costo de la compra sumando de forma exacta el precio de los ítems y los valores de flete logístico agrupados por identificador de orden.

###  Proceso: Pasarela de Pago (Datos Semiestructurados)
*   `fn_obtener_pago_orden(p_order_id)`: Extrae el subdocumento JSONB de auditoría de pago para una orden específica.
*   `fn_buscar_por_metodo_pago(p_payment_type)`: Realiza búsquedas mediante el operador de contención (`@>`). Aprovecha el índice invertido `GIN (jsonb_path_ops)` para ubicar transacciones instantáneamente (ej. verificar cuáles fueron hechas con `credit_card`) sin abrir las filas secuencialmente.

### Proceso: Gestión Comercial y KPIs (OLAP sobre OLTP)
*   `fn_productos_vendidos_por_vendedor()`: Genera el acumulado de ventas monetarias y cantidad de ítems colocados por oferente, ordenados de forma descendente.
*   `fn_top_vendedores(p_limite)`: Retorna un listado parametrizado por el usuario con los mejores vendedores del e-commerce según su volumen total facturado.
*   `fn_top_productos_vendidos(p_limite)`: Entrega el ranquin de los artículos más vendidos de la tienda web para la toma de decisiones de inventario.

###  Proceso: Cadena Logística (Pick & Pack, Bodega y Despacho)
Estas funciones consumen una cantidad mínima de memoria RAM y CPU al apoyarse en los índices parciales condicionales:
*   `fn_ordenes_pendientes_pago()`: Identifica pedidos en estado `created` esperando pasarela de pago.
*   `fn_ordenes_listas_pick_pack()`: Filtra las órdenes aprobadas (`approved`) que deben ingresar a las bandas de preparación.
*   `fn_productos_preparar_despacho(p_order_id)`: Realiza el cruce con el catálogo para listar las categorías que los operarios de bodega deben empacar.
*   `fn_ordenes_despachadas()`: Consulta las órdenes en tránsito (`shipped`) listas para control de rutas.

### Proceso: Tracking y Monitoreo Logístico
*   `fn_seguimiento_envios()`: Extrae de forma compacta las marcas de tiempo extrayendo los límites inferior (fecha de compra) y superior (fecha de entrega) del tipo de dato de rango `tsrange`, emparejándolos contra la fecha estimada de entrega.

---

##  2. Guía de Uso e Invocación SQL

Para consumir estas funciones desde cualquier servicio backend o consola de administración, se aplican los comandos estándar de selección:

```sql
-- 1. Consultar el detalle de una compra específica
SELECT * FROM fn_obtener_detalle_orden('00018f77f2f0320c557190d7a144bdd3');

-- 2. Buscar auditorías de pago realizadas exclusivamente con tarjeta de crédito
SELECT * FROM fn_buscar_por_metodo_pago('credit_card');

-- 3. Obtener el reporte gerencial con el TOP 10 de productos más vendidos
SELECT * FROM fn_top_productos_vendidos(10);

-- 4. Listar las órdenes pendientes en bodega para el flujo de Pick & Pack
SELECT * FROM fn_ordenes_listas_pick_pack();
```

---

## 📥 3. Instrucciones de Instalación

1.  Acceder al editor SQL de **Supabase** dentro del proyecto asignado.
2.  Abrir el archivo de scripts adjunto en esta carpeta (`/postgresql/stored_procedures.sql`).
3.  Ejecutar el bloque completo. El motor compilará la lógica en el esquema `public`, dejándola disponible de forma inmediata para ser invocada mediante APIs Rest o controladores internos de la aplicación.
