-- "Quem são os principais clientes (VIPs) da Northwind com base na métrica RFM (Recência, Frequência e Valor Monetário),
-- e como podemos segmentar a base para ações de retenção?"

SELECT t2.CompanyName,
       ROUND(julianday('now') - julianday(MAX(t1.orderdate)), 2) AS Recencia, -- Dias desde o último pedido
       COUNT(DISTINCT t1.OrderID) AS Frequência, -- Número de pedidos realizados
       ROUND(SUM(t3.Quantity * t3.UnitPrice * (1-t3.Discount)), 2) AS valormonetario -- valor líquido gasto pelo cliente
FROM Orders AS t1
LEFT JOIN Customers AS t2 -- join interligando com a tabela de clientes
ON t1.CustomerID = t2.CustomerID
JOIN "Order Details" AS t3 -- join interligando com a tabela de valores
ON t1.OrderID = t3.OrderID

GROUP BY t1.CustomerId -- agrupando por cliente

ORDER BY valormonetario DESC, Frequência DESC, recencia 

LIMIT 10 