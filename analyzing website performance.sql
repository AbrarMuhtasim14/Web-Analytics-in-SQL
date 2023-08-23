



-- finding top entry pages
SELECT pageview_url as landing_page, COUNT(DISTINCT min_website_pageview_id) AS count_distinct_min_website_pageview_id
FROM (
    SELECT website_session_id, MIN(website_pageview_id)  AS min_website_pageview_id, pageview_url
    FROM website_pageviews
    WHERE created_at < '2012-06-12'
    GROUP BY website_session_id
) AS temp_table
group by landing_page;
--------------------------------------

-- calculating bounce rate 


create temporary table totalsessions
select website_session_id, count(website_pageview_id) as pages_visited, min(website_pageview_id), pageview_url
from website_pageviews 
WHERE created_at < '2012-06-14'
group by website_session_id;
select * from totalsessions;



create temporary table bounced_session
select website_session_id, count(website_pageview_id) as pages_visited, min(website_pageview_id), pageview_url
from website_pageviews 
WHERE created_at < '2012-06-14'
group by website_session_id
having  pages_visited=1;

select * from bounced_session;



select count(distinct  totalsessions.website_session_id) as notbounced,
count(distinct bounced_session.website_session_id) as bsessions ,  
count(distinct bounced_session.website_session_id)/count(distinct  totalsessions.website_session_id) as brate
from totalsessions
left JOIN bounced_session on bounced_session.website_session_id = totalsessions.website_session_id
;
---------------------
-- Analyzing landing page test
----------
-- STEP 0: find out when the new page /lander launched
-- STEP 1: finding the first website_pageview_id for relevant sessions 
-- STEP 2: identifying the landing page of each session
-- STEP 3: counting pageviews for each session, to identify "bounces" 
-- STEP 4: summarizing total sessions and bounced sessions, by LP
create temporary table landerall
select website_session_id, count(website_pageview_id) as pages_visited, min(website_pageview_id), pageview_url
from website_pageviews 
WHERE created_at between '2012-06-19' and '2012-07-28'
group by website_session_id;

create temporary table bouncedall
select website_session_id, count(website_pageview_id) as pages_visited, min(website_pageview_id), pageview_url
from website_pageviews 
WHERE created_at between '2012-06-19' and '2012-07-28'
group by website_session_id
having pages_visited=1;

select landerall.pageview_url, count(distinct  landerall.website_session_id) as notbounced,
count(distinct bouncedall.website_session_id) as bsessions ,  
count(distinct bouncedall.website_session_id)/count(distinct  landerall.website_session_id) as brate
from landerall
left JOIN bouncedall on bouncedall.website_session_id = landerall.website_session_id
group by landerall.pageview_url;

-----------------------------------------------------------------
-- pull the volume of paid search nonbrand traffic landing on /home and /lander-1,paid search bounce rate trended trended weekly since  launched the business
---
-- STEP 1: finding the first website_pageview_id for relevant sessions 
-- STEP 2: identifying the landing page of each session
-- STEP 3: counting pageviews for each session, to identify "bounces"
-- STEP 4: summarizing by week (bounce rate, sessions to each lander)

CREATE TEMPORARY TABLE sessions_w_min_pv_id_and_view_count
SELECT
website_sessions.website_session_id,
MIN(website_pageviews.website_pageview_id) AS first_pageview_id, 
COUNT(website_pageviews.website_pageview_id) AS count_pageviews

FROM website_sessions
LEFT JOIN website_pageviews
ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.created_at > '2012-06-01'
AND website_sessions.created_at < '2012-08-31' AND website_sessions.utm_source= 'gsearch' AND website_sessions.utm_campaign = 'nonbrand'

GROUP BY
website_sessions.website_session_id;

CREATE TEMPORARY TABLE sessions_w_counts_lander_and_created_at
SELECT
sessions_w_min_pv_id_and_view_count. website_session_id,
sessions_w_min_pv_id_and_view_count.first_pageview_id, sessions_w_min_pv_id_and_view_count.count_pageviews,
website_pageviews.pageview_url AS landing_page,
 website_pageviews.created_at AS session_created_at
