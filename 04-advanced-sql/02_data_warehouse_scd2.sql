CREATE SCHEMA IF NOT EXISTS bank_db;

CREATE TABLE IF NOT EXISTS bank_db.customers (
    customer_id   INT64,
    full_name     STRING,
    city          STRING,
    segment       STRING
);

CREATE TABLE IF NOT EXISTS bank_db.accounts (
    account_number  INT64,
    customer_id     INT64,
    currency        STRING,
    open_date       DATE,
    status          STRING
);

CREATE TABLE IF NOT EXISTS bank_db.transactions (
    transaction_id  INT64,
    account_number  INT64,
    txn_timestamp   TIMESTAMP,
    type            STRING,
    status          STRING,
    amount          NUMERIC(18,2),
    fee_amount      NUMERIC(18,2)
);

INSERT INTO bank_db.customers (customer_id, full_name, city, segment)
VALUES
(1001, 'Ivan Petrenko', 'Kyiv', 'Retail'),
(NULL, 'Noname User', 'Unknown', 'Retail'),
(1006, 'Sergiy Melnyk', 'Lviv', 'SME'),
(1007, 'Tetiana Savchenko', 'Kyiv', 'Corporate'),
(1006, 'Sergiy I. Melnyk', 'Lviv', 'SME'),
(1008, 'Mykhailo Kotsiubynskyi', 'Chernihiv', 'Retail'),
(1009, 'Lesia Ukrainka', 'Lutsk', 'Retail'),
(NULL, 'Another Noname', 'Lviv', 'SME'),
(1010, 'Hryhorii Skovoroda', 'Poltava', 'SME'),
(1001, 'Ivan Petrenko', 'Kyiv', 'Retail'),
(1008, 'Mykhailo Kotsiubynskyi', 'Chernihiv', 'Retail'),
(1011, 'LLC EnergoInvest', 'Zaporizhzhia', 'Corporate');

INSERT INTO bank_db.accounts (account_number, customer_id, currency, open_date, status)
VALUES
(20002, 1002, 'EUR', '2024-02-15', 'Active'),
(20006, 1006, 'UAH', '2024-06-01', 'Active'),
(20007, 1007, 'USD', '2024-07-10', 'Pending Approval'),
(NULL, 1007, 'UAH', '2024-07-11', 'Active'),
(20008, 1001, 'USD', '2024-08-15', 'Frozen'),
(20009, 1003, 'EUR', '2024-08-20', 'Closed'),
(20006, 1006, 'UAH', '2024-06-01', 'Active'),
(20010, 1008, 'UAH', '2024-09-01', 'Active'),
(20011, 1009, 'EUR', '2024-09-05', 'Active'),
(20012, 1010, 'USD', '2024-09-10', 'Pending Approval'),
(20013, 1011, 'USD', '2024-09-15', 'Active'),
(NULL, 1008, 'EUR', '2024-09-16', 'Frozen'),
(20007, 1007, 'USD', '2024-07-10', 'Pending Approval'),
(20010, 1008, 'UAH', '2024-09-01', 'Active');

INSERT INTO bank_db.transactions (transaction_id, account_number, txn_timestamp, type, status, amount, fee_amount)
VALUES
(30005, 20004, TIMESTAMP '2024-05-06 10:20:00', 'Deposit', 'Completed', 50000.00, 0.00),
(30011, 20006, TIMESTAMP '2024-09-01 10:00:00', 'Deposit', 'Completed', 75000.00, 0.00),
(NULL, 20007, TIMESTAMP '2024-09-02 11:00:00', 'Deposit', 'Completed', 120000.00, 0.00),
(30012, 20007, TIMESTAMP '2024-09-03 14:30:00', 'Payment', 'Pending', -15000.00, 150.00),
(30013, 20008, TIMESTAMP '2024-09-04 16:00:00', 'Deposit', 'Failed', 3000.00, 0.00),
(30014, 20009, TIMESTAMP '2024-09-05 12:00:00', 'Withdrawal', 'Reversed', -500.00, 5.00),
(30011, 20006, TIMESTAMP '2024-09-01 10:00:00', 'Deposit', 'Completed', 75000.00, 0.00),
(NULL, 20001, TIMESTAMP '2024-09-05 09:15:00', 'Payment', 'Failed', -100.00, 1.00),
(30015, 20010, TIMESTAMP '2024-10-01 08:00:00', 'Deposit', 'Completed', 15000.00, 0.00),
(30016, 20011, TIMESTAMP '2024-10-02 11:30:00', 'Withdrawal', 'Completed', -1000.00, 10.00),
(30017, 20012, TIMESTAMP '2024-10-03 15:00:00', 'Payment', 'Pending', -5000.00, 50.00),
(30018, 20013, TIMESTAMP '2024-10-04 17:00:00', 'Deposit', 'Completed', 250000.00, 0.00),
(30019, 20010, TIMESTAMP '2024-10-05 10:10:10', 'Payment', 'Completed', -3000.00, 30.00),
(30020, 20008, TIMESTAMP '2024-10-06 13:45:00', 'Transfer', 'Failed', -500.00, 5.00),
(30015, 20010, TIMESTAMP '2024-10-01 08:00:00', 'Deposit', 'Completed', 15000.00, 0.00),
(NULL, 20011, TIMESTAMP '2024-10-07 18:00:00', 'Deposit', 'Reversed', 1000.00, 0.00),
(30018, 20013, TIMESTAMP '2024-10-04 17:00:00', 'Deposit', 'Completed', 250000.00, 0.00);

