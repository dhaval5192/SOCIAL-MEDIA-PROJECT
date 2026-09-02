-- =============================================================================
-- SOCIAL MEDIA ANALYTICS EXPLORATORY DATA ANALYSIS
-- =============================================================================
-- Database: MySQL 8.0
-- Purpose: Business-focused exploratory analysis for decision-making
-- Portfolio Project: Data Analyst
-- Note: All user-level references use the non-identifying surrogate key 
--       (user_id) from dim_user. No usernames or other personally 
--       identifiable information are queried or displayed.
-- =============================================================================

-- =============================================================================
-- CATEGORY 1: CONTENT AND PUBLISHING PERFORMANCE
-- =============================================================================

-- -----------------------------------------------------------------------------
-- QUESTION 1
-- -----------------------------------------------------------------------------
-- INFO:
-- Content format strategy heavily dictates resource allocation. 
-- Decision-makers need to understand which content formats are being published most frequently and the current adoption rate of audio-enhanced content.
-- 
-- QUESTION:
-- What is the breakdown of content formats being published, and what percentage of total posts include an active audio track?
-- 
-- QUERY:
SELECT
    post_type,
    COUNT(post_key) AS total_posts_published,
    ROUND(COUNT(post_key) * 100.0 / SUM(COUNT(post_key)) OVER (), 2) AS pct_of_total_posts,
    SUM(CASE WHEN has_audio = 1 THEN 1 ELSE 0 END) AS posts_with_audio,
    ROUND(SUM(CASE WHEN has_audio = 1 THEN 1 ELSE 0 END) / COUNT(post_key) * 100, 2) AS audio_adoption_pct
FROM dim_post
GROUP BY post_type
ORDER BY total_posts_published DESC;

-- INSIGHTS:
-- ---------------------------------------------------------------------------
-- 1. EXECUTIVE FINDING: STATIC & CAROUSEL AUDIO ADOPTION IS STALLED AT ~50%
--    Observation: Images (40.77%, n=2,446) and carousels (20.10%, n=1,206)
--                 together comprise 60.87% of published content, but audio adoption
--                 for both formats is stalled near 50% (49.14% and 50.91% 
--                 respectively), versus 100% adoption on video formats.
--    Explanation: Unlike video formats that require sound, half of non-video posts
--                 lack audio metadata, which reduces their reach in sound-driven
--                 discovery feeds and leaves session-length benefits (e.g., on
--                 swipeable carousels) only partially captured.
--    Recommendation: Product Operations should deploy smart audio prompts during
--                    the upload flow, paired with targeted creator education, to 
--                    raise non-video audio adoption toward 75%+.
--
-- 2. EXECUTIVE FINDING: VIDEO CATEGORY ALIGNMENT & REPORTING SIMPLIFICATION
--    Observation: Video inventory is split between legacy Video (9.45%, n=567) 
--                 and Reel (29.68%, n=1,781), despite both displaying identical
--                 100% audio usage rates.
--    Explanation: Maintaining duplicate video categories creates inconsistencies
--                 in executive performance dashboards, distorts content trend
--                 analysis, and increases administrative reporting overhead.
--    Recommendation: Operations and Business Analytics should standardize content
--                    definitions to consolidate legacy Video under the Reel classification.
-- ---------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- QUESTION 2
-- -----------------------------------------------------------------------------
-- INFO:
-- Understanding content velocity over time helps marketing and operational 
-- teams anticipate peak platform activity and plan strategic campaigns.
-- 
-- QUESTION:
-- How does the overall volume of published content fluctuate across 
-- different months and quarters of the year?
-- 
-- QUERY:
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

-- INSIGHTS:
-- ---------------------------------------------------------------------------
-- 1. EXECUTIVE FINDING: MID-YEAR PUBLISHING VELOCITY PEAK (Q2/Q3)
--    Observation: Content creation swells during Q2 (n=1,518; 25.30%) and Q3 
--                 (n=1,545; 25.75%), representing 51.05% of total annual output 
--                 (n=6,000) with monthly peaks in May (n=530) and July (n=529).
--    Explanation: Late spring and summer months drive higher creator participation 
--                 and lifestyle content capture, creating a predictable seasonal surge.
--    Recommendation: Marketing Operations should concentrate high-priority brand 
--                    sponsorships and major promotional campaigns in Q2-Q3 to leverage 
--                    peak platform activity and higher content velocity.
--
-- 2. EXECUTIVE FINDING: WINTER PRODUCTION SLUMP (Q4/Q1)
--    Observation: Publishing volume declines to annual lows during Q1 (n=1,447; 24.12%), 
--                 bottoming out in February (n=469; 11.5% below May peak) and remaining 
--                 subdued through late Q4 (Nov-Dec average: 489 posts/month).
--    Explanation: Post-holiday fatigue and year-end holiday schedules temporarily 
--                 reduce creator publishing frequency between November and February.
--    Recommendation: Creator Operations should roll out post-holiday incentive campaigns 
--                    and content scheduling features in Q1 to stabilize creator 
--                    activity and prevent seasonal drop-offs.
--
-- 3. EXECUTIVE FINDING: PREDICTABLE INVENTORY BASELINE & LOW VOLATILITY
--    Observation: Monthly content creation demonstrates high operational stability, 
--                 maintaining an average baseline of 500 posts/month across the year 
--                 with minimal fluctuation (+/- 6.1% from the mean).
--    Explanation: The active user base maintains a highly habitual publishing routine, 
--                 providing a stable, low-risk content supply for advertising monetization.
--    Recommendation: Monetization Strategy teams can rely on this steady inventory 
--                    supply for predictable ad-slot pricing and revenue forecasting while 
--                    setting a 10% volume growth target for the low-velocity winter months.
-- ---------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- QUESTION 3
-- -----------------------------------------------------------------------------
-- INFO:
-- Scheduling and automated publishing tools depend on knowing when users 
-- are historically most active in generating content.
-- 
-- QUESTION:
-- Is there a significant difference in daily publishing volume when comparing 
-- weekdays to weekends?
-- 
-- QUERY:
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

