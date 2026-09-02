USE social_media;

-- ==============================================================================
-- 1. DIMENSION TABLES
-- ==============================================================================

-- Calendar Dimension
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

-- User Dimension
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

-- Post Dimension
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

-- Hashtag Dimension
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/SocialMediaAnalytics/dim_hashtag.csv'
INTO TABLE dim_hashtag
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    hashtag_key,
    hashtag_text
);



-- ==============================================================================
-- 2. FACT TABLES
-- ==============================================================================

-- Post Creation Fact
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

-- Engagement Fact
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

-- Follower Network Fact
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

-- Hashtag Usage Fact
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