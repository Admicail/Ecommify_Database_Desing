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





# Esquemas Flexibles y Validación NoSQL
Este módulo reúne los reportes analíticos de ejecución, bitácoras de consola y capturas de pantalla que certifican el aprovisionamiento, la inyección masiva de prueba y el comportamiento de los patrones de diseño NoSQL validados de extremo a extremo en el clúster **`ClusterOlistKaggle`** de MongoDB Atlas.

---

## 1. Matriz de Control de Inyección y Estado de Colecciones

Tras ejecutar los scripts automatizados de validación de infraestructura desde la máquina virtual de Google Colab hacia la nube, se capturaron las siguientes métricas de consistencia física en el clúster:

| Parámetro Evaluado | Colección `products` (Catálogo) | Colección `reviews` (Referencia) | Diagnóstico Técnico del Estado del Clúster |
| :--- | :---: | :---: | :--- |
| **Volumen de Datos Inyectados** | **2,000 documentos** | **7,949 documentos** | **Carga Masiva Exitosa**: El clúster absorbió la carga sin pérdida de paquetes ni bloqueos en el firewall de Atlas. |
| **Estrategia de Modelado** | `Polymorphic & Embedded` | `External Referencing` | El documento primario se mantiene ligero al aislar los miles de comentarios en una colección satélite. |
| **Mecanismo de Conectividad** | Cifrado (`MONGO_URI`) | Cifrado (`MONGO_URI`) | Cero exposición de credenciales en texto plano mediante el gestor de secretos de Colab. |
| **Índice de Control (`_id`)** | Generado por Motor | Generado por Motor | La presencia de hashes hexadecimales (**`ObjectId`**) certifica el éxito de la escritura implícita. |

---

## 🔬 2. Diagnóstico Técnico de Evidencias Gráficas

Las capturas de pantalla guardadas en este módulo sirven como sustento científico de la validación del esquema polimórfico:

### Evidencia 1: Control Perimetral de Red (`network_access_0000.png`)
*   **Detalle Visual**: Muestra la pestaña **Network Access** en la consola web de MongoDB Atlas.
*   **Diagnóstico**: Evidencia la configuración activa de las listas de control de acceso IP (`IP Access List`). Registra la regla global `0.0.0.0/0` para facilitar el enlace dinámico de las IPs variables asignadas por las máquinas virtuales de Google Colab durante la etapa de pruebas de software.

<img src="https://github.com/Admicail/Ecommify_Database_Desing/blob/main/docs/Evidences/screenshots/IP%20Acces%20List.jpg" width="300">


## 3. Preparar e insertar colección de productos de ejemplo

1.  Verificación de la carga de documentos.
2.  Se verifica la colección: **clusterolistkaggle.yjfzm0i.mongodb.net --> DataBaseOlistKaggle --> CATALOG_PRODUCTS_COLLECTION**.

<img src="https://github.com/Admicail/Ecommify_Database_Desing/blob/main/docs/Evidences/screenshots/Document_CATALOG_PRODUCTS_COLECCTION.jpg" width="300">




# ⚡ Estrategia Maestra de Optimización de Motores de Bases de Datos - Ecommify

Este módulo maestro consolida la ejecución técnica, las auditorías de hardware y los resultados cuantitativos logrados al intervenir la infraestructura políglota de **Ecommify**. La estrategia erradica los cuellos de botella mediante análisis de planes de ejecución en tiempo real, indexación avanzada, segmentación física y políticas distribuidas tolerantes a fallos.

---

## 1. Módulo Relacional Transaccional: PostgreSQL (Supabase)

La optimización sobre las tablas relacionales normalizadas (3FN) con más de 100,000 registros erradicó los costosos escaneos secuenciales (`Seq Scan`) mediante auditorías con la herramienta `EXPLAIN (ANALYZE, BUFFERS)`.

###  Índices Especializados Desplegados
*   **B-Tree sobre Llaves Foráneas**: Se crearon índices clásicos en `order_id` y `product_id` dentro de los detalles. Al no indexarse automáticamente en PostgreSQL, su ausencia causaba lecturas globales al realizar uniones (`JOIN`).
*   **Índices Parciales Condicionales**: Se aisló la baja cardinalidad desbalanceada de los estados operativos de bodega (`WHERE order_status = 'created'`). Esto redujo el tamaño del índice en disco a menos de 16 KB, evitando almacenar el 97% de los datos históricos ociosos.
*   **Índices GIN para Datos Complejos**: Se implementó un índice invertido con la clase de operadores `jsonb_path_ops` sobre el campo objeto `payment_details` (JSONB), acelerando las consultas de contención (`@>`) de la pasarela de pagos.
*   **Índice Compuesto Funcional**: Pre-calcula y almacena físicamente en el árbol los límites de las líneas de tiempo temporales (`lower` y `upper` sobre tipos `tsrange`), resolviendo indicadores logísticos mediante un **Index-Only Scan** instantáneo.