-- INSIGHTS:
-- ---------------------------------------------------------------------------
-- 1. EXECUTIVE FINDING: EQUIVALENT DAILY PUBLISHING VELOCITY ACROSS ALL DAYS
--    Observation: Daily content output is virtually identical between Weekdays 
--                 (16.49 posts/day; n=4,287 over 260 days) and Weekends (16.31 
--                 posts/day; n=1,713 over 105 days), showing a negligible variance 
--                 of only 1.09% (0.18 posts/day).
--    Explanation: User content creation behavior is habituated into a daily routine 
--                 rather than being tied to work-week or leisure cycles, demonstrating 
--                 consistent platform dependency year-round.
--    Recommendation: Product Operations and Infrastructure teams should avoid shifting 
--                    heavy system maintenance or batch processing to weekends under 
--                    the assumption of lower traffic, as platform activity remains steady.
--
-- 2. EXECUTIVE FINDING: WEEKDAY TOTAL VOLUME DOMINANCE DUE TO CALENDAR SHARE
--    Observation: Weekdays capture 71.45% of total annual content volume (n=4,287), 
--                 driven solely by representing 71.23% of the calendar year (260 days), 
--                 not by higher per-day posting intensity.
--    Explanation: Aggregate weekly metrics can give a false impression of weekday 
--                 dominance; analyzing per-day density proves individual weekend days 
--                 match weekday productivity.
--    Recommendation: Business Intelligence should mandate normalized daily averages 
--                 (posts/day) across all executive reporting rather than total sum 
--                 aggregates to prevent misinterpretation of user activity levels.
-- ---------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- QUESTION 4
-- -----------------------------------------------------------------------------
-- INFO:
-- Copywriting efforts vary widely by content format. Understanding baseline 
-- caption behavior helps establish best practices for content creators.
-- 
-- QUESTION:
-- How does caption length distribute across different content types, and are 
-- certain formats consistently more text-heavy than others?
-- 
-- QUERY:
SELECT
    post_type,
    MIN(caption_length) AS shortest_caption_chars,
    MAX(caption_length) AS longest_caption_chars,
    ROUND(AVG(caption_length), 0) AS avg_caption_length
FROM dim_post
GROUP BY post_type
ORDER BY avg_caption_length DESC;

-- INSIGHTS:
-- ---------------------------------------------------------------------------
-- 1. EXECUTIVE FINDING: UNIFORM CAPTION BEHAVIOR & SHORT-FORM TEXT LEADERSHIP
--    Observation: Average caption lengths are remarkably uniform across all formats 
--                 (~1,080 to 1,145 characters), with Reels leading slightly at an 
--                 average of 1,145 characters—5.8% longer than standard Video (1,080 chars).
--    Explanation: Creators actively leverage longer captions on video assets (Reels) 
--                 to provide context, storytelling, or keyword-dense descriptions that 
--                 supplement visual content and improve search indexability.
--    Recommendation: Creator Operations should promote long-form caption best practices 
--                    (1,000+ characters) for Reels to maximize algorithmic discovery 
--                    and search relevance across short-form video feeds.
--
-- 2. EXECUTIVE FINDING: EXTREME CAPTION LENGTH DIVERGENCE & ZERO-TEXT UTILIZATION
--    Observation: All content formats exhibit extreme caption length ranges, spanning 
--                 from 0–2 characters at the minimum to ~2,200 characters at the maximum 
--                 (near platform character caps).
--    Explanation: Content strategies are heavily bifurcated between minimal, aesthetic 
--                 posting (zero/low text) and micro-blogging or detailed educational 
--                 posting (2,000+ characters).
--    Recommendation: Product Development should introduce structured caption templates 
--                    and AI copywriting assistants to help minimalist creators expand 
--                    short captions into search-optimized copy.
-- ---------------------------------------------------------------------------


-- =============================================================================
-- CATEGORY 2: ENGAGEMENT AND AUDIENCE BEHAVIOR
-- =============================================================================

