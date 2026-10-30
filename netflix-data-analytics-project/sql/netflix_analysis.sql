-- ============================================================
-- Netflix Subscriber & Content Performance Analysis
-- Database : PostgreSQL (Netflix_db)   |  Table : "Netflix_customers"
-- The table is loaded from the cleaned DataFrame with pandas.to_sql()
-- (see notebooks/Netflix_Data_Cleaning.ipynb). Table has 957 rows,
-- the same dataset used in the Power BI dashboards.
-- ============================================================

-- 0. Sanity check: did the import work?
SELECT * FROM "Netflix_customers" LIMIT 10;

-- ------------------------------------------------------------
-- Q1. Total customers
-- ------------------------------------------------------------
SELECT COUNT(*) AS total_customers
FROM "Netflix_customers";

-- ------------------------------------------------------------
-- Q2. Active customers
-- ------------------------------------------------------------
SELECT COUNT(*) AS active_customers
FROM "Netflix_customers"
WHERE "Account_Status" = 'Active';

-- ------------------------------------------------------------
-- Q3. Customers by subscription plan
-- ------------------------------------------------------------
SELECT "Subscription_Plan", COUNT(*) AS customers
FROM "Netflix_customers"
GROUP BY "Subscription_Plan"
ORDER BY customers DESC;

-- ------------------------------------------------------------
-- Q4. Revenue by subscription plan
-- ------------------------------------------------------------
SELECT "Subscription_Plan", SUM("Customer_Revenue") AS revenue
FROM "Netflix_customers"
GROUP BY "Subscription_Plan"
ORDER BY revenue DESC;

-- ------------------------------------------------------------
-- Q5. Popular genres
-- ------------------------------------------------------------
SELECT "Genre", COUNT(*) AS views
FROM "Netflix_customers"
GROUP BY "Genre"
ORDER BY views DESC;

-- ------------------------------------------------------------
-- Q6. Country-wise customers
-- ------------------------------------------------------------
SELECT "Country", COUNT(*) AS customers
FROM "Netflix_customers"
GROUP BY "Country"
ORDER BY customers DESC;

-- ------------------------------------------------------------
-- Q7. Device usage
-- ------------------------------------------------------------
SELECT "Device", COUNT(*) AS users
FROM "Netflix_customers"
GROUP BY "Device"
ORDER BY users DESC;

-- ------------------------------------------------------------
-- Q8. Average watch hours by plan
-- ------------------------------------------------------------
SELECT "Subscription_Plan",
       ROUND(AVG("Watch_Hours")::numeric, 2) AS avg_watch_hours
FROM "Netflix_customers"
GROUP BY "Subscription_Plan"
ORDER BY avg_watch_hours DESC;

-- ------------------------------------------------------------
-- Q9. Top 10 customers by revenue
-- (several customers tie at the maximum value, so LIMIT picks among ties)
-- ------------------------------------------------------------
SELECT "Customer_Name", "Customer_Revenue"
FROM "Netflix_customers"
ORDER BY "Customer_Revenue" DESC
LIMIT 10;

-- ------------------------------------------------------------
-- Q10. Movies vs TV shows
-- ------------------------------------------------------------
SELECT "Content_Type", COUNT(*) AS total
FROM "Netflix_customers"
GROUP BY "Content_Type"
ORDER BY total DESC;

-- ------------------------------------------------------------
-- Q11. Average rating by genre
-- ------------------------------------------------------------
SELECT "Genre", ROUND(AVG("Avg_Rating")::numeric, 2) AS avg_rating
FROM "Netflix_customers"
GROUP BY "Genre"
ORDER BY avg_rating DESC;

-- ------------------------------------------------------------
-- Q12. Account status distribution
-- ------------------------------------------------------------
SELECT "Account_Status", COUNT(*) AS customers
FROM "Netflix_customers"
GROUP BY "Account_Status"
ORDER BY customers DESC;

-- ============================================================
-- BONUS QUERIES
-- ============================================================

-- B1. Revenue share (%) by plan
SELECT "Subscription_Plan",
       SUM("Customer_Revenue") AS revenue,
       ROUND(100.0 * SUM("Customer_Revenue")
             / SUM(SUM("Customer_Revenue")) OVER (), 1) AS revenue_pct
