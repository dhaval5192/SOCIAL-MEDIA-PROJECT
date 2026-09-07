CREATE DATABASE social_media;

USE social_media;

CREATE TABLE dim_date (
    date_key INT PRIMARY KEY, -- Format: YYYYMMDD (e.g., 20231025)
    full_date DATE NOT NULL,
    calendar_year INT,
    calendar_quarter INT,
    calendar_month INT,
    month_name VARCHAR(20),
    day_of_month INT,
    day_of_week INT,
    day_name VARCHAR(20),
    is_weekend BOOLEAN
);

CREATE TABLE dim_user (
    user_key INT AUTO_INCREMENT PRIMARY KEY, -- Surrogate Key
    original_user_id VARCHAR(50) NOT NULL,   -- Business Key (from OLTP)
    username VARCHAR(100),
    account_type VARCHAR(20),                -- e.g., 'Personal', 'Creator', 'Business'
    is_verified BOOLEAN,
    country VARCHAR(50)
);

CREATE TABLE dim_post (
    post_key INT AUTO_INCREMENT PRIMARY KEY, -- Surrogate Key
    original_post_id VARCHAR(50) NOT NULL,   -- Business Key (from OLTP)
    post_type VARCHAR(20),                   -- e.g., 'Image', 'Carousel', 'Reel', 'Video'
    media_url VARCHAR(500),
    caption_length INT,
    has_audio BOOLEAN
);

CREATE TABLE dim_hashtag (
    hashtag_key INT AUTO_INCREMENT PRIMARY KEY, -- Surrogate Key
    hashtag_text VARCHAR(100) UNIQUE
);


CREATE TABLE fact_post_creation (
    author_user_key INT,
    post_key INT,
    creation_date_key INT,
    post_count INT DEFAULT 1,
    FOREIGN KEY (author_user_key) REFERENCES dim_user(user_key),
    FOREIGN KEY (post_key) REFERENCES dim_post(post_key),
    FOREIGN KEY (creation_date_key) REFERENCES dim_date(date_key)
);

CREATE TABLE fact_engagement (
    actor_user_key INT,
    post_key INT,
    interaction_date_key INT,
    interaction_type VARCHAR(20), -- e.g., 'Like', 'Comment', 'Share'
    interaction_count INT DEFAULT 1,
    FOREIGN KEY (actor_user_key) REFERENCES dim_user(user_key),
    FOREIGN KEY (post_key) REFERENCES dim_post(post_key),
    FOREIGN KEY (interaction_date_key) REFERENCES dim_date(date_key)
);

CREATE TABLE fact_engagement (
    actor_user_key INT,
    post_key INT,
    interaction_date_key INT,
    interaction_type VARCHAR(20), -- e.g., 'Like', 'Comment', 'Share'
    interaction_count INT DEFAULT 1,
    FOREIGN KEY (actor_user_key) REFERENCES dim_user(user_key),
    FOREIGN KEY (post_key) REFERENCES dim_post(post_key),
    FOREIGN KEY (interaction_date_key) REFERENCES dim_date(date_key)
);

CREATE TABLE fact_network (
    follower_user_key INT,
    followed_user_key INT,
    action_date_key INT,
    network_action VARCHAR(20), -- e.g., 'Follow', 'Unfollow'
    is_active_follow INT,       -- 1 for active follow, 0 for unfollowed
    FOREIGN KEY (follower_user_key) REFERENCES dim_user(user_key),
    FOREIGN KEY (followed_user_key) REFERENCES dim_user(user_key),
    FOREIGN KEY (action_date_key) REFERENCES dim_date(date_key)
);

CREATE TABLE fact_hashtag_usage (
    post_key INT,
    hashtag_key INT,
    usage_date_key INT,
    usage_count INT DEFAULT 1,
    FOREIGN KEY (post_key) REFERENCES dim_post(post_key),
    FOREIGN KEY (hashtag_key) REFERENCES dim_hashtag(hashtag_key),
    FOREIGN KEY (usage_date_key) REFERENCES dim_date(date_key)
);

