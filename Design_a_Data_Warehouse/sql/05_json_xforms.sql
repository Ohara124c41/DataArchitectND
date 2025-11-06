USE ROLE ACCOUNTADMIN;
USE WAREHOUSE WH_YELP_XS;
USE DATABASE YELP_WEATHER;

-- BUSINESS
INSERT OVERWRITE INTO ODS.BUSINESS
SELECT
  t.V:business_id::STRING                        AS BUSINESS_ID,
  t.V:name::STRING                               AS NAME,
  t.V:address::STRING                            AS ADDRESS,
  t.V:city::STRING                               AS CITY,
  t.V:state::STRING                              AS STATE,
  t.V:postal_code::STRING                        AS POSTAL_CODE,
  TRY_TO_NUMBER(TO_VARCHAR(t.V:latitude))        AS LATITUDE,
  TRY_TO_NUMBER(TO_VARCHAR(t.V:longitude))       AS LONGITUDE,
  TRY_TO_NUMBER(TO_VARCHAR(t.V:stars))           AS STARS,
  TRY_TO_NUMBER(TO_VARCHAR(t.V:review_count))    AS REVIEW_COUNT,
  TRY_TO_NUMBER(TO_VARCHAR(t.V:is_open))         AS IS_OPEN,
  t.V:categories::STRING                         AS CATEGORIES,
  t.V:hours:Monday::STRING      AS HOURS_MON,
  t.V:hours:Tuesday::STRING     AS HOURS_TUE,
  t.V:hours:Wednesday::STRING   AS HOURS_WED,
  t.V:hours:Thursday::STRING    AS HOURS_THU,
  t.V:hours:Friday::STRING      AS HOURS_FRI,
  t.V:hours:Saturday::STRING    AS HOURS_SAT,
  t.V:hours:Sunday::STRING      AS HOURS_SUN,
  t.V                                         AS RAW
FROM STG.BUSINESS_RAW t;

-- CUSTOMER (Yelp "user")
INSERT OVERWRITE INTO ODS.CUSTOMER
SELECT
  t.V:user_id::STRING                                         AS CUSTOMER_ID,
  COALESCE(
    TRY_TO_DATE(TO_VARCHAR(t.V:yelping_since), 'YYYY-MM'),
    TRY_TO_DATE(TO_VARCHAR(t.V:yelping_since), 'YYYY-MM-DD'),
    TRY_TO_TIMESTAMP_NTZ(TO_VARCHAR(t.V:yelping_since))::DATE
  )                                                           AS YELPING_SINCE,
  TRY_TO_NUMBER(TO_VARCHAR(t.V:review_count))                 AS REVIEW_COUNT,
  ARRAY_SIZE(TRY_PARSE_JSON(t.V:friends))                     AS FRIENDS_COUNT,
  TRY_TO_NUMBER(TO_VARCHAR(t.V:useful))                       AS USEFUL_VOTES,
  TRY_TO_NUMBER(TO_VARCHAR(t.V:funny))                        AS FUNNY_VOTES,
  TRY_TO_NUMBER(TO_VARCHAR(t.V:cool))                         AS COOL_VOTES,
  t.V:elite::STRING                                           AS ELITE_RAW,
  t.V                                                         AS RAW
FROM STG.CUSTOMER_RAW t;

-- REVIEW
INSERT OVERWRITE INTO ODS.REVIEW
SELECT
  t.V:review_id::STRING                           AS REVIEW_ID,
  t.V:business_id::STRING                         AS BUSINESS_ID,
  t.V:user_id::STRING                             AS CUSTOMER_ID,
  TRY_TO_NUMBER(TO_VARCHAR(t.V:stars))            AS STARS,
  TRY_TO_NUMBER(TO_VARCHAR(t.V:useful))           AS USEFUL,
  TRY_TO_NUMBER(TO_VARCHAR(t.V:funny))            AS FUNNY,
  TRY_TO_NUMBER(TO_VARCHAR(t.V:cool))             AS COOL,
  COALESCE(
    TRY_TO_DATE(TO_VARCHAR(t.V:date), 'YYYY-MM-DD'),
    TRY_TO_TIMESTAMP_NTZ(TO_VARCHAR(t.V:date))::DATE
  )                                               AS REVIEW_DATE,
  t.V                                             AS RAW