FROM "Netflix_customers"
GROUP BY "Subscription_Plan"
ORDER BY revenue DESC;

-- B2. Cancelled (churn) rate by plan
SELECT "Subscription_Plan",
       COUNT(*) AS customers,
       SUM(CASE WHEN "Account_Status" = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled,
       ROUND(100.0 * SUM(CASE WHEN "Account_Status" = 'Cancelled' THEN 1 ELSE 0 END)
             / COUNT(*), 1) AS churn_pct
FROM "Netflix_customers"
GROUP BY "Subscription_Plan"
ORDER BY churn_pct DESC;

-- B3. Revenue by country
SELECT "Country", SUM("Customer_Revenue") AS revenue
FROM "Netflix_customers"
GROUP BY "Country"
ORDER BY revenue DESC;

-- ============================================================
-- ADVANCED QUERIES: CTEs + WINDOW FUNCTIONS
-- ============================================================

-- W1. Top 3 customers by engagement score in every country
--     (DENSE_RANK + PARTITION BY)
WITH ranked AS (
    SELECT "Country", "Customer_Name", "Engagement_Score",
           DENSE_RANK() OVER (
               PARTITION BY "Country"
               ORDER BY "Engagement_Score" DESC
           ) AS rnk
    FROM "Netflix_customers"
)
SELECT *
FROM ranked
WHERE rnk <= 3
ORDER BY "Country", rnk;

-- W2. Monthly new customers: previous month, % change, running total
--     (LAG + running SUM)
WITH monthly AS (
    SELECT DATE_TRUNC('month', "Join_Date") AS join_month,
           COUNT(*) AS new_customers
    FROM "Netflix_customers"
    GROUP BY 1
)
SELECT TO_CHAR(join_month, 'YYYY-MM') AS month,
       new_customers,
       LAG(new_customers) OVER (ORDER BY join_month) AS prev_month,
       ROUND(100.0 * (new_customers - LAG(new_customers) OVER (ORDER BY join_month))
             / NULLIF(LAG(new_customers) OVER (ORDER BY join_month), 0), 1) AS mom_change_pct,
       SUM(new_customers) OVER (ORDER BY join_month) AS running_total
FROM monthly
ORDER BY join_month;

-- W3. Genre share of all customers (%)
--     (SUM() OVER () as the grand total)
SELECT "Genre",
       COUNT(*) AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS share_pct
FROM "Netflix_customers"
GROUP BY "Genre"
ORDER BY customers DESC;

-- W4. Most popular title in each genre
--     (ROW_NUMBER + PARTITION BY)
WITH title_counts AS (
    SELECT "Genre", "Title", COUNT(*) AS customers
    FROM "Netflix_customers"
    GROUP BY "Genre", "Title"
),
ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY "Genre"
               ORDER BY customers DESC, "Title"
           ) AS rn
    FROM title_counts
)
SELECT "Genre", "Title", customers
FROM ranked
WHERE rn = 1
ORDER BY customers DESC;

-- W5. Cancelled % by engagement quartile (1 = most engaged)
--     (NTILE)
WITH quartiles AS (
    SELECT "Account_Status",
           NTILE(4) OVER (ORDER BY "Engagement_Score" DESC) AS engagement_quartile
    FROM "Netflix_customers"
)
SELECT engagement_quartile,
       COUNT(*) AS customers,
       ROUND(100.0 * SUM(CASE WHEN "Account_Status" = 'Cancelled' THEN 1 ELSE 0 END)
             / COUNT(*), 1) AS cancelled_pct
FROM quartiles
GROUP BY engagement_quartile
ORDER BY engagement_quartile;

-- W6. Revenue by country with cumulative share (Pareto view)
--     (RANK + running SUM)
WITH country_rev AS (
    SELECT "Country", SUM("Customer_Revenue") AS revenue
    FROM "Netflix_customers"
    GROUP BY "Country"
)
SELECT RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
       "Country",
       revenue,
       ROUND(100.0 * SUM(revenue) OVER (ORDER BY revenue DESC)
             / SUM(revenue) OVER (), 1) AS cumulative_pct
FROM country_rev
ORDER BY revenue_rank;
