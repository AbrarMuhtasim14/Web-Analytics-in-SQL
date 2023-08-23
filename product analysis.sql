-- PRODUCT ANALYSIS
SELECT * FROM  orders;
select distinct pageview_url from website_pageviews;
-- ANALYZING MONTHY REVENUE, AOV


select year(created_at), monthname(created_at), count(order_id) as no_of_sales, sum(price_usd) , sum(price_usd-cogs_usd) as margin
from orders
where created_at < '2013-01-04'
group by 1,2 ;
--  product wise revenue after launch of 2nd product
SELECT 
    YEAR(ws.created_at) AS year,
    MONTHNAME(ws.created_at) AS month,
    COUNT(o.order_id) AS no_of_sales,
    (COUNT(distinct order_id) / COUNT(distinct website_session_id))*100 AS conversion_rate,
    SUM(price_usd ) / COUNT(ws.website_session_id) AS revenue_per_session,
    SUM(CASE WHEN primary_product_id = 1 THEN price_usd ELSE 0 END) AS revenue_product_1,
    SUM(CASE WHEN primary_product_id = 2 THEN price_usd ELSE 0 END) AS revenue_product_2
    
FROM 
    website_sessions ws
left JOIN 
    orders o USING (website_session_id)
WHERE 
    ws.created_at BETWEEN '2012-04-01' AND '2013-04-05'
GROUP BY 
    YEAR(ws.created_at), MONTH(ws.created_at);

--------------------------------------------------
-- Calculate the clickthrough rates since product launch (January 6th, 2013)
-- STEP1 FIND ALL RELEVENT SESSIONS
DROP temporary table product_pageviews;
create temporary table product_pageviews
SELECT website_session_id,website_pageview_id, pageview_url, created_at, 
case 
	when created_at >= '2013-01-06' then 'post_product_launch'
    when created_at <= '2013-01-06' then 'pre_product_launch'
    else 'uff_check logic' 
    end as time_period
FROM website_pageviews
WHERE created_at <= '2013-04-06' AND created_at >= '2012-10-06' and pageview_url in ('/products')
ORDER BY website_session_id;

-- STEP2 finding next page after product page
DROP temporary table sessions_w_next_page;
create temporary table sessions_w_next_page
SELECT 
    product_pageviews.time_period,
    product_pageviews.website_session_id, 
    MIN(website_pageviews.website_pageview_id) AS next_pageview_id
FROM 
    product_pageviews
LEFT JOIN 
    website_pageviews
    ON website_pageviews.website_session_id = product_pageviews.website_session_id
    AND website_pageviews.website_pageview_id > product_pageviews.website_pageview_id
GROUP BY 
    product_pageviews.time_period,
    product_pageviews.website_session_id;
    
    -- STEP 3 finding `pageview_url` related to next `website_pageview_id`
    DROP temporary table sessions_w_next_URL ; 
create temporary table sessions_w_next_URL    
SELECT 
sessions_w_next_page.time_period,
    sessions_w_next_page.website_session_id as sessions_id, 
    website_pageviews.pageview_url as pageurl
FROM 
    sessions_w_next_page
LEFT JOIN 
    website_pageviews
    ON website_pageviews.website_pageview_id =sessions_w_next_page.next_pageview_id;
    
    
    
    
    
-- STEP: 4  SUMMARIZE THE DATA AND ANALYZE PRE AND POST PERIODS
select time_period , count(distinct sessions_id),
COUNT(DISTINCT CASE WHEN pageurl IS NOT NULL THEN sessions_id ELSE NULL END) AS W_NEXT_PG,
COUNT(DISTINCT CASE WHEN pageurl IS NOT NULL THEN sessions_id ELSE NULL END)/count(distinct sessions_id) AS PCT_NEXT_PG,
COUNT(DISTINCT CASE WHEN pageurl = '/the-original-mr-fuzzy' THEN sessions_id ELSE NULL END) AS  TO_MRFUZZY,
COUNT(DISTINCT CASE WHEN pageurl = '/the-original-mr-fuzzy' THEN sessions_id ELSE NULL END)/count(distinct sessions_id) AS PCT_TO_MRFUZZY,
COUNT(DISTINCT CASE WHEN pageurl = '/the-forever-love-bear' THEN sessions_id ELSE NULL END) AS  TO_LOVEBEAR,
COUNT(DISTINCT CASE WHEN pageurl = '/the-forever-love-bear' THEN sessions_id ELSE NULL END)/count(distinct sessions_id) AS PCT_TO_LOVEBEAR
FROM sessions_w_next_URL 
group by time_period;

------------------

