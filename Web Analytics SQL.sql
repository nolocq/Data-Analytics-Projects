use mavenfuzzyfactory;

/* 1. Gsearch seems to be the biggest driver of our business. Could you pull monthly 
trends for gsearch sessions and orders so that we can showcase the growth there?*/
SELECT 
    YEAR(ws.created_at) AS yr,
    MONTH(ws.created_at) AS mo,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id) as conv_rate
FROM
    website_sessions ws
        LEFT JOIN
    orders o ON ws.website_session_id = o.website_session_id
WHERE
    ws.created_at < '2012-11-27'
        AND ws.utm_source = 'gsearch'
GROUP BY 1 , 2;

/* 2. Next, it would be great to see a similar monthly trend for Gsearch, but this time splitting out 
nonbrand and brand campaigns separately. I am wondering if brand is picking up at all. If so, this is a good story to tell.*/
SELECT 
    YEAR(ws.created_at) AS yr,
    MONTH(ws.created_at) AS mo,
    COUNT(DISTINCT CASE
            WHEN utm_campaign = 'nonbrand' THEN ws.website_session_id
            ELSE NULL
        END) AS nonbrand_sessions,
    COUNT(DISTINCT CASE
            WHEN utm_campaign = 'nonbrand' THEN o.order_id
            ELSE NULL
        END) AS nonbrand_orders,
    COUNT(DISTINCT CASE
            WHEN utm_campaign = 'brand' THEN ws.website_session_id
            ELSE NULL
        END) AS brand_sessions,
    COUNT(DISTINCT CASE
            WHEN utm_campaign = 'brand' THEN o.order_id
            ELSE NULL
        END) AS brand_orders
FROM
    website_sessions ws
        LEFT JOIN
    orders o ON ws.website_session_id = o.website_session_id
WHERE
    ws.created_at < '2012-11-27'
        AND ws.utm_source = 'gsearch'
GROUP BY 1 , 2;

/*
3. While we’re on Gsearch, could you dive into nonbrand, and pull monthly sessions and orders split by device type? 
I want to flex our analytical muscles a little and show the board we really know our traffic sources.
*/
SELECT 
    YEAR(ws.created_at) AS yr,
    MONTH(ws.created_at) AS mo,
    COUNT(DISTINCT CASE
            WHEN device_type = 'desktop' THEN ws.website_session_id
            ELSE NULL
        END) AS desktop_sessions,
    COUNT(DISTINCT CASE
            WHEN device_type = 'desktop' THEN o.order_id
            ELSE NULL
        END) AS desktop_orders,
    COUNT(DISTINCT CASE
            WHEN device_type = 'mobile' THEN ws.website_session_id
            ELSE NULL
        END) AS mobile_sessions,
    COUNT(DISTINCT CASE
            WHEN device_type = 'mobile' THEN o.order_id
            ELSE NULL
        END) AS mobile_orders
FROM
    website_sessions ws
        LEFT JOIN
    orders o ON ws.website_session_id = o.website_session_id
WHERE
    ws.created_at < '2012-11-27'
        AND ws.utm_source = 'gsearch'
GROUP BY 1 , 2;

/*4. I’m worried that one of our more pessimistic board members may be concerned about the large % of traffic from
Gsearch. Can you pull monthly trends for Gsearch, alongside monthly trends for each of our other channels?*/
SELECT DISTINCT
    utm_source, utm_campaign, http_referer
FROM
    website_sessions ws
WHERE
    ws.created_at < '2012-11-27';

SELECT 
    YEAR(ws.created_at) AS yr,
    MONTH(ws.created_at) AS mo,
    COUNT(DISTINCT CASE
            WHEN utm_source = 'gsearch' THEN ws.website_session_id
            ELSE NULL
        END) AS gsearch_paid_sessions,
    COUNT(DISTINCT CASE
            WHEN utm_source = 'bsearch' THEN ws.website_session_id
            ELSE NULL
        END) AS bsearch_paid_sessions,
    COUNT(DISTINCT CASE
            WHEN
                utm_source IS NULL
                    AND http_referer IS NOT NULL
            THEN
                ws.website_session_id
            ELSE NULL
        END) AS organic_search_sessions,
    COUNT(DISTINCT CASE
            WHEN
                utm_source IS NULL
                    AND http_referer IS NULL
            THEN
                ws.website_session_id
            ELSE NULL
        END) AS direct_typein_sessions
