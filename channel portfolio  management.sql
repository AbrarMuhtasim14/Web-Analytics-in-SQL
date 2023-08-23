-- channel portfolio 
------------------------
select * from  website_sessions;

SELECT 
min(date(created_at)) AS session_week,
  COUNT(CASE WHEN utm_source = 'gsearch' THEN website_session_id END) AS gsearch_sessions,
    COUNT(CASE WHEN utm_source = 'bsearch' THEN website_session_id END) AS bsearch_sessions
FROM website_sessions
WHERE created_at BETWEEN '2012-08-22' AND '2012-11-29'
and utm_campaign= 'nonbrand'
GROUP BY week(created_at);

-----------------------

SELECT 
    utm_source,
    COUNT(website_session_id) AS sessions, 
    COUNT(CASE WHEN device_type = 'mobile' THEN website_session_id END)  AS mobile_sessions,
    (COUNT(CASE WHEN device_type = 'mobile' THEN website_session_id END)  / COUNT(website_session_id)) * 100 AS mobile_pct
FROM website_sessions
WHERE created_at BETWEEN '2012-08-22' AND '2012-11-30'
	and utm_campaign= 'nonbrand'
    AND utm_source IN ('gsearch', 'bsearch')
GROUP BY utm_source;

---------------------------
SELECT 
    device_type,
    COUNT(ws.website_session_id) AS sessions, 
    COUNT(CASE WHEN utm_source = 'gsearch' THEN order_id END) AS gsearch_order,
    (COUNT(CASE WHEN utm_source = 'gsearch' THEN order_id END) / COUNT(website_session_id) * 100) as gsearch_pct,
    COUNT(CASE WHEN utm_source = 'bsearch' THEN order_id END) AS bsearch_order,
    (COUNT(CASE WHEN utm_source = 'bsearch' THEN order_id END) / COUNT(website_session_id) * 100) AS bsearch_pct
FROM website_sessions ws
left join orders o using (website_session_id)
WHERE ws.created_at > '2012-08-22' AND ws.created_at <'2012-09-19'
    AND utm_campaign = 'nonbrand'
GROUP BY device_type;

-------------------------

SELECT 
min(date(created_at)) AS session_week,
  COUNT(CASE WHEN utm_source = 'gsearch' and device_type = 'desktop' THEN website_session_id END) AS gsearch_desktop_,
  COUNT(CASE WHEN utm_source = 'bsearch' and device_type = 'desktop' THEN website_session_id END) AS bsearch_desktop_,
  COUNT(CASE WHEN utm_source = 'bsearch' and device_type = 'desktop' THEN website_session_id END)/COUNT(CASE WHEN utm_source = 'gsearch' and device_type = 'desktop' THEN website_session_id END) as b_pct_of_gtop,
  
 COUNT(CASE WHEN utm_source = 'gsearch' and device_type = 'mobile' THEN website_session_id END) AS mobile_gsearch_,
 COUNT(CASE WHEN utm_source = 'bsearch' and device_type = 'mobile' THEN website_session_id END) AS mobile_bsearch_,
 COUNT(CASE WHEN utm_source = 'bsearch' and device_type = 'mobile' THEN website_session_id END)/COUNT(CASE WHEN utm_source = 'gsearch' and device_type = 'mobile' THEN website_session_id END) as b_pct_of_gmobile
from website_sessions
where created_at > '2012-11-04' AND created_at <'2012-12-22'
AND utm_campaign = 'nonbrand'
group by week(created_at);


-----------------










   
   
   
SELECT 
    YEAR(created_at) AS year,
    MONTH(created_at) AS month,
    COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id END) AS nonbrand,
    COUNT(DISTINCT CASE WHEN channel_group = 'paid_brand' THEN website_session_id END) AS brand,
    COUNT(DISTINCT CASE WHEN channel_group = 'paid_brand' THEN website_session_id END) /
    COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id END) AS brand_pct_of_nonbrand,
    COUNT(DISTINCT CASE WHEN channel_group = 'direct_typein' THEN website_session_id END) AS direct,
    COUNT(DISTINCT CASE WHEN channel_group = 'direct_typein' THEN website_session_id END) /
    COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id END) AS direct_pct_of_nonbrand,
    COUNT(DISTINCT CASE WHEN channel_group = 'organic_search' THEN website_session_id END) AS organic,
    COUNT(DISTINCT CASE WHEN channel_group = 'organic_search' THEN website_session_id END) /
    COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id END) AS organic_pct_of_nonbrand
FROM (
    SELECT 
        website_session_id,
        created_at,
        CASE
            WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com') THEN 'organic_search'
            WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
            WHEN utm_campaign = 'brand' THEN 'paid_brand'
            WHEN utm_source IS NULL AND utm_campaign IS NULL THEN 'direct_typein' 
        END AS channel_group,
        utm_source,
        utm_campaign,
        http_referer
    FROM website_sessions
    WHERE created_at < '2012-12-23'
) AS session_with_channel_group
GROUP BY YEAR(created_at), MONTH(created_at);

   