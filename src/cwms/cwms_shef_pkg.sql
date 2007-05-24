/* Formatted on 2007/05/23 08:26 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE cwms_20.cwms_shef
AS
   TYPE cat_data_stream_rec_t IS RECORD (
      data_stream_code   NUMBER,
      data_stream_id     VARCHAR2 (16),
      data_stream_desc   VARCHAR2 (128),
      active_flag        VARCHAR2 (1),
      office_id          VARCHAR2 (16)
   );

   TYPE cat_data_stream_tab_t IS TABLE OF cat_data_stream_rec_t;

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

   PROCEDURE cat_shef_data_streams (
      p_shef_data_streams   OUT      sys_refcursor,
      p_db_office_id        IN       VARCHAR2 DEFAULT NULL
   );

   FUNCTION cat_shef_data_streams_tab (p_db_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN cat_data_stream_tab_t PIPELINED;

   PROCEDURE cat_shef_time_zones (p_shef_time_zones OUT sys_refcursor);

   FUNCTION cat_shef_time_zones_tab
      RETURN cat_shef_tz_tab_t PIPELINED;

   PROCEDURE parse_criteria_record (
      p_shef_id              OUT      VARCHAR2,
      p_shef_pe_code         OUT      VARCHAR2,
      p_shef_tse_code        OUT      VARCHAR2,
      p_shef_duration_code   OUT      VARCHAR2,
      p_units                OUT      VARCHAR2,
      p_unit_sys             OUT      VARCHAR2,
      p_tz                   OUT      VARCHAR2,
      p_dltime               OUT      VARCHAR2,
      p_int_offset           OUT      VARCHAR2,
      p_int_backward         OUT      VARCHAR2,
      p_int_forward          OUT      VARCHAR2,
      p_cwms_ts_id           OUT      VARCHAR2,
      p_comment              OUT      VARCHAR2,
      p_criteria_record      IN       VARCHAR2
   );
END cwms_shef;
/
