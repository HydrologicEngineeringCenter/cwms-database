/* Formatted on 2007/05/24 06:44 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE BODY cwms_cat
IS
-------------------------------------------------------------------------------
-- CAT_TS record-to-object conversion function
--
   FUNCTION cat_ts_rec2obj (r IN cat_ts_rec_t)
      RETURN cat_ts_obj_t
   IS
   BEGIN
      RETURN cat_ts_obj_t (r.office_id, r.cwms_ts_id, r.interval_utc_offset);
   END cat_ts_rec2obj;

-------------------------------------------------------------------------------
-- CAT_TS table-to-object conversion function
--
   FUNCTION cat_ts_tab2obj (t IN cat_ts_tab_t)
      RETURN cat_ts_otab_t
   IS
      o   cat_ts_otab_t;
   BEGIN
      FOR i IN 1 .. t.LAST
      LOOP
         o (i) := cat_ts_rec2obj (t (i));
      END LOOP;

      RETURN o;
   END cat_ts_tab2obj;

-------------------------------------------------------------------------------
-- CAT_TS object-to-record conversion function
--
   FUNCTION cat_ts_obj2rec (o IN cat_ts_obj_t)
      RETURN cat_ts_rec_t
   IS
      r   cat_ts_rec_t := NULL;
   BEGIN
      IF o IS NOT NULL
      THEN
         r.office_id := o.office_id;
         r.cwms_ts_id := o.cwms_ts_id;
         r.interval_utc_offset := o.interval_utc_offset;
      END IF;

      RETURN r;
   END cat_ts_obj2rec;

-------------------------------------------------------------------------------
-- CAT_TS object-to-table conversion function
--
   FUNCTION cat_ts_obj2tab (o IN cat_ts_otab_t)
      RETURN cat_ts_tab_t
   IS
      t   cat_ts_tab_t;
   BEGIN
      FOR i IN 1 .. o.LAST
      LOOP
         t (i) := cat_ts_obj2rec (o (i));
      END LOOP;

      RETURN t;
   END cat_ts_obj2tab;

-------------------------------------------------------------------------------
-- CAT_TS_CWMS_20 record-to-object conversion function
--
   FUNCTION cat_ts_cwms_20_rec2obj (r IN cat_ts_cwms_20_rec_t)
      RETURN cat_ts_cwms_20_obj_t
   IS
   BEGIN
      RETURN cat_ts_cwms_20_obj_t (r.office_id,
                                   r.cwms_ts_id,
                                   r.interval_utc_offset,
                                   r.user_privileges,
                                   r.inactive,
                                   r.lrts_timezone
                                  );
   END cat_ts_cwms_20_rec2obj;

-------------------------------------------------------------------------------
-- CAT_TS_CWMS_20 table-to-object conversion function
--
   FUNCTION cat_ts_cwms_20_tab2obj (t IN cat_ts_cwms_20_tab_t)
      RETURN cat_ts_cwms_20_otab_t
   IS
      o   cat_ts_cwms_20_otab_t;
   BEGIN
      FOR i IN 1 .. t.LAST
      LOOP
         o (i) := cat_ts_cwms_20_rec2obj (t (i));
      END LOOP;

      RETURN o;
   END cat_ts_cwms_20_tab2obj;

-------------------------------------------------------------------------------
-- CAT_TS_CWMS_20 object-to-record conversion function
--
   FUNCTION cat_ts_cwms_20_obj2rec (o IN cat_ts_cwms_20_obj_t)
      RETURN cat_ts_cwms_20_rec_t
   IS
      r   cat_ts_cwms_20_rec_t := NULL;
   BEGIN
      IF o IS NOT NULL
      THEN
         r.office_id := o.office_id;
         r.cwms_ts_id := o.cwms_ts_id;
         r.interval_utc_offset := o.interval_utc_offset;
         r.user_privileges := o.user_privileges;
         r.inactive := o.inactive;
         r.lrts_timezone := o.lrts_timezone;
      END IF;

      RETURN r;
   END cat_ts_cwms_20_obj2rec;

-------------------------------------------------------------------------------
-- CAT_TS_CWMS_20 object-to-table conversion function
--
   FUNCTION cat_ts_cwms_20_obj2tab (o IN cat_ts_cwms_20_otab_t)
      RETURN cat_ts_cwms_20_tab_t
   IS
      t   cat_ts_cwms_20_tab_t;
   BEGIN
      FOR i IN 1 .. o.LAST
      LOOP
         t (i) := cat_ts_cwms_20_obj2rec (o (i));
      END LOOP;

      RETURN t;
   END cat_ts_cwms_20_obj2tab;

-------------------------------------------------------------------------------
-- CAT_LOC record-to-object conversion function
--
   FUNCTION cat_loc_rec2obj (r IN cat_loc_rec_t)
      RETURN cat_loc_obj_t
   IS
   BEGIN
      RETURN cat_loc_obj_t (r.office_id,
                            r.base_loc_id,
                            r.state_initial,
                            r.county_name,
                            r.timezone_name,
                            r.location_type,
                            r.latitude,
                            r.longitude,
                            r.elevation,
                            r.elev_unit_id,
                            r.vertical_datum,
                            r.public_name,
                            r.long_name,
                            r.description
                           );
   END cat_loc_rec2obj;

-------------------------------------------------------------------------------
-- CAT_LOC table-to-object conversion function
--
   FUNCTION cat_loc_tab2obj (t IN cat_loc_tab_t)
      RETURN cat_loc_otab_t
   IS
      o   cat_loc_otab_t;
   BEGIN
      FOR i IN 1 .. t.LAST
      LOOP
         o (i) := cat_loc_rec2obj (t (i));
      END LOOP;

      RETURN o;
   END cat_loc_tab2obj;

-------------------------------------------------------------------------------
-- CAT_LOC object-to-record conversion function
--
   FUNCTION cat_loc_obj2rec (o IN cat_loc_obj_t)
      RETURN cat_loc_rec_t
   IS
      r   cat_loc_rec_t := NULL;
   BEGIN
      IF o IS NOT NULL
      THEN
         r.office_id := o.office_id;
         r.base_loc_id := o.base_loc_id;
         r.state_initial := o.state_initial;
         r.county_name := o.county_name;
         r.timezone_name := o.timezone_name;
         r.location_type := o.location_type;
         r.latitude := o.latitude;
         r.longitude := o.longitude;
         r.elevation := o.elevation;
         r.elev_unit_id := o.elev_unit_id;
         r.vertical_datum := o.vertical_datum;
         r.public_name := o.public_name;
         r.long_name := o.long_name;
         r.description := o.description;
      END IF;

      RETURN r;
   END cat_loc_obj2rec;

-------------------------------------------------------------------------------
-- CAT_LOC object-to-table conversion function
--
   FUNCTION cat_loc_obj2tab (o IN cat_loc_otab_t)
      RETURN cat_loc_tab_t
   IS
      t   cat_loc_tab_t;
   BEGIN
      FOR i IN 1 .. o.LAST
      LOOP
         t (i) := cat_loc_obj2rec (o (i));
      END LOOP;

      RETURN t;
   END cat_loc_obj2tab;

---------------------------------------------------------------------------------
---- CAT_LOC_ALIAS record-to-object conversion function
----
--   FUNCTION cat_loc_alias_rec2obj (r IN cat_loc_alias_rec_t)
--      RETURN cat_loc_alias_obj_t
--   IS
--   BEGIN
--      RETURN cat_loc_alias_obj_t (r.office_id,
--                                  r.cwms_id,
--                                  r.source_id,
--                                  r.gage_id
--                                 );
--   END cat_loc_alias_rec2obj;

   -------------------------------------------------------------------------------
-- CAT_LOC_ALIAS table-to-object conversion function
--
--   FUNCTION cat_loc_alias_tab2obj (t IN cat_loc_alias_tab_t)
--      RETURN cat_loc_alias_otab_t
--   IS
--      o   cat_loc_alias_otab_t;
--   BEGIN
--      FOR i IN 1 .. t.LAST
--      LOOP
--         o (i) := cat_loc_alias_rec2obj (t (i));
--      END LOOP;

   --      RETURN o;
--   END cat_loc_alias_tab2obj;

   ---------------------------------------------------------------------------------
---- CAT_LOC_ALIAS object-to-record conversion function
----
--   FUNCTION cat_loc_alias_obj2rec (o IN cat_loc_alias_obj_t)
--      RETURN cat_loc_alias_rec_t
--   IS
--      r   cat_loc_alias_rec_t := NULL;
--   BEGIN
--      IF o IS NOT NULL
--      THEN
--         r.office_id := o.office_id;
--         r.cwms_id := o.cwms_id;
--         r.source_id := o.source_id;
--         r.gage_id := o.gage_id;
--      END IF;

   --      RETURN r;
--   END cat_loc_alias_obj2rec;

   -------------------------------------------------------------------------------
-- CAT_LOC_ALIAS object-to-table conversion function
--
--   FUNCTION cat_loc_alias_obj2tab (o IN cat_loc_alias_otab_t)
--      RETURN cat_loc_alias_tab_t
--   IS
--      t   cat_loc_alias_tab_t;
--   BEGIN
--      FOR i IN 1 .. o.LAST
--      LOOP
--         t (i) := cat_loc_alias_obj2rec (o (i));
--      END LOOP;

   --      RETURN t;
--   END cat_loc_alias_obj2tab;

   -------------------------------------------------------------------------------
-- CAT_PARAM record-to-object conversion function
--
   FUNCTION cat_param_rec2obj (r IN cat_param_rec_t)
      RETURN cat_param_obj_t
   IS
   BEGIN
      RETURN cat_param_obj_t (r.parameter_id,
                              r.param_long_name,
                              r.param_description,
                              r.unit_id,
                              r.unit_long_name,
                              r.unit_description
                             );
   END cat_param_rec2obj;

-------------------------------------------------------------------------------
-- CAT_PARAM table-to-object conversion function
--
   FUNCTION cat_param_tab2obj (t IN cat_param_tab_t)
      RETURN cat_param_otab_t
   IS
      o   cat_param_otab_t;
   BEGIN
      FOR i IN 1 .. t.LAST
      LOOP
         o (i) := cat_param_rec2obj (t (i));
      END LOOP;

      RETURN o;
   END cat_param_tab2obj;

-------------------------------------------------------------------------------
-- CAT_PARAM object-to-record conversion function
--
   FUNCTION cat_param_obj2rec (o IN cat_param_obj_t)
      RETURN cat_param_rec_t
   IS
      r   cat_param_rec_t := NULL;
   BEGIN
      IF o IS NOT NULL
      THEN
         r.parameter_id := o.parameter_id;
         r.param_long_name := o.param_long_name;
         r.param_description := o.param_description;
         r.unit_id := o.unit_id;
         r.unit_long_name := o.unit_long_name;
         r.unit_description := o.unit_description;
      END IF;

      RETURN r;
   END cat_param_obj2rec;

-------------------------------------------------------------------------------
-- CAT_PARAM object-to-table conversion function
--
   FUNCTION cat_param_obj2tab (o IN cat_param_otab_t)
      RETURN cat_param_tab_t
   IS
      t   cat_param_tab_t;
   BEGIN
      FOR i IN 1 .. o.LAST
      LOOP
         t (i) := cat_param_obj2rec (o (i));
      END LOOP;

      RETURN t;
   END cat_param_obj2tab;

-------------------------------------------------------------------------------
-- CAT_SUB_PARAM record-to-object conversion function
--
   FUNCTION cat_sub_param_rec2obj (r IN cat_sub_param_rec_t)
      RETURN cat_sub_param_obj_t
   IS
   BEGIN
      RETURN cat_sub_param_obj_t (r.parameter_id,
                                  r.subparameter_id,
                                  r.description
                                 );
   END cat_sub_param_rec2obj;

-------------------------------------------------------------------------------
-- CAT_SUB_PARAM table-to-object conversion function
--
   FUNCTION cat_sub_param_tab2obj (t IN cat_sub_param_tab_t)
      RETURN cat_sub_param_otab_t
   IS
      o   cat_sub_param_otab_t;
   BEGIN
      FOR i IN 1 .. t.LAST
      LOOP
         o (i) := cat_sub_param_rec2obj (t (i));
      END LOOP;

      RETURN o;
   END cat_sub_param_tab2obj;

-------------------------------------------------------------------------------
-- CAT_SUB_PARAM object-to-record conversion function
--
   FUNCTION cat_sub_param_obj2rec (o IN cat_sub_param_obj_t)
      RETURN cat_sub_param_rec_t
   IS
      r   cat_sub_param_rec_t := NULL;
   BEGIN
      IF o IS NOT NULL
      THEN
         r.parameter_id := o.parameter_id;
         r.subparameter_id := o.subparameter_id;
         r.description := o.description;
      END IF;

      RETURN r;
   END cat_sub_param_obj2rec;

-------------------------------------------------------------------------------
-- CAT_SUB_PARAM object-to-table conversion function
--
   FUNCTION cat_sub_param_obj2tab (o IN cat_sub_param_otab_t)
      RETURN cat_sub_param_tab_t
   IS
      t   cat_sub_param_tab_t;
   BEGIN
      FOR i IN 1 .. o.LAST
      LOOP
         t (i) := cat_sub_param_obj2rec (o (i));
      END LOOP;

      RETURN t;
   END cat_sub_param_obj2tab;

-------------------------------------------------------------------------------
-- CAT_SUB_LOC record-to-object conversion function
--
   FUNCTION cat_sub_loc_rec2obj (r IN cat_sub_loc_rec_t)
      RETURN cat_sub_loc_obj_t
   IS
   BEGIN
      RETURN cat_sub_loc_obj_t (r.sublocation_id, r.description);
   END cat_sub_loc_rec2obj;

-------------------------------------------------------------------------------
-- CAT_SUB_LOC table-to-object conversion function
--
   FUNCTION cat_sub_loc_tab2obj (t IN cat_sub_loc_tab_t)
      RETURN cat_sub_loc_otab_t
   IS
      o   cat_sub_loc_otab_t;
   BEGIN
      FOR i IN 1 .. t.LAST
      LOOP
         o (i) := cat_sub_loc_rec2obj (t (i));
      END LOOP;

      RETURN o;
   END cat_sub_loc_tab2obj;

-------------------------------------------------------------------------------
-- CAT_SUB_LOC object-to-record conversion function
--
   FUNCTION cat_sub_loc_obj2rec (o IN cat_sub_loc_obj_t)
      RETURN cat_sub_loc_rec_t
   IS
      r   cat_sub_loc_rec_t := NULL;
   BEGIN
      IF o IS NOT NULL
      THEN
         r.sublocation_id := o.sublocation_id;
         r.description := o.description;
      END IF;

      RETURN r;
   END cat_sub_loc_obj2rec;

-------------------------------------------------------------------------------
-- CAT_SUB_LOC object-to-table conversion function
--
   FUNCTION cat_sub_loc_obj2tab (o IN cat_sub_loc_otab_t)
      RETURN cat_sub_loc_tab_t
   IS
      t   cat_sub_loc_tab_t;
   BEGIN
      FOR i IN 1 .. o.LAST
      LOOP
         t (i) := cat_sub_loc_obj2rec (o (i));
      END LOOP;

      RETURN t;
   END cat_sub_loc_obj2tab;

-------------------------------------------------------------------------------
-- CAT_STATE record-to-object conversion function
--
   FUNCTION cat_state_rec2obj (r IN cat_state_rec_t)
      RETURN cat_state_obj_t
   IS
   BEGIN
      RETURN cat_state_obj_t (r.state_initial, r.state_name);
   END cat_state_rec2obj;

-------------------------------------------------------------------------------
-- CAT_STATE table-to-object conversion function
--
   FUNCTION cat_state_tab2obj (t IN cat_state_tab_t)
      RETURN cat_state_otab_t
   IS
      o   cat_state_otab_t;
   BEGIN
      FOR i IN 1 .. t.LAST
      LOOP
         o (i) := cat_state_rec2obj (t (i));
      END LOOP;

      RETURN o;
   END cat_state_tab2obj;

-------------------------------------------------------------------------------
-- CAT_STATE object-to-record conversion function
--
   FUNCTION cat_state_obj2rec (o IN cat_state_obj_t)
      RETURN cat_state_rec_t
   IS
      r   cat_state_rec_t := NULL;
   BEGIN
      IF o IS NOT NULL
      THEN
         r.state_initial := o.state_initial;
         r.state_name := o.state_name;
      END IF;

      RETURN r;
   END cat_state_obj2rec;

-------------------------------------------------------------------------------
-- CAT_STATE object-to-table conversion function
--
   FUNCTION cat_state_obj2tab (o IN cat_state_otab_t)
      RETURN cat_state_tab_t
   IS
      t   cat_state_tab_t;
   BEGIN
      FOR i IN 1 .. o.LAST
      LOOP
         t (i) := cat_state_obj2rec (o (i));
      END LOOP;

      RETURN t;
   END cat_state_obj2tab;

-------------------------------------------------------------------------------
-- CAT_COUNTY record-to-object conversion function
--
   FUNCTION cat_county_rec2obj (r IN cat_county_rec_t)
      RETURN cat_county_obj_t
   IS
   BEGIN
      RETURN cat_county_obj_t (r.county_id, r.county_name, r.state_initial);
   END cat_county_rec2obj;

-------------------------------------------------------------------------------
-- CAT_COUNTY table-to-object conversion function
--
   FUNCTION cat_county_tab2obj (t IN cat_county_tab_t)
      RETURN cat_county_otab_t
   IS
      o   cat_county_otab_t;
   BEGIN
      FOR i IN 1 .. t.LAST
      LOOP
         o (i) := cat_county_rec2obj (t (i));
      END LOOP;

      RETURN o;
   END cat_county_tab2obj;

-------------------------------------------------------------------------------
-- CAT_COUNTY object-to-record conversion function
--
   FUNCTION cat_county_obj2rec (o IN cat_county_obj_t)
      RETURN cat_county_rec_t
   IS
      r   cat_county_rec_t := NULL;
   BEGIN
      IF o IS NOT NULL
      THEN
         r.county_id := o.county_id;
         r.county_name := o.county_name;
         r.state_initial := o.state_initial;
      END IF;

      RETURN r;
   END cat_county_obj2rec;

-------------------------------------------------------------------------------
-- CAT_COUNTY object-to-table conversion function
--
   FUNCTION cat_county_obj2tab (o IN cat_county_otab_t)
      RETURN cat_county_tab_t
   IS
      t   cat_county_tab_t;
   BEGIN
      FOR i IN 1 .. o.LAST
      LOOP
         t (i) := cat_county_obj2rec (o (i));
      END LOOP;

      RETURN t;
   END cat_county_obj2tab;

-------------------------------------------------------------------------------
-- CAT_TIMEZONE record-to-object conversion function
--
   FUNCTION cat_timezone_rec2obj (r IN cat_timezone_rec_t)
      RETURN cat_timezone_obj_t
   IS
   BEGIN
      RETURN cat_timezone_obj_t (r.timezone_name, r.utc_offset, r.dst_offset);
   END cat_timezone_rec2obj;

-------------------------------------------------------------------------------
-- CAT_TIMEZONE table-to-object conversion function
--
   FUNCTION cat_timezone_tab2obj (t IN cat_timezone_tab_t)
      RETURN cat_timezone_otab_t
   IS
      o   cat_timezone_otab_t;
   BEGIN
      FOR i IN 1 .. t.LAST
      LOOP
         o (i) := cat_timezone_rec2obj (t (i));
      END LOOP;

      RETURN o;
   END cat_timezone_tab2obj;

-------------------------------------------------------------------------------
-- CAT_TIMEZONE object-to-record conversion function
--
   FUNCTION cat_timezone_obj2rec (o IN cat_timezone_obj_t)
      RETURN cat_timezone_rec_t
   IS
      r   cat_timezone_rec_t := NULL;
   BEGIN
      IF o IS NOT NULL
      THEN
         r.timezone_name := o.timezone_name;
         r.utc_offset := o.utc_offset;
         r.dst_offset := o.dst_offset;
      END IF;

      RETURN r;
   END cat_timezone_obj2rec;

-------------------------------------------------------------------------------
-- CAT_TIMEZONE object-to-table conversion function
--
   FUNCTION cat_timezone_obj2tab (o IN cat_timezone_otab_t)
      RETURN cat_timezone_tab_t
   IS
      t   cat_timezone_tab_t;
   BEGIN
      FOR i IN 1 .. o.LAST
      LOOP
         t (i) := cat_timezone_obj2rec (o (i));
      END LOOP;

      RETURN t;
   END cat_timezone_obj2tab;

-------------------------------------------------------------------------------
-- CAT_DSS_FILE record-to-object conversion function
--
   FUNCTION cat_dss_file_rec2obj (r IN cat_dss_file_rec_t)
      RETURN cat_dss_file_obj_t
   IS
   BEGIN
      RETURN cat_dss_file_obj_t (r.dss_filemgr_url, r.dss_file_name);
   END cat_dss_file_rec2obj;

-------------------------------------------------------------------------------
-- CAT_DSS_FILE table-to-object conversion function
--
   FUNCTION cat_dss_file_tab2obj (t IN cat_dss_file_tab_t)
      RETURN cat_dss_file_otab_t
   IS
      o   cat_dss_file_otab_t;
   BEGIN
      FOR i IN 1 .. o.LAST
      LOOP
         o (i) := cat_dss_file_rec2obj (t (i));
      END LOOP;

      RETURN o;
   END cat_dss_file_tab2obj;

-------------------------------------------------------------------------------
-- CAT_DSS_FILE object-to-record conversion function
--
   FUNCTION cat_dss_file_obj2rec (o IN cat_dss_file_obj_t)
      RETURN cat_dss_file_rec_t
   IS
      r   cat_dss_file_rec_t := NULL;
   BEGIN
      IF o IS NOT NULL
      THEN
         r.dss_filemgr_url := o.dss_filemgr_url;
         r.dss_file_name := o.dss_file_name;
      END IF;

      RETURN r;
   END cat_dss_file_obj2rec;

-------------------------------------------------------------------------------
-- CAT_DSS_FILE object-to-table conversion function
--
   FUNCTION cat_dss_file_obj2tab (o IN cat_dss_file_otab_t)
      RETURN cat_dss_file_tab_t
   IS
      t   cat_dss_file_tab_t;
   BEGIN
      FOR i IN 1 .. o.LAST
      LOOP
         t (i) := cat_dss_file_obj2rec (o (i));
      END LOOP;

      RETURN t;
   END cat_dss_file_obj2tab;

-------------------------------------------------------------------------------
-- CAT_DSS_XCHG_SET record-to-object conversion function
--
   FUNCTION cat_dss_xchg_set_rec2obj (r IN cat_dss_xchg_set_rec_t)
      RETURN cat_dss_xchg_set_obj_t
   IS
   BEGIN
      RETURN cat_dss_xchg_set_obj_t (r.office_id,
                                     r.dss_xchg_set_id,
                                     r.dss_xchg_set_description,
                                     r.dss_filemgr_url,
                                     r.dss_file_name,
                                     r.dss_xchg_direction_id,
                                     r.dss_xchg_last_update
                                    );
   END cat_dss_xchg_set_rec2obj;

-------------------------------------------------------------------------------
-- CAT_DSS_XCHG_SET table-to-object conversion function
--
   FUNCTION cat_dss_xchg_set_tab2obj (t IN cat_dss_xchg_set_tab_t)
      RETURN cat_dss_xchg_set_otab_t
   IS
      o   cat_dss_xchg_set_otab_t;
   BEGIN
      FOR i IN 1 .. t.LAST
      LOOP
         o (i) := cat_dss_xchg_set_rec2obj (t (i));
      END LOOP;

      RETURN o;
   END cat_dss_xchg_set_tab2obj;

-------------------------------------------------------------------------------
-- CAT_DSS_XCHG_SET object-to-record conversion function
--
   FUNCTION cat_dss_xchg_set_obj2rec (o IN cat_dss_xchg_set_obj_t)
      RETURN cat_dss_xchg_set_rec_t
   IS
      r   cat_dss_xchg_set_rec_t := NULL;
   BEGIN
      IF o IS NOT NULL
      THEN
         r.office_id := o.office_id;
         r.dss_xchg_set_id := o.dss_xchg_set_id;
         r.dss_xchg_set_description := o.dss_xchg_set_description;
         r.dss_filemgr_url := o.dss_filemgr_url;
         r.dss_file_name := o.dss_file_name;
         r.dss_xchg_direction_id := o.dss_xchg_direction_id;
         r.dss_xchg_last_update := o.dss_xchg_last_update;
      END IF;

      RETURN r;
   END cat_dss_xchg_set_obj2rec;

-------------------------------------------------------------------------------
-- CAT_DSS_XCHG_SET object-to-table conversion function
--
   FUNCTION cat_dss_xchg_set_obj2tab (o IN cat_dss_xchg_set_otab_t)
      RETURN cat_dss_xchg_set_tab_t
   IS
      t   cat_dss_xchg_set_tab_t;
   BEGIN
      FOR i IN 1 .. o.LAST
      LOOP
         t (i) := cat_dss_xchg_set_obj2rec (o (i));
      END LOOP;

      RETURN t;
   END cat_dss_xchg_set_obj2tab;

-------------------------------------------------------------------------------
-- CAT_DSS_XCHG_TS_MAP record-to-object conversion function
--
   FUNCTION cat_dss_xchg_ts_map_rec2obj (r IN cat_dss_xchg_ts_map_rec_t)
      RETURN cat_dss_xchg_ts_map_obj_t
   IS
   BEGIN
      RETURN cat_dss_xchg_ts_map_obj_t (r.cwms_ts_id,
                                        r.dss_pathname,
                                        r.dss_parameter_type_id,
                                        r.dss_unit_id,
                                        r.dss_timezone_name,
                                        r.dss_tz_usage_id
                                       );
   END cat_dss_xchg_ts_map_rec2obj;

-------------------------------------------------------------------------------
-- CAT_DSS_XCHG_TS_MAP table-to-object conversion function
--
   FUNCTION cat_dss_xchg_ts_map_tab2obj (t IN cat_dss_xchg_ts_map_tab_t)
      RETURN cat_dss_xchg_ts_map_otab_t
   IS
      o   cat_dss_xchg_ts_map_otab_t;
   BEGIN
      FOR i IN 1 .. t.LAST
      LOOP
         o (i) := cat_dss_xchg_ts_map_rec2obj (t (i));
      END LOOP;

      RETURN o;
   END cat_dss_xchg_ts_map_tab2obj;

-------------------------------------------------------------------------------
-- CAT_DSS_XCHG_TS_MAP object-to-record conversion function
--
   FUNCTION cat_dss_xchg_ts_map_obj2rec (o IN cat_dss_xchg_ts_map_obj_t)
      RETURN cat_dss_xchg_ts_map_rec_t
   IS
      r   cat_dss_xchg_ts_map_rec_t := NULL;
   BEGIN
      IF o IS NOT NULL
      THEN
         r.cwms_ts_id := o.cwms_ts_id;
         r.dss_pathname := o.dss_pathname;
         r.dss_parameter_type_id := o.dss_parameter_type_id;
         r.dss_unit_id := o.dss_unit_id;
         r.dss_timezone_name := o.dss_timezone_name;
         r.dss_tz_usage_id := o.dss_tz_usage_id;
      END IF;

      RETURN r;
   END cat_dss_xchg_ts_map_obj2rec;

-------------------------------------------------------------------------------
-- CAT_DSS_XCHG_TS_MAP object-to-table conversion function
--
   FUNCTION cat_dss_xchg_ts_map_obj2tab (o IN cat_dss_xchg_ts_map_otab_t)
      RETURN cat_dss_xchg_ts_map_tab_t
   IS
      t   cat_dss_xchg_ts_map_tab_t;
   BEGIN
      FOR i IN 1 .. o.LAST
      LOOP
         t (i) := cat_dss_xchg_ts_map_obj2rec (o (i));
      END LOOP;

      RETURN t;
   END cat_dss_xchg_ts_map_obj2tab;

-------------------------------------------------------------------------------
-- DEPRICATED --
-- DEPRICATED -- procedure cat_ts(...)
-- DEPRICATED --
   PROCEDURE cat_ts (
      p_cwms_cat              OUT      sys_refcursor,
      p_officeid              IN       VARCHAR2 DEFAULT NULL,
      p_ts_subselect_string   IN       VARCHAR2 DEFAULT NULL
   )
-- DEPRICATED --
-- DEPRICATED --
-- DEPRICATED --
   IS
      l_office_id   VARCHAR2 (16);
   BEGIN
      IF p_officeid IS NULL
      THEN
         l_office_id := cwms_util.user_office_id;
      ELSE
         l_office_id := p_officeid;
      END IF;

      IF p_ts_subselect_string IS NULL
      THEN
---------------------------
-- only office specified --
---------------------------
         OPEN p_cwms_cat FOR
            SELECT   db_office_id, cwms_ts_id, interval_utc_offset
                FROM mv_cwms_ts_id
               WHERE db_office_id = UPPER (l_office_id)
            ORDER BY UPPER (cwms_ts_id) ASC;
      ELSE
---------------------------------------
-- both office and pattern specified --
---------------------------------------
         OPEN p_cwms_cat FOR
            SELECT   db_office_id, cwms_ts_id, interval_utc_offset
                FROM mv_cwms_ts_id
               WHERE db_office_id = UPPER (l_office_id)
                 AND UPPER (cwms_ts_id) LIKE
                        UPPER (REPLACE (REPLACE (p_ts_subselect_string,
                                                 '*',
                                                 '%'
                                                ),
                                        '?',
                                        '_'
                                       )
                              )
            ORDER BY UPPER (cwms_ts_id) ASC;
      END IF;
   END cat_ts;

-------------------------------------------------------------------------------
-- DEPRICATED --
-- DEPRICATED -- function cat_ts_tab(...)
-- DEPRICATED --
   FUNCTION cat_ts_tab (
      p_officeid              IN   VARCHAR2 DEFAULT NULL,
      p_ts_subselect_string   IN   VARCHAR2 DEFAULT NULL
   )
      RETURN cat_ts_tab_t PIPELINED
-- DEPRICATED --
-- DEPRICATED --
-- DEPRICATED --
   IS
      query_cursor   sys_refcursor;
      output_row     cat_ts_rec_t;
   BEGIN
      cat_ts (query_cursor, p_officeid, p_ts_subselect_string);

      LOOP
         FETCH query_cursor
          INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_ts_tab;

-------------------------------------------------------------------------------
-- DEPRICATED --
-- DEPRICATED -- procedure cat_ts_cwms_20(...)
-- DEPRICATED --
   PROCEDURE cat_ts_cwms_20 (
      p_cwms_cat              OUT      sys_refcursor,
      p_officeid              IN       VARCHAR2 DEFAULT NULL,
      p_ts_subselect_string   IN       VARCHAR2 DEFAULT NULL
   )
-- DEPRICATED --
-- DEPRICATED --
-- DEPRICATED --
   IS
      l_office_id   VARCHAR2 (16);
   BEGIN
      IF p_officeid IS NULL
      THEN
         l_office_id := cwms_util.user_office_id;
      ELSE
         l_office_id := p_officeid;
      END IF;

      IF p_ts_subselect_string IS NULL
      THEN
---------------------------
-- only office specified --
---------------------------
         OPEN p_cwms_cat FOR
            SELECT   v.db_office_id, v.cwms_ts_id, v.interval_utc_offset,
                     255,
                         -- substitute actual user privilege
                         v.active_flag,
                     CASE z.time_zone_code
                        WHEN 0
                           THEN NULL
                        ELSE z.time_zone_name
                     END AS lrts_timezone
                FROM mv_cwms_ts_id v, at_cwms_ts_spec s, cwms_time_zone z
               WHERE s.ts_code = v.ts_code
                 AND z.time_zone_code = NVL (s.time_zone_code, 0)
                 AND v.db_office_id = UPPER (l_office_id)
            ORDER BY UPPER (v.cwms_ts_id) ASC;
      ELSE
---------------------------------------
-- both office and pattern specified --
---------------------------------------
         OPEN p_cwms_cat FOR
            SELECT   v.db_office_id, v.cwms_ts_id, v.interval_utc_offset,
                     255,
                         -- substitute actual user privilege
                         v.active_flag,
                     CASE z.time_zone_code
                        WHEN 0
                           THEN NULL
                        ELSE z.time_zone_name
                     END AS lrts_time_zone
                FROM mv_cwms_ts_id v, at_cwms_ts_spec s, cwms_time_zone z
               WHERE s.ts_code = v.ts_code
                 AND z.time_zone_code = NVL (s.time_zone_code, 0)
                 AND v.db_office_id = UPPER (l_office_id)
                 AND UPPER (v.cwms_ts_id) LIKE
                        UPPER (REPLACE (REPLACE (p_ts_subselect_string,
                                                 '*',
                                                 '%'
                                                ),
                                        '?',
                                        '_'
                                       )
                              )
            ORDER BY UPPER (v.cwms_ts_id) ASC;
      END IF;
   END cat_ts_cwms_20;

-------------------------------------------------------------------------------
-- DEPRICATED --
-- DEPRICATED --function cat_ts_cwms_20_tab(...)
-- DEPRICATED --
   FUNCTION cat_ts_cwms_20_tab (
      p_officeid              IN   VARCHAR2 DEFAULT NULL,
      p_ts_subselect_string   IN   VARCHAR2 DEFAULT NULL
   )
      RETURN cat_ts_cwms_20_tab_t PIPELINED
-- DEPRICATED --
-- DEPRICATED --
-- DEPRICATED --
   IS
      query_cursor   sys_refcursor;
      output_row     cat_ts_cwms_20_rec_t;
   BEGIN
      cat_ts_cwms_20 (query_cursor, p_officeid, p_ts_subselect_string);

      LOOP
         FETCH query_cursor
          INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_ts_cwms_20_tab;

   PROCEDURE cat_ts_id (
      p_cwms_cat              OUT      sys_refcursor,
      p_ts_subselect_string   IN       VARCHAR2 DEFAULT NULL,
      p_loc_category_id       IN       VARCHAR2 DEFAULT NULL,
      p_loc_group_id          IN       VARCHAR2 DEFAULT NULL,
      p_db_office_id          IN       VARCHAR2 DEFAULT NULL
   )
   IS
      l_db_office_id          VARCHAR2 (16);
      l_db_office_code        NUMBER;
      l_loc_group_code        NUMBER         := NULL;
      l_ts_subselect_string   VARCHAR2 (512)
              := cwms_util.normalize_wildcards (TRIM (p_ts_subselect_string));
   BEGIN
      l_db_office_id := cwms_util.get_db_office_id (p_db_office_id);
      l_db_office_code := cwms_util.get_db_office_code (l_db_office_id);

---------------------------------------------------
-- get the loc_group_code if cat/group passed in --
---------------------------------------------------
      IF p_loc_category_id IS NOT NULL AND p_loc_group_id IS NOT NULL
      THEN
         l_loc_group_code :=
            cwms_util.get_loc_group_code (p_loc_category_id,
                                          p_loc_group_id,
                                          l_db_office_code
                                         );
      ELSIF    (p_loc_category_id IS NOT NULL AND p_loc_group_id IS NULL)
            OR (p_loc_category_id IS NULL AND p_loc_group_id IS NOT NULL)
      THEN
         cwms_err.RAISE
            ('ERROR',
             'The loc_category_id and loc_group_id is not a valid combination'
            );
      END IF;

      IF p_ts_subselect_string IS NULL
      THEN
         IF l_loc_group_code IS NULL
         THEN
            OPEN p_cwms_cat FOR
               SELECT   v.db_office_id, v.base_location_id, v.cwms_ts_id,
                        v.interval_utc_offset,
                        CASE z.time_zone_code
                           WHEN 0
                              THEN NULL
                           ELSE z.time_zone_name
                        END AS lrts_timezone,
                        v.active_flag, a.net_privilege_bit user_privileges
                   FROM mv_cwms_ts_id v,
                        at_cwms_ts_spec s,
                        cwms_time_zone z,
                        mv_sec_ts_priv a
                  WHERE s.ts_code = v.ts_code
                    AND a.ts_code = v.ts_code
                    AND z.time_zone_code = NVL (s.time_zone_code, 0)
                    AND v.db_office_code = l_db_office_code
                    AND a.user_id = cwms_util.get_user_id
               ORDER BY UPPER (v.cwms_ts_id) ASC;
         ELSE
            OPEN p_cwms_cat FOR
               SELECT   v.db_office_id, v.base_location_id, v.cwms_ts_id,
                        v.interval_utc_offset,
                        CASE z.time_zone_code
                           WHEN 0
                              THEN NULL
                           ELSE z.time_zone_name
                        END AS lrts_timezone,
                        v.active_flag, a.net_privilege_bit user_privileges
                   FROM mv_cwms_ts_id v,
                        at_cwms_ts_spec s,
                        cwms_time_zone z,
                        mv_sec_ts_priv a,
                        ---
                        at_loc_group_assignment b                          ---
                  WHERE s.ts_code = v.ts_code
                    AND a.ts_code = v.ts_code
                    AND z.time_zone_code = NVL (s.time_zone_code, 0)
                    AND v.db_office_code = l_db_office_code
                    AND a.user_id = cwms_util.get_user_id
                    ---
                    AND b.location_code = v.location_code                  ---
                    AND b.loc_group_code = l_loc_group_code                ---
               ORDER BY UPPER (v.cwms_ts_id) ASC;
         END IF;
      ELSE
         IF l_loc_group_code IS NULL
         THEN
            OPEN p_cwms_cat FOR
               SELECT   v.db_office_id, v.base_location_id, v.cwms_ts_id,
                        v.interval_utc_offset,
                        CASE z.time_zone_code
                           WHEN 0
                              THEN NULL
                           ELSE z.time_zone_name
                        END AS lrts_timezone,
                        v.active_flag, a.net_privilege_bit user_privileges
                   FROM mv_cwms_ts_id v,
                        at_cwms_ts_spec s,
                        cwms_time_zone z,
                        mv_sec_ts_priv a
                  WHERE s.ts_code = v.ts_code
                    AND a.ts_code = v.ts_code
                    AND z.time_zone_code = NVL (s.time_zone_code, 0)
                    AND v.db_office_code = l_db_office_code
                    AND a.user_id = cwms_util.get_user_id
                    AND UPPER (v.cwms_ts_id) LIKE
                                                 UPPER (l_ts_subselect_string)
               ORDER BY UPPER (v.cwms_ts_id) ASC;
         ELSE
            OPEN p_cwms_cat FOR
               SELECT   v.db_office_id, v.base_location_id, v.cwms_ts_id,
                        v.interval_utc_offset,
                        CASE z.time_zone_code
                           WHEN 0
                              THEN NULL
                           ELSE z.time_zone_name
                        END AS lrts_timezone,
                        v.active_flag, a.net_privilege_bit user_privileges
                   FROM mv_cwms_ts_id v,
                        at_cwms_ts_spec s,
                        cwms_time_zone z,
                        mv_sec_ts_priv a,
                        ---
                        at_loc_group_assignment b                          ---
                  WHERE s.ts_code = v.ts_code
                    AND a.ts_code = v.ts_code
                    AND z.time_zone_code = NVL (s.time_zone_code, 0)
                    AND v.db_office_code = l_db_office_code
                    AND a.user_id = cwms_util.get_user_id
                    AND UPPER (v.cwms_ts_id) LIKE
                                                 UPPER (l_ts_subselect_string)
                    ---
                    AND b.location_code = v.location_code                  ---
                    AND b.loc_group_code = l_loc_group_code                ---
               ORDER BY UPPER (v.cwms_ts_id) ASC;
         END IF;
      END IF;
   END cat_ts_id;

   FUNCTION cat_ts_id_tab (
      p_ts_subselect_string   IN   VARCHAR2 DEFAULT NULL,
      p_loc_category_id       IN   VARCHAR2 DEFAULT NULL,
      p_loc_group_id          IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id          IN   VARCHAR2 DEFAULT NULL
   )
      RETURN cat_ts_id_tab_t PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row     cat_ts_id_rec_t;
   BEGIN
      cat_ts_id (query_cursor,
                 p_ts_subselect_string,
                 p_loc_category_id,
                 p_loc_group_id,
                 p_db_office_id
                );

      LOOP
         FETCH query_cursor
          INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_ts_id_tab;

-------------------------------------------------------------------------------
-- procedure cat_location --
--
--
   PROCEDURE cat_location (
      p_cwms_cat          OUT      sys_refcursor,
      p_elevation_unit    IN       VARCHAR2 DEFAULT 'm',
      p_base_loc_only     IN       VARCHAR2 DEFAULT 'F',
      p_loc_category_id   IN       VARCHAR2 DEFAULT NULL,
      p_loc_group_id      IN       VARCHAR2 DEFAULT NULL,
      p_db_office_id      IN       VARCHAR2 DEFAULT NULL
   )
   IS
      l_from_id          cwms_unit.unit_id%TYPE             := 'm';
      l_to_id            cwms_unit.unit_id%TYPE
                                               := NVL (p_elevation_unit, 'm');
      l_from_code        cwms_unit.unit_code%TYPE;
      l_to_code          cwms_unit.unit_code%TYPE;
      l_factor           cwms_unit_conversion.factor%TYPE;
      l_offset           cwms_unit_conversion.offset%TYPE;
      l_office_id        cwms_office.office_id%TYPE;
      l_db_office_id     cwms_office.office_id%TYPE;
      l_db_office_code   NUMBER;
      l_loc_group_code   NUMBER                             := NULL;
      l_base_loc_only    BOOLEAN
               := cwms_util.return_true_or_false (NVL (p_base_loc_only, 'F'));
   BEGIN
-----------------------------------------------
-- get the office id of the hosting database --
-----------------------------------------------
      l_db_office_code := cwms_util.get_db_office_code (p_db_office_id);

      SELECT office_id
        INTO l_db_office_id
        FROM cwms_office
       WHERE office_code = l_db_office_code;

---------------------------------------------------
-- get the loc_group_code if cat/group passed in --
---------------------------------------------------
      IF p_loc_category_id IS NOT NULL AND p_loc_group_id IS NOT NULL
      THEN
         l_loc_group_code :=
            cwms_util.get_loc_group_code (p_loc_category_id,
                                          p_loc_group_id,
                                          l_db_office_code
                                         );
      ELSIF    (p_loc_category_id IS NOT NULL AND p_loc_group_id IS NULL)
            OR (p_loc_category_id IS NULL AND p_loc_group_id IS NOT NULL)
      THEN
         cwms_err.RAISE
            ('ERROR',
             'The loc_category_id and loc_group_id is not a valid combination'
            );
      END IF;

------------------------------------------
-- get the conversion factor and offset --
------------------------------------------
      SELECT unit_code
        INTO l_from_code
        FROM cwms_unit
       WHERE unit_id = l_from_id;

      SELECT unit_code
        INTO l_to_code
        FROM cwms_unit
       WHERE unit_id = l_to_id;

      SELECT factor, offset
        INTO l_factor, l_offset
        FROM cwms_unit_conversion
       WHERE from_unit_code = l_from_code AND to_unit_code = l_to_code;

----------------------
-- open the cursor  --
----------------------
      IF l_loc_group_code IS NOT NULL
      THEN
         IF l_base_loc_only
         THEN
            OPEN p_cwms_cat FOR
               SELECT   co.office_id db_office_id,
                           abl.base_location_id
                        || SUBSTR ('-', 1, LENGTH (apl.sub_location_id))
                        || apl.sub_location_id location_id,
                        abl.base_location_id, apl.sub_location_id,
                        cs.state_initial, cc.county_name, ctz.time_zone_name,
                        apl.location_type, apl.latitude, apl.longitude,
                        apl.horizontal_datum,
                        apl.elevation * cuc.factor + cuc.offset elevation,
                        cuc.to_unit_id elev_unit_id, apl.vertical_datum,
                        apl.public_name, apl.long_name, apl.description,
                        apl.active_flag
                   FROM at_physical_location apl,
                        at_base_location abl,
                        cwms_county cc,
                        cwms_office co,
                        cwms_state cs,
                        cwms_time_zone ctz,
                        cwms_unit_conversion cuc,
                        ---
                        at_loc_group_assignment atlga                      ---
                  WHERE abl.db_office_code = l_db_office_code
                    AND (cc.county_code = NVL (apl.county_code, 0))
                    AND (cs.state_code = NVL (cc.state_code, 0))
                    AND (abl.db_office_code = co.office_code)
                    AND (ctz.time_zone_code = NVL (apl.time_zone_code, 0))
                    AND apl.base_location_code = abl.base_location_code
                    AND apl.location_code != 0
                    AND cuc.from_unit_id = 'm'
                    AND cuc.to_unit_id = p_elevation_unit
                    ---
                    AND atlga.loc_group_code = l_loc_group_code            ---
                    AND apl.location_code = atlga.location_code            ---
                    AND apl.sub_location_id IS NULL                        ---
               ORDER BY location_id ASC;
         ELSE
            OPEN p_cwms_cat FOR
               SELECT   co.office_id db_office_id,
                           abl.base_location_id
                        || SUBSTR ('-', 1, LENGTH (apl.sub_location_id))
                        || apl.sub_location_id location_id,
                        abl.base_location_id, apl.sub_location_id,
                        cs.state_initial, cc.county_name, ctz.time_zone_name,
                        apl.location_type, apl.latitude, apl.longitude,
                        apl.horizontal_datum,
                        apl.elevation * cuc.factor + cuc.offset elevation,
                        cuc.to_unit_id elev_unit_id, apl.vertical_datum,
                        apl.public_name, apl.long_name, apl.description,
                        apl.active_flag
                   FROM at_physical_location apl,
                        at_base_location abl,
                        cwms_county cc,
                        cwms_office co,
                        cwms_state cs,
                        cwms_time_zone ctz,
                        cwms_unit_conversion cuc,
                        ---
                        at_loc_group_assignment atlga                      ---
                  WHERE abl.db_office_code = l_db_office_code
                    AND (cc.county_code = NVL (apl.county_code, 0))
                    AND (cs.state_code = NVL (cc.state_code, 0))
                    AND (abl.db_office_code = co.office_code)
                    AND (ctz.time_zone_code = NVL (apl.time_zone_code, 0))
                    AND apl.base_location_code = abl.base_location_code
                    AND apl.location_code != 0
                    AND cuc.from_unit_id = 'm'
                    AND cuc.to_unit_id = p_elevation_unit
                    ---
                    AND atlga.loc_group_code = l_loc_group_code            ---
                    AND apl.location_code = atlga.location_code            ---
               ORDER BY location_id ASC;
         END IF;
      ELSE
         IF l_base_loc_only
         THEN
            OPEN p_cwms_cat FOR
               SELECT   co.office_id db_office_id,
                           abl.base_location_id
                        || SUBSTR ('-', 1, LENGTH (apl.sub_location_id))
                        || apl.sub_location_id location_id,
                        abl.base_location_id, apl.sub_location_id,
                        cs.state_initial, cc.county_name, ctz.time_zone_name,
                        apl.location_type, apl.latitude, apl.longitude,
                        apl.horizontal_datum,
                        apl.elevation * cuc.factor + cuc.offset elevation,
                        cuc.to_unit_id elev_unit_id, apl.vertical_datum,
                        apl.public_name, apl.long_name, apl.description,
                        apl.active_flag
                   FROM at_physical_location apl,
                        at_base_location abl,
                        cwms_county cc,
                        cwms_office co,
                        cwms_state cs,
                        cwms_time_zone ctz,
                        cwms_unit_conversion cuc
                  WHERE abl.db_office_code = l_db_office_code
                    AND (cc.county_code = NVL (apl.county_code, 0))
                    AND (cs.state_code = NVL (cc.state_code, 0))
                    AND (abl.db_office_code = co.office_code)
                    AND (ctz.time_zone_code = NVL (apl.time_zone_code, 0))
                    AND apl.base_location_code = abl.base_location_code
                    AND apl.location_code != 0
                    AND cuc.from_unit_id = 'm'
                    AND cuc.to_unit_id = p_elevation_unit
                    ---
                    AND apl.sub_location_id IS NULL                        ---
               ORDER BY location_id ASC;
         ELSE
            OPEN p_cwms_cat FOR
               SELECT   co.office_id db_office_id,
                           abl.base_location_id
                        || SUBSTR ('-', 1, LENGTH (apl.sub_location_id))
                        || apl.sub_location_id location_id,
                        abl.base_location_id, apl.sub_location_id,
                        cs.state_initial, cc.county_name, ctz.time_zone_name,
                        apl.location_type, apl.latitude, apl.longitude,
                        apl.horizontal_datum,
                        apl.elevation * cuc.factor + cuc.offset elevation,
                        cuc.to_unit_id elev_unit_id, apl.vertical_datum,
                        apl.public_name, apl.long_name, apl.description,
                        apl.active_flag
                   FROM at_physical_location apl,
                        at_base_location abl,
                        cwms_county cc,
                        cwms_office co,
                        cwms_state cs,
                        cwms_time_zone ctz,
                        cwms_unit_conversion cuc
                  WHERE abl.db_office_code = l_db_office_code
                    AND (cc.county_code = NVL (apl.county_code, 0))
                    AND (cs.state_code = NVL (cc.state_code, 0))
                    AND (abl.db_office_code = co.office_code)
                    AND (ctz.time_zone_code = NVL (apl.time_zone_code, 0))
                    AND apl.base_location_code = abl.base_location_code
                    AND apl.location_code != 0
                    AND cuc.from_unit_id = 'm'
                    AND cuc.to_unit_id = p_elevation_unit
               ORDER BY location_id ASC;
         END IF;
      END IF;
   END cat_location;

   FUNCTION cat_location_tab (
      p_elevation_unit    IN   VARCHAR2 DEFAULT 'm',
      p_base_loc_only     IN   VARCHAR2 DEFAULT 'F',
      p_loc_category_id   IN   VARCHAR2 DEFAULT NULL,
      p_loc_group_id      IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   )
      RETURN cat_location_tab_t PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row     cat_location_rec_t;
   BEGIN
      cat_location (query_cursor,
                    p_elevation_unit,
                    p_base_loc_only,
                    p_loc_category_id,
                    p_loc_group_id,
                    p_db_office_id
                   );

      LOOP
         FETCH query_cursor
          INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_location_tab;

--------------------------------------------------------------------------------
-- DEPRICATED --
-- DEPRICATED -- cat_loc USE cat_location --
-- DEPRICATED --
   PROCEDURE cat_loc (
      p_cwms_cat         OUT      sys_refcursor,
      p_officeid         IN       VARCHAR2 DEFAULT NULL,
      p_elevation_unit   IN       VARCHAR2 DEFAULT 'm'
   )
-- DEPRICATED --
-- DEPRICATED --
-- DEPRICATED --
--------------------------------------------------------------------------------
   IS
      l_from_id        cwms_unit.unit_id%TYPE             := 'm';
      l_to_id          cwms_unit.unit_id%TYPE  := NVL (p_elevation_unit, 'm');
      l_from_code      cwms_unit.unit_code%TYPE;
      l_to_code        cwms_unit.unit_code%TYPE;
      l_factor         cwms_unit_conversion.factor%TYPE;
      l_offset         cwms_unit_conversion.offset%TYPE;
      l_office_id      cwms_office.office_id%TYPE;
      l_db_office_id   cwms_office.office_id%TYPE;
   BEGIN
-----------------------------------------------
-- get the office id of the hosting database --
-----------------------------------------------
      IF p_officeid IS NULL
      THEN
         l_office_id := cwms_util.user_office_id;
      ELSE
         l_office_id := p_officeid;
      END IF;

      SELECT o2.office_id
        INTO l_db_office_id
        FROM cwms_office o1, cwms_office o2
       WHERE o1.office_id = l_office_id
         AND o2.office_code = o1.db_host_office_code;

------------------------------------------
-- get the conversion factor and offset --
------------------------------------------
      SELECT unit_code
        INTO l_from_code
        FROM cwms_unit
       WHERE unit_id = l_from_id;

      SELECT unit_code
        INTO l_to_code
        FROM cwms_unit
       WHERE unit_id = l_to_id;

      SELECT factor, offset
        INTO l_factor, l_offset
        FROM cwms_unit_conversion
       WHERE from_unit_code = l_from_code AND to_unit_code = l_to_code;

----------------------
-- open the cursor  --
----------------------
      OPEN p_cwms_cat FOR
         SELECT   db_office_id, base_location_id, state_initial, county_name,
                  time_zone_name, location_type, latitude, longitude,
                  elevation * l_factor + l_offset AS elevation,
                  l_to_id AS elev_unit_id, vertical_datum, public_name,
                  long_name, description
             FROM av_loc alv
            WHERE db_office_id = UPPER (l_db_office_id)
         ORDER BY db_office_id ASC, base_location_id ASC;
   END cat_loc;

-------------------------------------------------------------------------------
-- DEPRICATED --
-- DEPRICATED --function cat_loc_tab USE cat_location_tab --
-- DEPRICATED --
   FUNCTION cat_loc_tab (
      p_officeid         IN   VARCHAR2 DEFAULT NULL,
      p_elevation_unit   IN   VARCHAR2 DEFAULT 'm'
   )
      RETURN cat_loc_tab_t PIPELINED
-- DEPRICATED --
-- DEPRICATED --
-- DEPRICATED --
--------------------------------------------------------------------------------
   IS
      query_cursor   sys_refcursor;
      output_row     cat_loc_rec_t;
   BEGIN
      cat_loc (query_cursor, p_officeid, p_elevation_unit);

      LOOP
         FETCH query_cursor
          INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_loc_tab;

-------------------------------------------------------------------------------
-- procedure cat_loc_alias(...)
--
--
   PROCEDURE cat_loc_alias (
      p_cwms_cat   OUT      sys_refcursor,
      p_officeid   IN       VARCHAR2 DEFAULT NULL,
      p_cwmsid     IN       VARCHAR2 DEFAULT NULL
   )
   IS
      l_office_id   VARCHAR2 (16);
   BEGIN
      NULL;
      /*
         IF p_officeid IS NULL
         THEN
            l_office_id := cwms_util.user_office_id;
         ELSE
            l_office_id := p_officeid;
         END IF;

         IF p_cwmsid IS NULL
         THEN
   ---------------------------
   -- only office specified --
   ---------------------------
            OPEN p_cwms_cat FOR
               SELECT   avl.db_office_id, avl.location_id, aan.agency_id,
                        sn.alias_id
                   FROM at_physical_location pl,
                        at_alias_name sn,
                        at_agency_name aan,
                        av_loc avl
                  WHERE pl.location_code = sn.location_code
                    AND avl.location_code = pl.location_code
                    AND aan.agency_code = sn.agency_code
                    AND avl.db_office_id = UPPER (l_office_id)
               ORDER BY avl.db_office_id ASC,
                        avl.location_id ASC,
                        aan.agency_id ASC,
                        sn.alias_id ASC;
         ELSE
   ----------------------------------------
   -- both office and location specified --
   ----------------------------------------
            OPEN p_cwms_cat FOR
               SELECT   avl.db_office_id, avl.location_id, aan.agency_id,
                        sn.alias_id
                   FROM at_physical_location pl,
                        at_alias_name sn,
                        at_agency_name aan,
                        av_loc avl
                  WHERE pl.location_code = sn.location_code
                    AND avl.location_code = pl.location_code
                    AND aan.agency_code = sn.agency_code
                    AND UPPER (avl.base_location_id) = UPPER (p_cwmsid)
                    AND avl.db_office_id = UPPER (l_office_id)
               ORDER BY avl.db_office_id ASC,
                        avl.location_id ASC,
                        aan.agency_id ASC,
                        sn.alias_id ASC;
         END IF;
   */
   END cat_loc_alias;

