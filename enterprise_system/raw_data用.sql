--------------------------------------------
-- 船の予約管理用のDDL

-- データベース：dbt
-- スキーマ：ships_raw_dev
-- テーブル：SQLファイル管理
--------------------------------------------

/* スキーマの作成 */
CREATE SCHEMA IF NOT EXISTS ships_raw_dev;
select aa from bbb;

/* マスタ系テーブル（船・客室関連） */

/* 船マスタ（基本情報）テーブル */
DROP TABLE IF EXISTS ships_raw_dev.ships;
CREATE TABLE IF NOT EXISTS ships_raw_dev.ships (
  ship_id STRING
  , ship_name STRING NOT NULL
  , length DECIMAL(5, 2) NOT NULL
  , width DECIMAL(4, 2) NOT NULL
  , gross_tonnage INT64 NOT NULL
  , service_speed INT64 NOT NULL
  , max_passenger_capacity INT64 NOT NULL
  , start_date DATE NOT NULL
  , end_date DATE
);

INSERT INTO ships_raw_dev.ships (ship_id, ship_name, length, width, gross_tonnage, service_speed, max_passenger_capacity, start_date, end_date) VALUES
 ('S001', 'AppleMaru', 199.6, 27.1, 14500, 23, 502, '2022-05-01', '9999-12-31')
 , ('S002', 'BananaMaru', 199.6, 27.1, 14500, 23, 502, '2022-06-14', '9999-12-31')
 , ('S003', 'OrangeMaru', 95.1, 22.1, 15301, 20, 665, '2023-01-10', '9999-12-31')
 , ('S004', 'GrapeMaru', 95.1, 22.1, 15301, 20, 665, '2023-03-05', '9999-12-31')
;


/* 客室クラス定義マスタテーブル */
DROP TABLE IF EXISTS ships_raw_dev.room_class_masters;
CREATE TABLE IF NOT EXISTS ships_raw_dev.room_class_masters (
  room_class_id STRING
  , room_class_name STRING
  , capacity_per_room INT64
  , description STRING
);

INSERT INTO ships_raw_dev.room_class_masters VALUES
 ('SY', 'スイート（洋室）', 2, '二名個室。「室単位」で予約。')
 , ('SW', 'スイート（和室）', 4, '四名個室。「室単位」で予約。')
 , ('DX', 'デラックスシングル', 1, '一人用個室。「室単位」で予約。')
 , ('TR', 'ツーリング（寝台）', 1, '一人用個室。「室単位」で予約。')
 , ('EC', 'エコノミー（雑魚寝）', 16, '大部屋。「エリアの定員」で管理。部屋番号が固定されない。')
 , ('FC', '一等室', 2, '二名個室。「室単位」で予約。')
 , ('SC', '二等室', 8, '八名部屋。「エリアの定員」で管理。部屋番号が固定されない。')
 , ('TC', '三等室', 40, '大部屋。「エリアの定員」で管理。部屋番号が固定されない。。')
;


/* 船別客室設定テーブル */
DROP TABLE IF EXISTS ships_raw_dev.ship_room_classes;
CREATE TABLE ships_raw_dev.ship_room_classes (
  ship_id STRING
  , room_class_id STRING
  , room_count INT64
  , capacity_per_room INT64
  , total_occupancy INT64
);

INSERT INTO ships_raw_dev.ship_room_classes (ship_id, room_class_id, room_count, capacity_per_room, total_occupancy) VALUES
 -- Apple, Banana (502名)
 ('S001', 'SY', 20, 2, 40), ('S001', 'SW', 5, 4, 20), ('S001', 'DX', 40, 1, 40), ('S001', 'TR', 50, 1, 50), ('S001', 'EC', 22, 16, 352)
 ,('S002', 'SY', 20, 2, 40), ('S002', 'SW', 5, 4, 20), ('S002', 'DX', 40, 1, 40), ('S002', 'TR', 50, 1, 50), ('S002', 'EC', 22, 16, 352)
 -- Orange, Grape (540名)
 ,('S003', 'FC', 6, 2, 12), ('S003', 'SC', 6, 8, 48), ('S003', 'TC', 12, 40, 480)
 ,('S004', 'FC', 6, 2, 12), ('S004', 'SC', 6, 8, 48), ('S004', 'TC', 12, 40, 480)