-- CREATE TEMPORARY TABLE SESSION SEEING PRODUCT PAGE
create temporary table session_seeing_product_page
SELECT website_session_id, website_pageview_id, pageview_url AS product_pageseen
from website_pageviews where  created_at< '2013-04-10' and created_at>'2013-01-06' 
and pageview_url in ('/the-original-mr-fuzzy','/the-forever-love-bear' );

-- finding the right pagevirw url to create funnel
select distinct website_pageviews.pageview_url
from session_seeing_product_page
left join  website_pageviews on  website_pageviews.website_session_id= session_seeing_product_page.website_session_id
and website_pageviews.website_pageview_id>  session_seeing_product_page.website_pageview_id;





create temporary table session_product_level_made_it_flags

select website_session_id,
case 
when product_pageseen = '/the-original-mr-fuzzy' then 'mrfuzzy'
 when product_pageseen = '/the-forever-love-bear' then 'lovebear' else 'checklogic'
end as productseen,
max(cartpage) as cart_made_it,
max(shipping) as shipping_made_it,
max(billing) as billing_made_it,
max(thankyou) as thankyou_made_it
from (


		select session_seeing_product_page.website_session_id, product_pageseen, 
		case when pageview_url = '/cart' then 1 else 0 end as cartpage,
		case when pageview_url = '/shipping' then 1 else 0 end as shipping,
		case when pageview_url = '/billing-2' then 1 else 0 end as billing,
		case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou
		from session_seeing_product_page
		left join website_pageviews
		on session_seeing_product_page.website_session_id=  website_pageviews.website_session_id
		and website_pageviews.website_pageview_id> session_seeing_product_page.website_pageview_id) as pageview_level
	group by website_session_id;
    
    
    
    
    
    select productseen, count(website_session_id) as sessions, 
    count(distinct case when cart_made_it= 1 then website_session_id else null end )as to_cart,
    count(distinct case when shipping_made_it= 1 then website_session_id else null end )as to_shipping,
     count(distinct case when billing_made_it= 1 then website_session_id else null end )as to_billing_,
      count(distinct case when thankyou_made_it= 1 then website_session_id else null end )as to_thankyou
      from session_product_level_made_it_flags
      group by productseen;
  ---------------------------------
  
  
  
  
  -- analyzing cross selling product
    
    
    
    
    
SELECT
count(orders.order_id) as orders,
orders.primary_product_id,
order_items.product_id AS cross_sell_product
FROM orders
LEFT JOIN order_items
ON order_items.order_id = orders.order_id

--  
WHERE order_items.is_primary_item = 0 AND  orders.order_id BETWEEN 10000 AND 11000
group by 2,3;
---------------




-- product refund  rate



SELECT 
    YEAR(created_at) AS year,
    MONTH(created_at) AS month,
    COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_id ELSE NULL END) AS p1_order,
    COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_item_refund_id ELSE NULL END) AS p1_refund,
    COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_id ELSE NULL END) AS p2_order,
    COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_item_refund_id ELSE NULL END) AS p2_refund,
    COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_id ELSE NULL END) AS p3_order,
    COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_item_refund_id ELSE NULL END) AS p3_refund,
    COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_id ELSE NULL END) AS p4_order,
    COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_item_refund_id ELSE NULL END) AS p4_refund,
    COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_item_refund_id ELSE NULL END) /
        COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_id ELSE NULL END) AS p1_return_rate,
    COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_item_refund_id ELSE NULL END) /
        COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_id ELSE NULL END) AS p2_return_rate,
    COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_item_refund_id ELSE NULL END) /
        COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_id ELSE NULL END) AS p3_return_rate,
    COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_item_refund_id ELSE NULL END) /
        COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_id ELSE NULL END) AS p4_return_rate
FROM (
    select order_items.created_at, order_items.order_id, order_items.product_id, order_item_refunds.order_item_refund_id
from order_items
left join order_item_refunds on order_items.order_id = order_item_refunds.order_id
) AS all_refunds
GROUP BY 1, 2;






----

-- expansion
SELECT
CASE
WHEN website_sessions.created_at < '2013-12-12' THEN 'A. Pre_Birthday_Bear'
WHEN website_sessions.created_at >= '2013-12-12' THEN 'B. Post Birthday_Bear' ELSE 'uh oh...check logic'
END AS time_period,
COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
COUNT(DISTINCT orders.order_id) AS orders,
COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate, SUM(orders.price_usd) AS total_revenue,
SUM(orders.items_purchased) AS total_products_sold,
SUM(orders.price_usd)/COUNT(DISTINCT orders.order_id) AS average_order_value, SUM(orders.items_purchased)/COUNT(DISTINCT orders.order_id) AS products_per_order, SUM(orders.price_usd)/COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session
FROM website_sessions
LEFT JOIN orders
ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at BETWEEN '2013-11-12' AND '2014-01-12'
GROUP BY 1;











