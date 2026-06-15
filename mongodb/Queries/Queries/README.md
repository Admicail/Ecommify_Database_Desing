#  Pipeline de Agregación Optimizado - MongoDB Atlas
**Carlos Alfonso Muñoz Agudelo - Esteban Giovanny Garay Cano - Carlos Sebastian Castillo Silva**  
*Proyecto Integrador: Motor de Navegación de Alta Velocidad*

Este módulo detalla la implementación y el comportamiento físico del **Aggregation Pipeline de 5 etapas** diseñado para resolver de forma ultrasónica el patrón de acceso principal de **Ecommify**: la navegación paginada por categorías de cara al usuario web, priorizando los productos con mayores ofertas activos.

---

##  1. Especificación Técnica del Pipeline Optimizado

Para garantizar respuestas en tiempo real y mitigar el uso de memoria RAM, se despliega el siguiente pipeline estructurado de forma quirúrgica de izquierda a derecha:

```javascript
db.CATALOG_PRODUCTS_COLLECTION.explain("executionStats").aggregate([
  // STAGE 1: Filtrado Temprano utilizando el índice compuesto (IXSCAN)
  { \$match: { category: "cama_mesa_banho" } },

  // STAGE 2: Ordenamiento indexado pre-cubierto físicamente
  { \$sort: { "active_promotions.discount": -1 } },

  // STAGE 3: Proyección Temprana para liberar memoria RAM
  { \$project: { _id: 1, category: 1, active_promotions: 1, reviews_summary: 1 } },

  // STAGE 4: Transformación Analítica acotada
  {
    \$addFields: {
      etiqueta_destacado: {
        \$cond: {
          if: { \(eq: ["\)active_promotions.is_promo", true] },
          then: "OFERTA RECOMENDADA",
          else: "PRODUCTO REGULAR"
        }
      }
    }
  },

  // STAGE 5: Paginación Arquitectural e instantánea
  { \$limit: 20 }
], 
{ 
  // Red de seguridad obligatoria contra desbordamientos (Fail-Safe)
  allowDiskUse: true,
  // Fuerza al motor a anular la caché de planes y usar la ruta física óptima
  hint: { "category": 1, "active_promotions.discount": -1 } 
})
```

---

##  2. Justificación de las Técnicas de Optimización Aplicadas

De acuerdo con el diagnóstico de la arquitectura, este diseño resuelve tres problemas críticos de hardware detectados en la línea base:

*   **Orden Eficiente de los Stages (Filtros Primero)**: Al ubicar `$match` y `$sort` en las posiciones de inicio absoluto, el volumen total de 32,341 productos se reduce de inmediato a un subconjunto del **9.36%** (correspondiente a la categoría *cama_mesa_banho*). Esto evita procesar colecciones completas en las etapas posteriores.
*   **Uso Estratégico de Índices (`hint`)**: La opción `hint` obliga al optimizador de MongoDB a utilizar el índice compuesto `{ category: 1, "active_promotions.discount": -1 }`. Esto transforma la consulta de un costoso escaneo de colección (`COLLSCAN`) a un acceso por índice quirúrgico (**`IXSCAN`**). El enrutador intercepta la petición y ejecuta una **Consulta Dirigida (Targeted Query)** enviándola al Shard físico exacto que guarda esa categoría, eliminando el tráfico basura en la red del clúster (*Scatter-Gather*).
*   **Proyecciones Tempranas**: Al ejecutar el `$project` en el **Stage 3**, se eliminan del flujo de memoria el subdocumento pesado `attributes` (pesos, dimensiones de empaque de Olist y datos de fotos). Al procesar solo los bytes estrictamente necesarios, la consulta se mantiene muy por debajo del límite drástico de **100 MB de RAM** por etapa de MongoDB.
*   **Mecanismo de Resiliencia (`allowDiskUse`)**: Se configura la propiedad `{ allowDiskUse: true }` como una **Red de Seguridad (Fail-Safe)**. Durante picos extremos de tráfico masivo (como el Black Friday), si el volumen acumulado de procesamiento roza el umbral de los 100 MB, el motor activa la paginación a disco abriendo archivos temporales ocultos en SSD, garantizando la **alta disponibilidad** de la tienda web; la página cargará pase lo que pase.

---

##  3. Impacto Cuantitativo en las Métricas de Hardware

El reporte real arrojado por el comando `.explain("executionStats")` en el entorno productivo de MongoDB Compass demostró los siguientes incrementos de eficiencia frente a la versión no optimizada:

| Métrica del Escaneo | Pipeline Sin Optimizar | Pipeline OPTIMIZADO | Diagnóstico Técnico del Éxito |
| :--- | :--- | :--- | :--- |
| **`executionTimeMillis`** | 6 milisegundos | **0 milisegundos** | **Velocidad Extrema**: Caída total de la latencia a cero absoluto en CPU al operar 100% sobre memoria RAM y estructuras ordenadas. |
| **`totalDocsExamined`** | 3,029 documentos | **20 documentos** | **Reducción de I/O**: Se eliminó la lectura innecesaria de 3,009 registros, reduciendo el desgaste de disco un 99.3%. |
| **`totalKeysExamined`** | 3,029 llaves | **20 llaves** | **Eficiencia de Índices**: El motor limitó su búsqueda secuencial al tamaño exacto de la página web del frontend. |
| **Etapa de Cierre (`stage`)** | **`SORT` (En memoria RAM)** | **`LIMIT` (Instantáneo)** | **Index-Covered Sort**: El catálogo se lee pre-ordenado físicamente. Desapareció el cuello de botella de ordenamiento manual en caliente. |

---

##  4. Instrucciones para la Reproducción del Test
1. Conectarse al clúster `ClusterOlistKaggle` a través de la interfaz de **MongoDB Compass** o la terminal interactiva `mongosh`.
2. Asegurar la existencia del índice compuesto `{ category: 1, "active_promotions.discount": -1 }` en la colección.
3. Copiar el bloque de código de agregación optimizado y ejecutarlo directamente. El motor procesará la metadata y reportará las métricas de latencia cero en milisegundos de forma predeterminada.