;



/* マスタ系テーブル（航路・港関連） */

/* 港テーブル */
DROP TABLE IF EXISTS ships_raw_dev.ports;
CREATE TABLE ships_raw_dev.ports (
  port_id STRING
  , port_name STRING
);

INSERT INTO ships_raw_dev.ports VALUES
 ('P1', 'ABC港'), ('P2', 'XYZ港'), ('P3', 'PQL港')
;


/* 航路テーブル */
DROP TABLE IF EXISTS ships_raw_dev.routes;
CREATE TABLE IF NOT EXISTS ships_raw_dev.routes (
  route_id STRING
  , route_name STRING
  , is_active BOOLEAN
);

INSERT INTO ships_raw_dev.routes (route_id, route_name, is_active) VALUES
 ('R1', 'ABC-XYZ航路', TRUE), ('R2', 'ABC-PQL航路', TRUE)
;


/* 区間テーブル */
DROP TABLE IF EXISTS ships_raw_dev.sections;
CREATE TABLE IF NOT EXISTS ships_raw_dev.sections (
  route_id STRING
  , dep_section_seq INT64
  , arr_section_seq INT64
  , departure_port_id STRING
  , arrival_port_id STRING
  , travel_time_minutes INT64
);

INSERT INTO ships_raw_dev.sections (route_id, dep_section_seq, arr_section_seq, departure_port_id, arrival_port_id, travel_time_minutes) VALUES
 ('R1', 1, 2, 'P1', 'P2', 195) -- ABC->XYZ (3h15m)
 ,('R1', 1, 2, 'P2', 'P1', 195) -- XYZ->ABC
 ,('R2', 1, 2, 'P1', 'P3', 100) -- ABC->PQL (1h40m)
 ,('R2', 1, 2, 'P3', 'P1', 100) -- PQL->ABC
;


/* 運航ダイヤテーブル */
DROP TABLE IF EXISTS ships_raw_dev.schedules;
CREATE TABLE IF NOT EXISTS ships_raw_dev.schedules (
  schedule_id STRING
  , ship_id STRING
  , route_id STRING
  , departure_port_id STRING
  , arrival_port_id STRING
  , departure_time DATETIME
  , arrival_time DATETIME
);

