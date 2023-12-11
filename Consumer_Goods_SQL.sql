/* 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.*/
SELECT *FROM dim_customer;
SELECT DISTINCT(market) FROM dim_customer WHERE customer = 'Atliq Exclusive' AND region = 'APAC';
/* 2. What is the percentage of unique product increase in 2021 vs. 2020?
 The final output contains these fields, unique_products_2020, unique_products_2021 */
SELECT * FROM fact_gross_price;
SELECT X.A as unique_products_2020,Y.B as unique_products_2021, (Y.B-X.A)*100/X.A AS percent_change
FROM 
(
(SELECT COUNT(DISTINCT(product_code)) AS A FROM fact_gross_price WHERE fiscal_year=2020) X,
(SELECT COUNT(DISTINCT(product_code)) AS B FROM fact_gross_price WHERE fiscal_year=2021) Y );
/* OR */
with cte1 as (select 
count(distinct (product_code)) as unique_product_2020
from fact_sales_monthly
where fiscal_year = 2020),
cte2 as (select
count(distinct(product_code)) as unique_product_2021
from fact_sales_monthly
where fiscal_year = 2021)

select unique_product_2020,
	   unique_product_2021,
       round((unique_product_2021-
       unique_product_2020)*100/
       unique_product_2020,2) as
       percentage_change
from cte1
join cte2;
/* 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
The final output contains 2 fields, segment, product_count */
SELECT *FROM dim_product;
SELECT segment, COUNT(DISTINCT(product_code))
FROM dim_product
GROUP BY segment
ORDER BY 2 DESC;
/* 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?
The final output contains these fields, segment, product_count_2020, product_count_2021, difference */
WITH cte1 AS(
SELECT p.segment,COUNT(DISTINCT(p.product_code)) AS product_count_2020
FROM dim_product p
JOIN fact_gross_price fp ON p.product_code=fp.product_code
WHERE fiscal_year=2020
GROUP BY p.segment
),
cte2 AS (
SELECT p.segment,COUNT(DISTINCT(p.product_code)) as product_count_2021
FROM dim_product p
JOIN fact_gross_price fp ON p.product_code=fp.product_code
WHERE fiscal_year=2020
GROUP BY p.segment)
SELECT cte1.segment,cte1.product_count_2020,cte2.product_count_2021,(cte2.product_count_2021-cte1.product_count_2020)*100/cte1.product_count_2020 AS diff
FROM cte1,cte2 
ORDER BY diff DESC;
/*5. Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields, product_code, product, manufacturing_cost*/
SELECT p.product_code,p.product,fmc.manufacturing_cost
FROM dim_product p
JOIN fact_manufacturing_cost fmc ON p.product_code=fmc.product_code
WHERE manufacturing_cost IN (( SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost), ( SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost))
order by manufacturing_cost desc;
/*6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.
The final output contains these fields, customer_code, customer, average_discount_percentage*/
SELECT c.customer_code,c.customer,AVG(fpnd.pre_invoice_discount_pct) as average_discount_percentage
FROM dim_customer c
JOIN fact_pre_invoice_deductions fpnd ON c.customer_code=fpnd.customer_code
WHERE fpnd.fiscal_year=2021 AND c.market='India'
GROUP BY c.customer_code,c.customer
ORDER BY 3 desc
LIMIT 5;
/*7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . This analysis helps to get an idea of low and high-performing months and take strategic decisions.
The final report contains these columns: Month, Year, Gross sales Amount*/
SELECT * FROM fact_gross_price;
SELECT * FROM dim_customer;
SELECT * FROM fact_sales_monthly;
SELECT DISTINCT(EXTRACT(MONTH FROM fsm.date)) AS Month, EXTRACT(YEAR FROM fsm.date) as YEAR, SUM(fgp.gross_price*fsm.sold_quantity) as Gross_sales_Amount 
FROM fact_sales_monthly fsm
JOIN fact_gross_price fgp ON fsm.product_code=fgp.product_code
JOIN dim_customer c ON fsm.customer_code=c.customer_code
WHERE c.customer='Atliq Exclusive'
GROUP BY 1,2
ORDER BY 2;
/* 8. In which quarter of 2020, got the maximum total_sold_quantity?
The final output contains these fields sorted by the total_sold_quantity, Quarter, total_sold_quantity */
SELECT 
	CASE 
        WHEN MONTH(fsm.date) IN (9,10,11) THEN 'Q1' 
        WHEN MONTH(fsm.date) IN (12,1,2) THEN 'Q2' 
        WHEN MONTH(fsm.date) IN (3,4,5) THEN 'Q3' 
        ELSE 'Q4' 
    END AS QUARTER , 
    SUM(fsm.sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly fsm
WHERE fsm.fiscal_year=2020
GROUP BY 1
ORDER BY 2 DESC;
/* 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
The final output contains these fields, channel, gross_sales_mln, percentage */
WITH cte2 AS ( 
SELECT channel,SUM(gross_price*sold_quantity) AS gross_sales_mln
FROM dim_customer c
JOIN fact_sales_monthly fsm ON c.customer_code=fsm.customer_code
JOIN fact_gross_price fgp ON fsm.product_code=fgp.product_code
WHERE fsm.fiscal_year=2021
GROUP BY c.channel
ORDER BY 2 DESC)
SELECT channel,gross_sales_mln,Round(gross_sales_mln*100/total,2) AS percentage FROM
(
(SELECT SUM(gross_sales_mln) AS total FROM cte2) A,
(SELECT * FROM cte2) B
) ;
/* 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
The final output contains these fields, division, product_code, product, total_sold_quantity, rank_order*/
WITH my_cte1 AS (
SELECT p.division,p.product_code,p.product,SUM(fsm.sold_quantity) AS s,
ROW_NUMBER() OVER(PARTITION BY p.division ORDER BY SUM(fsm.sold_quantity) DESC) AS r
FROM dim_product p
JOIN fact_sales_monthly fsm ON p.product_code=fsm.product_code
WHERE fsm.fiscal_year=2021
GROUP BY 1,2,3
ORDER BY 4 DESC)
SELECT my_cte1.division,my_cte1.product_code,my_cte1.product,my_cte1.s,my_cte1.r
FROM my_cte1
WHERE r<=3;


