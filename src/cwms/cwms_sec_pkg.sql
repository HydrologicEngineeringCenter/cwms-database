/* Formatted on 5/28/2013 1:59:38 PM (QP5 v5.163.1008.3004) */
SET DEFINE ON
CREATE OR REPLACE PACKAGE cwms_sec
AS
   max_cwms_priv_ugroup_code     CONSTANT NUMBER := 9;
   max_cwms_ts_ugroup_code       CONSTANT NUMBER := 19;
   max_cwms_ts_group_code        CONSTANT NUMBER := 9;
   --
   user_group_code_all_users     CONSTANT NUMBER := 10;
   user_group_code_dba_users     CONSTANT NUMBER := 0;
   user_group_code_user_admins   CONSTANT NUMBER := 7;
   user_group_code_pd_users      CONSTANT NUMBER:= 1;
   --
   acc_state_locked              CONSTANT VARCHAR2 (16) := 'LOCKED';
   acc_state_unlocked            CONSTANT VARCHAR2 (16) := 'UNLOCKED';
   acc_state_no_account          CONSTANT VARCHAR2 (16) := 'NO ACCOUNT';
   cac_service_user             CONSTANT VARCHAR2(8) := 'CWMS9999';

   TYPE cat_at_sec_allow_rec_t IS RECORD
   (
      db_office_code    NUMBER,
      user_group_code   NUMBER,
      ts_group_code     NUMBER,
      db_office_id      VARCHAR2 (16),
      user_group_id     VARCHAR2 (32),
      ts_group_id       VARCHAR2 (32),
      priv_sum          NUMBER,
      priv              VARCHAR2 (15)
   );

   TYPE cat_at_sec_allow_tab_t IS TABLE OF cat_at_sec_allow_rec_t;

   TYPE cat_priv_groups_rec_t IS RECORD
   (
      username            VARCHAR2 (31),
      db_office_id        VARCHAR2 (16),
      user_group_type     VARCHAR2 (24),
      user_group_owner    VARCHAR2 (16),
      user_group_id       VARCHAR2 (32),
      is_member           VARCHAR2 (1),
      user_group_desc     VARCHAR2 (256)
   );

   TYPE cat_priv_groups_tab_t IS TABLE OF cat_priv_groups_rec_t;

   FUNCTION get_this_db_office_code
      RETURN NUMBER;

   FUNCTION get_this_db_office_id
      RETURN VARCHAR2;

   FUNCTION get_this_db_office_name
      RETURN VARCHAR2;


   FUNCTION get_max_cwms_ts_group_code
      RETURN NUMBER;

   FUNCTION is_user_admin (p_db_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN BOOLEAN;

   FUNCTION is_member_user_group (p_user_group_code   IN NUMBER,
                                  p_username          IN VARCHAR2,
                                  p_db_office_code    IN NUMBER)
      RETURN BOOLEAN;


   PROCEDURE set_user_office_id (p_username                  IN VARCHAR2,
                                 p_db_office_id   IN VARCHAR2);

   PROCEDURE assign_ts_group_user_group (
      p_ts_group_id     IN VARCHAR2,
      p_user_group_id   IN VARCHAR2,
      p_privilege       IN VARCHAR2,                    -- none, read or write
      p_db_office_id    IN VARCHAR2 DEFAULT NULL);

   PROCEDURE lock_db_account (p_username IN VARCHAR2);

   PROCEDURE unlock_db_account (p_username IN VARCHAR2);

   PROCEDURE create_cwms_db_account (
      p_username       IN VARCHAR2,
      p_password       IN VARCHAR2,
      p_db_office_id   IN VARCHAR2 DEFAULT NULL);

   PROCEDURE create_cwmsdbi_db_user (
      p_dbi_username   IN VARCHAR2,
      p_dbi_password   IN VARCHAR2 DEFAULT NULL,
      p_db_office_id   IN VARCHAR2 DEFAULT NULL);

   PROCEDURE set_dbi_user_passwd (p_dbi_password   IN VARCHAR2,
                                  p_dbi_username   IN VARCHAR2 DEFAULT NULL,
                                  p_db_office_id   IN VARCHAR2 DEFAULT NULL);

   PROCEDURE delete_cwms_db_account (p_username IN VARCHAR2);

   PROCEDURE get_assigned_priv_groups (
      p_priv_groups       OUT SYS_REFCURSOR,
      p_db_office_id   IN     VARCHAR2 DEFAULT NULL);

   FUNCTION get_assigned_priv_groups_tab (
      p_db_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN cat_priv_groups_tab_t
      PIPELINED;

   PROCEDURE get_user_priv_groups (
      p_priv_groups       OUT SYS_REFCURSOR,
      p_username       IN     VARCHAR2 DEFAULT NULL,
      p_db_office_id   IN     VARCHAR2 DEFAULT NULL);

   FUNCTION get_user_priv_groups_tab (
      p_username       IN VARCHAR2 DEFAULT NULL,
      p_db_office_id   IN VARCHAR2 DEFAULT NULL)
      RETURN cat_priv_groups_tab_t
      PIPELINED;

   PROCEDURE get_user_office_data (p_office_id          OUT VARCHAR2,
                                   p_office_long_name   OUT VARCHAR2);

   FUNCTION get_user_office_id
      RETURN VARCHAR2;

   PROCEDURE unlock_user (p_username       IN VARCHAR2,
                          p_db_office_id   IN VARCHAR2 DEFAULT NULL);

   FUNCTION get_user_group_code (p_user_group_id    IN VARCHAR2,
                                 p_db_office_code   IN NUMBER)
      RETURN NUMBER;

   PROCEDURE add_user_to_group (p_username         IN VARCHAR2,
                                p_user_group_id    IN VARCHAR2,
                                p_db_office_code   IN NUMBER);

   PROCEDURE add_user_to_group (p_username        IN VARCHAR2,
                                p_user_group_id   IN VARCHAR2,
                                p_db_office_id    IN VARCHAR2 DEFAULT NULL);

   PROCEDURE create_logon_trigger (p_username IN VARCHAR2);
   PROCEDURE create_user (p_username             IN VARCHAR2,
                          p_password             IN VARCHAR2,
                          p_user_group_id_list   IN char_32_array_type,
                          p_db_office_id         IN VARCHAR2 DEFAULT NULL);
	PRAGMA DEPRECATE (create_user, 'This method is no longer supported through client-side API. All Oracle account administration is done by the Oracle DBA.');


   PROCEDURE create_cwms_service_user;

   PROCEDURE delete_user (p_username IN VARCHAR2);
   PRAGMA DEPRECATE (delete_user, 'This method is no longer supported through client-side API. All Oracle account administration is done by the Oracle DBA.');

   PROCEDURE lock_user (p_username       IN VARCHAR2,
                        p_db_office_id   IN VARCHAR2 DEFAULT NULL);
   PROCEDURE update_edipi (p_username       IN VARCHAR2,
                        p_edipi   IN NUMBER,p_db_office_id   IN VARCHAR2 DEFAULT NULL);

   PROCEDURE remove_user_from_group (
      p_username        IN VARCHAR2,
      p_user_group_id   IN VARCHAR2,
      p_db_office_id    IN VARCHAR2 DEFAULT NULL);

   FUNCTION get_user_state (p_username       IN VARCHAR2,
                            p_db_office_id   IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2;

   PROCEDURE cat_at_sec_allow (p_at_sec_allow      OUT SYS_REFCURSOR,
                               p_db_office_id   IN     VARCHAR2 DEFAULT NULL);

   FUNCTION cat_at_sec_allow_tab (p_db_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN cat_at_sec_allow_tab_t
      PIPELINED;

   PROCEDURE refresh_mv_sec_ts_privileges;

   PROCEDURE start_refresh_mv_sec_privs_job;
   PROCEDURE start_clean_session_job;

   PROCEDURE store_priv_groups (p_username             IN VARCHAR2,
                                p_user_group_id_list   IN char_32_array_type,
                                p_db_office_id_list    IN char_16_array_type,
                                p_is_member_list       IN char_16_array_type);

   PROCEDURE change_user_group_id (
      p_user_group_id_old   IN VARCHAR2,
      p_user_group_id_new   IN VARCHAR2,
      p_db_office_id        IN VARCHAR2 DEFAULT NULL);

   PROCEDURE change_user_group_desc (
      p_user_group_id     IN VARCHAR2,
      p_user_group_desc   IN VARCHAR2,
      p_db_office_id      IN VARCHAR2 DEFAULT NULL);

   PROCEDURE delete_user_group (p_user_group_id   IN VARCHAR2,
                                p_db_office_id    IN VARCHAR2 DEFAULT NULL);

   PROCEDURE create_user_group (p_user_group_id     IN VARCHAR2,
                                p_user_group_desc   IN VARCHAR2,
                                p_db_office_id      IN VARCHAR2 DEFAULT NULL);

   PROCEDURE delete_ts_group (p_ts_group_id    IN VARCHAR2,
                              p_db_office_id   IN VARCHAR2 DEFAULT NULL);

   PROCEDURE change_ts_group_id (
      p_ts_group_id_old   IN VARCHAR2,
      p_ts_group_id_new   IN VARCHAR2,
      p_db_office_id      IN VARCHAR2 DEFAULT NULL);

   PROCEDURE change_ts_group_desc (
      p_ts_group_id     IN VARCHAR2,
      p_ts_group_desc   IN VARCHAR2,
      p_db_office_id    IN VARCHAR2 DEFAULT NULL);

   PROCEDURE clear_ts_masks (p_ts_group_id    IN VARCHAR2,
                             p_db_office_id   IN VARCHAR2 DEFAULT NULL);

   PROCEDURE assign_ts_masks_to_ts_group (
      p_ts_group_id       IN VARCHAR2,
      p_ts_mask_list      IN str_tab_t,
      p_add_remove_list   IN char_16_array_type,
      p_db_office_id      IN VARCHAR2 DEFAULT NULL);

   PROCEDURE create_ts_group (p_ts_group_id     IN VARCHAR2,
                              p_ts_group_desc   IN VARCHAR2,
                              p_db_office_id    IN VARCHAR2 DEFAULT NULL);

   FUNCTION get_admin_cwms_permissions (p_user_name      IN VARCHAR2,
                                        p_db_office_id   IN VARCHAR2)
      RETURN VARCHAR2;

   PROCEDURE get_user_cwms_permissions (
      p_cwms_permissions      OUT SYS_REFCURSOR,
      p_db_office_id       IN     VARCHAR2,
      p_include_all        IN     BOOLEAN DEFAULT FALSE);

   PROCEDURE get_db_users (p_db_users       OUT SYS_REFCURSOR,
                           p_db_office_id       VARCHAR2);

   PROCEDURE set_pd_user_passwd (p_pd_password   IN VARCHAR2,
                                  p_pd_username   IN VARCHAR2);
   PROCEDURE update_user_data (p_userid     IN VARCHAR2,
                               p_fullname   IN VARCHAR2,
                               p_org        IN VARCHAR2,
                               p_office     IN VARCHAR2,
                               p_phone      IN VARCHAR2,
                               p_email      IN VARCHAR2);
   PRAGMA DEPRECATE (update_user_data, 'This method is no longer supported through client-side API. All Oracle account administration is done by the Oracle DBA.');

  PROCEDURE remove_session_key(p_session_key VARCHAR2);
  PROCEDURE clean_session_keys;
  PROCEDURE get_user_credentials (p_edipi      IN     NUMBER,
                                   p_user          OUT VARCHAR2,
                                   p_session_key      OUT VARCHAR2);
  PROCEDURE get_service_credentials(p_username OUT VARCHAR2,p_password OUT VARCHAR2);
END cwms_sec;
/
