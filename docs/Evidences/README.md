# Carpeta de Evidencias
**Carlos Alfonso Muñoz Agudelo - Esteban Giovanny Garay Cano - Carlos Sebastian Castillo Silva**  
*Proyecto Integrador*


# Diagramas de dominio y la Justificación arquitectónica

Este módulo reúne la documentación maestra, diagramas de dominio y la justificación arquitectónica que sustentan el modelo híbrido implementado para la plataforma de comercio electrónico multiproveedor **Ecommify**, inspirada en el ecosistema de datos de Olist.

---

## 1. Enfoque de Persistencia Políglota Híbrida
Para resolver los problemas tradicionales de rendimiento, flexibilidad y escalabilidad masiva, la plataforma fragmenta sus responsabilidades operativas en dos grandes frentes tecnológicos:

1.  **Core Transaccional y Logístico (PostgreSQL)**: Diseñado bajo un esquema rígido y normalizado (Tercera Forma Normal - 3FN). Garantiza consistencia inmediata y aislamiento absoluto mediante propiedades ACID para proteger el ciclo de vida de órdenes, desgloses financieros de pagos y control de inventarios.
2.  **Módulo Documental e Interactivo (MongoDB Atlas)**: Diseñado bajo un esquema flexible, desnormalizado y orientado a documentos. Gestiona la alta demanda de lectura concurrente en el catálogo enriquecido de productos, campañas promocionales y el mantenimiento de las sesiones y carritos activos con latencias inferiores a 50 ms.

---

## 2. Justificación Arquitectónica según el Teorema CAP

La distribución del modelo de dominio se segmenta estratégicamente para equilibrar los compromisos lógicos del sistema distribuido:

*   **Enfoque CP (Consistencia + Tolerancia a Particiones) - PostgreSQL**: En el procesamiento de compras y pagos es inaceptable la pérdida de datos o estados inconsistentes. El sistema prefiere rechazar o revertir una operación transaccional crítica antes que confirmar datos corruptos o duplicar cobros financieros.
*   **Enfoque AP (Disponibilidad + Tolerancia a Particiones) - MongoDB**: En la navegación del catálogo y el carrito de compras se prioriza que la interfaz web responda siempre de forma veloz. Se acepta una consistencia eventual (ej. ligeros retrasos en la actualización de una promoción o reseña) a cambio de blindar la plataforma contra caídas durante picos masivos de tráfico como un Black Friday.

---

## 3. Patrones de Modelado Documental Aplicados (MongoDB)

Para optimizar las lecturas masivas y eliminar el costo computacional de las uniones de tablas tradicionales, se implementaron cinco patrones lógicos:

1.  **Patrón de Incrustación (Embedding)**: Subdocumentos como promociones activas, dimensiones y líneas de carritos se fusionan en el documento padre, reduciendo el consumo de memoria I/O y CPU al resolver la consulta en una sola operación por llave primaria.
2.  **Patrón de Documento Autocontenido**: Cada ficha de producto almacena de forma desnormalizada toda la información multimedia y reputación necesaria para pintar la interfaz de usuario de inmediato.
3.  **Patrón de Resumen Precalculado**: El campo `reviews_summary` guarda la calificación promedio (`avg_score`) y el total de reseñas en caché, evitando operaciones de agregación masivas cuando miles de usuarios navegan simultáneamente.
4.  **Patrón TTL (Time-To-Live)**: Configuración de un índice de expiración sobre el campo `expires_at` en las sesiones, purgando automáticamente los carritos abandonados e inactivos para mantener limpia la memoria RAM del clúster.
5.  **Patrón de Referencia Lógica entre Motores**: Los motores conviven mediante un acoplamiento débil. Campos como `postgres_product_id` y `customer_id` sirven como enlaces lógicos sin restricciones físicas de integridad referencial para permitir que cada base de datos escale de forma independiente.

---

## 4. Flujos de Sincronización Inter-Motor

El negocio orquesta el ciclo de vida de la información a través de 5 flujos lógicos controlados desde la capa de la aplicació


# Documentación Técnica del Diseño Conceptual y Lógico

Este módulo concentra las especificaciones de diseño conceptual y lógico que orquestan el ecosistema de datos de **Ecommify**. El modelo fragmenta el dominio de Olist para explotar las fortalezas del motor relacional PostgreSQL y el motor documental MongoDB Atlas, conviviendo bajo un esquema de acoplamiento débil.