FROM sessions_w_min_pv_id_and_view_count
LEFT JOIN website_pageviews
ON sessions_w_min_pv_id_and_view_count.first_pageview_id = website_pageviews.website_pageview_id;

SELECT
-- YEARWEEK(session_created_at) AS year_week,
MIN(DATE(session_created_at)) AS week_start_date,
-- COUNT(DISTINCT website_session_id) AS total_sessions,
-- COUNT(DISTINCT CASE WHEN Count_pageviews = 1 THEN website_session_id ELSE NULL END) AS bounced_sessions,
COUNT(DISTINCT CASE WHEN count_pageviews = 1 THEN website_session_id ELSE NULL END)*1.0/COUNT(DISTINCT website_session_id) as bounce_rate, 
COUNT(DISTINCT CASE WHEN landing_page ='/home' THEN website_session_id ELSE NULL END) AS home_sessions,
COUNt(DISTINCT CASE WHEN landing_page ='/lander-1' THEN website_session_id ELSE NULL END) AS lander_sessions
FROM sessions_w_counts_lander_and_created_at
GROUP BY
YEARWEEK(session_created_at);
---------------------------------------------------------------
-- building a   full conversion funnel, analyzing how many customers make it to each step with /lander-1 and build the funnel all the way to our thank you page
------
-- STEP 1: select all pageviews for relevant sessions
-- STEP 2: identify each pageview as the specific funnel step 
-- STEP 3: create the session-level conversion funnel view 
-- STEP 4: aggregate the data to assess funnel performance


Create temporary table basic 
 select website_session_id, max(lander_reached) as  lr, max(products_reached) as pr, 
 max(mrfuzzy_reached) mr, max(cart_reached) as cr,  max(shipping_reached) sr, max(billing_reached) as br, max(thanks_reached) as tr
 from (select ws.website_session_id, website_pageview_id, pageview_url,
 case when pageview_url = '/lander-1' then 1 else 0 end as lander_reached, 
 case when pageview_url = '/products' then 1 else 0 end as products_reached,
 case when pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end as mrfuzzy_reached,
 case when pageview_url = '/cart' then 1  else 0 end as cart_reached,
 case when pageview_url = '/shipping' then 1 else 0 end as shipping_reached,
 case when pageview_url = '/billing' then 1 else 0 end as billing_reached,
 case when pageview_url = '/thank-you-for-your-order' then 1  else 0 end as thanks_reached
 
 
from website_sessions ws left join website_pageviews  wp on ws.website_session_id= wp.website_session_id
where  ws.created_at between '2012-08-05' and '2012-09-05'
 and utm_campaign = 'nonbrand'
 and utm_source = 'gsearch'
 order by website_session_id) x 
 group by website_session_id;
 
 
 SELECT 
    COUNT(DISTINCT website_session_id) AS sessions, 
    COUNT(DISTINCT CASE WHEN lr = 1 THEN website_session_id ELSE NULL END) AS to_landing_reached, 
    COUNT(DISTINCT CASE WHEN pr = 1 THEN website_session_id ELSE NULL END) AS to_product_reached, 
    COUNT(DISTINCT CASE WHEN mr = 1 THEN website_session_id ELSE NULL END) AS to_mavveen_reached, 
    COUNT(DISTINCT CASE WHEN cr = 1 THEN website_session_id ELSE NULL END) AS to_cart_reached, 
    COUNT(DISTINCT CASE WHEN sr = 1 THEN website_session_id ELSE NULL END) AS to_shipping_reached,
    COUNT(DISTINCT CASE WHEN br = 1 THEN website_session_id ELSE NULL END) AS to_billing_reached,
    COUNT(DISTINCT CASE WHEN tr = 1 THEN website_session_id ELSE NULL END) AS to_thanks_reached
FROM basic;