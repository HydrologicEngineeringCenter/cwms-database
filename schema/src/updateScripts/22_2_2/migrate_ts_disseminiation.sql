declare
   l_office_id          at_cwms_ts_id.db_office_id%type := '&office';
   l_office_code        at_cwms_ts_id.db_office_code%type := cwms_util.get_db_office_code(l_office_id);
   l_filter_to_corpsnet varchar2(1) := 'F';
   l_filter_to_dmz      varchar2(1) := 'F';
   l_ts_codes           number_tab_t;
   l_ts_dests           number_tab_t;
begin
   ---------------------------------------------------
   -- get the current ts dissemination destinations --
   ---------------------------------------------------
   select ts_code,
          cwms_data_dissem.get_dest(ts_code)
     bulk collect
     into l_ts_codes,
          l_ts_dests
     from at_cwms_ts_id
    where db_office_code = l_office_code
      and net_ts_active_flag = 'T';
   -----------------------------------------
   -- determine the destination filtering --
   -----------------------------------------
   for i in 1..l_ts_dests.count loop
      if l_ts_dests(i) = 0 then
         l_filter_to_corpsnet := 'T';
         l_filter_to_dmz := 'T';
         exit;
      elsif l_ts_dests(1) = 1 then
         l_filter_to_dmz := 'T';
      end if;
   end loop;
   -----------------------------------
   -- set the destination filtering --
   -----------------------------------
   cwms_data_dissem.set_ts_filtering(l_filter_to_corpsnet, l_filter_to_dmz, l_office_id);
   ----------------------------------------------------
   -- clear the destination filters in the ts groups --
   ----------------------------------------------------
   delete
     from at_ts_group_assignment
    where ts_group_code between 100 and 103
      and ts_code in (select ts_code from at_cwms_ts_id where db_office_code = l_office_code);
   -----------------------------------------------------
   -- create new destination filters in the ts groups --
   -----------------------------------------------------
   if l_filter_to_dmz = 'T' then
      for i in 1..l_ts_codes.count loop
         if l_ts_dests(i) = 2 then
            insert into at_ts_group_assignment (office_code, ts_code, ts_group_code) values (l_office_code, l_ts_codes(i), 102);
         elsif l_ts_dests(i) = 1 and l_filter_to_corpsnet = 'T' then
            insert into at_ts_group_assignment (office_code, ts_code, ts_group_code) values (l_office_code, l_ts_codes(i), 100);
         end if;
      end loop;
   end if;
   commit;
end;