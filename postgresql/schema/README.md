# Estructura del Esquema Transaccional - PostgreSQL (Supabase)
**Carlos Alfonso Muñoz Agudelo - Esteban Giovanny Garay Cano - Carlos Sebastian Castillo Silva**  
*Proyecto Integrador: Modelo de Datos Relacional y Tipos Avanzados*

Este módulo detalla el script de inicialización y despliegue físico del esquema transaccional para **Ecommify**. El diseño de la base de datos aprovecha las capacidades avanzadas de PostgreSQL (extensiones geoespaciales, datos semiestructurados y tipos lógicos complejos) para garantizar la integridad referencial y soportar de forma segura el core financiero de la plataforma.

---

## 1. Infraestructura de Extensiones y Tipos Personalizados

Antes del aprovisionamiento de las tablas, el script prepara el entorno del motor relacional mediante los siguientes componentes lógicos:

*   **`postgis`**: Extensión nativa que habilita el almacenamiento de objetos geográficos y el cómputo de funciones espaciales para optimizar la logística de entregas.
*   **`btree_gin`**: Extensión que permite combinar clases de operadores B-Tree con el índice invertido GIN, facilitando la creación de índices compuestos en tipos mixtos.
*   **`address_type`**: Tipo de Dato Compuesto (*User-Defined Type - UDT*) diseñado para estandarizar la persistencia de datos postales. Estructura de forma atómica el código postal (`zip_code`), la ciudad (`city`) y el estado federado (`state`), reduciendo la cantidad de columnas físicas en las tablas de clientes y vendedores.

---

## 2. Diccionario Técnico de las Tablas Estructuradas

El diseño relacional se compone de las siguientes entidades normalizadas y enlazadas mediante restricciones estrictas de clave foránea (`FOREIGN KEY`):

### A. Capa de Entidades Base (Catálogo y Actores)
*   **`ecommify_customers`**: Almacena el identificador único del comprador y su dirección estandarizada mediante el UDT `address_type`.
*   **`ecommify_sellers`**: Registra los datos de los proveedores y su ubicación logística de despacho de stock.
*   **`ecommify_products`**: Entidad híbrida que guarda las llaves de catálogo. Implementa la columna `product_specifications` como tipo **JSONB** para empaquetar dimensiones físicas sin alterar el esquema relacional, e indexa arreglos de texto (`TEXT[]`) para las rutas multimedia de fotos.

### B. Capa Geoespacial
*   **`ecommify_geolocation`**: Centraliza las coordenadas del mapa. Reemplaza las columnas de latitud y longitud planas por el objeto nativo **`geometry(Point, 4326)`** bajo el estándar espacial SRID 4326. Incorpora un índice **GiST** (`idx_geo_point`) para resolver cálculos de distancias por fuerza bruta en microsegundos.

### C. Capa Transaccional de Negocio
*   **`ecommify_orders`**: Orquesta el ciclo de vida de la compra. Implementa el tipo de dato avanzado de Rango Temporal **`TSRANGE`** (`order_logistics_timeline`) para consolidar de forma compacta y en una sola variable las marcas de tiempo de compra y entrega efectiva al cliente, evitando inconsistencias cronológicas lógicas.
*   **`ecommify_order_details`**: Tabla pivote de alta densidad de lectura. Rompe la relación muchos a muchos e incorpora una columna **JSONB** (`payment_details`) indexada mediante una estructura **GIN** invertida para registrar la auditoría completa de los métodos de pago (pasarela, cuotas y montos).

---

## 3. Instrucciones de Despliegue y Setup

Para inicializar y compilar el esquema relacional en el servidor de Supabase:

1.  Acceder a la consola de administración del proyecto en **Supabase** o utilizar una herramienta de administración SQL (ej. pgAdmin / DBeaver) conectada al motor.
2.  Garantizar los privilegios de superusuario para permitir la correcta compilación de las extensiones `postgis` y `btree_gin`.
3.  Cargar y ejecutar el bloque completo del script de creación de tablas (`database_schema.sql`).
4.  **Verificación**: Ejecutar una consulta de control para validar el correcto mapeo referencial del sistema:
    ```sql
    SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
    ```
