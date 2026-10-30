# Data Dictionary

## Original columns (20)
| Column | Description |
|---|---|
| Customer_ID | Unique customer identifier |
| Customer_Name | Customer name |
| Age | Customer age (valid range kept: 18–100) |
| Title | Content title watched |
| Content_Type | Movie / TV Show |
| Genre | Content genre |
| Country | Customer country |
| Subscription_Plan | Basic / Standard / Premium |
| Device | Watching device |
| Payment_Method | Payment method |
| Account_Status | Active / Paused / Cancelled |
| Join_Date | Date the customer joined |
| Last_Watch_Date | Date of last activity |
| Watch_Hours | Total watch hours |
| Monthly_Fee | Monthly subscription fee (149 / 499 / 649) |
| Movies_Watched | Number of movies watched |
| Episodes_Watched | Number of episodes watched |
| Avg_Rating | Average rating given (0–5) |
| Monthly_Sessions | Sessions per month |
| Download_Count | Number of downloads |

## Engineered columns (5)
| Column | Logic |
|---|---|
| Customer_Revenue | Monthly_Fee × Monthly_Sessions |
| Engagement_Score | Watch_Hours + Monthly_Sessions + Download_Count |
| Watch_Category | Low (>0–20) / Medium (20–50) / High (50–100) / Very High (>100) hours |
| Age_Group | 18-25 / 26-35 / 36-50 / 51+ |
| Active_Flag | 1 = Active, 0 = otherwise |

## Final dataset
957 rows × 25 columns, no null values, no duplicate rows.
