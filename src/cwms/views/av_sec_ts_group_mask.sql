--
--=============================================================================
-- av_sec_ts_group_mask
--=============================================================================
--

CREATE OR REPLACE FORCE VIEW av_sec_ts_group_mask
(
	db_office_id,
	ts_group_id,
	ts_group_desc,
	ts_group_mask_display,
	db_office_code,
	ts_group_code,
	ts_group_mask
)
AS
	SELECT	    c.office_id db_office_id, 
                b.ts_group_id, 
                b.ts_group_desc,
				CASE 
                  WHEN a.ts_group_mask IS NULL 
                  THEN 
                    NULL 
                  ELSE 
                    cwms_util.denormalize_wildcards (a.ts_group_mask) 
                  END ts_group_mask_display, 
                db_office_code, 
                ts_group_code,
				a.ts_group_mask
	  FROM		at_sec_ts_group_masks a
				RIGHT OUTER JOIN
					at_sec_ts_groups b
				USING (db_office_code, ts_group_code), cwms_office c
	 WHERE	db_office_code = c.office_code AND db_office_code != 0;

/
