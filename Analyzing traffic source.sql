-- finding top traffic source
SELECT
utm_source,
utm_campaign,
http_referer,
COUNT(DISTINCT website_session_id) AS number_of_sessions FROM website_sessions
WHERE created_at < '2012-04-12'
GROUP BY
utm_source, utm_campaign,
http_referer
ORDER BY number_of_sessions DESC;

-- finding conversion rate
SELECT
COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
COUNT(DISTINCT orders.order_id) AS orders,
COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS session_to_order_conv_rt FROM website_sessions
LEFT JOIN orders
ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at < '2012-04-14'
AND utm_source= 'gsearch'
AND utm_campaign= 'nonbrand';



















-- traffic source trending for gsearch nonbrand to see if bid changes have caused volume to drop
select min(date(created_at)) as week_started_at, count(distinct (website_session_id)) as sessions from website_sessions
 -- week(created_at)as weekly_v, count(website_session_id)  from website_sessions
 where  created_at < '2012-05-12'
 and utm_campaign = 'nonbrand'
 and utm_source = 'gsearch'
 group by  week(created_at), year(created_at);
 
 
 -- conversion rate by device type for bid optimization
 SELECT ws.device_type, 
       COUNT(DISTINCT ws.website_session_id) AS total_website_session_id, 
       COUNT(DISTINCT o.order_id) AS total_order_id,
       (COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id)) as conversion_rate
FROM website_sessions AS ws 
LEFT JOIN orders AS o 
       ON ws.website_session_id = o.website_session_id 
WHERE ws.created_at < '2012-05-11' 
and utm_campaign = 'nonbrand'
and utm_source = 'gsearch'
GROUP BY ws.device_type;

--  session by device type after biding up gsearch nonbrand


SELECT 
    MIN(DATE(created_at)) AS week_started_at,
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) AS desktop_sessions,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mobile_sessions
FROM website_sessions 
WHERE 
    created_at BETWEEN '2012-04-15' AND '2012-06-09'
    AND utm_campaign = 'nonbrand'
    AND utm_source = 'gsearch'
GROUP BY 
    WEEK(created_at)
    ;

