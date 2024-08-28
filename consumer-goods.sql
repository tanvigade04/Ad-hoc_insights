-- AD-HOC INSIGHTS REQUESTS

-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
SELECT * FROM dim_customer;
SELECT market FROM dim_customer
WHERE customer = 'Atliq Exclusive' AND region = 'APAC';

SELECT * FROM dim_product;
SELECT * FROM fact_gross_price;
SELECT * FROM fact_manufacturing_cost;
SELECT * FROM fact_pre_invoice_deductions;
SELECT * FROM fact_sales_monthly;

-- 2. What is the percentage of unique product increase in 2021 vs. 2020?
WITH fy20 AS (
        SELECT COUNT(DISTINCT(product_code)) AS up_20 FROM fact_sales_monthly
            WHERE fiscal_year = 2020),
            
    fy21 AS (
        SELECT COUNT(DISTINCT(product_code)) AS up_21 FROM fact_sales_monthly
            WHERE fiscal_year = 2021)
            
SELECT fy20.up_20 AS unique_products_2020,
    fy21.up_21 AS unique_products_2021,
    CONCAT(ROUND((fy21.up_21-fy20.up_20) * 100/fy20.up_20, 2), ' %') as percentage_chg
    FROM fy20, fy21;

-- 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
SELECT product,COUNT(DISTINCT product), segment FROM dim_product
GROUP BY product, segment 
Order BY product DESC;

-- 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?
WITH fy20 AS(
        SELECT segment, COUNT(DISTINCT(fm.product_code)) AS seg20 FROM fact_sales_monthly fm
            JOIN dim_product dp
            ON fm.product_code = dp.product_code
            WHERE fiscal_year = 2020
            GROUP BY dp.segment),
fy21 AS(
        SELECT segment, COUNT(DISTINCT(fm.product_code)) AS seg21 FROM fact_sales_monthly fm
            JOIN dim_product dp
            ON fm.product_code = dp.product_code
            WHERE fiscal_year = 2021
            GROUP BY dp.segment)
            
SELECT fy20.segment, seg20 AS product_count_2020, seg21 AS product_count_2021, seg21-seg20 AS difference FROM fy20
    JOIN fy21
    ON fy20.segment = fy21.segment
    ORDER BY difference DESC;

-- 5. Get the products that have the highest and lowest manufacturing costs.
SELECT dim_product.product, min(fact_manufacturing_cost.manufacturing_cost) AS lowest_cost, max(fact_manufacturing_cost.manufacturing_cost) As highest_cost
FROM dim_product
JOIN fact_manufacturing_cost ON dim_product.product_code = fact_manufacturing_cost.product_code
GROUP BY dim_product.product;

-- 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021
 -- and in the Indian market.
 SELECT * FROM fact_pre_invoice_deductions;
 SELECT dim_customer.customer, avg(fact_pre_invoice_deductions.pre_invoice_discount_pct)
 FROM dim_customer
 JOIN fact_pre_invoice_deductions ON dim_customer.customer_code = fact_pre_invoice_deductions.customer_code
 GROUP BY dim_customer.customer
 ORDER BY dim_customer.customer DESC
 LIMIT 5;
 
 -- 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month.
 SELECT SUM(fact_sales_monthly.sold_quantity * fact_gross_price.gross_price)  AS gross_sales_amount,dim_customer.customer, MONTHNAME(date) AS month,
 YEAR(fact_sales_monthly.date) AS year FROM fact_sales_monthly
 JOIN fact_gross_price ON fact_sales_monthly.product_code = fact_gross_price.product_code
 JOIN dim_customer ON fact_sales_monthly.customer_code = dim_customer.customer_code
 WHERE dim_customer.customer = 'Atliq Exclusive' 
 GROUP BY fact_sales_monthly.date,dim_customer.customer;
 
 -- 8. In which quarter of 2020, got the maximum total_sold_quantity?
SELECT QUARTER(date) AS Quarter, max(sold_quantity) AS total_sold_quantity FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY date;

-- 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
WITH gross_sale_table as (
        SELECT customer_code, gross_price * sold_quantity AS gross_sales_mln FROM fact_gross_price fp
            JOIN fact_sales_monthly fm
            ON fp.product_code = fm.product_code AND fp.fiscal_year = fm.fiscal_year
            WHERE fp.fiscal_year = 2021),

    channel_table AS (
        SELECT channel, ROUND(SUM(gross_sales_mln / 1000000), 3) AS gross_sales_mln FROM gross_sale_table gt
            JOIN dim_customer dc
            ON gt.customer_code = dc.customer_code
            GROUP BY channel),

    total_sum AS (
        SELECT SUM(gross_sales_mln) as SUM_ FROM channel_table)

SELECT ct.*,
   CONCAT(ROUND(ct.gross_sales_mln * 100 / ts.SUM_, 2), ' %') AS percentage
   FROM channel_table ct, total_sum ts
   ORDER BY percentage DESC;

-- 10.Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
SELECT dim_product.product, dim_product.division, max(sold_quantity) AS total_sold_quantity FROM fact_sales_monthly
JOIN dim_product ON fact_sales_monthly.product_code = dim_product.product_code
WHERE fact_sales_monthly.fiscal_year = 2021
GROUP BY dim_product.product, dim_product.division
ORDER BY dim_product.product DESC
LIMIT 3;