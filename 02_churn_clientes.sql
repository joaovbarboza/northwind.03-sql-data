--Quais clientes estão inativos ou em alto risco de churn, 
-- e qual é o impacto financeiro acumulado desses clientes em risco?

WITH tab_data AS (
SELECT MAX(orderdate) AS ultimacompra -- uma mini tabela com a data da última compra
FROM Orders
)

SELECT t3.CompanyName,
      ROUND(julianday((select ultimacompra from tab_data)) - julianday(MAX(orderdate)), 2) AS dia_ultima, -- Dia da ultima compra comparado com o dia atual
      COUNT(DISTINCT t1.OrderID) AS qtd_pedidos, -- Total pedidos
      ROUND(SUM(t2.Quantity * t2.UnitPrice * (1-t2.Discount)), 2) AS valormonetario -- Valor líquido gasto pelo cliente
FROM Orders AS t1
LEFT JOIN "Order Details" AS t2 -- join interligando com a tabela de valores
ON t1.OrderID = t2.OrderID
JOIN Customers AS t3 -- join interligando com a tabela de clientes
ON t1.CustomerID = t3.CustomerID


GROUP BY t1.CustomerId

ORDER BY dia_ultima DESC

LIMIT 10