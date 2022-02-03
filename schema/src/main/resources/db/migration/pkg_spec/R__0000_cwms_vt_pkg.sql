
CREATE OR REPLACE PACKAGE cwms_vt
/* (non-javadoc)
 * [description needed]
 *
 * @author Gerhard Krueger
 *
 * @since CWMS 2.1
 */
AS
   /* (non-javadoc)
    * [description needed]
    *
    * @member trans_id    [description needed]
    * @member description [description needed]
    */
   TYPE cat_tr_transforms_rec_t IS RECORD (
      trans_id      VARCHAR2 (32),
      description   VARCHAR2 (256)
   );
   /* (non-javadoc)
    * [description needed]
    */
   TYPE cat_tr_transforms_t IS TABLE OF cat_tr_transforms_rec_t;
   /* (non-javadoc)
    * [description needed]
    *
    * @member template_id          [description needed]
    * @member description          [description needed]
    * @member primary_ind_param_id [description needed]
    * @member dep_param_id         [description needed]
    */
   TYPE cat_tr_templates_rec_t IS RECORD (
      template_id            VARCHAR2 (32),
      description            VARCHAR2 (256),
      primary_ind_param_id   VARCHAR2 (16),
      dep_param_id           VARCHAR2 (16)
   );
   /* (non-javadoc)
    * [description needed]
    */
  TYPE cat_tr_templates_t IS TABLE OF cat_tr_templates_rec_t;
   /* (non-javadoc)
    * [description needed]
    *
    * @member sequence_no           [description needed]
    * @member transform_id          [description needed]
    * @member description           [description needed]
    * @member store_dep_flag        [description needed]
    * @member unit_system           [description needed]
    * @member lookup_agency_source  [description needed]
    * @member lookup_source_version [description needed]
    * @member scaling_arg_a         [description needed]
    * @member scaling_arg_b         [description needed]
    * @member scaling_arg_c         [description needed]
    */
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
   /* (non-javadoc)
    * [description needed]
    */
   TYPE tr_template_set_t IS TABLE OF tr_template_set_rec_t;
   /* (non-javadoc)
    * [description needed]
    *
    * @member sequence_no          [description needed]
    * @member variable_name        [description needed]
    * @member location_mask        [description needed]
    * @member base_parameter_mask  [description needed]
    * @member sub_parameter_mask   [description needed]
    * @member param_type_mask      [description needed]
    * @member interval_mask        [description needed]
    * @member duration_mask        [description needed]
    * @member version_mask         [description needed]
    */
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
   /* (non-javadoc)
    * [description needed]
    */
   TYPE tr_template_set_masks_t IS TABLE OF tr_template_set_masks_rec_t;
   /* (non-javadoc)
    * [description needed]
    *
    * @param p_screening_code [description needed]
    *
    * @return [description needed]
    */
   FUNCTION get_screening_code_ts_id_count (p_screening_code IN NUMBER)
      RETURN NUMBER;
   /* (non-javadoc)
    * [description needed]
    *
    * @param p_screening_id   [description needed]
    * @param p_db_office_code [description needed]
    *
    * @return [description needed]
    */
   FUNCTION get_screening_code (
      p_screening_id     IN   VARCHAR2,
      p_db_office_code   IN   NUMBER DEFAULT NULL
   )
      RETURN NUMBER;
   /* (non-javadoc)
    * [description needed]
    *
    * @param p_screening_id        [description needed]
    * @param p_screening_id_desc   [description needed]
    * @param p_parameter_id        [description needed]
    * @param p_parameter_type_id   [description needed]
    * @param p_duration_id         [description needed]
    * @param p_db_office_id        [description needed]
    *
    * @return [description needed]
    */
   FUNCTION create_screening_code (
      p_screening_id        IN   VARCHAR2,
      p_screening_id_desc   IN   VARCHAR2,
      p_parameter_id        IN   VARCHAR2,
      p_parameter_type_id   IN   VARCHAR2 DEFAULT NULL,
      p_duration_id         IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   )
      RETURN NUMBER;
   /* (non-javadoc)
    * [description needed]
    *
    * @param p_screening_id        [description needed]
    * @param p_screening_id_desc   [description needed]
    * @param p_parameter_id        [description needed]
    * @param p_parameter_type_id   [description needed]
    * @param p_duration_id         [description needed]
    * @param p_db_office_id        [description needed]
    */
   PROCEDURE create_screening_id (
      p_screening_id        IN   VARCHAR2,
      p_screening_id_desc   IN   VARCHAR2,
      p_parameter_id        IN   VARCHAR2,
      p_parameter_type_id   IN   VARCHAR2 DEFAULT NULL,
      p_duration_id         IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   );
   /* (non-javadoc)
    * [description needed]
    *
    * @param p_screening_id_old       [description needed]
    * @param p_screening_id_new       [description needed]
    * @param p_screening_id_desc_new  [description needed]
    * @param p_parameter_id_new       [description needed]
    * @param p_parameter_type_id_new  [description needed]
    * @param p_duration_id_new        [description needed]
    * @param p_param_check            [description needed]
    * @param p_db_office_id           [description needed]
    */
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
   /* (non-javadoc)
    * [description needed]
    *
    * @param p_screening_id_old  [description needed]
    * @param p_screening_id_new  [description needed]
    * @param p_db_office_id      [description needed]
    */
   PROCEDURE rename_screening_id (
      p_screening_id_old   IN   VARCHAR2,
      p_screening_id_new   IN   VARCHAR2,
      p_db_office_id       IN   VARCHAR2 DEFAULT NULL
   );
   /* (non-javadoc)
    * [description needed]
    *
    * @param p_screening_id      [description needed]
    * @param p_screening_id_desc [description needed]
    * @param p_db_office_id      [description needed]
    */
   PROCEDURE update_screening_id_desc (
      p_screening_id        IN   VARCHAR2,
      p_screening_id_desc   IN   VARCHAR2,
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   );
   /* (non-javadoc)
    * [description needed]
    *
    * @param p_screening_id      [description needed]
    * @param p_parameter_id      [description needed]
    * @param p_parameter_type_id [description needed]
    * @param p_duration_id       [description needed]
    * @param p_cascade           [description needed]
    * @param p_db_office_id      [description needed]
    */
   PROCEDURE delete_screening_id (
      p_screening_id        IN   VARCHAR2,
      p_parameter_id        IN   VARCHAR2,
      p_parameter_type_id   IN   VARCHAR2,
      p_duration_id         IN   VARCHAR2,
      p_cascade             IN   VARCHAR2 DEFAULT 'F',
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   );
   /* (non-javadoc)
    * [description needed]
    *
    * @param p_screening_id                  [description needed]
    * @param p_unit_id                       [description needed]
    * @param p_screen_crit_array             [description needed]
    * @param p_rate_change_disp_interval_id  [description needed]
    * @param p_screening_control             [description needed]
    * @param p_store_rule                    [description needed]
    * @param p_ignore_nulls                  [description needed]
    * @param p_db_office_id                  [description needed]
    */
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
   /* (non-javadoc)
    * [description needed]
    *
    * @param p_screening_id_old  [description needed]
    * @param p_screening_id_new  [description needed]
    * @param p_param_check       [description needed]
    * @param p_db_office_id      [description needed]
    */
   PROCEDURE copy_screening_criteria (
      p_screening_id_old   IN   VARCHAR2,
      p_screening_id_new   IN   VARCHAR2,
      p_param_check        IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id       IN   VARCHAR2 DEFAULT NULL
   );
   /* (non-javadoc)
    * [description needed]
    *
    * @param p_use_db_crit      [description needed]
    * @param p_crit_file        [description needed]
    * @param p_use_db_otf       [description needed]
    * @param p_otf_file         [description needed]
    * @param p_data_stream_id   [description needed]
    * @param p_db_office_id     [description needed]
    */
   PROCEDURE get_process_shefit_files (
      p_use_db_crit      OUT      VARCHAR2,
      p_crit_file        OUT      CLOB,
      p_use_db_otf       OUT      VARCHAR2,
      p_otf_file         OUT      CLOB,
      p_data_stream_id   IN       VARCHAR2,
      p_db_office_id     IN       VARCHAR2 DEFAULT NULL
   );
   /* (non-javadoc)
    * [description needed]
    *
    * @param p_screening_id       [description needed]
    * @param p_scr_assign_array   [description needed]
    * @param p_db_office_id       [description needed]
    */
   PROCEDURE assign_screening_id (
      p_screening_id       IN   VARCHAR2,
      p_scr_assign_array   IN   screen_assign_array,
      p_db_office_id       IN   VARCHAR2 DEFAULT NULL
   );
   /* (non-javadoc)
    * [description needed]
    *
    * @param p_screening_id      [description needed]
    * @param p_cwms_ts_id_array  [description needed]
    * @param p_unassign_all      [description needed]
    * @param p_db_office_id      [description needed]
    */
   PROCEDURE unassign_screening_id (
      p_screening_id       IN   VARCHAR2,
      p_cwms_ts_id_array   IN   cwms_ts_id_array,
      p_unassign_all       IN   VARCHAR2 DEFAULT 'F',
      p_db_office_id       IN   VARCHAR2 DEFAULT NULL
   );
   /* (non-javadoc)
    * [description needed]
    *
    * @param p_timeseries_data [description needed]
    * @param p_min_reject      [description needed]
    * @param p_min_question    [description needed]
    * @param p_max_question    [description needed]
    * @param p_max_reject      [description needed]
    */
   PROCEDURE val_abs_mag (
      p_timeseries_data   IN OUT   tsv_array,
      p_min_reject        IN       BINARY_DOUBLE,
      p_min_question      IN       BINARY_DOUBLE,
      p_max_question      IN       BINARY_DOUBLE,
      p_max_reject        IN       BINARY_DOUBLE
   );

