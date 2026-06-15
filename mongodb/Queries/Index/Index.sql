db.CATALOG_PRODUCTS_COLLECTION.createIndex({ 
  category: 1, 
  "active_promotions.discount": -1 
})

// Índices principales.
db.catalog_products_collection.createIndex({ category: 1 });
db.catalog_products_collection.createIndex({ "reviews_summary.avg_score": -1 });
db.catalog_products_collection.createIndex({ "active_promotions.is_promo": 1 });
db.catalog_products_collection.createIndex({ "active_promotions.valid_until": 1 });
db.catalog_products_collection.createIndex({ postgres_product_id: 1 });

db.customer_sessions_collection.createIndex({ customer_id: 1 });
db.customer_sessions_collection.createIndex({ last_activity: -1 });
db.customer_sessions_collection.createIndex({ expires_at: 1 }, { expireAfterSeconds: 0 });