-- -----------------------------------------------------------------------------
-- QUESTION 5
-- -----------------------------------------------------------------------------
-- INFO:
-- Not all published content drives equivalent engagement. Identifying the 
-- formats that yield the highest return on interaction informs future 
-- content production investments.
-- 
-- QUESTION:
-- Which specific content formats generate the highest average engagement 
-- volume per individual post?
-- 
-- QUERY:
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

-- INSIGHTS:
-- ---------------------------------------------------------------------------
-- 1. EXECUTIVE FINDING: UNIFORM FORMAT PERFORMANCE WITH SLIGHT VIDEO OUTPERFORMANCE
--    Observation: Average engagement per post remains tightly clustered across all 
--                 formats (2.68 to 2.81 interactions/post), with legacy Video leading 
--                 slightly at 2.81—3.7% above the overall platform average (~2.71).
--    Explanation: Interaction yield per asset is balanced across formats, indicating 
--                 that content distribution algorithms distribute engagement uniformly 
--                 regardless of whether the media type is static or video.
--    Recommendation: Content Strategy teams should maintain a diversified format mix 
--                    rather than over-indexing purely on video production, as static 
--                    and multi-frame assets yield nearly identical engagement density.
--
-- 2. EXECUTIVE FINDING: REELS & IMAGES DRIVE 82% OF TOTAL ENGAGEMENT VOLUME
--    Observation: Total platform interactions (n=14,999) are heavily dominated by 
--                 Images (40.64%, n=6,096) and Reels (29.90%, n=4,485), together 
--                 generating 70.54% of all platform engagement.
--    Explanation: High total engagement for Images and Reels is driven by sheer 
--                 publishing volume (n=2,253 and n=1,650 posts respectively) rather 
--                 than significantly higher per-post efficiency.
--    Recommendation: Creator Operations should incentivize creators to maintain high 
--                    publishing velocity on Images and Reels to safeguard baseline 
--                    platform interaction inventory for ad monetization.
--
-- 3. EXECUTIVE FINDING: CAROUSEL UNDERPERFORMANCE RELATIVE TO PRODUCTION EFFORT
--    Observation: Carousels generate the lowest average engagement (2.68 interactions/post; 
--                 n=2,985 total) despite being the most resource-intensive static asset.
--    Explanation: Users consume multi-frame content primarily via swipe duration (dwell 
--                 time) rather than explicitly tapping likes, comments, or shares.
--    Recommendation: Product Development should introduce interactive elements within 
--                    Carousels (e.g., inline polls, swipe stickers) to convert passive 
--                    dwell time into active interaction counts.
-- ---------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- QUESTION 6
-- -----------------------------------------------------------------------------
-- INFO:
-- Recognizing highly active unverified users ("super-fans" or emerging creators) 
-- is essential for community management, ambassadorship programs, and retention.
-- 
-- QUESTION:
-- Who are the top 10 most actively engaging non-verified users on the platform 
-- based on total interaction volume?
-- 
-- QUERY:
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

-- INSIGHTS:
-- ---------------------------------------------------------------------------
-- 1. EXECUTIVE FINDING: PERSONAL ACCOUNTS DRIVE TOP OUTGOING INTERACTION VOLUME
--    Observation: 70% of the top 10 most active non-verified users (n=7) hold 
--                 Personal account types, led by the top-ranked account 
--                 (15 interactions) and the second-ranked account (14 interactions).
--    Explanation: High interaction volume among non-verified personal accounts 
--                 signals core "super-fan" behavior—highly engaged power users who 
--                 consume and react to content heavily without monetizing their profiles.
--    Recommendation: Community Management should establish automated engagement 
--                    milestone rewards (e.g., top fan badges, early feature access) 
--                    to retain these organic power users and sustain platform activity.
--
-- 2. EXECUTIVE FINDING: EMERGING CREATOR & BUSINESS CONVERSION PIPELINE
--    Observation: Highly active non-verified users also include Creator accounts 
--                 (e.g., one account at 13 interactions) and Business accounts 
--                 (e.g., two accounts tied at 12 interactions each).
--    Explanation: Non-verified business and creator profiles with high engagement 
--                 represent active professional users who have not yet navigated 
--                 or qualified for official platform verification.
--    Recommendation: Creator Growth teams should build a proactive outreach funnel 
--                    targeting non-verified power accounts (10+ interactions) to 
--                    fast-track verification and boost creator retention.
--
-- 3. EXECUTIVE FINDING: GEOGRAPHICALLY DISPERSED SUPER-FAN BASE
--    Observation: Top active non-verified users span highly diverse international 
--                 markets (e.g., Netherlands, Nepal, Timor-Leste, Philippines, South Africa) 
--                 without regional concentration.
--    Explanation: Platform affinity and heavy engagement are globally distributed, 
--                 indicating strong organic user stickiness in developing and emerging markets.
--    Recommendation: International Product teams should ensure localization and low-bandwidth 
--                    performance optimization in these key growth regions to support 
--                    high-frequency power users.
-- ---------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- QUESTION 7
-- -----------------------------------------------------------------------------
-- INFO:
-- Audio integration can shift how users interact with content (e.g., more 
-- passive viewing vs. active commenting).
-- 
-- QUESTION:
-- What proportion of overall platform interactions do likes, comments, and shares 
-- represent when comparing posts with audio against posts without audio?
-- 
-- QUERY:
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

