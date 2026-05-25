-- Consultas PostGIS para Ecommify

-- Distancia aproximada entre dos códigos postales
SELECT
    g1.geolocation_zip_code_prefix AS origen,
    g2.geolocation_zip_code_prefix AS destino,
    ST_DistanceSphere(g1.geolocation_point, g2.geolocation_point) / 1000 AS distancia_km
FROM ecommify_geolocation g1
JOIN ecommify_geolocation g2
    ON g1.geolocation_zip_code_prefix <> g2.geolocation_zip_code_prefix
LIMIT 10;

-- Códigos postales cercanos a un punto de referencia
SELECT
    geolocation_zip_code_prefix,
    geolocation_city,
    geolocation_state
FROM ecommify_geolocation
ORDER BY geolocation_point <-> ST_SetSRID(ST_MakePoint(-46.6333, -23.5505), 4326)
LIMIT 20;
