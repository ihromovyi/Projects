CREATE OR REPLACE TABLE `qwiklabs-gcp-00-a42bd729d4fc.1.reviews_clean_analytical` AS

SELECT
  appid as game_id, 
  
  review_data.query_summary.total_reviews as batch_total_reviews,
  review_data.query_summary.total_positive as batch_total_positive,
  review_data.query_summary.review_score_desc as batch_score_desc, 

  r.recommendationid as review_id,
  r.review as review_text,
  
  TIMESTAMP_SECONDS(r.timestamp_created) as created_at,
  TIMESTAMP_SECONDS(r.timestamp_updated) as updated_at,
  
  r.voted_up as is_positive, 
    
  r.language,

  r.author.steamid as author_steam_id,
  
  r.author.num_games_owned as author_games_count,
  r.author.num_reviews as author_reviews_count

FROM
  `qwiklabs-gcp-00-a42bd729d4fc.1.reviews_raw`,
  UNNEST(review_data.reviews) AS r;       

SELECT * FROM `qwiklabs-gcp-00-a42bd729d4fc.1.reviews_clean_analytical`;

--------------------------------------------------------------------

CREATE OR REPLACE TABLE `qwiklabs-gcp-00-a42bd729d4fc.1.games_clean_analytical` AS

SELECT
  appid as game_id,
  name_from_applist,
  app_details.fetched_at,
  app_details.success as api_success,

  app_details.`data`.name as game_title,
  app_details.`data`.type as app_type,
  app_details.`data`.is_free,
  app_details.`data`.short_description,

  COALESCE(app_details.`data`.price_overview.final / 100, 0) as price_value,

  app_details.`data`.release_date.date as release_date_text,
  
  app_details.`data`.recommendations.total as recommendations_count,
  
  app_details.`data`.required_age,

  ARRAY(
    SELECT description FROM UNNEST(app_details.`data`.genres)
  ) as genres,

  ARRAY(
    SELECT description FROM UNNEST(app_details.`data`.categories)
  ) as categories,


FROM
  `qwiklabs-gcp-00-a42bd729d4fc.1.games_raw`
WHERE
  appid IS NOT NULL
  AND app_details.success = true 
  AND app_details.data.name IS NOT NULL;

------------------------------------------------------------------
Part 2 — Analytical Insights (6 points)

/// 1 insight /// Top 20 games by number of reviews
SELECT 
  game_id,
  COUNT(*) as total_reviews
FROM 
  `qwiklabs-gcp-00-a42bd729d4fc.1.reviews_clean_analytical`
GROUP BY 
  game_id
ORDER BY 
  total_reviews DESC
LIMIT 20;

/// 2 insight /// Distribution of game release years

SELECT 
  EXTRACT(YEAR FROM release_date) AS release_year,
  COUNT(*) as games_count
 FROM `qwiklabs-gcp-00-a42bd729d4fc.1.games_clean_analytical`
 WHERE
  release_date IS NOT NULL
GROUP BY
  release_year
ORDER BY
  release_year DESC;

/// 3 insight /// The most popular genre
  
SELECT 
  genre.description as genre,
  COUNT(*) as games_count
FROM 
  `qwiklabs-gcp-00-a42bd729d4fc.1.games_raw`,
  UNNEST(app_details.data.genres) as genre
WHERE 
  app_details.success = true
GROUP BY 
  genre
ORDER BY 
  games_count DESC
LIMIT 20;

/// 4 insight /// The most popular category

SELECT 
  category.description as category_name,
  COUNT(*) as category_count
FROM 
  `qwiklabs-gcp-00-a42bd729d4fc.1.games_raw`,
  UNNEST(app_details.data.categories) as category
WHERE 
  app_details.success = true
GROUP BY 
  category_name
ORDER BY 
  category_count DESC
LIMIT 20;


/// 5 insight /// On which language do our customers speak (considering their review language)

SELECT 
  r.language,
  COUNT(r.language) as reviews_language_count
FROM 
  `qwiklabs-gcp-00-a42bd729d4fc.1.reviews_clean_analytical` as r
WHERE 
  r.app_details.success = true,
  r.game_id = 730
GROUP BY 
  reviews_language_count
ORDER BY 
  reviews_language_count DESC;

----------------------------------------------------------------------------------------------
