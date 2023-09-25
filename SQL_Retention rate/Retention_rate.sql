SELECT
    start_month::DATE AS start_month,
    start_date,
    lifetime AS day_number,
    ROUND(percentage, 2) AS retention
FROM
(SELECT
    active_date,
    COUNT(DISTINCT user_id) AS active_users,
    COUNT(DISTINCT user_id)::DECIMAL / MAX(COUNT(DISTINCT user_id)) OVER (PARTITION BY start_date) AS percentage,
    start_date,
    DATE_TRUNC('month', start_date) AS start_month,
    DATE_TRUNC('month', active_date) AS active_month,
    active_date - start_date AS lifetime
FROM
(SELECT
    user_id,
    time::DATE AS active_date,
    MIN(time) OVER (PARTITION BY user_id)::DATE AS start_date
FROM
    user_actions) AS t1
GROUP BY active_date, start_date) AS t2
ORDER BY start_date, day_number