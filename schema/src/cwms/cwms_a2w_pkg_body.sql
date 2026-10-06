create or replace package body cwms_a2w
as
   ------------------------------------------------------------------------------
   -- procedure p_load_a2w_by_location
   ------------------------------------------------------------------------------
   procedure p_load_a2w_by_location (
      p_db_office_id            in  varchar2,
      p_location_id             in  varchar2,
      p_display_flag            in  varchar2,
      p_notes                   in  clob,
      p_num_ts_codes            in  number,
      p_ts_code_elev            in  number,
      p_ts_code_inflow          in  number,
      p_ts_code_outflow         in  number,
      p_ts_code_sur_release     in  number,
      p_ts_code_precip          in  number,
      p_ts_code_stage           in  number,
      p_ts_code_stor_drought    in  number,
      p_ts_code_stor_flood      in  number,
      p_ts_code_elev_tw         in  number,
      p_ts_code_stage_tw        in  number,
      p_ts_code_rule_curve_elev in  number,
      p_ts_code_power_gen       in  number,
      p_ts_code_temp_air        in  number,
      p_ts_code_temp_water      in  number,
      p_ts_code_do              in  number,
      p_ts_code_ph              in  number,
      p_ts_code_cond            in  number,
      p_ts_code_wind_dir        in  number,
      p_ts_code_wind_speed      in  number,
      p_ts_code_volt            in  number,
      p_ts_code_pct_flood       in  number,
      p_ts_code_pct_con         in  number,
      p_ts_code_irrad           in  number,
      p_ts_code_evap            in  number,
      p_rating_code_elev_stor   in  number,
      p_rating_code_elev_area   in  number,
      p_rating_code_outlet_flow in  number,
      p_ts_code_opening         in  number,
      p_opening_source_obj      in  varchar2,
      p_lake_summary_tf         in  varchar2,
      p_error_msg               out varchar2)
   is
      l_location_code at_a2w_attributes.location_code%type;

      -- AT_PUBLISHED_TS / AT_PUBLISHED_RATING hold one row per (location_code,
      -- published_id) instead of one column per data type on the old wide table.
      -- Delete-then-insert-if-not-null reproduces the old "set the column to this
      -- value, or NULL to clear it" behavior for a single published slot.
      procedure set_ts_mapping (
         p_published_id in cwms_published_id.published_id%type,
         p_ts_code      in at_published_ts.ts_code%type)
      is
      begin
         delete from at_published_ts
          where location_code = l_location_code
            and published_id  = p_published_id;

         if p_ts_code is not null then
            insert into at_published_ts (location_code, published_id, ts_code)
            values (l_location_code, p_published_id, p_ts_code);
         end if;
      end set_ts_mapping;

      procedure set_rating_mapping (
         p_published_id     in cwms_published_id.published_id%type,
         p_rating_spec_code in at_published_rating.rating_spec_code%type)
      is
      begin
         delete from at_published_rating
          where location_code = l_location_code
            and published_id  = p_published_id;

         if p_rating_spec_code is not null then
            insert into at_published_rating (location_code, published_id, rating_spec_code)
            values (l_location_code, p_published_id, p_rating_spec_code);
         end if;
      end set_rating_mapping;
   begin
      p_error_msg := null;

      select location_code
        into l_location_code
        from av_loc
       where unit_system  = 'EN'
         and location_id  = p_location_id
         and db_office_id = p_db_office_id;

      -- p_num_ts_codes is accepted for backward compatibility with existing callers but
      -- is not stored: AV_A2W_TS_CODES_BY_LOC derives NUM_TS_CODES from AT_PUBLISHED_TS.
      merge into at_a2w_attributes tgt
      using (select l_location_code as location_code from dual) src
         on (tgt.location_code = src.location_code)
       when matched then
          update set date_refreshed     = sysdate,
                     notes              = p_notes,
                     display_flag       = p_display_flag,
                     lake_summary_tf    = p_lake_summary_tf,
                     opening_source_obj = p_opening_source_obj
       when not matched then
          insert (location_code, date_refreshed, notes, display_flag, lake_summary_tf, opening_source_obj)
          values (l_location_code, sysdate, p_notes, p_display_flag, p_lake_summary_tf, p_opening_source_obj);

      set_ts_mapping('TS_ELEV',            p_ts_code_elev);
      set_ts_mapping('TS_INFLOW',          p_ts_code_inflow);
      set_ts_mapping('TS_OUTFLOW',         p_ts_code_outflow);
      set_ts_mapping('TS_SUR_RELEASE',     p_ts_code_sur_release);
      set_ts_mapping('TS_PRECIP',          p_ts_code_precip);
      set_ts_mapping('TS_STAGE',           p_ts_code_stage);
      set_ts_mapping('TS_STOR_DROUGHT',    p_ts_code_stor_drought);
      set_ts_mapping('TS_STOR_FLOOD',      p_ts_code_stor_flood);
      set_ts_mapping('TS_ELEV_TW',         p_ts_code_elev_tw);
      set_ts_mapping('TS_STAGE_TW',        p_ts_code_stage_tw);
      set_ts_mapping('TS_RULE_CURVE_ELEV', p_ts_code_rule_curve_elev);
      set_ts_mapping('TS_POWER_GEN',       p_ts_code_power_gen);
      set_ts_mapping('TS_TEMP_AIR',        p_ts_code_temp_air);
      set_ts_mapping('TS_TEMP_WATER',      p_ts_code_temp_water);
      set_ts_mapping('TS_DO',              p_ts_code_do);
      set_ts_mapping('TS_PH',              p_ts_code_ph);
      set_ts_mapping('TS_COND',            p_ts_code_cond);
      set_ts_mapping('TS_WIND_DIR',        p_ts_code_wind_dir);
      set_ts_mapping('TS_WIND_SPEED',      p_ts_code_wind_speed);
      set_ts_mapping('TS_VOLT',            p_ts_code_volt);
      set_ts_mapping('TS_PCT_FLOOD',       p_ts_code_pct_flood);
      set_ts_mapping('TS_PCT_CON',         p_ts_code_pct_con);
      set_ts_mapping('TS_IRRAD',           p_ts_code_irrad);
      set_ts_mapping('TS_EVAP',            p_ts_code_evap);

      -- TS_CODE_OPENING is only a real TS code when OPENING_SOURCE_OBJ = TS. When it is
      -- OBJ the value is an object reference, not a TS code, and must not go into
      -- AT_PUBLISHED_TS (it would fail AT_PUBLISHED_TS_FK_TS / AT_PUBLISHED_TS_T01).
      -- The OBJ case has no destination in the new schema yet, so it is preserved only
      -- through OPENING_SOURCE_OBJ on AT_A2W_ATTRIBUTES.
      if nvl(p_opening_source_obj, 'TS') != 'OBJ' then
         set_ts_mapping('TS_OPENING', p_ts_code_opening);
      end if;

      set_rating_mapping('RATING_ELEV_STOR',   p_rating_code_elev_stor);
      set_rating_mapping('RATING_ELEV_AREA',   p_rating_code_elev_area);
      set_rating_mapping('RATING_OUTLET_FLOW', p_rating_code_outlet_flow);
   exception
      when others then
         p_error_msg := sqlerrm;
   end p_load_a2w_by_location;
   ------------------------------------------------------------------------------
   -- procedure p_clear_a2w_ts_code
   ------------------------------------------------------------------------------
   procedure p_clear_a2w_ts_code (
      p_ts_code in number)
   is
   begin
      -- One DELETE on ts_code removes it from whichever published slot(s) it occupied.
      delete from at_published_ts
       where ts_code = p_ts_code;

      for rec in (select distinct location_code, db_office_id
                    from av_cwms_ts_id
                   where ts_code = p_ts_code)
      loop
         p_set_a2w_num_tsids(
            p_db_office_id  => rec.db_office_id,
            p_location_code => rec.location_code,
            p_user_id       => 'SYSTEM');
      end loop;
   end p_clear_a2w_ts_code;
   ------------------------------------------------------------------------------
   -- procedure p_set_a2w_num_tsids
   ------------------------------------------------------------------------------
   procedure p_set_a2w_num_tsids (
      p_db_office_id  in varchar2,
      p_location_code in number,
      p_user_id       in varchar2)
   is
      l_count pls_integer;
   begin
      -- number of displayable published time series for this location
      select count(*)
        into l_count
        from av_a2w_ts_codes_by_loc2
       where db_office_id  = p_db_office_id
         and location_code = p_location_code;

      -- NOTES/DISPLAY_FLAG live on AT_A2W_ATTRIBUTES (1:1 by LOCATION_CODE). The note
      -- text is unchanged from the CWMS_CMA version so existing notes stay consistent.
      for rec in (select notes from at_a2w_attributes where location_code = p_location_code)
      loop
         if l_count = 0 then
            update at_a2w_attributes
               set date_refreshed = sysdate,
                   notes          = rec.notes
                                    || chr(10)
                                    || ' updated via CMA on '
                                    || sysdate
                                    || ' by '
                                    || p_user_id
                                    || '. Set display flag to False because there are no TS IDs selected.',
                   display_flag   = 'F'
             where location_code = p_location_code;
         else
            update at_a2w_attributes
               set date_refreshed = sysdate,
                   notes          = rec.notes
                                    || chr(10)
                                    || ' updated via CMA on '
                                    || sysdate
                                    || ' by '
                                    || p_user_id
             where location_code = p_location_code;
         end if;
      end loop;
   end p_set_a2w_num_tsids;
   ------------------------------------------------------------------------------
   -- procedure p_add_missing_a2w_rows
   ------------------------------------------------------------------------------
   procedure p_add_missing_a2w_rows (
      p_db_office_id  in varchar2,
      p_location_code in number default null,
      p_user_id       in varchar2)
   is
   begin
      -- p_user_id is accepted for backward compatibility; it is not recorded anywhere.
      for rec in (select location_code
                    from av_loc
                   where db_office_id     = p_db_office_id
                     and unit_system      = 'EN'
                     and loc_active_flag  = 'T'
                     and location_kind_id not in ('STREAM', 'BASIN')
                     and (p_location_code is null or location_code = p_location_code)
                  minus
                  select location_code
                    from av_a2w_ts_codes_by_loc
                   where db_office_id = p_db_office_id
                     and (p_location_code is null or location_code = p_location_code))
      loop
         insert into at_a2w_attributes (location_code, date_refreshed)
         values (rec.location_code, sysdate);
      end loop;
   end p_add_missing_a2w_rows;

end cwms_a2w;
/
show errors
