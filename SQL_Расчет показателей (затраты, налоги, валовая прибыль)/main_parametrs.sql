SELECT
    date,
    revenue,
    costs,
    tax,
    revenue - costs - tax AS gross_profit,
    SUM(revenue) OVER (ORDER BY date) AS total_revenue,
    SUM(costs) OVER (ORDER BY date) AS total_costs,
    SUM(tax) OVER (ORDER BY date) AS total_tax,
    SUM(revenue - costs - tax) OVER (ORDER BY date) AS total_gross_profit,
    ROUND((revenue - costs - tax) / revenue * 100, 2) AS gross_profit_ratio,
    ROUND(SUM(revenue - costs - tax) OVER (ORDER BY date) / SUM(revenue) OVER (ORDER BY date) * 100, 2) AS total_gross_profit_ratio
FROM
(SELECT
    date,
    SUM(price) AS revenue,
    SUM(nds) AS tax
FROM
(SELECT
    date,
    order_id,
    name,
    price,
    CASE 
    WHEN name IN ('сахар', 'сухарики', 'сушки', 'семечки', 
'масло льняное', 'виноград', 'масло оливковое', 
'арбуз', 'батон', 'йогурт', 'сливки', 'гречка', 
'овсянка', 'макароны', 'баранина', 'апельсины', 
'бублики', 'хлеб', 'горох', 'сметана', 'рыба копченая', 
'мука', 'шпроты', 'сосиски', 'свинина', 'рис', 
'масло кунжутное', 'сгущенка', 'ананас', 'говядина', 
'соль', 'рыба вяленая', 'масло подсолнечное', 'яблоки', 
'груши', 'лепешка', 'молоко', 'курица', 'лаваш', 'вафли', 'мандарины') THEN ROUND(price - price / 1.1, 2)
    ELSE ROUND(price - price / 1.2, 2)
    END AS nds
FROM
(SELECT 
    creation_time::DATE as date,
    order_id,
    unnest(product_ids) as product_id
FROM orders
WHERE  order_id not in (SELECT order_id FROM user_actions WHERE  action = 'cancel_order')) as t1
LEFT JOIN products using(product_id)) AS t2
GROUP BY date) AS t8

LEFT JOIN

-- costs
(SELECT
    date,
    courier_costs + reg_costs + assembly_costs AS costs
FROM
(SELECT
    date,
    SUM(zp_courier) AS courier_costs,
    CASE 
    WHEN date <= '2022-08-31' THEN 120000
    WHEN date >= '2022-09-01' THEN 150000
    END AS reg_costs
FROM
(SELECT
    time::DATE as date,
    courier_id,
    COUNT(DISTINCT order_id) AS count_orders,
    CASE 
    WHEN COUNT(DISTINCT order_id) >= 5 AND time::DATE <= '2022-08-31' THEN COUNT(DISTINCT order_id) * 150 + 400
    WHEN COUNT(DISTINCT order_id) >= 5 AND time::DATE >= '2022-09-01' THEN COUNT(DISTINCT order_id) * 150 + 500
    WHEN COUNT(DISTINCT order_id) < 5 THEN COUNT(DISTINCT order_id) * 150
    END AS zp_courier
FROM 
    courier_actions
WHERE action = 'deliver_order'
GROUP BY date, courier_id) AS t3
GROUP BY date) AS t6

LEFT JOIN

(SELECT
    date,
    SUM(assembly_costs) AS assembly_costs
FROM
(SELECT
    time::DATE AS date,
    order_id,
    CASE
    WHEN time::DATE <= '2022-08-31' THEN 140
    WHEN time::DATE >= '2022-09-01' THEN 115
    END AS assembly_costs
FROM user_actions
WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) AS t4
GROUP BY date) AS t5 USING(date)
) AS t7 USING(date)
--costs
ORDER BY date