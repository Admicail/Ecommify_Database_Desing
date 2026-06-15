# Creación de Esquemas y Colecciones - MongoDB Atlas
**Carlos Alfonso Muñoz Agudelo - Esteban Giovanny Garay Cano - Carlos Sebastian Castillo Silva**  
*Proyecto Integrador: Módulo Documental Homologado*

Este módulo detalla el despliegue físico de las colecciones NoSQL estructuradas para **Ecommify**. La inicialización de estos contenedores de datos aplica el mecanismo de control **`$jsonSchema`** nativo de MongoDB para garantizar el tipado estricto, resguardar la integridad de la información y dar soporte al ecosistema políglota de la plataforma.

---

## 1. Especificación Técnica de los Esquemas Creados

### A. Colección del Catálogo de Productos (`catalog_products_collection`)
*   **Propósito**: Almacenar la información analítica, multimedia y de marketing del catálogo de productos de Olist.
*   **Campos Requeridos**: El identificador único del producto (`_id`) y la categoría taxonómica (`category`).
*   **Campos de Negocio Validados**:
    *   `active_promotions`: Subdocumento encargado de la gestión de ofertas de cara al cliente.
    *   `attributes`: Variables logísticas anidadas jerárquicamente (peso y dimensiones físicas de empaque).
    *   `reviews_summary`: Resumen pre-agregado de calificaciones de usuarios para agilizar las búsquedas del frontend.
    *   `postgres_product_id`: Campo clave de integración políglota que enlaza el documento NoSQL con el identificador único relacional del núcleo transaccional en PostgreSQL.

### B. Colección de Sesiones y Carritos Activos (`customer_sessions_collection`)
*   **Propósito**: Gestionar de forma dinámica el estado de los carritos de compras y la actividad transaccional concurrente en tiempo real (Momento 2 de la tienda).
*   **Campos Requeridos**: La clave primaria de la sesión (`_id`), el identificador del cliente (`customer_id`) y el objeto del carrito activo (`active_cart`).
*   **Campos de Negocio Validados**:
    *   `last_activity`: Registra la marca de tiempo de la última acción del usuario para auditoría.
    *   `expires_at`: Campo de tipo fecha configurado bajo un índice TTL (Time-To-Live) para purgar de manera automática del clúster los carritos abandonados e inactivos, optimizando el uso de memoria RAM en producción.

---

## 2. Justificación de la Validación de Esquemas NoSQL

Aunque MongoDB es una base de datos flexible por diseño (*Schemaless*), la arquitectura de software de Ecommify implementa la directiva `$jsonSchema` por los siguientes pilares de ingeniería:

*   **Evitar Corrupción de Datos**: Garantiza que ningún servicio backend pueda inyectar datos huérfanos o con tipos incorrectos (ej. guardar un texto donde el pipeline optimizado espera un descuento numérico), lo que provocaría fallos críticos e interrupciones en la interfaz de la tienda web.
*   **Homologación de Datos**: Las reglas fueron corregidas y calibradas de forma quirúrgica para aceptar valores nulos (`null`) o de tipado mixto (`int` / `double`) en propiedades como fechas de promociones (`valid_until`) y calificaciones promedio (`avg_score`), adaptándose perfectamente al comportamiento real del dataset de Kaggle.

---

## 3. Instrucciones de Inicialización y Setup

Para ejecutar el script de creación y compilar las reglas de validación en el clúster:

1.  Abrir la aplicación **MongoDB Compass** o iniciar la terminal interactiva **MongoDB Shell (`mongosh`)**.
2.  Asegurar la conexión hacia el clúster productivo e invocar el comando para posicionarse sobre el entorno del proyecto:
    ```javascript
    use DataBaseOlistKaggle;
    ```
3.  Copiar el script de código completo (`database_schemas.js`) y ejecutarlo en la consola.
4.  **Verificación**: Dirigirse a la pestaña **Validation** de cada colección dentro del panel web de MongoDB Atlas para confirmar que las estructuras lógicas se encuentren vigentes y protegiendo el almacenamiento.
