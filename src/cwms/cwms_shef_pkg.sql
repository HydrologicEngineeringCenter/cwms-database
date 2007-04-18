/* Formatted on 2007/04/18 06:07 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE cwms_shef
AS
   TYPE cat_shef_tz_rec_t IS RECORD (
      shef_time_zone_id     VARCHAR2 (16),
      shef_time_zone_desc   VARCHAR2 (64)
   );

   TYPE cat_shef_tz_tab_t IS TABLE OF cat_shef_tz_rec_t;

   PROCEDURE store_shef_spec (
      p_cwms_ts_id              IN   VARCHAR2,
      p_data_stream_id          IN   VARCHAR2,
      p_shef_pe_code            IN   VARCHAR2,
      p_shef_duration_code      IN   VARCHAR2,
      p_shef_tse_code           IN   VARCHAR2,
      p_shef_unit_id            IN   VARCHAR2,
      p_time_zone_id            IN   VARCHAR2,
      p_daylight_savings        IN   VARCHAR2 DEFAULT 'F',  -- psuedo boolean.
      p_snap_forward_minutes    IN   NUMBER,
      p_snap_backward_minutes   IN   NUMBER,
      p_loc_category_id         IN   VARCHAR2,
      p_loc_group_id            IN   VARCHAR2,
      p_interval_utc_offset     IN   NUMBER,                    -- in minutes.
      p_ts_active_flag          IN   VARCHAR2 DEFAULT 'T',
      p_permit_multiple_specs   IN   VARCHAR2 DEFAULT 'F',
      p_db_office_id            IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE delete_shef_spec (
      p_cwms_ts_id       IN   VARCHAR2,
      p_data_stream_id   IN   VARCHAR2,
      p_db_office_id     IN   VARCHAR2 DEFAULT NULL
   );

-- left kernal must be unique.
   PROCEDURE store_data_stream (
      p_data_stream_id     IN   VARCHAR2,
      p_data_stream_desc   IN   VARCHAR2 DEFAULT NULL,
      p_active_flag        IN   VARCHAR2 DEFAULT 'T',
      p_ignore_nulls       IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id       IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE rename_data_stream (
      p_data_stream_id_old   IN   VARCHAR2,
      p_data_stream_id_new   IN   VARCHAR2,
      p_db_office_id         IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE delete_data_stream (
      p_data_stream_id   IN   VARCHAR2,
      p_cascade_all      IN   VARCHAR2 DEFAULT 'F',
      p_db_office_id     IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE cat_shef_time_zones (p_shef_time_zones OUT sys_refcursor);

   FUNCTION cat_shef_time_zones_tab
      RETURN cat_shef_tz_tab_t PIPELINED;
END cwms_shef;
/