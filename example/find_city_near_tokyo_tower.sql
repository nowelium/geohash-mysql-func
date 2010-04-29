-- tokyo tower
-- latitude: 35.658329
-- longitude: 139.746645

set @geo_hash = geohash_encode(35.658329, 139.746645, 6);
select country_code, place_name, admin_name1, admin_name2, admin_name3
from postal_code as pc inner join (
    select postal_id from postal_geohash
    where substr(geo_hash, 1, 6) = @geo_hash
) as gh on (
    pc.postal_id = gh.postal_id
)