Show variables like 'secure_file_priv';

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/SocialMediaAnalytics/dim_date.csv'
INTO TABLE dim_date
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    date_key,
    @full_date_var,
    calendar_year,
    calendar_quarter,
    calendar_month,
    month_name,
    day_of_month,
    day_of_week,
    day_name,
    @is_weekend_var
)
SET 
    full_date = STR_TO_DATE(@full_date_var, '%Y-%m-%d'),
    is_weekend = IF(LOWER(@is_weekend_var) IN ('true', '1'), 1, 0);
    
    
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/SocialMediaAnalytics/dim_user.csv'
INTO TABLE dim_user
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    user_key,
    original_user_id,
    username,
    account_type,
    @is_verified_var,
    country
)
SET 
    is_verified = IF(LOWER(@is_verified_var) IN ('true', '1'), 1, 0);
    
    LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/SocialMediaAnalytics/dim_post.csv'
INTO TABLE dim_post
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    post_key,
    original_post_id,
    post_type,
    media_url,
    caption_length,
    @has_audio_var
)
SET 
    has_audio = IF(LOWER(@has_audio_var) IN ('true', '1'), 1, 0);
    
    LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/SocialMediaAnalytics/dim_hashtag.csv'
INTO TABLE dim_hashtag
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    hashtag_key,
    hashtag_text
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/SocialMediaAnalytics/fact_post_creation.csv'
INTO TABLE fact_post_creation
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    author_user_key,
    post_key,
    creation_date_key,
    post_count
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/SocialMediaAnalytics/fact_engagement.csv'
INTO TABLE fact_engagement
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    actor_user_key,
    post_key,
    interaction_date_key,
    interaction_type,
    interaction_count
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/SocialMediaAnalytics/fact_network.csv'
INTO TABLE fact_network
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    follower_user_key,
    followed_user_key,
    action_date_key,
    network_action,
    is_active_follow
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/SocialMediaAnalytics/fact_hashtag_usage.csv'
INTO TABLE fact_hashtag_usage
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    post_key,
    hashtag_key,
    usage_date_key,
    usage_count
);

-- QUESTION 1: What is the breakdown of content formats being published, and what percentage of total posts include an active audio track?
SELECT
    post_type,
    COUNT(post_key) AS total_posts_published,
    ROUND(COUNT(post_key) * 100.0 / SUM(COUNT(post_key)) OVER (), 2) AS pct_of_total_posts,
    SUM(CASE WHEN has_audio = 1 THEN 1 ELSE 0 END) AS posts_with_audio,
    ROUND(SUM(CASE WHEN has_audio = 1 THEN 1 ELSE 0 END) / COUNT(post_key) * 100, 2) AS audio_adoption_pct
FROM dim_post
GROUP BY post_type
ORDER BY total_posts_published DESC;

-- QUESTION 2: How does the overall volume of published content fluctuate across different months and quarters of the year?
WITH monthly_totals AS (
    SELECT
        d.calendar_year,
        d.calendar_quarter,
        d.calendar_month,
        d.month_name,
        SUM(fpc.post_count) AS total_published_posts
    FROM fact_post_creation fpc
    JOIN dim_date d ON fpc.creation_date_key = d.date_key
    GROUP BY 
        d.calendar_year, 
        d.calendar_quarter, 
        d.calendar_month,
        d.month_name
)
SELECT
    calendar_year,
    calendar_quarter,
    month_name,
    total_published_posts,
    SUM(total_published_posts) OVER (PARTITION BY calendar_year, calendar_quarter) AS quarterly_total_posts,
    ROUND(SUM(total_published_posts) OVER (PARTITION BY calendar_year, calendar_quarter) 
        / SUM(total_published_posts) OVER (PARTITION BY calendar_year) * 100, 2) AS quarterly_pct_of_annual_total,
    ROUND(total_published_posts 
        / SUM(total_published_posts) OVER (PARTITION BY calendar_year) * 100, 2) AS monthly_pct_of_annual_total,
    ROUND(AVG(total_published_posts) OVER (PARTITION BY calendar_year), 2) AS avg_posts_per_month,
    ROUND((total_published_posts - AVG(total_published_posts) OVER (PARTITION BY calendar_year)) 
        / AVG(total_published_posts) OVER (PARTITION BY calendar_year) * 100, 2) AS pct_deviation_from_monthly_avg
