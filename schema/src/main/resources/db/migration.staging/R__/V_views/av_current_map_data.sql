/* Formatted on 10/13/2011 2:25:38 PM (QP5 v5.163.1008.3004) */
--
-- AV_CURRENT_MAP_DATA	(View)
--
--  Dependencies:
--   AT_LOCATION_URL (Table)
--   MV_CWMS_TS_ID (Synonym)
--   AV_CWMS_TS_ID (View)
--   AV_LOC (View)
--   AV_TSV (View)
--   AV_TSV_DQU (View)
--

CREATE OR REPLACE FORCE VIEW av_current_map_data
(
	cwms_ts_id,
	date_time,
	data_entry_date,
	VALUE,
	units,
	db_office_id,
	description,
	loc_active_flag,
	location_type,
	long_name,
	lat,
	lon,
	map_name,
	public_name,
	vertical_datum,
	nearest_city,
	url_address,
	url_title
)
AS
	WITH maxdate
		  AS (SELECT	  MAX (date_time) maxtime, t.cwms_ts_id, t.ts_code
					 FROM   av_tsv v, mv_cwms_ts_id t
					WHERE 		t.ts_code = v.ts_code
							  AND v.date_time > SYSDATE - 30
							  AND v.VALUE IS NOT NULL
				GROUP BY   t.cwms_ts_id, t.ts_code)
	SELECT	m.cwms_ts_id,
				TO_CHAR (FROM_TZ (CAST (a.date_time AS TIMESTAMP), 'UTC') AT TIME ZONE 'US/Eastern', 'mm/dd hh24:mi') "DATE_TIME",
				a.data_entry_date, ROUND (a.VALUE, 1) VALUE, a.unit_id units,
				l.db_office_id, l.description, l.loc_active_flag, l.location_type,
				l.long_name, NVL (l.published_latitude, l.latitude) lat,
				NVL (l.published_longitude, l.longitude) lon,
				NVL (l.map_label, l.long_name) map_name, l.public_name,
				l.vertical_datum, l.nearest_city, u.url_address, u.url_title
	  FROM	av_tsv_dqu a,
				maxdate m,
				av_cwms_ts_id t,
				av_loc l,
				at_location_url u
	 WHERE		 a.ts_code = m.ts_code
				AND a.date_time = m.maxtime
				AND m.cwms_ts_id = t.cwms_ts_id
				AND t.location_code = l.location_code
				AND l.location_code = u.location_code(+)
				AND a.unit_id = 'ft'
				AND l.unit_system = 'EN'
				AND l.loc_active_flag = 'T'
/
