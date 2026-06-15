-- ============================================================================
-- PROCESO: CONFIRMACIÓN DE COMPRA
-- 1. Obtener detalle completo de una orden
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_obtener_detalle_orden(p_order_id TEXT)
RETURNS TABLE(
    order_id TEXT,
    order_status TEXT,
    customer_unique_id TEXT,
    product_id TEXT,
    price NUMERIC,
    freight_value NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT o.order_id, o.order_status, c.customer_unique_id, od.product_id, od.price, od.freight_value
    FROM ecommify_orders o
    JOIN ecommify_customers c ON o.customer_id = c.customer_id
    JOIN ecommify_order_details od ON o.order_id = od.order_id
    WHERE o.order_id = p_order_id;
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- PROCESO: PASARELA DE PAGO
-- 2. Obtener información del pago de una orden (Optimizado para JSONB Contención)
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_obtener_pago_orden(p_order_id TEXT)
RETURNS TABLE(
    order_id TEXT,
    payment_details JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT od.order_id, od.payment_details
    FROM ecommify_order_details od
    WHERE od.order_id = p_order_id;
END;
$$ LANGUAGE plpgsql;

-- Ejemplo extra: Buscar directamente POR un tipo de pago usando el índice jsonb_path_ops
CREATE OR REPLACE FUNCTION fn_buscar_por_metodo_pago(p_payment_type TEXT)
RETURNS TABLE(order_id TEXT, payment_details JSONB) AS $$
BEGIN
    RETURN QUERY
    SELECT od.order_id, od.payment_details
    FROM ecommify_order_details od
    WHERE od.payment_details @> jsonb_build_object('payment_type', p_payment_type);
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- PROCESO: FACTURACIÓN
-- 3. Calcular valor total de una compra
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_calcular_total_compra(p_order_id TEXT)
RETURNS TABLE(
    order_id TEXT,
    total_compra NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT od.order_id, SUM(od.price + od.freight_value) AS total_compra
    FROM ecommify_order_details od
    WHERE od.order_id = p_order_id
    GROUP BY od.order_id;
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- PROCESO: CONTROL FINANCIERO
-- 4. Consultar órdenes pendientes de pago (Usa índice parcial 'created')
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_ordenes_pendientes_pago()
RETURNS TABLE(
    order_id TEXT,
    order_status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT o.order_id, o.order_status
    FROM ecommify_orders o
    WHERE o.order_status = 'created';
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- PROCESO: ATENCIÓN AL CLIENTE
-- 5. Historial de compras de un cliente
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_historial_compras_cliente(p_customer_id TEXT)
RETURNS TABLE(
    customer_id TEXT,
    order_id TEXT,
    order_status TEXT,
    order_estimated_delivery TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT c.customer_id, o.order_id, o.order_status, o.order_estimated_delivery
    FROM ecommify_customers c
    JOIN ecommify_orders o ON c.customer_id = o.customer_id
    WHERE c.customer_id = p_customer_id;
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- PROCESO: GESTIÓN DE VENDEDORES
-- 6. Productos vendidos por vendedor
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_productos_vendidos_por_vendedor()
RETURNS TABLE(
    seller_id TEXT,
    cantidad_vendida BIGINT,
    ventas NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT od.seller_id, COUNT(*), SUM(od.price) AS ventas
    FROM ecommify_order_details od
    GROUP BY od.seller_id
    ORDER BY ventas DESC;
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- PROCESO: KPI COMERCIAL
-- 7. Top N vendedores (Parametrizado el límite de puestos)
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_top_vendedores(p_limite INT)
RETURNS TABLE(
    seller_id TEXT,
    total_vendido NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT od.seller_id, SUM(od.price) AS total_vendido
    FROM ecommify_order_details od
    GROUP BY od.seller_id
    ORDER BY total_vendido DESC
    LIMIT p_limite;
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- PROCESO: INTELIGENCIA DE NEGOCIO
-- 8. Top N productos más vendidos (Parametrizado el límite de puestos)
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_top_productos_vendidos(p_limite INT)
RETURNS TABLE(
    product_id TEXT,
    veces_vendido BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT od.product_id, COUNT(*) AS veces_vendido
    FROM ecommify_order_details od
    GROUP BY od.product_id
    ORDER BY veces_vendido DESC
    LIMIT p_limite;
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- PROCESO: PREPARACIÓN DE PEDIDOS
-- 9. Órdenes listas para Pick & Pack (Usa índice parcial 'approved')
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_ordenes_listas_pick_pack()
RETURNS TABLE(
    order_id TEXT,
    order_status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT o.order_id, o.order_status
    FROM ecommify_orders o
    WHERE o.order_status = 'approved';
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- PROCESO: PICK & PACK
-- 10. Productos que deben prepararse para despacho de una orden específica
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_productos_preparar_despacho(p_order_id TEXT)
RETURNS TABLE(
    order_id TEXT,
    product_id TEXT,
    product_category_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT od.order_id, od.product_id, p.product_category_name
    FROM ecommify_order_details od
    JOIN ecommify_products p ON od.product_id = p.product_id
    WHERE od.order_id = p_order_id;
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- PROCESO: ETIQUETADO Y DESPACHO
-- 11. Órdenes despachadas (Usa índice parcial 'shipped')
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_ordenes_despachadas()
RETURNS TABLE(
    order_id TEXT,
    order_status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT o.order_id, o.order_status
    FROM ecommify_orders o
    WHERE o.order_status = 'shipped';
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- PROCESO: TRACKING
-- 12. Seguimiento de envíos completo
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_seguimiento_envios()
RETURNS TABLE(
    order_id TEXT,
    fecha_compra TIMESTAMP,
    fecha_entrega TIMESTAMP,
    order_estimated_delivery TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT o.order_id, lower(o.order_logistics_timeline), upper(o.order_logistics_timeline), o.order_estimated_delivery
    FROM ecommify_orders o;
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- PROCESO: ENTREGA AL CLIENTE
-- 13. Pedidos entregados
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_pedidos_entregados()
RETURNS TABLE(
    order_id TEXT,
    order_status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT o.order_id, o.order_status
    FROM ecommify_orders o
    WHERE o.order_status = 'delivered';
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- PROCESO: INDICADOR LOGÍSTICO
-- 14. Tiempo promedio de entrega (Usa Índice compuesto funcional)
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_tiempo_promedio_entrega()
RETURNS TABLE(
    tiempo_promedio INTERVAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT AVG(upper(o.order_logistics_timeline) - lower(o.order_logistics_timeline)) AS tiempo_promedio
    FROM ecommify_orders o
    WHERE o.order_status = 'delivered';
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- PROCESO: REPORTE GERENCIAL
-- 15. Ventas por categoría (Optimizado y ordenado por volumen)
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_ventas_por_categoria()
RETURNS TABLE(
    product_category_name TEXT,
    cantidad BIGINT,
    total_vendido NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.product_category_name, COUNT(*), SUM(od.price) AS total_vendido
    FROM ecommify_order_details od
    JOIN ecommify_products p ON od.product_id = p.product_id
    GROUP BY p.product_category_name
    ORDER BY total_vendido DESC;
END;
$$ LANGUAGE plpgsql;

-- Ejemplo extra: Buscar categorías usando el índice GIN de búsqueda por Texto Completo (FTS)
CREATE OR REPLACE FUNCTION fn_buscar_categoria_inteligente(p_termino_busqueda TEXT)
RETURNS TABLE(product_id TEXT, product_category_name TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT p.product_id, p.product_category_name
    FROM ecommify_products p
