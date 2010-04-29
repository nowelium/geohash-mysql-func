DROP FUNCTION IF EXISTS `geohash_encode`;
DELIMITER //
CREATE FUNCTION `geohash_encode` (
    _latitude DOUBLE(10, 7),
    _longitude DOUBLE(10, 7),
    _precision TINYINT UNSIGNED
)
RETURNS VARCHAR(12)
DETERMINISTIC NO SQL
COMMENT 'geohash_encode(57.64911, 10.40744, 12) => u4pruydqquvx'
BEGIN
    DECLARE latL DOUBLE(10, 7) DEFAULT -90.0;
    DECLARE latR DOUBLE(10, 7) DEFAULT 90.0;

    DECLARE lonT DOUBLE(10, 7) DEFAULT -180.0;
    DECLARE lonB DOUBLE(10, 7) DEFAULT 180.0;

    DECLARE bit TINYINT UNSIGNED DEFAULT 0;
    DECLARE bit_pos TINYINT UNSIGNED DEFAULT 0;
    DECLARE ch CHAR(1) DEFAULT '';
    DECLARE ch_pos INT UNSIGNED DEFAULT 0;
    DECLARE mid DOUBLE(10, 7) DEFAULT NULL;

    DECLARE even TINYINT UNSIGNED DEFAULT 1;
    DECLARE geohash VARCHAR(12) DEFAULT '';
    DECLARE geohash_length TINYINT UNSIGNED DEFAULT 0;

    /*
    CREATE TEMPORARY TABLE `TMP_BIT` (`pos` TINYINT UNSIGNED, `val` TINYINT UNSIGNED) ENGINE=MEMORY;
    CREATE TEMPORARY TABLE `TMP_BASE32` (`pos` TINYINT UNSIGNED, `val` CHAR(1)) ENGINE=MEMORY;

    INSERT INTO `TMP_BIT` (`pos`, `val`) VALUES (0, 16), (1, 8), (2, 4), (3, 2), (4, 1);
    INSERT INTO `TMP_BASE32` (`pos`, `val`) VALUES
        (0, '0'), (1, '1'), (2, '2'), (3, '3'), (4, '4'),
        (5, '5'), (6, '6'), (7, '7'), (8, '8'), (9, '9'),
        (10, 'b'), (11, 'c'), (12, 'd'), (13, 'e'), (14, 'f'),
        (15, 'g'), (16, 'h'), (17, 'j'), (18, 'k'), (19, 'm'),
        (20, 'n'), (21, 'p'), (22, 'q'), (23, 'r'), (24, 's'),
        (25, 't'), (26, 'u'), (27, 'v'), (28, 'w'), (29, 'x'),
        (30, 'y'), (31, 'z');
    */

    IF _precision IS NULL THEN
        SET _precision = 12;
    END IF;

    WHILE geohash_length < _precision DO
        IF even = 1 THEN
            --
            -- is even
            --
            
            SET mid = (lonT + lonB) / 2;
            IF mid < _longitude THEN
                SET bit = geohash_bit(bit_pos);
                /*
                 * SELECT `val` INTO bit FROM `TMP_BIT` WHERE `pos` = bit_pos;
                 */
                SET ch_pos = ch_pos | bit;
                SET lonT = mid;
            ELSE
                SET lonB = mid;
            END IF;
        ELSE
            --
            -- not even
            --
            
            SET mid = (latL + latR) / 2;
            IF mid < _latitude THEN
                SET bit = geohash_bit(bit_pos);
                /*
                 * SELECT `val` INTO bit FROM `TMP_BIT` WHERE `pos` = bit_pos;
                 */
                SET ch_pos = ch_pos | bit;
                SET latL = mid;
            ELSE
                SET latR = mid;
            END IF;
        END IF;

        -- toggle even
        SET even = !even;

        IF bit_pos < 4 THEN
            SET bit_pos = bit_pos + 1;
        ELSE
            SET ch = geohash_base32(ch_pos);
            /*
             * SELECT `val` INTO ch FROM `TMP_BASE32` WHERE `pos` = ch_pos;
             */
            SET geohash = CONCAT(geohash, ch);
            SET bit_pos = 0;
            SET ch_pos = 0;
        END IF;

        SET geohash_length = LENGTH(geohash);
    END WHILE;

    /*
    DROP TEMPORARY TABLE IF EXISTS `TMP_BIT`;
    DROP TEMPORARY TABLE IF EXISTS `TMP_BASE32`;
    */

    RETURN geohash;
