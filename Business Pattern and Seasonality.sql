-- business paterns and seasonality
SELECT year(ws.created_at), 
    MONTH(ws.created_at) AS month,
    count(distinct ws.website_session_id) as no_of_sessions,
   count(distinct o.order_id) as no_of_orders
FROM website_sessions ws
LEFT JOIN orders o USING (website_session_id)
 where ws.created_at >= '2012-01-01' AND ws.created_at <='2012-12-31'
 group by 1,2;
 
------------ 
 select  year(ws.created_at) as year,weekofyear(ws.created_at) as weekno, min(date(ws.created_at)) AS session_week,
 count(distinct ws.website_session_id) as no_of_sessions,
   count(distinct o.order_id) as no_of_orders

FROM website_sessions ws
LEFT JOIN orders o USING (website_session_id)
 where ws.created_at >= '2012-01-01' AND ws.created_at <='2012-12-31'
 group by week(ws.created_at);
------------------


SELECT 
    Hours,
    avg ( CASE WHEN days = 'sunday' THEN sessions END) AS sunday,
    avg( CASE WHEN days = 'monday' THEN sessions END) AS monday,
    avg( CASE WHEN days = 'tuesday' THEN sessions END) AS tuesday,
    avg( CASE WHEN days = 'wednesday' THEN sessions END) AS wednesday,
    avg( CASE WHEN days = 'thursday' THEN sessions END) AS thursday,
    avg( CASE WHEN days = 'friday' THEN sessions END) AS friday,
    avg( CASE WHEN days = 'saturday' THEN sessions END) AS saturday
from(
SELECT 
    DATE(created_at) AS created_date,
    HOUR(created_at) AS Hours,
    CASE
        WHEN WEEKDAY(created_at) = 0 THEN 'monday'
        WHEN WEEKDAY(created_at) = 1 THEN 'tuesday'
        WHEN WEEKDAY(created_at) = 2 THEN 'wednesday'
        WHEN WEEKDAY(created_at) = 3 THEN 'thursday'
        WHEN WEEKDAY(created_at) = 4 THEN 'friday'
        WHEN WEEKDAY(created_at) = 5 THEN 'saturday'
        WHEN WEEKDAY(created_at) = 6 THEN 'sunday'
    END AS days,
    COUNT(website_session_id) AS sessions
FROM website_sessions
WHERE created_at >= '2013-09-15' AND created_at <= '2013-11-15'
GROUP BY 1, 2, 3
) as hour_wise_sessions
GROUP BY Hours  ; 
















