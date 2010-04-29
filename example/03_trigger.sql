delimiter //
create trigger `tgr_after_insert_postal_code` after insert on `postal_code`
for each row begin
    declare _geo_hash varchar(12);

    SET _geo_hash = geohash_encode(NEW.latitude, NEW.longitude, 12);
    insert into postal_geohash(`geo_hash`, `postal_id`) values (_geo_hash, NEW.postal_id);
end
//
delimiter ;