DELETE FROM ships_raw_dev.schedules WHERE TRUE;
INSERT INTO ships_raw_dev.schedules (
    schedule_id, ship_id, route_id, departure_port_id, arrival_port_id, departure_time, arrival_time
)
WITH date_range AS (
  SELECT CAST(day AS DATE) AS day 
  FROM generate_series(DATE '2026-03-01', DATE '2026-03-31', INTERVAL 1 DAY) AS t(day) -- 開始日と終了日を手動で入力する
)
, base_timetable AS (
  -- R1航路 (AppleMaru)
  SELECT 'S001' AS ship_id, 'R1' AS  route_id, 'P1' AS departure_port_id, 'P2' AS arrival_port_id, '080000' AS  dep_time, '111500' AS  arr_time UNION ALL
  SELECT 'S001' AS ship_id, 'R1' AS  route_id, 'P2' AS departure_port_id, 'P1' AS arrival_port_id, '131500' AS  dep_time, '163000' AS  arr_time UNION ALL
  SELECT 'S001' AS ship_id, 'R1' AS  route_id, 'P1' AS departure_port_id, 'P2' AS arrival_port_id, '183000' AS  dep_time, '214500' AS  arr_time UNION ALL
  SELECT 'S001' AS ship_id, 'R1' AS  route_id, 'P2' AS departure_port_id, 'P1' AS arrival_port_id, '234500' AS  dep_time, '030000' AS  arr_time UNION ALL

  -- R1航路 (BananaMaru)
  SELECT 'S002' AS ship_id, 'R1' AS  route_id, 'P2' AS departure_port_id, 'P1' AS arrival_port_id, '080000' AS  dep_time, '111500' AS  arr_time UNION ALL
  SELECT 'S002' AS ship_id, 'R1' AS  route_id, 'P1' AS departure_port_id, 'P2' AS arrival_port_id, '131500' AS  dep_time, '163000' AS  arr_time UNION ALL
  SELECT 'S002' AS ship_id, 'R1' AS  route_id, 'P2' AS departure_port_id, 'P1' AS arrival_port_id, '183000' AS  dep_time, '214500' AS  arr_time UNION ALL
  SELECT 'S002' AS ship_id, 'R1' AS  route_id, 'P1' AS departure_port_id, 'P2' AS arrival_port_id, '234500' AS  dep_time, '030000' AS  arr_time UNION ALL

  -- R2航路 (OrangeMaru)
  SELECT 'S003' AS ship_id, 'R2' AS  route_id, 'P1' AS departure_port_id, 'P3' AS arrival_port_id, '070000' AS  dep_time, '084000' AS  arr_time UNION ALL
  SELECT 'S003' AS ship_id, 'R2' AS  route_id, 'P3' AS departure_port_id, 'P1' AS arrival_port_id, '092000' AS  dep_time, '110000' AS  arr_time UNION ALL
  SELECT 'S003' AS ship_id, 'R2' AS  route_id, 'P1' AS departure_port_id, 'P3' AS arrival_port_id, '114000' AS  dep_time, '132000' AS  arr_time UNION ALL
  SELECT 'S003' AS ship_id, 'R2' AS  route_id, 'P3' AS departure_port_id, 'P1' AS arrival_port_id, '140000' AS  dep_time, '154000' AS  arr_time UNION ALL
  SELECT 'S003' AS ship_id, 'R2' AS  route_id, 'P1' AS departure_port_id, 'P3' AS arrival_port_id, '162000' AS  dep_time, '180000' AS  arr_time UNION ALL
  SELECT 'S003' AS ship_id, 'R2' AS  route_id, 'P3' AS departure_port_id, 'P1' AS arrival_port_id, '184000' AS  dep_time, '202000' AS  arr_time UNION ALL
  SELECT 'S003' AS ship_id, 'R2' AS  route_id, 'P1' AS departure_port_id, 'P3' AS arrival_port_id, '210000' AS  dep_time, '224000' AS  arr_time UNION ALL
  SELECT 'S003' AS ship_id, 'R2' AS  route_id, 'P3' AS departure_port_id, 'P1' AS arrival_port_id, '232000' AS  dep_time, '010000' AS  arr_time UNION ALL

  -- R2航路 (GrapeMaru)
  SELECT 'S004' AS ship_id, 'R2' AS  route_id, 'P3' AS departure_port_id, 'P1' AS arrival_port_id, '070000' AS  dep_time, '084000' AS  arr_time UNION ALL
  SELECT 'S004' AS ship_id, 'R2' AS  route_id, 'P1' AS departure_port_id, 'P3' AS arrival_port_id, '092000' AS  dep_time, '110000' AS  arr_time UNION ALL
  SELECT 'S004' AS ship_id, 'R2' AS  route_id, 'P3' AS departure_port_id, 'P1' AS arrival_port_id, '114000' AS  dep_time, '132000' AS  arr_time UNION ALL
  SELECT 'S004' AS ship_id, 'R2' AS  route_id, 'P1' AS departure_port_id, 'P3' AS arrival_port_id, '140000' AS  dep_time, '154000' AS  arr_time UNION ALL
  SELECT 'S004' AS ship_id, 'R2' AS  route_id, 'P3' AS departure_port_id, 'P1' AS arrival_port_id, '162000' AS  dep_time, '180000' AS  arr_time UNION ALL
  SELECT 'S004' AS ship_id, 'R2' AS  route_id, 'P1' AS departure_port_id, 'P3' AS arrival_port_id, '184000' AS  dep_time, '202000' AS  arr_time UNION ALL
  SELECT 'S004' AS ship_id, 'R2' AS  route_id, 'P3' AS departure_port_id, 'P1' AS arrival_port_id, '210000' AS  dep_time, '224000' AS  arr_time UNION ALL
  SELECT 'S004' AS ship_id, 'R2' AS  route_id, 'P1' AS departure_port_id, 'P3' AS arrival_port_id, '232000' AS  dep_time, '010000' AS  arr_time
)
SELECT 
  strftime(day, '%Y%m%d') || ship_id || substring(dep_time, 1, 2) AS schedule_id
  , ship_id
  , route_id
  , departure_port_id
  , arrival_port_id
  , strptime(strftime(day, '%Y%m%d') || dep_time, '%Y%m%d%H%M%S') AS departure_time
  , CASE 
      WHEN arr_time < dep_time THEN 
        strptime(strftime(day + INTERVAL 1 DAY, '%Y%m%d') || arr_time, '%Y%m%d%H%M%S')
      ELSE 
        strptime(strftime(day, '%Y%m%d') || arr_time, '%Y%m%d%H%M%S')
    END AS arrival_time
