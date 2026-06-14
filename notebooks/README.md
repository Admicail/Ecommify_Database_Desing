#Componentes de Análisis y ETL (Google Colab Notebooks)


**Esteban Giovanny Garay Cano**  

**Carlos Alfonso Muñoz Agudelo**

**Carlos Sebastian Castillo Silva**


*Proyecto Integrador: Módulo Analítico e Ingeniería de Datos*


Esta sección del repositorio concentra los entornos de trabajo desarrollados en **Google Colab**, los cuales componen la fase de Ingeniería de Datos (ETL), auditoría de calidad, control de conectividad y el sustento matemático de la infraestructura para **Ecommify**.

---

## 1. Inventario de Notebooks y Flujos de Trabajo

La carpeta se divide en componentes modulares organizados por su secuencia lógica de ejecución:

### 1. Diagnóstico Exploratorio y Calidad de Datos
*   **Nombre del Archivo**: `01_data_analysis.ipynb`
*   **Objetivo**: Realizar la ingesta cruda de las fuentes relacionales del dataset original de Kaggle (Olist), mapear sus dependencias estructurales y auditar la presencia de registros nulos.
*   **Hallazgos Críticos**: Detección de llaves foráneas lógicas (`customer_id`, `order_id`, `product_id`, `seller_id`) y el aislamiento de **610 registros nulos** en la taxonomía de productos, justificando la necesidad de etapas de limpieza antes de la migración NoSQL.

### 2. Ingeniería de Datos y Transformación para PostgreSQL
*   **Nombre del Archivo**: `02_generate_data_files_sql_postgres.ipynb`
*   **Objetivo**: Ejecutar los algoritmos de transformación (ETL) para convertir el dataset plano original hacia los tipos de datos avanzados requeridos por la arquitectura relacional transaccional.
*   **Mecanismos Aplicados**: Conversión de direcciones a tipos compuestos (`Udt`), empaquetado de especificaciones en cadenas JSON semiestructuradas y transformación de coordenadas a formato espacial estándar **WKT (Well-Known Text)** como objetos `POINT(...)`.

### 3. Modelado y Estructuración de Documentos JSON para MongoDB
*   **Nombre del Archivo**: `03_generate_mongodb_json_files.ipynb`
*   **Objetivo**: Diseñar los esquemas jerárquicos NoSQL aplicando el patrón de diseño incrustado, inicializando arreglos limpios de multimedia y subdocumentos analíticos para carritos y calificaciones.

### 4. Producción, Limpieza y Exportación Masiva NoSQL
*   **Nombre del Archivo**: `04_generate_mongo_db_json_files_production.ipynb`
*   **Objetivo**: Realizar la limpieza final de datos nulos mediante funciones de reemplazo absoluto (`.fillna("")`) y exportar de forma masiva los esquemas homologados en formato JSON nativo limpios de fallas de tipado.
*   **Métricas de Salida**: Generación exitosa de **32,951** documentos de catálogo y **99,441** documentos de sesión listos para inyección en el clúster.

### 5. Verificación de Conectividad mediante Escritura NoSQL
*   **Nombre del Archivo**: `05_nosql_connectivity_verification.ipynb`
*   **Objetivo**: Validar la arquitectura de red externa y los privilegios de acceso hacia el clúster remoto en la nube mediante controladores oficiales.
*   **Directrices Técnicas**: Recuperación de la cadena `MONGO_URI` desde los secretos de Colab e inserción física automatizada de un documento de auditoría con marca de tiempo global (`Timestamp UTC`).

### 6. Evaluación de Distribución Geográfica de Sellers y su Impacto
*   **Nombre del Archivo**: `06_evaluar_distribucion_geografica_sellers.ipynb`
*   **Objetivo**: Calcular el grado de concentración del inventario para validar las decisiones de diseño de la Shard Key utilizando el Algoritmo del Índice de Herfindahl-Hirschman (HHI).

---

## 2. Resultados del Análisis de Concentración Geográfica (HHI)

El script analítico cruzó el volumen total de productos activos contra el estado federado de origen de cada vendedor, arrojando las siguientes métricas de infraestructura:

*   **Volumen de Productos Evaluados**: 112,650 registros físicos de stock.
*   **Regiones Proveedoras**: 23 Estados Federados detectados.
*   **Índice HHI Geográfico Resultante**: **5,243.98 puntos**.

### Top 5 de Concentración de Carga de Escritura:
```text
seller_state   Productos_En_Catalogo   Participacion_%
     SP                 80,342             71.32 %
     MG                  8,827              7.83 %
     PR                  8,671              7.69 %
     RJ                  4,818              4.27 %
     SC                  4,075              3.61 %
```

### Diagnóstico Técnico y Justificación de Arquitectura NoSQL:
De acuerdo con las escalas de la ingeniería de datos, un resultado superior a los 2,500 puntos se clasifica como una **Concentración Crítica**. El estado de **São Paulo (SP) monopoliza de forma severa el 71.32% de la inyección de ítems** del catálogo.

*   **Riesgo de Hotspot**: Si se seleccionara la ubicación geográfica del vendedor como Shard Key, el balanceador automático acumularía la gran mayoría de los bloques de datos (*chunks*) en un único servidor físico. Durante una actualización masiva de inventario, el Shard asignado a la región 'SP' sufriría una saturación crítica de disco y CPU, mientras los demás Shards permanecerían ociosos.
*   **Validación de la Solución**: Este hallazgo matemático justifica con total autoridad técnica el descarte definitivo de claves geográficas y reconfirma la selección de la **Compound Shard Key `{ category: 1, _id: "hashed" }`** para blindar la escalabilidad horizontal del hardware de Ecommify.

---

## 3. Instrucciones para la Reproducción de los Entornos

1.  **Clonar el repositorio** y abrir la herramienta de **Google Colab**.
2.  Acceder al entorno seguro de Colab y registrar la variable secreta `MONGO_URI` haciendo clic en el ícono de la llave lateral.
3.  Vincular la cuenta personal de Google Drive para dar soporte físico a las rutas configuradas en la variable `DATA_DIR`.
4.  Ejecutar de forma secuencial las celdas de cada notebook para comprobar la veracidad de las transformaciones y los diagnósticos matemáticos del sistema.
