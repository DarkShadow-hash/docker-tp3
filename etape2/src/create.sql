CREATE DATABASE IF NOT EXISTS mabase;
USE mabase;
CREATE TABLE IF NOT EXISTS matable (compteur INTEGER);
USE mysql;
GRANT ALL PRIVILEGES ON *.* TO 'monuser'@'%' IDENTIFIED BY 'password';
FLUSH PRIVILEGES;
-- INSERT INTO matable (compteur) SELECT count(*)+1 FROM matable;