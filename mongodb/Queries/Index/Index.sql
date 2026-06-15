db.CATALOG_PRODUCTS_COLLECTION.createIndex({ 
  category: 1, 
  "active_promotions.discount": -1 
})