## 1. Enfoque Arquitectónico Seleccionado

Ecommify adopta una **Arquitectura Políglota Híbrida**, bajo la premisa de que una plataforma moderna de alta escala no debe limitarse a un único tipo de motor de base de datos.

## 1.1 Esquema Relacional Base de Datos transaccional

<img width="934" height="709" alt="Esquema Relacional" src="https://github.com/Admicail/Ecommify_Database_Desing/blob/main/docs/Evidences/screenshots/Esquema%20Relacional.jpg" />

## 1.2 Colecciones de datos en MongoDB

<img src="https://github.com/Admicail/Ecommify_Database_Desing/blob/main/docs/Evidences/screenshots/Colecciones%20MongoDB.png" width="300">


## 2. Especificación Detallada del Modelo Lógico

### A. Módulo Transaccional (PostgreSQL)
Las entidades core del negocio se estructuran bajo tipos de datos avanzados y extensiones empresariales para maximizar el rendimiento:
*   **Clientes y Vendedores (`ecommify_customers` / `ecommify_sellers`)**: Implementan el atributo compuesto personalizado **`address_type`**, el cual encapsula de forma atómica el código postal, la ciudad y el estado, promoviendo la reutilización de código.
*   **Órdenes (`ecommify_orders`)**: Incorpora el tipo avanzado de Rango Temporal **`TSRANGE`** (`order_logistics_timeline`). Almacena en una sola columna el momento exacto de la compra y la entrega física, optimizando las consultas analíticas de tiempos de entrega y asegurando la coherencia cronológica.
*   **Detalles de Órdenes (`ecommify_order_details`)**: Entidad asociativa que congela precios y fletes individuales. Maneja los desgloses de pagos múltiples y complejos (ej. combinar tarjetas y cupones) mediante un tipo **`JSONB`** (`payment_details`) respaldado por índices GIN.
*   **Geolocalización (`ecommify_geolocation`)**: Integra la extensión espacial **PostGIS** bajo el tipo nativo **`geometry(Point, 4326)`**. Permite calcular distancias vectoriales y optimizar costos de flete por proximidad de códigos postales.

### B. Módulo Documental (MongoDB)
Las colecciones principales aplican el **Patrón de Incrustación (Embedding)** para auto-contener los datos relacionados y eliminar por completo el costo computacional de las operaciones `JOIN`:
*   **Catálogo de Productos (`catalog_products_collection`)**: Almacena fichas unificadas de productos. El campo `attributes` se define como un objeto flexible polimórfico para aceptar especificaciones variables según la categoría sin alterar la base de datos. Incorpora el campo precalculado `reviews_summary` (`avg_score` y `total_reviews`) que actúa como caché analítico para evitar agregaciones pesadas en caliente.
*   **Sesiones de Clientes (`customer_sessions_collection`)**: Gestiona las variables efímeras de carritos de compras activos en tiempo real. Implementa el **Patrón TTL** sobre el campo `expires_at` para purgar automáticamente del clúster las sesiones inactivas o carritos abandonados, protegiendo la memoria RAM.

---

## 3. Estrategia de Integración e Inter-Motor

La base de datos híbrida opera bajo un esquema de **Acoplamiento Débil**, donde la consistencia cruzada no se basa en restricciones físicas (llaves foráneas inter-motor), sino en **referencias lógicas compartidas**. 

*   El `_id` de la colección de productos en MongoDB coincide lógicamente con la clave primaria `product_id` en PostgreSQL.
*   El `customer_id` de la sesión en MongoDB se empareja lógicamente con el registro maestro del cliente guardado en PostgreSQL.

### Flujo Crítico de Checkout y Compra:
1.  El usuario navega por el catálogo (consultas AP veloces a MongoDB) y añade elementos a su carrito (escrituras en tiempo real en la colección de sesiones NoSQL).
2.  Al presionar el botón de pago, la capa de aplicación lee el payload del documento de la sesión en MongoDB y lo transfiere hacia las tablas relacionales de PostgreSQL.
3.  PostgreSQL procesa e inserta los datos de forma atómica en las tablas `ecommify_orders` y `ecommify_order_details`, validando la precisión financiera de precios y fletes bajo tipos exactos `NUMERIC` y protegiendo la transacción bajo garantías ACID absolutas.

