/* Formatted on 2007/05/27 10:56 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE cwms_ts
AS
   FUNCTION get_cwms_ts_id (p_cwms_ts_id IN VARCHAR2, p_office_id IN VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION get_db_unit_id (p_cwms_ts_id IN VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION get_time_on_after_interval (
      p_unsnapped_datetime   IN   DATE,
      p_ts_offset            IN   NUMBER,
      p_ts_interval          IN   NUMBER
   )
      RETURN DATE;

   FUNCTION get_time_on_before_interval (
      p_unsnapped_datetime   IN   DATE,
      p_ts_offset            IN   NUMBER,
      p_ts_interval          IN   NUMBER
   )
      RETURN DATE;

   FUNCTION get_parameter_code (
      p_base_parameter_id   IN   VARCHAR2,
      p_sub_parameter_id    IN   VARCHAR2,
      p_office_id           IN   VARCHAR2 DEFAULT NULL,
      p_create              IN   VARCHAR2 DEFAULT 'T'
   )
      RETURN NUMBER;

   FUNCTION get_parameter_code (
      p_base_parameter_code   IN   NUMBER,
      p_sub_parameter_id      IN   VARCHAR2,
      p_office_code           IN   NUMBER,
      p_create                IN   BOOLEAN DEFAULT TRUE
   )
      RETURN NUMBER;

   FUNCTION get_parameter_code (p_cwms_ts_code IN NUMBER)
      RETURN NUMBER;

   FUNCTION get_base_parameter_code (p_cwms_ts_code IN NUMBER)
      RETURN NUMBER;

   FUNCTION get_parameter_type_code (p_cwms_ts_code IN NUMBER)
      RETURN NUMBER;

   FUNCTION get_db_office_code (p_cwms_ts_code IN NUMBER)
      RETURN NUMBER;

   FUNCTION get_parameter_id (p_cwms_ts_code IN NUMBER)
      RETURN VARCHAR2;

   FUNCTION get_base_parameter_id (p_cwms_ts_code IN NUMBER)
      RETURN VARCHAR2;

   FUNCTION get_parameter_type_id (p_cwms_ts_code IN NUMBER)
      RETURN VARCHAR2;

   FUNCTION get_db_office_id (p_cwms_ts_code IN NUMBER)
      RETURN VARCHAR2;

   FUNCTION get_ts_ni_hash (
      p_parameter_code        IN   NUMBER,
      p_parameter_type_code   IN   NUMBER,
      p_duration_code         IN   NUMBER
   )
      RETURN VARCHAR2;

   FUNCTION create_ts_ni_hash (
      p_parameter_id        IN   VARCHAR2,
      p_parameter_type_id   IN   VARCHAR2,
      p_duration_id         IN   VARCHAR2,
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   )
      RETURN VARCHAR2;

--
--*******************************************************************   --
--*******************************************************************   --
--
-- DELETE_TS -
--
   PROCEDURE delete_ts (
      p_cwms_ts_id      IN   VARCHAR2,
      p_delete_action   IN   VARCHAR2 DEFAULT cwms_util.delete_ts_id,
      p_db_office_id    IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE delete_ts (
      p_cwms_ts_id       IN   VARCHAR2,
      p_delete_action    IN   VARCHAR2 DEFAULT cwms_util.delete_ts_id,
      p_db_office_code   IN   NUMBER DEFAULT NULL
   );

--
--*******************************************************************   --
--*******************************************************************   --
--
-- CREATE_TS -
--
--v 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvvvv -
   PROCEDURE create_ts (
      p_office_id    IN   VARCHAR2,
      p_cwms_ts_id   IN   VARCHAR2,
      p_utc_offset   IN   NUMBER DEFAULT NULL
   );

--
--*******************************************************************   --
--*******************************************************************   --
--
-- CREATE_TS -
--
   PROCEDURE create_ts (
      p_cwms_ts_id          IN   VARCHAR2,
      p_utc_offset          IN   NUMBER DEFAULT NULL,
      p_interval_forward    IN   NUMBER DEFAULT NULL,
      p_interval_backward   IN   NUMBER DEFAULT NULL,
      p_versioned           IN   VARCHAR2 DEFAULT 'F',
      p_active_flag         IN   VARCHAR2 DEFAULT 'T',
      p_office_id           IN   VARCHAR2 DEFAULT NULL
   );

--
--*******************************************************************   --
--*******************************************************************   --
--
-- CREATE_TS_CODE - v2.0 -
--
   PROCEDURE create_ts_code (
      p_ts_code             OUT      NUMBER,
      p_cwms_ts_id          IN       VARCHAR2,
      p_utc_offset          IN       NUMBER DEFAULT NULL,
      p_interval_forward    IN       NUMBER DEFAULT NULL,
      p_interval_backward   IN       NUMBER DEFAULT NULL,
      p_versioned           IN       VARCHAR2 DEFAULT 'F',
      p_active_flag         IN       VARCHAR2 DEFAULT 'T',
      p_fail_if_exists      IN       VARCHAR2 DEFAULT 'T',
      p_office_id           IN       VARCHAR2 DEFAULT NULL
   );

--
--*******************************************************************   --
--*******************************************************************   --
--
-- RETREIVE_TS -
--
--v 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvvvv -
   PROCEDURE retrieve_ts (
      p_at_tsv_rc     IN OUT   sys_refcursor,
      p_units         IN       VARCHAR2,
      p_officeid      IN       VARCHAR2,
      p_cwms_ts_id    IN       VARCHAR2,
      p_start_time    IN       DATE,
      p_end_time      IN       DATE,
      p_timezone      IN       VARCHAR2 DEFAULT 'GMT',
      p_trim          IN       NUMBER DEFAULT cwms_util.false_num,
      p_inclusive     IN       NUMBER DEFAULT NULL,
      p_versiondate   IN       DATE DEFAULT NULL,
      p_max_version   IN       NUMBER DEFAULT cwms_util.true_num
   );

--
--*******************************************************************   --
--*******************************************************************   --
--
-- RETREIVE_TS -
--
   PROCEDURE retrieve_ts (
      p_at_tsv_rc      IN OUT   sys_refcursor,
      p_units          IN       VARCHAR2,
      p_cwms_ts_id     IN       VARCHAR2,
      p_start_time     IN       DATE,
      p_end_time       IN       DATE,
      p_time_zone      IN       VARCHAR2 DEFAULT 'UTC',
      p_trim           IN       VARCHAR2 DEFAULT 'F',
      p_inclusive      IN       NUMBER DEFAULT NULL,
      p_version_date   IN       DATE DEFAULT NULL,
      p_max_version    IN       VARCHAR2 DEFAULT 'T',
      p_office_id      IN       VARCHAR2 DEFAULT NULL
   );

--
--*******************************************************************   --
--*******************************************************************   --
--
-- RETREIVE_TS_JAVA -
--
   PROCEDURE retrieve_ts_java (
      p_transaction_time   OUT      DATE,
      p_at_tsv_rc          OUT      sys_refcursor,
      p_units_out          OUT      VARCHAR2,
      p_cwms_ts_id_out     OUT      VARCHAR2,
      p_units_in           IN       VARCHAR2,
      p_cwms_ts_id_in      IN       VARCHAR2,
      p_start_time         IN       DATE,
      p_end_time           IN       DATE,
      p_time_zone          IN       VARCHAR2 DEFAULT 'UTC',
      p_trim               IN       VARCHAR2 DEFAULT 'F',
      p_inclusive          IN       NUMBER DEFAULT NULL,
      p_version_date       IN       DATE DEFAULT NULL,
      p_max_version        IN       VARCHAR2 DEFAULT 'T',
      p_office_id          IN       VARCHAR2 DEFAULT NULL
   );

--
--*******************************************************************   --
--*******************************************************************   --
--
-- STORE_TS -
--
--v 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvvvv -
   PROCEDURE store_ts (
      p_office_id         IN   VARCHAR2,
      p_cwms_ts_id        IN   VARCHAR2,
      p_units             IN   VARCHAR2,
      p_timeseries_data   IN   tsv_array,
      p_store_rule        IN   VARCHAR2 DEFAULT NULL,
      p_override_prot     IN   NUMBER DEFAULT cwms_util.false_num,
      p_versiondate       IN   DATE DEFAULT cwms_util.non_versioned
   );

--^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^^^^ -
--
--*******************************************************************   --
--*******************************************************************   --
--
-- STORE_TS -
--
   PROCEDURE store_ts (
      p_cwms_ts_id        IN   VARCHAR2,
      p_units             IN   VARCHAR2,
      p_timeseries_data   IN   tsv_array,
      p_store_rule        IN   VARCHAR2 DEFAULT NULL,
      p_override_prot     IN   VARCHAR2 DEFAULT 'F',
      p_version_date      IN   DATE DEFAULT cwms_util.non_versioned,
      p_office_id         IN   VARCHAR2 DEFAULT NULL
   );

--
--*******************************************************************   --
--*******************************************************************   --
--
   PROCEDURE update_ts (
      p_ts_code                  IN   NUMBER,
      p_interval_utc_offset      IN   NUMBER DEFAULT NULL,     -- in minutes.
      p_snap_forward_minutes     IN   NUMBER DEFAULT NULL,
      p_snap_backward_minutes    IN   NUMBER DEFAULT NULL,
      p_local_reg_time_zone_id   IN   VARCHAR2 DEFAULT NULL,
      p_ts_active_flag           IN   VARCHAR2 DEFAULT NULL
   );

--
--*******************************************************************   --
--*******************************************************************   --
--
-- RENAME_TS_JAVA -
--
--v 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvvvv -
   PROCEDURE rename_ts (
      p_office_id             IN   VARCHAR2,
      p_timeseries_desc_old   IN   VARCHAR2,
      p_timeseries_desc_new   IN   VARCHAR2
   );

--^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^^^^ -
--
   PROCEDURE rename_ts (
      p_cwms_ts_id_old   IN   VARCHAR2,
      p_cwms_ts_id_new   IN   VARCHAR2,
      p_utc_offset_new   IN   NUMBER DEFAULT NULL,
      p_office_id        IN   VARCHAR2 DEFAULT NULL
   );

--
--*******************************************************************   --
--*******************************************************************   --
--
-- PARSE_TS -
--
   PROCEDURE parse_ts (
      p_cwms_ts_id          IN       VARCHAR2,
      p_base_location_id    OUT      VARCHAR2,
      p_sub_location_id     OUT      VARCHAR2,
      p_base_parameter_id   OUT      VARCHAR2,
      p_sub_parameter_id    OUT      VARCHAR2,
      p_parameter_type_id   OUT      VARCHAR2,
      p_interval_id         OUT      VARCHAR2,
      p_duration_id         OUT      VARCHAR2,
      p_version_id          OUT      VARCHAR2
   );

   PROCEDURE zretrieve_ts (
      p_at_tsv_rc      IN OUT   sys_refcursor,
      p_units          IN       VARCHAR2,
      p_cwms_ts_id     IN       VARCHAR2,
      p_start_time     IN       DATE,
      p_end_time       IN       DATE,
      p_trim           IN       VARCHAR2 DEFAULT 'F',
      p_inclusive      IN       NUMBER DEFAULT NULL,
      p_version_date   IN       DATE DEFAULT NULL,
      p_max_version    IN       VARCHAR2 DEFAULT 'T',
      p_db_office_id   IN       VARCHAR2 DEFAULT NULL
   );

   PROCEDURE zretrieve_ts_java (
      p_transaction_time   OUT      DATE,
      p_at_tsv_rc          OUT      sys_refcursor,
      p_units_out          OUT      VARCHAR2,
      p_cwms_ts_id_out     OUT      VARCHAR2,
      p_units_in           IN       VARCHAR2,
      p_cwms_ts_id_in      IN       VARCHAR2,
      p_start_time         IN       DATE,
      p_end_time           IN       DATE,
      p_trim               IN       VARCHAR2 DEFAULT 'F',
      p_inclusive          IN       NUMBER DEFAULT NULL,
      p_version_date       IN       DATE DEFAULT NULL,
      p_max_version        IN       VARCHAR2 DEFAULT 'T',
      p_db_office_id       IN       VARCHAR2 DEFAULT NULL
   );
END;
/