-------------------------------------------------------------------------------
-- function cat_loc_alias_tab(...)
--
--
   FUNCTION cat_loc_aliases_tab (
      p_location_id       IN   VARCHAR2 DEFAULT NULL,
      p_loc_category_id   IN   VARCHAR2 DEFAULT NULL,
      p_loc_group_id      IN   VARCHAR2 DEFAULT NULL,
      p_abreviated        IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   )
      RETURN cat_loc_alias_tab_t PIPELINED
   IS
      output_row     cat_loc_alias_rec_t;
      query_cursor   sys_refcursor;
   BEGIN
      cat_loc_aliases (query_cursor,
                       p_location_id,
                       p_loc_category_id,
                       p_loc_group_id,
                       p_abreviated,
                       p_db_office_id
                      );

      LOOP
         FETCH query_cursor
          INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_loc_aliases_tab;

-------------------------------------------------------------------------------
-- DEPRICATED -
-- DEPRICATED - procedure cat_param(...) - DEPRICATED -
-- DEPRICATED -
   PROCEDURE cat_param (p_cwms_cat OUT sys_refcursor)
   IS
   BEGIN
      OPEN p_cwms_cat FOR
         SELECT   cp.base_parameter_id, cp.long_name param_long_name,
                  cp.description param_description, cu.unit_id,
                  cu.long_name unit_long_name,
                  cu.description unit_description
             FROM cwms_base_parameter cp, cwms_unit cu
            WHERE cp.unit_code = cu.unit_code
         ORDER BY cp.base_parameter_id ASC;
   END cat_param;

