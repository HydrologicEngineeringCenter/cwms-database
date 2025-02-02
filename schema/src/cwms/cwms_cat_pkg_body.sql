/* Formatted on 4/8/2011 8:39:45 AM (QP5 v5.139.911.3011) */
SET define off
CREATE OR REPLACE PACKAGE BODY cwms_cat
IS
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
      l_db_office_code    NUMBER;
      l_loc_group_code    NUMBER := NULL;
       l_ts_group_code    NUMBER := NULL;
      l_ts_subselect_string VARCHAR2 (512)
            := nvl(cwms_util.normalize_wildcards(TRIM (p_ts_subselect_string)), '%') ;
   BEGIN

      l_db_office_code := cwms_util.get_db_office_code(p_db_office_id);

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

    open p_cwms_cat for
      select q1.db_office_id,
             q1.base_location_id,
             q1.cwms_ts_id,
             q1.interval_utc_offset,
             q1.time_zone_id as lrts_timezone,
             q1.net_ts_active_flag as ts_active_flag,
             q2.net_privilege_bit as user_privileges
        from (select v.ts_code,
                     v.db_office_id,
                     v.base_location_id,
                     v.cwms_ts_id,
                     v.interval_utc_offset,
                     v.time_zone_id,
                     t.net_ts_active_flag
                from av_cwms_ts_id v,
                     at_cwms_ts_id t
               where t.ts_code = v.ts_code
                 and (l_loc_group_code is null or
                      v.location_code in (select location_code
                                            from at_loc_group_assignment
                                           where loc_group_code = l_loc_group_code
                                         )
                     )
                 and (l_ts_group_code is null or
                      v.ts_code in (select ts_code
                                      from at_ts_group_assignment
                                      where ts_group_code=l_ts_group_code
                                   )
                     )
                 and (l_db_office_code is null or
                      v.db_office_code = l_db_office_code
                     )
                 and upper(v.cwms_ts_id) like upper (l_ts_subselect_string) escape '\'
             ) q1
             left outer join
             (select ts_code,
                     net_privilege_bit
                from av_sec_ts_privileges
               where username = cwms_util.get_user_id
             ) q2 on q2.ts_code = q1.ts_code
       order by upper(cwms_util.split_text(q1.cwms_ts_id, 1, '.')), -- location
                upper (q1.cwms_ts_id),                              -- tsid
                upper (q1.db_office_id) asc;                        -- office
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
      l_office_code number(14);
   begin
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
      l_office_code number(14);
   begin
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
                      where upper(c.ts_category_id) like cwms_util.normalize_wildcards(nvl(upper(p_ts_category_id), '*')) escape '\'
                        and upper(g.ts_group_id) like cwms_util.normalize_wildcards(nvl(upper(p_ts_group_id), '*')) escape '\'
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
                      where upper(cwms_ts.get_ts_id(a.ts_code)) like cwms_util.normalize_wildcards(nvl(upper(p_ts_id), '*')) escape '\'
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
                      where upper(c.ts_category_id) like cwms_util.normalize_wildcards(nvl(upper(p_ts_category_id), '*')) escape '\'
                        and upper(g.ts_group_id) like cwms_util.normalize_wildcards(nvl(upper(p_ts_group_id), '*')) escape '\'
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
                      where upper(cwms_ts.get_ts_id(a.ts_code)) like cwms_util.normalize_wildcards(nvl(upper(p_ts_id), '*')) escape '\'
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
      l_office_code number(14);
   begin
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
   --    location_id              varchar2(57)   full location id
   --    base_location_id         varchar2(24)   base location id
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
   --    public_name              varchar2(57)   location public name
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
--    location_id              varchar2(57)   full location id
--    base_location_id         varchar2(24)   base location id
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
--    public_name              varchar2(57)   location public name
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
                               clk.location_kind_id,
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
                               cwms_location_kind clk,
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
                           and clk.location_kind_code = apl.location_kind
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
                      ( select fips_cntry,
                               long_name as nation_id
                          from cwms_nation_sp
                      ) nat on nat.fips_cntry = loc.nation_code
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
                               clk.location_kind_id,
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
                               cwms_location_kind clk,
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
                           and clk.location_kind_code = apl.location_kind
                           and atlga.loc_group_code = l_loc_group_code
                           and apl.location_code = atlga.location_code
                      ) loc
                      left outer join
                      ( select office_code,
                               office_id as bounding_office_id
                          from cwms_office
                      ) ofc on ofc.office_code = loc.bounding_office_code
                      left outer join
                      ( select fips_cntry,
                               long_name as nation_id
                          from cwms_nation_sp
                      ) nat on nat.fips_cntry = loc.nation_code
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
                               clk.location_kind_id,
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
                               cwms_location_kind clk
                         where abl.db_office_code = l_db_office_code
                           and (cc.county_code = nvl (apl.county_code, 0))
                           and (cs.state_code = nvl (cc.state_code, 0))
                           and (abl.db_office_code = co.office_code)
                           and (ctz.time_zone_code = nvl (apl.time_zone_code, 0))
                           and apl.base_location_code = abl.base_location_code
                           and apl.location_code != 0
                           and cuc.from_unit_id = 'm'
                           and cuc.to_unit_id = p_elevation_unit
                           and clk.location_kind_code = apl.location_kind
                           and apl.sub_location_id is null
                      ) loc
                      left outer join
                      ( select office_code,
                               office_id as bounding_office_id
                          from cwms_office
                      ) ofc on ofc.office_code = loc.bounding_office_code
                      left outer join
                      ( select fips_cntry,
                               long_name as nation_id
                          from cwms_nation_sp
                      ) nat on nat.fips_cntry = loc.nation_code
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
                               clk.location_kind_id,
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
                               cwms_location_kind clk
                         where abl.db_office_code = l_db_office_code
                           and (cc.county_code = nvl (apl.county_code, 0))
                           and (cs.state_code = nvl (cc.state_code, 0))
                           and (abl.db_office_code = co.office_code)
                           and (ctz.time_zone_code = nvl (apl.time_zone_code, 0))
                           and apl.base_location_code = abl.base_location_code
                           and apl.location_code != 0
                           and cuc.from_unit_id = 'm'
                           and cuc.to_unit_id = p_elevation_unit
                           and clk.location_kind_code = apl.location_kind
                      ) loc
                      left outer join
                      ( select office_code,
                               office_id as bounding_office_id
                          from cwms_office
                      ) ofc on ofc.office_code = loc.bounding_office_code
                      left outer join
                      ( select fips_cntry,
                               long_name as nation_id
                          from cwms_nation_sp
                      ) nat on nat.fips_cntry = loc.nation_code
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
      open p_cwms_cat for
         select cp.base_parameter_id
                || substr('-', 1, length(atp.sub_parameter_id))
                || atp.sub_parameter_id as parameter_id,
                cp.base_parameter_id,
                atp.sub_parameter_id,
                case
                   when atp.sub_parameter_desc is null then cp.description
                   else atp.sub_parameter_desc
                end as sub_parameter_desc,
                co.office_id as db_office_id,
                cu.unit_id as db_unit_id,
                cu.long_name as unit_long_name,
                cu.description as unit_description
           from at_parameter atp,
                cwms_base_parameter cp,
                cwms_unit cu,
                cwms_office co
          where atp.parameter_code > 0 -- exclude Text, Binary
            and atp.base_parameter_code = cp.base_parameter_code
            and cp.unit_code = cu.unit_code
            and co.office_code = atp.db_office_code
            and atp.db_office_code in (cwms_util.db_office_code_all, l_db_office_code)
          order by cp.base_parameter_id asc;
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
                    av_cwms_ts_id tspec,
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
   END cat_loc_aliases_java;

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
      l_loc_id       VARCHAR2 (57);
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
                          loc_attribute as attribute,
                          loc_group_attribute as group_attribute
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
                                       b.loc_group_attribute,
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
                          loc_attribute as attribute,
                          loc_group_attribute as group_attribute
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
                                       b.loc_group_attribute,
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
                  WHERE       UPPER (a.location_id) LIKE l_loc_id escape '\'
                          AND UPPER (a.loc_category_id) LIKE l_loc_cat_id escape '\'
                          AND UPPER (a.loc_group_id) LIKE l_loc_grp_id escape '\'
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
                          loc_attribute as attribute,
                          loc_group_attribute as group_attribute
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
                                       b.loc_group_attribute,
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
                          loc_attribute as attribute,
                          loc_group_attribute as group_attribute
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
                                       b.loc_group_attribute,
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
                  WHERE       UPPER (a.location_id) LIKE l_loc_id escape '\'
                          AND UPPER (a.loc_category_id) LIKE l_loc_cat_id escape '\'
                          AND UPPER (a.loc_group_id) LIKE l_loc_grp_id escape '\'
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
      l_office_code      NUMBER (14) := NULL;
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
      l_db_office_id    VARCHAR2(16) := trim(p_db_office_id);
      l_lookup_category VARCHAR2(30) := trim(p_lookup_category);
      l_lookup_prefix   VARCHAR2(30) := trim(p_lookup_prefix);
      l_str             varchar2(32767);
   begin
      dbms_application_info.set_module ('cwms_cat.get_lookup_table','querying lookups');

      -- check args for errors
      dbms_application_info.set_action('checking args');
      if l_lookup_category is null then
         cwms_err.raise('NULL_ARGUMENT', 'p_lookup_category');
      end if;
      if l_lookup_category is null then
         cwms_err.raise('NULL_ARGUMENT', 'p_lookup_prefix');
      end if;

      begin
         l_str := dbms_assert.simple_sql_name(nvl(l_db_office_id, cwms_util.user_office_id));
      exception
         when others then
            cwms_err.raise('INVALID_OFFICE_ID', l_db_office_id);
      end;
      begin
         l_str := dbms_assert.simple_sql_name(l_lookup_category);
      exception
         when others then
            cwms_err.raise('INVALID_ITEM', l_lookup_category, 'lookup category');
      end;
      begin
         l_str := dbms_assert.simple_sql_name(l_lookup_prefix);
      exception
         when others then
            cwms_err.raise('INVALID_ITEM', l_lookup_prefix, 'lookup prefix');
      end;


      --do work.
      dbms_application_info.set_action('querying lookups for: '||p_lookup_category);
      p_lookup_type_tab := lookup_type_tab_t();

      l_str := 'SELECT CAST (MULTISET (SELECT :bv1 office_id,
        '|| l_lookup_prefix || '_display_value display_value,
        '|| l_lookup_prefix || '_tooltip tooltip,
        '|| l_lookup_prefix || '_active active
      FROM '||l_lookup_category||'
      WHERE db_office_code in (cwms_util.get_office_code(:bv2), 53)
      ) AS lookup_type_tab_t) FROM dual';

      cwms_util.check_dynamic_sql(l_str);

      EXECUTE IMMEDIATE l_str
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
      l_lookup_category VARCHAR2(30) := trim(p_lookup_category);
      l_lookup_prefix   VARCHAR2(30) := trim(p_lookup_prefix);
      l_str             varchar2(32767);

   begin
      dbms_application_info.set_module ('cwms_cat.set_lookup_table','setting lookups');

      --sanitize vars
      dbms_application_info.set_action('sanitizing vars');
      if l_lookup_category is null then
         cwms_err.raise('NULL_ARGUMENT', 'p_lookup_category');
      end if;
      begin
         l_str := dbms_assert.simple_sql_name(l_lookup_category);
      exception
         when others then
            cwms_err.raise('INVALID_ITEM', l_lookup_category, 'lookup category');
      end;
      if l_lookup_category is null then
         cwms_err.raise('NULL_ARGUMENT', 'p_lookup_prefix');
      end if;
      begin
         l_str := dbms_assert.simple_sql_name(l_lookup_prefix);
      exception
         when others then
            cwms_err.raise('INVALID_ITEM', l_lookup_prefix, 'lookup prefix');
      end;

      --this should be a merge.
      --incoming object array sanitized when being used.

      l_str := 'MERGE INTO '||l_lookup_category||' lutab
        USING (  SELECT cwms_util.get_office_code(ltab.office_id) office_code,
                    ltab.display_value display_value,
                    ltab.tooltip tooltip,
                    ltab.active active
                from table (cast (:bv1 as lookup_type_tab_t)) ltab
        ) mtab
        ON (  lutab.db_office_code = mtab.office_code
              AND upper(lutab.'||l_lookup_prefix||'_display_value) = upper(mtab.display_value)
        )
        WHEN MATCHED THEN
            UPDATE SET
              lutab.'||l_lookup_prefix||'_tooltip = mtab.tooltip,
              lutab.'||l_lookup_prefix||'_active = mtab.active
        WHEN NOT MATCHED THEN
            INSERT
            ( lutab.'||l_lookup_prefix||'_code,
              lutab.db_office_code,
              lutab.'||l_lookup_prefix||'_display_value,
              lutab.'||l_lookup_prefix||'_tooltip,
              lutab.'||l_lookup_prefix||'_active
            )
            VALUES (
              cwms_seq.nextval,
              mtab.office_code,
              mtab.display_value,
              mtab.tooltip,
              mtab.active
            )';

      cwms_util.check_dynamic_sql(l_str);

      EXECUTE IMMEDIATE l_str
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
      l_lookup_category VARCHAR2(30) := trim(p_lookup_category);
      l_lookup_prefix   VARCHAR2(30) := trim(p_lookup_prefix);
      l_str             varchar2(32767);

   begin
      dbms_application_info.set_module ('cwms_cat.delete_lookups','deleting lookups');

      --sanitize vars
      dbms_application_info.set_action('sanitizing vars');
      --sanitize vars
      dbms_application_info.set_action('sanitizing vars');
      if l_lookup_category is null then
         cwms_err.raise('NULL_ARGUMENT', 'p_lookup_category');
      end if;
      begin
         l_str := dbms_assert.simple_sql_name(l_lookup_category);
      exception
         when others then
            cwms_err.raise('INVALID_ITEM', l_lookup_category, 'lookup category');
      end;
      if l_lookup_category is null then
         cwms_err.raise('NULL_ARGUMENT', 'p_lookup_prefix');
      end if;
      begin
         l_str := dbms_assert.simple_sql_name(l_lookup_prefix);
      exception
         when others then
            cwms_err.raise('INVALID_ITEM', l_lookup_prefix, 'lookup prefix');
      end;

      l_str := 'DELETE FROM '||l_lookup_category||'
         WHERE '||l_lookup_prefix||'_code IN (
         SELECT lu.'||l_lookup_prefix||'_code
         FROM '||l_lookup_category||' lu
         INNER JOIN TABLE (CAST (:bv1 AS lookup_type_tab_t)) ltab
         ON lu.db_office_code = cwms_util.get_office_code(ltab.office_id)
         AND UPPER(lu.'||l_lookup_prefix||'_display_value) = UPPER(ltab.display_value))';

      cwms_util.check_dynamic_sql(l_str);

      BEGIN
         --delete the passed in lookups. this will fail if lookups are fked.

         EXECUTE IMMEDIATE
            l_str
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
   --    stream_id            varchar2(57)
   --    stationing_starts_ds varchar2(1)
   --    flows_into_stream    varchar2(57)
   --    flows_into_station   binary_double
   --    flows_into_bank      varchar2(1)
   --    diverts_from_stream  varchar2(57)
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
   --    stream_id            varchar2(57)
   --    stationing_starts_ds varchar2(1)
   --    flows_into_stream    varchar2(57)
   --    flows_into_station   binary_double
   --    flows_into_bank      varchar2(1)
   --    diverts_from_stream  varchar2(57)
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
   --    stream_id            varchar2(57)
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
   --    stream_id            varchar2(57)
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
   --    stream_id               varchar2(57)
   --    location_id             varchar2(57)
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
   --    stream_id               varchar2(57)
   --    location_id             varchar2(57)
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
   --    basin_id                   varchar2(57)
   --    parent_basin_id            varchar2(57)
   --    sort_order                 binary_double
   --    primary_stream_id          varchar2(57)
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
   --    basin_id                   varchar2(57)
   --    parent_basin_id            varchar2(57)
   --    sort_order                 binary_double
   --    primary_stream_id          varchar2(57)
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

   function cat_loc_lvl_cur_max_ind
      return loc_lvl_cur_max_ind_tab_t
      pipelined
   as
      l_cursor sys_refcursor;
      l_indicator_id     varchar2(431);
      l_attribute_id     varchar2(83);
      l_attribute_value  number;
      l_attribute_units  varchar2(16);
      l_indicator_values number_tab_t;
      l_output_row       loc_lvl_cur_max_ind_t := loc_lvl_cur_max_ind_t(null, null, null, null, null, null, null);
      l_revert_lrts_ids  boolean;
   begin
      l_revert_lrts_ids := cwms_ts.use_new_lrts_format_on_output = 'T' and
                           cwms_ts.require_new_lrts_format_on_input = 'F';
      for rec in (select distinct * from av_loc_lvl_ts_map) loop
         cwms_level.get_level_indicator_values(
            p_cursor               => l_cursor,
            p_tsid                 => cwms_ts.format_lrts_input(rec.cwms_ts_id,l_revert_lrts_ids),
            p_specified_level_mask => cwms_util.split_text(rec.location_level_id, 5, '.'),
            p_indicator_id_mask    => rec.level_indicator_id,
            p_office_id            => rec.office_id);
         begin
            fetch l_cursor
             into l_indicator_id,
                  l_attribute_id,
                  l_attribute_value,
                  l_attribute_units,
                  l_indicator_values;
         exception
            when others then null;

         end;
         close l_cursor;

         l_output_row.office_id          := rec.office_id;
         l_output_row.cwms_ts_id         := rec.cwms_ts_id;
         l_output_row.level_indicator_id := rec.location_level_id||'.'||rec.level_indicator_id;
         l_output_row.attribute_id       := rec.attribute_id;
         l_output_row.attribute_value    := rec.attribute_value;

         if l_indicator_values is null or l_indicator_values.count = 0 then
            l_output_row.max_indicator := 0;
         else
            l_output_row.max_indicator := l_indicator_values(l_indicator_values.count);
         end if;

         if l_output_row.max_indicator = 0 then
            l_output_row.indicator_name := 'None';
         else
            select name
              into l_output_row.indicator_name
              from av_loc_lvl_indicator lli
             where lli.office_id = l_output_row.office_id
               and lli.level_indicator_id = l_output_row.level_indicator_id
               and nvl(lli.attribute_id, '.') = nvl(l_output_row.attribute_id, '.')
               and nvl(lli.attribute_value, -1) = nvl(l_output_row.attribute_value, -1)
               and lli.value = l_output_row.max_indicator;
         end if;
         pipe row(l_output_row);
      end loop;
   end cat_loc_lvl_cur_max_ind;

   function iso_duration(
      p_intvl in dsinterval_unconstrained)
      return varchar2
   is
      l_hours   integer := extract(hour   from p_intvl);
      l_minutes integer := extract(minute from p_intvl);
      l_seconds number  := extract(second from p_intvl);
      l_iso     varchar2(17) := 'PT';
   begin
      if l_hours > 0 then
         l_iso := l_iso || l_hours || 'H';
      end if;
      if l_minutes > 0 then
         l_iso := l_iso || l_minutes || 'M';
      end if;
      if l_seconds > 0 then
         l_iso := l_iso || trim(to_char(l_seconds, '90.999')) || 'S';
      end if;
      if l_iso = 'PT' then
         l_iso := l_iso || '0S';
      end if;
      return l_iso;
   end;

   procedure retrieve_offices(
      p_offices out clob,
      p_format  in  varchar2)
   is
   begin
      p_offices := retrieve_offices_f(p_format);
   end retrieve_offices;

   function retrieve_offices_f(
      p_format in varchar2)
      return clob
   is
      type rec_t is record(office_id varchar2(16), long_name varchar2(80), office_type varchar2(32), reports_to_office varchar2(16));
      type tab_t is table of rec_t;
      l_format         varchar2(16) := lower(trim(p_format));
      l_offices        tab_t;
      l_data           clob;
      l_tab            varchar2(1) := chr(9);
      l_nl             varchar2(1) := chr(10);
      l_ts1            timestamp;
      l_ts2            timestamp;
      l_query_time     date;
      l_elapsed_query  interval day (0) to second (6);
      l_elapsed_format interval day (0) to second (6);
   begin
      l_query_time := sysdate;
      l_ts1 := systimestamp;
      select office_id,
             long_name,
             case office_type
                when 'HQ'   then 'USACE Headquarters'
                when 'DIS'  then 'District'
                when 'FOA'  then 'Field Operating Activity'
                when 'UNK'  then 'Other/Unknown'
                when 'MSC'  then 'Division Headquarters'
                when 'MSCR' then 'Division Regional Office'
             end,
             report_to_office_id
        bulk collect
        into l_offices
        from av_office
       order by office_id;
      l_ts2 := systimestamp;
      l_elapsed_query := l_ts2 - l_ts1;
      l_ts1 := systimestamp;

      dbms_lob.createtemporary(l_data, true);
      case
      when l_format in ('tab', 'csv') then
         ----------------
         -- TAB or CSV --
         ----------------
         cwms_util.append(l_data, '#Office Name'||l_tab||'Long Name'||l_tab||'Office Type'||l_tab||'Reports To Office'||l_nl);
         for i in 1..l_offices.count loop
            cwms_util.append(
               l_data,
               l_offices(i).office_id           ||l_tab
               ||l_offices(i).long_name         ||l_tab
               ||l_offices(i).office_type       ||l_tab
               ||l_offices(i).reports_to_office ||l_nl);
         end loop;
         if l_format = 'csv' then
            l_data := cwms_util.tab_to_csv(l_data);
         end if;
      when l_format = 'xml' then
         ---------
         -- XML --
         ---------
         cwms_util.append(l_data, '<?xml version="1.0" encoding="windows-1252"?><offices>');
         for i in 1..l_offices.count loop
            cwms_util.append(
               l_data,
               '<office><name>'
               ||l_offices(i).office_id||'</name><long-name>'
               ||l_offices(i).long_name||'</long-name><type>'
               ||l_offices(i).office_type||'</type><reports-to>'
               ||l_offices(i).reports_to_office||'</reports-to>'
               ||'</office>');
         end loop;
         cwms_util.append(l_data, '</offices>');
      when l_format = 'json' then
         ----------
         -- JSON --
         ----------
         cwms_util.append(l_data, '{"offices":{"offices":[');
         for i in 1..l_offices.count loop
            cwms_util.append(
               l_data,
               case i when 1 then '{"name":"' else ',{"name":"' end
               ||l_offices(i).office_id
               ||'","long-name":"'
               ||l_offices(i).long_name
               ||'","type":"'
               ||l_offices(i).office_type
               ||'","reports-to":"'
               ||l_offices(i).reports_to_office
               ||'"}');
         end loop;
         cwms_util.append(l_data, ']}}');
      else
         cwms_err.raise('ERROR', p_format||' must be ''tab'', ''csv'', ''xml'', or ''json''');
      end case;
      l_ts2 := systimestamp;
      l_elapsed_format := l_ts2 - l_ts1;

      declare
         l_data2 clob;
         l_name  varchar2(32767);
      begin
         dbms_lob.createtemporary(l_data2, true);
         l_name := cwms_util.get_db_name;
         case
         when l_format = 'xml' then
            cwms_util.append(
               l_data2,
               '<query-info><time-of-query>'
               ||to_char(l_query_time, 'yyyy-mm-dd"T"hh24:mi:ss')
               ||'Z</time-of-query><process-query>'
               ||iso_duration(l_elapsed_query)
               ||'</process-query><format-output>'
               ||iso_duration(l_elapsed_format)
               ||'</format-output><requested-format>'
               ||upper(l_format)
               ||'</requested-format><offices-retrieved>'
               ||l_offices.count
               ||'</offices-retrieved></query-info>');
            l_data := regexp_replace(l_data, '^((<\?xml .+?\?>)?(<offices>))', '\1'||l_data2, 1, 1);
         when l_format = 'json' then
            cwms_util.append(
               l_data2,
               '{"query-info":{"time-of-query":"'
               ||to_char(l_query_time, 'yyyy-mm-dd"T"hh24:mi:ss')
               ||'Z","process-query":"'
               ||iso_duration(l_elapsed_query)
               ||'","format-output":"'
               ||iso_duration(l_elapsed_format)
               ||'","requested-format":"'
               ||upper(l_format)
               ||'","locations-retrieved":'
               ||l_offices.count
               ||'}');
            l_data := regexp_replace(l_data, '\{("offices":\[)', l_data2||',\1', 1, 1);
         when l_format in ('tab', 'csv') then
            cwms_util.append(l_data2, '#Time Of Query'    ||l_tab||to_char(l_query_time, 'dd-Mon-yyyy hh24:mi')||' UTC'||l_nl);
            cwms_util.append(l_data2, '#Process Query'    ||l_tab||trunc(1000 * (extract(minute from l_elapsed_query) * 60 + extract(second from l_elapsed_query)))||' Milliseconds'||l_nl);
            cwms_util.append(l_data2, '#Format Output'    ||l_tab||trunc(1000 * (extract(minute from l_elapsed_format) * 60 + extract(second from l_elapsed_format)))||' Milliseconds'||l_nl);
            cwms_util.append(l_data2, '#Requested Format' ||l_tab||upper(l_format)||l_nl);
            cwms_util.append(l_data2, '#Offices Retrieved'||l_tab||l_offices.count||l_nl||l_nl);
            if l_format = 'csv' then
               l_data2 := cwms_util.tab_to_csv(l_data2);
            end if;
            l_data := regexp_replace(l_data, '^', l_data2, 1, 1);
         end case;
      end;

      return l_data;
   end retrieve_offices_f;

   procedure retrieve_time_zones(
      p_time_zones out clob,
      p_format     in  varchar2)
   is
   begin
      p_time_zones := retrieve_time_zones_f(p_format);
   end retrieve_time_zones;

   function retrieve_time_zones_f(
      p_format in varchar2)
      return clob
   is
      type rec_t is record(time_zone_name varchar2(28), utc_offset varchar2(6), dst_offset varchar2(6));
      type tab_t is table of rec_t;
      l_format         varchar2(16) := lower(trim(p_format));
      l_time_zones     tab_t;
      l_data           clob;
      l_tab            varchar2(1) := chr(9);
      l_nl             varchar2(1) := chr(10);
      l_ts1            timestamp;
      l_ts2            timestamp;
      l_query_time     date;
      l_elapsed_query  interval day (0) to second (6);
      l_elapsed_format interval day (0) to second (6);

   begin
      l_query_time := sysdate;
      l_ts1 := systimestamp;
      select time_zone_name,
             to_char(extract(hour from utc_offset), 'S09')||':'||trim(to_char(abs(extract(minute from utc_offset)), '09')) as utc_offset,
             to_char(extract(hour from dst_offset), 'S09')||':'||trim(to_char(abs(extract(minute from dst_offset)), '09')) as dst_offset
        bulk collect
        into l_time_zones
        from (select time_zone_name,
                     utc_offset,
                     dst_offset
                from cwms_time_zone
               where time_zone_code > 0
                 and time_zone_name not in (select time_zone_alias from cwms_time_zone_alias)
              union all
              select time_zone_alias as time_zone_name,
                     utc_offset,
                     dst_offset
                from cwms_time_zone tz,
                     cwms_time_zone_alias tza
               where tz.time_zone_name = tza.time_zone_name
             )
       order by time_zone_name;
      l_ts2 := systimestamp;
      l_elapsed_query := l_ts2 - l_ts1;
      l_ts1 := systimestamp;
      dbms_lob.createtemporary(l_data, true);
      case
      when l_format in ('tab', 'csv') then
         ----------------
         -- TAB or CSV --
         ----------------
         cwms_util.append(l_data, '#Time Zone Name'||l_tab||'Utc Offset'||l_tab||'Dst Offset'||l_nl);
         for i in 1..l_time_zones.count loop
            cwms_util.append(
               l_data,
               l_time_zones(i).time_zone_name ||l_tab
               ||l_time_zones(i).utc_offset   ||l_tab
               ||l_time_zones(i).dst_offset   ||l_nl);
         end loop;
         if l_format = 'csv' then
            l_data := cwms_util.tab_to_csv(l_data);
         end if;
      when l_format = 'xml' then
         ---------
         -- XML --
         ---------
         cwms_util.append(l_data, '<?xml version="1.0" encoding="windows-1252"?><time-zones>');
         for i in 1..l_time_zones.count loop
            cwms_util.append(
               l_data,
               '<time-zone><name>'
               ||l_time_zones(i).time_zone_name||'</name><utc-offset>'
               ||l_time_zones(i).utc_offset||'</utc-offset><dst-offset>'
               ||l_time_zones(i).dst_offset||'</dst-offset>'
               ||'</time-zone>');
         end loop;
         cwms_util.append(l_data, '</time-zones>');
      when l_format = 'json' then
         ----------
         -- JSON --
         ----------
         cwms_util.append(l_data, '{"time-zones":{"time-zones":[');
         for i in 1..l_time_zones.count loop
            cwms_util.append(
               l_data,
               case i when 1 then '{"name":"' else ',{"name":"' end
               ||l_time_zones(i).time_zone_name
               ||'","utc-offset":"'
               ||l_time_zones(i).utc_offset
               ||'","dst-offset":"'
               ||l_time_zones(i).dst_offset
               ||'"}');
         end loop;
         cwms_util.append(l_data, ']}}');
      else
         cwms_err.raise('ERROR', p_format||' must be ''tab'', ''xml'', or ''json''');
      end case;
      l_ts2 := systimestamp;
      l_elapsed_format := l_ts2 - l_ts1;

      declare
         l_data2 clob;
         l_name  varchar2(32767);
      begin
         dbms_lob.createtemporary(l_data2, true);
         l_name := cwms_util.get_db_name;
         case
         when l_format = 'xml' then
            cwms_util.append(
               l_data2,
               '<query-info><time-of-query>'
               ||to_char(l_query_time, 'yyyy-mm-dd"T"hh24:mi:ss')
               ||'Z</time-of-query><process-query>'
               ||iso_duration(l_elapsed_query)
               ||'</process-query><format-output>'
               ||iso_duration(l_elapsed_format)
               ||'</format-output><requested-format>'
               ||upper(l_format)
               ||'</requested-format><time-zones-retrieved>'
               ||l_time_zones.count
               ||'</time-zones-retrieved></query-info>');
            l_data := regexp_replace(l_data, '^((<\?xml .+?\?>)?(<time-zones>))', '\1'||l_data2, 1, 1);
         when l_format = 'json' then
            cwms_util.append(
               l_data2,
               '{"query-info":"time-of-query":"'
               ||to_char(l_query_time, 'yyyy-mm-dd"T"hh24:mi:ss')
               ||'Z","process-query":"'
               ||iso_duration(l_elapsed_query)
               ||'","format-output":"'
               ||iso_duration(l_elapsed_format)
               ||'","requested-format":"'
               ||upper(l_format)
               ||'","time-zones-retrieved":'
               ||l_time_zones.count
               ||'}');
            l_data := regexp_replace(l_data, '\{("time-zones":\[)', l_data2||',\1', 1, 1);
         when l_format in ('tab', 'csv') then
            cwms_util.append(l_data2, '#Time Of Query'       ||l_tab||to_char(l_query_time, 'dd-Mon-yyyy hh24:mi')||' UTC'||l_nl);
            cwms_util.append(l_data2, '#Process Query'       ||l_tab||trunc(1000 * (extract(minute from l_elapsed_query) * 60 + extract(second from l_elapsed_query)))||' Milliseconds'||l_nl);
            cwms_util.append(l_data2, '#Format Output'       ||l_tab||trunc(1000 * (extract(minute from l_elapsed_format) * 60 + extract(second from l_elapsed_format)))||' Milliseconds'||l_nl);
            cwms_util.append(l_data2, '#Requested Format'    ||l_tab||upper(l_format)||l_nl);
            cwms_util.append(l_data2, '#Time Zones Retrieved'||l_tab||l_time_zones.count||l_nl||l_nl);
            if l_format = 'csv' then
               l_data2 := cwms_util.tab_to_csv(l_data2);
            end if;
            l_data := regexp_replace(l_data, '^', l_data2, 1, 1);
         end case;
      end;
      return l_data;
   end retrieve_time_zones_f;

   procedure retrieve_units(
      p_units  out clob,
      p_format in  varchar2)
   is
   begin
      p_units := retrieve_units_f(p_format);
   end retrieve_units;

   function retrieve_units_f(
      p_format in varchar2)
      return clob
   is
      type unit_rec_t is record(
         abstract_param varchar2(32),
         code integer,
         name varchar2(32),
         unit_system varchar2(5),
         long_name varchar2(80),
         description varchar2(80));
      type unit_tab_t is table of unit_rec_t;
      type alternates_t is table of str_tab_t index by varchar2(16);
      l_format         varchar2(16) := lower(trim(p_format));
      l_units          unit_tab_t;
      l_names_by_code  alternates_t;
      l_alt_names      str_tab_t;
      l_data           clob;
      l_tab            varchar2(1) := chr(9);
      l_nl             varchar2(1) := chr(10);
      l_ts1            timestamp;
      l_ts2            timestamp;
      l_query_time     date;
      l_elapsed_query  interval day (0) to second (6);
      l_elapsed_format interval day (0) to second (6);
      l_code_str       varchar2(16);

   begin
      l_query_time := sysdate;
      l_ts1 := systimestamp;
      select abstract_param_id,
             unit_code,
             unit_id,
             nvl(unit_system, 'SI+EN'),
             long_name,
             description
        bulk collect
        into l_units
        from cwms_abstract_parameter ap,
             (select abstract_param_code,
                     unit_code,
                     unit_id,
                     unit_system,
                     long_name,
                     description
                from cwms_unit
              union all
              select cu.abstract_param_code,
                     cu.unit_code,
                     ca.alias_id as unit_id,
                     cu.unit_system,
                     cu.long_name,
                     cu.description
                from cwms_unit cu,
                     at_unit_alias ca
               where cu.unit_code = ca.unit_code
                 and ca.db_office_code = 53
             ) u
       where ap.abstract_param_code = u.abstract_param_code
       order by abstract_param_id,
                upper(unit_id);

      for i in 1..l_units.count loop
         l_code_str := to_char(l_units(i).code);
         if not l_names_by_code.exists(l_code_str) then
            l_names_by_code(l_code_str) := str_tab_t();
         end if;
            l_names_by_code(l_code_str).extend;
            l_names_by_code(l_code_str)(l_names_by_code(l_code_str).count) := l_units(i).name;
      end loop;

      l_ts2 := systimestamp;
      l_elapsed_query := l_ts2 - l_ts1;
      l_ts1 := systimestamp;
      dbms_lob.createtemporary(l_data, true);
      case
      when l_format in ('tab', 'csv') then
         ----------------
         -- TAB or CSV --
         ----------------
         cwms_util.append(l_data, '#Abstract Parameter'||l_tab||'Name'||l_tab||'Unit System'||l_tab||'Long Name'||l_tab||'Description'||l_tab||'Alternate Names'||l_nl);
         for i in 1..l_units.count loop
            cwms_util.append(
               l_data,
               l_units(i).abstract_param ||l_tab
               ||l_units(i).name         ||l_tab
               ||l_units(i).unit_system  ||l_tab
               ||l_units(i).long_name    ||l_tab
               ||l_units(i).description);
            l_code_str := to_char(l_units(i).code);
            if l_names_by_code(l_code_str).count > 1 then
               select column_value
                 bulk collect
                 into l_alt_names
                 from table(l_names_by_code(l_code_str))
                where column_value != l_units(i).name;
               cwms_util.append(l_data, l_tab||cwms_util.join_text(l_alt_names, l_tab));
            end if;
            cwms_util.append(l_data, l_nl);
         end loop;
         if l_format = 'csv' then
            l_data := cwms_util.tab_to_csv(l_data);
         end if;
      when l_format = 'xml' then
         ---------
         -- XML --
         ---------
			cwms_util.append(l_data, '<?xml version="1.0" encoding="windows-1252"?><units>');
         for i in 1..l_units.count loop
            cwms_util.append(
               l_data,
               '<unit><abstract-parameter>'
               ||l_units(i).abstract_param ||'</abstract-parameter><name>'
               ||l_units(i).name           ||'</name><unit-system>'
               ||l_units(i).unit_system    ||'</unit-system><long-name>'
               ||l_units(i).long_name      ||'</long-name><description>'
               ||l_units(i).description    ||'</description><alternate-names>');
            l_code_str := to_char(l_units(i).code);
            if l_names_by_code(l_code_str).count > 1 then
               select column_value
                 bulk collect
                 into l_alt_names
                 from table(l_names_by_code(l_code_str))
                where column_value != l_units(i).name;
               cwms_util.append(
                  l_data,
                  '<name>'
                  ||cwms_util.join_text(l_alt_names, '</name><name>')
                  ||'</name>');
            end if;
            cwms_util.append(l_data, '</alternate-names></unit>');
         end loop;
         cwms_util.append(l_data, '</units>');
      when l_format = 'json' then
         ----------
         -- JSON --
         ----------
         cwms_util.append(l_data, '{"units":{"units":[');
         for i in 1..l_units.count loop
            cwms_util.append(
               l_data,
               case i
               when 1 then '{"abstract-parameter":"' else ',{"abstract-parameter":"' end
               ||l_units(i).abstract_param
               ||'","name":"'
               ||l_units(i).name
               ||'","unit-system":"'
               ||l_units(i).unit_system
               ||'","long-name":"'
               ||l_units(i).long_name
               ||'","description":"'
               ||l_units(i).description
               ||'","alternate-names":[');
            l_code_str := to_char(l_units(i).code);
            if l_names_by_code(l_code_str).count > 1 then
               select column_value
                 bulk collect
                 into l_alt_names
                 from table(l_names_by_code(l_code_str))
                where column_value != l_units(i).name;
               cwms_util.append(
                  l_data,
                  '"'
                  ||cwms_util.join_text(l_alt_names, '","')
                  ||'"');
            end if;
            cwms_util.append(l_data, ']}');
         end loop;
         cwms_util.append(l_data, ']}}');
      else
         cwms_err.raise('ERROR', p_format||' must be ''tab'', ''xml'', or ''json''');
      end case;
      l_ts2 := systimestamp;
      l_elapsed_format := l_ts2 - l_ts1;

      declare
         l_data2 clob;
         l_name  varchar2(32767);
      begin
         dbms_lob.createtemporary(l_data2, true);
         l_name := cwms_util.get_db_name;
         case
         when l_format = 'xml' then
            cwms_util.append(
               l_data2,
               '<query-info><time-of-query>'
               ||to_char(l_query_time, 'yyyy-mm-dd"T"hh24:mi:ss')
               ||'Z</time-of-query><process-query>'
               ||iso_duration(l_elapsed_query)
               ||'</process-query><format-output>'
               ||iso_duration(l_elapsed_format)
               ||'</format-output><requested-format>'
               ||upper(l_format)
               ||'</requested-format><total-units-retrieved>'
               ||l_units.count
               ||'</total-units-retrieved><unique-units-retrieved>'
               ||l_names_by_code.count
               ||'</unique-units-retrieved></query-info>');
				l_data := regexp_replace(l_data, '^((<\?xml .+?\?>)?(<units>))', '\1'||l_data2, 1, 1);
         when l_format = 'json' then
            cwms_util.append(
               l_data2,
               '{"query-info":{"time-of-query":"'
               ||to_char(l_query_time, 'yyyy-mm-dd"T"hh24:mi:ss')
               ||'Z","process-query":"'
               ||iso_duration(l_elapsed_query)
               ||'","format-output":"'
               ||iso_duration(l_elapsed_format)
               ||'","requested-format":"'
               ||upper(l_format)
               ||'","total-units-retrieved":'
               ||l_units.count
               ||',"unique-units-retrieved":'
               ||l_names_by_code.count
               ||'}');
            l_data := regexp_replace(l_data, '\{"units":\[', l_data2||','||'"units":[', 1, 1);
         when l_format in ('tab', 'csv') then
            cwms_util.append(l_data2, '#Time Of Query'         ||l_tab||to_char(l_query_time, 'dd-Mon-yyyy hh24:mi')||' UTC'||l_nl);
            cwms_util.append(l_data2, '#Process Query'         ||l_tab||trunc(1000 * (extract(minute from l_elapsed_query) * 60 + extract(second from l_elapsed_query)))||' Milliseconds'||l_nl);
            cwms_util.append(l_data2, '#Format Output'         ||l_tab||trunc(1000 * (extract(minute from l_elapsed_format) * 60 + extract(second from l_elapsed_format)))||' Milliseconds'||l_nl);
            cwms_util.append(l_data2, '#Requested Format'      ||l_tab||upper(l_format)||l_nl);
            cwms_util.append(l_data2, '#Total Units Retrieved' ||l_tab||l_units.count||l_nl);
            cwms_util.append(l_data2, '#Unique Units Retrieved'||l_tab||l_names_by_code.count||l_nl||l_nl);
            if l_format = 'csv' then
               l_data2 := cwms_util.tab_to_csv(l_data2);
            end if;
            l_data := regexp_replace(l_data, '^', l_data2, 1, 1);
         end case;
      end;
      return l_data;
   end retrieve_units_f;

   procedure retrieve_parameters(
      p_parameters out clob,
      p_format     in  varchar2)
   is
   begin
      p_parameters := retrieve_parameters_f(p_format);
   end retrieve_parameters;

   function retrieve_parameters_f(
      p_format in varchar2)
      return clob
   is
      type rec_t is record(
         abstract_param varchar2(32),
         base_param     varchar2(16),
         sub_param      varchar2(32),
         office         varchar2(16),
         en_unit        varchar2(16),
         si_unit        varchar2(16),
         long_name      varchar2(80),
         description varchar2(160));
      type tab_t is table of rec_t;
      l_format         varchar2(16) := lower(trim(p_format));
      l_params         tab_t;
      l_data           clob;
      l_tab            varchar2(1) := chr(9);
      l_nl             varchar2(1) := chr(10);
      l_ts1            timestamp;
      l_ts2            timestamp;
      l_query_time     date;
      l_elapsed_query  interval day (0) to second (6);
      l_elapsed_format interval day (0) to second (6);

   begin
      l_query_time := sysdate;
      l_ts1 := systimestamp;
      select abstract_param_id,
             base_parameter_id,
             sub_parameter_id,
             office,
             en_unit,
             si_unit,
             long_name,
             description
        bulk collect
        into l_params
        from (select ap.abstract_param_id,
                     bp.base_parameter_id,
                     null as sub_parameter_id,
                     'All' as office,
                     u1.unit_id as en_unit,
                     u2.unit_id as si_unit,
                     bp.long_name,
                     bp.description
                from cwms_abstract_parameter ap,
                     cwms_base_parameter bp,
                     cwms_unit u1,
                     cwms_unit u2
               where ap.abstract_param_code = bp.abstract_param_code
                 and u1.unit_code = bp.display_unit_code_en
                 and u2.unit_code = bp.display_unit_code_si
              union all
              select ap.abstract_param_id,
                     bp.base_parameter_id,
                     p.sub_parameter_id,
                     replace(o.office_id, 'CWMS', 'All') as office,
                     u1.unit_id as en_unit,
                     u2.unit_id as si_unit,
                     bp.long_name,
                     case
                     when p.sub_parameter_desc is null then bp.description||'-'||p.sub_parameter_id
                     else p.sub_parameter_desc
                     end as description
                from at_parameter p,
                     cwms_abstract_parameter ap,
                     cwms_base_parameter bp,
                     cwms_unit u1,
                     cwms_unit u2,
                     cwms_office o
               where p.sub_parameter_id is not null
                 and bp.base_parameter_code = p.base_parameter_code
                 and ap.abstract_param_code = bp.abstract_param_code
                 and u1.unit_code = bp.display_unit_code_en
                 and u2.unit_code = bp.display_unit_code_si
                 and o.office_code = p.db_office_code
            )
       order by abstract_param_id,
                base_parameter_id,
                sub_parameter_id nulls first,
                office;
      l_ts2 := systimestamp;
      l_elapsed_query := l_ts2 - l_ts1;
      l_ts1 := systimestamp;
      dbms_lob.createtemporary(l_data, true);
      case
      when l_format in ('tab', 'csv') then
         ----------------
         -- TAB or CSV --
         ----------------
         cwms_util.append(l_data, '#Abstract Parameter'||l_tab||'Parameter'||l_tab||'Office'||l_tab||'Default English Unit'||l_tab||'Default SI Unit'||l_tab||'Long Name'||l_tab||'Description'||l_nl);
         for i in 1..l_params.count loop
            cwms_util.append(
               l_data,
               l_params(i).abstract_param ||l_tab
               ||l_params(i).base_param
               ||substr('-', 1, length(l_params(i).sub_param))
               ||l_params(i).sub_param    ||l_tab
               ||l_params(i).office       ||l_tab
               ||l_params(i).en_unit      ||l_tab
               ||l_params(i).si_unit      ||l_tab
               ||l_params(i).long_name    ||l_tab
               ||l_params(i).description  ||l_nl);
         end loop;
         if l_format = 'csv' then
            l_data := cwms_util.tab_to_csv(l_data);
         end if;
      when l_format = 'xml' then
         ---------
         -- XML --
         ---------
			cwms_util.append(l_data, '<?xml version="1.0" encoding="windows-1252"?><parameters>');
         for i in 1..l_params.count loop
            cwms_util.append(
               l_data,
               '<parameter><abstract-parameter>'
               ||l_params(i).abstract_param ||'</abstract-parameter><name>'
               ||l_params(i).base_param
               ||substr('-', 1, length(l_params(i).sub_param))
               ||l_params(i).sub_param      ||'</name><office>'
               ||l_params(i).office         ||'</office><default-english-unit>'
               ||l_params(i).en_unit        ||'</default-english-unit><default-si-unit>'
               ||l_params(i).si_unit        ||'</default-si-unit><long-name>'
               ||l_params(i).long_name      ||'</long-name><description>'
               ||l_params(i).description    ||'</description>'
               ||'</parameter>');
         end loop;
         cwms_util.append(l_data, '</parameters>');
      when l_format = 'json' then
         ----------
         -- JSON --
         ----------
         cwms_util.append(l_data, '{"parameters":{"parameters":[');
         for i in 1..l_params.count loop
            cwms_util.append(
               l_data,
               case i when 1 then '{"abstract-param":"' else ',{"abstract-param":"' end
               ||l_params(i).abstract_param
               ||'","name":"'
               ||l_params(i).base_param
               ||substr('-', 1, length(l_params(i).sub_param))
               ||l_params(i).sub_param
               ||'","office":"'
               ||l_params(i).office
               ||'","default-english-unit":"'
               ||l_params(i).en_unit
               ||'","default-si-unit":"'
               ||l_params(i).en_unit
               ||'","long-name":"'
               ||l_params(i).long_name
               ||'","description":"'
               ||l_params(i).description
               ||'"}');
         end loop;
         cwms_util.append(l_data,']}}');
      else
         cwms_err.raise('ERROR', p_format||' must be ''tab'', ''xml'', or ''json''');
      end case;
      l_ts2 := systimestamp;
      l_elapsed_format := l_ts2 - l_ts1;

      declare
         l_data2 clob;
         l_name  varchar2(32767);
      begin
         dbms_lob.createtemporary(l_data2, true);
         l_name := cwms_util.get_db_name;
         case
         when l_format = 'xml' then
            cwms_util.append(
               l_data2,
               '<query-info><time-of-query>'
               ||to_char(l_query_time, 'yyyy-mm-dd"T"hh24:mi:ss')
               ||'Z</time-of-query> <process-query>'
               ||iso_duration(l_elapsed_query)
               ||'</process-query><format-output>'
               ||iso_duration(l_elapsed_format)
               ||'</format-output><requested-format>'
               ||upper(l_format)
               ||'</requested-format><parameters-retrieved>'
               ||l_params.count
               ||'</parameters-retrieved></query-info>');
				l_data := regexp_replace(l_data, '^((<\?xml .+?\?>)?(<parameters>))', '\1'||l_data2, 1, 1);
         when l_format = 'json' then
            cwms_util.append(
               l_data2,
               '{"query-info":{"time-of-query":"'
               ||to_char(l_query_time, 'yyyy-mm-dd"T"hh24:mi:ss')
               ||'Z","process-query":"'
               ||iso_duration(l_elapsed_query)
               ||'","format-output":"'
               ||iso_duration(l_elapsed_format)
               ||'","requested-format":"'
               ||upper(l_format)
               ||'","parameters-retrieved":'
               ||l_params.count
               ||'}');
            l_data := regexp_replace(l_data, '\{("parameters":\[)', l_data2||',\1', 1, 1);
         when l_format in ('tab', 'csv') then
            cwms_util.append(l_data2, '#Time Of Query'        ||l_tab||to_char(l_query_time, 'dd-Mon-yyyy hh24:mi')||' UTC'||l_nl);
            cwms_util.append(l_data2, '#Process Query'        ||l_tab||trunc(1000 * (extract(minute from l_elapsed_query) * 60 + extract(second from l_elapsed_query)))||' Milliseconds'||l_nl);
            cwms_util.append(l_data2, '#Format Output'        ||l_tab||trunc(1000 * (extract(minute from l_elapsed_format) * 60 + extract(second from l_elapsed_format)))||' Milliseconds'||l_nl);
            cwms_util.append(l_data2, '#Requested Format'     ||l_tab||upper(l_format)||l_nl);
            cwms_util.append(l_data2, '#Parameters Retrieved' ||l_tab||l_params.count||l_nl||l_nl);
            if l_format = 'csv' then
               l_data2 := cwms_util.tab_to_csv(l_data2);
            end if;
            l_data := regexp_replace(l_data, '^', l_data2, 1, 1);
         end case;
      end;
      return l_data;
   end retrieve_parameters_f;

END cwms_cat;
/

SHOW errors;
