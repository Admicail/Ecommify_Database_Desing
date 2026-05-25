-- Consultas de órdenes para Ecommify

-- Órdenes por estado
SELECT
    order_status,
    COUNT(*) AS total_orders
FROM ecommify_orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- Tiempo logístico de cada orden
SELECT
    order_id,
    order_status,
    upper(order_logistics_timeline) - lower(order_logistics_timeline) AS tiempo_entrega
FROM ecommify_orders
WHERE NOT isempty(order_logistics_timeline);

-- Órdenes estimadas por mes
SELECT
    DATE_TRUNC('month', order_estimated_delivery) AS mes,
    COUNT(*) AS total_orders
FROM ecommify_orders
GROUP BY mes
ORDER BY mes;
