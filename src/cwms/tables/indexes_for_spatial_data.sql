/*
  These sql scripts MUST be run as the cwms_20 user. They insert data into
  user_sdo_geom_metadata which uses the logged-on schema as the "owner" of
  the stored data.
*/
@@cwms_agg_district_sidx.sql
@@cwms_cities_sp_sidx.sql
@@cwms_county_sp_sidx.sql
@@cwms_nation_sp_sidx.sql
@@cwms_nid_sidx.sql
@@cwms_offices_geoloc_sidx.sql
@@cwms_state_sp_sidx.sql
@@cwms_station_nws_sidx.sql
@@cwms_station_usgs_sidx.sql
@@cwms_time_zone_sp_sidx.sql
@@cwms_usace_dam_sidx.sql


