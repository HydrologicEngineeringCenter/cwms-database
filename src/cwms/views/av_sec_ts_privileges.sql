--
--=============================================================================
-- av_sec_ts_privileges
--=============================================================================
--

CREATE OR REPLACE FORCE VIEW av_sec_ts_privileges
(
	db_office_code,
	username,
	ts_code,
	net_privilege_bit
)
AS
      SELECT   db_office_code, username, ts_code,
                  SUM (privilege_bit) net_privilege_bit
         FROM   (SELECT    UNIQUE db_office_code, username, ts_code, privilege_bit
                      FROM        (SELECT     db_office_code, username, ts_group_mask,
                                                 privilege_bit
                                        FROM             at_sec_users
                                                     JOIN
                                                         at_sec_allow
                                                     USING (db_office_code, user_group_code)
                                                 JOIN
                                                     at_sec_ts_group_masks
                                                 USING (db_office_code, ts_group_code))
                                JOIN
                                    mv_cwms_ts_id
                                USING (db_office_code)
                     WHERE    UPPER (cwms_ts_id) LIKE ts_group_mask ESCAPE '\')
    GROUP BY   db_office_code, username, ts_code
/