-- INSIGHTS:
-- ---------------------------------------------------------------------------
-- 1. EXECUTIVE FINDING: AUDIO CONTENT DRIVES ENGAGEMENT VOLUME SUPERIORITY
--    Observation: Content with audio generates 69.18% of total platform interactions 
--                 (n=10,376), outperforming non-audio content (30.82%, n=4,623) 
--                 by more than a 2.2x margin.
--    Explanation: Audio-enhanced media commands higher platform distribution and user 
--                 attention, yielding significantly higher total engagement volume.
--    Recommendation: Marketing Strategy should prioritize audio-backed creative formats 
--                    across major promotional campaigns to maximize reach and volume.
--
-- 2. EXECUTIVE FINDING: LIKES HEAVILY DOMINATE AUDIO CONTENT INTERACTION MIX
--    Observation: For audio content, Likes account for 52.15% of total platform 
--                 interactions (n=7,822), vastly outstripping Comments (10.14%, n=1,521) 
--                 and Shares (6.89%, n=1,033).
--    Explanation: Audio content induces low-friction passive consumption where users 
--                 frequently signal approval via Likes rather than high-friction actions.
--    Recommendation: Product Development should introduce interactive audio stickers and 
--                    in-stream comment prompts to convert passive Likes into Comments.
--
-- 3. EXECUTIVE FINDING: NON-AUDIO CONTENT SUFFERS FROM LOW SHAREABILITY
--    Observation: Non-audio content yields the lowest interaction volume across all 
--                 categories, bottoming out at Shares (2.95%, n=442) and Comments (4.47%, n=671).
--    Explanation: Static or silent media lacks the viral distribution dynamic of trending 
--                 audio, making users significantly less likely to share content externally.
--    Recommendation: Creator Operations should incentivize creators to attach audio tracks 
--                    to static posts to elevate baseline shareability and viral reach.
-- ---------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- QUESTION 8
-- -----------------------------------------------------------------------------
-- INFO:
-- Spikes in daily engagement dictate when community managers should be most 
-- active and when infrastructure loads are heaviest.
-- 
-- QUESTION:
-- Which specific days of the week consistently experience user engagement 
-- volumes that exceed the daily platform average?
-- 
-- QUERY:
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

-- INSIGHTS:
-- ---------------------------------------------------------------------------
-- 1. EXECUTIVE FINDING: MID-WEEK TO FRIDAY ENGAGEMENT PEAK (TUE-FRI), LED BY TUESDAY
--    Observation: Only four days—Tuesday (42/day, the platform-wide maximum; 
--                 n=2,173 across 52 occurrences), Friday (41/day), Wednesday 
--                 (41/day), and Thursday (41/day)—exceed the global platform 
--                 baseline average (~41.1 daily interactions).
--    Explanation: User engagement concentrates heavily mid-week through Friday, 
--                 creating a predictable 4-day window of heightened user activity, 
--                 with Tuesday marking the point of peak algorithmic distribution 
--                 for early-week content.
--    Recommendation: Community Management and Moderation teams should shift staff 
--                    rosters to prioritize coverage between Tuesday and Friday, and 
--                    Infrastructure Operations should avoid scheduling major system 
--                    deployments or maintenance on Tuesdays to prevent disruption 
--                    during peak traffic load.
--
-- 2. EXECUTIVE FINDING: WEEKEND & MONDAY ENGAGEMENT DEFICIT
--    Observation: Monday, Saturday, and Sunday are excluded from the results because 
--                 their daily averages fall strictly below the platform average threshold.
--    Explanation: User interaction drops over weekends and early Mondays due to 
--                 offline lifestyle patterns and work-week transitions.
--    Recommendation: Marketing Operations should schedule platform notifications and 
--                    re-engagement campaigns on Monday mornings to stimulate 
--                    early-week interaction volume.
-- ---------------------------------------------------------------------------


-- =============================================================================
-- CATEGORY 3: USER, ACCOUNT, AND NETWORK GROWTH
-- =============================================================================

-- -----------------------------------------------------------------------------
-- QUESTION 9
-- -----------------------------------------------------------------------------
-- INFO:
-- The follower-to-following ratio is a primary indicator of account influence 
-- and audience dynamic. Variations across account types highlight differing 
-- platform usage strategies.
-- 
-- QUESTION:
-- What is the aggregate ratio of followers to following for different 
-- account types (Personal, Creator, Business)?
-- 
-- QUERY:
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

