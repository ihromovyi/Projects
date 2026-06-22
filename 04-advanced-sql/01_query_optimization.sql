DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS users;

-- СТВОРЕННЯ ТАБЛИЦЬ -----------------------------------------------------------------
CREATE TABLE users (
    user_id INT UNSIGNED NOT NULL PRIMARY KEY,
    username VARCHAR(100),
    email VARCHAR(255),
    registration_date DATE
);

CREATE TABLE orders (
    order_id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
    user_id INT UNSIGNED,
    order_date TIMESTAMP,
    status ENUM('created', 'shipped', 'delivered', 'cancelled'), -- ENUM ефективніший
    
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE order_items (
    item_id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
    order_id BIGINT UNSIGNED,
    product_name VARCHAR(200),
    quantity INT,
    price_per_item DECIMAL(10, 2),

    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE IF NOT EXISTS digits (
    n INT NOT NULL PRIMARY KEY
);
-----------------------------------------------------------------------------------

-- ВСТАВЛЯЄМО ДАНІ ----------------------------------------------------------------


INSERT INTO digits (n) 
VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

SET foreign_key_checks = 0;

SET @@SESSION.cte_max_recursion_depth = 5000000;
-- 2. ВСТАВКА ДАНИХ

-- Вставляємо 1,000,000 користувачів (БЕЗ 'OPTION')
INSERT INTO users (user_id, username, email, registration_date)
WITH RECURSIVE seq (n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 1000000
)
SELECT
    n AS user_id,
    CONCAT('user_', n) AS username,
    CONCAT('user', n, '@example.com') AS email,
    DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND() * 365 * 5) DAY) AS registration_date
FROM seq;

SET @@SESSION.time_zone = '+00:00';

SET @row := 0;
SET foreign_key_checks = 0;

TRUNCATE TABLE order_items;

TRUNCATE TABLE orders;

SET foreign_key_checks = 1;

INSERT INTO orders (order_id, user_id, order_date, status)
SELECT
    (@row := @row + 1) AS order_id,
    FLOOR(RAND() * 1000000) + 1 AS user_id,
    DATE_SUB(
        DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 730) DAY),
        INTERVAL FLOOR(RAND() * 86400) SECOND
    ) AS order_date,
    ELT(FLOOR(RAND() * 4) + 1, 'created', 'shipped', 'delivered', 'cancelled') AS status
FROM
    (SELECT 1 UNION SELECT 2) AS two_rows, -- 2
    digits d1, -- 20
    digits d2, -- 200
    digits d3, -- 2,000
    digits d4, -- 20,000
    digits d5, -- 200,000
    digits d6  -- 2,000,000
LIMIT 2000000;

SET @@SESSION.time_zone = @@GLOBAL.time_zone;

SET foreign_key_checks = 0;
TRUNCATE TABLE order_items;
SET foreign_key_checks = 1;

SET @row := 0;

INSERT INTO order_items (
    item_id, 
    order_id,  -- <--- Ми беремо це з `orders`
    product_name, 
    quantity, 
    price_per_item
)
SELECT
    (@row := @row + 1) AS item_id,
    
    o.order_id AS order_id, -- <--- ОСЬ НОВА ЛОГІКА
    
    CONCAT('Product ', FLOOR(RAND() * 1000) + 1) AS product_name,
    FLOOR(RAND() * 5) + 1 AS quantity,
    ROUND(RAND() * 200 + 5, 2) AS price_per_item
FROM
    orders o  -- Беремо 2М існуючих замовлень
CROSS JOIN
    -- Множимо їх на 3 (щоб отримати 2М * 3 = 6М рядків)
    (SELECT 1 UNION SELECT 2 UNION SELECT 3) AS multiplier
LIMIT 5000000;
-------------------------------------------------------------------



-- ПОВІЛЬНИЙ ЗАПИТ ------------------------------------------------------
SELECT
    u.username,
    u.email,
    -- ПРОБЛЕМА 1: 
    -- Перший прохід по таблицях orders/order_items
    delivered_stats.total_delivered,
    -- ПРОБЛЕМА 2: 
    -- Другий, окремий прохід по таблицях orders/order_items
    cancelled_stats.total_cancelled,
    -- ПРОБЛЕМА 3: 
    -- Третій, окремий прохід по таблицях orders/order_items
    first_order_items.items_in_first_order
    
FROM
    users u
-- JOIN №1: Підзапит для доставлених
LEFT JOIN (
    SELECT
        o.user_id,
        SUM(it.quantity * it.price_per_item) AS total_delivered
    FROM orders o
    JOIN order_items it ON o.order_id = it.order_id
    WHERE o.status = 'delivered'
    GROUP BY o.user_id
) AS delivered_stats ON u.user_id = delivered_stats.user_id
-- JOIN №2: Підзапит для скасованих
LEFT JOIN (
    SELECT
        o.user_id,
        SUM(it.quantity * it.price_per_item) AS total_cancelled
    FROM orders o
    JOIN order_items it ON o.order_id = it.order_id
    WHERE o.status = 'cancelled'
    GROUP BY o.user_id
) AS cancelled_stats ON u.user_id = cancelled_stats.user_id
-- JOIN №3: Підзапит для першого замовлення

LEFT JOIN (
    SELECT
        o.user_id,
        SUM(it.quantity) AS items_in_first_order
    FROM orders o
    JOIN order_items it ON o.order_id = it.order_id
    WHERE 
        -- Знаходимо перше замовлення для КОЖНОГО користувача
        o.order_date = (
            SELECT MIN(o2.order_date) 
            FROM orders o2 
            WHERE o2.user_id = o.user_id
        )
    GROUP BY o.user_id
) AS first_order_items ON u.user_id = first_order_items.user_id

WHERE
    u.registration_date > '2024-01-01' -- Фільтруємо користувачів
ORDER BY 
    u.username ASC
LIMIT 100;
----------------------------------------------------------------------




-- ОПТИМІЗОВАНИЙ ЗАПИТ -----------------------------------------------------


CREATE INDEX idx_cover_users 
    ON users(registration_date, user_id, username, email);

CREATE INDEX idx_cover_orders 
    ON orders(user_id, order_date, status, order_id);

CREATE INDEX idx_cover_items 
    ON order_items(order_id, quantity, price_per_item);

WITH Filtered_Users AS (
    SELECT 
        user_id, 
        username, 
        email
    FROM 
        users
	USE INDEX(idx_cover_users)
    WHERE 
        registration_date > '2024-01-01'
),
All_orders_data AS (
    SELECT
        fu.user_id,
        o.status,
        o.order_date, 
        it.quantity,
        it.price_per_item,
        RANK() OVER(
            PARTITION BY user_id
            ORDER BY order_date ASC
        ) AS order_rank
    FROM
        Filtered_Users fu
    JOIN 
        orders o USE INDEX (idx_cover_orders)
        ON o.user_id = fu.user_id 
    JOIN 
        order_items it USE INDEX (idx_cover_items)
        ON o.order_id = it.order_id
)
SELECT 
	fu.username,
    fu.email,
    SUM(CASE WHEN aod.status = 'delivered' THEN aod.price_per_item * aod.quantity ELSE NULL END) AS total_delivered,
    SUM(CASE WHEN aod.status = 'cancelled' THEN aod.price_per_item * aod.quantity ELSE NULL END) AS total_cancelled,
    SUM(CASE WHEN aod.order_rank = 1 THEN aod.quantity ELSE NULL END) AS items_in_first_order 
FROM
    Filtered_Users fu
LEFT JOIN
    All_orders_data aod ON fu.user_id = aod.user_id
GROUP BY
    fu.user_id, fu.username, fu.email
ORDER BY 
    fu.username ASC
LIMIT 100;
-- КІНЕЦЬ -------------------------------------------------------------