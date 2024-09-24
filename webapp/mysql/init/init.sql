-- テーブル作成
CREATE TABLE IF NOT EXISTS areas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL DEFAULT '$argon2id$v=19$m=19456,t=2,p=1$XATPp8QqqTtg3VrdJ/QPfw$r3o9L6zWQc/Zq70GbP33Gl9N50jGUSMMvYcl7M05ukw',
    profile_image VARCHAR(255) NOT NULL DEFAULT 'default.png',
    role VARCHAR(255) NOT NULL, 
INDEX idx_username(username)  -- 为 username 字段添加索引
);

CREATE TABLE IF NOT EXISTS sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    session_token VARCHAR(255) NOT NULL,
    is_valid BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,  -- 指定 user_id 为外键
INDEX idx_user_id_session(user_id, session_token),
    UNIQUE INDEX unique_session_token(session_token)  -- 为 session_token 创建唯一索引
);

CREATE TABLE IF NOT EXISTS dispatchers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    area_id INT NOT NULL,
UNIQUE INDEX unique_user_id(user_id),  -- 为 user_id 创建唯一索引
    FOREIGN KEY (user_id) REFERENCES users(id)  -- 指定 user_id 为外键
);

CREATE TABLE IF NOT EXISTS tow_trucks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    driver_id INT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'available',
    area_id INT NOT NULL,
-- 索引
FOREIGN KEY (driver_id) REFERENCES users(id),
INDEX idx_status_area_id(status, area_id)

);

CREATE TABLE IF NOT EXISTS nodes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    area_id INT NOT NULL,
    x INT NOT NULL,
    y INT NOT NULL,
    -- 创建组合索引 (area_id, id) 加速 WHERE 和 ORDER BY
    UNIQUE INDEX idx_nodes_area_id_id(area_id, id)
);

CREATE TABLE IF NOT EXISTS edges (
    id INT AUTO_INCREMENT PRIMARY KEY,
    node_a_id INT NOT NULL,
    node_b_id INT NOT NULL,
    weight INT NOT NULL,
    UNIQUE (node_a_id, node_b_id)
);

CREATE TABLE IF NOT EXISTS locations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tow_truck_id INT NOT NULL,
    node_id INT NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,

-- 索引
FOREIGN KEY (tow_truck_id) REFERENCES tow_trucks(id), 
INDEX idx_tow_truck_timestamp (tow_truck_id, timestamp)

);

CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_id INT NOT NULL,
    dispatcher_id INT,
    tow_truck_id INT,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    node_id INT NOT NULL,
    car_value DOUBLE NOT NULL,
    order_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_time DATETIME,
    FOREIGN KEY (client_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (dispatcher_id) REFERENCES dispatchers(id) ON DELETE CASCADE,
    FOREIGN KEY (tow_truck_id) REFERENCES tow_trucks(id) ON DELETE CASCADE,
    FOREIGN KEY (node_id) REFERENCES nodes(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS completed_orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL UNIQUE,
    tow_truck_id INT NOT NULL UNIQUE,
    completed_time DATETIME NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (tow_truck_id) REFERENCES tow_trucks(id) ON DELETE CASCADE
);

-- CSVファイルからデータをロード
LOAD DATA INFILE '/docker-entrypoint-initdb.d/csv/areas.csv'
INTO TABLE areas
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(name);

LOAD DATA INFILE '/docker-entrypoint-initdb.d/csv/users.csv'
INTO TABLE users
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(username, role, profile_image);

LOAD DATA INFILE '/docker-entrypoint-initdb.d/csv/dispatchers.csv'
INTO TABLE dispatchers
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(user_id, area_id);

LOAD DATA INFILE '/docker-entrypoint-initdb.d/csv/tow_trucks.csv'
INTO TABLE tow_trucks
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(driver_id, status, area_id);

LOAD DATA INFILE '/docker-entrypoint-initdb.d/csv/nodes.csv'
INTO TABLE nodes
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(name, area_id, x, y);

LOAD DATA INFILE '/docker-entrypoint-initdb.d/csv/edges.csv'
INTO TABLE edges
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(node_a_id, node_b_id, weight);

LOAD DATA INFILE '/docker-entrypoint-initdb.d/csv/locations.csv'
INTO TABLE locations
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(tow_truck_id, node_id, timestamp);

LOAD DATA INFILE '/docker-entrypoint-initdb.d/csv/orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(client_id, @dispatcher_id, @tow_truck_id, status, node_id, car_value, @completed_time, order_time)
SET
    dispatcher_id = NULLIF(@dispatcher_id, ''),
    tow_truck_id = NULLIF(@tow_truck_id, ''),
    completed_time = NULLIF(@completed_time, '');

LOAD DATA INFILE '/docker-entrypoint-initdb.d/csv/completed_orders.csv'
INTO TABLE completed_orders
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, tow_truck_id, completed_time);

-- sessions テーブルにテスト用のデータを追加
INSERT INTO sessions (user_id, session_token) VALUES (100001, "GclZwGGYuogTIbhixe6D3nC6JIMkFH");
