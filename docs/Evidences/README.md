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

El negocio orquesta el ciclo de vida de la información a través de 5 flujos lógicos controlados desde la capa de la aplicación:
