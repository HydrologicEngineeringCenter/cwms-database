/* Formatted on 2007/04/03 09:37 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE cwms_vt
AS
/******************************************************************************
   NAME:       CWMS_VAL
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        12/11/2006             1. Created this package.
******************************************************************************/
   FUNCTION get_screening_code_ts_id_count (p_screening_code IN NUMBER)
      RETURN NUMBER;

   FUNCTION get_screening_code (
      p_screening_id     IN   VARCHAR2,
      p_db_office_code   IN   NUMBER DEFAULT NULL
   )
      RETURN NUMBER;

   FUNCTION create_screening_code (
      p_screening_id        IN   VARCHAR2,
      p_screening_id_desc   IN   VARCHAR2,
      p_parameter_id        IN   VARCHAR2,
      p_parameter_type_id   IN   VARCHAR2 DEFAULT NULL,
      p_duration_id         IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   )
      RETURN NUMBER;

   PROCEDURE create_screening_id (
      p_screening_id        IN   VARCHAR2,
      p_screening_id_desc   IN   VARCHAR2,
      p_parameter_id        IN   VARCHAR2,
      p_parameter_type_id   IN   VARCHAR2 DEFAULT NULL,
      p_duration_id         IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE copy_screening_id (
      p_screening_id_old        IN   VARCHAR2,
      p_screening_id_new        IN   VARCHAR2,
      p_screening_id_desc_new   IN   VARCHAR2,
      p_parameter_id_new        IN   VARCHAR2 DEFAULT NULL,
      p_parameter_type_id_new   IN   VARCHAR2 DEFAULT NULL,
      p_duration_id_new         IN   VARCHAR2 DEFAULT NULL,
      p_param_check             IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id            IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE rename_screening_id (
      p_screening_id_old   IN   VARCHAR2,
      p_screening_id_new   IN   VARCHAR2,
      p_db_office_id       IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE update_screening_id_desc (
      p_screening_id        IN   VARCHAR2,
      p_screening_id_desc   IN   VARCHAR2,
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE delete_screening_id (
      p_screening_id        IN   VARCHAR2,
      p_parameter_id        IN   VARCHAR2,
      p_parameter_type_id   IN   VARCHAR2,
      p_duration_id         IN   VARCHAR2,
      p_cascade             IN   VARCHAR2 DEFAULT 'F',
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE store_screening_criteria (
      p_screening_id              IN   VARCHAR2,
      p_rate_change_interval_id   IN   VARCHAR2,
      p_unit_id                   IN   VARCHAR2,
      p_screen_crit_array         IN   screen_crit_array,
      p_store_rule                IN   VARCHAR2 DEFAULT 'DELETE INSERT',
      p_ignore_nulls              IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id              IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE copy_screening_criteria (
      p_screening_id_old   IN   VARCHAR2,
      p_screening_id_new   IN   VARCHAR2,
      p_param_check        IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id       IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE get_process_shefit_files (
      p_use_crit_clob   OUT      VARCHAR2,
      p_crit_file       OUT      CLOB,
      p_use_otf_clob    OUT      VARCHAR2,
      p_otf_file        OUT      CLOB,
      p_data_stream     IN       VARCHAR2,
      p_db_office_id    IN       VARCHAR2 DEFAULT NULL
   );

   PROCEDURE assign_screening_id (
      p_screening_id       IN   VARCHAR2,
      p_scr_assign_array   IN   screen_assign_array,
      p_db_office_id       IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE unassign_screening_id (
      p_screening_id       IN   VARCHAR2,
      p_cwms_ts_id_array   IN   cwms_ts_id_array,
      p_unassign_all       IN   VARCHAR2 DEFAULT 'F',
      p_db_office_id       IN   VARCHAR2 DEFAULT NULL
   );
END cwms_vt;
/