--
--
prompt INSERT sdo geom metatdata for AT_LOCATION_GEOMETRY
--
--
insert into user_sdo_geom_metadata (table_name, column_name, diminfo, srid)
values (
   'AT_LOCATION_GEOMETRY',
   'GEOMETRY',
   sdo_dim_array(
      sdo_dim_element('X', -180, 180, .01),
      sdo_dim_element('Y', -90, 90, .01)
   ),
   4326
);

--
--
prompt CREATE AT_LOCATION_GEOMETRY
--
--
create index
   at_location_geometry_spidx
on
   at_location_geometry (geometry)
indextype is 
   mdsys.spatial_index_v2;