###  Matriz Cuantitativa de Impacto (Línea Base vs. Optimizado)
*   **Detalle de Orden (Confirmación de Compra)**: El costo lineal mutó a un `Index Scan` directo, resolviendo el flujo en **14.18 ms** con un ahorro del 85% en memoria.
*   **Pasarela de Pago (Auditoría JSONB)**: El escaneo secuencial cayó de 2,768.1 ms a **0.22 ms** (Reducción del **99.99%**), bajando la lectura en caché de 5,019 bloques a solo 4 bloques.
*   **Control Financiero (Órdenes Pendientes)**: Pasó de 1,146.2 ms a **10.52 ms** (Reducción del **99.08%**), escaneando solo 6 bloques en lugar de 1,715.
*   **Indicador Logístico (Tiempos de Entrega)**: Al actuar como una caché de cálculo matemático, redujo el tiempo de procesamiento total en un **80.45%** (bajando de 208.4 ms a 40.67 ms).

###  Aplicación de Particionamiento Declarativo
Para blindar la mantenibilidad a largo plazo de la tabla central de órdenes (`ecommify_orders`), se aplicó una estrategia de segmentación temporal **`PARTITION BY RANGE`** con una granularidad trimestral y un nodo de contingencia **`DEFAULT`**. 
*   **Resultado**: Al ejecutar búsquedas por ventanas de fechas, PostgreSQL aplica el mecanismo **`Partition Pruning`**, descartando de manera automática las particiones ociosas y consultando únicamente el segmento físico del trimestre correspondiente, liberando ciclos de CPU.

---

##  2. Módulo Documental Interactivo: MongoDB (Atlas & Compass)

La intervención sobre el clúster NoSQL de alta disponibilidad atacó el patrón de acceso principal del frontend: la navegación del catálogo enriquecido con visualización prioritaria de ofertas.

### Índices No Relacionales Desplegados
*   **Índice Compuesto ESR**: Diseñado bajo la estructura estricta `{ category: 1, "active_promotions.discount": -1 }`. Sigue la regla *Equality, Sort, Range*, permitiendo al motor filtrar primero por el criterio exacto de la categoría y entregar los documentos pre-ordenados físicamente por nivel de descuento.
*   **Índices Parciales y de Texto**: Diseñados para indexar subconjuntos de datos (campañas de marketing activas) y dar soporte al motor de búsqueda avanzada de cara al cliente por palabras clave (*Full-Text Search*).

### Refinamiento  del Aggregation Pipeline
Se estructuró un pipeline optimizado de **5 etapas** de izquierda a derecha:
1.  **Stage 1 (`$match`)**: Ejecuta un filtrado temprano aprovechando el prefijo del índice para realizar una **Consulta Dirigida (Targeted Query)** enviada directo al Shard físico correspondiente, eliminando el tráfico basura en la red del clúster (*Scatter-Gather*).
2.  **Stage 2 (`$sort`)**: Aprovecha el ordenamiento indexado pre-cubierto físicamente en memoria caché.
3.  **Stage 3 (`$project`)**: Remueve tempranamente el subdocumento pesado de logística `attributes` (pesos y dimensiones de Olist), disminuyendo drásticamente los bytes concurrentes que viajan por el pipeline.
4.  **Stage 4 (`$addFields`)**: Inyecta la transformación analítica de etiquetas de promoción únicamente sobre los registros finales.
5.  **Stage 5 (`$limit`)**: Ejecuta la paginación arquitectural acotada a las primeras 20 tarjetas de la página web.

### Red de Seguridad de Hardware (`allowDiskUse`)
Se inyectó globalmente la propiedad de configuración **`{ allowDiskUse: true }`** como un mecanismo de resiliencia (*Fail-Safe*). Si una etapa pesada (como agrupaciones masivas concurrentes en un Black Friday) supera el límite estricto de 100 MB de RAM de MongoDB, el motor realiza una conmutación por error activando una paginación temporal en las unidades sólidas SSD del clúster, garantizando la **alta disponibilidad** de la tienda web (la página cargará pase lo que pase).

### Matriz Cuantitativa de Impacto NoSQL (`executionStats`)
*   **Tiempo de Ejecución en CPU**: Se redujo de 6 milisegundos a **0 milisegundos absolutos**.
*   **Eficiencia de Lectura (I/O)**: Cayó drásticamente de 3,029 documentos físicos examinados a **exactamente 20 registros** (coincidentes con el tamaño de la página del frontend).
*   **Llaves de Índice Evaluadas**: Bajó de 3,029 a solo **20 llaves**.
*   **Uso de Memoria RAM**: La alerta crítica de rendimiento *"Is sorted in memory"* desapareció por completo al transformarse en un ordenamiento cubierto físicamente por el índice.

---

##  3. Instrucciones de Reproducción del Entorno de Auditoría

1.  **PostgreSQL**: Cargar los scripts de esquemas, índices y funciones provistos en la carpeta corporativa e invocar las sentencias anteponiendo la instrucción `EXPLAIN (ANALYZE, BUFFERS)` en Supabase.
2.  **MongoDB**: Conectarse al clúster `ClusterOlistKaggle` desde MongoDB Compass, cargar el JSON de agregación optimizado en la pestaña **Aggregations**, habilitar la propiedad *Allow Disk Use* en la pestaña de opciones y ejecutar el comando **`Explain`** para validar la desaparición visual del bloque de bloqueo `SORT`.