-------------------------------------------------------------------------------
-- function cat_param_tab(...)
--
--
   FUNCTION cat_param_tab
      RETURN cat_param_tab_t PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row     cat_param_rec_t;
   BEGIN
      cat_param (query_cursor);

      LOOP
         FETCH query_cursor
          INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_param_tab;

   PROCEDURE cat_base_parameter (p_cwms_cat OUT sys_refcursor)
   IS
   BEGIN
      OPEN p_cwms_cat FOR
         SELECT   cp.base_parameter_id, cp.long_name param_long_name,
                  cp.description param_description, cu.unit_id,
                  cu.long_name unit_long_name,
                  cu.description unit_description
             FROM cwms_base_parameter cp, cwms_unit cu
            WHERE cp.unit_code = cu.unit_code
         ORDER BY cp.base_parameter_id ASC;
   END cat_base_parameter;

-------------------------------------------------------------------------------
   FUNCTION cat_base_parameter_tab
      RETURN cat_base_param_tab_t PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row     cat_base_param_rec_t;
   BEGIN
      cat_base_parameter (query_cursor);

      LOOP
         FETCH query_cursor
          INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_base_parameter_tab;

   PROCEDURE cat_parameter (
      p_cwms_cat       OUT      sys_refcursor,
      p_db_office_id   IN       VARCHAR2 DEFAULT NULL
   )
   IS
      l_db_office_code   NUMBER
                             := cwms_util.get_db_office_code (p_db_office_id);
   BEGIN
      OPEN p_cwms_cat FOR
         SELECT      cp.base_parameter_id
                  || SUBSTR ('-', 1, LENGTH (atp.sub_parameter_id))
                  || atp.sub_parameter_id parameter_id,
                  cp.base_parameter_id, atp.sub_parameter_id,
                  CASE
                     WHEN atp.sub_parameter_desc IS NULL
                        THEN cp.description
                     ELSE atp.sub_parameter_desc
                  END sub_parameter_desc,
                  co.office_id db_office_id, cu.unit_id db_unit_id,
                  cu.long_name unit_long_name,
                  cu.description unit_description
             FROM at_parameter atp,
                  cwms_base_parameter cp,
                  cwms_unit cu,
                  cwms_office co
            WHERE atp.base_parameter_code = cp.base_parameter_code
              AND cp.unit_code = cu.unit_code
              AND co.office_code = atp.db_office_code
              AND atp.db_office_code IN
                             (cwms_util.db_office_code_all, l_db_office_code)
         ORDER BY cp.base_parameter_id ASC;
   END cat_parameter;

   FUNCTION cat_parameter_tab (p_db_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN cat_parameter_tab_t PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row     cat_parameter_rec_t;
   BEGIN
      cat_parameter (query_cursor, p_db_office_id);

      LOOP
         FETCH query_cursor
          INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_parameter_tab;

-------------------------------------------------------------------------------
-- DEPRICATED -
-- DEPRICATED procedure cat_sub_param(...)
-- DEPRICATED -
   PROCEDURE cat_sub_param (p_cwms_cat OUT sys_refcursor)
   IS
   BEGIN
      OPEN p_cwms_cat FOR
         SELECT   cp.base_parameter_id, cs.sub_parameter_id,
                  cs.sub_parameter_desc
             FROM at_parameter cs, cwms_base_parameter cp
            WHERE cp.base_parameter_code(+) = cs.base_parameter_code
         ORDER BY cp.base_parameter_id ASC, cs.sub_parameter_id ASC;
   END cat_sub_param;

-------------------------------------------------------------------------------
-- function cat_sub_param_tab(...)
--
--
   FUNCTION cat_sub_param_tab
      RETURN cat_sub_param_tab_t PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row     cat_sub_param_rec_t;
   BEGIN
      cat_sub_param (query_cursor);

      LOOP
         FETCH query_cursor
          INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_sub_param_tab;

-------------------------------------------------------------------------------
-- procedure cat_sub_loc(...)
--
--
   PROCEDURE cat_sub_loc (
      p_cwms_cat   OUT      sys_refcursor,
      p_officeid   IN       VARCHAR2 DEFAULT NULL
   )
   IS
      l_office_id     VARCHAR2 (16);
      l_office_code   NUMBER;
   BEGIN
      IF p_officeid IS NULL
      THEN
         l_office_id := cwms_util.user_office_id;
      ELSE
         l_office_id := UPPER (p_officeid);
      END IF;

      l_office_code := cwms_loc.get_office_code (l_office_id);

      OPEN p_cwms_cat FOR
         SELECT   sub_location_id, description
             FROM (SELECT DISTINCT apl.sub_location_id, apl.description
                              FROM at_physical_location apl,
                                   at_base_location abl
                             WHERE apl.base_location_code =
                                                        abl.base_location_code
                               AND abl.db_office_code = l_office_code)
         ORDER BY UPPER (sub_location_id);
   END cat_sub_loc;

-------------------------------------------------------------------------------
-- function cat_sub_loc_tab(...)
--
--
   FUNCTION cat_sub_loc_tab (p_officeid IN VARCHAR2 DEFAULT NULL)
      RETURN cat_sub_loc_tab_t PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row     cat_sub_loc_rec_t;
   BEGIN
      cat_sub_loc (query_cursor, p_officeid);

--
      LOOP
         FETCH query_cursor
          INTO output_row;

--
         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

--
      CLOSE query_cursor;

--
      RETURN;
   END cat_sub_loc_tab;

   -------------------------------------------------------------------------------
-- procedure cat_state(...)
--
--
   PROCEDURE cat_state (p_cwms_cat OUT sys_refcursor)
   IS
   BEGIN
      OPEN p_cwms_cat FOR
         SELECT   state_initial, NAME "STATE_NAME"
             FROM cwms_state
         ORDER BY state_initial ASC;
   END cat_state;

-------------------------------------------------------------------------------
-- function cat_state_tab(...)
--
--
   FUNCTION cat_state_tab
      RETURN cat_state_tab_t PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row     cat_state_rec_t;
   BEGIN
      cat_state (query_cursor);

      LOOP
         FETCH query_cursor
          INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_state_tab;

-------------------------------------------------------------------------------
-- procedure cat_county(...)
--
--
   PROCEDURE cat_county (
      p_cwms_cat   OUT      sys_refcursor,
      p_stateint   IN       VARCHAR2 DEFAULT NULL
   )
   IS
   BEGIN
      IF p_stateint IS NULL
      THEN
----------------------------
-- state is not specified --
----------------------------
         OPEN p_cwms_cat FOR
            SELECT   county_id, county_name, state_initial
                FROM cwms_county cc, cwms_state cs
               WHERE cs.state_code = cc.state_code
            ORDER BY state_initial ASC, county_id ASC;
      ELSE
------------------------
-- state is specified --
------------------------
         OPEN p_cwms_cat FOR
            SELECT   county_id, county_name, state_initial
                FROM cwms_county cc, cwms_state cs
               WHERE cs.state_code = cc.state_code
                 AND state_initial = UPPER (p_stateint)
            ORDER BY state_initial ASC, county_id ASC;
      END IF;
   END cat_county;

-------------------------------------------------------------------------------
-- function cat_county_tab(...)
--
--
   FUNCTION cat_county_tab (p_stateint IN VARCHAR2 DEFAULT NULL)
      RETURN cat_county_tab_t PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row     cat_county_rec_t;
   BEGIN
      cat_county (query_cursor, p_stateint);

      LOOP
         FETCH query_cursor
          INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_county_tab;

-------------------------------------------------------------------------------
-- procedure cat_timezone(...)
--
--
   PROCEDURE cat_timezone (p_cwms_cat OUT sys_refcursor)
   IS
   BEGIN
      OPEN p_cwms_cat FOR
         SELECT   time_zone_name, utc_offset, dst_offset
             FROM cwms_time_zone
         ORDER BY time_zone_name ASC;
   END cat_timezone;

-------------------------------------------------------------------------------
-- function cat_timezone_tab(...)
--
--
   FUNCTION cat_timezone_tab
      RETURN cat_timezone_tab_t PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row     cat_timezone_rec_t;
   BEGIN
      cat_timezone (query_cursor);

      LOOP
         FETCH query_cursor
          INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_timezone_tab;

-------------------------------------------------------------------------------
-- procedure cat_dss_file(...)
--
--
   PROCEDURE cat_dss_file (
      p_cwms_cat      OUT      sys_refcursor,
      p_filemgr_url   IN       VARCHAR2 DEFAULT NULL,
      p_file_name     IN       VARCHAR2 DEFAULT NULL
   )
   IS
   BEGIN
      IF p_filemgr_url IS NULL AND p_file_name IS NULL
      THEN
----------------------------------------
-- neither url nor name are specified --
----------------------------------------
         OPEN p_cwms_cat FOR
            SELECT   dss_filemgr_url, dss_file_name
                FROM at_dss_file
            ORDER BY dss_filemgr_url ASC, dss_file_name ASC;
      ELSIF p_filemgr_url IS NULL
      THEN
----------------------------
-- only name is specified --
----------------------------
         OPEN p_cwms_cat FOR
            SELECT   dss_filemgr_url, dss_file_name
                FROM at_dss_file
               WHERE dss_file_name LIKE
                          REPLACE (REPLACE (p_file_name, '*', '%'), '?', '_')
            ORDER BY dss_filemgr_url ASC, dss_file_name ASC;
      ELSIF p_file_name IS NULL
      THEN
---------------------------
-- only url is specified --
---------------------------
         OPEN p_cwms_cat FOR
            SELECT   dss_filemgr_url, dss_file_name
                FROM at_dss_file
               WHERE dss_filemgr_url LIKE
                        REPLACE (REPLACE (p_filemgr_url, '*', '%'), '?', '_')
            ORDER BY dss_filemgr_url ASC, dss_file_name ASC;
      ELSE
-------------------------------------
-- both url and name are specified --
-------------------------------------
         OPEN p_cwms_cat FOR
            SELECT   dss_filemgr_url, dss_file_name
                FROM at_dss_file
               WHERE dss_filemgr_url LIKE
                        REPLACE (REPLACE (p_filemgr_url, '*', '%'), '?', '_')
                 AND dss_file_name LIKE
                           REPLACE (REPLACE (p_file_name, '*', '%'), '?', '_')
            ORDER BY dss_filemgr_url ASC, dss_file_name ASC;
      END IF;
   END cat_dss_file;

-------------------------------------------------------------------------------
-- function cat_dss_file_tab(...)
--
--
   FUNCTION cat_dss_file_tab (
      p_filemgr_url   IN   VARCHAR2 DEFAULT NULL,
      p_file_name     IN   VARCHAR2 DEFAULT NULL
   )
      RETURN cat_dss_file_tab_t PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row     cat_dss_file_rec_t;
   BEGIN
      cat_dss_file (query_cursor, p_filemgr_url, p_file_name);

      LOOP
         FETCH query_cursor
          INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_dss_file_tab;

-------------------------------------------------------------------------------
-- procedure cat_dss_xchg_set(...)
--
--
   PROCEDURE cat_dss_xchg_set (
      p_cwms_cat      OUT      sys_refcursor,
      p_officeid      IN       VARCHAR2 DEFAULT NULL,
      p_filemgr_url   IN       VARCHAR2 DEFAULT NULL,
      p_file_name     IN       VARCHAR2 DEFAULT NULL
   )
   IS
      l_office_code   NUMBER (10)   := NULL;
      l_office_id     VARCHAR2 (16);
   BEGIN
      IF p_officeid IS NULL
      THEN
         l_office_id := cwms_util.user_office_id;
      ELSE
         l_office_id := p_officeid;
      END IF;

      SELECT office_code
        INTO l_office_code
        FROM cwms_office
       WHERE office_id = UPPER (l_office_id);

      IF p_filemgr_url IS NULL AND p_file_name IS NULL
      THEN
----------------------------------------
-- neither url nor name are specified --
----------------------------------------
         OPEN p_cwms_cat FOR
            SELECT   office_id, dss_xchg_set_id, description,
                     dss_filemgr_url, dss_file_name,
                     CASE NVL (realtime, -1)
                        WHEN -1
                           THEN NULL
                        ELSE (SELECT dss_xchg_direction_id
                                FROM cwms_dss_xchg_direction
                               WHERE dss_xchg_direction_code = realtime)
                     END
                FROM at_dss_file f, at_dss_xchg_set s, cwms_office o
               WHERE s.office_code = l_office_code
                 AND s.dss_file_code = f.dss_file_code
                 AND o.office_code = s.office_code
            ORDER BY dss_xchg_set_id ASC;
      ELSIF p_filemgr_url IS NULL
      THEN
----------------------------
-- only name is specified --
----------------------------
         OPEN p_cwms_cat FOR
            SELECT   office_id, dss_xchg_set_id, description,
                     dss_filemgr_url, dss_file_name,
                     CASE NVL (realtime, -1)
                        WHEN -1
                           THEN NULL
                        ELSE (SELECT dss_xchg_direction_id
                                FROM cwms_dss_xchg_direction
                               WHERE dss_xchg_direction_code = realtime)
                     END
                FROM at_dss_file f, at_dss_xchg_set s, cwms_office o
               WHERE s.office_code = l_office_code
                 AND s.dss_file_code = f.dss_file_code
                 AND o.office_code = s.office_code
                 AND dss_file_name LIKE
                           REPLACE (REPLACE (p_file_name, '*', '%'), '?', '_')
            ORDER BY dss_xchg_set_id ASC;
      ELSIF p_file_name IS NULL
      THEN
---------------------------
-- only url is specified --
---------------------------
         OPEN p_cwms_cat FOR
            SELECT   office_id, dss_xchg_set_id, description,
                     dss_filemgr_url, dss_file_name,
                     CASE NVL (realtime, -1)
                        WHEN -1
                           THEN NULL
                        ELSE (SELECT dss_xchg_direction_id
                                FROM cwms_dss_xchg_direction
                               WHERE dss_xchg_direction_code = realtime)
                     END
                FROM at_dss_file f, at_dss_xchg_set s, cwms_office o
               WHERE s.office_code = l_office_code
                 AND s.dss_file_code = f.dss_file_code
                 AND o.office_code = s.office_code
                 AND dss_filemgr_url LIKE
                         REPLACE (REPLACE (p_filemgr_url, '*', '%'), '?', '_')
            ORDER BY dss_xchg_set_id ASC;
      ELSE
-------------------------------------
-- both url and name are specified --
-------------------------------------
         OPEN p_cwms_cat FOR
            SELECT   office_id, dss_xchg_set_id, description,
                     dss_filemgr_url, dss_file_name,
                     CASE NVL (realtime, -1)
                        WHEN -1
                           THEN NULL
                        ELSE (SELECT dss_xchg_direction_id
                                FROM cwms_dss_xchg_direction
                               WHERE dss_xchg_direction_code = realtime)
                     END,
                     last_update
                FROM at_dss_file f, at_dss_xchg_set s, cwms_office o
               WHERE s.office_code = l_office_code
                 AND s.dss_file_code = f.dss_file_code
                 AND o.office_code = s.office_code
                 AND dss_filemgr_url LIKE
                         REPLACE (REPLACE (p_filemgr_url, '*', '%'), '?', '_')
                 AND dss_file_name LIKE
                           REPLACE (REPLACE (p_file_name, '*', '%'), '?', '_')
            ORDER BY dss_xchg_set_id ASC;
      END IF;
   END cat_dss_xchg_set;

-------------------------------------------------------------------------------
-- function cat_dss_xchg_set_tab(...)
--
--
   FUNCTION cat_dss_xchg_set_tab (
      p_officeid      IN   VARCHAR2 DEFAULT NULL,
      p_filemgr_url   IN   VARCHAR2 DEFAULT NULL,
      p_file_name     IN   VARCHAR2 DEFAULT NULL
   )
      RETURN cat_dss_xchg_set_tab_t PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row     cat_dss_xchg_set_rec_t;
   BEGIN
      cat_dss_xchg_set (query_cursor, p_officeid, p_filemgr_url, p_file_name);

      LOOP
         FETCH query_cursor
          INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_dss_xchg_set_tab;

-------------------------------------------------------------------------------
-- procedure cat_dss_xchg_ts_map(...)
--
--
   PROCEDURE cat_dss_xchg_ts_map (
      p_cwms_cat          OUT      sys_refcursor,
      p_officeid          IN       VARCHAR2,
      p_dss_xchg_set_id   IN       VARCHAR2
   )
   IS
      l_dss_xchg_set_code   NUMBER (10);
      l_office_id           VARCHAR2 (16);
   BEGIN
      IF p_officeid IS NULL
      THEN
         l_office_id := cwms_util.user_office_id;
      ELSE
         l_office_id := p_officeid;
      END IF;

      BEGIN
         SELECT dss_xchg_set_code
           INTO l_dss_xchg_set_code
           FROM cwms_office o, at_dss_xchg_set s
          WHERE o.office_id = UPPER (l_office_id)
            AND s.office_code = o.office_code
            AND UPPER (s.dss_xchg_set_id) = UPPER (p_dss_xchg_set_id);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.RAISE ('INVALID_ITEM',
                            l_office_id || '/' || p_dss_xchg_set_id,
                            'HEC-DSS exchange set'
                           );
      END;

      OPEN p_cwms_cat FOR
         SELECT   cwms_ts_id,
                     '/'
                  || NVL (a_pathname_part, '')
                  || '/'
                  || NVL (b_pathname_part, '')
                  || '/'
                  || NVL (c_pathname_part, '')
                  || '//'
                  || NVL (e_pathname_part, '')
                  || '/'
                  || NVL (f_pathname_part, '')
                  || '/',
                  dss_parameter_type_id, dspec.unit_id,
                  time_zone_name AS dss_timezone_name,
                  tz_usage_id AS dss_tz_usage_id
             FROM at_dss_xchg_set xset,
                  at_dss_ts_xchg_map xmap,
                  at_dss_ts_xchg_spec xspec,
                  at_dss_ts_spec dspec,
                  mv_cwms_ts_id tspec,
                  cwms_dss_parameter_type ptype,
                  cwms_time_zone tzone,
                  cwms_tz_usage tzuse
            WHERE xset.dss_xchg_set_code = l_dss_xchg_set_code
              AND xset.dss_xchg_set_id = p_dss_xchg_set_id
              AND xmap.dss_xchg_set_code = xset.dss_xchg_set_code
              AND xmap.dss_ts_xchg_code = xspec.dss_ts_xchg_code
              AND tspec.ts_code = xspec.ts_code
              AND xspec.dss_ts_code = dspec.dss_ts_code
              AND ptype.dss_parameter_type_code =
                                                 dspec.dss_parameter_type_code
              AND tzone.time_zone_code = dspec.time_zone_code
              AND tzuse.tz_usage_code = dspec.tz_usage_code
         ORDER BY cwms_ts_id;
   END cat_dss_xchg_ts_map;

-------------------------------------------------------------------------------
-- function cat_dss_xchg_ts_map_tab(...)
--
--
   FUNCTION cat_dss_xchg_ts_map_tab (
      p_officeid          IN   VARCHAR2,
      p_dss_xchg_set_id   IN   VARCHAR2
   )
      RETURN cat_dss_xchg_ts_map_tab_t PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row     cat_dss_xchg_ts_map_rec_t;
   BEGIN
      cat_dss_xchg_ts_map (query_cursor, p_officeid, p_dss_xchg_set_id);

      LOOP
         FETCH query_cursor
          INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_dss_xchg_ts_map_tab;

-------------------------------------------------------------------------------
-- function cat_loc_alias_abrev_tab(...)
--
--
   FUNCTION cat_loc_alias_abrev_tab (
      p_location_id   IN   VARCHAR2 DEFAULT NULL,
      p_agency_id     IN   VARCHAR2 DEFAULT NULL,
      p_office_id     IN   VARCHAR2 DEFAULT NULL
   )
      RETURN cat_loc_alias_abrev_tab_t PIPELINED
   IS
      output_row     cat_loc_alias_abrev_rec_t;
      query_cursor   sys_refcursor;
   BEGIN
      cat_loc_aliases (query_cursor,
                       p_location_id,
                       p_agency_id,
                       'T',
                       p_office_id
                      );

      LOOP
         FETCH query_cursor
          INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_loc_alias_abrev_tab;

-------------------------------------------------------------------------------
-- procedure cat_loc_alias(...)
--
--
   PROCEDURE cat_loc_aliases_java (
      p_cwms_cat          OUT      sys_refcursor,
      p_location_id       IN       VARCHAR2 DEFAULT NULL,
      p_loc_category_id   IN       VARCHAR2 DEFAULT NULL,
      p_loc_group_id      IN       VARCHAR2 DEFAULT NULL,
      p_abreviated        IN       VARCHAR2 DEFAULT 'T',
      p_db_office_id      IN       VARCHAR2 DEFAULT NULL
   )
   IS
   BEGIN
      cat_loc_aliases (p_cwms_cat             => p_cwms_cat,
                       p_location_id          => p_location_id,
                       p_loc_category_id      => p_loc_category_id,
                       p_loc_group_id         => p_loc_group_id,
                       p_abreviated           => p_abreviated,
                       p_db_office_id         => p_db_office_id
                      );
   END;

--
   PROCEDURE cat_loc_aliases (
      p_cwms_cat          IN OUT   sys_refcursor,
      p_location_id       IN       VARCHAR2 DEFAULT NULL,
      p_loc_category_id   IN       VARCHAR2 DEFAULT NULL,
      p_loc_group_id      IN       VARCHAR2 DEFAULT NULL,
      p_abreviated        IN       VARCHAR2 DEFAULT 'T',
      p_db_office_id      IN       VARCHAR2 DEFAULT NULL
   )
   IS
      l_db_office_code   NUMBER
                             := cwms_util.get_db_office_code (p_db_office_id);
      l_abreviated       BOOLEAN
                  := cwms_util.return_true_or_false (NVL (p_abreviated, 'T'));
      l_loc_id           VARCHAR2 (16);
      l_loc_grp_id       VARCHAR2 (32);
      l_loc_cat_id       VARCHAR2 (32);
      l_is_null          BOOLEAN       := TRUE;
   BEGIN
      IF p_location_id IS NULL
      THEN
         l_loc_id := '%';
      ELSE
         l_loc_id :=
                 cwms_util.normalize_wildcards (UPPER (TRIM (p_location_id)));
         l_is_null := FALSE;
      END IF;

      --
      IF p_loc_category_id IS NULL
      THEN
         l_loc_cat_id := '%';
      ELSE
         l_loc_cat_id :=
             cwms_util.normalize_wildcards (UPPER (TRIM (p_loc_category_id)));
         l_is_null := FALSE;
      END IF;

      --
      IF p_loc_group_id IS NULL
      THEN
         l_loc_grp_id := '%';
      ELSE
         l_loc_grp_id :=
                cwms_util.normalize_wildcards (UPPER (TRIM (p_loc_group_id)));
         l_is_null := FALSE;
      END IF;

      IF l_abreviated
      THEN
         IF l_is_null
         THEN
            -- abreviated listing...
            OPEN p_cwms_cat FOR
               SELECT   db_office_id, location_id, cat_db_office_id,
                        loc_category_id, grp_db_office_id, loc_group_id,
                        loc_group_desc, loc_alias_id
                   FROM (SELECT e1.office_id db_office_id, c.location_code,
                                b.loc_group_code,
                                   d.base_location_id
                                || SUBSTR ('-', 1, LENGTH (c.sub_location_id))
                                || c.sub_location_id location_id,
                                a.loc_category_id,
                                e2.office_id cat_db_office_id,
                                b.loc_group_id,
                                e3.office_id grp_db_office_id,
                                b.loc_group_desc
                           FROM at_loc_category a,
                                at_loc_group b,
                                at_physical_location c,
                                at_base_location d,
                                cwms_office e1,
                                cwms_office e2,
                                cwms_office e3
                          WHERE a.loc_category_code = b.loc_category_code
                            AND c.base_location_code = d.base_location_code
                            AND b.db_office_code IN
                                   (cwms_util.db_office_code_all,
                                    l_db_office_code
                                   )
                            AND d.db_office_code = l_db_office_code
                            AND d.db_office_code = e1.office_code
                            AND a.db_office_code = e2.office_code
                            AND b.db_office_code = e3.office_code) a
                        JOIN
                        at_loc_group_assignment b
                        USING (location_code, loc_group_code)
               ORDER BY UPPER (location_id),
                        UPPER (loc_category_id),
                        UPPER (loc_group_id);
         ELSE
            -- Refined abreviated listing...
            OPEN p_cwms_cat FOR
               SELECT   db_office_id, location_id, cat_db_office_id,
                        loc_category_id, grp_db_office_id, loc_group_id,
                        loc_group_desc, loc_alias_id
                   FROM (SELECT e1.office_id db_office_id, c.location_code,
                                b.loc_group_code,
                                   d.base_location_id
                                || SUBSTR ('-', 1, LENGTH (c.sub_location_id))
                                || c.sub_location_id location_id,
                                a.loc_category_id,
                                e2.office_id cat_db_office_id,
                                b.loc_group_id,
                                e3.office_id grp_db_office_id,
                                b.loc_group_desc
                           FROM at_loc_category a,
                                at_loc_group b,
                                at_physical_location c,
                                at_base_location d,
                                cwms_office e1,
                                cwms_office e2,
                                cwms_office e3
                          WHERE a.loc_category_code = b.loc_category_code
                            AND c.base_location_code = d.base_location_code
                            AND b.db_office_code IN
                                   (cwms_util.db_office_code_all,
                                    l_db_office_code
                                   )
                            AND d.db_office_code = l_db_office_code
                            AND d.db_office_code = e1.office_code
                            AND a.db_office_code = e2.office_code
                            AND b.db_office_code = e3.office_code) a
                        JOIN
                        at_loc_group_assignment b
                        USING (location_code, loc_group_code)
                  WHERE UPPER (a.location_id) LIKE l_loc_id
                    AND UPPER (a.loc_category_id) LIKE l_loc_cat_id
                    AND UPPER (a.loc_group_id) LIKE l_loc_grp_id
               ORDER BY UPPER (location_id),
                        UPPER (loc_category_id),
                        UPPER (loc_group_id);
         END IF;
      ELSE
         IF l_is_null
         THEN
            -- full listing...
            OPEN p_cwms_cat FOR
               SELECT   db_office_id, location_id, cat_db_office_id,
                        loc_category_id, grp_db_office_id, loc_group_id,
                        loc_group_desc, loc_alias_id
                   FROM (SELECT e1.office_id db_office_id, c.location_code,
                                b.loc_group_code,
                                   d.base_location_id
                                || SUBSTR ('-', 1, LENGTH (c.sub_location_id))
                                || c.sub_location_id location_id,
                                a.loc_category_id,
                                e2.office_id cat_db_office_id,
                                b.loc_group_id,
                                e3.office_id grp_db_office_id,
                                b.loc_group_desc
                           FROM at_loc_category a,
                                at_loc_group b,
                                at_physical_location c,
                                at_base_location d,
                                cwms_office e1,
                                cwms_office e2,
                                cwms_office e3
                          WHERE a.loc_category_code = b.loc_category_code
                            AND c.base_location_code = d.base_location_code
                            AND b.db_office_code IN
                                   (cwms_util.db_office_code_all,
                                    l_db_office_code
                                   )
                            AND d.db_office_code = l_db_office_code
                            AND d.db_office_code = e1.office_code
                            AND a.db_office_code = e2.office_code
                            AND b.db_office_code = e3.office_code) a
                        FULL OUTER JOIN
                        at_loc_group_assignment b
                        USING (location_code, loc_group_code)
               ORDER BY UPPER (location_id),
                        UPPER (loc_category_id),
                        UPPER (loc_group_id);
         ELSE
            -- Refined full listing...
            OPEN p_cwms_cat FOR
               SELECT   db_office_id, location_id, cat_db_office_id,
                        loc_category_id, grp_db_office_id, loc_group_id,
                        loc_group_desc, loc_alias_id
                   FROM (SELECT e1.office_id db_office_id, c.location_code,
                                b.loc_group_code,
                                   d.base_location_id
                                || SUBSTR ('-', 1, LENGTH (c.sub_location_id))
                                || c.sub_location_id location_id,
                                a.loc_category_id,
                                e2.office_id cat_db_office_id,
                                b.loc_group_id,
                                e3.office_id grp_db_office_id,
                                b.loc_group_desc
                           FROM at_loc_category a,
                                at_loc_group b,
                                at_physical_location c,
                                at_base_location d,
                                cwms_office e1,
                                cwms_office e2,
                                cwms_office e3
                          WHERE a.loc_category_code = b.loc_category_code
                            AND c.base_location_code = d.base_location_code
                            AND b.db_office_code IN
                                   (cwms_util.db_office_code_all,
                                    l_db_office_code
                                   )
                            AND d.db_office_code = l_db_office_code
                            AND d.db_office_code = e1.office_code
                            AND a.db_office_code = e2.office_code
                            AND b.db_office_code = e3.office_code) a
                        FULL OUTER JOIN
                        at_loc_group_assignment b
                        USING (location_code, loc_group_code)
                  WHERE UPPER (a.location_id) LIKE l_loc_id
                    AND UPPER (a.loc_category_id) LIKE l_loc_cat_id
                    AND UPPER (a.loc_group_id) LIKE l_loc_grp_id
               ORDER BY UPPER (location_id),
                        UPPER (loc_category_id),
                        UPPER (loc_group_id);
         END IF;
      END IF;
   END cat_loc_aliases;

-------------------------------------------------------------------------------
-- function cat_property_tab(...)
--
   FUNCTION cat_property_tab (
      p_office_id       IN   VARCHAR2 DEFAULT NULL,
      p_prop_category   IN   VARCHAR2 DEFAULT NULL,
      p_prop_id         IN   VARCHAR2 DEFAULT NULL
   )
      RETURN cat_property_tab_t PIPELINED
   IS
      output_row     cat_property_rec_t;
      query_cursor   sys_refcursor;
   BEGIN
      cat_property (query_cursor, p_office_id, p_prop_category, p_prop_id);

      LOOP
         FETCH query_cursor
          INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_property_tab;

-------------------------------------------------------------------------------
-- procedure cat_property(...)
--
--
   PROCEDURE cat_property (
      p_cwms_cat        OUT      sys_refcursor,
      p_office_id       IN       VARCHAR2 DEFAULT NULL,
      p_prop_category   IN       VARCHAR2 DEFAULT NULL,
      p_prop_id         IN       VARCHAR2 DEFAULT NULL
   )
   IS
      l_office_code     NUMBER (10)    := NULL;
      l_office_id       VARCHAR2 (16);
      l_prop_category   VARCHAR2 (256);
      l_prop_id         VARCHAR2 (256);
   BEGIN
      l_office_id := NVL (p_office_id, cwms_util.user_office_id);
      l_prop_category :=
         UPPER (REPLACE (REPLACE (NVL (p_prop_category, '%'), '*', '%'),
                         '?',
                         '_'
                        )
               );
      l_prop_id :=
          UPPER (REPLACE (REPLACE (NVL (p_prop_id, '%'), '*', '%'), '?', '_'));

      OPEN p_cwms_cat FOR
         SELECT   o.office_id, p.prop_category, p.prop_id
             FROM at_properties p, cwms_office o
            WHERE o.office_id = l_office_id
              AND p.office_code = o.office_code
              AND UPPER (p.prop_category) LIKE l_prop_category ESCAPE '\'
              AND UPPER (p.prop_id) LIKE l_prop_id ESCAPE '\'
         ORDER BY o.office_id, UPPER (p.prop_category), UPPER (p.prop_id) ASC;
   END cat_property;

   PROCEDURE cat_loc_group (
      p_cwms_cat       OUT      sys_refcursor,
      p_db_office_id   IN       VARCHAR2 DEFAULT NULL
   )
   IS
      l_db_office_code   NUMBER
                             := cwms_util.get_db_office_code (p_db_office_id);
   BEGIN
      OPEN p_cwms_cat FOR
         SELECT co.office_id cat_db_office_id, loc_category_id,
                loc_category_desc, coo.office_id grp_db_office_id,
                loc_group_id, loc_group_desc
           FROM cwms_office co,
                cwms_office coo,
                at_loc_category atlc,
                at_loc_group atlg
          WHERE atlc.db_office_code = co.office_code
            AND atlg.db_office_code = coo.office_code(+)
            AND atlc.loc_category_code = atlg.loc_category_code(+)
            AND NVL (atlg.db_office_code, cwms_util.db_office_code_all) IN
                             (l_db_office_code, cwms_util.db_office_code_all)
            AND atlc.db_office_code IN
                             (l_db_office_code, cwms_util.db_office_code_all);
   END cat_loc_group;

   FUNCTION cat_loc_group_tab (p_db_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN cat_loc_grp_tab_t PIPELINED
   IS
      output_row     cat_loc_grp_rec_t;
      query_cursor   sys_refcursor;
   BEGIN
      cat_loc_group (query_cursor, p_db_office_id);

      LOOP
         FETCH query_cursor
          INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_loc_group_tab;
END cwms_cat;
/

SHOW errors;