FROM monthly_totals
ORDER BY 
    calendar_year, 
    calendar_month;
    
  --   QUESTION 3: Is there a significant difference in daily publishing volume when comparing weekdays to weekends?
    WITH day_type_summary AS (
    SELECT
        CASE WHEN d.is_weekend = 1 THEN 'Weekend' ELSE 'Weekday' END AS weekly_classification,
        COUNT(DISTINCT d.date_key) AS total_days_in_period,
        SUM(fpc.post_count) AS aggregate_posts
    FROM fact_post_creation fpc
    JOIN dim_date d ON fpc.creation_date_key = d.date_key
    GROUP BY 
        CASE WHEN d.is_weekend = 1 THEN 'Weekend' ELSE 'Weekday' END
)
SELECT
    weekly_classification,
    total_days_in_period,
    ROUND(total_days_in_period / SUM(total_days_in_period) OVER () * 100, 2) AS pct_of_total_days,
    aggregate_posts,
    ROUND(aggregate_posts / SUM(aggregate_posts) OVER () * 100, 2) AS pct_of_total_posts,
    ROUND(aggregate_posts / total_days_in_period, 2) AS avg_posts_per_day
FROM day_type_summary
ORDER BY avg_posts_per_day DESC;

-- QUESTION 4: 	
SELECT
    post_type,
    MIN(caption_length) AS shortest_caption_chars,
    MAX(caption_length) AS longest_caption_chars,
    ROUND(AVG(caption_length), 0) AS avg_caption_length
FROM dim_post
GROUP BY post_type
ORDER BY avg_caption_length DESC;

-- QUESTION 5: Which specific content formats generate the highest average engagement volume per individual post?
WITH format_engagement AS (
    SELECT
        p.post_type,
        COUNT(DISTINCT p.post_key) AS total_unique_posts,
        SUM(post_eng.total_interactions) AS platform_total_engagement
    FROM dim_post p
    JOIN (
        -- Pre-aggregate engagement at the post level to ensure accurate averages
        SELECT post_key, SUM(interaction_count) AS total_interactions
        FROM fact_engagement
        GROUP BY post_key
    ) post_eng ON p.post_key = post_eng.post_key
    GROUP BY p.post_type
)
SELECT
    post_type,
    total_unique_posts,
    platform_total_engagement,
    ROUND(platform_total_engagement / SUM(platform_total_engagement) OVER () * 100, 2) AS pct_of_total_engagement,
    ROUND(platform_total_engagement / total_unique_posts, 2) AS avg_engagement_per_post,
    ROUND(SUM(platform_total_engagement) OVER () / SUM(total_unique_posts) OVER (), 2) AS platform_avg_engagement_per_post,
    ROUND((platform_total_engagement / total_unique_posts) 
        / (SUM(platform_total_engagement) OVER () / SUM(total_unique_posts) OVER ()) * 100 - 100, 2) AS pct_vs_platform_avg
FROM format_engagement
ORDER BY avg_engagement_per_post DESC;

-- QUESTION 6: Who are the top 10 most actively engaging non-verified users on the platform based on total interaction volume?

	WITH top_unverified_users AS (
    SELECT
        u.user_key AS user_id,
        u.account_type,
        u.country,
        user_activity.total_interactions_made
    FROM dim_user u
    JOIN (
        -- Calculate total outgoing interactions per user
        SELECT actor_user_key, SUM(interaction_count) AS total_interactions_made
        FROM fact_engagement
        GROUP BY actor_user_key
    ) user_activity ON u.user_key = user_activity.actor_user_key
    WHERE u.is_verified = 0
    ORDER BY user_activity.total_interactions_made DESC
    LIMIT 10
)
SELECT
    user_id,
    account_type,
    country,
    total_interactions_made,
    COUNT(*) OVER () AS total_users_in_list,
    SUM(CASE WHEN account_type = 'Personal' THEN 1 ELSE 0 END) OVER () AS personal_account_count,
    ROUND(SUM(CASE WHEN account_type = 'Personal' THEN 1 ELSE 0 END) OVER () 
        / COUNT(*) OVER () * 100, 1) AS pct_personal_accounts
