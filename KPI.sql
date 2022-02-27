/*
 *
 * *****************************************
 * ANALYSIS WITH SCALE MODEL CARS DATABASE *
 * *****************************************
 *
 * stores.db is a sales records database for scale model cars. In
 * this analysis, key performance indicators (KPIs) are extracted
 * in order to shape business decision-making moving forward. The
 * following questions are addressed:
 *
 * 1. Which products should we order more of or less of?
 * 2. How should we tailor marketing and communication strategies
 *    to customer behaviors?
 * 3. How much can we spend on acquiring new customers?
 *
 *
 * *******************
 * Tables (8 in total)
 * *******************
 *
 * customers: customer data
 * employees: all employee information
 * offices: sales office information
 * orders: customers' sales orders
 * orderDetails: sales order line for each sales order
 * payments: customers' payment records
 * products: a list of scale model cars
 * productLines: a list of product line categories
 *
 * ************************
 * Table Links (8 in total)
 * ************************
 *
 * employees.officeCode <--> offices.officeCode
 * employees.employeeNumber <--> employees.reportsTo
 * employees.employeeNumber <--> customers.salesRepEmployeeNumber
 * customers.customerNumber <--> payments.customerNumber
 * customers.customerNumber <--> orders.customerNumber
 * orders.orderNumber <--> orderdetails.orderNumber
 * orderdetails.productCode <--> products.productCode
 * products.productLine <--> productlines.productLine
 *
 */

-- Table Layout Summary
SELECT 'Customers' AS table_name,
       13 AS number_of_attributes,
       COUNT(*) AS number_of_rows
  FROM customers

 UNION ALL

SELECT 'Products', 9, COUNT(*)
  FROM products

 UNION ALL

SELECT 'ProductLines', 4, COUNT(*)
  FROM productLines

 UNION ALL

SELECT 'Orders', 7, COUNT(*)
  FROM orders

 UNION ALL

SELECT 'OrderDetails', 5, COUNT(*)
  FROM orderDetails

 UNION ALL

SELECT 'Payments', 4, COUNT(*)
  FROM payments

 UNION ALL

SELECT 'Employees', 8, COUNT(*)
  FROM employees

 UNION ALL

SELECT 'Offices', 9, COUNT(*)
  FROM offices;


/*
 * 1. Which products should we order more of or less of?
 *
 *
 * Two important KPIs for addressing this question are the:
 *
 *  Stock to Sales Ratio = quantityInStock / SUM(quantityOrdered)
 *
 *  Product Performance = SUM(quantityOrdered × priceEach)
 *
 *
 * A relatively low Stock to Sales Ratio is indicative of a
 * product that is closer to being out-of-stock. The Product
 * Performance corresponds to the total sales for a product.
 * Products that should be prioritized are those with high
 * product performance that are on the brink of being out of
 * stock.
 *
 * The products and orderdetails tables are used to compute the
 * Stock to Sales Ratio and Product Performance KPIs.
 */

-- Low stock
SELECT productCode,
       ROUND((SELECT quantityInStock
                FROM products p
               WHERE o.productCode = p.productCode) * 1.0 / SUM(quantityOrdered), 2) AS low_stock
  FROM orderdetails o
 GROUP BY productCode
 ORDER BY low_stock
 LIMIT 10;

-- Product performance
SELECT productCode,
       SUM(quantityOrdered * priceEach) AS product_performance
  FROM orderdetails
 GROUP BY productCode
 ORDER BY product_performance DESC
 LIMIT 10;

-- Priority Products for Restocking
WITH
low_stock_table AS (
    SELECT productCode,
           ROUND((SELECT quantityInStock
                    FROM products p
                   WHERE o.productCode = p.productCode) * 1.0 / SUM(quantityOrdered), 2) AS low_stock
      FROM orderdetails o
     GROUP BY productCode
     ORDER BY low_stock
     LIMIT 10
)
    SELECT o.productCode,
           productName,
           productLine,
           productScale,
           productVendor,
           productDescription,
           SUM(quantityOrdered * priceEach) AS product_performance
      FROM orderdetails o
      JOIN products p
        ON o.productCode = p.productCode
     WHERE o.productCode IN (SELECT productCode
                             FROM low_stock_table)
     GROUP BY o.productCode
     ORDER BY product_performance DESC
     LIMIT 10;


