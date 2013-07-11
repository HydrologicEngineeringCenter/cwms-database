--
--=============================================================================
-- av_sec_ts_privileges_mv
--=============================================================================
--
CREATE OR REPLACE FORCE VIEW av_sec_ts_privileges_mv
(
    db_office_code,
    username,
    ts_code,
    net_privilege_bit
)
AS
    SELECT    db_office_code, username, ts_code, net_privilege_bit
      FROM        av_sec_ts_privileges
                JOIN
                    at_sec_locked_users
                USING (db_office_code, username)
     WHERE    is_locked != 'T'
/
