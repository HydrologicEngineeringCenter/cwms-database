create or replace trigger at_physical_location_t03
after delete or update of time_zone_code,
                          county_code,
                          location_type,
                          elevation,
                          vertical_datum,
                          longitude,
                          latitude,
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
for each row
declare
   l_msg varchar2(4000);
   l_ofc varchar2(16);
   l_loc varchar2(256);
begin
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
      if nvl(to_char(:new.county_code), '<NULL>')          != nvl(to_char(:old.county_code), '<NULL>')           then l_msg := l_msg||'county_code           : '||nvl(to_char(:old.county_code), '<NULL>')          ||' -> '||nvl(to_char(:new.county_code), '<NULL>')          ||chr(10); end if;
      if nvl(:new.location_type, '<NULL>')                 != nvl(:old.location_type, '<NULL>')                  then l_msg := l_msg||'location_type         : '||nvl(:old.location_type, '<NULL>')                 ||' -> '||nvl(:new.location_type, '<NULL>')                 ||chr(10); end if;
      if nvl(to_char(:new.elevation), '<NULL>')            != nvl(to_char(:old.elevation), '<NULL>')             then l_msg := l_msg||'elevation             : '||nvl(to_char(:old.elevation), '<NULL>')            ||' -> '||nvl(to_char(:new.elevation), '<NULL>')            ||chr(10); end if;
      if nvl(:new.vertical_datum, '<NULL>')                != nvl(:old.vertical_datum, '<NULL>')                 then l_msg := l_msg||'vertical_datum        : '||nvl(:old.vertical_datum, '<NULL>')                ||' -> '||nvl(:new.vertical_datum, '<NULL>')                ||chr(10); end if;
      if nvl(to_char(:new.longitude), '<NULL>')            != nvl(to_char(:old.longitude), '<NULL>')             then l_msg := l_msg||'longitude             : '||nvl(to_char(:old.longitude), '<NULL>')            ||' -> '||nvl(to_char(:new.longitude), '<NULL>')            ||chr(10); end if;
      if nvl(to_char(:new.latitude), '<NULL>')             != nvl(to_char(:old.latitude), '<NULL>')              then l_msg := l_msg||'latitude              : '||nvl(to_char(:old.latitude), '<NULL>')             ||' -> '||nvl(to_char(:new.latitude), '<NULL>')             ||chr(10); end if;
      if nvl(:new.horizontal_datum, '<NULL>')              != nvl(:old.horizontal_datum, '<NULL>')               then l_msg := l_msg||'horizontal_datum      : '||nvl(:old.horizontal_datum, '<NULL>')              ||' -> '||nvl(:new.horizontal_datum, '<NULL>')              ||chr(10); end if;
      if nvl(:new.public_name, '<NULL>')                   != nvl(:old.public_name, '<NULL>')                    then l_msg := l_msg||'public_name           : '||nvl(:old.public_name, '<NULL>')                   ||' -> '||nvl(:new.public_name, '<NULL>')                   ||chr(10); end if;
      if nvl(:new.long_name, '<NULL>')                     != nvl(:old.long_name, '<NULL>')                      then l_msg := l_msg||'long_name             : '||nvl(:old.long_name, '<NULL>')                     ||' -> '||nvl(:new.long_name, '<NULL>')                     ||chr(10); end if;
      if nvl(:new.description, '<NULL>')                   != nvl(:old.description, '<NULL>')                    then l_msg := l_msg||'description           : '||nvl(:old.description, '<NULL>')                   ||' -> '||nvl(:new.description, '<NULL>')                   ||chr(10); end if;
      if nvl(:new.active_flag, '<NULL>')                   != nvl(:old.active_flag, '<NULL>')                    then l_msg := l_msg||'active_flag           : '||nvl(:old.active_flag, '<NULL>')                   ||' -> '||nvl(:new.active_flag, '<NULL>')                   ||chr(10); end if;
      if nvl(to_char(:new.location_kind), '<NULL>')        != nvl(to_char(:old.location_kind), '<NULL>')         then l_msg := l_msg||'location_kind         : '||nvl(to_char(:old.location_kind), '<NULL>')        ||' -> '||nvl(to_char(:new.location_kind), '<NULL>')        ||chr(10); end if;
      if nvl(to_char(:new.published_latitude), '<NULL>')   != nvl(to_char(:old.published_latitude), '<NULL>')    then l_msg := l_msg||'published_latitude    : '||nvl(to_char(:old.published_latitude), '<NULL>')   ||' -> '||nvl(to_char(:new.published_latitude), '<NULL>')   ||chr(10); end if;
      if nvl(to_char(:new.published_longitude), '<NULL>')  != nvl(to_char(:old.published_longitude), '<NULL>')   then l_msg := l_msg||'published_longitude   : '||nvl(to_char(:old.published_longitude), '<NULL>')  ||' -> '||nvl(to_char(:new.published_longitude), '<NULL>')  ||chr(10); end if;
      if nvl(to_char(:new.office_code), '<NULL>')          != nvl(to_char(:old.office_code), '<NULL>')           then l_msg := l_msg||'office_code           : '||nvl(to_char(:old.office_code), '<NULL>')          ||' -> '||nvl(to_char(:new.office_code), '<NULL>')          ||chr(10); end if;
      if nvl(to_char(:new.nation_code), '<NULL>')          != nvl(to_char(:old.nation_code), '<NULL>')           then l_msg := l_msg||'nation_code           : '||nvl(to_char(:old.nation_code), '<NULL>')          ||' -> '||nvl(to_char(:new.nation_code), '<NULL>')          ||chr(10); end if;
      if nvl(:new.nearest_city, '<NULL>')                  != nvl(:old.nearest_city, '<NULL>')                   then l_msg := l_msg||'nearest_city          : '||nvl(:old.nearest_city, '<NULL>')                  ||' -> '||nvl(:new.nearest_city, '<NULL>')                  ||chr(10); end if;
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
end at_physical_location_t03;
/