FROM
    website_sessions ws
WHERE
    ws.created_at < '2012-11-27'
GROUP BY 1 , 2;

/*5. I’d like to tell the story of our website performance improvements over the course of the first 8 months.
Could you pull session to order conversion rates, by month ? */
SELECT 
    YEAR(ws.created_at) AS yr,
    MONTH(ws.created_at) AS mo,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT o.order_id) / COUNT(DISTINCT ws.website_session_id) AS conv_rate
FROM
    website_sessions ws
        LEFT JOIN
    orders o ON ws.website_session_id = o.website_session_id
WHERE
    ws.created_at < '2012-11-27'
GROUP BY 1 , 2; 


/*6. For the gsearch lander test, please estimate the revenue that test earned us (Hint: Look at the increase in CVR
from the test (Jun 19-Jul 28), and use nonbrand sessions and revenue since then to calculate incremental value)*/
SELECT 
    website_session_id, MIN(website_pageview_id) AS min_test_pv
FROM
    website_pageviews
WHERE
    pageview_url = '/lander-1';
    
-- Create temporary table first_test_pageviews
CREATE TEMPORARY TABLE first_pageviews
SELECT 
    wp.website_session_id,
    MIN(wp.website_pageview_id) AS min_pageview_id
FROM
    website_pageviews wp
        JOIN
    website_sessions ws ON wp.website_session_id = ws.website_session_id
        AND ws.created_at < '2012-07-28' AND wp.website_pageview_id >= 23504 
        AND utm_source = 'gsearch' AND utm_campaign='nonbrand'
GROUP BY wp.website_session_id;

-- next, bring in the landing page to each session
CREATE TEMPORARY TABLE nonbrand_test_session_w_landing_pages
SELECT 
    fp.website_session_id, wp.pageview_url AS landing_page
FROM
    first_pageviews fp
        LEFT JOIN
    website_pageviews wp ON fp.min_pageview_id = wp.website_pageview_id
WHERE
    wp.pageview_url IN ('/home' , '/lander-1');
    
-- then we make a table to bring in orders
CREATE TEMPORARY TABLE nonbrand_test_sessions_w_orders
SELECT 
    nl.website_session_id, nl.landing_page, o.order_id AS orders
FROM
    nonbrand_test_session_w_landing_pages nl
        LEFT JOIN
    orders o ON nl.website_session_id = o.website_session_id;

-- to find the difference btw conversion rate
SELECT 
    landing_page,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT orders) AS orders,
    COUNT(DISTINCT orders) / COUNT(DISTINCT website_session_id) AS conv_rate
FROM
    nonbrand_test_sessions_w_orders
GROUP BY 1; 
-- /home -- 0.0319
-- /lander-1 -- 0.0406

-- find the most recent pageview for gsearch nonbrand where the traffic was sent to /home
SELECT 
    MAX(ws.website_session_id) AS most_recent_gsearch_nonbrand_home_pageview
FROM
    website_sessions ws
        LEFT JOIN
    website_pageviews wp ON ws.website_session_id = wp.website_session_id
WHERE
    utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
        AND pageview_url = '/home'
        AND ws.created_at < '2012-11-27';
-- the most recent is 17145

SELECT 
    COUNT(website_session_id) AS session_since_test
FROM
    website_sessions
WHERE
    utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
        AND website_session_id > 17145
        AND created_at < '2012-11-27';
-- 22972 website sessions since the test
-- 0.0087 incremental conversion = 202 incremental orders since 7/29
        

-- identify Repeat Visitors
-- to find repeat_session users with their new and repeat session id
CREATE TEMPORARY TABLE sessions_w_repeats
SELECT 
    new_sessions.user_id,
    new_sessions.website_session_id AS new_session,
    website_sessions.website_session_id AS repeat_session
