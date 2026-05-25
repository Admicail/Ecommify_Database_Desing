-- Consultas JSONB para Ecommify

-- Productos con especificaciones de peso mayor a cero
SELECT
    product_id,
    product_category_name,
    product_specifications ->> 'weight_g' AS weight_g
FROM ecommify_products
WHERE (product_specifications ->> 'weight_g')::numeric > 0;

-- Búsqueda de productos que contengan una clave específica
SELECT
    product_id,
    product_specifications
FROM ecommify_products
WHERE product_specifications ? 'weight_g';

-- Pagos que contengan detalles financieros registrados
SELECT
    order_item_id,
    order_id,
    payment_details
FROM ecommify_order_details
WHERE jsonb_array_length(payment_details) > 0;