FROM top_unverified_users
ORDER BY total_interactions_made DESC;

QUESTION 7: What proportion of overall platform interactions do likes, comments, and shares represent when comparing posts with audio against posts without audio?
WITH interaction_breakdown AS (
    SELECT
        CASE WHEN p.has_audio = 1 THEN 'Contains Audio' ELSE 'No Audio' END AS audio_status,
        e.interaction_type,
        SUM(e.interaction_count) AS interaction_volume
    FROM dim_post p
    JOIN fact_engagement e ON p.post_key = e.post_key
    GROUP BY p.has_audio, e.interaction_type
)
SELECT
    audio_status,
    interaction_type,
    interaction_volume,
    ROUND(interaction_volume / SUM(interaction_volume) OVER () * 100, 2) AS pct_of_platform_total,
    SUM(interaction_volume) OVER (PARTITION BY audio_status) AS audio_status_total_interactions,
    ROUND(SUM(interaction_volume) OVER (PARTITION BY audio_status) 
        / SUM(interaction_volume) OVER () * 100, 2) AS audio_status_pct_of_platform_total
FROM interaction_breakdown
ORDER BY audio_status, interaction_volume DESC;

-- QUESTION 8: Which specific days of the week consistently experience user engagement volumes that exceed the daily platform average?
SELECT
    d.day_name,
    COUNT(DISTINCT d.date_key) AS occurrences_in_dataset,
    SUM(e.interaction_count) AS total_interactions,
    ROUND(SUM(e.interaction_count) / COUNT(DISTINCT d.date_key), 0) AS avg_daily_volume
FROM fact_engagement e
JOIN dim_date d ON e.interaction_date_key = d.date_key
GROUP BY d.day_name
HAVING SUM(e.interaction_count) / COUNT(DISTINCT d.date_key) > (
    -- Determine the baseline average interactions per day across the entire dataset
    SELECT SUM(interaction_count) / COUNT(DISTINCT interaction_date_key)
    FROM fact_engagement
)
ORDER BY avg_daily_volume DESC;

-- QUESTION 9  What is the aggregate ratio of followers to following for different account types (Personal, Creator, Business)?
WITH follower_metrics AS (
    SELECT followed_user_key AS user_key, SUM(is_active_follow) AS total_followers
    FROM fact_network
    GROUP BY followed_user_key
),
following_metrics AS (
    SELECT follower_user_key AS user_key, SUM(is_active_follow) AS total_following
    FROM fact_network
    GROUP BY follower_user_key
),
followers_by_type AS (
    SELECT
        u.account_type,
        SUM(IFNULL(fm.total_followers, 0)) AS aggregate_followers,
        SUM(IFNULL(fnm.total_following, 0)) AS aggregate_following
    FROM dim_user u
    LEFT JOIN follower_metrics fm ON u.user_key = fm.user_key
    LEFT JOIN following_metrics fnm ON u.user_key = fnm.user_key
    GROUP BY u.account_type
)
SELECT
    account_type,
    aggregate_followers,
    ROUND(aggregate_followers / SUM(aggregate_followers) OVER () * 100, 2) AS pct_of_total_followers,
    aggregate_following,
    ROUND(aggregate_following / SUM(aggregate_following) OVER () * 100, 2) AS pct_of_total_following,
    ROUND(aggregate_followers / NULLIF(aggregate_following, 0), 2) AS follower_to_following_ratio
FROM followers_by_type
ORDER BY follower_to_following_ratio DESC;

