create table `postal_geohash` (
    `geo_hash` varchar(12) not null,
    `postal_id` integer unsigned not null,
    INDEX `idx_geo_hash`(`geo_hash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8
PARTITION BY LINEAR KEY( `geo_hash` )
PARTITIONS 128;
