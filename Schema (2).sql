-- ==============================================================================
-- SOCIAL MEDIA ANALYTICS DATA WAREHOUSE SCHEMA (MYSQL VERSION)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. DIMENSION TABLES (The Context)
-- ------------------------------------------------------------------------------

-- Calendar Dimension
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

-- User Dimension
CREATE TABLE dim_user (
    user_key INT AUTO_INCREMENT PRIMARY KEY, -- Surrogate Key
    original_user_id VARCHAR(50) NOT NULL,   -- Business Key (from OLTP)
    username VARCHAR(100),
    account_type VARCHAR(20),                -- e.g., 'Personal', 'Creator', 'Business'
    is_verified BOOLEAN,
    country VARCHAR(50)
);

-- Post Dimension
CREATE TABLE dim_post (
    post_key INT AUTO_INCREMENT PRIMARY KEY, -- Surrogate Key
    original_post_id VARCHAR(50) NOT NULL,   -- Business Key (from OLTP)
    post_type VARCHAR(20),                   -- e.g., 'Image', 'Carousel', 'Reel', 'Video'
    media_url VARCHAR(500),
    caption_length INT,
    has_audio BOOLEAN
);

-- Hashtag Dimension
CREATE TABLE dim_hashtag (
    hashtag_key INT AUTO_INCREMENT PRIMARY KEY, -- Surrogate Key
    hashtag_text VARCHAR(100) UNIQUE
);


-- ------------------------------------------------------------------------------
-- 2. FACT TABLES (The Events & Metrics)
-- ------------------------------------------------------------------------------

-- Post Creation Fact (Connects Author to Post)
CREATE TABLE fact_post_creation (
    author_user_key INT,
    post_key INT,
    creation_date_key INT,
    post_count INT DEFAULT 1,
    FOREIGN KEY (author_user_key) REFERENCES dim_user(user_key),
    FOREIGN KEY (post_key) REFERENCES dim_post(post_key),
    FOREIGN KEY (creation_date_key) REFERENCES dim_date(date_key)
);

-- Engagement Fact (Likes, Comments, Shares)
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

-- Follower Network Fact (Followers & Following)
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

-- Hashtag Usage Fact (Bridge Fact for Posts and Hashtags)
CREATE TABLE fact_hashtag_usage (
    post_key INT,
    hashtag_key INT,
    usage_date_key INT,
    usage_count INT DEFAULT 1,
    FOREIGN KEY (post_key) REFERENCES dim_post(post_key),
    FOREIGN KEY (hashtag_key) REFERENCES dim_hashtag(hashtag_key),
    FOREIGN KEY (usage_date_key) REFERENCES dim_date(date_key)
);
