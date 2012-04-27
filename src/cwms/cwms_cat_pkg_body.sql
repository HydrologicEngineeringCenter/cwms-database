/* Formatted on 4/8/2011 8:39:45 AM (QP5 v5.139.911.3011) */
SET define off
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
      o    cat_ts_otab_t;
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
      r    cat_ts_rec_t := NULL;
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
      t    cat_ts_tab_t;
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
      o    cat_ts_cwms_20_otab_t;
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
      r    cat_ts_cwms_20_rec_t := NULL;
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
      t    cat_ts_cwms_20_tab_t;
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
      o    cat_loc_otab_t;
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
      r    cat_loc_rec_t := NULL;
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
      t    cat_loc_tab_t;
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
   --    RETURN cat_loc_alias_obj_t
   --   IS
   --   BEGIN
   --    RETURN cat_loc_alias_obj_t (r.office_id,
   --                                r.cwms_id,
   --                                r.source_id,
   --                                r.gage_id
   --                               );
   --   END cat_loc_alias_rec2obj;
   -------------------------------------------------------------------------------
   -- CAT_LOCATION record-to-object conversion function
   --
      FUNCTION cat_location_rec2obj (r IN cat_location_rec_t)
         RETURN cat_location_obj_t
      IS
      BEGIN
         RETURN cat_location_obj_t (
            r.db_office_id,
            r.location_id,
            r.base_location_id,
            r.sub_location_id,
            r.state_initial,
            r.county_name,
            r.time_zone_name,
            r.location_type,
            r.latitude,
            r.longitude,
            r.horizontal_datum,
            r.elevation,
            r.elev_unit_id,
            r.vertical_datum,
            r.public_name,
            r.long_name,
            r.description,
            r.active_flag
            );
      END cat_location_rec2obj;

   -------------------------------------------------------------------------------
   -- CAT_LOCATION table-to-object conversion function
   --
      FUNCTION cat_location_tab2obj (t IN cat_location_tab_t)
         RETURN cat_location_otab_t
      IS
         o   cat_location_otab_t;
      BEGIN
         FOR i IN 1 .. t.LAST
         LOOP
            o (i) := cat_location_rec2obj (t (i));
         END LOOP;

         RETURN o;
      END cat_location_tab2obj;

   -------------------------------------------------------------------------------
   -- CAT_LOCATION object-to-record conversion function
   --
      FUNCTION cat_location_obj2rec (o IN cat_location_obj_t)
         RETURN cat_location_rec_t
      IS
         r   cat_location_rec_t := NULL;
      BEGIN
         IF o IS NOT NULL
         THEN
            r.db_office_id := o.db_office_id;
            r.location_id := o.location_id;
            r.base_location_id := o.base_location_id;
            r.sub_location_id := o.sub_location_id;
            r.state_initial := o.state_initial;
            r.county_name := o.county_name;
            r.time_zone_name := o.time_zone_name;
            r.location_type := o.location_type;
            r.latitude := o.latitude;
            r.longitude := o.longitude;
            r.horizontal_datum := o.horizontal_datum;
            r.elevation := o.elevation;
            r.elev_unit_id := o.elev_unit_id;
            r.vertical_datum := o.vertical_datum;
            r.public_name := o.public_name;
            r.long_name := o.long_name;
            r.description := o.description;
            r.active_flag := o.active_flag;
         END IF;

         RETURN r;
      END cat_location_obj2rec;

   -------------------------------------------------------------------------------
   -- CAT_LOCATION object-to-table conversion function
   --
      FUNCTION cat_location_obj2tab (o IN cat_location_otab_t)
         RETURN cat_location_tab_t
      IS
         t   cat_location_tab_t;
      BEGIN
         FOR i IN 1 .. o.LAST
         LOOP
            t (i) := cat_location_obj2rec (o (i));
         END LOOP;

         RETURN t;
      END cat_location_obj2tab;

   -------------------------------------------------------------------------------
   -- CAT_LOCATION2 record-to-object conversion function
   --
      FUNCTION cat_location2_rec2obj (r IN cat_location2_rec_t)
         RETURN cat_location2_obj_t
      IS
      BEGIN
         RETURN cat_location2_obj_t (
            r.db_office_id,
            r.location_id,
            r.base_location_id,
            r.sub_location_id,
            r.state_initial,
            r.county_name,
            r.time_zone_name,
            r.location_type,
            r.latitude,
            r.longitude,
            r.horizontal_datum,
            r.elevation,
            r.elev_unit_id,
            r.vertical_datum,
            r.public_name,
            r.long_name,
            r.description,
            r.active_flag,
            r.location_kind_id,
            r.map_label,
            r.published_latitude,
            r.published_longitude,
            r.bounding_office_id,
            r.nation_id,
            r.nearest_city
            );
      END cat_location2_rec2obj;

   -------------------------------------------------------------------------------
   -- CAT_LOCATION2 table-to-object conversion function
   --
      FUNCTION cat_location2_tab2obj (t IN cat_location2_tab_t)
         RETURN cat_location2_otab_t
      IS
         o   cat_location2_otab_t;
      BEGIN
         FOR i IN 1 .. t.LAST
         LOOP
            o (i) := cat_location2_rec2obj (t (i));
         END LOOP;

         RETURN o;
      END cat_location2_tab2obj;

   -------------------------------------------------------------------------------
   -- CAT_LOCATION2 object-to-record conversion function
   --
      FUNCTION cat_location2_obj2rec (o IN cat_location2_obj_t)
         RETURN cat_location2_rec_t
      IS
         r   cat_location2_rec_t := NULL;
      BEGIN
         IF o IS NOT NULL
         THEN
            r.db_office_id := o.db_office_id;
            r.location_id := o.location_id;
            r.base_location_id := o.base_location_id;
            r.sub_location_id := o.sub_location_id;
            r.state_initial := o.state_initial;
            r.county_name := o.county_name;
            r.time_zone_name := o.time_zone_name;
            r.location_type := o.location_type;
            r.latitude := o.latitude;
            r.longitude := o.longitude;
            r.horizontal_datum := o.horizontal_datum;
            r.elevation := o.elevation;
            r.elev_unit_id := o.elev_unit_id;
            r.vertical_datum := o.vertical_datum;
            r.public_name := o.public_name;
            r.long_name := o.long_name;
            r.description := o.description;
            r.active_flag := o.active_flag;
            r.location_kind_id := o.location_kind_id;
            r.map_label := o.map_label;
            r.published_latitude := o.published_latitude;
            r.published_longitude := o.published_longitude;
            r.bounding_office_id := o.bounding_office_id;
            r.nation_id := o.nation_id;
            r.nearest_city := o.nearest_city;
         END IF;

         RETURN r;
      END cat_location2_obj2rec;

   -------------------------------------------------------------------------------
   -- CAT_LOCATION2 object-to-table conversion function
   --
      FUNCTION cat_location2_obj2tab (o IN cat_location2_otab_t)
         RETURN cat_location2_tab_t
      IS
         t   cat_location2_tab_t;
      BEGIN
         FOR i IN 1 .. o.LAST
         LOOP
            t (i) := cat_location2_obj2rec (o (i));
         END LOOP;

         RETURN t;
      END cat_location2_obj2tab;

   -------------------------------------------------------------------------------
   -- CAT_LOCATION_KIND record-to-object conversion function
   --
      FUNCTION cat_location_kind_rec2obj (r IN cat_location_kind_rec_t)
         RETURN cat_location_kind_obj_t
      IS
      BEGIN
         RETURN cat_location_kind_obj_t (
            r.office_id,
            r.location_kind_id,
            r.description
            );
      END cat_location_kind_rec2obj;

   -------------------------------------------------------------------------------
   -- CAT_LOCATION_KIND table-to-object conversion function
   --
      FUNCTION cat_location_kind_tab2obj (t IN cat_location_kind_tab_t)
         RETURN cat_location_kind_otab_t
      IS
         o   cat_location_kind_otab_t;
      BEGIN
         FOR i IN 1 .. t.LAST
         LOOP
            o (i) := cat_location_kind_rec2obj (t (i));
         END LOOP;

         RETURN o;
      END cat_location_kind_tab2obj;

   -------------------------------------------------------------------------------
   -- CAT_LOCATION_KIND object-to-record conversion function
   --
      FUNCTION cat_location_kind_obj2rec (o IN cat_location_kind_obj_t)
         RETURN cat_location_kind_rec_t
      IS
         r   cat_location_kind_rec_t := NULL;
      BEGIN
         IF o IS NOT NULL
         THEN
            r.office_id        := o.office_id;
            r.location_kind_id := o.location_kind_id;
            r.description      := o.description;
         END IF;

         RETURN r;
      END cat_location_kind_obj2rec;

   -------------------------------------------------------------------------------
   -- CAT_LOCATION_KIND object-to-table conversion function
   --
      FUNCTION cat_location_kind_obj2tab (o IN cat_location_kind_otab_t)
         RETURN cat_location_kind_tab_t
      IS
         t   cat_location_kind_tab_t;
      BEGIN
         FOR i IN 1 .. o.LAST
         LOOP
            t (i) := cat_location_kind_obj2rec (o (i));
         END LOOP;

         RETURN t;
      END cat_location_kind_obj2tab;

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

   ---------------------------------------------------------------------------------
   ---- CAT_LOC_ALIAS object-to-record conversion function
   ----
   --   FUNCTION cat_loc_alias_obj2rec (o IN cat_loc_alias_obj_t)
   --    RETURN cat_loc_alias_rec_t
   --   IS
   --    r    cat_loc_alias_rec_t := NULL;
   --   BEGIN
   --    IF o IS NOT NULL
   --    THEN
   --       r.office_id := o.office_id;
   --       r.cwms_id := o.cwms_id;
   --       r.source_id := o.source_id;
   --       r.gage_id := o.gage_id;
   --    END IF;

   --    RETURN r;
   --   END cat_loc_alias_obj2rec;

   -------------------------------------------------------------------------------
   -- CAT_LOC_ALIAS object-to-table conversion function
   --
   --   FUNCTION cat_loc_alias_obj2tab (o IN cat_loc_alias_otab_t)
   --    RETURN cat_loc_alias_tab_t
   --   IS
   --    t    cat_loc_alias_tab_t;
   --   BEGIN
   --    FOR i IN 1 .. o.LAST
   --    LOOP
   --       t (i) := cat_loc_alias_obj2rec (o (i));
   --    END LOOP;

   --    RETURN t;
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
      o    cat_param_otab_t;
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
      r    cat_param_rec_t := NULL;
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
      t    cat_param_tab_t;
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
      o    cat_sub_param_otab_t;
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
      r    cat_sub_param_rec_t := NULL;
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
      t    cat_sub_param_tab_t;
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
      o    cat_sub_loc_otab_t;
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
      r    cat_sub_loc_rec_t := NULL;
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
      t    cat_sub_loc_tab_t;
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
      o    cat_state_otab_t;
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
      r    cat_state_rec_t := NULL;
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
      t    cat_state_tab_t;
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
      o    cat_county_otab_t;
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
      r    cat_county_rec_t := NULL;
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
      t    cat_county_tab_t;
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
      o    cat_timezone_otab_t;
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
      r    cat_timezone_rec_t := NULL;
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
      t    cat_timezone_tab_t;
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
      RETURN cat_dss_file_obj_t (r.office_id,
                                 r.dss_filemgr_url,
                                 r.dss_file_name
                                );
   END cat_dss_file_rec2obj;

   -------------------------------------------------------------------------------
   -- CAT_DSS_FILE table-to-object conversion function
   --
   FUNCTION cat_dss_file_tab2obj (t IN cat_dss_file_tab_t)
      RETURN cat_dss_file_otab_t
   IS
      o    cat_dss_file_otab_t;
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
      r    cat_dss_file_rec_t := NULL;
   BEGIN
      IF o IS NOT NULL
      THEN
         r.office_id := o.office_id;
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
      t    cat_dss_file_tab_t;
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
      o    cat_dss_xchg_set_otab_t;
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
      r    cat_dss_xchg_set_rec_t := NULL;
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
      t    cat_dss_xchg_set_tab_t;
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
      RETURN cat_dss_xchg_ts_map_obj_t (r.office_id,
                                        r.cwms_ts_id,
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
      RETURN cat_dss_xchg_tsmap_otab_t
   IS
      o    cat_dss_xchg_tsmap_otab_t;
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
      r    cat_dss_xchg_ts_map_rec_t := NULL;
   BEGIN
      IF o IS NOT NULL
      THEN
         r.office_id := o.office_id;
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
   FUNCTION cat_dss_xchg_ts_map_obj2tab (o IN cat_dss_xchg_tsmap_otab_t)
      RETURN cat_dss_xchg_ts_map_tab_t
   IS
      t    cat_dss_xchg_ts_map_tab_t;
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
   PROCEDURE cat_ts (p_cwms_cat                  OUT sys_refcursor,
                     p_office_id             IN     VARCHAR2 DEFAULT NULL ,
                     p_ts_subselect_string   IN     VARCHAR2 DEFAULT NULL
                    )
   -- DEPRICATED --
   -- DEPRICATED --
   -- DEPRICATED --
   IS
      l_office_id   VARCHAR2 (16);
   BEGIN
      IF p_office_id IS NULL
      THEN
         l_office_id := cwms_util.user_office_id;
      ELSE
         l_office_id := p_office_id;
      END IF;

      IF p_ts_subselect_string IS NULL
      THEN
         ---------------------------
         -- only office specified --
         ---------------------------
         OPEN p_cwms_cat FOR
              SELECT   db_office_id, cwms_ts_id, interval_utc_offset
                FROM   mv_cwms_ts_id
               WHERE   db_office_id = UPPER (l_office_id)
            ORDER BY   UPPER (cwms_ts_id) ASC;
      ELSE
         ---------------------------------------
         -- both office and pattern specified --
         ---------------------------------------
         OPEN p_cwms_cat FOR
              SELECT   db_office_id, cwms_ts_id, interval_utc_offset
                FROM   mv_cwms_ts_id
               WHERE   db_office_id = UPPER (l_office_id)
                       AND UPPER (cwms_ts_id) LIKE
                             UPPER(REPLACE (
                                      REPLACE (p_ts_subselect_string, '*', '%'),
                                      '?',
                                      '_'
                                   ))
            ORDER BY   UPPER (cwms_ts_id) ASC;
      END IF;
   END cat_ts;

   -------------------------------------------------------------------------------
   -- DEPRICATED --
   -- DEPRICATED -- function cat_ts_tab(...)
   -- DEPRICATED --
   FUNCTION cat_ts_tab (p_office_id             IN VARCHAR2 DEFAULT NULL ,
                        p_ts_subselect_string   IN VARCHAR2 DEFAULT NULL
                       )
      RETURN cat_ts_tab_t
      PIPELINED
   -- DEPRICATED --
   -- DEPRICATED --
   -- DEPRICATED --
   IS
      query_cursor   sys_refcursor;
      output_row      cat_ts_rec_t;
   BEGIN
      cat_ts (query_cursor, p_office_id, p_ts_subselect_string);

      LOOP
         FETCH query_cursor INTO   output_row;

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
      p_cwms_cat                  OUT sys_refcursor,
      p_office_id             IN     VARCHAR2 DEFAULT NULL ,
      p_ts_subselect_string   IN     VARCHAR2 DEFAULT NULL
   )
   -- DEPRICATED --
   -- DEPRICATED --
   -- DEPRICATED --
   IS
      l_office_id   VARCHAR2 (16);
   BEGIN
      IF p_office_id IS NULL
      THEN
         l_office_id := cwms_util.user_office_id;
      ELSE
         l_office_id := p_office_id;
      END IF;

      IF p_ts_subselect_string IS NULL
      THEN
         ---------------------------
         -- only office specified --
         ---------------------------
         OPEN p_cwms_cat FOR
              SELECT   v.db_office_id, v.cwms_ts_id, v.interval_utc_offset, 255,
                       -- substitute actual user privilege
                       v.ts_active_flag,
                       CASE z.time_zone_code
                          WHEN 0 THEN NULL
                          ELSE z.time_zone_name
                       END
                          AS lrts_timezone
                FROM   mv_cwms_ts_id v, at_cwms_ts_spec s, cwms_time_zone z
               WHERE       s.ts_code = v.ts_code
                       AND z.time_zone_code = NVL (s.time_zone_code, 0)
                       AND v.db_office_id = UPPER (l_office_id)
            ORDER BY   UPPER (v.cwms_ts_id) ASC;
      ELSE
         ---------------------------------------
         -- both office and pattern specified --
         ---------------------------------------
         OPEN p_cwms_cat FOR
              SELECT   v.db_office_id, v.cwms_ts_id, v.interval_utc_offset, 255,
                       -- substitute actual user privilege
                       v.ts_active_flag,
                       CASE z.time_zone_code
                          WHEN 0 THEN NULL
                          ELSE z.time_zone_name
                       END
                          AS lrts_time_zone
                FROM   mv_cwms_ts_id v, at_cwms_ts_spec s, cwms_time_zone z
               WHERE       s.ts_code = v.ts_code
                       AND z.time_zone_code = NVL (s.time_zone_code, 0)
                       AND v.db_office_id = UPPER (l_office_id)
                       AND UPPER (v.cwms_ts_id) LIKE
                             UPPER(REPLACE (
                                      REPLACE (p_ts_subselect_string, '*', '%'),
                                      '?',
                                      '_'
                                   ))
            ORDER BY   UPPER (v.cwms_ts_id) ASC;
      END IF;
   END cat_ts_cwms_20;

   -------------------------------------------------------------------------------
   -- DEPRICATED --
   -- DEPRICATED --function cat_ts_cwms_20_tab(...)
   -- DEPRICATED --
   FUNCTION cat_ts_cwms_20_tab (
      p_office_id             IN VARCHAR2 DEFAULT NULL ,
      p_ts_subselect_string   IN VARCHAR2 DEFAULT NULL
   )
      RETURN cat_ts_cwms_20_tab_t
      PIPELINED
   -- DEPRICATED --
   -- DEPRICATED --
   -- DEPRICATED --
   IS
      query_cursor   sys_refcursor;
      output_row      cat_ts_cwms_20_rec_t;
   BEGIN
      cat_ts_cwms_20 (query_cursor, p_office_id, p_ts_subselect_string);

      LOOP
         FETCH query_cursor INTO   output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_ts_cwms_20_tab;

   /*
   start cat_ts_id

   if p_db_office_id is NULL, then a cateloge of all cwms_ts_id's for all offices is returned.

       end cat_ts_id
     */
  PROCEDURE cat_ts_id (
      p_cwms_cat                  OUT sys_refcursor,
      p_ts_subselect_string   IN     VARCHAR2 DEFAULT NULL ,
      p_loc_category_id       IN     VARCHAR2 DEFAULT NULL ,
      p_loc_group_id          IN     VARCHAR2 DEFAULT NULL ,
      p_ts_category_id       IN     VARCHAR2 DEFAULT NULL ,
      p_ts_group_id          IN     VARCHAR2 DEFAULT NULL ,
      p_db_office_id          IN     VARCHAR2 DEFAULT NULL
   )
   IS
      l_db_office_id     VARCHAR2 (16);
      l_db_office_code    NUMBER;
      l_loc_group_code    NUMBER := NULL;
       l_ts_group_code    NUMBER := NULL;
      l_ts_subselect_string VARCHAR2 (512)
            := nvl(cwms_util.normalize_wildcards(TRIM (p_ts_subselect_string)), '%') ;
   BEGIN

      l_db_office_id := cwms_util.get_db_office_id (p_db_office_id);
      l_db_office_code := cwms_util.get_db_office_code (l_db_office_id);

      ---------------------------------------------------
      -- get the loc_group_code if cat/group passed in --
      ---------------------------------------------------
      IF (p_loc_category_id IS NULL) != (p_loc_group_id IS NULL)
      THEN
         cwms_err.raise (
            'ERROR',
            'The loc_category_id and loc_group_id is not a valid combination'
         );
      END IF;
      IF p_loc_group_id IS NOT NULL
      THEN
         l_loc_group_code :=
            cwms_util.get_loc_group_code (p_loc_category_id,
                                          p_loc_group_id,
                                          l_db_office_code
                                         );
      END IF;
      
       ---------------------------------------------------
      -- get the ts_group_code if cat/group passed in --
      ---------------------------------------------------
      IF (p_ts_category_id IS NULL) != (p_ts_group_id IS NULL)
      THEN
         cwms_err.raise (
            'ERROR',
            'The ts_category_id and ts_group_id is not a valid combination'
         );
      END IF;
      IF p_ts_group_id IS NOT NULL
      THEN
         l_ts_group_code :=
            cwms_util.get_ts_group_code (p_ts_category_id,
                                          p_ts_group_id,
                                          l_db_office_code
                                         );
      END IF;
      --
    ---- Revised Select 11Mar2011
    --
    IF p_db_office_id IS NULL
    THEN
        l_db_office_code := NULL;            -- i.e., return ts_id's for all offices
    END IF;

    OPEN p_cwms_cat FOR
        SELECT      v.db_office_id, v.base_location_id, v.cwms_ts_id,
                      v.interval_utc_offset, z.time_zone_name lrts_timezone,
                      v.ts_active_flag, a.user_privileges
             FROM   mv_cwms_ts_id v
                      JOIN (SELECT   ts_code, net_privilege_bit user_privileges
                                 FROM   av_sec_ts_privileges
                                WHERE   username = cwms_util.get_user_id) a
                          USING (ts_code)
                      JOIN at_cwms_ts_spec s
                          USING (ts_code)
                      LEFT OUTER JOIN cwms_time_zone z
                          USING (time_zone_code)
            WHERE   (l_loc_group_code IS NULL
                        OR v.location_code IN
                                (SELECT     location_code
                                    FROM     at_loc_group_assignment
                                  WHERE     loc_group_code = l_loc_group_code))
                     AND(l_ts_group_code IS NULL
                     OR ts_code IN 
                        (SELECT ts_code
                            FROM at_ts_group_assignment
                                WHERE ts_group_code=l_ts_group_code))
                     AND  (l_db_office_code IS NULL
                             OR v.db_office_code = l_db_office_code)
                      AND UPPER (v.cwms_ts_id) LIKE UPPER (l_ts_subselect_string)
        ORDER BY   UPPER (v.cwms_ts_id), UPPER (v.db_office_id) ASC;