-- transfromation tables...
   /* (non-javadoc)
    * [description needed]
    *
    * @param p_db_office_id [description needed]
    *
    * @return [description needed]
    */
   FUNCTION cat_tr_templates_tab (p_db_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN cat_tr_templates_t PIPELINED;
   /* (non-javadoc)
    * [description needed]
    *
    * @param p_template_id   [description needed]
    * @param p_db_office_id  [description needed]
    *
    * @return [description needed]
    */
   FUNCTION cat_tr_template_set_masks_tab (
      p_template_id    IN   VARCHAR2,
      p_db_office_id   IN   VARCHAR2 DEFAULT NULL
   )
      RETURN tr_template_set_masks_t PIPELINED;
   /* (non-javadoc)
    * [description needed]
    *
    * @param p_template_id   [description needed]
    * @param p_db_office_id  [description needed]
    *
    * @return [description needed]
    */
   FUNCTION cat_tr_template_set_tab (
      p_template_id    IN   VARCHAR2,
      p_db_office_id   IN   VARCHAR2 DEFAULT NULL
   )
      RETURN tr_template_set_t PIPELINED;
   /* (non-javadoc)
    * [description needed]
    *
    * @return [description needed]
    */
   FUNCTION cat_tr_transforms_tab
      RETURN cat_tr_transforms_t PIPELINED;
   /* (non-javadoc)
    * [description needed]
    * @param p_template_id        [description needed]
    * @param p_cwms_ts_id         [description needed]
    * @param p_active_flag        [description needed]
    * @param p_event_trigger      [description needed]
    * @param p_reassign_existing  [description needed]
    * @param p_db_office_id       [description needed]
    */
   PROCEDURE assign_tr_template (
      p_template_id         IN   VARCHAR2,
      p_cwms_ts_id          IN   VARCHAR2,
      p_active_flag         IN   VARCHAR2 DEFAULT 'T',
      p_event_trigger       IN   VARCHAR2,
      p_reassign_existing   IN   VARCHAR2 DEFAULT 'F',
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   );
   /* (non-javadoc)
    * [description needed]
    *
    * @param p_template_id    [description needed]
    * @param p_cwms_ts_id     [description needed]
    * @param p_db_office_id   [description needed]
    */
   PROCEDURE unassign_tr_template (
      p_template_id    IN   VARCHAR2,
      p_cwms_ts_id     IN   VARCHAR2,
      p_db_office_id   IN   VARCHAR2 DEFAULT NULL
   );
   /* (non-javadoc)
    * [description needed]
    *
    * @param p_template_id             [description needed]
    * @param p_delete_template_cascade [description needed]
    * @param p_db_office_id            [description needed]
    */
   PROCEDURE delete_tr_template (
      p_template_id               IN   VARCHAR2,
      p_delete_template_cascade   IN   VARCHAR2 DEFAULT 'F',
      p_db_office_id              IN   VARCHAR2 DEFAULT NULL
   );
   /* (non-javadoc)
    * [description needed]
    *
    * @param p_template_id      [description needed]
    * @param p_template_id_new  [description needed]
    * @param p_db_office_id     [description needed]
    */
   PROCEDURE rename_tr_template (
      p_template_id       IN   VARCHAR2,
      p_template_id_new   IN   VARCHAR2,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   );
   /* (non-javadoc)
    * [description needed]
    *
    * @param p_template_id    [description needed]
    * @param description_new  [description needed]
    * @param p_db_office_id   [description needed]
    */
   PROCEDURE revise_tr_template_desc (
      p_template_id     IN   VARCHAR2,
      description_new   IN   VARCHAR2,
      p_db_office_id    IN   VARCHAR2 DEFAULT NULL
   );
   /* (non-javadoc)
    * [description needed]
    *
    * @param p_template_id        [description needed]
    * @param p_description        [description needed]
    * @param p_primary_indep_mask [description needed]
    * @param p_template_set       [description needed]
    * @param p_replace_existing   [description needed]
    * @param p_db_office_id       [description needed]
    */
   PROCEDURE store_tr_template (
      p_template_id          IN   VARCHAR2,
      p_description          IN   VARCHAR2,
      p_primary_indep_mask   IN   VARCHAR2,
      p_template_set         IN   tr_template_set_array,
      p_replace_existing     IN   VARCHAR2 DEFAULT 'F',
      p_db_office_id         IN   VARCHAR2 DEFAULT NULL
   );
   /* (non-javadoc)
    * [description needed]
    *
    * @param p_location_id       [description needed]
    * @param p_parameter_id      [description needed]
    * @param p_parameter_type_id [description needed]
    * @param p_interval_id       [description needed]
    * @param p_duration_id       [description needed]
    * @param p_version_id        [description needed]
    */
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