# ⚡ Estrategia de Indexación Avanzada NoSQL - MongoDB Atlas
**Carlos Alfonso Muñoz Agudelo - Esteban Giovanny Garay Cano - Carlos Sebastian Castillo Silva**  
*Proyecto Integrador: Capa Interactiva de Baja Latencia*

Este módulo detalla el diseño y despliegue físico del índice compuesto implementado en el clúster NoSQL de **Ecommify**. La estrategia se fundamenta en principios avanzados de optimización para bases de datos documentales, erradicando los bloqueos por ordenamiento manual y garantizando la escalabilidad de la tienda web.

---

## 📑 1. Especificación Técnica del Índice Compuesto

Para optimizar el patrón de acceso principal del frontend (navegación paginada por categorías con visualización prioritaria de ofertas), se ejecutó la creación del siguiente índice compuesto en el clúster productivo:

```javascript
db.CATALOG_PRODUCTS_COLLECTION.createIndex({ 
  "category": 1, 
  "active_promotions.discount": -1 
})
```

### 🧱 Justificación Estructural bajo la Regla ESR (Equality, Sort, Range)
El diseño de la llave compuesta sigue estrictamente el estándar de ingeniería NoSQL **ESR** para maximizar la eficiencia del motor de búsqueda:

1.  **Filtro de Igualdad (`category: 1`)**: Al colocarse como el prefijo absoluto del índice, permite al enrutador distribuido `mongos` interceptar las consultas de navegación y realizar una **Consulta Dirigida (Targeted Query)** directo al Shard físico específico que almacena dicha categoría. Esto elimina por completo el tráfico basura en la red del clúster provocado por los escaneos distribuidos (*Scatter-Gather*).
2.  **Filtro de Ordenamiento (`"active_promotions.discount": -1`)**: El segundo componente accede de forma directa a una propiedad incrustada dentro del subdocumento de promociones. Al definirse en sentido descendente, los productos se ordenan físicamente en el árbol de datos de mayor a menor descuento.

---

## 🚀 2. Impacto Cuantitativo en el Hardware (Antes vs. Después)

A través del método analítico nativo `.explain("executionStats")` ejecutado en MongoDB Compass, se contrastó el rendimiento del hardware al cargar las tarjetas de productos del catálogo de Olist (32,341 registros activos):

*   **Eliminación del Escaneo Global (`COLLSCAN`)**: Sin el índice, el sistema leía los miles de registros uno por uno en disco duro. Con el índice activo, realiza un **`IXSCAN` (Index Scan)** quirúrgico, saltando directamente al subbloque de la categoría en la memoria RAM.
*   **Erradicación del Cuello de Botella `SORT` en RAM**: En la versión sin optimizar, el motor filtraba los 3,029 documentos de la categoría elegida, pero al estar desordenados, se veía obligado a cargarlos en una cola de la memoria RAM del servidor para ordenarlos manualmente en caliente (activando la etapa de bloqueo `SORT` con un límite estricto de 32 MB).
*   **Acceso Quirúrgico**: Con el índice compuesto, los datos se leen **pre-ordenados de forma física**. El motor encadena de forma nativa la paginación (`LIMIT`), reduciendo el parámetro `docsExamined` de **3,029 documentos a exactamente 20 registros**. Esto disminuyó la latencia de procesamiento de **6 ms a 0 ms** netos en la CPU del clúster.

---

## 📥 3. Instrucciones de Despliegue

1.  Iniciar la aplicación de escritorio **MongoDB Compass** o abrir el shell interactivo (`mongosh`) conectado al clúster `ClusterOlistKaggle`.
2.  Asegurar el posicionamiento sobre la base de datos `DataBaseOlistKaggle` y la colección `CATALOG_PRODUCTS_COLLECTION`.
3.  Pegar y ejecutar el comando de creación de índice en la consola de comandos. El clúster de MongoDB Atlas estructurará los punteros en segundo plano, habilitando la aceleración inmediata de las peticiones del frontend.
