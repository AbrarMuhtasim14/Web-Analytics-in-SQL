-- analyzing repeat session


create temporary table new_sessions
select user_id, website_session_id   from website_sessions
WHERE is_repeat_session = 0 and 
    YEAR(created_at) =2014 
    ;


create temporary table all_sessions
select new_sessions.user_id,  new_sessions.website_session_id as news_session, website_sessions.website_session_id as repeat_session 
 from
(select user_id , website_session_id from website_sessions
where is_repeat_session = 0 and 
YEAR(created_at) = 2014 ) as new_sessions
left join website_sessions on website_sessions.user_id  = new_sessions.user_id
and website_sessions.is_repeat_session =1 

and  YEAR(created_at) = 2014
;
 
 
select  total_repeat_session, count(user_id) from
	(select  user_id, count(distinct news_session) as new_session , count(distinct repeat_session) as total_repeat_session
	 from all_sessions
	 group by user_id) as new_repeat
group by total_repeat_session;












drop table session_day_difference;
create temporary table session_day_difference
SELECT new_sessions.user_id,
       new_sessions.website_session_id AS news_session,
       min(website_sessions.website_session_id) AS repeat_session,
       new_sessions.created_at AS first_session_time,
       min(website_sessions.created_at) AS repeat_session_time,
       DATEDIFF(website_sessions.created_at, new_sessions.created_at) AS session_diff
FROM
(
    SELECT user_id, website_session_id, created_at
    FROM website_sessions
    WHERE is_repeat_session = 0 AND YEAR(created_at) = 2014
) AS new_sessions
LEFT JOIN website_sessions ON website_sessions.user_id = new_sessions.user_id
    AND website_sessions.is_repeat_session = 1
    where YEAR(website_sessions.created_at) = 2014
    group by user_id;


 
select  min(session_diff), max(session_diff), avg(session_diff)
from session_day_difference;

-------------------------










SELECT
CASE
WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com') THEN 'organic_search'
 WHEN utm_campaign='nonbrand' THEN 'paid_nonbrand'
WHEN utm_campaign ='brand' THEN 'paid_brand'
WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
WHEN utm_source= 'socialbook' THEN 'paid_social'
END AS channel_group,
utm_source, utm_campaign,
http_referer,
COUNT(CASE WHEN is_repeat_session= 0 THEN website_session_id ELSE NULL END) AS new_sessions,
COUNT(CASE WHEN is_repeat_session = 1 THEN website_session_id ELSE NULL END) AS repeat_sessions FROM website_sessions
WHERE created_at < '2014-11-05'
AND created_at >= '2014-01-01'
GROUP BY 1;




    
    
    
----------------------




SELECT
    CASE
        WHEN is_repeat_session = 0 THEN 'New Session'
        WHEN is_repeat_session = 1 THEN 'Repeat Session'
        ELSE 'Unknown'
    END AS session_type,
    COUNT(DISTINCT website_sessions.website_session_id) AS session_count,
    COUNT(DISTINCT order_id) AS order_count,
    COUNT(DISTINCT order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS conversion_rate,
    SUM(price_usd) / COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session
FROM
    website_sessions
LEFT JOIN
    orders ON orders.website_session_id = website_sessions.website_session_id
WHERE
    website_sessions.created_at >= '2014-01-01'
    AND website_sessions.created_at < '2014-11-08'
GROUP BY
    session_type;
    
    

