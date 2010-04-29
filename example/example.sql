set names utf8;

drop database if exists `geo_example`;
create database `geo_example` CHARACTER SET utf8;

use `geo_example`;

source 01_postal_code.sql;
source 02_postal_geohash.sql;
source 03_trigger.sql;
source 04_procedure.sql;
source ../geohash.sql;

system unzip -qo geonames/JP.zip -d geonames;
system unzip -qo geonames/US.zip -d geonames;
system unzip -qo geonames/FR.zip -d geonames;
system cat geonames/JP.txt geonames/US.txt geonames/FR.txt > countries.txt;

load data local infile 'countries.txt'
    into table `postal_code`
    fields terminated by '\t'
    lines terminated by '\n'
    (country_code, postal_code, place_name, admin_name1, admin_code1, admin_name2, admin_code2, admin_name3, latitude, longitude);

