create or replace trigger at_physical_location_t02
   before insert or update
   on at_physical_location
   referencing new as new old as old
   for each row
declare
   l_lat_lon_changed boolean;
   l_update_non_null boolean;
   l_county_code     integer;
begin
   if :new.latitude is not null and :new.longitude is not null then
      -------------------------------------------------------------
      -- won't apply to sub-locations that inherit their lat/lon --
      -------------------------------------------------------------
      l_lat_lon_changed :=
         :old.latitude is null
         or :old.longitude is null
         or :new.latitude != :old.latitude
         or :new.longitude != :old.longitude;
      if l_lat_lon_changed then
         l_update_non_null := instr(
            'TRUE',
            upper(cwms_properties.get_property(
               'CWMSDB',
               'location.update_non_null_items_on_latlon_change',
               'false'))) = 1;
      end if;
      if :new.county_code is null or :new.county_code = 0 or (l_lat_lon_changed and l_update_non_null) then
         -------------------------------------
         -- get the county from the lat/lon --
         -------------------------------------
         :new.county_code := cwms_loc.get_county_code(:new.latitude, :new.longitude);
      end if;
      if :new.nation_code is null or (l_lat_lon_changed and l_update_non_null) then
         ----------------------------------------------
         -- get the nation office from the lat/lon --
         ----------------------------------------------
         :new.nation_code := cwms_loc.get_nation_id(:new.latitude, :new.longitude);
      end if;
      ----------------------------------------
      -- validate nation/county combination --
      ----------------------------------------
      if cwms_loc.valid_county_code_for_nation(:new.county_code, :new.nation_code) != 'T' then
         cwms_err.raise('ERROR', 'Cannot use county code of '||:new.county_code||' with nation code of '||nvl(:new.nation_code, '<NULL>'));
      end if;
      if :new.office_code is null or (l_lat_lon_changed and l_update_non_null) then
         ----------------------------------------------
         -- get the bounding office from the lat/lon --
         ----------------------------------------------
         :new.office_code := cwms_loc.get_bounding_ofc_code(:new.latitude, :new.longitude);
      end if;
      if :new.nearest_city is null or (l_lat_lon_changed and l_update_non_null) then
         -------------------------------------------
         -- get the nearest city from the lat/lon --
         -------------------------------------------
         :new.nearest_city := cwms_loc.get_nearest_city(:new.latitude, :new.longitude)(1);
      end if;
   end if;
exception
   when others then cwms_err.raise('ERROR', dbms_utility.format_error_backtrace);
end at_physical_location_t02;
/