FROM date_range CROSS JOIN base_timetable
;



/* トランザクション系テーブル（予約・在庫） */

/* 予約基本情報テーブル */
DROP TABLE IF EXISTS ships_raw_dev.reservations;
CREATE TABLE IF NOT EXISTS ships_raw_dev.reservations (
  reservation_id STRING
  , reservation_name STRING
  , reservation_email STRING
  , reservation_date DATE
);


/* 予約明細情報テーブル */
DROP TABLE IF EXISTS ships_raw_dev.reservation_details;
CREATE TABLE IF NOT EXISTS ships_raw_dev.reservation_details (
  reservation_id STRING
  , detail_id STRING
  , schedule_id STRING
  , passenger_id STRING
  , passenger_type STRING
  , ship_id STRING
  , room_class_id STRING
  , applied_fare INT64
);


/* 在庫テーブル */
DROP TABLE IF EXISTS ships_raw_dev.inventories;
CREATE TABLE IF NOT EXISTS ships_raw_dev.inventories (
  schedule_id STRING
  , room_class_id STRING
  , room_count INT64
  , remaining_room_cnt INT64
  , num_of_people INT64
  , remaining_num_of_people INT64
);
INSERT INTO ships_raw_dev.inventories (
  schedule_id, room_class_id, room_count, remaining_room_cnt, num_of_people, remaining_num_of_people
)
SELECT 
  s.schedule_id
  , src.room_class_id 
  , src.room_count
  , src.room_count
  , src.total_occupancy
  , src.total_occupancy
FROM
  ships_raw_dev.schedules s
  INNER JOIN ships_raw_dev.ship_room_classes src ON s.ship_id = src.ship_id
;



--------------------------------------------
-- 船の予約管理用のDML
-- 開発環境用スキーマ：ships_raw_dev
--------------------------------------------

/* 予約基本情報 (reservations) の生成 */
-- 1ヶ月間で約5000件の予約データを生成
INSERT INTO ships_raw_dev.reservations (reservation_id, reservation_name, reservation_email, reservation_date)
WITH base_dates AS (
  SELECT i AS id FROM generate_series(1, 5000) AS t(i)
)
, random_data AS (
  SELECT 
    id
    , DATE '2026-01-01' + INTERVAL (floor(random() * 31)) DAY AS r_date  -- 予約月（搭乗月-1か月ぐらい）
    , uuid()::VARCHAR AS u_id
  FROM base_dates
)
SELECT 
'R' || strftime(r_date, '%Y%m%d') || '-' || lpad(id::VARCHAR, 4, '0') AS reservation_id
  , 'User_' || substring(u_id, 1, 8) AS reservation_name
  , 'user_' || id || '@example.com' AS reservation_email
  , r_date AS reservation_date
