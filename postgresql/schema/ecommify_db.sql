CREATE DATABASE ecommify;

SET search_path TO ecommify, public;
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS btree_gin;

CREATE TYPE address_type AS (
    zip_code VARCHAR(20),
    city VARCHAR(100),
    state VARCHAR(10)
);

CREATE TABLE ecommify_customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_address address_type
);

CREATE TABLE ecommify_geolocation (
    geolocation_zip_code_prefix VARCHAR(20) PRIMARY KEY,
    geolocation_point geometry(Point, 4326),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(10)
);

CREATE INDEX idx_geo_point
ON ecommify_geolocation
USING GIST (geolocation_point);

CREATE TABLE ecommify_products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_specifications JSONB,
    product_photos TEXT[]
);

CREATE INDEX idx_products_specifications
ON ecommify_products
USING GIN (product_specifications);

CREATE INDEX idx_products_photos
ON ecommify_products
USING GIN (product_photos);



CREATE TABLE ecommify_sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_address address_type
);



CREATE TABLE ecommify_orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(30),
    order_logistics_timeline TSRANGE,
    order_estimated_delivery TIMESTAMP,

    CONSTRAINT fk_orders_customer
    FOREIGN KEY (customer_id)
    REFERENCES ecommify_customers(customer_id)
);


CREATE TABLE ecommify_order_details (
    order_item_id INT PRIMARY KEY,
    order_id VARCHAR(50),
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    price NUMERIC(10,2),
    freight_value NUMERIC(10,2),
    payment_details JSONB,

    CONSTRAINT fk_order_details_order
    FOREIGN KEY (order_id)
    REFERENCES ecommify_orders(order_id),

    CONSTRAINT fk_order_details_product
    FOREIGN KEY (product_id)
    REFERENCES ecommify_products(product_id),

    CONSTRAINT fk_order_details_seller
    FOREIGN KEY (seller_id)
    REFERENCES ecommify_sellers(seller_id)
);

CREATE INDEX idx_order_details_payment
ON ecommify_order_details
USING GIN (payment_details);