-- QUESTION 10  How does the ratio of user engagement to content creation vary across different geographic regions (countries)?
WITH creator_activity AS (
    SELECT author_user_key AS user_key, SUM(post_count) AS total_posts_created
    FROM fact_post_creation
    GROUP BY author_user_key
),
engagement_activity AS (
    SELECT actor_user_key AS user_key, SUM(interaction_count) AS total_interactions_made
    FROM fact_engagement
    GROUP BY actor_user_key
)
SELECT
    u.country,
    COUNT(DISTINCT u.user_key) AS total_users_in_region,
    SUM(IFNULL(ca.total_posts_created, 0)) AS total_regional_posts,
    SUM(IFNULL(ea.total_interactions_made, 0)) AS total_regional_interactions,
    ROUND(SUM(IFNULL(ea.total_interactions_made, 0)) / NULLIF(SUM(IFNULL(ca.total_posts_created, 0)), 0), 2) AS engagement_to_creation_ratio
FROM dim_user u
LEFT JOIN creator_activity ca ON u.user_key = ca.user_key
LEFT JOIN engagement_activity ea ON u.user_key = ea.user_key
GROUP BY u.country
ORDER BY engagement_to_creation_ratio DESC;

-- QUESTION 11    How does the verification status of an account impact its ability to attract active followers and its historical follower churn rate?
WITH network_flows AS (
    SELECT
        followed_user_key AS user_key,
        SUM(CASE WHEN network_action = 'Follow' THEN 1 ELSE 0 END) AS gross_follows,
        SUM(CASE WHEN network_action = 'Unfollow' THEN 1 ELSE 0 END) AS gross_unfollows,
        SUM(is_active_follow) AS current_active_followers
    FROM fact_network
    GROUP BY followed_user_key
),
verification_summary AS (
    SELECT
        CASE WHEN u.is_verified = 1 THEN 'Verified Status' ELSE 'Unverified Status' END AS verification_tier,
        COUNT(DISTINCT u.user_key) AS distinct_accounts,
        SUM(nf.current_active_followers) AS network_active_followers,
        ROUND(AVG(nf.current_active_followers), 0) AS avg_active_followers_per_account,
        ROUND(SUM(nf.gross_unfollows) / NULLIF(SUM(nf.gross_follows), 0) * 100, 2) AS network_churn_percentage
    FROM dim_user u
    JOIN network_flows nf ON u.user_key = nf.user_key
    GROUP BY u.is_verified
)
SELECT
    verification_tier,
    distinct_accounts,
    network_active_followers,
    ROUND(network_active_followers / SUM(network_active_followers) OVER () * 100, 2) AS pct_of_total_active_followers,
    avg_active_followers_per_account,
    network_churn_percentage
FROM verification_summary
ORDER BY avg_active_followers_per_account DESC;

-- QUESTION 12    What is the month-over-month trajectory of net-new active follow relationships established across the entire platform?
WITH monthly_aggregation AS (
    SELECT
        d.calendar_year,
        d.calendar_month,
        d.month_name,
        SUM(n.is_active_follow) AS net_new_connections
    FROM fact_network n
    JOIN dim_date d ON n.action_date_key = d.date_key
    GROUP BY 
        d.calendar_year, 
        d.calendar_month, 
        d.month_name
)
SELECT
    curr.calendar_year,
    curr.calendar_month,
    curr.month_name,
    curr.net_new_connections AS current_month_growth,
    prev.net_new_connections AS previous_month_growth,
    curr.net_new_connections - IFNULL(prev.net_new_connections, 0) AS absolute_growth_difference,
    ROUND((curr.net_new_connections - prev.net_new_connections) / NULLIF(prev.net_new_connections, 0) * 100, 2) AS mom_growth_pct,
    SUM(curr.net_new_connections) OVER (PARTITION BY curr.calendar_year) AS annual_total_net_new_connections,
    ROUND(AVG(curr.net_new_connections) OVER (PARTITION BY curr.calendar_year), 2) AS avg_monthly_net_new_connections
FROM monthly_aggregation curr
LEFT JOIN monthly_aggregation prev
    ON (curr.calendar_year = prev.calendar_year AND curr.calendar_month = prev.calendar_month + 1)
    OR (curr.calendar_year = prev.calendar_year + 1 AND curr.calendar_month = 1 AND prev.calendar_month = 12)
ORDER BY 
    curr.calendar_year, 
    curr.calendar_month;
    