END;
//
DELIMITER ;

DROP FUNCTION IF EXISTS `geohash_decode`;
DELIMITER //
CREATE FUNCTION `geohash_decode` (
    _geohash VARCHAR(12)
)
RETURNS CHAR(77)
DETERMINISTIC NO SQL
COMMENT 'geohash_decode(u4pru) => csv'
BEGIN
    DECLARE latL DOUBLE(10, 7) DEFAULT -90.0;
    DECLARE latR DOUBLE(10, 7) DEFAULT 90.0;

    DECLARE lonT DOUBLE(10, 7) DEFAULT -180.0;
    DECLARE lonB DOUBLE(10, 7) DEFAULT 180.0;

    DECLARE lat_err DOUBLE(10, 7) DEFAULT 90.0;
    DECLARE lon_err DOUBLE(10, 7) DEFAULT 180.0;

    DECLARE ch CHAR(1) DEFAULT '';
    DECLARE ch_pos INT UNSIGNED DEFAULT 0;

    DECLARE even TINYINT UNSIGNED DEFAULT 1;
    DECLARE geohash_length TINYINT UNSIGNED DEFAULT 0;
    DECLARE geohash_pos TINYINT UNSIGNED DEFAULT 0;
    DECLARE pos TINYINT UNSIGNED DEFAULT 0;

    DECLARE mask TINYINT UNSIGNED DEFAULT 0;
    DECLARE masked_val TINYINT UNSIGNED DEFAULT 0;

    DECLARE buf VARCHAR(77) DEFAULT '';

    SET geohash_length = LENGTH(_geohash);

    WHILE geohash_pos < geohash_length DO
        SET ch = geohash_base32(geohash_pos);
        SET ch_pos = geohash_base32_index(ch);

        SET pos = 0;
        WHILE pos < 5 DO
            SET mask = geohash_bit(pos);
            SET masked_val = ch_pos & mask;

            IF even = 1 THEN
                SET lon_err = lon_err / 2;

                IF masked_val != 0 THEN
                    SET lonT = (lonT + lonB) / 2;
                ELSE
                    SET lonB = (lonT + lonB) / 2;
                END IF;
            ELSE
                SET lat_err = lat_err / 2;

                IF masked_val != 0 THEN
                    SET latL = (latL + latR) / 2;
                ELSE
                    SET latR = (latL + latR) / 2;
                END IF;
            END IF;
            
            SET even = !even;
            SET pos = pos + 1;
        END WHILE;

        SET geohash_pos = geohash_pos + 1;
    END WHILE;

    SET lat_err = (latL + latR) / 2;
    SET lon_err = (lonT + lonB) / 2;

    /*
    IF _column_output = 1 THEN
        SELECT latL AS 'latitude', lonT AS 'longitude'
        UNION ALL
        SELECT latR AS 'latitude', lonB AS 'longitude'
        UNION ALL
        SELECT lat_err AS 'latitude', lon_err AS 'longitude';
    END IF;
    */

    SET buf = CONCAT(buf, latL, ',', lonT);
    SET buf = CONCAT(buf, '\n');
    SET buf = CONCAT(buf, latR, ',', lonB);
    SET buf = CONCAT(buf, '\n');
    SET buf = CONCAT(buf, lat_err, ',', lon_err);

    RETURN buf;
END;
//
DELIMITER ;

DROP FUNCTION IF EXISTS `geohash_bit`;
DELIMITER //
CREATE FUNCTION `geohash_bit` (
    _bit TINYINT UNSIGNED
)
RETURNS TINYINT UNSIGNED
DETERMINISTIC NO SQL
COMMENT 'geohash_bit(0) => 16, geohash_bit(1) => 8'
BEGIN
    DECLARE bit TINYINT UNSIGNED DEFAULT NULL;

    CASE _bit
        WHEN 0 THEN SET bit = 16;
        WHEN 1 THEN SET bit = 8;
        WHEN 2 THEN SET bit = 4;
        WHEN 3 THEN SET bit = 2;
        WHEN 4 THEN SET bit = 1;
    END CASE;

    RETURN bit;
END;
//
DELIMITER ;


