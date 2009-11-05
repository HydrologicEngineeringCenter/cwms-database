SET define off
/* Formatted on 2008/07/17 07:19 (Formatter Plus v4.8.8) */
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
   TYPE cat_tr_transforms_rec_t IS RECORD (
      trans_id      VARCHAR2 (32),
      description   VARCHAR2 (256)
   );

   TYPE cat_tr_transforms_t IS TABLE OF cat_tr_transforms_rec_t;

   TYPE cat_tr_templates_rec_t IS RECORD (
      template_id            VARCHAR2 (32),
      description            VARCHAR2 (256),
      primary_ind_param_id   VARCHAR2 (16),
      dep_param_id           VARCHAR2 (16)
   );

   TYPE cat_tr_templates_t IS TABLE OF cat_tr_templates_rec_t;

   TYPE tr_template_set_rec_t IS RECORD (
      sequence_no             NUMBER,
      transform_id            VARCHAR2 (32),
      description             VARCHAR2 (256),
      store_dep_flag          VARCHAR2 (1),
      unit_system             VARCHAR2 (2),
      lookup_agency_source    VARCHAR2 (32),
      lookup_source_version   VARCHAR2 (32),
      scaling_arg_a           NUMBER,
      scaling_arg_b           NUMBER,
      scaling_arg_c           NUMBER
   );

   TYPE tr_template_set_t IS TABLE OF tr_template_set_rec_t;

   TYPE tr_template_set_masks_rec_t IS RECORD (
      sequence_no           NUMBER,
      variable_name         VARCHAR2 (32),
      location_mask         VARCHAR2 (32),
      base_parameter_mask   VARCHAR2 (16),
      sub_parameter_mask    VARCHAR2 (32),
      param_type_mask       VARCHAR2 (19),
      interval_mask         VARCHAR2 (16),
      duration_mask         VARCHAR2 (16),
      version_mask          VARCHAR2 (42)
   );

   TYPE tr_template_set_masks_t IS TABLE OF tr_template_set_masks_rec_t;

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
      p_screening_id                   IN   VARCHAR2,
      p_unit_id                        IN   VARCHAR2,
      p_screen_crit_array              IN   screen_crit_array,
      p_rate_change_disp_interval_id   IN   VARCHAR2,
      p_screening_control              IN   screening_control_t,
      p_store_rule                     IN   VARCHAR2 DEFAULT 'DELETE INSERT',
      p_ignore_nulls                   IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id                   IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE copy_screening_criteria (
      p_screening_id_old   IN   VARCHAR2,
      p_screening_id_new   IN   VARCHAR2,
      p_param_check        IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id       IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE get_process_shefit_files (
      p_use_db_crit      OUT      VARCHAR2,
      p_crit_file        OUT      CLOB,
      p_use_db_otf       OUT      VARCHAR2,
      p_otf_file         OUT      CLOB,
      p_data_stream_id   IN       VARCHAR2,
      p_db_office_id     IN       VARCHAR2 DEFAULT NULL
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

   PROCEDURE val_abs_mag (
      p_timeseries_data   IN OUT   tsv_array,
      p_min_reject        IN       BINARY_DOUBLE,
      p_min_question      IN       BINARY_DOUBLE,
      p_max_question      IN       BINARY_DOUBLE,
      p_max_reject        IN       BINARY_DOUBLE
   );

-- transfromation tables...
   FUNCTION cat_tr_templates_tab (p_db_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN cat_tr_templates_t PIPELINED;

   FUNCTION cat_tr_template_set_masks_tab (
      p_template_id    IN   VARCHAR2,
      p_db_office_id   IN   VARCHAR2 DEFAULT NULL
   )
      RETURN tr_template_set_masks_t PIPELINED;

   FUNCTION cat_tr_template_set_tab (
      p_template_id    IN   VARCHAR2,
      p_db_office_id   IN   VARCHAR2 DEFAULT NULL
   )
      RETURN tr_template_set_t PIPELINED;

   FUNCTION cat_tr_transforms_tab
      RETURN cat_tr_transforms_t PIPELINED;

   PROCEDURE assign_tr_template (
      p_template_id         IN   VARCHAR2,
      p_cwms_ts_id          IN   VARCHAR2,
      p_active_flag         IN   VARCHAR2 DEFAULT 'T',
      p_event_trigger       IN   VARCHAR2,
      p_reassign_existing   IN   VARCHAR2 DEFAULT 'F',
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE unassign_tr_template (
      p_template_id    IN   VARCHAR2,
      p_cwms_ts_id     IN   VARCHAR2,
      p_db_office_id   IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE delete_tr_template (
      p_template_id               IN   VARCHAR2,
      p_delete_template_cascade   IN   VARCHAR2 DEFAULT 'F',
      p_db_office_id              IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE rename_tr_template (
      p_template_id       IN   VARCHAR2,
      p_template_id_new   IN   VARCHAR2,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE revise_tr_template_desc (
      p_template_id     IN   VARCHAR2,
      description_new   IN   VARCHAR2,
      p_db_office_id    IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE store_tr_template (
      p_template_id          IN   VARCHAR2,
      p_description          IN   VARCHAR2,
      p_primary_indep_mask   IN   VARCHAR2,
      p_template_set         IN   tr_template_set_array,
      p_replace_existing     IN   VARCHAR2 DEFAULT 'F',
      p_db_office_id         IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE create_tr_ts_mask (
      p_location_id         IN   VARCHAR2,
      p_parameter_id        IN   VARCHAR2,
      p_parameter_type_id   IN   VARCHAR2,
      p_interval_id         IN   VARCHAR2,
      p_duration_id         IN   VARCHAR2,
      p_version_id          IN   VARCHAR2
   );
END cwms_vt;
/