--     QUESTION 13: Which highly utilized hashtags are driving the most significant engagement, and how do they rank against their peers in the top usage quartile?
WITH hashtag_base_metrics AS (
    SELECT
        hu.hashtag_key,
        SUM(hu.usage_count) AS total_applications,
        SUM(e.interaction_count) AS total_attributed_engagement
    FROM fact_hashtag_usage hu
    LEFT JOIN fact_engagement e ON hu.post_key = e.post_key
    GROUP BY hu.hashtag_key
),
ranked_hashtag_performance AS (
    SELECT
        h.hashtag_text,
        hbm.total_applications,
        hbm.total_attributed_engagement,
        NTILE(4) OVER (ORDER BY hbm.total_applications DESC) AS overall_usage_quartile,
        RANK() OVER (ORDER BY hbm.total_attributed_engagement DESC) AS platform_engagement_rank
    FROM hashtag_base_metrics hbm
    JOIN dim_hashtag h ON hbm.hashtag_key = h.hashtag_key
    WHERE hbm.total_attributed_engagement IS NOT NULL
)
SELECT
    hashtag_text,
    total_applications,
    total_attributed_engagement,
    overall_usage_quartile,
    platform_engagement_rank,
    ROUND(total_attributed_engagement / NULLIF(total_applications, 0), 2) AS engagement_efficiency_ratio
FROM ranked_hashtag_performance
WHERE overall_usage_quartile = 1
ORDER BY platform_engagement_rank
LIMIT 15;

-- QUESTION 14    What is the rolling 7-day average of platform-wide interactions, and how does daily performance deviate from this trend line? 
WITH daily_platform_engagement AS (
    SELECT
        d.full_date,
        SUM(e.interaction_count) AS daily_interactions
    FROM fact_engagement e
    JOIN dim_date d ON e.interaction_date_key = d.date_key
    GROUP BY d.full_date
),
momentum_calculations AS (
    SELECT
        full_date,
        daily_interactions,
        ROUND(AVG(daily_interactions) OVER (
            ORDER BY full_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ), 0) AS rolling_7d_avg_interactions
    FROM daily_platform_engagement
),
trailing_30d_sample AS (
    SELECT
        full_date,
        daily_interactions,
        rolling_7d_avg_interactions,
        daily_interactions - rolling_7d_avg_interactions AS variation_from_trend,
        CASE
            WHEN daily_interactions > (rolling_7d_avg_interactions * 1.25) THEN 'Positive Spike'
            WHEN daily_interactions < (rolling_7d_avg_interactions * 0.75) THEN 'Negative Drop'
            ELSE 'Stable Baseline'
        END AS momentum_indicator
    FROM momentum_calculations
    ORDER BY full_date DESC
    LIMIT 31
)
SELECT
    full_date,
    daily_interactions,
    rolling_7d_avg_interactions,
    variation_from_trend,
    momentum_indicator,
    COUNT(*) OVER () AS days_in_sample,
    SUM(CASE WHEN momentum_indicator = 'Stable Baseline' THEN 1 ELSE 0 END) OVER () AS stable_baseline_days,
    ROUND(SUM(CASE WHEN momentum_indicator = 'Stable Baseline' THEN 1 ELSE 0 END) OVER () 
        / COUNT(*) OVER () * 100, 1) AS pct_stable_baseline
FROM trailing_30d_sample
ORDER BY full_date DESC;

