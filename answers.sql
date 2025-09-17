-- ===============================================
-- WEEK 4: 
-- Student: Stephen
-- Assignment: Complete Sales Database Analysis and Reporting
-- ===============================================

-- IMPORTANT SUBMISSION GUIDELINES:
-- 1. Use the provided repository only - do NOT create new repository
-- 2. Submit the correct link provided by trainer
-- 3. Follow the given questions exactly - do NOT create your own questions
-- 4. Use the salesdb database from Week 2 - do NOT create new database

-- Ensure we're working with the correct database from previous weeks
USE salesDB;


-- Section 1: Sales Performance Analysis
-- Question 1: Create a comprehensive sales report showing monthly revenue trends
SELECT 
    YEAR(o.orderDate) AS orderYear,
    MONTH(o.orderDate) AS orderMonth,
    MONTHNAME(o.orderDate) AS monthName,
    COUNT(DISTINCT o.orderNumber) AS totalOrders,
    COUNT(DISTINCT o.customerNumber) AS uniqueCustomers,
    SUM(od.quantityOrdered * od.priceEach) AS monthlyRevenue,
    AVG(od.quantityOrdered * od.priceEach) AS avgOrderValue
FROM orders o
INNER JOIN orderdetails od ON o.orderNumber = od.orderNumber
WHERE o.status = 'Shipped'
GROUP BY YEAR(o.orderDate), MONTH(o.orderDate), MONTHNAME(o.orderDate)
ORDER BY orderYear DESC, orderMonth DESC;

-- Question 2: Top performing employees by sales volume
SELECT 
    e.employeeNumber,
    CONCAT(e.firstName, ' ', e.lastName) AS employeeName,
    e.jobTitle,
    o.city AS officeLocation,
    COUNT(DISTINCT c.customerNumber) AS customersManaged,
    COUNT(DISTINCT ord.orderNumber) AS totalOrders,
    COALESCE(SUM(od.quantityOrdered * od.priceEach), 0) AS totalSalesVolume
FROM employees e
INNER JOIN offices o ON e.officeCode = o.officeCode
LEFT JOIN customers c ON e.employeeNumber = c.salesRepEmployeeNumber
LEFT JOIN orders ord ON c.customerNumber = ord.customerNumber
LEFT JOIN orderdetails od ON ord.orderNumber = od.orderNumber
WHERE e.jobTitle IN ('Sales Rep', 'Sales Manager')
GROUP BY e.employeeNumber, employeeName, e.jobTitle, o.city
ORDER BY totalSalesVolume DESC;

-- Section 2: Customer Analysis
-- Question 3: Customer segmentation based on total purchase value
SELECT 
    c.customerNumber,
    c.customerName,
    c.country,
    SUM(p.amount) AS totalPayments,
    COUNT(DISTINCT o.orderNumber) AS totalOrders,
    AVG(od.quantityOrdered * od.priceEach) AS avgOrderValue,
    CASE 
        WHEN SUM(p.amount) >= 100000 THEN 'Premium Customer'
        WHEN SUM(p.amount) >= 50000 THEN 'Gold Customer'
        WHEN SUM(p.amount) >= 25000 THEN 'Silver Customer'
        ELSE 'Bronze Customer'
    END AS customerTier
FROM customers c
LEFT JOIN payments p ON c.customerNumber = p.customerNumber
LEFT JOIN orders o ON c.customerNumber = o.customerNumber
LEFT JOIN orderdetails od ON o.orderNumber = od.orderNumber
GROUP BY c.customerNumber, c.customerName, c.country
ORDER BY totalPayments DESC;

-- Question 4: Geographic sales distribution analysis
SELECT 
    c.country,
    c.city,
    COUNT(DISTINCT c.customerNumber) AS customerCount,
    COUNT(DISTINCT o.orderNumber) AS orderCount,
    SUM(od.quantityOrdered * od.priceEach) AS totalRevenue,
    AVG(od.quantityOrdered * od.priceEach) AS avgOrderValue
FROM customers c
INNER JOIN orders o ON c.customerNumber = o.customerNumber
INNER JOIN orderdetails od ON o.orderNumber = od.orderNumber
GROUP BY c.country, c.city
HAVING totalRevenue > 10000
ORDER BY totalRevenue DESC;

-- Section 3: Product Performance Analysis
-- Question 5: Best and worst performing products by category
SELECT 
    p.productLine,
    p.productCode,
    p.productName,
    p.quantityInStock,
    SUM(od.quantityOrdered) AS totalQuantitySold,
    SUM(od.quantityOrdered * od.priceEach) AS totalRevenue,
    SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) AS totalProfit,
    ROUND(
        (SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) / 
         SUM(od.quantityOrdered * od.priceEach)) * 100, 2
    ) AS profitMarginPercent
