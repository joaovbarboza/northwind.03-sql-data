-- Como se distribuem os clientes da Northwind em faixas de faturamento 
-- (ex: Alto Valor, Médio Valor e Baixo Valor), qual é o ticket médio por pedido em cada categoria 
-- e qual faixa representa o maior volume da receita?

WITH tab_faturamento AS (
SELECT t3.CompanyName,
ROUND(SUM(t2.UnitPrice * t2.Quantity * (1-t2.Discount)), 2) AS receita_liquida -- cálculo receita líquida 
FROM Orders AS t1

LEFT JOIN "Order Details" AS t2 -- join para pegar os detalhes do pedido
ON t1.OrderID = t2.OrderID
JOIN Customers AS t3 -- join para pegar o nome da empresa
ON t1.CustomerID = t3.CustomerID

WHERE t3.Country IS NOT NULL -- filtrando apenas clientes com país definido

GROUP BY t3.CustomerID, t3.CompanyName -- agrupando por clientes 
),

tab_categoria AS (
SELECT *,
    CASE WHEN receita_liquida >= 5000000 THEN 'Alto Valor'
         WHEN receita_liquida >= 4000000 AND receita_liquida < 5000000 THEN 'Médio Valor' -- classificando os clientes em faixas de faturamento
         ELSE 'Baixo Valor'
         END AS categoria
FROM tab_faturamento

ORDER BY receita_liquida DESC -- ordenando do maior para o menor faturamento
)

SELECT COUNT(CompanyName) AS qtd_clientes, -- quantidade total de clientes
       ROUND(SUM(receita_liquida), 2) AS faturamento_total, -- soma do faturamento total
       ROUND(AVG(receita_liquida), 2) AS ticket_medio -- média do faturamento total
FROM tab_categoria

GROUP BY categoria -- agrupei por categoria

ORDER BY faturamento_total DESC -- ordenando do maior para o menor 