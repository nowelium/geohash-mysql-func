drop procedure if exists `find_near_city`;
delimiter //
create procedure `find_near_city` (
    _latitude DOUBLE(10, 7),
    _longitude DOUBLE(10, 7),
    _precision TINYINT UNSIGNED
)
begin
    declare hash varchar(12);
    set hash = geohash_encode(_latitude, _longitude, _precision);

    create temporary table `tmp` (`postal_id` integer unsigned, `prefix` varchar(12)) ENGINE=MEMORY;
    insert into tmp (postal_id, prefix) select postal_id, substr(geo_hash, 1, _precision) from postal_geohash;

    select country_code, place_name, admin_name1, admin_name2, admin_name3
    from postal_code as pc inner join (
        select postal_id
        from tmp
        where prefix = hash
    ) as gh on (
        pc.postal_id = gh.postal_id
    );

    drop temporary table `tmp`;
end;
//
delimiter ;
