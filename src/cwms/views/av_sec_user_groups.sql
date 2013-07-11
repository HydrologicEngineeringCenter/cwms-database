--
--=============================================================================
-- av_sec_user_groups
--=============================================================================
--

CREATE OR REPLACE FORCE VIEW av_sec_user_groups
(
	db_office_id,
	user_group_type,
	user_group_owner,
	user_group_id,
	user_group_desc,
	db_office_code,
	user_group_code
)
AS
	SELECT	b.office_id db_office_id,
				CASE WHEN a.user_group_code < 10 THEN 'Privilege User Group' ELSE 'TS Collection User Group' END user_group_type,
				CASE WHEN a.user_group_code < 20 THEN 'CWMS' ELSE b.office_id END user_group_owner, a.user_group_id, a.user_group_desc,
				a.db_office_code, a.user_group_code
	  FROM	at_sec_user_groups a, cwms_office b
	 WHERE	b.office_code = a.db_office_code AND a.db_office_code != 0;

/
