--
--=============================================================================
-- av_sec_users
--=============================================================================
--
CREATE OR REPLACE FORCE VIEW CWMS_20.AV_SEC_USERS
(
   USERNAME,
   DB_OFFICE_ID,
   USER_GROUP_TYPE,
   USER_GROUP_OWNER,
   USER_GROUP_ID,
   IS_MEMBER,
   IS_LOCKED,
   USER_GROUP_DESC,
   DB_OFFICE_CODE,
   USER_GROUP_CODE
)
AS
   SELECT username,
          db_office_id,
          CASE
             WHEN user_group_code < 10 THEN 'Privilege User Group'
             ELSE 'TS Collection User Group'
          END
             user_group_type,
          CASE WHEN user_group_code < 20 THEN 'CWMS' ELSE db_office_id END
             user_group_owner,
          user_group_id,
          is_member,
          CASE WHEN is_locked IS NULL THEN 'F' ELSE is_locked END is_locked,
          user_group_desc,
          db_office_code,
          user_group_code
     FROM    (SELECT username,
                     db_office_id,
                     user_group_id,
                     user_group_desc,
                     db_office_code db_office_code,
                     user_group_code,
                     CASE
                        WHEN ROWIDTOCHAR (b.ROWID) IS NOT NULL THEN 'T'
                        ELSE 'F'
                     END
                        is_member
                FROM    (SELECT a.userid username,
                                c.office_id db_office_id,
                                b.user_group_id,
                                b.user_group_desc,
                                b.db_office_code,
                                b.user_group_code,
                                'T' is_member
                           FROM at_sec_cwms_users a,
                                at_sec_user_groups b,
                                cwms_office c
                          WHERE b.db_office_code = c.office_code) a
                     LEFT OUTER JOIN
                        at_sec_users b
                     USING (username, db_office_code, user_group_code)) a
          LEFT OUTER JOIN
             at_sec_locked_users
          USING (username, db_office_code);
/