-- INSIGHTS:
-- ---------------------------------------------------------------------------
-- 1. EXECUTIVE FINDING: BUSINESS ACCOUNTS LEAD AS NET NETWORK INFLUENCERS
--    Observation: Business accounts generate the highest aggregate ratio at 1.07 
--                 (4,384 followers vs. 4,101 following), standing out as the only 
--                 category where audience size exceeds outgoing follows.
--    Explanation: Commercial accounts naturally command net audience growth 
--                 as platform users follow brand profiles for products, updates, 
--                 and customer support without expecting reciprocal follows.
--    Recommendation: Brand Growth teams should leverage this authority signal 
--                    by incentivizing Business accounts to utilize promoted posts 
--                    and ad tools to expand their follower base further.
--
-- 2. EXECUTIVE FINDING: PERSONAL ACCOUNTS MAINTAIN BALANCED RECIPROCAL NETWORKS
--    Observation: Personal profiles demonstrate a perfectly balanced 1.00 ratio 
--                 (2,775 followers vs. 2,766 following; ~50% total network volume).
--    Explanation: Everyday individual users operate on a strict "follow-for-follow" 
--                 reciprocal dynamic within peer-to-peer friend and acquaintance networks.
--    Recommendation: Product Development should maintain friend-suggestion features 
--                    and contact-sync onboarding to preserve low-friction mutual 
--                    connections among personal account holders.
--
-- 3. EXECUTIVE FINDING: CREATOR ACCOUNTS SUFFER FROM DEFICIT NETWORK RATIOS
--    Observation: Creator profiles exhibit a deficit ratio of 0.95 (776 followers 
--                 vs. 813 following), maintaining more outgoing follows than audience.
--    Explanation: Emerging creators actively follow other accounts to build network 
--                 visibility, but struggle to convert that outreach into incoming followers.
--    Recommendation: Creator Operations should provide growth toolkits and profile 
--                    optimization guidelines to help non-verified creators convert 
--                    profile views into net follower growth.
-- ---------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- QUESTION 10
-- -----------------------------------------------------------------------------
-- INFO:
-- Regional platform health requires a balance between content creation and 
-- consumption. Markets with high engagement but low creation may represent 
-- strategic expansion opportunities.
-- 
-- QUESTION:
-- How does the ratio of user engagement to content creation vary across 
-- different geographic regions (countries)?
-- 
-- QUERY:
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

-- INSIGHTS:
-- ---------------------------------------------------------------------------
-- 1. EXECUTIVE FINDING: EXTREME CONSUMPTION OUTLIERS DRIVEN BY SMALL-MARKET USERS
--    Observation: Honduras leads global engagement-to-creation density with a 10.00 
--                 ratio (20 posts vs. 200 interactions across 2 users), followed by 
--                 Nauru (5.57 ratio) and Moldova (5.55 ratio), compared to a platform 
--                 baseline range of 2.00–3.00.
--    Explanation: Smaller, emerging user clusters demonstrate highly active content 
--                 consumption relative to publishing output, signaling strong organic 
--                 content demand that outpaces local creator inventory.
--    Recommendation: Strategic Expansion teams should target creator acquisition 
--                    campaigns in high-ratio markets (Honduras, Nauru, Moldova) to 
--                    supply local creators and capture under-monetized engagement.
--
-- 2. EXECUTIVE FINDING: CORE COMMERCIAL MARKETS EXHIBIT CREATION-HEAVY DYNAMICS
--    Observation: Major established user bases show significantly lower ratios, 
--                 including the United States (1.91 ratio; n=35 posts, 67 interactions), 
--                 India (1.94 ratio), France (1.76 ratio), and Indonesia (1.76 ratio).
--    Explanation: High creator density and active publishing behavior in mature 
--                 geographies dilute aggregate engagement-per-post ratios, creating 
--                 a hyper-competitive environment for audience attention.
--    Recommendation: Product Marketing should deploy reach-boosting tools and paid 
--                    amplification features in saturated markets (US, India, France) 
--                    to help creators break through high publishing volume.
--
-- 3. EXECUTIVE FINDING: ENGAGEMENT DEFICIT IN SELECT CREATOR-DOMINATED REGIONS
--    Observation: Low-ratio markets at the bottom of the spectrum—such as Guam (1.00 ratio), 
--                 Saint Lucia (1.21 ratio), and Iraq (1.50 ratio)—generate nearly equal 
--                 posts and interactions (e.g., Guam: 22 posts vs. 22 interactions).
--    Explanation: High post creation paired with minimal audience reaction indicates 
--                 either a breakdown in local feed distribution algorithms or a lack 
--                 of active consumer accounts in these sub-regions.
--    Recommendation: Growth Engineering should review content distribution pipelines 
--                    in under-engaging regions to ensure locally produced content 
--                    is effectively served to relevant target audiences.
-- ---------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- QUESTION 11
-- -----------------------------------------------------------------------------
-- INFO:
-- Verification badges are intended to signal trust. Measuring whether verified 
-- accounts actually experience lower audience churn validates this assumption.
-- 
-- QUESTION:
-- How does the verification status of an account impact its ability to attract 
-- active followers and its historical follower churn rate?
-- 
-- QUERY:
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

