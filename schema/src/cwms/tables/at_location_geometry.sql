--------------------------
-- AT_LOCATION_GEOMETRY --
--------------------------
create table at_location_geometry (
   location_code      number(14) not null,
   geometry           sdo_geometry not null,
   geometry_type_code number(2),
   latitude           number,
   longitude          number,
   constraint at_location_geometry_pk  primary key (location_code),
   constraint at_location_geometry_fk1 foreign key (location_code) references at_physical_location (location_code)
);

comment on table  at_location_geometry                    is 'Holds geometry (point, polygon, etc...) for locations that have geometry';
comment on column at_location_geometry.location_code      is 'References location in AT_PHYSICAL_LOCATION table';
comment on column at_location_geometry.geometry           is 'Geometry of location';
comment on column at_location_geometry.geometry_type_code is 'Type of geometry (1..7 = point,line,polygon,collection,multipoint,multiline,multipolygon) - populated by trigger';
comment on column at_location_geometry.latitude           is 'Latitude if geometry type is 1, otherwise NULL - populated by trigger';
comment on column at_location_geometry.longitude          is 'Longitude if geometry type is 1, otherwise NULL - populated by trigger';

create or replace trigger at_location_geometry_t01
   before insert or update of geometry
   on at_location_geometry referencing new as new old as old
   for each row
declare
   l_geometry_type_code at_location_geometry.geometry_type_code%type;
   l_srid mdsys.sdo_coord_ref_sys.srid%type;
   l_geometry sdo_geometry;
begin
   if :new.geometry is null then
      -------------------
      -- null geometry --
      -------------------
      :new.geometry_type_code := null;
      :new.latitude           := null;
      :new.longitude          := null;
   else
      l_geometry_type_code := :new.geometry.get_gtype;
      :new.geometry_type_code := l_geometry_type_code;
      if l_geometry_type_code = 1 then
      --------------------
      -- point geometry --
      --------------------
         l_srid := cwms_loc.get_location_srid(:new.location_code);
         if l_srid is null then
            :new.latitude  := :new.geometry.sdo_point.y;
            :new.longitude := :new.geometry.sdo_point.x;
         else
            l_geometry := cwms_loc.to_srid(:new.geometry, l_srid);
            :new.latitude  := l_geometry.sdo_point.y;
            :new.longitude := l_geometry.sdo_point.x;
         end if;
      else
         ------------------------
         -- non-point geometry --
         ------------------------
         :new.latitude  := null;
         :new.longitude := null;
      end if;
   end if;
   if :new.latitude is not null and :new.longitude is not null then
      ---------------------------------
      -- update AT_PHYSICAL_LOCATION --
      ---------------------------------
      declare
         l_old_county_code at_physical_location.county_code%type;
         l_old_nation_code at_physical_location.nation_code%type;
         l_old_office_code at_physical_location.office_code%type;
         l_old_nearest_city at_physical_location.nearest_city%type;
         l_base_location_code at_physical_location.base_location_code%type;
         l_new_county_code at_physical_location.county_code%type;
         l_new_nation_code at_physical_location.nation_code%type;
         l_new_office_code at_physical_location.office_code%type;
         l_new_nearest_city at_physical_location.nearest_city%type;
      begin
         select base_location_code,
                county_code,
                nation_code,
                office_code,
                nearest_city
           into l_base_location_code,
                l_old_county_code,
                l_old_nation_code,
                l_old_office_code,
                l_old_nearest_city
           from at_physical_location
          where location_code = :new.location_code;
          
         -------------------------------------------------------------------------------------------
         -- set county, nation, bounding office, and nearest city from following preference order --
         -- 1. existing value                                                                     --
         -- 2. inherit value from base location                                                   --
         -- 3. generate value from lat/lon                                                        --
         -------------------------------------------------------------------------------------------
         if l_old_county_code is not null then
            l_new_county_code := l_old_county_code;
         else
            if l_base_location_code != :new.location_code then
               select county_code into l_new_county_code from at_physical_location where location_code = l_base_location_code;
            end if;
            if l_new_county_code is null then
               l_new_county_code := cwms_loc.get_county_code(:new.latitude, :new.longitude);
            end if;
         end if;

         if l_old_nation_code is not null then
            l_new_nation_code := l_old_nation_code;
         else
            if l_base_location_code != :new.location_code then
               select nation_code into l_new_nation_code from at_physical_location where location_code = l_base_location_code;
            end if;
            if l_new_nation_code is null then
               l_new_nation_code := cwms_loc.get_nation_id(:new.latitude, :new.longitude);
            end if;
         end if;

         if l_old_office_code is not null then
            l_new_office_code := l_old_office_code;
         else
            if l_base_location_code != :new.location_code then
               select office_code into l_new_office_code from at_physical_location where location_code = l_base_location_code;
            end if;
            if l_new_office_code is null then
               l_new_office_code := cwms_loc.get_bounding_ofc_code(:new.latitude, :new.longitude);
               if l_new_office_code = 0 then
                  l_new_office_code := null;
               end if;
            end if;
         end if;

         if l_old_nearest_city is not null then
            l_new_nearest_city := l_old_nearest_city;
         else
            if l_base_location_code != :new.location_code then
               select nearest_city into l_new_nearest_city from at_physical_location where location_code = l_base_location_code;
            end if;
            if l_new_nearest_city is null then
               l_new_nearest_city := trim(',' from trim(' ' from cwms_util.join_text(cwms_loc.get_nearest_city(:new.latitude, :new.longitude), ', ')));
            end if;
         end if;
         
         if l_new_county_code  = nvl(l_old_county_code,  -1)  and
            l_new_nation_code  = nvl(l_old_nation_code,  '@') and
            l_new_office_code  = nvl(l_old_office_code,  -1)  and
            l_new_nearest_city = nvl(l_old_nearest_city, '@')
         then
            null;
         else
            update at_physical_location
               set county_code  = nvl(l_new_county_code, 0),
                   nation_code = l_new_nation_code,
                   office_code  = l_new_office_code,
                   nearest_city = l_new_nearest_city
             where location_code = :new.location_code;
         end if;
      end;
   end if;
end;
/
