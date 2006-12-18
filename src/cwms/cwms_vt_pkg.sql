/* Formatted on 2006/12/18 14:11 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE cwms_vt AUTHID CURRENT_USER
AS
/******************************************************************************
   NAME:       CWMS_VAL
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        12/11/2006             1. Created this package.
******************************************************************************/
   FUNCTION get_screening_code (
      p_screening_id     IN   VARCHAR2,
      p_ts_ni_hash       IN   VARCHAR2,
      p_db_office_code   IN   NUMBER
   )
      RETURN NUMBER;

   FUNCTION create_screening_code (
      p_screening_id        IN   VARCHAR2,
      p_screening_id_desc   IN   VARCHAR2,
      p_parameter_id        IN   VARCHAR2,
      p_parameter_type_id   IN   VARCHAR2,
      p_duration_id         IN   VARCHAR2,
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   )
      RETURN NUMBER;

   PROCEDURE create_screening_id (
      p_screening_id        IN   VARCHAR2,
      p_screening_id_desc   IN   VARCHAR2,
      p_parameter_id        IN   VARCHAR2,
      p_parameter_type_id   IN   VARCHAR2,
      p_duration_id         IN   VARCHAR2,
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE rename_screening_id (
      p_screening_id_old    IN   VARCHAR2,
      p_screening_id_new    IN   VARCHAR2,
      p_parameter_id        IN   VARCHAR2,
      p_parameter_type_id   IN   VARCHAR2,
      p_duration_id         IN   VARCHAR2,
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE update_screening_id_desc (
      p_screening_id        IN   VARCHAR2,
      p_screening_id_desc   IN   VARCHAR2,
      p_parameter_id        IN   VARCHAR2,
      p_parameter_type_id   IN   VARCHAR2,
      p_duration_id         IN   VARCHAR2,
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
      p_parameter_id              IN   VARCHAR2,
      p_parameter_type_id         IN   VARCHAR2,
      p_duration_id               IN   VARCHAR2,
      p_rate_change_interval_id   IN   VARCHAR2,
      p_unit_id                   IN   VARCHAR2,
      p_screen_crit_array         IN   screen_crit_array,
      p_store_rule                IN   VARCHAR2 DEFAULT 'DELETE INSERT',
      p_ignore_nulls              IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id              IN   VARCHAR2 DEFAULT NULL
   );
END cwms_vt;
/