-- INSIGHTS:
-- ---------------------------------------------------------------------------
-- 1. EXECUTIVE FINDING: VERIFIED BADGES DRIVE AUDIENCE SCALE & ACQUISITION LEVERAGE
--    Observation: Verified accounts command 1,203 active followers per profile 
--                 (n=20,453 across 17 accounts)—over 54x the average follower size 
--                 of unverified profiles (22 followers/account; n=22,242 across 992 accounts).
--    Explanation: Verification badges act as strong authority signals in search, 
--                 recommendation algorithms, and discovery feeds, driving high-volume 
--                 organic follower acquisition.
--    Recommendation: Creator Growth teams should establish clear verification pathways 
--                    for high-potential creators to accelerate audience growth and 
--                    boost overall platform retention.
--
-- 2. EXECUTIVE FINDING: VERIFIED PROFILES SUFFER HIGHER FOLLOWER CHURN THAN UNVERIFIED PEERS
--    Observation: Verified accounts experience a higher network churn rate at 25.52% 
--                 (unfollows relative to total gross follows) compared to 22.32% for 
--                 unverified profiles—a 3.20 percentage point gap—even though unverified 
--                 accounts hold the larger share of total active followers (52.1%, n=22,242).
--    Explanation: Larger follower bases attract passive or casual audience members who 
--                 churn at higher rates when content strategy or publishing frequency 
--                 shifts, whereas smaller unverified accounts tend to build close-knit, 
--                 reciprocal peer networks with lower unfollow friction.
--    Recommendation: Product Operations should build audience re-engagement alerts and 
--                    churn-analytics dashboards specifically for verified accounts, while 
--                    Community Management tests peer-to-peer engagement features within 
--                    stable unverified user circles.
-- ---------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- QUESTION 12
-- -----------------------------------------------------------------------------
-- INFO:
-- Overall network health is measured by the continuous addition of net-new 
-- social connections. Tracking this sequentially alerts leadership to 
-- accelerating growth or structural plateaus.
-- 
-- QUESTION:
-- What is the month-over-month trajectory of net-new active follow relationships 
-- established across the entire platform?
-- 
-- QUERY:
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

-- INSIGHTS:
-- ---------------------------------------------------------------------------
-- 1. EXECUTIVE FINDING: MID-YEAR SURGE & HIGH-VOLUME EXPANSION (MAY & AUGUST)
--    Observation: Network expansion peaks during May (n=366 net connections; +8.28% MoM) 
--                 and August (n=361 net connections; +4.34% MoM), driving strong 
--                 seasonal user discovery during late spring and summer months.
--    Explanation: Elevated user activity and increased content publishing during 
--                 Q2 and Q3 naturally accelerate account discovery and new follow 
--                 relationship creation.
--    Recommendation: Marketing Strategy should execute user acquisition and brand 
--                    partnership campaigns during these high-growth periods to maximize 
--                    organic network density.
--
-- 2. EXECUTIVE FINDING: RECURRING POST-SUMMER CONTRACTION (SEPTEMBER DIP)
--    Observation: September experiences the sharpest single-month contraction of the 
--                 year (-17.73% MoM; dropping by 64 net connections to a low of 297), 
--                 following a similar early-year dip in February (-9.88% MoM; n=292).
--    Explanation: Seasonal transitions (e.g., return-to-school/work routines in autumn) 
--                 temporarily reduce active browsing and new profile discovery.
--    Recommendation: Product Growth teams should deploy targeted re-engagement pushes 
--                    and follow-recommendation prompts in late Q3 to mitigate seasonal 
--                    drop-offs in network expansion.
--
-- 3. EXECUTIVE FINDING: STABLE ANNUAL NETWORK GROWTH WITH RESILIENT Q4 RECOVERY
--    Observation: Total net-new active connections reach 3,990 across the year, 
--                 maintaining a consistent baseline average of ~332 connections/month 
--                 and rebounding strongly in December (+10.58% MoM; n=345).
--    Explanation: Strong year-end recovery demonstrates healthy core network retention 
--                 and platform resilience, balancing out mid-year seasonal fluctuations.
--    Recommendation: Executive Leadership can rely on steady ~3,900+ annual net-new 
--                 connection growth for long-term user retention models and ad placement 
--                 forecasts.
-- ---------------------------------------------------------------------------


-- =============================================================================
-- CATEGORY 4: HASHTAG, TREND, AND STRATEGIC GROWTH OPPORTUNITIES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- QUESTION 13
-- -----------------------------------------------------------------------------
-- INFO:
-- High-volume usage doesn't always guarantee high engagement. Identifying tags 
-- that punch above their weight class provides actionable recommendations for 
-- content optimization.
-- 
-- QUESTION:
-- Which highly utilized hashtags are driving the most significant engagement, 
-- and how do they rank against their peers in the top usage quartile?
-- 
-- QUERY:
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