-- QUESTION 15   Which users qualify as "breakout creators"—those who rank in the top 20% for content engagement but remain in the bottom 50% for total audience size?
WITH user_audience_size AS (
    SELECT followed_user_key AS user_key, SUM(is_active_follow) AS current_followers
    FROM fact_network
    GROUP BY followed_user_key
),
user_content_engagement AS (
    SELECT pc.author_user_key AS user_key, SUM(e.interaction_count) AS total_earned_engagement
    FROM fact_post_creation pc
    JOIN fact_engagement e ON pc.post_key = e.post_key
    GROUP BY pc.author_user_key
),
percentile_rankings AS (
    SELECT
        u.user_key AS user_id,
        u.account_type,
        IFNULL(uas.current_followers, 0) AS follower_count,
        IFNULL(uce.total_earned_engagement, 0) AS engagement_generated,
        PERCENT_RANK() OVER (ORDER BY IFNULL(uas.current_followers, 0)) AS follower_percentile,
        PERCENT_RANK() OVER (ORDER BY IFNULL(uce.total_earned_engagement, 0)) AS engagement_percentile
    FROM dim_user u
    LEFT JOIN user_audience_size uas ON u.user_key = uas.user_key
    LEFT JOIN user_content_engagement uce ON u.user_key = uce.user_key
),
breakout_creators AS (
    SELECT
        user_id,
        account_type,
        follower_count,
        engagement_generated,
        ROUND(follower_percentile * 100, 1) AS follower_percentile_rank,
        ROUND(engagement_percentile * 100, 1) AS engagement_percentile_rank,
        ROUND(engagement_generated / NULLIF(follower_count, 0), 2) AS interaction_to_follower_multiplier
    FROM percentile_rankings
    WHERE engagement_percentile >= 0.80 
      AND follower_percentile <= 0.50
    ORDER BY interaction_to_follower_multiplier DESC
    LIMIT 15
)
SELECT
    user_id,
    account_type,
    follower_count,
    engagement_generated,
    follower_percentile_rank,
    engagement_percentile_rank,
    interaction_to_follower_multiplier,
    COUNT(*) OVER () AS breakout_creator_count,
    SUM(CASE WHEN account_type = 'Personal' THEN 1 ELSE 0 END) OVER () AS personal_account_count,
    ROUND(SUM(CASE WHEN account_type = 'Personal' THEN 1 ELSE 0 END) OVER () 
        / COUNT(*) OVER () * 100, 1) AS pct_personal_accounts
FROM breakout_creators
ORDER BY interaction_to_follower_multiplier DESC;

-- QUESTION 16  How does the cumulative usage of the top 5 trending hashtags evolve over time, and are they currently accelerating or decelerating in popularity?
WITH top_platform_hashtags AS (
    SELECT hashtag_key
    FROM fact_hashtag_usage
    GROUP BY hashtag_key
    ORDER BY SUM(usage_count) DESC
    LIMIT 5
),
monthly_usage_aggregation AS (
    SELECT
        hu.hashtag_key,
        d.calendar_year,
        d.calendar_month,
        d.month_name,
        SUM(hu.usage_count) AS monthly_uses
    FROM fact_hashtag_usage hu
    JOIN dim_date d ON hu.usage_date_key = d.date_key
    JOIN top_platform_hashtags th ON hu.hashtag_key = th.hashtag_key
    GROUP BY 
        hu.hashtag_key, 
        d.calendar_year, 
        d.calendar_month, 
        d.month_name
),
hashtag_trajectory_metrics AS (
    SELECT
        mua.hashtag_key,
        mua.calendar_year,
        mua.calendar_month,
        mua.month_name,
        mua.monthly_uses,
        SUM(mua.monthly_uses) OVER (
            PARTITION BY mua.hashtag_key
            ORDER BY mua.calendar_year, mua.calendar_month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_lifetime_uses,
        LAG(mua.monthly_uses, 1) OVER (
            PARTITION BY mua.hashtag_key
            ORDER BY mua.calendar_year, mua.calendar_month
        ) AS previous_month_uses
    FROM monthly_usage_aggregation mua
)
SELECT
    h.hashtag_text,
    htm.calendar_year,
    htm.month_name,
    htm.monthly_uses,
    htm.cumulative_lifetime_uses,
    htm.monthly_uses - IFNULL(htm.previous_month_uses, 0) AS usage_velocity_change,
    CASE
        WHEN htm.previous_month_uses IS NULL THEN 'Initial Emergence'
        WHEN htm.monthly_uses > htm.previous_month_uses THEN 'Accelerating Trend'
        WHEN htm.monthly_uses < htm.previous_month_uses THEN 'Decelerating Trend'
        ELSE 'Plateaued Activity'
    END AS trend_lifecycle_status
FROM hashtag_trajectory_metrics htm
JOIN dim_hashtag h ON htm.hashtag_key = h.hashtag_key
ORDER BY 
    h.hashtag_text, 
    htm.calendar_year, 
    htm.calendar_month;



