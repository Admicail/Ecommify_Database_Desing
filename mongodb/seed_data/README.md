# 📂 Datos de Carga e Inyección Masiva (Seed Data - MongoDB)
**Esteban Giovanny Garay Cano**  
*Proyecto Integrador: Datos de Inicialización del Clúster NoSQL*

Esta carpeta contiene los archivos de datos optimizados y homologados en formato JSON nativo. Estos archivos son el resultado directo de los procesos de extracción, limpieza y transformación (ETL) ejecutados sobre los datasets originales planos de Kaggle (Olist), quedando completamente acondicionados para su inyección en **MongoDB Atlas**.

---

## 📄 1. Descripción de los Archivos de Datos

### A. `mongo_catalog_products.json`
*   **Propósito**: Proveer los datos de inicialización para la colección del catálogo global de productos (`CATALOG_PRODUCTS_COLLECTION`).
*   **Estructura y Patrón de Diseño**: Implementa un modelo de datos jerárquico basado en el **Patrón de Documentos Incrustados (Embedded Documents)**. En lugar de fragmentar la información en múltiples tablas relacionales, cada registro agrupa en una sola entidad los siguientes subdocumentos:
    *   `active_promotions`: Subobjeto para la gestión dinámica de ofertas en la interfaz web (inicializado con valores por defecto).
    *   `attributes`: Datos logísticos estructurados que anidan de forma jerárquica el peso (`weight_g`) y las dimensiones físicas de empaque (`length_cm`, `height_cm`, `width_cm`).
    *   `reviews_summary`: Subdocumento analítico pre-agregado para almacenar la calificación promedio (`avg_score`) y el conteo de reseñas, optimizando las consultas del frontend.

### B. `mongo_customer_sessions.json`
*   **Propósito**: Proveer los documentos base para la colección de gestión de carritos y estados de navegación (`CUSTOMER_SESSIONS_COLLECTION`).
*   **Estructura y Patrón de Diseño**: Diseñado para soportar operaciones transaccionales de alta velocidad en tiempo real. 
    *   Utiliza el identificador único de cliente (`customer_unique_id`) como la clave primaria `_id`.
    *   Inicializa el subdocumento `active_cart` con un arreglo vacío de ítems y un total acumulado en cero, quedando listo para absorber escrituras concurrentes e inyecciones de productos de forma balanceada a lo largo del clúster sharded.

---

## 🚀 2. Guía de Ingesta y Setup en la Nube

Para reproducir la carga de estos datos en el entorno de base de datos distribuidos, se debe seguir el siguiente procedimiento técnico:

1.  **Garantizar las Reglas de Validación**: Antes de importar los archivos, se debe asegurar que la colección de destino en MongoDB Atlas tenga cargado el esquema estricto de validación (`validation-schema.json`) para mantener la integridad del tipado.
2.  **Ejecutar la Importación desde MongoDB Compass**:
    *   Abrir la herramienta de escritorio **MongoDB Compass** y conectarse al clúster operativo.
    *   Ingresar a la base de datos e ir a la colección correspondiente.
    *   Hacer clic en el botón **Add Data** y seleccionar la opción **Import JSON or CSV file**.
    *   Seleccionar el archivo físico deseado (`mongo_catalog_products.json` o `mongo_customer_sessions.json`), verificar que el formato sea detectado como un arreglo JSON válido y presionar **Import**.
3.  **Verificación**: Confirmar que la inyección masiva finalice de forma exitosa y que el contador de documentos refleje la persistencia correcta de los registros en el almacenamiento de Atlas.
