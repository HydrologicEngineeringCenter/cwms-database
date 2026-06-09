create or replace trigger at_physical_location_t03
for delete or update of time_zone_code,
                          county_code,
                          location_type,
                          elevation,
                          vertical_datum,
                          horizontal_datum,
                          public_name,
                          long_name,
                          description,
                          active_flag,
                          location_kind,
                          published_latitude,
                          published_longitude,
                          office_code,
                          nation_code,
                          nearest_city
on at_physical_location
referencing new as new old as old
compound trigger

   l_msg     varchar2(4000);
   l_ofc     varchar2(16);
   l_loc     varchar2(256);
   
   l_tz_code cwms_time_zone.time_zone_code%type;

   type tz_codes is table of cwms_time_zone.time_zone_code%type;
   type tz_loc_codes is table of at_base_location.base_location_code%type;

   l_tz_loc_codes tz_loc_codes := tz_loc_codes();
   l_tz_loc_codes_base tz_loc_codes := tz_loc_codes();
   l_tz_loc_tz tz_codes := tz_codes();
   l_tz_code_len integer := 1;
before each row is
begin
   l_msg := null;
   if deleting then
      select o.office_id,
             bl.base_location_id
             ||substr('-', 1, length(:old.sub_location_id))
             ||:old.sub_location_id
        into l_ofc,
             l_loc
        from at_base_location bl,
             cwms_office o
       where bl.base_location_code = :old.base_location_code
         and o.office_code = bl.db_office_code;
      l_msg := 'Location '||l_ofc||'/'||l_loc||' deleted';
      cwms_msg.log_db_message(cwms_msg.msg_level_normal, l_msg);
   elsif updating then
      if (nvl(to_char(:new.time_zone_code), '<NULL>') != nvl(to_char(:old.time_zone_code), '<NULL>'))
         or (:new.sub_location_id is not null and :new.time_zone_code is null) then
         l_tz_loc_codes.extend;
         l_tz_loc_codes(l_tz_code_len) := :new.location_code;
         l_tz_loc_codes_base.extend;
         l_tz_loc_codes_base(l_tz_code_len) := :new.base_location_code;
         l_tz_loc_tz.extend;
         l_tz_loc_tz(l_tz_code_len) := :new.time_zone_code;
         l_tz_code_len := l_tz_code_len + 1;
      end if;
      if nvl(to_char(:new.time_zone_code), '<NULL>')      != nvl(to_char(:old.time_zone_code), '<NULL>')      then l_msg := l_msg||'time_zone_code        : '||nvl(to_char(:old.time_zone_code), '<NULL>')     ||' -> '||nvl(to_char(:new.time_zone_code), '<NULL>')     ||chr(10); end if;
      if nvl(to_char(:new.county_code), '<NULL>')         != nvl(to_char(:old.county_code), '<NULL>')         then l_msg := l_msg||'county_code           : '||nvl(to_char(:old.county_code), '<NULL>')        ||' -> '||nvl(to_char(:new.county_code), '<NULL>')        ||chr(10); end if;
      if nvl(:new.location_type, '<NULL>')                != nvl(:old.location_type, '<NULL>')                then l_msg := l_msg||'location_type         : '||nvl(:old.location_type, '<NULL>')               ||' -> '||nvl(:new.location_type, '<NULL>')               ||chr(10); end if;
      if nvl(to_char(:new.elevation), '<NULL>')           != nvl(to_char(:old.elevation), '<NULL>')           then l_msg := l_msg||'elevation             : '||nvl(to_char(:old.elevation), '<NULL>')          ||' -> '||nvl(to_char(:new.elevation), '<NULL>')          ||chr(10); end if;
      if nvl(:new.vertical_datum, '<NULL>')               != nvl(:old.vertical_datum, '<NULL>')               then l_msg := l_msg||'vertical_datum        : '||nvl(:old.vertical_datum, '<NULL>')              ||' -> '||nvl(:new.vertical_datum, '<NULL>')              ||chr(10); end if;
      if nvl(:new.horizontal_datum, '<NULL>')             != nvl(:old.horizontal_datum, '<NULL>')             then l_msg := l_msg||'horizontal_datum      : '||nvl(:old.horizontal_datum, '<NULL>')            ||' -> '||nvl(:new.horizontal_datum, '<NULL>')            ||chr(10); end if;
      if nvl(:new.public_name, '<NULL>')                  != nvl(:old.public_name, '<NULL>')                  then l_msg := l_msg||'public_name           : '||nvl(:old.public_name, '<NULL>')                 ||' -> '||nvl(:new.public_name, '<NULL>')                 ||chr(10); end if;
      if nvl(:new.long_name, '<NULL>')                    != nvl(:old.long_name, '<NULL>')                    then l_msg := l_msg||'long_name             : '||nvl(:old.long_name, '<NULL>')                   ||' -> '||nvl(:new.long_name, '<NULL>')                   ||chr(10); end if;
      if nvl(:new.description, '<NULL>')                  != nvl(:old.description, '<NULL>')                  then l_msg := l_msg||'description           : '||nvl(:old.description, '<NULL>')                 ||' -> '||nvl(:new.description, '<NULL>')                 ||chr(10); end if;
      if nvl(:new.active_flag, '<NULL>')                  != nvl(:old.active_flag, '<NULL>')                  then l_msg := l_msg||'active_flag           : '||nvl(:old.active_flag, '<NULL>')                 ||' -> '||nvl(:new.active_flag, '<NULL>')                 ||chr(10); end if;
      if nvl(to_char(:new.location_kind), '<NULL>')       != nvl(to_char(:old.location_kind), '<NULL>')       then l_msg := l_msg||'location_kind         : '||nvl(to_char(:old.location_kind), '<NULL>')      ||' -> '||nvl(to_char(:new.location_kind), '<NULL>')      ||chr(10); end if;
      if nvl(to_char(:new.published_latitude), '<NULL>')  != nvl(to_char(:old.published_latitude), '<NULL>')  then l_msg := l_msg||'published_latitude    : '||nvl(to_char(:old.published_latitude), '<NULL>') ||' -> '||nvl(to_char(:new.published_latitude), '<NULL>') ||chr(10); end if;
      if nvl(to_char(:new.published_longitude), '<NULL>') != nvl(to_char(:old.published_longitude), '<NULL>') then l_msg := l_msg||'published_longitude   : '||nvl(to_char(:old.published_longitude), '<NULL>')||' -> '||nvl(to_char(:new.published_longitude), '<NULL>')||chr(10); end if;
      if nvl(to_char(:new.office_code), '<NULL>')         != nvl(to_char(:old.office_code), '<NULL>')         then l_msg := l_msg||'office_code           : '||nvl(to_char(:old.office_code), '<NULL>')        ||' -> '||nvl(to_char(:new.office_code), '<NULL>')        ||chr(10); end if;
      if nvl(to_char(:new.nation_code), '<NULL>')         != nvl(to_char(:old.nation_code), '<NULL>')         then l_msg := l_msg||'nation_code           : '||nvl(to_char(:old.nation_code), '<NULL>')        ||' -> '||nvl(to_char(:new.nation_code), '<NULL>')        ||chr(10); end if;
      if nvl(:new.nearest_city, '<NULL>')                 != nvl(:old.nearest_city, '<NULL>')                 then l_msg := l_msg||'nearest_city          : '||nvl(:old.nearest_city, '<NULL>')                ||' -> '||nvl(:new.nearest_city, '<NULL>')                ||chr(10); end if;
      if l_msg is not null then
         select o.office_id,
                bl.base_location_id
                ||substr('-', 1, length(:old.sub_location_id))
                ||:old.sub_location_id
           into l_ofc,
                l_loc
           from at_base_location bl,
                cwms_office o
          where bl.base_location_code = :old.base_location_code
            and o.office_code = bl.db_office_code;
         l_msg := 'Location '||l_ofc||'/'||l_loc||' updated:'||chr(10)||l_msg;
         cwms_msg.log_db_message(cwms_msg.msg_level_normal, l_msg);
      end if;
   end if;
end before each row;

after statement is
begin
   if updating then
      for idx in 1..l_tz_loc_tz.count loop
      
         ----------------------------
         -- update LRTS time zones --
         ----------------------------
         if l_tz_loc_tz(idx) is null then
            -- try base location
            select time_zone_code
              into l_tz_code
              from at_physical_location
             where location_code = l_tz_loc_codes_base(idx);
            if l_tz_code is null then
               -- fall back to UTC
               select time_zone_code
                 into l_tz_code
                 from cwms_time_zone
                where time_zone_name = 'UTC';
            end if;
         else
            l_tz_code := l_tz_loc_tz(idx);
         end if;
         update at_cwms_ts_spec
            set time_zone_code = l_tz_code
          where location_code = l_tz_loc_codes(idx);
      end loop;
   end if;
end after statement;
end at_physical_location_t03;
/
