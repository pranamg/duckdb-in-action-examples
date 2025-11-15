duckdb my_ch03.db
import database 'ch03_db';
CREATE TABLE IF NOT EXISTS systems (
    id INTEGER PRIMARY KEY,
    name VARCHAR(128) NOT NULL
);
CREATE TABLE IF NOT EXISTS readings (
    system_id INTEGER NOT NULL,
    read_on TIMESTAMP NOT NULL,
    power DECIMAL(10, 3) NOT NULL DEFAULT 0.0 CHECK (power >= 0.0),
    PRIMARY KEY (system_id, read_on),
    FOREIGN KEY (system_id) REFERENCES systems(id)
);
CREATE SEQUENCE IF NOT EXISTS prices_id INCREMENT BY 1 MINVALUE 10;
CREATE TABLE IF NOT EXISTS prices (
    id INTEGER PRIMARY KEY DEFAULT (nextval('prices_id')),
    value DECIMAL(5, 2) NOT NULL,
    valid_from DATE NOT NULL,
    CONSTRAINT prices_uk UNIQUE (valid_from)
);
SELECT sequence_name FROM duckdb_sequences();
ALTER TABLE prices
ADD COLUMN IF NOT EXISTS valid_until DATE;
CREATE TABLE prices_duplicate AS
SELECT * FROM prices;
CREATE OR REPLACE VIEW v_power_per_day AS
SELECT system_id,
       date_trunc('day', read_on)        AS day,
       round(sum(power)  / 4 / 1000, 2)  AS kWh,
FROM readings
GROUP BY system_id, day;
SELECT * FROM v_power_per_day;
DESCRIBE readings;
DESCRIBE prices;
DESCRIBE SELECT read_on, power FROM readings;
DESCRIBE VALUES (4711, '2023-05-28 11:00'::timestamp, 42);
INSERT INTO prices
VALUES (1, 11.59, '2018-12-01', '2019-01-01');
INSERT INTO prices
VALUES (1, 11.59, '2018-12-01', '2019-01-01')
ON CONFLICT DO NOTHING;
INSERT INTO prices(value, valid_from, valid_until)
VALUES (11.47, '2019-01-01', '2019-02-01'),
       (11.35, '2019-02-01', '2019-03-01'),
       (11.23, '2019-03-01', '2019-04-01'),
       (11.11, '2019-04-01', '2019-05-01'),
       (10.95, '2019-05-01', '2019-06-01');
INSERT INTO prices(value, valid_from, valid_until)
VALUES (11.47, '2019-01-01', '2019-02-01')
ON CONFLICT (valid_from)
  DO UPDATE SET value = excluded.value;
INSERT INTO prices(value, valid_from, valid_until)
SELECT * FROM 'prices.csv' src;
INSTALL 'httpfs';
LOAD 'httpfs';

DESCRIBE SELECT * FROM
    'https://oedi-data-lake.s3.amazonaws.com/pvdaq/csv/systems.csv';
INSTALL 'httpfs';
LOAD 'httpfs';
INSERT INTO systems(id, name)
SELECT DISTINCT system_id, system_public_name
FROM 'https://oedi-data-lake.s3.amazonaws.com/pvdaq/csv/systems.csv'
ORDER BY system_id ASC;
INSERT INTO readings(system_id, read_on, power)
SELECT SiteId, "Date-Time",
       CASE
           WHEN ac_power < 0 OR ac_power IS NULL THEN 0
           ELSE ac_power END
FROM read_csv_auto(
       'https://developer.nrel.gov/api/pvdaq/v3/data_file?' ||
       'api_key=DEMO_KEY&system_id=34&year=2019'
     );
SELECT * FROM readings WHERE date_trunc('day', read_on) = '2019-08-26' AND power <> 0;
`SELECT * FROM v_power_per_day WHERE day = '2019-08-26'`
SELECT *
FROM (
    SELECT 'https://' || years.range || '.csv' AS v
    FROM range(2019,2021) years
) urls, read_csv_auto(urls.v);