FROM random_data
;

/* 予約明細情報 (reservation_details) の生成 */
-- 各スケジュールごとにランダムなクラスを数件ずつ予約
INSERT INTO ships_raw_dev.reservation_details (reservation_id, detail_id, schedule_id, passenger_id, passenger_type, ship_id, room_class_id, applied_fare)
WITH random_reservations AS (
  SELECT 
    s.schedule_id
    , s.ship_id
    , src.room_class_id
    , f.fare
    , f.is_unit_rate
    , src.capacity_per_room
    , CAST(floor(random() * 5) AS INT) + 1 AS num_bookings -- 1つのスケジュール・クラスにつき最大5件の予約を生成
  FROM 
    ships_raw_dev.schedules s
    CROSS JOIN ships_raw_dev.ship_room_classes src
    INNER JOIN ships_seeds_master_dev.fare_type f 
      ON src.room_class_id = f.room_class_id
  WHERE 
    s.ship_id = src.ship_id
)
, expanded_bookings AS (
  SELECT 
    r.*
    , uuid() AS u_id
  FROM
    random_reservations r
    , generate_series(1, 5) AS t(sub_id) -- 最大値5で固定し、後でnum_bookingsでフィルタ
  WHERE t.sub_id <= r.num_bookings
)
, numbered_bookings AS (
  SELECT 
    *
    , ROW_NUMBER() OVER(PARTITION BY schedule_id, room_class_id ORDER BY u_id) as booking_rank
  FROM expanded_bookings
)
SELECT 
  res.reservation_id
  , LPAD((ROW_NUMBER() OVER(PARTITION BY res.reservation_id))::VARCHAR, 3, '0') AS detail_id
  , nb.schedule_id
  , 'P-' || substring(nb.u_id::VARCHAR, 1, 8) AS passenger_id
  , 'ADULT' AS passenger_type
  , nb.ship_id
  , nb.room_class_id
  , nb.fare AS applied_fare
FROM numbered_bookings nb
INNER JOIN (
  SELECT reservation_id, ROW_NUMBER() OVER() as rn 
  FROM ships_raw_dev.reservations
) res
  ON (abs(hash(nb.u_id::VARCHAR)) % 5000) = res.rn - 1
INNER JOIN ships_raw_dev.inventories i 
  ON nb.schedule_id = i.schedule_id AND nb.room_class_id = i.room_class_id
WHERE 
  -- 予約の連番が、在庫（room_count）以下のものだけを採用する
  nb.booking_rank <= i.room_count
;
  
  
  
/* 在庫テーブル (inventories) の更新（予約された分を差し引く） */
UPDATE ships_raw_dev.inventories i
SET 
  remaining_room_cnt = i.room_count - agg.booked_rooms,
  remaining_num_of_people = i.num_of_people - agg.booked_people
FROM (
  SELECT 
    rd.schedule_id
    , rd.room_class_id
    , COUNT(*) AS booked_rooms -- 1レコード=1ユニット販売の前提
    , SUM(CASE 
        WHEN f.is_unit_rate THEN m.capacity_per_room -- ルームチャージは定員分減らす
        ELSE 1 -- エコノミー等は1人分
      END) AS booked_people
  FROM ships_raw_dev.reservation_details rd
  JOIN ships_seeds_master_dev.fare_type f ON rd.room_class_id = f.room_class_id
  JOIN ships_raw_dev.room_class_masters m ON rd.room_class_id = m.room_class_id
  GROUP BY 1, 2
) agg
WHERE i.schedule_id = agg.schedule_id 
  AND i.room_class_id = agg.room_class_id
;