/*
 * 2. How should we tailor marketing and communication strategies
 *    to customer behaviors?
 *
 * For this question, the profit with each customer is calculated
 * in order to determine the:
 *
 *  top 5 VIP (who might then be targeted with loyalty programs)
 *
 *  5 least engaged customers (who might the be targeted with
 *  marketing campaigns)
 *
 * The products, orderdetails, and orders are used to calculate
 * the profit with each customer.
*/

-- profit by customer
SELECT customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS profit
  FROM orders o
  JOIN orderdetails od
    ON o.orderNumber = od.orderNumber
  JOIN products p
    ON od.productCode = p.productCode
 GROUP BY customerNumber;


-- Top 5 VIP customers
WITH
profit_table AS (
    SELECT customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS profit
      FROM orders o
      JOIN orderdetails od
        ON o.orderNumber = od.orderNumber
      JOIN products p
        ON od.productCode = p.productCode
     GROUP BY customerNumber
)
    SELECT contactLastName, contactFirstName, city, country, profit
      FROM customers c
      JOIN profit_table p
        ON c.customerNumber = p.customerNumber
     ORDER BY profit DESC
     LIMIT 5;

-- 5 least engaged customers
WITH
profit_table AS (
    SELECT customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS profit
      FROM orders o
      JOIN orderdetails od
        ON o.orderNumber = od.orderNumber
      JOIN products p
        ON od.productCode = p.productCode
     GROUP BY customerNumber
)
    SELECT contactLastName, contactFirstName, city, country, profit
      FROM customers c
      JOIN profit_table p
        ON c.customerNumber = p.customerNumber
     ORDER BY profit
     LIMIT 5;

/*
 * How much can be spent on acquiring new customers?
 *
 * The Customer Lifetime Value (LTV), which is the average amount
 * of profit a customer generates gives an upper bound on how
 * much more can be spent on the average to acquire each new
 * customer while profitability is maintained.
 */
 
-- Customer LTV
WITH
profit_table AS (
    SELECT customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS profit
      FROM orders o
      JOIN orderdetails od
        ON o.orderNumber = od.orderNumber
      JOIN products p
        ON od.productCode = p.productCode
     GROUP BY customerNumber
)
    SELECT AVG(profit) AS ltv
      FROM profit_table;

/*
 * Conclusion
 *
 * 1. Which products should we order more of or less of?
 *
 * The majority of the 10 highest priority products for
 * restocking are Motorcycles and Vintage Cars (please see
 * csv/priority_products.csv). One may want to investigate
 * further if a broader focus on Motorcyles and Vintage Cars is
 * appropriate.
 *
 * 2. How should we tailor marketing and communication strategies
 *    to customer behaviors?
 *
 * Information on the top 5 VIP customers and the 5 least engaged
 * customers can be found in csv/top_5_vip_customers.csv and
 * csv/5_least_engaged_customers.csv respectively. With this
 * knowledge, one can reach out these customer segments
 * accordingly.
 *
 * 3. How much can we spend on acquiring new customers?
 *
 * The customer Lifetime Value (LTV) is approximately 39,000 USD
 * (please see csv/customer_ltv.csv). This suggests that if there
 * are 10 new customers next month, there will be approximately
 * 390,000 more in lifetime profits. Some percentage of these
 * anticipated additional profits would have to be put towards
 * attracting the new customers.
 */

/*
 * Resources
 *
 *  1. Dataquest. https://www.dataquest.io/
 *  2. 13 Critical Inventory Management KPIs You've Got to
 *     Monitor.
 *     https://www.skunexus.com/blog/inventory-management-kpis
 */
 
 
    

