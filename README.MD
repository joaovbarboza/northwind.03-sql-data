# Ánalise dos clientes da Northwind

##  Contexto e Desafio de Negócio

> Objetivo: Entender o comportamento da base de clientes, a saúde do pipeline e identificar padrões de retenção versus abandono (churn).

##  Abordagem e Estrutura do Repositório

Para responder a este desafio, a análise foi estruturada de forma progressiva, partindo de agregações fundamentais até consultas avançadas com **CTEs** e **Window Functions**.

* **Foco do README:** Apresentação dos resultados, gráficos mentais e recomendações de negócio geradas por cada consulta.
* **Códigos Completos:** Os scripts `.sql` comentados passo a passo estão organizados na pasta `/Northwind` para rápida consulta e auditoria.

---

## 1º pergunta: 'Quem são os principais clientes (VIPs) da Northwind com base na métrica RFM (Recência, Frequência e Valor Monetário), e como podemos segmentar a base para ações de retenção?"'
* Objetivo: Focar-se em identificar e segmentar os clientes mais valiosos da base com base nos três pilares do RFM: Recência, Frequência e Monetário

```sql
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
```

### Resultado:

| Empresa (`CompanyName`) | Recência (Dias)* | Frequência (Pedidos) | Valor Monetário ($) |
| :--- | :---: | :---: | :---: |
| **B's Beverages** | 1113.06 | 210 | $6,154,115.34 |
| **Hungry Coyote Import Store** | 1106.66 | 198 | $5,698,023.67 |
| **Rancho grande** | 1129.87 | 194 | $5,559,110.08 |
| **Gourmet Lanchonetes** | 1117.84 | 202 | $5,552,309.81 |
| **Ana Trujillo Emparedados y helados** | 1108.30 | 195 | $5,534,356.65 |
| **Ricardo Adocicados** | 1139.23 | 203 | $5,524,517.31 |
| **Folies gourmandes** | 1116.12 | 195 | $5,505,502.85 |
| **Let's Stop N Shop** | 1133.70 | 191 | $5,462,198.02 |
| **LILA-Supermercado** | 1111.56 | 203 | $5,437,438.34 |
| **Princesa Isabel Vinhos** | 1108.52 | 200 | $5,436,770.55 |

