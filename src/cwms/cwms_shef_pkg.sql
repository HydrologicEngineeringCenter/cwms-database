/* Formatted on 2008/02/07 10:21 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE cwms_20.cwms_shef
AS
-- PROCEDURE clean_at_shef_crit_file p_action constants.
   ten_file_limit   CONSTANT VARCHAR2 (32) := 'TEN FILE LIMIT';
   -- default value.
   delete_all       CONSTANT VARCHAR2 (32) := 'DELETE ALL';

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

   TYPE cat_shef_dur_rec_t IS RECORD (
      shef_duration_code      VARCHAR2 (1),
      shef_duration_desc      VARCHAR2 (128),
      shef_duration_numeric   VARCHAR2 (4)
   );

   TYPE cat_shef_dur_tab_t IS TABLE OF cat_shef_dur_rec_t;

   TYPE cat_shef_units_rec_t IS RECORD (
      shef_unit_id   VARCHAR2 (16)
   );

   TYPE cat_shef_units_tab_t IS TABLE OF cat_shef_units_rec_t;

   TYPE cat_shef_crit_lines_rec_t IS RECORD (
      shef_crit_line   VARCHAR2 (400)
   );

   TYPE cat_shef_crit_lines_tab_t IS TABLE OF cat_shef_crit_lines_rec_t;

   PROCEDURE update_shef_spec (
      p_cwms_ts_id              IN   VARCHAR2,
      p_data_stream_id          IN   VARCHAR2,
      p_loc_group_id            IN   VARCHAR2,
      p_shef_loc_id             IN   VARCHAR2 DEFAULT NULL,
      -- normally use loc_group_id
      p_shef_pe_code            IN   VARCHAR2,
      p_shef_tse_code           IN   VARCHAR2,
      p_shef_duration_code      IN   VARCHAR2,
      -- e.g., V5002 or simply L     -
      p_shef_unit_id            IN   VARCHAR2,
      p_time_zone_id            IN   VARCHAR2,
      p_daylight_savings        IN   VARCHAR2 DEFAULT 'F',  -- psuedo boolean.
      p_interval_utc_offset     IN   NUMBER DEFAULT NULL,       -- in minutes.
      p_snap_forward_minutes    IN   NUMBER DEFAULT NULL,
      p_snap_backward_minutes   IN   NUMBER DEFAULT NULL,
      p_ts_active_flag          IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id            IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE store_shef_spec (
      p_cwms_ts_id              IN   VARCHAR2,
      p_data_stream_id          IN   VARCHAR2,
      p_loc_group_id            IN   VARCHAR2,
      p_shef_loc_id             IN   VARCHAR2 DEFAULT NULL,
      -- normally use loc_group_id
      p_shef_pe_code            IN   VARCHAR2,
      p_shef_tse_code           IN   VARCHAR2,
      p_shef_duration_code      IN   VARCHAR2,
      -- e.g., V5002 or simply L     -
      p_shef_unit_id            IN   VARCHAR2,
      p_time_zone_id            IN   VARCHAR2,
      p_daylight_savings        IN   VARCHAR2 DEFAULT 'F',  -- psuedo boolean.
      p_interval_utc_offset     IN   NUMBER DEFAULT NULL,       -- in minutes.
      p_snap_forward_minutes    IN   NUMBER DEFAULT NULL,
      p_snap_backward_minutes   IN   NUMBER DEFAULT NULL,
      p_ts_active_flag          IN   VARCHAR2 DEFAULT 'T',
      p_update_allowed          IN   VARCHAR2 DEFAULT 'T',
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

   PROCEDURE delete_data_stream_shef_specs (
      p_data_stream_id   IN   VARCHAR2,
      p_db_office_id     IN   VARCHAR2 DEFAULT NULL
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

   FUNCTION cat_shef_durations_tab
      RETURN cat_shef_dur_tab_t PIPELINED;

   FUNCTION cat_shef_units_tab
      RETURN cat_shef_units_tab_t PIPELINED;

   FUNCTION get_shef_duration_numeric (p_shef_duration_code IN VARCHAR2)
      RETURN VARCHAR2;

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

   PROCEDURE cat_shef_crit_lines (
      p_shef_crit_lines   OUT      sys_refcursor,
      p_data_stream_id    IN       VARCHAR2,
      p_db_office_id      IN       VARCHAR2 DEFAULT NULL
   );

   FUNCTION cat_shef_crit_lines_tab (
      p_data_stream_id   IN   VARCHAR2,
      p_db_office_id     IN   VARCHAR2 DEFAULT NULL
   )
      RETURN cat_shef_crit_lines_tab_t PIPELINED;

   PROCEDURE store_shef_crit_file (
      p_data_stream_id   IN   VARCHAR2,
      p_db_office_id     IN   VARCHAR2 DEFAULT NULL
   );

   FUNCTION get_data_stream_code (
      p_data_stream_id   IN   VARCHAR2,
      p_db_office_id     IN   VARCHAR2 DEFAULT NULL
   )
      RETURN NUMBER;

   FUNCTION is_data_stream_active (
      p_data_stream_id   IN   VARCHAR2,
      p_db_office_id     IN   VARCHAR2 DEFAULT NULL
   )
      RETURN BOOLEAN;
END cwms_shef;
/