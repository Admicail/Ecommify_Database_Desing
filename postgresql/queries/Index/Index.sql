-- ============================================================================
-- 1. ÍNDICES B-TREE PARA LLAVES FORÁNEAS (Optimiza JOINs operativos)
-- ============================================================================
-- Crucial para los JOINs de las consultas 1, 2, 10 y 15
CREATE INDEX IF NOT EXISTS idx_order_details_order_id 
ON ecommify_order_details(order_id);

-- Crucial para el historial de clientes de la consulta 5
CREATE INDEX IF NOT EXISTS idx_orders_customer_id 
ON ecommify_orders(customer_id);


-- ============================================================================
-- 2. ÍNDICES PARCIALES PARA ESTADOS ACTIVOS (Optimiza flujo de trabajo en bodega)
-- ============================================================================
-- Filtro financiero: Órdenes creadas/esperando pago (Consulta 4)
CREATE INDEX IF NOT EXISTS idx_orders_status_created 
ON ecommify_orders (order_id) 
WHERE order_status = 'created';

-- Filtro logístico de Pick & Pack: Órdenes listas para empacar (Consulta 9)
CREATE INDEX IF NOT EXISTS idx_orders_status_approved 
ON ecommify_orders (order_id) 
WHERE order_status = 'approved';

-- Filtro logístico de Despacho: Órdenes en tránsito (Consulta 11)
CREATE INDEX IF NOT EXISTS idx_orders_status_shipped 
ON ecommify_orders (order_id) 
WHERE order_status = 'shipped';


-- ============================================================================
-- 3. ÍNDICES GIN PARA DATOS COMPLEJOS (JSONB y Búsqueda de Texto)
-- ============================================================================
-- Indexa rutas completas del JSONB para consultas de pasarelas de pago (Consulta 2)
CREATE INDEX IF NOT EXISTS idx_order_details_payment_path_jsonb 
ON ecommify_order_details USING gin (payment_details jsonb_path_ops);

-- Indexa texto normalizado en español para búsquedas inteligentes en categorías (Consulta 10 y 15)
CREATE INDEX IF NOT EXISTS idx_products_category_fts 
ON ecommify_products USING gin (to_tsvector('spanish', product_category_name));


-- ============================================================================
-- 4. ÍNDICE COMPUESTO FUNCIONAL PARA MÉTRICAS LOGÍSTICAS
-- ============================================================================
-- Permite Index-Only Scans para calcular promedios de tiempos de entrega (Consulta 14)
CREATE INDEX IF NOT EXISTS idx_orders_delivery_metrics
ON ecommify_orders (
    order_status, 
    lower(order_logistics_timeline), 
    upper(order_logistics_timeline)
);

