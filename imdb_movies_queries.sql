-- 1. database setup ---------------------
CREATE DATABASE IF NOT EXISTS imdb CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
USE imdb;

-- 2. create table 'movies' ------------------
CREATE TABLE movies (
	poster_link VARCHAR(255),
    title VARCHAR(255),
    release_year INT,
    certificate VARCHAR(10),
    runtime VARCHAR(20),
    genre VARCHAR(100),
    imdb_rate DECIMAL(3,1),
    overview VARCHAR(255),
    meta_score INT,
    director VARCHAR(100),
    star1 VARCHAR(100),
    star2 VARCHAR(100),
    star3 VARCHAR(100),
    star4 VARCHAR(100),
    no_of_votes INT,
    gross BIGINT,
    PRIMARY KEY (title)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 3. load data into table 'movies' ----------------

/* LOAD DATA LOCAL INFILE '/path/to/file.csv'
INTO TABLE table_name
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS; */

-- 4. cleaning data in table 'movies' ---------------------

-- dropping 'poster_link' column/field from the table
ALTER TABLE movies
DROP COLUMN poster_link;

-- changing runtime field to numeric
SELECT CAST(REPLACE(runtime, ' min', '')AS UNSIGNED) AS runtime_mins FROM movies;

-- creating a new cloumn 'decade_released'
SELECT CONCAT(FLOOR(release_year/10)*10,'s') AS decade_released FROM movies;

-- creating a clean view of the table 'movies'
CREATE VIEW movies_cleaned AS
SELECT title, release_year,
CONCAT(FLOOR(release_year/10)*10,'s') AS decade_released,
certificate,
CAST(REPLACE(runtime, ' min', '')AS UNSIGNED) AS runtime_mins,
genre, imdb_rate, overview, meta_score, director, star1, star2, star3, star4, no_of_votes, gross
FROM movies;

-- 5. kpi queries ----------------------

-- 5.1 total movies analysed
SELECT COUNT(*) AS total_movies FROM movies_cleaned;

-- 5.2 average imdb rating (audience acceptance)
SELECT FORMAT(AVG(imdb_rate),1) AS avg_imdb_rating FROM movies_cleaned;

-- 5.3 average meta score (critic acceptance)
SELECT FORMAT(AVG(meta_score),0) AS avg_meta_score FROM movies_cleaned;

-- 5.4 average runtime of top 1000 movies
SELECT CONCAT(FLOOR(AVG(runtime_mins)),' mins') AS avg_runtime_mins FROM movies_cleaned;

-- 5.5 top 10 directors by average imdb ratings (max score - 10)
SELECT director, FORMAT(AVG(imdb_rate),1) AS avg_imdb_rating_outof10
FROM movies_cleaned 
GROUP BY director 
ORDER BY avg_imdb_rating_outof10 DESC LIMIT 10;

-- 5.6 top 10 directors by average imdb ratings and average metascore combined (max score - 110)
SELECT director, FORMAT(AVG(imdb_rate)+AVG(meta_score),2) AS avg_overall_score_outof110 
FROM movies_cleaned 
GROUP BY director 
ORDER BY avg_overall_score_outof110 DESC LIMIT 10;

-- 6. analysis/visualisation queries -------------------------------

-- 6.1 number of popular movies per decade
SELECT decade_released, COUNT(title) AS no_of_popular_movies
FROM movies_cleaned 
GROUP BY decade_released 
ORDER BY no_of_popular_movies DESC;

-- 6.2 average imdb rating by genre
SELECT genre, FORMAT(AVG(imdb_rate),1) AS avg_imdb_rating_outof10
FROM movies_cleaned
GROUP BY genre
ORDER BY avg_imdb_rating_outof10 DESC;

-- 6.3 movies loved by both audience(imdb rating) and critics(meta_score)
SELECT title, director, release_year, certificate, genre, imdb_rate, meta_score
FROM movies_cleaned
WHERE meta_score > 0
ORDER BY imdb_rate+meta_score DESC;

-- 6.4 average runtime by genre
SELECT genre, CONCAT(FLOOR(AVG(runtime_mins)), ' mins') AS avg_runtime, COUNT(title) AS no_of_movies
FROM movies_cleaned
GROUP BY genre
ORDER BY FLOOR(AVG(runtime_mins)) DESC;

-- 6.5 certification distribution
SELECT certificate, COUNT(certificate) AS no_of_movies 
FROM movies_cleaned
WHERE certificate != ''
GROUP BY certificate
ORDER BY no_of_movies DESC;

-- 6.6 directors who make top rated films in each genre (more than 2 films)
CREATE VIEW directors AS
SELECT DISTINCT director FROM movies_cleaned;

SELECT d.director, m.genre, FORMAT(AVG(m.imdb_rate),1) AS avg_imdb_rating_outof10, COUNT(m.title) AS no_of_movies
FROM movies_cleaned AS m
JOIN directors as d ON m.director = d.director
GROUP BY d.director, m.genre
HAVING no_of_movies > 2
ORDER BY avg_imdb_rating_outof10 DESC;

-- 6.7 most popular genre of each decade
SELECT decade_released, genre, COUNT(genre) AS no_of_movies
FROM movies_cleaned
GROUP BY decade_released, genre
HAVING no_of_movies > 0
ORDER BY decade_released;

-- 6.8 most popular director of each decade
SELECT 
    m.decade_released,
    m.director,
    ROUND(AVG(m.imdb_rate), 1) AS avg_rating
FROM movies_cleaned AS m
GROUP BY m.decade_released, m.director
HAVING ROUND(AVG(m.imdb_rate), 1) = (
    SELECT MAX(avg_rating)
    FROM (
        SELECT 
            director, 
            ROUND(AVG(imdb_rate), 1) AS avg_rating
        FROM movies_cleaned
        WHERE decade_released = m.decade_released
        GROUP BY director
    ) AS sub
)
ORDER BY m.decade_released;