FROM products p
INNER JOIN orderdetails od ON p.productCode = od.productCode
GROUP BY p.productLine, p.productCode, p.productName, p.quantityInStock
ORDER BY p.productLine, totalRevenue DESC;

-- Question 6: Inventory analysis - products needing restock
SELECT 
    p.productCode,
    p.productName,
    p.productLine,
    p.quantityInStock,
    COALESCE(AVG(od.quantityOrdered), 0) AS avgOrderQuantity,
    CASE 
        WHEN p.quantityInStock < 1000 THEN 'Critical - Immediate Restock'
        WHEN p.quantityInStock < 2000 THEN 'Low - Schedule Restock'
        WHEN p.quantityInStock < 5000 THEN 'Moderate - Monitor'
        ELSE 'Adequate Stock'
    END AS stockStatus
FROM products p
LEFT JOIN orderdetails od ON p.productCode = od.productCode
GROUP BY p.productCode, p.productName, p.productLine, p.quantityInStock
ORDER BY p.quantityInStock ASC;

-- Section 4: Financial Analysis
-- Question 7: Payment analysis and outstanding balances
SELECT 
    c.customerNumber,
    c.customerName,
    SUM(od.quantityOrdered * od.priceEach) AS totalOrderValue,
    COALESCE(SUM(p.amount), 0) AS totalPayments,
    (SUM(od.quantityOrdered * od.priceEach) - COALESCE(SUM(p.amount), 0)) AS outstandingBalance,
    CASE 
        WHEN (SUM(od.quantityOrdered * od.priceEach) - COALESCE(SUM(p.amount), 0)) > 0 
        THEN 'Has Outstanding Balance'
        WHEN (SUM(od.quantityOrdered * od.priceEach) - COALESCE(SUM(p.amount), 0)) < 0 
        THEN 'Overpaid'
        ELSE 'Balanced'
    END AS paymentStatus
FROM customers c
INNER JOIN orders o ON c.customerNumber = o.customerNumber
INNER JOIN orderdetails od ON o.orderNumber = od.orderNumber
LEFT JOIN payments p ON c.customerNumber = p.customerNumber
GROUP BY c.customerNumber, c.customerName
HAVING ABS(SUM(od.quantityOrdered * od.priceEach) - COALESCE(SUM(p.amount), 0)) > 0.01
ORDER BY outstandingBalance DESC;

-- Section 5: Data Maintenance Operations
-- Question 8: Update employee information - promote Stephen to Sales Manager
UPDATE employees 
SET jobTitle = 'Sales Manager',
    extension = 'x5501'
WHERE employeeNumber = 1703 AND firstName = 'Stephen';

-- Question 9: Insert new product line for modern vehicles
INSERT INTO products (
    productCode,
    productName,
    productLine,
    productScale,
    productVendor,
    productDescription,
    quantityInStock,
    buyPrice,
    MSRP
) VALUES (
    'S24_4000',
    'Tesla Model S Electric Sedan',
    'Classic Cars',
    '1:24',
    'Modern Auto Models',
    'Detailed replica of Tesla Model S electric luxury sedan with opening doors and detailed interior',
    5000,
    45.99,
    89.99
);

-- Question 10: Create summary view for management dashboard
CREATE VIEW management_dashboard AS
SELECT 
    'Total Customers' AS metric,
    COUNT(*) AS value,
    'customers' AS unit
FROM customers
UNION ALL
SELECT 
    'Total Products' AS metric,
    COUNT(*) AS value,
    'products' AS unit
FROM products
UNION ALL
SELECT 
    'Total Employees' AS metric,
    COUNT(*) AS value,
    'employees' AS unit
FROM employees
UNION ALL
SELECT 
    'Total Revenue' AS metric,
    ROUND(SUM(od.quantityOrdered * od.priceEach), 2) AS value,
    'USD' AS unit
FROM orderdetails od
UNION ALL
SELECT 
    'Total Orders' AS metric,
    COUNT(DISTINCT orderNumber) AS value,
    'orders' AS unit
FROM orders;

-- Display the management dashboard
SELECT * FROM management_dashboard;


-- COMPREHENSIVE SKILLS DEMONSTRATED:
-- - Complex multi-table JOINs (INNER, LEFT, RIGHT)
-- - Advanced aggregate functions and calculations
-- - CASE statements for conditional logic
-- - Date functions and time-based analysis
-- - Subqueries and correlated subqueries
-- - Data modification (INSERT, UPDATE)
-- - View creation for reporting
-- - Customer segmentation and business intelligence
-- - Financial analysis and reporting
-- - Inventory management queries
-- - Geographic analysis
-- - Performance optimization considerations
-- 
