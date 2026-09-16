
declare
   l_lines str_tab_t;
begin
   select text
     bulk collect
     into l_lines
     from user_source
    where name = 'ST_PHYSICAL_LOCATION'
    order by line;

   execute immediate
      'create or replace '
      ||replace(cwms_util.join_text(l_lines, null), 'PHYSICAL_LOCATION', 'LOCATION_GEOMETRY');
end;
/


declare
   type srids_by_name_t is table of mdsys.sdo_coord_ref_sys.srid%type
      index by mdsys.sdo_coord_ref_sys.coord_ref_sys_name%type;

   l_srids_by_name srids_by_name_t;
   l_name         mdsys.sdo_coord_ref_sys.coord_ref_sys_name%type;
   l_srid         mdsys.sdo_coord_ref_sys.srid%type;
   l_geometry     sdo_geometry;
   l_message      varchar2(32767);
begin
   ---------------------------
   -- Collect SRIDs by name --
   ---------------------------
   for rec in (
      select coord_ref_sys_name,
             srid
        from mdsys.sdo_coord_ref_sys
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
   -- Perform conversions from latitude/longitude    --
   -- to geometry                                   --
   ---------------------------------------------------
   for rec in (
      select location_code,
             horizontal_datum,
             latitude,
             longitude
        from at_physical_location
   )
   loop
      l_geometry := null;
      l_message  := null;
      l_name     := upper(trim(rec.horizontal_datum));

      if not l_srids_by_name.exists(l_name)
         and substr(l_name, 1, 3) in ('WGS', 'NAD')
      then
         l_name := substr(l_name, 1, 3) || ' ' || substr(l_name, 4);
      end if;

      case

         ------------------------------------------------
         -- No latitude or longitude; no geometry made --
         ------------------------------------------------
         when rec.latitude is null
           or rec.longitude is null
         then
            l_message :=
               '[warning] No lat/long - geometry not created';

         ---------------------------------------------
         -- No datum; assume WGS 84 / SRID 4326     --
         ---------------------------------------------
         when l_name is null
         then
            l_geometry :=
               sdo_geometry(
                  2001,
                  4326,
                  sdo_point_type(
                     rec.longitude,
                     rec.latitude,
                     null
                  ),
                  null,
                  null
               );

            l_message :=
               '[warning] No horizontal datum - created geometry as WGS 84 (4326)';

         ---------------------------------------------
         -- Recognized datum                            --
         ---------------------------------------------
         when l_srids_by_name.exists(l_name)
         then
            l_srid := l_srids_by_name(l_name);

            l_geometry :=
               sdo_geometry(
                  2001,
                  l_srid,
                  sdo_point_type(
                     rec.longitude,
                     rec.latitude,
                     null
                  ),
                  null,
                  null
               );

            if l_srid = 4326 then
               l_message :=
                  '[okay   ] Already in WGS 84 (4326) - no conversion necessary';
            else
               l_geometry := sdo_cs.transform(l_geometry, 4326);

               l_message :=
                  '[okay   ] Converted from '
                  || l_name
                  || ' ('
                  || l_srid
                  || ') to WGS 84 (4326)';
            end if;

         ---------------------------------------------
         -- Unknown datum; assume WGS 84 / 4326      --
         ---------------------------------------------
         else
            l_geometry :=
               sdo_geometry(
                  2001,
                  4326,
                  sdo_point_type(
                     rec.longitude,
                     rec.latitude,
                     null
                  ),
                  null,
                  null
               );

            l_message :=
               '[warning] Unknown horizontal datum ('
               || l_name
               || ') - created geometry as WGS 84 (4326)';

      end case;

      ---------------------------------------------------
      -- Insert the geometry when one was created.      --
      -- The conversion message is inserted only after  --
      -- the geometry insert succeeds.                  --
      ---------------------------------------------------
      if l_geometry is not null then
         begin
            insert into at_location_geometry (
               location_code,
               geometry
            )
            values (
               rec.location_code,
               l_geometry
            );

            -- Log the original conversion message only
            -- after the geometry insert succeeds.
            insert into at_latlon_conversion
            values (
               rec.location_code,
               l_message
            );

         exception
            when others then
               -- The geometry insert failed. Log the error
               -- instead of the original conversion message.
               insert into at_latlon_conversion
               values (
                  rec.location_code,
                  '[z-error  ] Trigger failed: '
                  || dbms_utility.format_error_stack
               );
         end;
      else
         ------------------------------------------------
         -- No geometry was created, so log the message --
         -- directly. This covers missing lat/long.     --
         ------------------------------------------------
         insert into at_latlon_conversion
         values (
            rec.location_code,
            l_message
         );
      end if;
   end loop;

   commit;
end;
/