DROP FUNCTION IF EXISTS `geohash_base32`;
DELIMITER //
CREATE FUNCTION `geohash_base32` (
    _index TINYINT UNSIGNED
)
RETURNS CHAR(1)
DETERMINISTIC NO SQL
COMMENT 'geohash_base32(0) => "0", geohash_base32(31) => "z"'
BEGIN
    DECLARE ch CHAR(1) DEFAULT NULL;

    CASE _index
        WHEN 0 THEN SET ch = '0';
        WHEN 1 THEN SET ch = '1';
        WHEN 2 THEN SET ch = '2';
        WHEN 3 THEN SET ch = '3';
        WHEN 4 THEN SET ch = '4';
        WHEN 5 THEN SET ch = '5';
        WHEN 6 THEN SET ch = '6';
        WHEN 7 THEN SET ch = '7';
        WHEN 8 THEN SET ch = '8';
        WHEN 9 THEN SET ch = '9';
        WHEN 10 THEN SET ch = 'b';
        WHEN 11 THEN SET ch = 'c';
        WHEN 12 THEN SET ch = 'd';
        WHEN 13 THEN SET ch = 'e';
        WHEN 14 THEN SET ch = 'f';
        WHEN 15 THEN SET ch = 'g';
        WHEN 16 THEN SET ch = 'h';
        WHEN 17 THEN SET ch = 'j';
        WHEN 18 THEN SET ch = 'k';
        WHEN 19 THEN SET ch = 'm';
        WHEN 20 THEN SET ch = 'n';
        WHEN 21 THEN SET ch = 'p';
        WHEN 22 THEN SET ch = 'q';
        WHEN 23 THEN SET ch = 'r';
        WHEN 24 THEN SET ch = 's';
        WHEN 25 THEN SET ch = 't';
        WHEN 26 THEN SET ch = 'u';
        WHEN 27 THEN SET ch = 'v';
        WHEN 28 THEN SET ch = 'w';
        WHEN 29 THEN SET ch = 'x';
        WHEN 30 THEN SET ch = 'y';
        WHEN 31 THEN SET ch = 'z';
    END CASE;

    RETURN ch;
END;
//
DELIMITER ;

DROP FUNCTION IF EXISTS `geohash_base32_index`;
DELIMITER //
CREATE FUNCTION `geohash_base32_index` (
    _ch CHAR(1)
)
RETURNS TINYINT UNSIGNED
DETERMINISTIC NO SQL
COMMENT 'geohash_base32_index("b") => 10, geohash_base32_index("z") => 31'
BEGIN
    DECLARE idx TINYINT UNSIGNED DEFAULT NULL;

    CASE _ch
        WHEN '0' THEN SET idx = 0;
        WHEN '1' THEN SET idx = 1;
        WHEN '2' THEN SET idx = 2;
        WHEN '3' THEN SET idx = 3;
        WHEN '4' THEN SET idx = 4;
        WHEN '5' THEN SET idx = 5;
        WHEN '6' THEN SET idx = 6;
        WHEN '7' THEN SET idx = 7;
        WHEN '8' THEN SET idx = 8;
        WHEN '9' THEN SET idx = 9;
        WHEN 'b' THEN SET idx = 10;
        WHEN 'c' THEN SET idx = 11;
        WHEN 'd' THEN SET idx = 12;
        WHEN 'e' THEN SET idx = 13;
        WHEN 'f' THEN SET idx = 14;
        WHEN 'g' THEN SET idx = 15;
        WHEN 'h' THEN SET idx = 16;
        WHEN 'j' THEN SET idx = 17;
        WHEN 'k' THEN SET idx = 18;
        WHEN 'm' THEN SET idx = 19;
        WHEN 'n' THEN SET idx = 20;
        WHEN 'p' THEN SET idx = 21;
        WHEN 'q' THEN SET idx = 22;
        WHEN 'r' THEN SET idx = 23;
        WHEN 's' THEN SET idx = 24;
        WHEN 't' THEN SET idx = 25;
        WHEN 'u' THEN SET idx = 26;
        WHEN 'v' THEN SET idx = 27;
        WHEN 'w' THEN SET idx = 28;
        WHEN 'x' THEN SET idx = 29;
        WHEN 'y' THEN SET idx = 30;
        WHEN 'z' THEN SET idx = 31;
    END CASE;

    RETURN idx;
END;
//
DELIMITER ;

