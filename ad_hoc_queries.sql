-- Request 1

SELECT DISTINCT(market) FROM dim_customer WHERE customer = "Atliq Exclusive" AND region = "APAC";

-- request 2

WITH FY2020 AS(
SELECT  
COUNT(DISTINCT(product)) AS unique_product_2020
FROM fact_sales_monthly s
JOIN dim_product p
ON s.product_code = p.product_code
WHERE fiscal_year = 2020),
FY2021 AS (
SELECT
COUNT(DISTINCT(product)) AS unique_product_2021
FROM fact_sales_monthly s
JOIN dim_product p
ON s.product_code = p.product_code
WHERE fiscal_year = 2021)

SELECT *,
((unique_product_2021 - unique_product_2020) / unique_product_2020)*100 AS percentage_chg
FROM FY2020 JOIN FY2021;

-- request 3

SELECT 
segment,
COUNT(DISTINCT(product)) AS product_count
FROM dim_product 
GROUP BY segment
ORDER BY product_count DESC;

-- request 4

WITH FY2020 AS (
SELECT
segment,
COUNT(DISTINCT(product)) AS product_count_2020
FROM fact_sales_monthly s
JOIN dim_product p
ON s.product_code = p.product_code
WHERE fiscal_year = 2020
GROUP BY segment),
FY2021 AS (
SELECT
segment,
COUNT(DISTINCT(product)) AS product_count_2021
FROM fact_sales_monthly s
JOIN dim_product p
ON s.product_code = p.product_code
WHERE fiscal_year = 2021
GROUP BY segment),
segment as (SELECT distinct(segment) FROM dim_product)
SELECT *,
product_count_2021 - product_count_2020 AS diff_21vs20
FROM FY2020 x
JOIN FY2021 y
USING (segment);

-- request 5

(SELECT p.product_code,
product,
mc.manufacturing_cost
FROM dim_product p
JOIN fact_manufacturing_cost mc
USING(product_code)
ORDER BY manufacturing_cost ASC
LIMIT 1)

UNION
 
(SELECT p.product_code,
product,
mc.manufacturing_cost
FROM dim_product p
JOIN fact_manufacturing_cost mc
USING(product_code)
ORDER BY manufacturing_cost DESC
LIMIT 1);

-- request 6

SELECT pre.customer_code,
c.customer,
pre_invoice_discount_pct
FROM fact_pre_invoice_deductions pre
JOIN dim_customer c
USING (customer_code)
WHERE fiscal_year = 2021 
AND pre_invoice_discount_pct >= (SELECT AVG(pre_invoice_discount_pct) FROM fact_pre_invoice_deductions)
AND market = "india"
ORDER BY pre_invoice_discount_pct DESC
LIMIT 5;

-- request 7

SELECT 
MONTH(s.date) AS month_num,
s.fiscal_year,
SUM((gross_price * sold_quantity)) AS gross_sales_amount
FROM fact_sales_monthly s
JOIN dim_customer c
ON 
  c.customer_code = s.customer_code
JOIN fact_gross_price g
ON
  g.product_code = s.product_code AND
  g.fiscal_year = s.fiscal_year
WHERE customer = "Atliq Exclusive"
GROUP BY s.date;

-- request 8

SELECT 
CASE
	WHEN MONTH(s.date) IN (9,10,11) THEN "Q1"
	WHEN MONTH(s.date) IN (12,1,2) THEN "Q2"
	WHEN MONTH(s.date) IN (3,4,5) THEN "Q3"
	WHEN MONTH(s.date) IN (6,7,8) THEN "Q4"
END AS qtr,
s.fiscal_year,
SUM((gross_price * sold_quantity)) AS gross_sales_amount
FROM fact_sales_monthly s
JOIN dim_customer c
ON 
  c.customer_code = s.customer_code
JOIN fact_gross_price g
ON
  g.product_code = s.product_code AND
  g.fiscal_year = s.fiscal_year
WHERE s.fiscal_year = 2020
GROUP BY qtr
ORDER BY gross_sales_amount DESC;

-- request 9

WITH CTE1 AS (
SELECT
c.channel,
ROUND(SUM((gross_price * sold_quantity)/1000000), 2) AS gross_sales_mln
FROM fact_sales_monthly s
JOIN dim_customer c
ON 
  c.customer_code = s.customer_code
JOIN fact_gross_price g
ON
  g.product_code = s.product_code AND
  g.fiscal_year = s.fiscal_year
GROUP BY c.channel
ORDER BY gross_sales_mln DESC)

SELECT *,
gross_sales_mln/SUM(gross_sales_mln) OVER() AS percentage_chg
FROM CTE1;

-- request 10

WITH CTE1 AS (
SELECT 
p.division,
s.product_code,
p.product,
SUM(sold_quantity) AS total_sold_qty,
DENSE_RANK() OVER (PARTITION BY division ORDER BY SUM(sold_quantity) desc) AS rank_order
FROM fact_sales_monthly s
JOIN dim_product p
USING(product_code)
WHERE fiscal_year = 2021
GROUP BY product)
SELECT *
FROM CTE1
WHERE rank_order <= 3;