--------------------------------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS bank_db_stg;

CREATE TABLE IF NOT EXISTS bank_db_stg.customers AS (
  SELECT
    * EXCEPT (rn)
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY customer_id) as rn
    FROM
      bank_db.customers
    WHERE
      customer_id IS NOT NULL
  )
  WHERE
    rn = 1
);

CREATE TABLE IF NOT EXISTS bank_db_stg.accounts AS (
  SELECT
    * EXCEPT (rn)
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY account_number ORDER BY account_number) as rn
    FROM
      bank_db.accounts
    WHERE
      account_number IS NOT NULL
  )
  WHERE
    rn = 1
    AND status = 'Active'
);

CREATE TABLE IF NOT EXISTS bank_db_stg.transactions AS (
  SELECT
    * EXCEPT (rn)
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY transaction_id) as rn
    FROM
      bank_db.transactions
    WHERE
      transaction_id IS NOT NULL
  )
  WHERE
    rn = 1
    AND status = 'Completed'
);

-------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS bank_db_dwh;

CREATE TABLE IF NOT EXISTS bank_db_dwh.Dim_Date AS (
  SELECT
    
    CAST(FORMAT_DATE('%Y%m%d', d) AS INT64) AS date_key,
    
    
    d AS full_date,
    EXTRACT(DAY FROM d) AS day_of_month,
    EXTRACT(MONTH FROM d) AS month_number,
    FORMAT_DATE('%B', d) AS month_name,
    EXTRACT(QUARTER FROM d) AS quarter,
    EXTRACT(YEAR FROM d) AS year,
    EXTRACT(DAYOFWEEK FROM d) AS day_of_week_number,
    FORMAT_DATE('%A', d) AS day_of_week_name,
    
    
    (EXTRACT(DAYOFWEEK FROM d) IN (1, 7)) AS is_weekend,
    FALSE AS is_holiday
    
  FROM
    
    UNNEST(GENERATE_DATE_ARRAY('2020-01-01', '2030-12-31', INTERVAL 1 DAY)) AS d
);

---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS bank_db_dwh.Dim_Account AS (
  SELECT
    GENERATE_UUID() AS account_key,
    account_number,
    customer_id,
    currency,
    open_date,
    status
  FROM
    bank_db_stg.accounts
);

CREATE TABLE bank_db_dwh.Dim_Customer (
  customer_key   STRING NOT NULL,
  customer_id    INT64 NOT NULL,
  full_name      STRING,
  city           STRING,
  segment        STRING,
  
  valid_from     TIMESTAMP,
  valid_to       TIMESTAMP,
  is_active      BOOL
);

INSERT INTO bank_db_dwh.Dim_Customer (
  customer_key, customer_id, full_name, city, segment,
  valid_from, valid_to, is_active
)
SELECT
  GENERATE_UUID() AS customer_key,
  customer_id,
  full_name,
  city,
  segment,
  CURRENT_TIMESTAMP() AS valid_from,
  TIMESTAMP('9999-12-31 23:59:59') AS valid_to,
  TRUE AS is_active
FROM
  bank_db_stg.customers;

UPDATE bank_db_dwh.Dim_Customer
SET
  is_active = FALSE,
  valid_to = CURRENT_TIMESTAMP()
WHERE
  customer_id = 1001 AND is_active = TRUE;

INSERT INTO bank_db_dwh.Dim_Customer (
  customer_key, customer_id, full_name, city, segment,
  valid_from, valid_to, is_active
)
VALUES (
  GENERATE_UUID(),
  1001,
  'Ivan Petrenko',
  'Lviv',
  'Retail',
  CURRENT_TIMESTAMP(),
  TIMESTAMP('9999-12-31 23:59:59'),
  TRUE
);

--------------------------------------------------------------------------------

CREATE SCHEMA bank_db_ftc;

CREATE TABLE IF NOT EXISTS bank_db_ftc.fact_bank_summary AS (
  SELECT
    
    
    da.account_key,
    dc.customer_key,
    dd.date_key,

    
    
    st.transaction_id,
    st.type,
    st.status,
    
    
    
    
    st.amount,
    st.fee_amount
    
  FROM
    bank_db_stg.transactions AS st
  
  
  LEFT JOIN
    bank_db_dwh.Dim_Account AS da ON st.account_number = da.account_number
  LEFT JOIN
    bank_db_dwh.Dim_Customer AS dc ON da.customer_id = dc.customer_id AND dc.is_active = TRUE
  LEFT JOIN
    bank_db_dwh.Dim_Date AS dd 
      ON CAST(FORMAT_DATE('%Y%m%d', DATE(st.txn_timestamp)) AS INT64) = dd.date_key
);

---------
