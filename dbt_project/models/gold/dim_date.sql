{{config(materialized='table', schema='gold', pre_hook=["
                               ALTER SESSION SET  WEEK_START = 0;
                               SET (START_DATE,END_DATE) = ('1900-01-01','2100-12-31');
                               SET NUM_OF_DAYS = (SELECT DATEDIFF(DAY, TO_DATE($START_DATE), TO_DATE($END_DATE)));
"]) }}

WITH staging_data AS
(
SELECT
    ROW_NUMBER() OVER( ORDER BY SEQ4()) -1 AS  DIM_DATE_ID
    ,TO_DATE(DATEADD(DAY,DIM_DATE_ID, TO_DATE($START_DATE))) AS DATE
FROM
     TABLE(GENERATOR(ROWCOUNT => $NUM_OF_DAYS))
),

dim_date AS (
    SELECT CONCAT(DIM_DATE_ID+10,YEAR(DATE),TO_CHAR(DATE,'MM'),TO_CHAR(DATE,'DD')) AS DATE_SK
        , DATE
        , DECODE(DAYNAME(DATE),
                 'Mon','Monday',
                 'Tue','Tuesday',
                 'Wed', 'Wednesday',
                 'Thu','Thursday',
                 'Fri', 'Friday',
                 'Sat','Saturday',
                 'Sun', 'Sunday')  AS DAY_NAME
        , DAYNAME(DATE) AS DAY_NAME_ABV
        , DAYOFWEEK(DATE) DAY_OF_WEEK
        , MONTH(DATE) AS MONTH_NUM
        , CONCAT(YEAR(DATE),TO_CHAR(DATE,'MM')) AS MONTH_ID
        , TO_CHAR(DATE,'MMMM') AS MONTH_NAME
        , MONTHNAME(DATE) AS MONTH_NAME_ABV
        , DATEADD(DAY, 1,LAST_DAY( DATEADD(MONTH,-1,DATE),MONTH)) as First_Day_Month
        , LAST_DAY(DATE, MONTH) LAST_DAY_MONTH
        , QUARTER(DATE) AS QUARTER_NUM
        , CONCAT(YEAR(DATE),'Q',QUARTER(DATE)) AS QUARTER_ID
        , DATEADD(DAY, 1,LAST_DAY( DATEADD(QUARTER,-1,DATE),QUARTER)) as FIRST_DAY_QUARTER
        , LAST_DAY(DATE,QUARTER) AS LAST_DAY_QUARTER
        , YEAR(DATE) AS YEAR
         FROM staging_data
)

SELECT * FROM dim_date
