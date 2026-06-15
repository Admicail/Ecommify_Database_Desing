# Implementación y Optimización de la Infraestructura de Datos - Ecommify
**Carlos Alfonso Muñoz Agudelo**

**Esteban Giovanny Garay Cano**

**Carlos Sebastian Castillo Silva**


*Proyecto Integrador: Diseño y Optimización de Bases de Datos*

Este repositorio consolida la arquitectura de persistencia políglota, las simulaciones de sistemas distribuidos y las evidencias científicas de optimización aplicadas al catálogo de productos y el módulo analítico de carritos de la plataforma **Ecommify**.

---

## 1. Arquitectura de Persistencia Políglota
La plataforma distribuye sus responsabilidades operativas bajo dos motores complementarios:
*   **Core Transaccional (PostgreSQL)**: Motor relacional encargado en exclusiva de proteger la integridad financiera (Ciclo de vida de órdenes, pagos y facturación) garantizando propiedades ACID.
*   **Capa Interactiva y Analítica (MongoDB Atlas)**: Clúster NoSQL distribuido que gestiona operaciones masivas de baja latencia (Navegación paginada del catálogo y persistencia del estado de sesiones activas).

---

## 2. Estructura del Repositorio
El repositorio se encuentra organizado de forma modular bajo la siguiente topología de archivos:

```text
ecommify-db-optimization/
├── README.md                          <-- Manual maestro y guía de reproducción
├── notebooks/                         
│   └── ecommify_hhi_analysis.ipynb    <-- Notebook de Colab para diagnóstico de Hotspots
├── postgresql/                    
│   │   ── schema.sql                 <-- Esquema transaccional (Orders, Payments)
│   │   ── queries.sql                <-- Flujo crítico de Checkout
│── mongodb/                       
│       ├── validation-schema.json     <-- Reglas de validación JSONSchema corregidas
│       ├── initial-sharding.js        <-- Scripts teóricos de inicialización de Sharding
│       ├── pipeline-unoptimized.js    <-- Pipeline original con etapa SORT en RAM
│       └── pipeline-optimized.js      <-- Pipeline optimizado con soporte de índice compuesto
└── evidence/                          
    ├── datasets/
    │   └── mongo_catalog_products.json <-- Muestra del catálogo homologado importado
    └── screenshots/                   <-- Evidencias gráficas de Compass y Atlas Metrics
```

---

## 3. Instrucciones de Setup y Reproducción (Paso a Paso)

### Paso 1: Diagnóstico Analítico en Google Colab
1. Navegar a la carpeta `/notebooks` y abrir `ecommify_hhi_analysis.ipynb` en Google Colab.
2. Cargar el dataset de productos original.
3. Ejecutar las celdas del script en Python para validar el Índice de Herfindahl-Hirschman (HHI).
   *   **HHI Taxonómico**: **509.78** (Catálogo altamente desconcentrado por categorías).
   *   **HHI Geográfico**: **5,243.98** (Monopolio severo de inventario centralizado en São Paulo con el 71.32% del stock).

### Paso 2: Configuración del Entorno NoSQL (MongoDB Atlas)
1. Ingresar al panel web de **MongoDB Atlas** y seleccionar la base de datos `DataBaseOlistKaggle`.
2. Crear la colección `CATALOG_PRODUCTS_COLLECTION`.
3. Dirigirse a la pestaña **Validation** de la colección y pegar las reglas estrictas provistas en `/database-engines/mongodb/validation-schema.json` para homologar el tipado de datos.
4. Abrir **MongoDB Compass**, conectarse al clúster y utilizar el asistente *Import JSON* para cargar de forma masiva el archivo `evidence/datasets/mongo_catalog_products.json`.

### Paso 3: Despliegue de Índices de Soporte
Para habilitar la optimización del pipeline, acceder a la pestaña **Indexes** en Compass o Atlas y crear un índice compuesto con la siguiente estructura física:
```json
{
  "category": 1,
  "active_promotions.discount": -1
}
```

---

## 4. Reporte de Resultados y Métricas de Rendimiento

A través del método analítico nativo `.explain("executionStats")` ejecutado en el shell de MongoDB Compass, se contrastaron los dos momentos de agregación del catálogo de navegación masiva:

| Variable Evaluada | Pipeline Original (Sin Optimizar) | Pipeline Optimizado | Diagnóstico Técnico de la Mejora |
| :--- | :--- | :--- | :--- |
| **`executionTimeMillis`** | 6 milisegundos | **0 milisegundos** | Reducción total de la latencia a cero absoluto en CPU. |
| **`totalDocsExamined`** | **3,029 documentos** | **20 documentos** | Reducción del 99.3% en el uso de canales de I/O de lectura. |
| **`totalKeysExamined`** | 3,029 llaves | **20 llaves** | Búsqueda quirúrgica limitada al tamaño exacto de la página web. |
| **Etapa de Cierre (`Stage`)** | **`SORT` (En memoria RAM)** | **`LIMIT` (Instantáneo)** | Se eliminó el cuello de botella de ordenamiento manual en caliente. |

---

##  5. Configuración de Arquitectura Distribuida (Teórica)

### Estrategia de Sharding
*   **Colección Catálogo**: Shard Key compuesta `{ category: 1, _id: "hashed" }`. El prefijo garantiza consultas dirigidas (**Targeted Queries**) para la navegación, mientras que el sufijo por Hash dispersa de forma simétrica las actualizaciones masivas de inventario provenientes de São Paulo entre todos los shards.
*   **Colección Sesiones (Carritos)**: Shard Key simple `{ _id: "hashed" }` para lograr una paralelización matemática perfecta del tráfico de escritura concurrente en eventos masivos (Black Friday).

### Topología de Replica Set (Alta Disponibilidad)
Cada fragmento físico del clúster opera bajo un Replica Set de tres nodos distribuidos en distintas zonas de disponibilidad (AZ-A, AZ-B, AZ-C) monitorizados de forma continua:
*   **Nodo Primario**: Centraliza el 100% de las escrituras operativas en caliente.
*   **Nodos Secundarios**: Replican el `oplog` de forma asíncrona y resuelven las lecturas pasivas del frontend mediante la política **`Read Preference: Nearest`** para mitigar la latencia de red.
*   **Políticas de Consistencia**: Se implementa Write Concern `{ w: "majority", j: true }` para la sincronización crítica de precios en el catálogo, y `{ w: 1, j: false }` para maximizar la velocidad al añadir ítems al carrito.

---