*/*Nota: A rêcencia utilizada foi com base na data 'now', ou seja, a data de último dia que comprou está sendo comparada com a data atual.

### Insights Executivos e Leitura de Negócio

* **Frequência**: A frequência dos 10 melhores clientes da Northwind é boa, são bem similares comparado umas com as outras, e o valor monetário acompanha também essa similaridade, ou seja, é válido criar um porgrama de fidelidade coma alguns descontos, atendimento exclusivo para reter o máximo possível desses clientes mais valiosos.  

## 2º pergunta: Quais clientes estão inativos ou em alto risco de churn, e qual é o impacto financeiro acumulado desses clientes em risco?
* Objetivo: Identificar os clientes em risco de churn e o seu impacto financeiro.

```sql
WITH tab_data AS (
SELECT MAX(orderdate) AS ultimacompra -- uma mini tabela com a data da última compra
FROM Orders
)
SELECT t3.CompanyName,
      ROUND(julianday((select ultimacompra from tab_data)) - julianday(MAX(orderdate)), 2) AS dia_ultima,
      COUNT(DISTINCT t1.OrderID) AS qtd_pedidos, -- Total pedidos
      ROUND(SUM(t2.Quantity * t2.UnitPrice * (1-t2.Discount)), 2) AS valormonetario
FROM Orders AS t1
LEFT JOIN "Order Details" AS t2 
ON t1.OrderID = t2.OrderID
JOIN Customers AS t3 
ON t1.CustomerID = t3.CustomerID
GROUP BY t1.CustomerId
ORDER BY dia_ultima DESC
LIMIT 10
```
### Resultado:

| CompanyName | Data ultima visita | quantidade de pedidos | Valor Monetário ($) |
| :--- | :---: | :---: | :---: |
| **FISSA Fabrica Inter. Salchichas S.A** | 169.61 | 155 | $ 4.719.540,2 |
| **QUICK-Stop** | 127.97 | 183 | $ 4.938.975,48 |
| **Mère Paillarde** | 110.06 | 175 | $ 4.877.478,78 |
| **The Big Cheese** | 	103.19 | 164 | $ 4.830.860,98 |
| **Pericles Comidas clásicas** | 169 | 195 | $ 5.071.822,53 |
| **Du monde entier** | 86.43 | 160 | $ 4.236.208,17 |
| **Suprêmes délices** | 81.79 | 169 | $ 4.609.931,11 |
| **Comércio Mineiro** | 76.68 | 179 | $ 4.992.489,53 |
| **Reggiani Caseifici** | 56.14 | 160 | $ 4.223.241,67 |
| **Around the Horn** | 53.85 | 156 | $ 4.251.821,62 |

### Insights Executivos e Leitura de Negócio
* **Impacto** Churn nunca é bom, mas aqui podemos observar que o impacto financeiro é bem alto, tendo em vista que todos eles possuem valores similares. Para que haja uma reversão desses dados, é preciso entender quais são os produtos mais consumidos por eles e oferecer um desconto, e além disso, entender pq houve essa redução de compra.

### 3º pergunta: Qual é o Customer Lifetime Value (LTV) médio e o faturamento total por país, e quais regiões geográficas concentram os clientes de maior valor para a Northwind?
* Objetivo: Pontuar qual o Customer Lifetime Value por país.

```sql
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
```

#### Resultados Encontrados (Top 10 Países por LTV Médio):

| País (`Country`) | Qtd. Clientes | Faturamento Total ($) | LTV Médio por Cliente ($) |
| :--- | :---: | :---: | :---: |
| **Brasil** | 9 | $45.801.779,28 | $5.089.086,59 |
| **México** | 5 | $24.802.282,44 | $4.960.456,49 |
| **Áustria** | 2 | $9.908.284,14 | $4.954.142,07 |
| **Suiça** | 2 | $9.823.388,54 | $4.911.694,27 |
| **Venezuela** | 4 | $19.424.911,97 | $4.856.227,99 |
| **Dinamarca** | 2 | $9.708.374,72 | $4.854.187,36 |
| **Reino Unido (UK)** | 7 | $33.959.254,80 | $4.851.322,11 |
| **França** | 11 | $53.323.305,76 | $4.847.573,25 |
| **EUA (USA)** | 13 | $62.601.564,84 | $4.815.504,99 |
| **Espanha** | 5 | $24.023.498,25 | $4.804.699,65 |

---

#### Insight Executivo:
* **Liderança em Volume vs. Eficiência por Cliente:** os  EUA e France possui os maiores valores de faturamento, diz respeito a quantidade de clientes que cada um possui também, sendo os países com maior quantidade. 
* **Ação Estratégica:** Priorizar expansão comercial em mercados com alto LTV Médio (América Latina) e manter ações de fidelização nos mercados de grande volume (EUA/Europa).

### 4º pergunta: Como se distribuem os clientes da Northwind em faixas de faturamento (Alto, Médio e Baixo Valor), qual é a representatividade de cada categoria e a média gerada por cliente?
* Objetivo: Distribuição por Faixas de Faturamento (Segmentação de Receita)

```sql
WITH tab_faturamento AS (
SELECT t3.CompanyName,
ROUND(SUM(t2.UnitPrice * t2.Quantity * (1-t2.Discount)), 2) AS receita_liquida
FROM Orders AS t1

LEFT JOIN "Order Details" AS t2
ON t1.OrderID = t2.OrderID
JOIN Customers AS t3
ON t1.CustomerID = t3.CustomerID

WHERE t3.Country IS NOT NULL 

GROUP BY t3.CustomerID, t3.CompanyName
),

tab_categoria AS (
SELECT *,
    CASE WHEN receita_liquida >= 5000000 THEN 'Alto Valor'
         WHEN receita_liquida >= 4000000 AND receita_liquida < 5000000 THEN 'Médio Valor'
         ELSE 'Baixo Valor'
         END AS categoria
FROM tab_faturamento

ORDER BY receita_liquida DESC
)

SELECT COUNT(CompanyName) AS qtd_clientes,
       ROUND(SUM(receita_liquida), 2) AS faturamento_total,
       ROUND(AVG(receita_liquida), 2) AS ticket_medio
FROM tab_categoria

GROUP BY categoria

ORDER BY faturamento_total DESC
```

#### Resultados Encontrados:

| Categoria de Cliente | Qtd. Clientes | Faturamento Total ($) | Ticket Médio por Cliente ($) | % Receita Total |
| :--- | :---: | :---: | :---: | :---: |
| **Médio Valor ($\$4M - \$5M$)** | 67 | $310.949.527,51 | $4.641.037,72 | 70.9% |
| **Alto Valor ($\ge \$5M$)** | 23 | $123.726.269,39 | $5.379.403,02 | 28.2% |
| **Baixo Valor ($< \$4M$)** | 1 | $3.965.464,95 | $3.965.464,95 | 0.9% |

---

#### Insight Executivo:
* **Concentração no "Core Business":** A grande maioria da base (67 clientes, representando 70,9% da receita total) enquadra-se na faixa de **Médio Valor**, constituindo o grande pilar de estabilidade financeira da Northwind.
* **Clientes de Alto Valor (VIPs):** 23 clientes geram mais de **$123,7 Milhões** (28,2% do faturamento), com um ticket médio elevado de $5,37M por cliente.
* **Ação Recomendada:** Focar os esforços de upsell nos clientes de Médio Valor que estão próximos do limite de $5M, migrando-os para a categoria VIP através de incentivos de volume.

## Conclusão Geral e Impacto de Negócio


* **Concentração e Estabilidade da Receita**: A análise de faixas de faturamento revelou que o núcleo da receita da Northwind reside na categoria de Médio Valor (representando cerca de 70,9% do faturamento total), enquanto o topo da pirâmide é sustentado por um grupo restrito de clientes de Alto Valor, confirmando a eficácia da retenção de contas-chave.

* **Saúde da Base e Alertas de Churn**: Identificou-se que parceiros comerciais de alto volume histórico (como a FISSA Fabrica e a QUICK-Stop) encontram-se inativos há mais de 120 dias, evidenciando riscos críticos de evasão em contas de alto impacto financeiro.

* **Rentabilidade Geográfica (LTV)**: Embora os EUA e a França liderem o volume absoluto de faturação devido ao número de contas, o Brasil destacou-se com o maior LTV Médio por Cliente, demonstrando um ticket de consumo individual altamente qualificado.