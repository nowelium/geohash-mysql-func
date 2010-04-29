create table `postal_code` (
    `postal_id` integer unsigned not null auto_increment,
    `country_code` char(2) not null,
    `postal_code` varchar(10),
    `place_name` varchar(100),
    `admin_name1` varchar(100),
    `admin_code1` varchar(20),
    `admin_name2` varchar(100),
    `admin_code2` varchar(20),
    `admin_name3` varchar(100),
    `latitude` double(10, 7),
    `longitude` double(10, 7),
    INDEX `idx_postal_id` (`postal_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8
PARTITION BY RANGE( CEILING( `longitude` div 15 ) )
SUBPARTITION BY HASH( CEILING( `latitude` div 5 ) )
SUBPARTITIONS 37 (
    PARTITION w180 VALUES LESS THAN (-180),
    PARTITION w165 VALUES LESS THAN (-165),
    PARTITION w150 VALUES LESS THAN (-150),
    PARTITION w135 VALUES LESS THAN (-135),
    PARTITION w120 VALUES LESS THAN (-120),
    PARTITION w105 VALUES LESS THAN (-105),
    PARTITION w090 VALUES LESS THAN (-90),
    PARTITION w075 VALUES LESS THAN (-75),
    PARTITION w060 VALUES LESS THAN (-60),
    PARTITION w045 VALUES LESS THAN (-45),
    PARTITION w030 VALUES LESS THAN (-30),
    PARTITION w015 VALUES LESS THAN (-15),
    PARTITION mid VALUES LESS THAN (0),
    PARTITION e015 VALUES LESS THAN (15),
    PARTITION e030 VALUES LESS THAN (30),
    PARTITION e045 VALUES LESS THAN (45),
    PARTITION e060 VALUES LESS THAN (60),
    PARTITION e075 VALUES LESS THAN (75),
    PARTITION e090 VALUES LESS THAN (90),
    PARTITION e105 VALUES LESS THAN (105),
    PARTITION e120 VALUES LESS THAN (120),
    PARTITION e135 VALUES LESS THAN (135),
    PARTITION e150 VALUES LESS THAN (150),
    PARTITION e165 VALUES LESS THAN (165),
    PARTITION e180 VALUES LESS THAN (180)
);