--
---- Original Released Select...
--
--       OPEN p_cwms_cat FOR
--             SELECT DISTINCT
--                      b.db_office_id,
--                      b.base_location_id,
--                      b.cwms_ts_id,
--                      b.interval_utc_offset,
--                      z.time_zone_name lrts_timezone,
--                      b.ts_active_flag,
--                      b.user_privileges
--              FROM  (   SELECT a.ts_code,
--                                     v.location_code,
--                                     v.db_office_id,
--                                     v.base_location_id,
--                                     v.cwms_ts_id,
--                                     v.interval_utc_offset,
--                                     v.ts_active_flag,
--                                     a.user_privileges
--                              FROM mv_cwms_ts_id v,
--                                     (     SELECT ts_code,
--                                                   net_privilege_bit user_privileges
--                                             FROM av_sec_ts_privileges
--                                           WHERE username = cwms_util.get_user_id
--                                     ) a
--                             WHERE v.ts_code = a.ts_code
--                               AND v.db_office_code = l_db_office_code
--                      ) b,
--                      (   SELECT location_code
--                              FROM at_loc_group_assignment
--                             WHERE loc_group_code = nvl(l_loc_group_code, loc_group_code)
--                      ) c,
--                      at_cwms_ts_spec s,
--                      cwms_time_zone z
--              WHERE (l_loc_group_code IS NULL OR (b.location_code = c.location_code))
--                 AND b.ts_code = s.ts_code
--                 AND s.time_zone_code = z.time_zone_code(+)
--                 AND UPPER(b.cwms_ts_id) LIKE UPPER(l_ts_subselect_string)
--          ORDER BY UPPER(b.cwms_ts_id), UPPER(b.db_office_id) ASC;
--
END cat_ts_id;

   FUNCTION cat_ts_id_tab (p_ts_subselect_string   IN VARCHAR2 DEFAULT NULL ,
                           p_loc_category_id       IN VARCHAR2 DEFAULT NULL ,
                           p_loc_group_id          IN VARCHAR2 DEFAULT NULL ,
                           p_ts_category_id       IN     VARCHAR2 DEFAULT NULL ,
                           p_ts_group_id          IN     VARCHAR2 DEFAULT NULL ,
                           p_db_office_id          IN VARCHAR2 DEFAULT NULL
                          )
      RETURN cat_ts_id_tab_t
      PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row      cat_ts_id_rec_t;
   BEGIN
      cat_ts_id (query_cursor,
                 p_ts_subselect_string,
                 p_loc_category_id,
                 p_loc_group_id,
                 p_ts_category_id,
                 p_ts_group_id,
                 p_db_office_id
                );

      LOOP
         FETCH query_cursor INTO   output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;
   END cat_ts_id_tab;


   procedure cat_ts_alias (
      p_cwms_cat     out sys_refcursor,
      p_cwms_ts_id   in  varchar2 default null,
      p_db_office_id in  varchar2 default null
   )
   is
      l_office_code number(10);
   begin
      ------------------
      -- sanity check --
      ------------------
      cwms_util.check_inputs(str_tab_t(
         p_cwms_ts_id,
         p_db_office_id));
      l_office_code := cwms_util.get_db_office_code(p_db_office_id);
      -----------------------------
      -- open the catalog cursor --
      -----------------------------
      open p_cwms_cat for 
         select o.office_id,
                cwms_ts.get_ts_id(a.ts_code) as ts_id,
                g.ts_group_id as agency_id,
                a.ts_alias_id
           from at_ts_group_assignment a,
                at_ts_group g,
                at_ts_category c,
                cwms_office o
          where C.TS_CATEGORY_ID = 'Agency Aliases'
            and g.ts_category_code = c.ts_category_code
            and G.DB_OFFICE_CODE in (l_office_code, cwms_util.db_office_code_all)
            and a.ts_group_code = g.ts_group_code
            and upper(cwms_ts.get_ts_id(a.ts_code)) = upper(nvl(p_cwms_ts_id, cwms_ts.get_ts_id(a.ts_code)))
       order by cwms_ts.get_ts_id(a.ts_code),
                g.ts_group_id,
                a.ts_alias_id;           
   end cat_ts_alias;

   procedure cat_ts_aliases (
      p_cwms_cat       out sys_refcursor,
      p_ts_id          in  varchar2 default null,
      p_ts_category_id in  varchar2 default null,
      p_ts_group_id    in  varchar2 default null,
      p_abbreviated    in  varchar2 default 'T',
      p_db_office_id   in  varchar2 default null
   )
   is
      l_abbreviated boolean;
      l_office_code number(10);   
   begin
      ------------------
      -- sanity check --
      ------------------
      cwms_util.check_inputs(str_tab_t(
         p_ts_id,
         p_ts_category_id,
         p_ts_group_id,
         p_abbreviated,
         p_db_office_id));
      
      l_office_code := cwms_util.get_db_office_code(p_db_office_id);
      l_abbreviated := cwms_util.is_true(p_abbreviated);

      if l_abbreviated then
         ------------------------
         -- perform inner join --
         ------------------------
         open p_cwms_cat for
            select db_office_id,
                   cwms_ts.get_ts_id(ts_code) as ts_id,
                   cat_db_office_id,
                   ts_category_id,
                   grp_db_office_id,
                   ts_group_id,
                   ts_group_desc,
                   ts_alias_id,
                   case 
                     when ts_ref_code is null then null
                     else cwms_ts.get_ts_id(ts_ref_code)
                   end as ref_ts_id,
                   shared_ts_alias_id,
                   case
                     when shared_ts_ref_code is null then null
                     else cwms_ts.get_ts_id(shared_ts_ref_code)
                   end as ref_ts_id,
                   ts_attribute
              from ( select o1.office_id as cat_db_office_id,
                            c.ts_category_id,
                            o2.office_id as grp_db_office_id,
                            g.ts_group_code,
                            g.ts_group_id,
                            g.ts_group_desc,
                            g.shared_ts_alias_id,
                            g.shared_ts_ref_code
                       from at_ts_category c,
                            at_ts_group g,
                            cwms_office o1,
                            cwms_office o2
                      where upper(c.ts_category_id) like cwms_util.normalize_wildcards(nvl(upper(p_ts_category_id), '*'))
                        and upper(g.ts_group_id) like cwms_util.normalize_wildcards(nvl(upper(p_ts_group_id), '*'))
                        and g.db_office_code in (cwms_util.db_office_code_all, l_office_code)
                        and g.ts_category_code = c.ts_category_code
                        and o1.office_code = c.db_office_code
                        and o2.office_code = g.db_office_code
                   ) grp
                   join 
                   ( select a.ts_code,
                            a.ts_group_code,
                            a.ts_attribute,
                            a.ts_alias_id,
                            a.ts_ref_code,
                            o.office_id as db_office_id 
                       from at_ts_group_assignment a,
                            at_cwms_ts_id t,
                            cwms_office o
                      where upper(cwms_ts.get_ts_id(a.ts_code)) like cwms_util.normalize_wildcards(nvl(upper(p_ts_id), '*'))
                        and t.ts_code = a.ts_code
                        and o.office_code = t.db_office_code
                   ) assgn on assgn.ts_group_code = grp.ts_group_code;
      else
         ------------------------
         -- perform outer join --
         ------------------------
         open p_cwms_cat for
            select db_office_id,
                   cwms_ts.get_ts_id(ts_code) as ts_id,
                   cat_db_office_id,
                   ts_category_id,
                   grp_db_office_id,
                   ts_group_id,
                   ts_group_desc,
                   ts_alias_id,
                   case 
                     when ts_ref_code is null then null
                     else cwms_ts.get_ts_id(ts_ref_code)
                   end as ref_ts_id,
                   shared_ts_alias_id,
                   case
                     when shared_ts_ref_code is null then null
                     else cwms_ts.get_ts_id(shared_ts_ref_code)
                   end as shared_ref_ts_id,
                   ts_attribute
              from ( select o1.office_id as cat_db_office_id,
                            c.ts_category_id,
                            o2.office_id as grp_db_office_id,
                            g.ts_group_code,
                            g.ts_group_id,
                            g.ts_group_desc,
                            g.shared_ts_alias_id,
                            g.shared_ts_ref_code
                       from at_ts_category c,
                            at_ts_group g,
                            cwms_office o1,
                            cwms_office o2
                      where upper(c.ts_category_id) like cwms_util.normalize_wildcards(nvl(upper(p_ts_category_id), '*'))
                        and upper(g.ts_group_id) like cwms_util.normalize_wildcards(nvl(upper(p_ts_group_id), '*'))
                        and g.db_office_code in (cwms_util.db_office_code_all, l_office_code)
                        and g.ts_category_code = c.ts_category_code
                        and o1.office_code = c.db_office_code
                        and o2.office_code = g.db_office_code
                   ) grp
                   full outer join
                   ( select a.ts_code,
                            a.ts_group_code,
                            a.ts_attribute,
                            a.ts_alias_id,
                            a.ts_ref_code,
                            o.office_id as db_office_id 
                       from at_ts_group_assignment a,
                            at_cwms_ts_id t,
                            cwms_office o
                      where upper(cwms_ts.get_ts_id(a.ts_code)) like cwms_util.normalize_wildcards(nvl(upper(p_ts_id), '*'))
                        and t.ts_code = a.ts_code
                        and o.office_code = t.db_office_code
                   ) assgn on assgn.ts_group_code = grp.ts_group_code;
      end if;      
                         
   end cat_ts_aliases;

   function cat_ts_aliases_tab (
      p_ts_id          in varchar2 default null,
      p_ts_category_id in varchar2 default null,
      p_ts_group_id    in varchar2 default null,
      p_abbreviated    in varchar2 default 'T',
      p_db_office_id   in varchar2 default null
   )  return cat_ts_alias_tab_t pipelined
   is
      output_row   cat_ts_alias_rec_t;
      query_cursor sys_refcursor;
   begin
      cat_ts_aliases (
         query_cursor,
         p_ts_id,
         p_ts_category_id,
         p_ts_group_id,
         p_abbreviated,
         p_db_office_id);

      loop
         fetch query_cursor into output_row;
         exit when query_cursor%notfound;
         pipe row (output_row);
      end loop;

      close query_cursor;
      return;
   end cat_ts_aliases_tab;

   procedure cat_ts_group (
      p_cwms_cat     out sys_refcursor,
      p_db_office_id in  varchar2 default null
   )
   is
      l_office_code number(10);
   begin
      cwms_util.check_input(p_db_office_id);
      l_office_code := cwms_util.get_db_office_code(p_db_office_id);
      open p_cwms_cat for
         select o1.office_id as cat_db_office_id,
                c.ts_category_id,
                c.ts_category_desc,
                o2.office_id as grp_db_office_id,
                g.ts_group_id,
                g.ts_group_desc,
                g.shared_ts_alias_id,
                case
                  when g.shared_ts_ref_code is null then null
                  else cwms_ts.get_ts_id(g.shared_ts_ref_code)
               end as shared_ts_ref_id
           from at_ts_category c,
                at_ts_group g,
                cwms_office o1,
                cwms_office o2
          where g.db_office_code in (cwms_util.db_office_code_all, l_office_code)
            and g.ts_category_code = c.ts_category_code
            and o1.office_code = c.db_office_code
            and o2.office_code = g.db_office_code
       order by o1.office_id,
                upper(c.ts_category_id),
                o2.office_id,
                upper(g.ts_group_id);
   end cat_ts_group;

   function cat_ts_group_tab (p_db_office_id in varchar2 default null)
      return cat_ts_grp_tab_t pipelined
   is
      output_row   cat_ts_grp_rec_t;
      query_cursor sys_refcursor;
   begin
      cat_ts_group (query_cursor, p_db_office_id);

      loop
         fetch query_cursor into output_row;
         exit when query_cursor%notfound;
         pipe row (output_row);
      end loop;

      close query_cursor;
      return;
   end cat_ts_group_tab;
      
   -------------------------------------------------------------------------------
   -- CAT_LOCATION
   --
   -- These procedures and functions catalog locations in the CWMS.
   -- database.
   --
   -- Function returns may be used as source of SELECT statements.
   --
   -- The returned records contain the following columns:
   --
   --    Name                      Datatype      Description
   --    ------------------------ ------------- ----------------------------
   --    db_office_id             varchar2(16)   owning office of location
   --    location_id              varchar2(49)   full location id
   --    base_location_id         varchar2(16)   base location id
   --    sub_location_id          varchar2(32)   sub-location id, if any
   --    state_initial            varchar2(2)    two-character state abbreviation
   --    county_name              varchar2(40)   county name
   --    time_zone_name           varchar2(28)   local time zone name for location
   --    location_type            varchar2(32)   descriptive text of loctaion type
   --    latitude                 number         location latitude
   --    longitude                number         location longitude
   --    horizontal_datum         varchar2(16)   horizontal datrum of lat/lon
   --    elevation                number         location elevation
   --    elev_unit_id             varchar2(16)   location elevation units
   --    vertical_datum           varchar2(16)   veritcal datum of elevation
   --    public_name              varchar2(32)   location public name
   --    long_name                varchar2(80)   location long name
   --    description              varchar2(512)  location description
   --    active_flag              varchar2(1)    'T' if active, else 'F'
   --
   -------------------------------------------------------------------------------
   -- procedure cat_location(...)
   --
   --
   PROCEDURE cat_location (
      p_cwms_cat          OUT      sys_refcursor,
                           p_elevation_unit     IN      VARCHAR2 DEFAULT 'm' ,
                           p_base_loc_only     IN      VARCHAR2 DEFAULT 'F' ,
                           p_loc_category_id   IN      VARCHAR2 DEFAULT NULL ,
                           p_loc_group_id      IN      VARCHAR2 DEFAULT NULL ,
                           p_db_office_id      IN      VARCHAR2 DEFAULT NULL
                          )
   IS
      l_from_id          cwms_unit.unit_id%TYPE := 'm';
      l_to_id            cwms_unit.unit_id%TYPE
                                               := NVL (p_elevation_unit, 'm');
      l_from_code        cwms_unit.unit_code%TYPE;
      l_to_code          cwms_unit.unit_code%TYPE;
      l_factor           cwms_unit_conversion.factor%TYPE;
      l_offset           cwms_unit_conversion.offset%TYPE;
      l_office_id        cwms_office.office_id%TYPE;
      l_db_office_id     cwms_office.office_id%TYPE;
      l_db_office_code    NUMBER;
      l_loc_group_code    NUMBER := NULL;
      l_base_loc_only BOOLEAN
            := cwms_util.return_true_or_false (NVL (p_base_loc_only, 'F')) ;
   BEGIN
      -----------------------------------------------
      -- get the office id of the hosting database --
      -----------------------------------------------
      l_db_office_code := cwms_util.get_db_office_code (p_db_office_id);
      SELECT   office_id
        INTO   l_db_office_id
        FROM   cwms_office
       WHERE   office_code = l_db_office_code;

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
      ELSIF (p_loc_category_id IS NOT NULL AND p_loc_group_id IS NULL) OR (p_loc_category_id IS NULL AND p_loc_group_id IS NOT NULL)
      THEN
         cwms_err.raise (
            'ERROR',
            'The loc_category_id and loc_group_id is not a valid combination'
         );
      END IF;

      ------------------------------------------
      -- get the conversion factor and offset --
      ------------------------------------------
      SELECT   unit_code
        INTO   l_from_code
        FROM   cwms_unit
       WHERE   unit_id = l_from_id;

      SELECT   unit_code
        INTO   l_to_code
        FROM   cwms_unit
       WHERE   unit_id = l_to_id;

      SELECT   factor, offset
        INTO   l_factor, l_offset
        FROM   cwms_unit_conversion
       WHERE   from_unit_code = l_from_code AND to_unit_code = l_to_code;

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
                          || apl.sub_location_id
                             location_id, abl.base_location_id,
                          apl.sub_location_id, cs.state_initial, cc.county_name,
                          ctz.time_zone_name, apl.location_type, apl.latitude,
                          apl.longitude, apl.horizontal_datum,
                          apl.elevation * cuc.factor + cuc.offset elevation,
                          cuc.to_unit_id elev_unit_id, apl.vertical_datum,
                          apl.public_name, apl.long_name, apl.description,
                          apl.active_flag
                   FROM   at_physical_location apl,
                          at_base_location abl,
                          cwms_county cc,
                          cwms_office co,
                          cwms_state cs,
                          cwms_time_zone ctz,
                          cwms_unit_conversion cuc,
                          ---
                          at_loc_group_assignment atlga                     ---
                  WHERE       abl.db_office_code = l_db_office_code
                          AND (cc.county_code = NVL (apl.county_code, 0))
                          AND (cs.state_code = NVL (cc.state_code, 0))
                          AND (abl.db_office_code = co.office_code)
                          AND (ctz.time_zone_code = NVL (apl.time_zone_code, 0))
                          AND apl.base_location_code = abl.base_location_code
                          AND apl.location_code != 0
                          AND cuc.from_unit_id = 'm'
                          AND cuc.to_unit_id = p_elevation_unit
                          ---
                          AND atlga.loc_group_code = l_loc_group_code      ---
                          AND apl.location_code = atlga.location_code      ---
                          AND apl.sub_location_id IS NULL                  ---
               ORDER BY  UPPER(location_id) ASC;
         ELSE
            OPEN p_cwms_cat FOR
                 SELECT   co.office_id db_office_id,
                             abl.base_location_id
                          || SUBSTR ('-', 1, LENGTH (apl.sub_location_id))
                          || apl.sub_location_id
                             location_id, abl.base_location_id,
                          apl.sub_location_id, cs.state_initial, cc.county_name,
                          ctz.time_zone_name, apl.location_type, apl.latitude,
                          apl.longitude, apl.horizontal_datum,
                          apl.elevation * cuc.factor + cuc.offset elevation,
                          cuc.to_unit_id elev_unit_id, apl.vertical_datum,
                          apl.public_name, apl.long_name, apl.description,
                          apl.active_flag
                   FROM   at_physical_location apl,
                          at_base_location abl,
                          cwms_county cc,
                          cwms_office co,
                          cwms_state cs,
                          cwms_time_zone ctz,
                          cwms_unit_conversion cuc,
                          ---
                          at_loc_group_assignment atlga                     ---
                  WHERE       abl.db_office_code = l_db_office_code
                          AND (cc.county_code = NVL (apl.county_code, 0))
                          AND (cs.state_code = NVL (cc.state_code, 0))
                          AND (abl.db_office_code = co.office_code)
                          AND (ctz.time_zone_code = NVL (apl.time_zone_code, 0))
                          AND apl.base_location_code = abl.base_location_code
                          AND apl.location_code != 0
                          AND cuc.from_unit_id = 'm'
                          AND cuc.to_unit_id = p_elevation_unit
                          ---
                          AND atlga.loc_group_code = l_loc_group_code      ---
                          AND apl.location_code = atlga.location_code      ---
               ORDER BY   UPPER(location_id) ASC;
         END IF;
      ELSE
         IF l_base_loc_only
         THEN
            OPEN p_cwms_cat FOR
                 SELECT   co.office_id db_office_id,
                             abl.base_location_id
                          || SUBSTR ('-', 1, LENGTH (apl.sub_location_id))
                          || apl.sub_location_id
                             location_id, abl.base_location_id,
                          apl.sub_location_id, cs.state_initial, cc.county_name,
                          ctz.time_zone_name, apl.location_type, apl.latitude,
                          apl.longitude, apl.horizontal_datum,
                          apl.elevation * cuc.factor + cuc.offset elevation,
                          cuc.to_unit_id elev_unit_id, apl.vertical_datum,
                          apl.public_name, apl.long_name, apl.description,
                          apl.active_flag
                   FROM   at_physical_location apl,
                          at_base_location abl,
                          cwms_county cc,
                          cwms_office co,
                          cwms_state cs,
                          cwms_time_zone ctz,
                          cwms_unit_conversion cuc
                  WHERE       abl.db_office_code = l_db_office_code
                          AND (cc.county_code = NVL (apl.county_code, 0))
                          AND (cs.state_code = NVL (cc.state_code, 0))
                          AND (abl.db_office_code = co.office_code)
                          AND (ctz.time_zone_code = NVL (apl.time_zone_code, 0))
                          AND apl.base_location_code = abl.base_location_code
                          AND apl.location_code != 0
                          AND cuc.from_unit_id = 'm'
                          AND cuc.to_unit_id = p_elevation_unit
                          ---
                          AND apl.sub_location_id IS NULL                  ---
               ORDER BY   UPPER(location_id) ASC;
         ELSE
            OPEN p_cwms_cat FOR
                 SELECT   co.office_id db_office_id,
                             abl.base_location_id
                          || SUBSTR ('-', 1, LENGTH (apl.sub_location_id))
                          || apl.sub_location_id
                             location_id, abl.base_location_id,
                          apl.sub_location_id, cs.state_initial, cc.county_name,
                          ctz.time_zone_name, apl.location_type, apl.latitude,
                          apl.longitude, apl.horizontal_datum,
                          apl.elevation * cuc.factor + cuc.offset elevation,
                          cuc.to_unit_id elev_unit_id, apl.vertical_datum,
                          apl.public_name, apl.long_name, apl.description,
                          apl.active_flag
                   FROM   at_physical_location apl,
                          at_base_location abl,
                          cwms_county cc,
                          cwms_office co,
                          cwms_state cs,
                          cwms_time_zone ctz,
                          cwms_unit_conversion cuc
                  WHERE       abl.db_office_code = l_db_office_code
                          AND (cc.county_code = NVL (apl.county_code, 0))
                          AND (cs.state_code = NVL (cc.state_code, 0))
                          AND (abl.db_office_code = co.office_code)
                          AND (ctz.time_zone_code = NVL (apl.time_zone_code, 0))
                          AND apl.base_location_code = abl.base_location_code
                          AND apl.location_code != 0
                          AND cuc.from_unit_id = 'm'
                          AND cuc.to_unit_id = p_elevation_unit
               ORDER BY   UPPER(location_id) ASC;
         END IF;
      END IF;
   END cat_location;

   FUNCTION cat_location_tab (p_elevation_unit     IN VARCHAR2 DEFAULT 'm' ,
                              p_base_loc_only     IN VARCHAR2 DEFAULT 'F' ,
                              p_loc_category_id   IN VARCHAR2 DEFAULT NULL ,
                              p_loc_group_id      IN VARCHAR2 DEFAULT NULL ,
                              p_db_office_id      IN VARCHAR2 DEFAULT NULL
                             )
      RETURN cat_location_tab_t
      PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row      cat_location_rec_t;
   BEGIN
      cat_location (query_cursor,
                    p_elevation_unit,
                    p_base_loc_only,
                    p_loc_category_id,
                    p_loc_group_id,
                    p_db_office_id
                   );

      LOOP
         FETCH query_cursor INTO   output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;
   END cat_location_tab;
