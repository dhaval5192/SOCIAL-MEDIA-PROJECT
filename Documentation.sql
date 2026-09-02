-- ==============================================================================
-- SOCIAL MEDIA ANALYTICS SCHEMA DOCUMENTATION
-- ==============================================================================

-- ==============================================================================
-- 1. DIMENSION TABLES (Context & Entities)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Table: dim_date
-- Purpose: Stores calendar context to group, slice, and filter metrics by day, 
--          week, month, quarter, or year without runtime date calculations.
-- ------------------------------------------------------------------------------
-- Columns:
-- date_key          : Integer primary key formatted as YYYYMMDD (e.g., 20260831). Joins directly to fact tables.
-- full_date         : Complete standard date value (YYYY-MM-DD) for display and standard calculations.
-- calendar_year     : Four-digit year number used for annual reporting.
-- calendar_quarter  : Quarter number (1 through 4) for quarterly performance tracking.
-- calendar_month    : Month number (1 through 12) for chronological ordering.
-- month_name        : Full English month name (e.g., August) for charts and dashboard labels.
-- day_of_month      : Day number within the month (1 through 31).
-- day_of_week       : Day number within the week (1 through 7).
-- day_name          : Full English day name (e.g., Monday) for day-of-week usage analysis.
-- is_weekend        : Indicator (true/false or 1/0) showing whether the date is a Saturday or Sunday.


-- ------------------------------------------------------------------------------
-- Table: dim_user
-- Purpose: Stores profile information and attributes of platform users who create 
--          posts or interact with content.
-- ------------------------------------------------------------------------------
-- Columns:
-- user_key          : Warehouse-managed surrogate key to uniquely identify user dimension records over time.
-- original_user_id  : Original business ID from the source system to trace back to source data.
-- username          : User handle or account name.
-- account_type      : Classification category of the account (e.g., Personal, Creator, Business).
-- is_verified       : Indicator showing if the account holds a verified status badge.
-- country           : Geographical country location linked to the user profile.


-- ------------------------------------------------------------------------------
-- Table: dim_post
-- Purpose: Stores metadata, media attributes, and structural characteristics of 
--          published content.
-- ------------------------------------------------------------------------------
-- Columns:
-- post_key          : Warehouse-managed surrogate key uniquely identifying each content asset.
-- original_post_id  : Original business post ID from the source transactional system.
-- post_type         : Content format classification (e.g., Image, Carousel, Reel, Video).
-- media_url         : Web link pointing to the stored image or video file.
-- caption_length    : Total character count of the post caption text.
-- has_audio         : Indicator showing whether the post contains an active audio or music track.


-- ------------------------------------------------------------------------------
-- Table: dim_hashtag
-- Purpose: Stores unique hashtags and tags used across content on the platform.
-- ------------------------------------------------------------------------------
-- Columns:
-- hashtag_key       : Warehouse-managed surrogate key uniquely identifying each tag.
-- hashtag_text      : The actual string value of the hashtag without special characters (e.g., photography, travel).


-- ==============================================================================
-- 2. FACT TABLES (Events & Metrics)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Table: fact_post_creation
-- Purpose: Captures content publishing events, linking content creators to their 
--          posts and creation dates.
-- ------------------------------------------------------------------------------
-- Columns:
-- author_user_key   : References the user dimension record for the account that published the post.
-- post_key          : References the post dimension record for the created piece of content.
-- creation_date_key : References the date dimension record for the day the post was published.
-- post_count        : Additive metric (default value of 1) used to sum the total volume of published posts.


-- ------------------------------------------------------------------------------
-- Table: fact_engagement
-- Purpose: Captures individual user interactions (likes, comments, shares) made 
--          on published content.
-- ------------------------------------------------------------------------------
-- Columns:
-- actor_user_key    : References the user dimension record for the person taking the action.
-- post_key          : References the post dimension record receiving the interaction.
-- interaction_date_key : References the date dimension record for when the action occurred.
-- interaction_type  : Categorization label for the action taken (e.g., Like, Comment, Share).
-- interaction_count : Additive metric (default value of 1) used to sum total interaction volume.


-- ------------------------------------------------------------------------------
-- Table: fact_network
-- Purpose: Captures relationship changes (follows and unfollows) between users to 
--          track network growth over time.
-- ------------------------------------------------------------------------------
-- Columns:
-- follower_user_key : References the user dimension record for the person initiating the follow action.
-- followed_user_key : References the user dimension record for the person being followed.
-- action_date_key   : References the date dimension record for when the relationship change occurred.
-- network_action    : Classification label for the event type (e.g., Follow, Unfollow).
-- is_active_follow  : Numeric status flag (1 for active follow, 0 for unfollowed) used to calculate net active followers.


-- ------------------------------------------------------------------------------
-- Table: fact_hashtag_usage
-- Purpose: Connects posts directly to the individual hashtags applied to them 
--          for topic and trend analysis.
-- ------------------------------------------------------------------------------
-- Columns:
-- post_key          : References the post dimension record containing the tag.
-- hashtag_key       : References the hashtag dimension record being applied.
-- usage_date_key    : References the date dimension record for when the tag was posted.
-- usage_count       : Additive metric (default value of 1) used to calculate total usage frequency per hashtag.