-- INSIGHTS:
-- ---------------------------------------------------------------------------
-- 1. EXECUTIVE FINDING: TOP QUARTILE HASHTAG EFFICIENCY CLUSTERS TIGHTLY NEAR 1.00
--    Observation: The top 15 most-used hashtags (Quartile 1) maintain an extremely 
--                 tight engagement efficiency spread of 0.94 to 1.00, led by #which 
--                 (1.00 ratio; Rank 2) and #speak (1.00 ratio; Rank 6), with no 
--                 significant drop-off in per-application returns across the tier.
--    Explanation: High-frequency hashtags capture steady, proportional interaction 
--                 returns relative to post volume, and high platform adoption does 
--                 not dilute performance—making these tags dependable anchors for 
--                 baseline algorithmic categorization and reach.
--    Recommendation: Content Strategy should establish these top-quartile hashtags 
--                    as core tagging templates, and Product Development can safely 
--                    expand auto-suggested hashtag features using them without 
--                    risking engagement decay.
--
-- 2. EXECUTIVE FINDING: DISCREPANCY BETWEEN USAGE VOLUME AND ABSOLUTE ENGAGEMENT
--    Observation: Usage volume among Quartile 1 tags ranges from 62 to 76 applications, 
--                 yet absolute engagement ranking varies significantly—e.g., #rock 
--                 ranks 1st globally (75 interactions; 76 posts) while #economic 
--                 drops to 10th rank (64 interactions; 68 posts; 0.94 efficiency).
--    Explanation: Broad or generic utility tags (e.g., #economic) suffer from lower 
--                 topic alignment, yielding lower engagement conversion per usage 
--                 compared to expressive lifestyle tags (e.g., #rock, #which).
--    Recommendation: Creator Education teams should advise creators against relying 
--                    solely on generic tags and encourage pairing high-volume tags 
--                    with niche, high-intent micro-hashtags.
-- ---------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- QUESTION 14
-- -----------------------------------------------------------------------------
-- INFO:
-- Daily fluctuations can hide macro-trends. Applying a rolling average smooths 
-- out the noise, making true engagement momentum and viral spikes clearly visible.
-- 
-- QUESTION:
-- What is the rolling 7-day average of platform-wide interactions, and how does 
-- daily performance deviate from this trend line?
-- 
-- QUERY:
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

-- INSIGHTS:
-- ---------------------------------------------------------------------------
-- 1. EXECUTIVE FINDING: STABLE BASELINE MONOTONY WITH LOW VOLATILITY
--    Observation: Over 93.5% of the December trailing sample (29 out of 31 days) 
--                 operates strictly within the "Stable Baseline" performance corridor, 
--                 with the 7-day rolling average anchoring tightly between 38 and 45 
--                 interactions/day.
--    Explanation: Platform consumption exhibits highly predictable engagement patterns, 
--                 meaning overall interaction throughput is driven by habitual user 
--                 routines rather than wild, unpredictable platform-wide swings.
--    Recommendation: Capacity Planning & Infrastructure teams can rely on the ~41 
--                    daily interaction baseline for server load provisioning without 
--                    needing massive elasticity headroom for frequent viral spikes.
--
-- 2. EXECUTIVE FINDING: ISOLATED DOWNSIDE DROPS DURING HOLIDAY/WEEKEND PERIODS
--    Observation: Only two notable outliers occurred in December: December 15th 
--                 (27 interactions; -12 vs. trend) and December 30th (25 interactions; 
--                 -15 vs. trend), both triggering "Negative Drop" flags (<75% of 7D avg).
--    Explanation: Drops align directly with key pre-holiday travel and holiday weekend 
--                 windows where offline user activity naturally competes with platform 
--                 session duration.
--    Recommendation: Marketing Operations should avoid launching major campaign 
--                    milestones or time-sensitive promotional activations on major 
--                    holiday eves to prevent underperforming reach metrics.
--
-- 3. EXECUTIVE FINDING: MID-WEEK RALLY DAYS NEAREST TO POSITIVE SPIKE THRESHOLD
--    Observation: Highest single-day volumes peaked at 49–51 interactions (e.g., Dec 5, 
--                 Dec 14, Dec 19), approaching the 1.25x "Positive Spike" threshold 
--                 (~51–53 interactions required) without breaching it.
--    Explanation: Mid-week content cycles regularly generate 15%–20% positive deviations 
--                 above trailing averages, signaling organic engagement momentum on 
--                 Tuesdays and Thursdays.
--    Recommendation: Ad Sales and Monetization teams should price premium sponsored 
--                    inventory higher during mid-week windows (Tuesday–Thursday) to 
--                    capture predictable positive momentum shifts above the rolling average.
-- ---------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- QUESTION 15
-- -----------------------------------------------------------------------------
-- INFO:
-- Sponsoring massive accounts is expensive. Finding "breakout creators" who 
-- command massive engagement relative to their small follower counts highlights 
-- underpriced partnership opportunities.
-- 
-- QUESTION:
-- Which users qualify as "breakout creators"—those who rank in the top 20% for 
-- content engagement but remain in the bottom 50% for total audience size?
-- 
-- QUERY:
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

-- INSIGHTS:
-- ---------------------------------------------------------------------------
-- 1. EXECUTIVE FINDING: PERSONAL PROFILES DOMINATE BREAKOUT EFFICIENCY
--    Observation: 80% of the qualifying breakout creators (n=12 out of 15) hold 
--                 Personal account classifications, led by the top-ranked account 
--                 (28.00x multiplier; 28 interactions across a single follower) and 
--                 the second-ranked account (24.00x multiplier).
--    Explanation: Non-commercial, personal profiles often post hyper-authentic, highly 
--                 relatable content that drives disproportionate viral engagement relative 
--                 to their micro-audience size.
--    Recommendation: Creator Partnerships teams should expand influencer scouting beyond 
--                    formal "Creator" account tags to include high-efficiency Personal profiles 
--                    for hyper-cost-effective micro-sponsorships.
--
-- 2. EXECUTIVE FINDING: MASSIVE ENGAGEMENT OUTLIERS IN THE BOTTOM AUDIENCE TIERS
--    Observation: Every identified breakout user resides in the bottom 5th percentile 
--                 for follower count (4.7th percentile; exactly 1 follower each) while 
--                 ranking in the top 3.3% globally for total earned engagement (96.7th to 99.9th percentile).
--    Explanation: Content distribution algorithms are actively divorcing asset reach 
--                 from follower counts, allowing high-quality posts to go viral across the 
--                 platform regardless of account baseline scale.
--    Recommendation: Brand Strategy should shift ad spend away from fixed flat-fee 
--                    follower-based sponsorships toward performance-tier contracts 
--                    that pay creators based on actual interaction multipliers.
--
-- 3. EXECUTIVE FINDING: HIGH CONVERSION POTENTIAL FOR EMERGING CREATOR PROFILES
--    Observation: Official Creator accounts within the breakout list generate 
--                 19–21 interactions per follower, with the three highest-ranked 
--                 creator accounts posting multipliers of 21.00x, 19.00x, and 19.00x.
--    Explanation: Emerging professional creators with small follower footprints possess 
--                 exceptional engagement density but lack audience distribution support.
--    Recommendation: Talent Development should enroll these high-multiplier creators 
--                    into verification and audience-growth acceleration pipelines to 
--                    help them scale their follower base without diluting efficiency.
-- ---------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- QUESTION 16
-- -----------------------------------------------------------------------------
-- INFO:
-- A tag may be popular overall, but its relevance could be fading. Tracking the 
-- cumulative buildup and monthly velocity of top tags reveals strategic lifecycles.
-- 
-- QUESTION:
-- How does the cumulative usage of the top 5 trending hashtags evolve over time, 
-- and are they currently accelerating or decelerating in popularity?
-- 
-- QUERY:
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

-- INSIGHTS:
-- ---------------------------------------------------------------------------
-- 1. EXECUTIVE FINDING: LATE-YEAR DECELERATION & PLATEAU ACROSS TOP-TIER HASHTAGS
--    Observation: By December 2023, four out of the top 5 trending hashtags (#agree, 
--                 #church, #economic, #very) ended the year in a "Plateaued Activity" 
--                 or "Decelerating Trend" state, with monthly application volumes 
--                 stagnating at low single-digit levels (1–4 uses/month).
--    Explanation: High-frequency evergreen tags naturally reach an equilibrium or 
--                 saturation point late in the year as creators diversify tagging 
--                 strategies toward seasonal and campaign-specific terms.
--    Recommendation: Content Operations should introduce quarterly hashtag refresh 
--                    playbooks to nudge creators toward emerging tags before core 
--                    platform tags enter prolonged plateau phases.
--
-- 2. EXECUTIVE FINDING: 'PER' DEMONSTRATES LATE-YEAR RESURGENCE & ACCELERATION MOMENTUM
--    Observation: #per stands out as the sole top hashtag closing Q4 with active positive 
--                 momentum ("Accelerating Trend" in Dec with +1 velocity change; 3 uses), 
--                 rebounding from an earlier drop in November.
--    Explanation: Multi-purpose functional terms experience periodic usage surges driven 
--                 by evolving content formats and shifting regional creator campaigns.
--    Recommendation: Product Development should leverage accelerating tags like #per 
--                    within auto-complete indexing algorithms to capture real-time 
--                    creator search intent.
--
-- 3. EXECUTIVE FINDING: EXTREME MID-YEAR LIFECYCLE VOLATILITY (#AGREE & #VERY)
--    Observation: Top tags display severe velocity shifts mid-year—e.g., #agree spiked 
--                 to 5 uses in July (+3 velocity) before dropping to a decelerating state 
--                 in September (-2 velocity), while #very collapsed from 5 uses in January 
--                 down to 1 use across mid-summer.
--    Explanation: Hashtag lifecycles on the platform are highly volatile, characterized 
--                 by short 1-to-2 month acceleration spikes followed by prolonged multi-month 
--                 deceleration periods.
--    Recommendation: Creator Marketing should design short-burst promotional campaigns 
--                    (30–45 days) that capitalize on rapid hashtag acceleration phases 
--                    rather than long-term sustained tag reliance.
-- ---------------------------------------------------------------------------