FROM -- create a new sessions table [first-time visit the session]
    (SELECT 
        user_id, website_session_id
    FROM
        website_sessions
    WHERE
        created_at < '2014-11-01'
            AND created_at >= '2014-01-01'
            AND is_repeat_session = 0) new_sessions
        LEFT JOIN
    website_sessions ON website_sessions.user_id = new_sessions.user_id
        AND website_sessions.is_repeat_session = 1
        AND website_sessions.created_at < '2014-11-01'
        AND website_sessions.created_at >= '2014-01-01';
        

SELECT -- count number of 0-3 times repeat_sessions
    repeat_session, COUNT(DISTINCT user_id) AS users
FROM
    (SELECT  -- count users' number of repeat_sessions
        user_id,
            COUNT(DISTINCT new_session) AS new_session,
            COUNT(DISTINCT repeat_session) AS repeat_session
    FROM
        sessions_w_repeats
    GROUP BY 1) AS user_level
GROUP BY 1;


-- step 1: identify the relevant new sessions
-- step 2: user the user_id values for step 1 to find any repeat sessions those user had
-- step 3: find the created_at times for first and second sessions
-- step 4: find the differences between first and second sessions at a user level
-- step 5: aggregate the user level data to find the average, min, max

CREATE TEMPORARY TABLE sessions_repeats
SELECT 
    new_sessions.user_id,
    new_sessions.website_session_id AS new_session_id,
    new_sessions.created_at AS new_session_created_at,
    website_sessions.website_session_id AS repeat_session_id,
    website_sessions.created_at AS repeat_session_created_at
FROM
    (SELECT 
        user_id, website_session_id, created_at
    FROM
        website_sessions
    WHERE
        created_at < '2014-11-03'
            AND created_at >= '2014-01-01'
            AND is_repeat_session = 0) new_sessions
        LEFT JOIN
    website_sessions ON website_sessions.user_id = new_sessions.user_id
        AND website_sessions.is_repeat_session = 1
        AND website_sessions.website_session_id > new_sessions.website_session_id
        AND website_sessions.created_at < '2014-11-03'
        AND website_sessions.created_at >= '2014-01-01';
        
CREATE TEMPORARY TABLE user_first_to_second 
SELECT 
    user_id,
    DATEDIFF(second_session_created_at,
            new_session_created_at) AS days_first_to_second_session
FROM
    (SELECT  -- find the second session id next to the first time 
        user_id,
            new_session_id,
            new_session_created_at,
            MIN(repeat_session_id) AS second_session_id, 
            MIN(repeat_session_created_at) AS second_session_created_at
    FROM
        sessions_repeats
    WHERE
        repeat_session_id IS NOT NULL
    GROUP BY 1 , 2 , 3) AS first_second;
    

SELECT 
    AVG(days_first_to_second_session) AS avg_days_first_to_second,
    MIN(days_first_to_second_session) AS min_days_first_to_second,
    MAX(days_first_to_second_session) AS max_days_first_to_second
FROM
    user_first_to_second;
    
    
select utm_source, utm_campaign, http_referer,
count(case when is_repeat_session = 0 then website_session_id else null end) as new_sessions,
count(case when is_repeat_session = 1 then website_session_id else null end) as repeat_sessions
from website_sessions
where created_at < '2014-11-05'
            AND created_at >= '2014-01-01'
group by 1,2,3
order by 5 desc;

select case when utm_source is null and http_referer in ('https://www.gsearch.com', 'https://www.bsearch.com') then 'organic_search'
when utm_campaign = 'nonbrand' then 'paid_nonbrand'
when utm_campaign = 'brand' then 'paid_brand'
when utm_source is null and http_referer is null then 'direct_type_in'
when utm_source = 'socialbook' then 'paid_social' 
end as channel_group,
count(case when is_repeat_session = 0 then website_session_id else null end) as new_sessions,
count(case when is_repeat_session = 1 then website_session_id else null end) as repeat_sessions
from website_sessions
where created_at < '2014-11-05'
            AND created_at >= '2014-01-01'
group by 1
order by 3 desc;