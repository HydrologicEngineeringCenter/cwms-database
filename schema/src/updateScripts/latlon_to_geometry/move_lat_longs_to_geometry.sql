-----------------------------------
-- create conversion notes table --
-----------------------------------
create table at_latlon_conversion(location_code number(14) primary key, conversion_note varchar2(256));

declare
   type srids_by_name_t is table of mdsys.sdo_coord_ref_sys.srid%type index by mdsys.sdo_coord_ref_sys.coord_ref_sys_name%type;
   l_srids_by_name srids_by_name_t;
   l_name mdsys.sdo_coord_ref_sys.coord_ref_sys_name%type;
   l_srid mdsys.sdo_coord_ref_sys.srid%type;
   l_geometry sdo_geometry;
begin
   ---------------------------
   -- collect SRIDs by name --
   ---------------------------
   for rec in (select coord_ref_sys_name, srid
                 from MDSYS.SDO_COORD_REF_SYS
                where coord_ref_sys_kind = 'GEOGRAPHIC2D'
                  and data_source = 'EPSG'
                order by 1, 2
              )
   loop
      l_name := upper(rec.coord_ref_sys_name);
      if not l_srids_by_name.exists(l_name) then
         l_srids_by_name(l_name) := rec.srid;
      end if;
   end loop;
   ---------------------------------------------------
   -- perform conversions from lat/long to geometry --
   ---------------------------------------------------
   for rec in (select location_code, horizontal_datum, latitude, longitude from at_physical_location) loop
      l_geometry := null;
      l_name := upper(trim(rec.horizontal_datum));
      if not l_srids_by_name.exists(l_name) and substr(l_name, 1, 3) in ('WGS', 'NAD') then
         l_name := substr(l_name, 1, 3)||' '||substr(l_name, 4);
      end if;
      case
      when rec.latitude is null or rec.longitude is null then
         insert into at_latlon_conversion values (rec.location_code, '[warning] No lat/long - geometry not created');
      when l_name is null then
         l_geometry := sdo_geometry(2001, 4326, sdo_point_type(rec.longitude, rec.latitude, null), null, null);
         insert into at_latlon_conversion values (rec.location_code, '[warning] No horizontal datum - created geometry as WGS 84 (4326)');
      when l_srids_by_name.exists(l_name) then
         l_srid := l_srids_by_name(l_name);
         l_geometry := sdo_geometry(2001, l_srid, sdo_point_type(rec.longitude, rec.latitude, null), null, null);
         if l_srid = 4326 then
            insert into at_latlon_conversion values (rec.location_code, '[okay   ] Already in WGS 84 (4326) - no conversion necessary');
         else
            l_geometry := sdo_cs.transform(l_geometry, 4326);
            insert into at_latlon_conversion values (rec.location_code, '[okay   ] Converted from '||l_name||' ('||l_srid||') to WGS 84 (4326)');
         end if;
      else
         l_geometry := sdo_geometry(2001, 4326, sdo_point_type(rec.longitude, rec.latitude, null), null, null);
         insert into at_latlon_conversion values (rec.location_code, '[warning] Unknown horizontal datum ('||l_name||') - created geometry as WGS 84 (4326)');
      end case;
      if l_geometry is not null then
         insert into at_location_geometry (location_code, geometry) values (rec.location_code, l_geometry);
      end if;
   end loop;
   commit;
end;
/