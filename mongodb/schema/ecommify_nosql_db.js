// =========================================================
// Proyecto Ecommify - MongoDB Schema
// Módulo documental: catálogo, promociones, sesiones y carritos
// =========================================================

use DataBaseOlistKaggle;

// Colección de catálogo de productos.
db.createCollection("catalog_products_collection", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["_id", "category"],
      properties: {
        _id: { bsonType: "string" },
        category: { bsonType: "string" },
        product_name: { bsonType: ["string", "null"] },
        active_promotions: { bsonType: "object" },
        attributes: { bsonType: "object" },
        media: { bsonType: "array" },
        reviews_summary: { bsonType: "object" },
        postgres_product_id: { bsonType: ["string", "null"] }
      }
    }
  }
});

// Colección de sesiones y carritos activos.
db.createCollection("customer_sessions_collection", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["_id", "customer_id", "active_cart"],
      properties: {
        _id: { bsonType: "string" },
        customer_id: { bsonType: "string" },
        last_activity: { bsonType: ["date", "null"] },
        active_cart: { bsonType: "object" },
        expires_at: { bsonType: ["date", "null"] }
      }
    }
  }
});

// Índices principales.
db.catalog_products_collection.createIndex({ category: 1 });
db.catalog_products_collection.createIndex({ "reviews_summary.avg_score": -1 });
db.catalog_products_collection.createIndex({ "active_promotions.is_promo": 1 });
db.catalog_products_collection.createIndex({ "active_promotions.valid_until": 1 });
db.catalog_products_collection.createIndex({ postgres_product_id: 1 });

db.customer_sessions_collection.createIndex({ customer_id: 1 });
db.customer_sessions_collection.createIndex({ last_activity: -1 });
db.customer_sessions_collection.createIndex({ expires_at: 1 }, { expireAfterSeconds: 0 });