-------------------------------------------------------------------------------
-- CAT_LOCATION2
--
-- These procedures and functions catalog locations in the CWMS.
-- database.
--
-- Function returns may be used as source of SELECT statements.
--
-- The returned records contain the following columns:
--
--    Name                      Datatype      Description
--    ------------------------ ------------- ----------------------------
--    db_office_id             varchar2(16)   owning office of location
--    location_id              varchar2(49)   full location id
--    base_location_id         varchar2(16)   base location id
--    sub_location_id          varchar2(32)   sub-location id, if any
--    state_initial            varchar2(2)    two-character state abbreviation
--    county_name              varchar2(40)   county name
--    time_zone_name           varchar2(28)   local time zone name for location
--    location_type            varchar2(32)   descriptive text of loctaion type
--    latitude                 number         location latitude
--    longitude                number         location longitude
--    horizontal_datum         varchar2(16)   horizontal datrum of lat/lon
--    elevation                number         location elevation
--    elev_unit_id             varchar2(16)   location elevation units
--    vertical_datum           varchar2(16)   veritcal datum of elevation
--    public_name              varchar2(32)   location public name
--    long_name                varchar2(80)   location long name
--    description              varchar2(512)  location description
--    active_flag              varchar2(1)    'T' if active, else 'F'
--    location_kind_id         varchar2(32)   location kind
--    map_label                varchar2(50)   map label for location
--    published_latitude       number         published latitude for location
--    published_longitude      number         published longitude for location
--    bounding_office_id       varchar2(16)   id of office whose area bounds location
--    nation_id                varchar2(48)   nation of location
--    nearest_city             varchar2(50)   nearest city of location
--
-------------------------------------------------------------------------------
-- procedure cat_location2(...)
--
--
   PROCEDURE cat_location2 (
      p_cwms_cat          OUT      sys_refcursor,
      p_elevation_unit    IN       VARCHAR2 DEFAULT 'm',
      p_base_loc_only     IN       VARCHAR2 DEFAULT 'F',
      p_loc_category_id   IN       VARCHAR2 DEFAULT NULL,
      p_loc_group_id      IN       VARCHAR2 DEFAULT NULL,
      p_db_office_id      IN       VARCHAR2 DEFAULT NULL
   )
   IS
      l_from_id          cwms_unit.unit_id%TYPE := 'm';
      l_to_id            cwms_unit.unit_id%TYPE := NVL (p_elevation_unit, 'm');
      l_from_code        cwms_unit.unit_code%TYPE;
      l_to_code          cwms_unit.unit_code%TYPE;
      l_factor           cwms_unit_conversion.factor%TYPE;
      l_offset           cwms_unit_conversion.offset%TYPE;
      l_office_id        cwms_office.office_id%TYPE;
      l_db_office_id     cwms_office.office_id%TYPE;
      l_db_office_code   NUMBER;
      l_loc_group_code   NUMBER := NULL;
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
            open p_cwms_cat for
               select db_office_id,
                      location_id,
                      base_location_id,
                      sub_location_id,
                      state_initial,
                      county_name,
                      time_zone_name,
                      location_type,
                      latitude,
                      longitude,
                      horizontal_datum,
                      elevation,
                      elev_unit_id,
                      vertical_datum,
                      public_name,
                      long_name,
                      description,
                      active_flag,
                      location_kind_id,
                      map_label,
                      published_latitude,
                      published_longitude,
                      bounding_office_id,
                      nation_id,
                      nearest_city
                 from ( select co.office_id as db_office_id,
                               abl.base_location_id
                               || substr ('-', 1, length (apl.sub_location_id))
                               || apl.sub_location_id as location_id,
                               abl.base_location_id,
                               apl.sub_location_id,
                               cs.state_initial,
                               cc.county_name,
                               ctz.time_zone_name,
                               apl.location_type,
                               apl.latitude,
                               apl.longitude,
                               apl.horizontal_datum,
                               apl.elevation * cuc.factor + cuc.offset as elevation,
                               cuc.to_unit_id as elev_unit_id,
                               apl.vertical_datum,
                               apl.public_name,
                               apl.long_name,
                               apl.description,
                               apl.active_flag,
                               alk.location_kind_id,
                               apl.map_label,
                               apl.published_latitude,
                               apl.published_longitude,
                               apl.office_code as bounding_office_code,
                               apl.nation_code,
                               apl.nearest_city
                          from at_physical_location apl,
                               at_base_location abl,
                               cwms_county cc,
                               cwms_office co,
                               cwms_state cs,
                               cwms_time_zone ctz,
                               cwms_unit_conversion cuc,
                               at_location_kind alk,
                               at_loc_group_assignment atlga
                         where abl.db_office_code = l_db_office_code
                           and (cc.county_code = nvl (apl.county_code, 0))
                           and (cs.state_code = nvl (cc.state_code, 0))
                           and (abl.db_office_code = co.office_code)
                           and (ctz.time_zone_code = nvl (apl.time_zone_code, 0))
                           and apl.base_location_code = abl.base_location_code
                           and apl.location_code != 0
                           and cuc.from_unit_id = 'm'
                           and cuc.to_unit_id = p_elevation_unit
                           and alk.location_kind_code = apl.location_kind
                           and atlga.loc_group_code = l_loc_group_code
                           and apl.location_code = atlga.location_code
                           and apl.sub_location_id is null
                      ) loc
                      left outer join
                      ( select office_code,
                               office_id as bounding_office_id
                          from cwms_office
                      ) ofc on ofc.office_code = loc.bounding_office_code
                      left outer join
                      ( select nation_code,
                               nation_id
                          from cwms_nation
                      ) nat on nat.nation_code = loc.nation_code
             order by location_id asc;
         ELSE
            open p_cwms_cat for
               select db_office_id,
                      location_id,
                      base_location_id,
                      sub_location_id,
                      state_initial,
                      county_name,
                      time_zone_name,
                      location_type,
                      latitude,
                      longitude,
                      horizontal_datum,
                      elevation,
                      elev_unit_id,
                      vertical_datum,
                      public_name,
                      long_name,
                      description,
                      active_flag,
                      location_kind_id,
                      map_label,
                      published_latitude,
                      published_longitude,
                      bounding_office_id,
                      nation_id,
                      nearest_city
                 from ( select co.office_id as db_office_id,
                               abl.base_location_id
                               || substr ('-', 1, length (apl.sub_location_id))
                               || apl.sub_location_id as location_id,
                               abl.base_location_id,
                               apl.sub_location_id,
                               cs.state_initial,
                               cc.county_name,
                               ctz.time_zone_name,
                               apl.location_type,
                               apl.latitude,
                               apl.longitude,
                               apl.horizontal_datum,
                               apl.elevation * cuc.factor + cuc.offset as elevation,
                               cuc.to_unit_id as elev_unit_id,
                               apl.vertical_datum,
                               apl.public_name,
                               apl.long_name,
                               apl.description,
                               apl.active_flag,
                               alk.location_kind_id,
                               apl.map_label,
                               apl.published_latitude,
                               apl.published_longitude,
                               apl.office_code as bounding_office_code,
                               apl.nation_code,
                               apl.nearest_city
                          from at_physical_location apl,
                               at_base_location abl,
                               cwms_county cc,
                               cwms_office co,
                               cwms_state cs,
                               cwms_time_zone ctz,
                               cwms_unit_conversion cuc,
                               at_location_kind alk,
                               at_loc_group_assignment atlga
                         where abl.db_office_code = l_db_office_code
                           and (cc.county_code = nvl (apl.county_code, 0))
                           and (cs.state_code = nvl (cc.state_code, 0))
                           and (abl.db_office_code = co.office_code)
                           and (ctz.time_zone_code = nvl (apl.time_zone_code, 0))
                           and apl.base_location_code = abl.base_location_code
                           and apl.location_code != 0
                           and cuc.from_unit_id = 'm'
                           and cuc.to_unit_id = p_elevation_unit
                           and alk.location_kind_code = apl.location_kind
                           and atlga.loc_group_code = l_loc_group_code
                           and apl.location_code = atlga.location_code
                      ) loc
                      left outer join
                      ( select office_code,
                               office_id as bounding_office_id
                          from cwms_office
                      ) ofc on ofc.office_code = loc.bounding_office_code
                      left outer join
                      ( select nation_code,
                               nation_id
                          from cwms_nation
                      ) nat on nat.nation_code = loc.nation_code
             order by location_id asc;
         END IF;
      ELSE
         IF l_base_loc_only
         THEN
            open p_cwms_cat for
               select db_office_id,
                      location_id,
                      base_location_id,
                      sub_location_id,
                      state_initial,
                      county_name,
                      time_zone_name,
                      location_type,
                      latitude,
                      longitude,
                      horizontal_datum,
                      elevation,
                      elev_unit_id,
                      vertical_datum,
                      public_name,
                      long_name,
                      description,
                      active_flag,
                      location_kind_id,
                      map_label,
                      published_latitude,
                      published_longitude,
                      bounding_office_id,
                      nation_id,
                      nearest_city
                 from ( select co.office_id as db_office_id,
                               abl.base_location_id
                               || substr ('-', 1, length (apl.sub_location_id))
                               || apl.sub_location_id as location_id,
                               abl.base_location_id,
                               apl.sub_location_id,
                               cs.state_initial,
                               cc.county_name,
                               ctz.time_zone_name,
                               apl.location_type,
                               apl.latitude,
                               apl.longitude,
                               apl.horizontal_datum,
                               apl.elevation * cuc.factor + cuc.offset as elevation,
                               cuc.to_unit_id as elev_unit_id,
                               apl.vertical_datum,
                               apl.public_name,
                               apl.long_name,
                               apl.description,
                               apl.active_flag,
                               alk.location_kind_id,
                               apl.map_label,
                               apl.published_latitude,
                               apl.published_longitude,
                               apl.office_code as bounding_office_code,
                               apl.nation_code,
                               apl.nearest_city
                          from at_physical_location apl,
                               at_base_location abl,
                               cwms_county cc,
                               cwms_office co,
                               cwms_state cs,
                               cwms_time_zone ctz,
                               cwms_unit_conversion cuc,
                               at_location_kind alk
                         where abl.db_office_code = l_db_office_code
                           and (cc.county_code = nvl (apl.county_code, 0))
                           and (cs.state_code = nvl (cc.state_code, 0))
                           and (abl.db_office_code = co.office_code)
                           and (ctz.time_zone_code = nvl (apl.time_zone_code, 0))
                           and apl.base_location_code = abl.base_location_code
                           and apl.location_code != 0
                           and cuc.from_unit_id = 'm'
                           and cuc.to_unit_id = p_elevation_unit
                           and alk.location_kind_code = apl.location_kind
                           and apl.sub_location_id is null
                      ) loc
                      left outer join
                      ( select office_code,
                               office_id as bounding_office_id
                          from cwms_office
                      ) ofc on ofc.office_code = loc.bounding_office_code
                      left outer join
                      ( select nation_code,
                               nation_id
                          from cwms_nation
                      ) nat on nat.nation_code = loc.nation_code
             order by location_id asc;
         ELSE
            open p_cwms_cat for
               select db_office_id,
                      location_id,
                      base_location_id,
                      sub_location_id,
                      state_initial,
                      county_name,
                      time_zone_name,
                      location_type,
                      latitude,
                      longitude,
                      horizontal_datum,
                      elevation,
                      elev_unit_id,
                      vertical_datum,
                      public_name,
                      long_name,
                      description,
                      active_flag,
                      location_kind_id,
                      map_label,
                      published_latitude,
                      published_longitude,
                      bounding_office_id,
                      nation_id,
                      nearest_city
                 from ( select co.office_id as db_office_id,
                               abl.base_location_id
                               || substr ('-', 1, length (apl.sub_location_id))
                               || apl.sub_location_id as location_id,
                               abl.base_location_id,
                               apl.sub_location_id,
                               cs.state_initial,
                               cc.county_name,
                               ctz.time_zone_name,
                               apl.location_type,
                               apl.latitude,
                               apl.longitude,
                               apl.horizontal_datum,
                               apl.elevation * cuc.factor + cuc.offset as elevation,
                               cuc.to_unit_id as elev_unit_id,
                               apl.vertical_datum,
                               apl.public_name,
                               apl.long_name,
                               apl.description,
                               apl.active_flag,
                               alk.location_kind_id,
                               apl.map_label,
                               apl.published_latitude,
                               apl.published_longitude,
                               apl.office_code as bounding_office_code,
                               apl.nation_code,
                               apl.nearest_city
                          from at_physical_location apl,
                               at_base_location abl,
                               cwms_county cc,
                               cwms_office co,
                               cwms_state cs,
                               cwms_time_zone ctz,
                               cwms_unit_conversion cuc,
                               at_location_kind alk
                         where abl.db_office_code = l_db_office_code
                           and (cc.county_code = nvl (apl.county_code, 0))
                           and (cs.state_code = nvl (cc.state_code, 0))
                           and (abl.db_office_code = co.office_code)
                           and (ctz.time_zone_code = nvl (apl.time_zone_code, 0))
                           and apl.base_location_code = abl.base_location_code
                           and apl.location_code != 0
                           and cuc.from_unit_id = 'm'
                           and cuc.to_unit_id = p_elevation_unit
                           and alk.location_kind_code = apl.location_kind
                      ) loc
                      left outer join
                      ( select office_code,
                               office_id as bounding_office_id
                          from cwms_office
                      ) ofc on ofc.office_code = loc.bounding_office_code
                      left outer join
                      ( select nation_code,
                               nation_id
                          from cwms_nation
                      ) nat on nat.nation_code = loc.nation_code
             order by location_id asc;
         END IF;
      END IF;
   END cat_location2;