FROM STG.REVIEW_RAW t;

-- TIP
INSERT OVERWRITE INTO ODS.TIP
SELECT
  t.V:business_id::STRING                         AS BUSINESS_ID,
  t.V:user_id::STRING                             AS CUSTOMER_ID,
  COALESCE(
    TRY_TO_DATE(TO_VARCHAR(t.V:date), 'YYYY-MM-DD'),
    TRY_TO_TIMESTAMP_NTZ(TO_VARCHAR(t.V:date))::DATE
  )                                               AS TIP_DATE,
  TRY_TO_NUMBER(TO_VARCHAR(t.V:compliment_count)) AS COMPLIMENT_COUNT,
  t.V:text::STRING                                AS TEXT,
  t.V                                             AS RAW
FROM STG.TIP_RAW t;

-- CHECKIN (counts of timestamps)
INSERT OVERWRITE INTO ODS.CHECKIN
SELECT
  t.V:business_id::STRING                         AS BUSINESS_ID,
  IFF(t.V:date IS NULL, 0,
      ARRAY_SIZE(SPLIT(TO_VARCHAR(t.V:date), ','))) AS CHECKINS_COUNT,
  t.V                                             AS RAW
FROM STG.CHECKIN_RAW t;

-- COVID flags from free-form strings
INSERT OVERWRITE INTO ODS.COVID
SELECT
  t.V:business_id::STRING AS BUSINESS_ID,
  IFF(UPPER(TO_VARCHAR(t.V:delivery_or_takeout)) IN ('TRUE','T','YES','Y','1'), TRUE, FALSE) AS DELIVERY_OR_TAKEOUT,
  IFF(UPPER(TO_VARCHAR(t.V:Grubhub))            IN ('TRUE','T','YES','Y','1'), TRUE, FALSE) AS GRUBHUB,
  IFF(UPPER(TO_VARCHAR(t.V:DoorDash))           IN ('TRUE','T','YES','Y','1'), TRUE, FALSE) AS DOORDASH,
  IFF(UPPER(TO_VARCHAR(t.V:UberEats))           IN ('TRUE','T','YES','Y','1'), TRUE, FALSE) AS UBEREATS,
  t.V                                             AS RAW
FROM STG.COVID_RAW t;

-- TEMPERATURE CSV to typed ODS table
INSERT OVERWRITE INTO ODS.TEMPERATURE
SELECT
  TO_DATE(date_raw, 'YYYYMMDD') AS WX_DATE,
  TMIN_F                        AS TMIN_F,
  TMAX_F                        AS TMAX_F,
  NORMAL_TMIN_F                 AS NORMAL_MIN_F,
  NORMAL_TMAX_F                 AS NORMAL_MAX_F
FROM STG.TEMPERATURE_RAW
WHERE DATE_RAW IS NOT NULL;

-- PRECIPITATION CSV to typed ODS table
INSERT OVERWRITE INTO ODS.PRECIPITATION
SELECT
  TO_DATE(date_raw, 'YYYYMMDD') AS WX_DATE,
  PRECIP_IN                     AS PRECIP_IN,
  PRECIP_NORMAL_IN              AS PRECIP_NORMAL_IN
FROM STG.PRECIPITATION_RAW
WHERE DATE_RAW IS NOT NULL;

-- Evidence for ODS load
SELECT table_name, row_count
FROM INFORMATION_SCHEMA.TABLES
WHERE table_schema = 'ODS'
  AND table_name IN (
    'BUSINESS','CUSTOMER','REVIEW','TIP','CHECKIN','COVID','TEMPERATURE','PRECIPITATION')
ORDER BY table_name;
