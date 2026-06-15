
# 1. Obtener detalle completo de una orden

**Proceso:** Confirmación de compra

```sql
SELECT
    o.order_id,
    o.order_status,
    c.customer_unique_id,
    od.product_id,
    od.price,
    od.freight_value
FROM ecommify_orders o
JOIN ecommify_customers c
    ON o.customer_id = c.customer_id
JOIN ecommify_order_details od
    ON o.order_id = od.order_id
WHERE o.order_id = 'ID_ORDEN';
```

---

# 2. Obtener información del pago de una orden

**Proceso:** Pasarela de pago

```sql
SELECT
    order_id,
    payment_details
FROM ecommify_order_details
WHERE order_id = 'ID_ORDEN';
```

---

# 3. Calcular valor total de una compra

**Proceso:** Facturación

```sql
SELECT
    order_id,
    SUM(price + freight_value) AS total_compra
FROM ecommify_order_details
GROUP BY order_id;
```

---

# 4. Consultar órdenes pendientes de pago

**Proceso:** Control financiero

```sql
SELECT
    order_id,
    order_status
FROM ecommify_orders
WHERE order_status = 'created';
```

---

# 5. Historial de compras de un cliente

**Proceso:** Atención al cliente

```sql
SELECT
    c.customer_id,
    o.order_id,
    o.order_status,
    o.order_estimated_delivery
FROM ecommify_customers c
JOIN ecommify_orders o
    ON c.customer_id = o.customer_id
WHERE c.customer_id = 'CUSTOMER_ID';
```

---

# 6. Productos vendidos por vendedor

**Proceso:** Gestión de vendedores

```sql
SELECT
    seller_id,
    COUNT(*) cantidad_vendida,
    SUM(price) ventas
FROM ecommify_order_details
GROUP BY seller_id
ORDER BY ventas DESC;
```

---

# 7. Top 10 vendedores

**Proceso:** KPI comercial

```sql
SELECT
    seller_id,
    SUM(price) total_vendido
FROM ecommify_order_details
GROUP BY seller_id
ORDER BY total_vendido DESC
LIMIT 10;
```

---

# 8. Top 10 productos más vendidos

**Proceso:** Inteligencia de negocio

```sql
SELECT
    product_id,
    COUNT(*) veces_vendido
FROM ecommify_order_details
GROUP BY product_id
ORDER BY veces_vendido DESC
LIMIT 10;
```

---

# 9. Órdenes listas para Pick & Pack

**Proceso:** Preparación de pedidos

```sql
SELECT
    order_id,
    order_status
FROM ecommify_orders
WHERE order_status = 'approved';
```

---

# 10. Productos que deben prepararse para despacho

**Proceso:** Pick & Pack

```sql
SELECT
    od.order_id,
    od.product_id,
    p.product_category_name
FROM ecommify_order_details od
JOIN ecommify_products p
    ON od.product_id = p.product_id
WHERE od.order_id = 'ID_ORDEN';
```

---

# 11. Órdenes despachadas

**Proceso:** Etiquetado y despacho

```sql
SELECT
    order_id,
    order_status
FROM ecommify_orders
WHERE order_status = 'shipped';
```

---

# 12. Seguimiento de envíos

**Proceso:** Tracking

```sql
SELECT
    order_id,
    lower(order_logistics_timeline) fecha_compra,
    upper(order_logistics_timeline) fecha_entrega,
    order_estimated_delivery
FROM ecommify_orders;
```

---

# 13. Pedidos entregados

**Proceso:** Entrega al cliente

```sql
SELECT
    order_id,
    order_status
FROM ecommify_orders
WHERE order_status = 'delivered';
```

---

# 14. Tiempo promedio de entrega

**Proceso:** Indicador logístico

```sql
SELECT
    AVG(
        upper(order_logistics_timeline)
        -
        lower(order_logistics_timeline)
    ) tiempo_promedio
FROM ecommify_orders
WHERE order_status = 'delivered';
```

---

# 15. Ventas por categoría

**Proceso:** Reporte gerencial

```sql
SELECT
    p.product_category_name,
    COUNT(*) cantidad,
    SUM(od.price) total_vendido
FROM ecommify_order_details od
JOIN ecommify_products p
    ON od.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY total_vendido DESC;
```
