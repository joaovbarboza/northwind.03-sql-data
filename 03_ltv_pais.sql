-- Qual é o Customer Lifetime Value (LTV) médio e o faturamento total por país, 
-- e quais regiões geográficas concentram os clientes de maior valor para a Northwind?

SELECT t2.Country,
       COUNT(DISTINCT t1.CustomerID) AS qtd_clientes,
       ROUND(SUM(t3.Quantity * t3.UnitPrice * (1-t3.Discount)), 2) AS faturamento_total,
       ROUND(SUM(t3.Quantity * t3.UnitPrice * (1-t3.Discount)) / COUNT(DISTINCT t1.CustomerID), 2) AS ltv_medio
FROM Orders AS t1
LEFT JOIN Customers AS t2
ON  t1.CustomerId = t2.CustomerID
JOIN "Order Details" AS t3
ON t1.OrderId = t3.OrderID

WHERE t2.Country IS NOT NULL 

GROUP BY t2.Country

ORDER BY ltv_medio DESC