-------------------------------------------------------------------------------
-- function cat_location2(...)
--
--
   FUNCTION cat_location2_tab (
      p_elevation_unit    IN   VARCHAR2 DEFAULT 'm',
      p_base_loc_only     IN   VARCHAR2 DEFAULT 'F',
      p_loc_category_id   IN   VARCHAR2 DEFAULT NULL,
      p_loc_group_id      IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   )
      RETURN cat_location2_tab_t PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row     cat_location2_rec_t;
   BEGIN
      cat_location2 (query_cursor,
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
   END cat_location2_tab;

-------------------------------------------------------------------------------
-- CAT_LOCATION_KIND
--
-- These procedures and functions catalog location kinds in the CWMS.
-- database.
--
-- Function returns may be used as source of SELECT statements.
--
-- The returned records contain the following columns:
--
--    Name              Datatype      Description
--    ------------------------------ --------------------------------
--    office_id        varchar2(16)   owning office of location kind
--    location_kind_id varchar2(32)   location kind id
--    description      varchar2(256)  description of location kind
--
-------------------------------------------------------------------------------
-- procedure cat_location_kind(...)
--
--
   PROCEDURE cat_location_kind (
      p_cwms_cat              out sys_refcursor,
      p_location_kind_id_mask in  varchar2 default null,
      p_office_id_mask        in  varchar2 default null
   )
   is
      l_location_kind_id_mask varchar2(32);
      l_office_id_mask        varchar2(16);
   begin
      l_location_kind_id_mask := cwms_util.normalize_wildcards(
         upper(nvl(p_location_kind_id_mask, '*')), true);
      l_office_id_mask        := cwms_util.normalize_wildcards(
         upper(nvl(p_office_id_mask, cwms_util.user_office_id)), true);
      open p_cwms_cat for 
         select o.office_id,
                k.location_kind_id,
                k.description
           from cwms_office o,
                at_location_kind k
          where k.location_kind_id like l_location_kind_id_mask escape '\'
            and (o.office_id like l_office_id_mask escape '\' or o.office_id = 'CWMS')
            and o.office_code = k.office_code
       order by o.office_id,
                k.location_kind_id;
   end cat_location_kind;

-------------------------------------------------------------------------------
-- function cat_location_kind_tab(...)
--
--
   FUNCTION cat_location_kind_tab (
      p_location_kind_id_mask in  varchar2 default null,
      p_office_id_mask        in  varchar2 default null
   )
      RETURN cat_location_kind_tab_t PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row     cat_location_kind_rec_t;
   BEGIN
      cat_location_kind (
         query_cursor,
         p_location_kind_id_mask,
         p_office_id_mask);

      LOOP
         FETCH query_cursor
          INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   end cat_location_kind_tab;

   --------------------------------------------------------------------------------
   -- DEPRICATED --
   -- DEPRICATED -- cat_loc USE cat_location --
   -- DEPRICATED --
   PROCEDURE cat_loc (
      p_cwms_cat         OUT      sys_refcursor,
                      p_office_id        IN      VARCHAR2 DEFAULT NULL ,
                      p_elevation_unit   IN      VARCHAR2 DEFAULT 'm'
                     )
   -- DEPRICATED --
   -- DEPRICATED --
   -- DEPRICATED --
   --------------------------------------------------------------------------------
   IS
      l_from_id        cwms_unit.unit_id%TYPE := 'm';
      l_to_id           cwms_unit.unit_id%TYPE := NVL (p_elevation_unit, 'm');
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
      IF p_office_id IS NULL
      THEN
         l_office_id := cwms_util.user_office_id;
      ELSE
         l_office_id := p_office_id;
      END IF;

      SELECT   o2.office_id
        INTO   l_db_office_id
        FROM   cwms_office o1, cwms_office o2
       WHERE   o1.office_id = l_office_id
               AND o2.office_code = o1.db_host_office_code;

      ------------------------------------------
      -- get the conversion factor and offset --
      ------------------------------------------
      SELECT   unit_code
        INTO   l_from_code
        FROM   cwms_unit
       WHERE   unit_id = l_from_id;

      SELECT   unit_code
        INTO   l_to_code
        FROM   cwms_unit
       WHERE   unit_id = l_to_id;

      SELECT   factor, offset
        INTO   l_factor, l_offset
        FROM   cwms_unit_conversion
       WHERE   from_unit_code = l_from_code AND to_unit_code = l_to_code;

      ----------------------
      -- open the cursor  --
      ----------------------
      OPEN p_cwms_cat FOR
           SELECT   db_office_id, base_location_id, state_initial, county_name,
                    time_zone_name, location_type, latitude, longitude,
                    elevation * l_factor + l_offset AS elevation,
                    l_to_id AS elev_unit_id, vertical_datum, public_name,
                    long_name, description
             FROM   av_loc alv
            WHERE   db_office_id = UPPER (l_db_office_id)
         ORDER BY   db_office_id ASC, base_location_id ASC;
   END cat_loc;

   -------------------------------------------------------------------------------
   -- DEPRICATED --
   -- DEPRICATED --function cat_loc_tab USE cat_location_tab --
   -- DEPRICATED --
   FUNCTION cat_loc_tab (p_office_id        IN VARCHAR2 DEFAULT NULL ,
                         p_elevation_unit   IN VARCHAR2 DEFAULT 'm'
                        )
      RETURN cat_loc_tab_t
      PIPELINED
   -- DEPRICATED --
   -- DEPRICATED --
   -- DEPRICATED --
   --------------------------------------------------------------------------------
   IS
      query_cursor   sys_refcursor;
      output_row      cat_loc_rec_t;
   BEGIN
      cat_loc (query_cursor, p_office_id, p_elevation_unit);

      LOOP
         FETCH query_cursor INTO   output_row;

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
   PROCEDURE cat_loc_alias (p_cwms_cat          OUT sys_refcursor,
                            p_cwms_ts_id      IN     VARCHAR2 DEFAULT NULL ,
                            p_db_office_id   IN     VARCHAR2 DEFAULT NULL
                           )
   IS
      l_db_office_id VARCHAR2 (16)
            := cwms_util.get_db_office_id (p_db_office_id) ;
      l_location_code   NUMBER;
   BEGIN
      IF p_cwms_ts_id IS NULL
      THEN
         ---------------------------
         -- only office specified --
         ---------------------------
         OPEN p_cwms_cat FOR
              SELECT   a.db_office_id, a.location_id, a.GROUP_ID agency_id,
                       a.alias_id
                FROM   av_loc_alias a
               WHERE   category_id = 'Agency Alias'
                       AND db_office_id = l_db_office_id
            ORDER BY   UPPER (a.location_id),
                       UPPER (a.GROUP_ID),
                       UPPER (a.alias_id);
      ELSE
         ----------------------------------------
         -- both office and location specified --
         ----------------------------------------
         l_location_code :=
            cwms_loc.get_location_code (
               p_db_office_id   => l_db_office_id,
               p_location_id     => cwms_ts.get_location_id (
                                     p_cwms_ts_id      => p_cwms_ts_id,
                                     p_db_office_id   => l_db_office_id
                                  )
            );

         OPEN p_cwms_cat FOR
              SELECT   a.db_office_id, a.location_id, a.GROUP_ID agency_id,
                       a.alias_id
                FROM   av_loc_alias a
               WHERE   category_id = 'Agency Alias'
                       AND a.location_code = l_location_code
            ORDER BY   UPPER (a.location_id),
                       UPPER (a.GROUP_ID),
                       UPPER (a.alias_id);
      END IF;
   END cat_loc_alias;

   -------------------------------------------------------------------------------
   -- function cat_loc_alias_tab(...)
   --
   --
   FUNCTION cat_loc_aliases_tab (
      p_location_id       IN VARCHAR2 DEFAULT NULL ,
      p_loc_category_id   IN VARCHAR2 DEFAULT NULL ,
      p_loc_group_id      IN VARCHAR2 DEFAULT NULL ,
      p_abbreviated       IN VARCHAR2 default 'T' ,
      p_db_office_id      IN VARCHAR2 DEFAULT NULL
   )
      RETURN cat_loc_alias_tab_t
      PIPELINED
   IS
      output_row      cat_loc_alias_rec_t;
      query_cursor   sys_refcursor;
   BEGIN
      cat_loc_aliases (query_cursor,
                       p_location_id,
                       p_loc_category_id,
                       p_loc_group_id,
                       p_abbreviated,
                       p_db_office_id
                      );

      LOOP
         FETCH query_cursor INTO   output_row;

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
             FROM   cwms_base_parameter cp, cwms_unit cu
            WHERE   cp.unit_code = cu.unit_code
         ORDER BY   cp.base_parameter_id ASC;
   END cat_param;

   -------------------------------------------------------------------------------
   -- function cat_param_tab(...)
   --
   --
   FUNCTION cat_param_tab
      RETURN cat_param_tab_t
      PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row      cat_param_rec_t;
   BEGIN
      cat_param (query_cursor);

      LOOP
         FETCH query_cursor INTO   output_row;

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
             FROM   cwms_base_parameter cp, cwms_unit cu
            WHERE   cp.unit_code = cu.unit_code
         ORDER BY   cp.base_parameter_id ASC;
   END cat_base_parameter;

   -------------------------------------------------------------------------------
   FUNCTION cat_base_parameter_tab
      RETURN cat_base_param_tab_t
      PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row      cat_base_param_rec_t;
   BEGIN
      cat_base_parameter (query_cursor);

      LOOP
         FETCH query_cursor INTO   output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_base_parameter_tab;

   PROCEDURE cat_parameter (p_cwms_cat          OUT sys_refcursor,
                            p_db_office_id   IN     VARCHAR2 DEFAULT NULL
                           )
   IS
      l_db_office_code NUMBER
            := cwms_util.get_db_office_code (p_db_office_id) ;
   BEGIN
      OPEN p_cwms_cat FOR
           SELECT      cp.base_parameter_id
                    || SUBSTR ('-', 1, LENGTH (atp.sub_parameter_id))
                    || atp.sub_parameter_id
                       parameter_id, cp.base_parameter_id, atp.sub_parameter_id,
                    CASE
                       WHEN atp.sub_parameter_desc IS NULL THEN cp.description
                       ELSE atp.sub_parameter_desc
                    END
                       sub_parameter_desc, co.office_id db_office_id,
                    cu.unit_id db_unit_id, cu.long_name unit_long_name,
                    cu.description unit_description
             FROM   at_parameter atp,
                    cwms_base_parameter cp,
                    cwms_unit cu,
                    cwms_office co
            WHERE       atp.base_parameter_code = cp.base_parameter_code
                    AND cp.unit_code = cu.unit_code
                    AND co.office_code = atp.db_office_code
                    AND atp.db_office_code IN
                             (cwms_util.db_office_code_all, l_db_office_code)
         ORDER BY   cp.base_parameter_id ASC;
   END cat_parameter;

   FUNCTION cat_parameter_tab (p_db_office_id IN VARCHAR2 DEFAULT NULL )
      RETURN cat_parameter_tab_t
      PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row      cat_parameter_rec_t;
   BEGIN
      cat_parameter (query_cursor, p_db_office_id);

      LOOP
         FETCH query_cursor INTO   output_row;

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
             FROM   at_parameter cs, cwms_base_parameter cp
            WHERE   cp.base_parameter_code(+) = cs.base_parameter_code
         ORDER BY   cp.base_parameter_id ASC, cs.sub_parameter_id ASC;
   END cat_sub_param;

   -------------------------------------------------------------------------------
   -- function cat_sub_param_tab(...)
   --
   --
   FUNCTION cat_sub_param_tab
      RETURN cat_sub_param_tab_t
      PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row      cat_sub_param_rec_t;
   BEGIN
      cat_sub_param (query_cursor);

      LOOP
         FETCH query_cursor INTO   output_row;

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
   PROCEDURE cat_sub_loc (p_cwms_cat       OUT sys_refcursor,
                          p_office_id    IN     VARCHAR2 DEFAULT NULL
                         )
   IS
      l_office_id     VARCHAR2 (16);
      l_office_code    NUMBER;
   BEGIN
      IF p_office_id IS NULL
      THEN
         l_office_id := cwms_util.user_office_id;
      ELSE
         l_office_id := UPPER (p_office_id);
      END IF;

      l_office_code := cwms_util.get_db_office_code (l_office_id);

      OPEN p_cwms_cat FOR
           SELECT   sub_location_id, description
             FROM   (SELECT   DISTINCT apl.sub_location_id, apl.description
                       FROM   at_physical_location apl, at_base_location abl
                      WHERE   apl.base_location_code = abl.base_location_code
                              AND abl.db_office_code = l_office_code)
         ORDER BY   UPPER (sub_location_id);
   END cat_sub_loc;

   -------------------------------------------------------------------------------
   -- function cat_sub_loc_tab(...)
   --
   --
   FUNCTION cat_sub_loc_tab (p_office_id IN VARCHAR2 DEFAULT NULL )
      RETURN cat_sub_loc_tab_t
      PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row      cat_sub_loc_rec_t;
   BEGIN
      cat_sub_loc (query_cursor, p_office_id);

      --
      LOOP
         FETCH query_cursor INTO   output_row;

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
   -- procedure cat_parameter_type(...)
   --
   --
   PROCEDURE cat_parameter_type (p_cwms_cat OUT sys_refcursor)
   IS
   BEGIN
      OPEN p_cwms_cat FOR
           SELECT   parameter_type_id, description
             FROM   cwms_parameter_type
            WHERE   parameter_type_code != 0
         ORDER BY   parameter_type_code ASC;
   END cat_parameter_type;

   -------------------------------------------------------------------------------
   -- function cat_parameter_type_tab(...)
   --
   --
   FUNCTION cat_parameter_type_tab
      RETURN cat_parameter_type_tab_t
      PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row      cat_parameter_type_rec_t;
   BEGIN
      cat_parameter_type (query_cursor);

      LOOP
         FETCH query_cursor INTO   output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_parameter_type_tab;

   -------------------------------------------------------------------------------
   -- procedure cat_interval(...)
   --
   --
   PROCEDURE cat_interval (p_cwms_cat OUT sys_refcursor)
   IS
   BEGIN
      OPEN p_cwms_cat FOR
           SELECT   ci.interval_id, ci.interval, ci.description
             FROM   cwms_interval ci
            WHERE   ci.interval_code != 0
         ORDER BY   ci.interval ASC;
   END cat_interval;

   -------------------------------------------------------------------------------
   -- function cat_interval_tab(...)
   --
   --
   FUNCTION cat_interval_tab
      RETURN cat_interval_tab_t
      PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row      cat_interval_rec_t;
   BEGIN
      cat_interval (query_cursor);

      LOOP
         FETCH query_cursor INTO   output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_interval_tab;

   -------------------------------------------------------------------------------
   -- procedure cat_duration(...)
   --
   --
   PROCEDURE cat_duration (p_cwms_cat OUT sys_refcursor)
   IS
   BEGIN
      OPEN p_cwms_cat FOR
           SELECT   duration_id, duration, description
             FROM   cwms_duration
            WHERE   duration_code != 0
         ORDER BY   duration, duration_id ASC;
   END cat_duration;

   -------------------------------------------------------------------------------
   -- function cat_duration_tab(...)
   --
   --
   FUNCTION cat_duration_tab
      RETURN cat_duration_tab_t
      PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row      cat_duration_rec_t;
   BEGIN
      cat_duration (query_cursor);

      LOOP
         FETCH query_cursor INTO   output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_duration_tab;

   -------------------------------------------------------------------------------
   -- procedure cat_state(...)
   --
   --
   PROCEDURE cat_state (p_cwms_cat OUT sys_refcursor)
   IS
   BEGIN
      OPEN p_cwms_cat FOR
           SELECT   state_initial, name "STATE_NAME"
             FROM   cwms_state
         ORDER BY   state_initial ASC;
   END cat_state;

   -------------------------------------------------------------------------------
   -- function cat_state_tab(...)
   --
   --
   FUNCTION cat_state_tab
      RETURN cat_state_tab_t
      PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row      cat_state_rec_t;
   BEGIN
      cat_state (query_cursor);

      LOOP
         FETCH query_cursor INTO   output_row;

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
   PROCEDURE cat_county (p_cwms_cat      OUT sys_refcursor,
                         p_stateint   IN      VARCHAR2 DEFAULT NULL
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
                FROM   cwms_county cc, cwms_state cs
               WHERE   cs.state_code = cc.state_code
            ORDER BY   state_initial ASC, county_id ASC;
      ELSE
         ------------------------
         -- state is specified --
         ------------------------
         OPEN p_cwms_cat FOR
              SELECT   county_id, county_name, state_initial
                FROM   cwms_county cc, cwms_state cs
               WHERE   cs.state_code = cc.state_code
                       AND state_initial = UPPER (p_stateint)
            ORDER BY   state_initial ASC, county_id ASC;
      END IF;
   END cat_county;

   -------------------------------------------------------------------------------
   -- function cat_county_tab(...)
   --
   --
   FUNCTION cat_county_tab (p_stateint IN VARCHAR2 DEFAULT NULL )
      RETURN cat_county_tab_t
      PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row      cat_county_rec_t;
   BEGIN
      cat_county (query_cursor, p_stateint);

      LOOP
         FETCH query_cursor INTO   output_row;

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
             FROM   cwms_time_zone
         ORDER BY   time_zone_name ASC;
   END cat_timezone;

   -------------------------------------------------------------------------------
   -- function cat_timezone_tab(...)
   --
   --
   FUNCTION cat_timezone_tab
      RETURN cat_timezone_tab_t
      PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row      cat_timezone_rec_t;
   BEGIN
      cat_timezone (query_cursor);

      LOOP
         FETCH query_cursor INTO   output_row;

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
   PROCEDURE cat_dss_file (p_cwms_cat          OUT sys_refcursor,
                           p_filemgr_url    IN     VARCHAR2 DEFAULT NULL ,
                           p_file_name     IN     VARCHAR2 DEFAULT NULL ,
                           p_office_id     IN     VARCHAR2 DEFAULT NULL
                          )
   IS
      l_filemgr_url VARCHAR2 (256)
            := cwms_util.normalize_wildcards (NVL (p_filemgr_url, '*')) ;
      l_file_name VARCHAR2 (256)
            := cwms_util.normalize_wildcards (NVL (p_file_name, '*')) ;
      l_office_id VARCHAR2 (16)
            := cwms_util.normalize_wildcards (
                  NVL (p_office_id, cwms_util.user_office_id)
               ) ;
   BEGIN
      OPEN p_cwms_cat FOR
           SELECT   o.office_id, x.dss_filemgr_url, x.dss_file_name
             FROM   at_xchg_datastore_dss x, cwms_office o
            WHERE       x.dss_filemgr_url LIKE l_filemgr_url ESCAPE '\'
                    AND x.dss_file_name LIKE l_file_name ESCAPE '\'
                    AND x.office_code = o.office_code
                    AND o.office_id LIKE l_office_id ESCAPE '\'
         ORDER BY   o.office_id, dss_filemgr_url, dss_file_name;
   END cat_dss_file;

   -------------------------------------------------------------------------------
   -- function cat_dss_file_tab(...)
   --
   --
   FUNCTION cat_dss_file_tab (p_filemgr_url    IN VARCHAR2 DEFAULT NULL ,
                              p_file_name     IN VARCHAR2 DEFAULT NULL ,
                              p_office_id     IN VARCHAR2 DEFAULT NULL
                             )
      RETURN cat_dss_file_tab_t
      PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row      cat_dss_file_rec_t;
   BEGIN
      cat_dss_file (query_cursor, p_filemgr_url, p_file_name, p_office_id);

      LOOP
         FETCH query_cursor INTO   output_row;

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
   PROCEDURE cat_dss_xchg_set (p_cwms_cat         OUT sys_refcursor,
                               p_office_id     IN      VARCHAR2 DEFAULT NULL ,
                               p_filemgr_url   IN      VARCHAR2 DEFAULT NULL ,
                               p_file_name     IN      VARCHAR2 DEFAULT NULL
                              )
   IS
      l_office_id VARCHAR2 (16)
            := cwms_util.normalize_wildcards (
                  NVL (p_office_id, cwms_util.user_office_id)
               ) ;
      l_filemgr_url VARCHAR2 (256)
            := cwms_util.normalize_wildcards (NVL (p_filemgr_url, '*')) ;
      l_file_name VARCHAR2 (256)
            := cwms_util.normalize_wildcards (NVL (p_file_name, '*')) ;
   BEGIN
      OPEN p_cwms_cat FOR
           SELECT   o.office_id, s.xchg_set_id, s.description,
                    d.dss_filemgr_url, d.dss_file_name,
                    CASE NVL (s.realtime, -1)
                       WHEN -1
                       THEN
                          NULL
                       ELSE
                          (SELECT   dss_xchg_direction_id
                             FROM   cwms_dss_xchg_direction
                            WHERE   dss_xchg_direction_code = s.realtime)
                    END
                       AS realtime
             FROM   at_xchg_set s, at_xchg_datastore_dss d, cwms_office o
            WHERE       d.dss_filemgr_url LIKE l_filemgr_url ESCAPE '\'
                    AND d.dss_file_name LIKE l_file_name ESCAPE '\'
                    AND d.office_code = o.office_code
                    AND o.office_id LIKE l_office_id ESCAPE '\'
                    AND s.datastore_code = d.datastore_code
         ORDER BY   o.office_id, s.xchg_set_id;
   END cat_dss_xchg_set;

   -------------------------------------------------------------------------------
   -- function cat_dss_xchg_set_tab(...)
   --
   --
   FUNCTION cat_dss_xchg_set_tab (p_office_id     IN VARCHAR2 DEFAULT NULL ,
                                  p_filemgr_url   IN VARCHAR2 DEFAULT NULL ,
                                  p_file_name     IN VARCHAR2 DEFAULT NULL
                                 )
      RETURN cat_dss_xchg_set_tab_t
      PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row      cat_dss_xchg_set_rec_t;
   BEGIN
      cat_dss_xchg_set (query_cursor,
                        p_office_id,
                        p_filemgr_url,
                        p_file_name
                       );

      LOOP
         FETCH query_cursor INTO   output_row;

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
   PROCEDURE cat_dss_xchg_ts_map (p_cwms_cat         OUT sys_refcursor,
                                  p_office_id     IN      VARCHAR2,
                                  p_xchg_set_id   IN      VARCHAR2
                                 )
   IS
      l_office_id VARCHAR2 (16)
            := cwms_util.normalize_wildcards (
                  NVL (p_office_id, cwms_util.user_office_id)
               ) ;
      l_xchg_set_id VARCHAR2 (256)
            := cwms_util.normalize_wildcards (NVL (p_xchg_set_id, '*')) ;
   BEGIN
      OPEN p_cwms_cat FOR
           SELECT   o.office_id, tspec.cwms_ts_id,
                       '/'
                    || NVL (xmap.a_pathname_part, '')
                    || '/'
                    || NVL (xmap.b_pathname_part, '')
                    || '/'
                    || NVL (xmap.c_pathname_part, '')
                    || '//'
                    || NVL (xmap.e_pathname_part, '')
                    || '/'
                    || NVL (xmap.f_pathname_part, '')
                    || '/', ptype.dss_parameter_type_id, xmap.unit_id,
                    tzone.time_zone_name AS dss_timezone_name,
                    tzuse.tz_usage_id AS dss_tz_usage_id
             FROM   at_xchg_set xset,
                    at_xchg_dss_ts_mappings xmap,
                    mv_cwms_ts_id tspec,
                    cwms_office o,
                    cwms_dss_parameter_type ptype,
                    cwms_time_zone tzone,
                    cwms_tz_usage tzuse
            WHERE   UPPER (o.office_id) LIKE UPPER (l_office_id) ESCAPE '\'
                    AND xset.office_code = o.office_code
                    AND UPPER (xset.xchg_set_id) LIKE
                          UPPER (l_xchg_set_id) ESCAPE '\'
                    AND xmap.xchg_set_code = xset.xchg_set_code
                    AND tspec.ts_code = xmap.cwms_ts_code
                    AND ptype.dss_parameter_type_code =
                          xmap.dss_parameter_type_code
                    AND tzone.time_zone_code = xmap.time_zone_code
                    AND tzuse.tz_usage_code = xmap.tz_usage_code
         ORDER BY   o.office_id, tspec.cwms_ts_id;
   END cat_dss_xchg_ts_map;

   -------------------------------------------------------------------------------
   -- function cat_dss_xchg_ts_map_tab(...)
   --
   --
   FUNCTION cat_dss_xchg_ts_map_tab (p_office_id         IN VARCHAR2,
                                     p_dss_xchg_set_id   IN VARCHAR2
                                    )
      RETURN cat_dss_xchg_ts_map_tab_t
      PIPELINED
   IS
      query_cursor   sys_refcursor;
      output_row      cat_dss_xchg_ts_map_rec_t;
   BEGIN
      cat_dss_xchg_ts_map (query_cursor, p_office_id, p_dss_xchg_set_id);

      LOOP
         FETCH query_cursor INTO   output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_dss_xchg_ts_map_tab;

   -------------------------------------------------------------------------------
   -- function cat_loc_alias_abbrev_tab(...)
   --
   --
   FUNCTION cat_loc_alias_abbrev_tab (
      p_location_id   IN VARCHAR2 DEFAULT NULL ,
      p_agency_id     IN VARCHAR2 DEFAULT NULL ,
      p_office_id     IN VARCHAR2 DEFAULT NULL
   )
      RETURN cat_loc_alias_abbrev_tab_t
      PIPELINED
   IS
      output_row      cat_loc_alias_abbrev_rec_t;
      query_cursor   sys_refcursor;
   BEGIN
      cat_loc_aliases (query_cursor,
                       p_location_id,
                       p_agency_id,
                       'T',
                       p_office_id
                      );

      LOOP
         FETCH query_cursor INTO   output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_loc_alias_abbrev_tab;

   -------------------------------------------------------------------------------
   -- procedure cat_loc_alias(...)
   --
   --
   PROCEDURE cat_loc_aliases_java (
      p_cwms_cat          OUT sys_refcursor,
      p_location_id       IN      VARCHAR2 DEFAULT NULL ,
      p_loc_category_id   IN      VARCHAR2 DEFAULT NULL ,
      p_loc_group_id      IN      VARCHAR2 DEFAULT NULL ,
      p_abbreviated       IN      VARCHAR2 DEFAULT 'T' ,
      p_db_office_id      IN      VARCHAR2 DEFAULT NULL
   )
   IS
   BEGIN
      cat_loc_aliases (p_cwms_cat          => p_cwms_cat,
                       p_location_id       => p_location_id,
                       p_loc_category_id   => p_loc_category_id,
                       p_loc_group_id      => p_loc_group_id,
                       p_abbreviated       => p_abbreviated,
                       p_db_office_id      => p_db_office_id
                      );
   END;

   --
   PROCEDURE cat_loc_aliases (
      p_cwms_cat          OUT sys_refcursor,
      p_location_id       IN  VARCHAR2 DEFAULT NULL ,
      p_loc_category_id   IN  VARCHAR2 DEFAULT NULL ,
      p_loc_group_id      IN  VARCHAR2 DEFAULT NULL ,
      p_abbreviated       IN  VARCHAR2 DEFAULT 'T' ,
      p_db_office_id      IN  VARCHAR2 DEFAULT NULL
   )
   IS
      l_db_office_code NUMBER
            := cwms_util.get_db_office_code (p_db_office_id) ;
      l_abbreviated BOOLEAN
            := cwms_util.return_true_or_false (NVL (p_abbreviated, 'T')) ;
      l_loc_id       VARCHAR2 (49);
      l_loc_grp_id   VARCHAR2 (32);
      l_loc_cat_id   VARCHAR2 (32);
      l_is_null      BOOLEAN := TRUE;
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

      IF l_abbreviated
      THEN
         IF l_is_null
         THEN
            -- abbreviated listing...
            OPEN p_cwms_cat FOR
                 SELECT   db_office_id, location_id, cat_db_office_id,
                          loc_category_id, grp_db_office_id, loc_group_id,
                          loc_group_desc, loc_alias_id, 
                          cwms_util.get_location_id(loc_ref_code) ref_location_id,
                          shared_loc_alias_id, 
                          cwms_util.get_location_id(shared_loc_ref_code) shared_loc_ref_id, 
                          loc_attribute as attribute
                   FROM      (SELECT   e1.office_id db_office_id,
                                       c.location_code, b.loc_group_code,
                                       d.base_location_id
                                       || SUBSTR ('-',
                                                  1,
                                                  LENGTH (c.sub_location_id)
                                                 )
                                       || c.sub_location_id
                                          location_id, a.loc_category_id,
                                       e2.office_id cat_db_office_id,
                                       b.loc_group_id,
                                       e3.office_id grp_db_office_id,
                                       b.loc_group_desc,
                                       b.shared_loc_alias_id,
                                       b.shared_loc_ref_code
                                FROM   at_loc_category a,
                                       at_loc_group b,
                                       at_physical_location c,
                                       at_base_location d,
                                       cwms_office e1,
                                       cwms_office e2,
                                       cwms_office e3
                               WHERE   a.loc_category_code =
                                          b.loc_category_code
                                       AND c.base_location_code =
                                             d.base_location_code
                                       AND b.db_office_code IN
                                                (cwms_util.db_office_code_all,
                                                 l_db_office_code)
                                       AND d.db_office_code = l_db_office_code
                                       AND d.db_office_code = e1.office_code
                                       AND a.db_office_code = e2.office_code
                                       AND b.db_office_code = e3.office_code) a
                          JOIN
                             at_loc_group_assignment b
                          USING (location_code, loc_group_code)
               ORDER BY   UPPER (location_id),
                          UPPER (loc_category_id),
                          UPPER (loc_group_id);
         ELSE 
            -- Refined abbreviated listing...
            OPEN p_cwms_cat FOR
                 SELECT   db_office_id, location_id, cat_db_office_id,
                          loc_category_id, grp_db_office_id, loc_group_id,
                          loc_group_desc, loc_alias_id, 
                          cwms_util.get_location_id(loc_ref_code) ref_location_id,
                          shared_loc_alias_id, 
                          cwms_util.get_location_id(shared_loc_ref_code) shared_loc_ref_id,
                          loc_attribute as attribute
                   FROM      (SELECT   e1.office_id db_office_id,
                                       c.location_code, b.loc_group_code,
                                       d.base_location_id
                                       || SUBSTR ('-',
                                                  1,
                                                  LENGTH (c.sub_location_id)
                                                 )
                                       || c.sub_location_id
                                           location_id, a.loc_category_id,
                                       e2.office_id cat_db_office_id,
                                       b.loc_group_id,
                                       e3.office_id grp_db_office_id,
                                       b.loc_group_desc,
                                       b.shared_loc_alias_id,
                                       b.shared_loc_ref_code
                                FROM   at_loc_category a,
                                       at_loc_group b,
                                       at_physical_location c,
                                       at_base_location d,
                                       cwms_office e1,
                                       cwms_office e2,
                                       cwms_office e3
                               WHERE   a.loc_category_code =
                                          b.loc_category_code
                                       AND c.base_location_code =
                                             d.base_location_code
                                       AND b.db_office_code IN
                                                (cwms_util.db_office_code_all,
                                                 l_db_office_code)
                                       AND d.db_office_code = l_db_office_code
                                       AND d.db_office_code = e1.office_code
                                       AND a.db_office_code = e2.office_code
                                       AND b.db_office_code = e3.office_code) a
                          JOIN
                             at_loc_group_assignment b
                          USING (location_code, loc_group_code)
                  WHERE       UPPER (a.location_id) LIKE l_loc_id
                          AND UPPER (a.loc_category_id) LIKE l_loc_cat_id
                          AND UPPER (a.loc_group_id) LIKE l_loc_grp_id
               ORDER BY   UPPER (location_id),
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
                          loc_group_desc, loc_alias_id, 
                          cwms_util.get_location_id(loc_ref_code) ref_location_id,
                          shared_loc_alias_id, 
                          cwms_util.get_location_id(shared_loc_ref_code) shared_loc_ref_id,
                          loc_attribute as attribute
                   FROM      (SELECT   e1.office_id db_office_id,
                                       c.location_code, b.loc_group_code,
                                       d.base_location_id
                                       || SUBSTR ('-',
                                                  1,
                                                  LENGTH (c.sub_location_id)
                                                 )
                                       || c.sub_location_id
                                          location_id, a.loc_category_id,
                                       e2.office_id cat_db_office_id,
                                       b.loc_group_id,
                                       e3.office_id grp_db_office_id,
                                       b.loc_group_desc,
                                       b.shared_loc_alias_id,
                                       b.shared_loc_ref_code
                                FROM   at_loc_category a,
                                       at_loc_group b,
                                       at_physical_location c,
                                       at_base_location d,
                                       cwms_office e1,
                                       cwms_office e2,
                                       cwms_office e3
                               WHERE   a.loc_category_code =
                                          b.loc_category_code
                                       AND c.base_location_code =
                                             d.base_location_code
                                       AND b.db_office_code IN
                                                (cwms_util.db_office_code_all,
                                                 l_db_office_code)
                                       AND d.db_office_code = l_db_office_code
                                       AND d.db_office_code = e1.office_code
                                       AND a.db_office_code = e2.office_code
                                       AND b.db_office_code = e3.office_code) a
                          FULL OUTER JOIN
                             at_loc_group_assignment b
                          USING (location_code, loc_group_code)
               ORDER BY   UPPER (location_id),
                          UPPER (loc_category_id),
                          UPPER (loc_group_id);
         ELSE
            -- Refined full listing...
            OPEN p_cwms_cat FOR
                 SELECT   db_office_id, location_id, cat_db_office_id,
                          loc_category_id, grp_db_office_id, loc_group_id,
                          loc_group_desc, loc_alias_id, 
                          cwms_util.get_location_id(loc_ref_code) ref_location_id,
                          shared_loc_alias_id, 
                          cwms_util.get_location_id(shared_loc_ref_code) shared_loc_ref_id,
                          loc_attribute as attribute
                   FROM      (SELECT   e1.office_id db_office_id,
                                       c.location_code, b.loc_group_code,
                                       d.base_location_id
                                       || SUBSTR ('-',
                                                  1,
                                                  LENGTH (c.sub_location_id)
                                                 )
                                       || c.sub_location_id
                                          location_id, a.loc_category_id,
                                       e2.office_id cat_db_office_id,
                                       b.loc_group_id,
                                       e3.office_id grp_db_office_id,
                                       b.loc_group_desc,
                                       b.shared_loc_alias_id,
                                       b.shared_loc_ref_code
                                FROM   at_loc_category a,
                                       at_loc_group b,
                                       at_physical_location c,
                                       at_base_location d,
                                       cwms_office e1,
                                       cwms_office e2,
                                       cwms_office e3
                               WHERE   a.loc_category_code =
                                          b.loc_category_code
                                       AND c.base_location_code =
                                             d.base_location_code
                                       AND b.db_office_code IN
                                                (cwms_util.db_office_code_all,
                                                 l_db_office_code)
                                       AND d.db_office_code = l_db_office_code
                                       AND d.db_office_code = e1.office_code
                                       AND a.db_office_code = e2.office_code
                                       AND b.db_office_code = e3.office_code) a
                          FULL OUTER JOIN
                             at_loc_group_assignment b
                          USING (location_code, loc_group_code)
                  WHERE       UPPER (a.location_id) LIKE l_loc_id
                          AND UPPER (a.loc_category_id) LIKE l_loc_cat_id
                          AND UPPER (a.loc_group_id) LIKE l_loc_grp_id
               ORDER BY   UPPER (location_id),
                          UPPER (loc_category_id),
                          UPPER (loc_group_id);
         END IF;
      END IF;
   END cat_loc_aliases;

   -------------------------------------------------------------------------------
   -- function cat_property_tab(...)
   --
   FUNCTION cat_property_tab (p_office_id       IN VARCHAR2 DEFAULT NULL ,
                              p_prop_category   IN VARCHAR2 DEFAULT NULL ,
                              p_prop_id         IN VARCHAR2 DEFAULT NULL
                             )
      RETURN cat_property_tab_t
      PIPELINED
   IS
      output_row      cat_property_rec_t;
      query_cursor   sys_refcursor;
   BEGIN
      cat_property (query_cursor, p_office_id, p_prop_category, p_prop_id);

      LOOP
         FETCH query_cursor INTO   output_row;

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
   PROCEDURE cat_property (p_cwms_cat            OUT sys_refcursor,
                           p_office_id       IN     VARCHAR2 DEFAULT NULL ,
                           p_prop_category   IN     VARCHAR2 DEFAULT NULL ,
                           p_prop_id         IN     VARCHAR2 DEFAULT NULL
                          )
   IS
      l_office_code      NUMBER (10) := NULL;
      l_office_id       VARCHAR2 (16);
      l_prop_category   VARCHAR2 (256);
      l_prop_id         VARCHAR2 (256);
   BEGIN
      l_office_id := NVL (p_office_id, cwms_util.user_office_id);
      l_prop_category := upper(cwms_util.normalize_wildcards(nvl(p_prop_category, '*'), true));
      l_prop_id       := upper(cwms_util.normalize_wildcards(nvl(p_prop_id, '*'), true));

      open p_cwms_cat for
           select o.office_id, 
                  p.prop_category, 
                  p.prop_id
             from at_properties p, 
                  cwms_office o
            where o.office_id = l_office_id
              and p.office_code = o.office_code
              and upper (p.prop_category) like l_prop_category escape '\'
              and upper (p.prop_id) like l_prop_id escape '\'
         order by o.office_id,
                  upper (p.prop_category),
                  upper (p.prop_id) asc;
   END cat_property;

   PROCEDURE cat_loc_group (p_cwms_cat          OUT sys_refcursor,
                            p_db_office_id   IN     VARCHAR2 DEFAULT NULL
                           )
   IS
      l_db_office_code NUMBER
            := cwms_util.get_db_office_code (p_db_office_id) ;
   BEGIN
      OPEN p_cwms_cat FOR
         SELECT   co.office_id cat_db_office_id, loc_category_id,
                  loc_category_desc, coo.office_id grp_db_office_id,
                  loc_group_id, loc_group_desc, shared_loc_alias_id,
                  cwms_util.get_location_id(shared_loc_ref_code) shared_loc_ref_id
           FROM   cwms_office co,
                  cwms_office coo,
                  at_loc_category atlc,
                  at_loc_group atlg
          WHERE       atlc.db_office_code = co.office_code
                  AND atlg.db_office_code = coo.office_code(+)
                  AND atlc.loc_category_code = atlg.loc_category_code(+)
                  AND NVL (atlg.db_office_code, cwms_util.db_office_code_all) IN
                           (l_db_office_code, cwms_util.db_office_code_all)
                  AND atlc.db_office_code IN
                           (l_db_office_code, cwms_util.db_office_code_all);
   END cat_loc_group;

   FUNCTION cat_loc_group_tab (p_db_office_id IN VARCHAR2 DEFAULT NULL )
      RETURN cat_loc_grp_tab_t
      PIPELINED
   IS
      output_row      cat_loc_grp_rec_t;
      query_cursor   sys_refcursor;
   BEGIN
      cat_loc_group (query_cursor, p_db_office_id);

      LOOP
         FETCH query_cursor INTO   output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_loc_group_tab;
  
  
-------------------------------------------------------------------------------
--  manipulate generic lookup tables in the database.
--

-- retrieves a set of lookups
  procedure get_lookup_table( 
    -- the set of lookups for the office and type specified.
    p_lookup_type_tab OUT lookup_type_tab_t,
    -- the category of lookup to retrieve. currently should be the table name.
    p_lookup_category IN VARCHAR2,
    -- the lookups have a prefix on the column name.
    p_lookup_prefix IN VARCHAR2,
    -- defaults to the connected user's office if null
    p_db_office_id IN VARCHAR2 DEFAULT NULL )
  is
    l_db_office_id VARCHAR2(16) := nvl(p_db_office_id, cwms_util.user_office_id);
  begin
    dbms_application_info.set_module ('cwms_cat.get_lookup_table','querying lookups');
    
    --sanitize vars
    dbms_application_info.set_action('sanitizing vars');
    cwms_util.check_inputs(str_tab_t(
      p_lookup_category,
      p_lookup_prefix,
      p_db_office_id));
    
    -- check args for errors
    dbms_application_info.set_action('checking args');
    if p_lookup_category is null then
      cwms_err.raise(
            'NULL_ARGUMENT',
            'Lookup Category');
    end if;
    
    if p_lookup_prefix is null then
      cwms_err.raise(
            'NULL_ARGUMENT',
            'Lookup Prefix');
    end if;
    
    --do work.
    dbms_application_info.set_action('querying lookups for: '||p_lookup_category);
    p_lookup_type_tab := lookup_type_tab_t();
    
    EXECUTE IMMEDIATE 'SELECT CAST (MULTISET (SELECT :bv1 office_id,
        '|| p_lookup_prefix || '_display_value display_value,
        '|| p_lookup_prefix || '_tooltip tooltip,
        '|| p_lookup_prefix || '_active active
      FROM '||p_lookup_category||'
      WHERE db_office_code = cwms_util.get_office_code(:bv2)
      ) AS lookup_type_tab_t) FROM dual'
    INTO p_lookup_type_tab
    USING l_db_office_id, l_db_office_id;

  end get_lookup_table;

-- stores a set of lookups replacing the existing lookups for the given category
-- and office id.
  procedure set_lookup_table(
    p_lookup_type_tab IN lookup_type_tab_t,
    -- the category of the incoming lookups, should be the table name.
    p_lookup_category IN VARCHAR2,
    -- the lookups have a prefix on the column name.
    p_lookup_prefix IN VARCHAR2
    )
  is
    
    child_rec_exception EXCEPTION; 
    PRAGMA exception_init (child_rec_exception, -2292);   
    
  begin
    dbms_application_info.set_module ('cwms_cat.get_lookup_table','setting lookups');
    
    --sanitize vars
    dbms_application_info.set_action('sanitizing vars');
    cwms_util.check_inputs(str_tab_t(
      p_lookup_category,
      p_lookup_prefix));
    
    -- check args for errors
    dbms_application_info.set_action('checking args');
    if p_lookup_category is null then
      cwms_err.raise(
            'NULL_ARGUMENT',
            'Lookup Category');
    end if;
    
    if p_lookup_prefix is null then
      cwms_err.raise(
            'NULL_ARGUMENT',
            'Lookup Prefix');
    END IF;

-- removed use the delete_lookups() procedure instead.
--    begin
--      --clear out existing. this should probably be a loop to handle lus that are fked.
--      EXECUTE IMMEDIATE 'delete 
--          from '||p_lookup_category||' 
--          where db_office_code in (
--            select cwms_util.get_office_code(cwms_util.check_input_f(ltab.office_id)) 
--            from table (cast (:bv1 as lookup_type_tab_t)) ltab )'
--        using p_lookup_type_tab;
--        EXCEPTION
--            WHEN child_rec_exception THEN
--              null;
--    end;

    --this should be a merge.
    --incoming object array sanitized when being used.
    EXECUTE IMMEDIATE 'MERGE INTO '||p_lookup_category||' lutab
        USING (  SELECT cwms_util.get_office_code(cwms_util.check_input_f(ltab.office_id)) office_code, 
                    cwms_util.check_input_f(ltab.display_value) display_value, 
                    cwms_util.check_input_f(ltab.tooltip) tooltip, 
                    cwms_util.check_input_f(ltab.active) active 
                from table (cast (:bv1 as lookup_type_tab_t)) ltab
        ) mtab
        ON (  lutab.db_office_code = mtab.office_code 
              AND upper(lutab.'||p_lookup_prefix||'_display_value) = upper(mtab.display_value)
        )  
        WHEN MATCHED THEN
            UPDATE SET 
              lutab.'||p_lookup_prefix||'_tooltip = mtab.tooltip,
              lutab.'||p_lookup_prefix||'_active = mtab.active
        WHEN NOT MATCHED THEN
            INSERT 
            ( lutab.'||p_lookup_prefix||'_code,
              lutab.db_office_code,
              lutab.'||p_lookup_prefix||'_display_value,
              lutab.'||p_lookup_prefix||'_tooltip,
              lutab.'||p_lookup_prefix||'_active 
            )
            VALUES (
              cwms_seq.nextval,
              mtab.office_code,
              mtab.display_value,
              mtab.tooltip,
              mtab.active
            )'
      USING p_lookup_type_tab;

  end set_lookup_table;

--Deletes a set of lookup values that conform to a common structure but different names. 
--The identifying parts within the arg lookup table type are used to determine which row
--values to delete from the look up table.d.
  procedure delete_lookups(
    -- the lookups to delete. only the identifying parts need be defined.
    p_lookup_type_tab IN lookup_type_tab_t,
    -- the category of the incoming lookups, should be the table name.
    p_lookup_category IN VARCHAR2,
    -- the lookups have a prefix on the column name.
    p_lookup_prefix IN VARCHAR2
    )
  is

    child_rec_exception EXCEPTION; 
    PRAGMA exception_init (child_rec_exception, -2292);   

  begin
    dbms_application_info.set_module ('cwms_cat.delete_lookups','deleting lookups');  
   
    --sanitize vars
    dbms_application_info.set_action('sanitizing vars');
    cwms_util.check_inputs(str_tab_t(
      p_lookup_category,
      p_lookup_prefix));
    
    -- check args for errors
    dbms_application_info.set_action('checking args');
    if p_lookup_category is null then
      cwms_err.raise(
            'NULL_ARGUMENT',
            'Lookup Category');
    end if;
    
    if p_lookup_prefix is null then
      cwms_err.raise(
            'NULL_ARGUMENT',
            'Lookup Prefix');
    end if;

    BEGIN
      --delete the passed in lookups. this will fail if lookups are fked.
      EXECUTE IMMEDIATE 
      'DELETE FROM '||p_lookup_category||'   
      WHERE '||p_lookup_prefix||'_code IN (    
        SELECT lu.'||p_lookup_prefix||'_code     
        FROM '||p_lookup_category||' lu    
        INNER JOIN TABLE (CAST (:bv1 AS lookup_type_tab_t)) ltab     
          ON lu.db_office_code = cwms_util.get_office_code(ltab.office_id)    
          AND UPPER(lu.'||p_lookup_prefix||'_display_value) = UPPER(ltab.display_value))' 
      USING p_lookup_type_tab;
      EXCEPTION
          WHEN CHILD_REC_EXCEPTION THEN
            NULL;
    END;    
 
  END delete_lookups;

   --------------------------------------------------------------------------------
   -- procedure cat_streams
   --
   -- catalog has the following fields, sorted ascending by office_id and stream_id
   --
   --    office_id            varchar2(16)
   --    stream_id            varchar2(49)
   --    stationing_starts_ds varchar2(1)
   --    flows_into_stream    varchar2(49)
   --    flows_into_station   binary_double
   --    flows_into_bank      varchar2(1) 
   --    diverts_from_stream  varchar2(49)
   --    diverts_from_station binary_double
   --    diverts_from_bank    varchar2(1)
   --    stream_length        binary_double
   --    average_slope        binary_double
   --    comments             varchar2(256) 
   --
   --------------------------------------------------------------------------------
   procedure cat_streams(          
      p_stream_catalog              out sys_refcursor,
      p_stream_id_mask              in  varchar2 default '*',
      p_station_units               in  varchar2 default 'km',
      p_stationing_starts_ds_mask   in  varchar2 default '*',
      p_flows_into_stream_id_mask   in  varchar2 default '*',
      p_flows_into_station_min      in  binary_double default null,
      p_flows_into_station_max      in  binary_double default null,
      p_flows_into_bank_mask        in  varchar2 default '*',
      p_diverts_from_stream_id_mask in  varchar2 default '*',
      p_diverts_from_station_min    in  binary_double default null,
      p_diverts_from_station_max    in  binary_double default null,
      p_diverts_from_bank_mask      in  varchar2 default '*',
      p_length_min                  in  binary_double default null,
      p_length_max                  in  binary_double default null,
      p_average_slope_min           in  binary_double default null,
      p_average_slope_max           in  binary_double default null,
      p_comments_mask               in  varchar2 default '*',
      p_office_id_mask              in  varchar2 default null)
   is
   begin
      cwms_stream.cat_streams(          
         p_stream_catalog,
         p_stream_id_mask,
         p_station_units,
         p_stationing_starts_ds_mask,
         p_flows_into_stream_id_mask,
         p_flows_into_station_min,
         p_flows_into_station_max,
         p_flows_into_bank_mask,
         p_diverts_from_stream_id_mask,
         p_diverts_from_station_min,
         p_diverts_from_station_max,
         p_diverts_from_bank_mask,
         p_length_min,
         p_length_max,
         p_average_slope_min,
         p_average_slope_max,
         p_comments_mask,
         p_office_id_mask);
   end cat_streams;      

   --------------------------------------------------------------------------------
   -- function cat_streams_f
   --
   -- catalog has the following fields, sorted ascending by office_id and stream_id
   --
   --    office_id            varchar2(16)
   --    stream_id            varchar2(49)
   --    stationing_starts_ds varchar2(1)
   --    flows_into_stream    varchar2(49)
   --    flows_into_station   binary_double
   --    flows_into_bank      varchar2(1) 
   --    diverts_from_stream  varchar2(49)
   --    diverts_from_station binary_double
   --    diverts_from_bank    varchar2(1)
   --    stream_length        binary_double
   --    average_slope        binary_double
   --    comments             varchar2(256) 
   --
   --------------------------------------------------------------------------------
   function cat_streams_f(          
      p_stream_id_mask              in varchar2 default '*',
      p_station_units               in varchar2 default 'km',
      p_stationing_starts_ds_mask   in varchar2 default '*',
      p_flows_into_stream_id_mask   in varchar2 default '*',
      p_flows_into_station_min      in binary_double default null,
      p_flows_into_station_max      in binary_double default null,
      p_flows_into_bank_mask        in varchar2 default '*',
      p_diverts_from_stream_id_mask in varchar2 default '*',
      p_diverts_from_station_min    in binary_double default null,
      p_diverts_from_station_max    in binary_double default null,
      p_diverts_from_bank_mask      in varchar2 default '*',
      p_length_min                  in binary_double default null,
      p_length_max                  in binary_double default null,
      p_average_slope_min           in binary_double default null,
      p_average_slope_max           in binary_double default null,
      p_comments_mask               in varchar2 default '*',
      p_office_id_mask              in varchar2 default null)
      return sys_refcursor
   is
   begin
      return cwms_stream.cat_streams_f(          
         p_stream_id_mask,
         p_station_units,
         p_stationing_starts_ds_mask,
         p_flows_into_stream_id_mask,
         p_flows_into_station_min,
         p_flows_into_station_max,
         p_flows_into_bank_mask,
         p_diverts_from_stream_id_mask,
         p_diverts_from_station_min,
         p_diverts_from_station_max,
         p_diverts_from_bank_mask,
         p_length_min,
         p_length_max,
         p_average_slope_min,
         p_average_slope_max,
         p_comments_mask,
         p_office_id_mask);
   end cat_streams_f;      

   --------------------------------------------------------------------------------
   -- procedure cat_stream_reaches
   --
   -- catalog has the following fields, sorted by first 3 fields
   --
   --    office_id            varchar2(16)
   --    stream_id            varchar2(49)
   --    stream_reach_id      varchar2(64)
   --    upstream_station     binary_double
   --    downstream_station   binary_double
   --    stream_type_id       varchar2(4)
   --    comments             varchar2(256)
   --------------------------------------------------------------------------------
   procedure cat_stream_reaches(
      p_reach_catalog       out sys_refcursor,
      p_stream_id_mask      in  varchar2 default '*',
      p_reach_id_mask       in  varchar2 default '*',
      p_stream_type_id_mask in  varchar2 default '*',
      p_comments_mask       in  varchar2 default '*',
      p_office_id_mask      in  varchar2 default null)
   is
   begin
      cwms_stream.cat_stream_reaches(
         p_reach_catalog,
         p_stream_id_mask,
         p_reach_id_mask,
         p_stream_type_id_mask,
         p_comments_mask,
         p_office_id_mask);
   end cat_stream_reaches;

   --------------------------------------------------------------------------------
   -- function cat_stream_reaches_f
   --
   -- catalog has the following fields, sorted by first 3 fields
   --
   --    office_id            varchar2(16)
   --    stream_id            varchar2(49)
   --    stream_reach_id      varchar2(64)
   --    upstream_station     binary_double
   --    downstream_station   binary_double
   --    stream_type_id       varchar2(4)
   --    comments             varchar2(256)
   --------------------------------------------------------------------------------
   function cat_stream_reaches_f(
      p_stream_id_mask      in varchar2 default '*',
      p_reach_id_mask       in varchar2 default '*',
      p_stream_type_id_mask in varchar2 default '*',
      p_comments_mask       in varchar2 default '*',
      p_office_id_mask      in varchar2 default null)
      return sys_refcursor
   is
   begin
      return cwms_stream.cat_stream_reaches_f(
         p_stream_id_mask,
         p_reach_id_mask,
         p_stream_type_id_mask,
         p_comments_mask,
         p_office_id_mask);
   end cat_stream_reaches_f;      
      
   --------------------------------------------------------------------------------
   -- procedure cat_stream_locations
   --
   -- catalog includes, sorted by office_id, stream_id, station, location_id
   --
   --    office_id               varchar2(16)
   --    stream_id               varchar2(49)
   --    location_id             varchar2(49)
   --    station                 binary_double
   --    bank                    varchar2(1)
   --    lowest_measurable_stage binary_double
   --    drainage_area           binary_double
   --    ungaged_area            binary_double
   --    station_unit            varchar2(16)
   --    stage_unit              varchar2(16)
   --    area_unit               varchar2(16)
   --
   --------------------------------------------------------------------------------
   procedure cat_stream_locations(
      p_stream_location_catalog out sys_refcursor,
      p_stream_id_mask          in  varchar2 default '*',
      p_location_id_mask        in  varchar2 default '*',
      p_station_unit            in  varchar2 default null,
      p_stage_unit              in  varchar2 default null,
      p_area_unit               in  varchar2 default null,
      p_office_id_mask          in  varchar2 default null)
   is
   begin
      cwms_stream.cat_stream_locations(
         p_stream_location_catalog,
         p_stream_id_mask,
         p_location_id_mask,
         p_station_unit,
         p_stage_unit,
         p_area_unit,
         p_office_id_mask);
   end cat_stream_locations;      
      
   --------------------------------------------------------------------------------
   -- function cat_stream_locations_f   
   --
   -- catalog includes, sorted by office_id, stream_id, station, location_id
   --
   --    office_id               varchar2(16)
   --    stream_id               varchar2(49)
   --    location_id             varchar2(49)
   --    station                 binary_double
   --    bank                    varchar2(1)
   --    lowest_measurable_stage binary_double
   --    drainage_area           binary_double
   --    ungaged_area            binary_double
   --    station_unit            varchar2(16)
   --    stage_unit              varchar2(16)
   --    area_unit               varchar2(16)
   --
   --------------------------------------------------------------------------------
   function cat_stream_locations_f(
      p_stream_id_mask   in  varchar2 default '*',
      p_location_id_mask in  varchar2 default '*',
      p_station_unit     in  varchar2 default null,
      p_stage_unit       in  varchar2 default null,
      p_area_unit        in  varchar2 default null,
      p_office_id_mask   in  varchar2 default null)
      return sys_refcursor
   is
   begin
      return cwms_stream.cat_stream_locations_f(
         p_stream_id_mask,
         p_location_id_mask,
         p_station_unit,
         p_stage_unit,
         p_area_unit,
         p_office_id_mask);
   end cat_stream_locations_f;      

   --------------------------------------------------------------------------------
   -- procedure cat_basins
   --
   -- the catalog contains the following fields, sorted by the first 4
   --
   --    office_id                  varchar2(16)
   --    basin_id                   varchar2(49)
   --    parent_basin_id            varchar2(49)
   --    sort_order                 binary_double
   --    primary_stream_id          varchar2(49)
   --    total_drainage_area        binary_double
   --    contributing_drainage_area binary_double
   --    area_unit                  varchar2(16)
   --
   --------------------------------------------------------------------------------
   procedure cat_basins(
      p_basins_catalog         out sys_refcursor,
      p_basin_id_mask          in  varchar2 default '*',
      p_parent_basin_id_mask   in  varchar2 default '*',
      p_primary_stream_id_mask in  varchar2 default '*',
      p_area_unit              in  varchar2 default null,
      p_office_id_mask         in  varchar2 default null)
   is
   begin
      cwms_basin.cat_basins(
         p_basins_catalog,
         p_basin_id_mask,
         p_parent_basin_id_mask,
         p_primary_stream_id_mask,
         p_area_unit,
         p_office_id_mask);
   end cat_basins;

   --------------------------------------------------------------------------------
   -- function cat_basins_f
   --
   -- the catalog contains the following fields, sorted by the first 4
   --
   --    office_id                  varchar2(16)
   --    basin_id                   varchar2(49)
   --    parent_basin_id            varchar2(49)
   --    sort_order                 binary_double
   --    primary_stream_id          varchar2(49)
   --    total_drainage_area        binary_double
   --    contributing_drainage_area binary_double
   --    area_unit                  varchar2(16)
   --
   --------------------------------------------------------------------------------
   function cat_basins_f(
      p_basin_id_mask          in varchar2 default '*',
      p_parent_basin_id_mask   in varchar2 default '*',
      p_primary_stream_id_mask in varchar2 default '*',
      p_area_unit              in varchar2 default null,
      p_office_id_mask         in varchar2 default null)
      return sys_refcursor
   is
   begin
      return cwms_basin.cat_basins_f(
         p_basin_id_mask,
         p_parent_basin_id_mask,
         p_primary_stream_id_mask,
         p_area_unit,
         p_office_id_mask);
   end cat_basins_f;
    
END cwms_cat;
/

SHOW errors;