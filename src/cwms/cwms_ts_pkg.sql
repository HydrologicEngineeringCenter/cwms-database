/* Formatted on 3/19/2010 5:18:28 AM (QP5 v5.139.911.3011) */
CREATE OR REPLACE PACKAGE cwms_ts
AS
   TYPE zts_rec_t IS RECORD (
      date_time      DATE,
      VALUE          BINARY_DOUBLE,
      quality_code   NUMBER
   );

   TYPE zts_tab_t IS TABLE OF zts_rec_t;

   TYPE number_array IS TABLE OF NUMBER
                           INDEX BY BINARY_INTEGER;

   TYPE double_array IS TABLE OF BINARY_DOUBLE
                           INDEX BY BINARY_INTEGER;

   FUNCTION get_max_open_cursors
      RETURN INTEGER;

   FUNCTION get_ts_code (p_cwms_ts_id        IN VARCHAR2,
                         p_db_office_code   IN NUMBER
                        )
      RETURN NUMBER;

   FUNCTION get_ts_code (p_cwms_ts_id      IN VARCHAR2,
                         p_db_office_id   IN VARCHAR2
                        )
      RETURN NUMBER;


   FUNCTION get_ts_id (p_ts_code IN NUMBER)
      RETURN VARCHAR2;

   FUNCTION get_cwms_ts_id (p_cwms_ts_id    IN VARCHAR2,
                            p_office_id    IN VARCHAR2
                           )
      RETURN VARCHAR2;

   FUNCTION get_db_unit_id (p_cwms_ts_id IN VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION get_time_on_after_interval (p_datetime      IN DATE,
                                        p_ts_offset     IN NUMBER,
                                        p_ts_interval   IN NUMBER
                                       )
      RETURN DATE;

   FUNCTION get_time_on_before_interval (p_datetime      IN DATE,
                                         p_ts_offset      IN NUMBER,
                                         p_ts_interval   IN NUMBER
                                        )
      RETURN DATE;

   FUNCTION get_parameter_code (
      p_base_parameter_id    IN VARCHAR2,
      p_sub_parameter_id    IN VARCHAR2,
      p_office_id           IN VARCHAR2 DEFAULT NULL,
      p_create              IN VARCHAR2 DEFAULT 'T'
   )
      RETURN NUMBER;

   FUNCTION get_display_parameter_code (p_base_parameter_id IN VARCHAR2,
      p_sub_parameter_id      IN VARCHAR2,
                                        p_office_id IN VARCHAR2 DEFAULT NULL
   )
      RETURN NUMBER;

   function get_display_parameter_code2(
      p_base_parameter_id in varchar2,
      p_sub_parameter_id  in varchar2,
      p_office_id         in varchar2 default null
   )  return number;
   
   FUNCTION get_parameter_code (p_base_parameter_code IN number,
                                p_sub_parameter_id IN varchar2,
                                p_office_code IN number,
                                p_create IN boolean DEFAULT TRUE
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

   --   FUNCTION get_ts_ni_hash (
   --  p_parameter_code   IN NUMBER,
   --  p_parameter_type_code IN NUMBER,
   --  p_duration_code   IN NUMBER
   --   )
   --  RETURN VARCHAR2;

   --   FUNCTION create_ts_ni_hash (
   --  p_parameter_id IN  VARCHAR2,
   --  p_parameter_type_id IN  VARCHAR2,
   --  p_duration_id  IN VARCHAR2,
   --  p_db_office_id IN  VARCHAR2 DEFAULT NULL
   --   )
   --  RETURN VARCHAR2;
   FUNCTION get_location_id (p_cwms_ts_id     IN VARCHAR2,
                             p_db_office_id    IN VARCHAR2
                            )
      RETURN VARCHAR2;

   FUNCTION get_location_id (p_cwms_ts_code IN NUMBER)
      RETURN VARCHAR2;

   --
   --******************************************************************* --
   --******************************************************************* --
   --
   -- DELETE_TS -
   --
   PROCEDURE delete_ts (
      p_cwms_ts_id      IN VARCHAR2,
      p_delete_action   IN VARCHAR2 DEFAULT cwms_util.delete_ts_id,
      p_db_office_id    IN VARCHAR2 DEFAULT NULL
   );

   PROCEDURE delete_ts (
      p_cwms_ts_id       IN VARCHAR2,
      p_delete_action    IN VARCHAR2,
      p_db_office_code    IN NUMBER
   ); 
   
   procedure purge_ts_data(
      p_ts_code          in number,
      p_version_date_utc in date,
      p_start_time_utc   in date,
      p_end_time_utc     in date);
   
   procedure change_version_date (
      p_ts_code              in number,
      p_old_version_date_utc in date,
      p_new_version_date_utc in date,
      p_start_time_utc       in date,
      p_end_time_utc         in date);

   --
   --******************************************************************* --
   --******************************************************************* --
   --
   -- SET_TS_TIME_ZONE -
   --
   PROCEDURE set_ts_time_zone (p_ts_code           IN NUMBER,
                               p_time_zone_name   IN VARCHAR2
                              );

   --
   --******************************************************************* --
   --******************************************************************* --
   --
   -- SET_TS_TIME_ZONE -
   --
   PROCEDURE set_tsid_time_zone (p_ts_id             IN VARCHAR2,
                                 p_time_zone_name    IN VARCHAR2,
                                 p_office_id        IN VARCHAR2 DEFAULT NULL
                                );

   --
   --******************************************************************* --
   --******************************************************************* --
   --
   -- GET_TS_TIME_ZONE -
   --
   FUNCTION get_ts_time_zone (p_ts_code IN NUMBER)
      RETURN VARCHAR2;

   --
   --******************************************************************* --
   --******************************************************************* --
   --
   -- GET_TS_TIME_ZONE -
   --
   FUNCTION get_tsid_time_zone (p_ts_id       IN VARCHAR2,
                                p_office_id    IN VARCHAR2 DEFAULT NULL
                               )
      RETURN VARCHAR2;

   --
   --******************************************************************* --
   
   procedure set_ts_versioned(
      p_cwms_ts_code in number,
      p_versioned    in varchar2 default 'T');
   
   procedure set_tsid_versioned(
      p_cwms_ts_id   in varchar2,
      p_versioned    in varchar2 default 'T',
      p_db_office_id in varchar2 default null);
      
   procedure is_ts_versioned(
      p_is_versioned out varchar2,
      p_cwms_ts_code in  number);
      
   procedure is_tsid_versioned(
      p_is_versioned out varchar2,
      p_cwms_ts_id   in  varchar2,
      p_db_office_id in  varchar2 default null);
      
   function is_tsid_versioned_f(
      p_cwms_ts_id   in varchar2,
      p_db_office_id in varchar2 default null)
      return varchar2;
      
   procedure get_ts_version_dates(
      p_date_cat     out sys_refcursor,
      p_cwms_ts_code in  number,
      p_start_time   in  date,
      p_end_time     in  date,
      p_time_zone    in  varchar2 default 'UTC');      
      
   procedure get_tsid_version_dates(
      p_date_cat     out sys_refcursor,
      p_cwms_ts_id   in  varchar2,
      p_start_time   in  date,
      p_end_time     in  date,
      p_time_zone    in  varchar2 default 'UTC',
      p_db_office_id in  varchar2 default null);      
   
   --******************************************************************* --
   --
   -- CREATE_TS -
   --
   --v 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvvvv -
   PROCEDURE create_ts (p_office_id    IN VARCHAR2,
                        p_cwms_ts_id   IN VARCHAR2,
                        p_utc_offset   IN NUMBER DEFAULT NULL
                       );

   --
   --******************************************************************* --
   --******************************************************************* --
   --
   -- CREATE_TS -
   --
   PROCEDURE create_ts (p_cwms_ts_id          IN VARCHAR2,
                        p_utc_offset          IN NUMBER DEFAULT NULL,
                        p_interval_forward    IN NUMBER DEFAULT NULL,
                        p_interval_backward    IN NUMBER DEFAULT NULL,
                        p_versioned           IN VARCHAR2 DEFAULT 'F',
                        p_active_flag          IN VARCHAR2 DEFAULT 'T',
                        p_office_id           IN VARCHAR2 DEFAULT NULL
                       );

   --
   --******************************************************************* --
   --******************************************************************* --
   --
   -- CREATE_TS -
   --
   PROCEDURE create_ts_tz (p_cwms_ts_id          IN VARCHAR2,
                           p_utc_offset          IN NUMBER DEFAULT NULL,
                           p_interval_forward    IN NUMBER DEFAULT NULL,
                           p_interval_backward    IN NUMBER DEFAULT NULL,
                           p_versioned           IN VARCHAR2 DEFAULT 'F',
                           p_active_flag          IN VARCHAR2 DEFAULT 'T',
                           p_time_zone_name       IN VARCHAR2 DEFAULT 'UTC',
                           p_office_id           IN VARCHAR2 DEFAULT NULL
                          );

   --
   --******************************************************************* --
   --******************************************************************* --
   --
   -- CREATE_TS_CODE - v2.0 -
   --
   PROCEDURE create_ts_code (
      p_ts_code                OUT NUMBER,
      p_cwms_ts_id          IN     VARCHAR2,
      p_utc_offset          IN     NUMBER DEFAULT NULL,
      p_interval_forward    IN     NUMBER DEFAULT NULL,
      p_interval_backward    IN     NUMBER DEFAULT NULL,
      p_versioned           IN     VARCHAR2 DEFAULT 'F',
      p_active_flag          IN     VARCHAR2 DEFAULT 'T',
      p_fail_if_exists       IN     VARCHAR2 DEFAULT 'T',
      p_office_id           IN     VARCHAR2 DEFAULT NULL
   );

   --
   --******************************************************************* --
   --******************************************************************* --
   --
   -- CREATE_TS_CODE - v2.0 -
   --
   PROCEDURE create_ts_code_tz (
      p_ts_code                OUT NUMBER,
      p_cwms_ts_id          IN     VARCHAR2,
      p_utc_offset          IN     NUMBER DEFAULT NULL,
      p_interval_forward    IN     NUMBER DEFAULT NULL,
      p_interval_backward    IN     NUMBER DEFAULT NULL,
      p_versioned           IN     VARCHAR2 DEFAULT 'F',
      p_active_flag          IN     VARCHAR2 DEFAULT 'T',
      p_fail_if_exists       IN     VARCHAR2 DEFAULT 'T',
      p_time_zone_name       IN     VARCHAR2 DEFAULT 'UTC',
      p_office_id           IN     VARCHAR2 DEFAULT NULL
   );

   --
   --******************************************************************* --
   --******************************************************************* --
   --
   -- RETREIVE_TS_OUT - v2.0 -
   --
   PROCEDURE retrieve_ts_out (
      p_at_tsv_rc            OUT SYS_REFCURSOR,
      p_cwms_ts_id_out        OUT VARCHAR2,
      p_units_out            OUT VARCHAR2,
      p_cwms_ts_id        IN      VARCHAR2,
      p_units              IN      VARCHAR2,
      p_start_time        IN      DATE,
      p_end_time           IN      DATE,
      p_time_zone         IN      VARCHAR2 DEFAULT 'UTC',
      p_trim              IN      VARCHAR2 DEFAULT 'F',
      p_start_inclusive   IN      VARCHAR2 DEFAULT 'T',
      p_end_inclusive     IN      VARCHAR2 DEFAULT 'T',
      p_previous           IN      VARCHAR2 DEFAULT 'F',
      p_next              IN      VARCHAR2 DEFAULT 'F',
      p_version_date      IN      DATE DEFAULT NULL,
      p_max_version        IN      VARCHAR2 DEFAULT 'T',
      p_office_id         IN      VARCHAR2 DEFAULT NULL
   );

   --******************************************************************* --

   FUNCTION retrieve_ts_out_tab (p_cwms_ts_id        IN VARCHAR2,
                                 p_units              IN VARCHAR2,
                                 p_start_time        IN DATE,
                                 p_end_time           IN DATE,
                                 p_time_zone         IN VARCHAR2 DEFAULT 'UTC',
                                 p_trim              IN VARCHAR2 DEFAULT 'F',
                                 p_start_inclusive   IN VARCHAR2 DEFAULT 'T',
                                 p_end_inclusive     IN VARCHAR2 DEFAULT 'T',
                                 p_previous           IN VARCHAR2 DEFAULT 'F',
                                 p_next              IN VARCHAR2 DEFAULT 'F',
                                 p_version_date      IN DATE DEFAULT NULL,
                                 p_max_version        IN VARCHAR2 DEFAULT 'T',
                                 p_office_id         IN VARCHAR2 DEFAULT NULL
                                )
      RETURN zts_tab_t
      PIPELINED;

   --
   --******************************************************************* --
   --******************************************************************* --
   --
   -- RETREIVE_TS - v1.4 -
   --
   PROCEDURE retrieve_ts (
      p_at_tsv_rc     IN OUT SYS_REFCURSOR,
      p_units          IN     VARCHAR2,
      p_officeid       IN     VARCHAR2,
      p_cwms_ts_id    IN     VARCHAR2,
      p_start_time    IN     DATE,
      p_end_time       IN     DATE,
      p_timezone       IN     VARCHAR2 DEFAULT 'GMT',
      p_trim          IN     NUMBER DEFAULT cwms_util.false_num,
      p_inclusive     IN     NUMBER DEFAULT NULL,
      p_versiondate    IN     DATE DEFAULT NULL,
      p_max_version    IN     NUMBER DEFAULT cwms_util.true_num
   );

   --
   --******************************************************************* --
   --******************************************************************* --
   --
   -- RETREIVE_TS_2 - v1.4 -
   --
   PROCEDURE retrieve_ts_2 (
      p_at_tsv_rc        OUT SYS_REFCURSOR,
      p_units          IN     VARCHAR2,
      p_officeid       IN     VARCHAR2,
      p_cwms_ts_id    IN     VARCHAR2,
      p_start_time    IN     DATE,
      p_end_time       IN     DATE,
      p_timezone       IN     VARCHAR2 DEFAULT 'GMT',
      p_trim          IN     NUMBER DEFAULT cwms_util.false_num,
      p_inclusive     IN     NUMBER DEFAULT NULL,
      p_versiondate    IN     DATE DEFAULT NULL,
      p_max_version    IN     NUMBER DEFAULT cwms_util.true_num
   );

   --
   --******************************************************************* --
   --******************************************************************* --
   --
   -- RETREIVE_TS - v2.0 -
   --
   PROCEDURE retrieve_ts (p_at_tsv_rc             OUT SYS_REFCURSOR,
                          p_cwms_ts_id        IN     VARCHAR2,
                          p_units             IN     VARCHAR2,
                          p_start_time        IN     DATE,
                          p_end_time          IN     DATE,
                          p_time_zone          IN     VARCHAR2 DEFAULT 'UTC',
                          p_trim              IN     VARCHAR2 DEFAULT 'F',
                          p_start_inclusive    IN     VARCHAR2 DEFAULT 'T',
                          p_end_inclusive     IN     VARCHAR2 DEFAULT 'T',
                          p_previous          IN     VARCHAR2 DEFAULT 'F',
                          p_next              IN     VARCHAR2 DEFAULT 'F',
                          p_version_date       IN     DATE DEFAULT NULL,
                          p_max_version       IN     VARCHAR2 DEFAULT 'T',
                          p_office_id          IN     VARCHAR2 DEFAULT NULL
                         );

   --
   --******************************************************************* --
   --******************************************************************* --
   --
   -- RETREIVE_TS_MULTI - v2.0 -
   --
   PROCEDURE retrieve_ts_multi (
      p_at_tsv_rc            OUT SYS_REFCURSOR,
      p_timeseries_info   IN      timeseries_req_array,
      p_time_zone         IN      VARCHAR2 DEFAULT 'UTC',
      p_trim              IN      VARCHAR2 DEFAULT 'F',
      p_start_inclusive   IN      VARCHAR2 DEFAULT 'T',
      p_end_inclusive     IN      VARCHAR2 DEFAULT 'T',
      p_previous           IN      VARCHAR2 DEFAULT 'F',
      p_next              IN      VARCHAR2 DEFAULT 'F',
      p_version_date      IN      DATE DEFAULT NULL,
      p_max_version        IN      VARCHAR2 DEFAULT 'T',
      p_office_id         IN      VARCHAR2 DEFAULT NULL
   );

   --
   --******************************************************************* --
   --******************************************************************* --
   --
   -- shift_for_localtime
   --
   FUNCTION shift_for_localtime (p_date_time IN DATE, p_tz_name IN VARCHAR2)
      RETURN DATE;

   --
   --
   --******************************************************************* --
   --******************************************************************* --
   --
   -- CLEAN_QUALITY_CODE -
   --
   FUNCTION clean_quality_code (p_quality_code IN NUMBER)
      RETURN NUMBER
      RESULT_CACHE;

   --
   --******************************************************************* --
   --******************************************************************* --
   --
   -- STORE_TS -
   --
   --v 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvvvv -
   PROCEDURE store_ts (
      p_office_id         IN VARCHAR2,
      p_cwms_ts_id        IN VARCHAR2,
      p_units              IN VARCHAR2,
      p_timeseries_data   IN tsv_array,
      p_store_rule        IN VARCHAR2 DEFAULT NULL,
      p_override_prot     IN NUMBER DEFAULT cwms_util.false_num,
      p_versiondate        IN DATE DEFAULT cwms_util.non_versioned
   );

   --^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^^^^ -
   --
   --******************************************************************* --
   --******************************************************************* --
   --
   -- STORE_TS -
   --
   PROCEDURE store_ts (
      p_cwms_ts_id        IN VARCHAR2,
      p_units              IN VARCHAR2,
      p_timeseries_data   IN tsv_array,
      p_store_rule        IN VARCHAR2 DEFAULT NULL,
      p_override_prot     IN VARCHAR2 DEFAULT 'F',
      p_version_date      IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id         IN VARCHAR2 DEFAULT NULL
   );

   --
   --******************************************************************* --
   --******************************************************************* --
   --
   -- STORE_TS - This version is for Python/CxOracle
   --
   PROCEDURE store_ts (
      p_cwms_ts_id      IN VARCHAR2,
      p_units            IN VARCHAR2,
      p_times            IN number_array,
      p_values          IN double_array,
      p_qualities       IN number_array,
      p_store_rule      IN VARCHAR2 DEFAULT NULL,
      p_override_prot   IN VARCHAR2 DEFAULT 'F',
      p_version_date    IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id       IN VARCHAR2 DEFAULT NULL
   );

   --
   --******************************************************************* --
   --******************************************************************* --
   --
   -- STORE_TS - This version is for Java/Jython bypassing TIMESTAMPTZ type
   --
   PROCEDURE store_ts (
      p_cwms_ts_id      IN VARCHAR2,
      p_units            IN VARCHAR2,
      p_times            IN number_tab_t,
      p_values          IN number_tab_t,
      p_qualities       IN number_tab_t,
      p_store_rule      IN VARCHAR2 DEFAULT NULL,
      p_override_prot   IN VARCHAR2 DEFAULT 'F',
      p_version_date    IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id       IN VARCHAR2 DEFAULT NULL
   );

   --
   --******************************************************************* --
   --******************************************************************* --
   --
   -- STORE_TS_MULTI -
   --
   PROCEDURE store_ts_multi (
      p_timeseries_array   IN timeseries_array,
      p_store_rule         IN VARCHAR2 DEFAULT NULL,
      p_override_prot      IN VARCHAR2 DEFAULT 'F',
      p_version_date       IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id          IN VARCHAR2 DEFAULT NULL
   );

   --
   --******************************************************************* --
   --******************************************************************* --
   --
   PROCEDURE update_ts_id (
      p_ts_code                  IN NUMBER,
      p_interval_utc_offset      IN NUMBER DEFAULT NULL,        -- in minutes.
      p_snap_forward_minutes      IN NUMBER DEFAULT NULL,
      p_snap_backward_minutes    IN NUMBER DEFAULT NULL,
      p_local_reg_time_zone_id   IN VARCHAR2 DEFAULT NULL,
      p_ts_active_flag            IN VARCHAR2 DEFAULT NULL
   );

   PROCEDURE update_ts_id (
      p_cwms_ts_id               IN VARCHAR2,
      p_interval_utc_offset      IN NUMBER DEFAULT NULL,        -- in minutes.
      p_snap_forward_minutes      IN NUMBER DEFAULT NULL,
      p_snap_backward_minutes    IN NUMBER DEFAULT NULL,
      p_local_reg_time_zone_id   IN VARCHAR2 DEFAULT NULL,
      p_ts_active_flag            IN VARCHAR2 DEFAULT NULL,
      p_db_office_id             IN VARCHAR2 DEFAULT NULL
   );

   --
   --******************************************************************* --
   --******************************************************************* --
   --
   -- RENAME_TS_JAVA -
   --
   --v 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvvvv -
   PROCEDURE rename_ts (p_office_id             IN VARCHAR2,
                        p_timeseries_desc_old   IN VARCHAR2,
                        p_timeseries_desc_new   IN VARCHAR2
                       );

   --^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^^^^ -
   --
   PROCEDURE rename_ts (p_cwms_ts_id_old    IN VARCHAR2,
                        p_cwms_ts_id_new    IN VARCHAR2,
                        p_utc_offset_new    IN NUMBER DEFAULT NULL,
                        p_office_id        IN VARCHAR2 DEFAULT NULL
                       );

   --
   --******************************************************************* --
   --******************************************************************* --
   --
   -- PARSE_TS -
   --
   PROCEDURE parse_ts (p_cwms_ts_id          IN     VARCHAR2,
                       p_base_location_id       OUT VARCHAR2,
                       p_sub_location_id         OUT VARCHAR2,
                       p_base_parameter_id      OUT VARCHAR2,
                       p_sub_parameter_id       OUT VARCHAR2,
                       p_parameter_type_id      OUT VARCHAR2,
                       p_interval_id            OUT VARCHAR2,
                       p_duration_id            OUT VARCHAR2,
                       p_version_id             OUT VARCHAR2
                      );

   PROCEDURE zretrieve_ts (p_at_tsv_rc      IN OUT SYS_REFCURSOR,
                           p_units           IN      VARCHAR2,
                           p_cwms_ts_id     IN      VARCHAR2,
                           p_start_time     IN      DATE,
                           p_end_time        IN      DATE,
                           p_trim           IN      VARCHAR2 DEFAULT 'F',
                           p_inclusive      IN      NUMBER DEFAULT NULL,
                           p_version_date   IN      DATE DEFAULT NULL,
                           p_max_version     IN      VARCHAR2 DEFAULT 'T',
                           p_db_office_id   IN      VARCHAR2 DEFAULT NULL
                          );

   PROCEDURE zstore_ts (
      p_cwms_ts_id        IN VARCHAR2,
      p_units              IN VARCHAR2,
      p_timeseries_data   IN ztsv_array,
      p_store_rule        IN VARCHAR2 DEFAULT NULL,
      p_override_prot     IN VARCHAR2 DEFAULT 'F',
      p_version_date      IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id         IN VARCHAR2 DEFAULT NULL
   );

   PROCEDURE zstore_ts_multi (
      p_timeseries_array   IN ztimeseries_array,
      p_store_rule         IN VARCHAR2 DEFAULT NULL,
      p_override_prot      IN VARCHAR2 DEFAULT 'F',
      p_version_date       IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id          IN VARCHAR2 DEFAULT NULL
   );

   PROCEDURE zretrieve_ts_java (
      p_transaction_time      OUT DATE,
      p_at_tsv_rc             OUT SYS_REFCURSOR,
      p_units_out             OUT VARCHAR2,
      p_cwms_ts_id_out         OUT VARCHAR2,
      p_units_in            IN     VARCHAR2,
      p_cwms_ts_id_in      IN     VARCHAR2,
      p_start_time         IN     DATE,
      p_end_time            IN     DATE,
      p_trim               IN     VARCHAR2 DEFAULT 'F',
      p_inclusive          IN     NUMBER DEFAULT NULL,
      p_version_date       IN     DATE DEFAULT NULL,
      p_max_version         IN     VARCHAR2 DEFAULT 'T',
      p_db_office_id       IN     VARCHAR2 DEFAULT NULL
   );
   
   procedure collect_deleted_times (
      p_deleted_time in timestamp,
      p_ts_code      in number,
      p_version_date in date,
      p_start_time   in date,
      p_end_time     in date);   
   
   procedure retrieve_deleted_times (
      p_deleted_times out date_table_type,
      p_deleted_time  in  number,
      p_ts_code       in  number,
      p_version_date  in  number);   
   
   function retrieve_deleted_times_f (
      p_deleted_time  in number,
      p_ts_code       in number,
      p_version_date  in number)
      return date_table_type;   

   PROCEDURE create_parameter_id (p_parameter_id   IN VARCHAR2,
                                  p_db_office_id   IN VARCHAR2 DEFAULT NULL
                                 );

   PROCEDURE delete_parameter_id (p_parameter_id   IN VARCHAR2,
                                  p_db_office_id   IN VARCHAR2 DEFAULT NULL
                                 );

   PROCEDURE rename_parameter_id (
      p_parameter_id_old   IN VARCHAR2,
      p_parameter_id_new   IN VARCHAR2,
      p_db_office_id       IN VARCHAR2 DEFAULT NULL
   );
   
   FUNCTION register_ts_callback (
      p_procedure_name  IN VARCHAR2,
      p_subscriber_name IN VARCHAR2 DEFAULT NULL,
      p_queue_name      IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2;
   
   PROCEDURE unregister_ts_callback (
      p_procedure_name  IN VARCHAR2,
      p_subscriber_name IN VARCHAR2,
      p_queue_name      IN VARCHAR2 DEFAULT NULL);

   PROCEDURE refresh_ts_catalog;
   
   -------------------------------
   -- Timeseries group routines --
   -------------------------------
   procedure store_ts_category(
      p_ts_category_id   in varchar2,
      p_ts_category_desc in varchar2 default null,
      p_fail_if_exists   in varchar2 default 'F',
      p_ignore_null      in varchar2 default 'T',
      p_db_office_id     in varchar2 default null
   );
      
   function store_ts_category_f(
      p_ts_category_id   in varchar2,
      p_ts_category_desc in varchar2 default null,
      p_fail_if_exists   in varchar2 default 'F',
      p_ignore_null      in varchar2 default 'T',
      p_db_office_id     in varchar2 default null
   )  return number;

   procedure rename_ts_category (
      p_ts_category_id_old   in   varchar2,
      p_ts_category_id_new   in   varchar2,
      p_db_office_id         in   varchar2 default null
   );

   procedure delete_ts_category (
      p_ts_category_id in varchar2,
      p_cascade        in varchar2 default 'F' ,
      p_db_office_id   in varchar2 default null
   );

   procedure store_ts_group (
      p_ts_category_id   in   varchar2,
      p_ts_group_id      in   varchar2,
      p_ts_group_desc    in   varchar2 default null,
      p_fail_if_exists   in   varchar2 default 'F',
      p_ignore_nulls     in   varchar2 default 'T',
      p_shared_alias_id  in   varchar2 default null,
      p_shared_ts_ref_id in   varchar2 default null,
      p_db_office_id     in   varchar2 default null
   );

   function store_ts_group_f (
      p_ts_category_id   in   varchar2,
      p_ts_group_id      in   varchar2,
      p_ts_group_desc    in   varchar2 default null,
      p_fail_if_exists   in   varchar2 default 'F',
      p_ignore_nulls     in   varchar2 default 'T',
      p_shared_alias_id  in   varchar2 default null,
      p_shared_ts_ref_id in   varchar2 default null,
      p_db_office_id     in   varchar2 default null
   )  return number;

   procedure rename_ts_group (
      p_ts_category_id    in   varchar2,
      p_ts_group_id_old   in   varchar2,
      p_ts_group_id_new   in   varchar2,
      p_db_office_id      in   varchar2 default null
   );
      
   procedure delete_ts_group (
      p_ts_category_id   in varchar2,
      p_ts_group_id      in varchar2,
      p_db_office_id     in varchar2 default null
   );

   procedure assign_ts_group (
      p_ts_category_id   in   varchar2,
      p_ts_group_id      in   varchar2,
      p_ts_id            in   varchar2,
      p_ts_attribute     in   number   default null,
      p_ts_alias_id      in   varchar2 default null,
      p_ref_ts_id        in   varchar2 default null,
      p_db_office_id     in   varchar2 default null
   );

   procedure unassign_ts_group (
      p_ts_category_id   in   varchar2,
      p_ts_group_id      in   varchar2,
      p_ts_id            in   varchar2,
      p_unassign_all     in   varchar2 default 'F',
      p_db_office_id     in   varchar2 default null
   );

   procedure assign_ts_groups (
      p_ts_category_id   in   varchar2,
      p_ts_group_id      in   varchar2,
      p_ts_alias_array   in   ts_alias_tab_t,
      p_db_office_id     in   varchar2 default null
   );

   procedure unassign_ts_groups (
      p_ts_category_id   in   varchar2,
      p_ts_group_id      in   varchar2,
      p_ts_array         in   str_tab_t,
      p_unassign_all     in   varchar2 default 'F',
      p_db_office_id     in   varchar2 default null
   );
   
   function get_ts_id_from_alias(
      p_alias_id    in varchar2,
      p_group_id    in varchar2 default null,
      p_category_id in varchar2 default null,
      p_office_id   in varchar2 default null
   )  return varchar2;
      
   
   function get_ts_code_from_alias(
      p_alias_id    in varchar2,
      p_group_id    in varchar2 default null,
      p_category_id in varchar2 default null,
      p_office_id   in varchar2 default null
   )  return number;
   
   function get_ts_id(
      p_ts_id_or_alias in varchar2,
      p_office_id      in varchar2
   )  return varchar2;

   function get_ts_id(
      p_ts_id_or_alias in varchar2,
      p_office_code    in number
   )  return varchar2;
   
   ---------------------------
   -- Data quality routines --
   ---------------------------
   function get_quality_validity(
      p_quality_code in number)
      return varchar2 result_cache;
      
   function get_quality_validity(
      p_value in tsv_type)
      return varchar2;
      
   function get_quality_validity(
      p_value in ztsv_type)
      return varchar2;
      
   function quality_is_okay(
      p_quality_code in number)
      return boolean result_cache;      
      
   function quality_is_okay(
      p_value in tsv_type)
      return boolean;
      
   function quality_is_okay(
      p_value in ztsv_type)
      return boolean;
      
   function quality_is_missing(
      p_quality_code in number)
      return boolean result_cache;      
      
   function quality_is_missing(
      p_value in tsv_type)
      return boolean;
      
   function quality_is_missing(
      p_value in ztsv_type)
      return boolean;
      
   function quality_is_questionable(
      p_quality_code in number)
      return boolean result_cache;      
      
   function quality_is_questionable(
      p_value in tsv_type)
      return boolean;
      
   function quality_is_questionable(
      p_value in ztsv_type)
      return boolean;
      
   function quality_is_rejected(
      p_quality_code in number)
      return boolean result_cache;      
      
   function quality_is_rejected(
      p_value in tsv_type)
      return boolean;
      
   function quality_is_rejected(
      p_value in ztsv_type)
      return boolean;

   function get_quality_description(
      p_quality_code in number)
      return varchar2 result_cache;
   
   ----------------------------------      
   -- time series extents routines --
   ----------------------------------      
   function get_ts_min_date_utc(
      p_ts_code          in number,
      p_version_date_utc in date default cwms_util.non_versioned)
      return date;
      
   function get_ts_min_date(
      p_cwms_ts_id   in varchar2,
      p_time_zone    in varchar2 default 'UTC',
      p_version_date in date     default cwms_util.non_versioned,
      p_office_id    in varchar2 default null)
      return date;
      
   function get_ts_max_date_utc(
      p_ts_code          in number,
      p_version_date_utc in date default cwms_util.non_versioned)
      return date;
      
   function get_ts_max_date(
      p_cwms_ts_id   in varchar2,
      p_time_zone    in varchar2 default 'UTC',
      p_version_date in date     default cwms_util.non_versioned,
      p_office_id    in varchar2 default null)
      return date;
      
   procedure get_ts_extents_utc(
      p_min_date_utc     out date,
      p_max_date_utc     out date,
      p_ts_code          in  number,
      p_version_date_utc in  date default cwms_util.non_versioned);
      
   procedure get_ts_extents(
      p_min_date     out date,
      p_max_date     out date,
      p_cwms_ts_id   in  varchar2,
      p_time_zone    in  varchar2 default 'UTC',
      p_version_date in  date     default cwms_util.non_versioned,
      p_office_id    in  varchar2 default null);

   procedure get_value_extents(
      p_min_value out binary_double,
      p_max_value out binary_double,
      p_ts_id     in  varchar2,
      p_unit      in  varchar2,
      p_min_date  in  date default null,
      p_max_date  in  date default null,
      p_time_zone in  varchar2 default null,
      p_office_id in  varchar2 default null);

   procedure get_value_extents(
      p_min_value      out binary_double,
      p_max_value      out binary_double,
      p_min_value_date out date,
      p_max_value_date out date,
      p_ts_id          in  varchar2,
      p_unit           in  varchar2,
      p_min_date       in  date default null,
      p_max_date       in  date default null,
      p_time_zone      in  varchar2 default null,
      p_office_id      in  varchar2 default null);
      
   function get_values_in_range(
      p_ts_id     in varchar2,
      p_min_value in binary_double,
      p_max_value in binary_double,
      p_unit      in varchar2,
      p_min_date  in date default null,
      p_max_date  in date default null,
      p_time_zone in varchar2 default null,
      p_office_id in varchar2 default null)
      return ztsv_array;

   function get_values_in_range(
      p_criteria in time_series_range_t)
      return ztsv_array;      
      
   function get_values_in_range(
      p_criteria in time_series_range_tab_t)
      return ztsv_array_tab;      
      
   procedure trim_ts_deleted_times;
   
   procedure start_trim_ts_deleted_job;
            
END;
/

show errors;
COMMIT;
