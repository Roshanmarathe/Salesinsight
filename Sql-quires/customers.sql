create database business_case_study;
use  business_case_study;
source C:/Users/rosha/OneDrive/Desktop/powerbi_sql/customers.sql; -- customers table
source C:/Users/rosha/OneDrive/Desktop/powerbi_sql/order_items.sql;-- order_items table
source C:/Users/rosha/OneDrive/Desktop/powerbi_sql/orders.sql;-- orders table
source C:/Users/rosha/OneDrive/Desktop/powerbi_sql/products.sql;-- products table
source C:/Users\rosha/OneDrive/Desktop/powerbi_sql/shipping.sql;-- shipping table

show tables;
select * from cutomers;
select * from order_items;
select * from orders;
select * from products;
select * from shipping;
--------------------------------------------------
-- 🔹 1. DATA EXPLORATION
--------------------------------------------------

-- Total Orders
SELECT COUNT(*) AS total_orders FROM orders;

-- Total Customers
SELECT COUNT(*) AS total_customers FROM customers;

-- Total Products
SELECT COUNT(*) AS total_products FROM products;

-- Most Frequently Ordered Products
SELECT 
    p.product_name,
    SUM(oi.quantity) AS total_quantity
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_quantity DESC;

-- Total Revenue
SELECT 
    SUM(oi.quantity * p.unit_price * (1 - oi.discount)) AS total_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id;

-- Average Order Value (AOV)
SELECT 
    SUM(oi.quantity * p.unit_price * (1 - oi.discount)) 
    / COUNT(DISTINCT o.order_id) AS AOV
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id;

-- Revenue Over Time (Monthly)
SELECT 
    YEAR(o.order_date) AS year,
    MONTH(o.order_date) AS month,
    SUM(oi.quantity * p.unit_price * (1 - oi.discount)) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY YEAR(o.order_date), MONTH(o.order_date)
ORDER BY year, month;

-- Top 5 States by Revenue
SELECT TOP 5
    c.state,
    SUM(oi.quantity * p.unit_price * (1 - oi.discount)) AS revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY c.state
ORDER BY revenue DESC;


--------------------------------------------------
-- 🔹 2. CUSTOMER ANALYSIS
--------------------------------------------------

-- New vs Returning Customers
SELECT 
    customer_id,
    COUNT(order_id) AS total_orders,
    CASE 
        WHEN COUNT(order_id) = 1 THEN 'New'
        ELSE 'Returning'
    END AS customer_type
FROM orders
GROUP BY customer_id;

-- Top 10 Customers by Spending
SELECT TOP 10
    c.customer_id,
    c.first_name,
    SUM(oi.quantity * p.unit_price * (1 - oi.discount)) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY c.customer_id, c.first_name
ORDER BY total_spent DESC;

-- Churn Customers (Inactive > 90 days)
SELECT 
    customer_id,
    MAX(order_date) AS last_order_date,
    DATEDIFF(DAY, MAX(order_date), GETDATE()) AS days_inactive
FROM orders
GROUP BY customer_id
HAVING DATEDIFF(DAY, MAX(order_date), GETDATE()) > 90;


--------------------------------------------------
-- 🔹 3. PRODUCT ANALYSIS
--------------------------------------------------

-- Best Selling Products
SELECT TOP 10
    p.product_name,
    SUM(oi.quantity) AS total_sold
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_sold DESC;

-- Category-wise Revenue
SELECT 
    p.category,
    SUM(oi.quantity * p.unit_price * (1 - oi.discount)) AS revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category;

-- Profit Analysis
SELECT 
    p.product_name,
    SUM((p.unit_price - p.cost_price) * oi.quantity) AS profit
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY profit DESC;

-- Underperforming Products
SELECT 
    p.product_name,
    SUM(oi.quantity) AS total_sales
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_name
HAVING SUM(oi.quantity) < 10;


--------------------------------------------------
-- 🔹 4. SHIPPING ANALYSIS
--------------------------------------------------

-- Average Shipping Time
SELECT 
    AVG(DATEDIFF(DAY, o.order_date, s.shipping_date)) AS avg_shipping_days
FROM orders o
JOIN shipping s ON o.order_id = s.order_id;

-- Shipping Cost Analysis
SELECT 
    AVG(shipping_cost) AS avg_shipping_cost
FROM shipping;

-- Delayed Shipments
SELECT 
    COUNT(*) AS delayed_orders
FROM shipping
WHERE shipping_status = 'Delayed';


--------------------------------------------------
-- 🔹 5. ADVANCED SQL
--------------------------------------------------

-- Customer Ranking
SELECT 
    customer_id,
    SUM(oi.quantity * p.unit_price) AS total_spent,
    RANK() OVER (ORDER BY SUM(oi.quantity * p.unit_price) DESC) AS rank
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY customer_id;

-- Previous Order Date (LAG)
SELECT 
    customer_id,
    order_date,
    LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order
FROM orders;


--------------------------------------------------

--------------------------------------------------

-- 1. Customer Lifetime Value (CLV)
SELECT 
    c.customer_id,
    c.first_name,
    SUM(oi.quantity * p.unit_price) AS lifetime_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY c.customer_id, c.first_name
ORDER BY lifetime_value DESC;


-- 2. Monthly Growth Rate (Revenue Growth)
SELECT 
    YEAR(o.order_date) AS year,
    MONTH(o.order_date) AS month,
    SUM(oi.quantity * p.unit_price) AS revenue,
    LAG(SUM(oi.quantity * p.unit_price)) OVER (
        ORDER BY YEAR(o.order_date), MONTH(o.order_date)
    ) AS prev_month_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY YEAR(o.order_date), MONTH(o.order_date);


-- 3. Top Payment Method
SELECT 
    payment_method,
    COUNT(*) AS total_orders
FROM orders
GROUP BY payment_method
ORDER BY total_orders DESC;


-- 4. Discount Impact on Sales
SELECT 
    CASE 
        WHEN discount = 0 THEN 'No Discount'
        ELSE 'Discount Applied'
    END AS discount_type,
    SUM(quantity) AS total_sales
FROM order_items
GROUP BY 
    CASE 
        WHEN discount = 0 THEN 'No Discount'
        ELSE 'Discount Applied'
    END;
