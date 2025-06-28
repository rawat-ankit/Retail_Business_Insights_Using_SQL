SELECT feedback_category,
ROUND(AVG(rating),2) AS avg_rating
FROM feedback
GROUP BY feedback_category



SELECT 
	ROUND(100.0*(SUM(CASE
		WHEN delivery_time_minutes <=0 THEN 1 ELSE 0 END))/COUNT(*),2) AS Timely_delivered_percentage,
	ROUND(100.0*(SUM(CASE
		WHEN delivery_time_minutes >0 THEN 1 ELSE 0 END))/COUNT(*),2) AS late_delivered_percentage
FROM delivery_performance


SELECT p.category,COUNT(o.order_id) AS total_orders, SUM(o.quantity*o.unit_price) AS total_Sales
FROM products p
INNER JOIN order_items o
ON p.product_id = o.product_id
GROUP BY p.category
ORDER BY total_sales DESC,total_orders DESC


WITH TOP_CUSTOMERS AS
(
SELECT c.customer_id, c.customer_name, SUM(quantity*unit_price) AS total_order_value,
ROW_NUMBER() OVER( ORDER BY SUM(quantity*unit_price)DESC)
FROM Order_items i
INNER JOIN orders o
ON i.order_id = o.order_id
INNER JOIN customers c
ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_order_value DESC
)
SELECT customer_id, customer_name,
CASE
    WHEN row_number BETWEEN 1 AND ((SELECT COUNT(*) FROM TOP_CUSTOMERS )* 0.2) THEN 'High Value'
	WHEN row_number BETWEEN ((SELECT COUNT(*) FROM TOP_CUSTOMERS )* 0.2) AND ((SELECT COUNT(*) FROM TOP_CUSTOMERS )* 0.5) THEN 'Medium Value'
	ELSE 'Low Value'
	END AS segment
FROM top_customers








SELECT * 
FROM order_items oi
INNER JOIN inventory i
ON oi.product_id = i.product_id
INNER JOIN products p
ON p.product_id = i.product_id
INNER JOIN orders o
ON oi.order_id = o.order_id

WITH i AS (
    SELECT 
        product_id,
        (stock_received - damaged_stock) AS current_stock,
        ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY date DESC) AS rn
    FROM inventory
)
SELECT i.product_id, p.product_name, p.brand, i.current_stock, p.min_stock_level
FROM  i
INNER JOIN products p
ON i.product_id = p.product_id
WHERE i.rn = 1 AND i.current_stock<p.min_stock_level
ORDER BY p.product_name


SELECT 
  CASE 
    WHEN EXTRACT(HOUR FROM promised_time) BETWEEN 6 AND 11 THEN 'Morning'
    WHEN EXTRACT(HOUR FROM promised_time) BETWEEN 12 AND 17 THEN 'Afternoon'
	WHEN EXTRACT(HOUR FROM promised_time) BETWEEN 18 AND 23 THEN 'Evening'
    ELSE 'Mid-Night'
  END AS time_period,

  ROUND(100.0 * SUM(CASE WHEN delivery_time_minutes <= 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS timely_percentage,
  ROUND(100.0 * SUM(CASE WHEN delivery_time_minutes > 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS late_percentage

FROM delivery_performance
GROUP BY time_period
ORDER BY time_period



WITH customer_ordering_patterns AS (
  SELECT 
    c.customer_id,
    c.customer_name,
    c.email,
    COUNT(DISTINCT DATE_TRUNC('month', o.order_date)) AS active_months,
    MIN(o.order_date) AS first_order_date,
    MAX(o.order_date) AS last_order_date,
    SUM(oi.quantity * oi.unit_price) AS lifetime_spend,
    COUNT(DISTINCT o.order_id) AS total_orders
  FROM 
    customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
  GROUP BY 
    c.customer_id, c.customer_name, c.email
),

customer_activity AS (
  SELECT 
    *,
    (EXTRACT(YEAR FROM last_order_date) * 12 + EXTRACT(MONTH FROM last_order_date)) - 
    (EXTRACT(YEAR FROM first_order_date) * 12 + EXTRACT(MONTH FROM first_order_date)) + 1 
      AS observed_months,
    EXTRACT(DAY FROM (CURRENT_DATE - last_order_date)) AS days_inactive
  FROM 
    customer_ordering_patterns
  WHERE 
    active_months >= CEILING(
      ((EXTRACT(YEAR FROM last_order_date) * 12 + EXTRACT(MONTH FROM last_order_date)) - 
      (EXTRACT(YEAR FROM first_order_date) * 12 + EXTRACT(MONTH FROM first_order_date)) + 1
    ) / 2)
    AND last_order_date < CURRENT_DATE - INTERVAL '90 days'
)

SELECT 
  customer_id,
  customer_name,
  email,
  first_order_date,
  last_order_date,
  lifetime_spend,
  total_orders,
  active_months,
  ROUND(lifetime_spend / NULLIF(active_months, 0), 2) AS avg_monthly_spend,
  days_inactive
FROM 
  customer_activity
ORDER BY 
  days_inactive DESC