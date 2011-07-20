-------------------------
-- AV_LOG_MESSAGE view.
--

CREATE OR REPLACE FORCE VIEW av_log_message
(
	msg_id,
	log_timestamp_utc,
	report_timestamp_utc,
	office_id,
	component,
	instance,
	HOST,
	port,
	msg_level,
	msg_type,
	msg_text,
	properties
)
AS
	SELECT	a.msg_id,
				a.log_timestamp_utc,
				a.report_timestamp_utc,
				c.office_id,
				a.component,
				a.instance,
				a.HOST,
				a.port,
				CASE a.msg_level
					WHEN 0 THEN 'None'
					WHEN 1 THEN 'Normal'
					WHEN 2 THEN 'Normal+'
					WHEN 3 THEN 'Basic'
					WHEN 4 THEN 'Basic+'
					WHEN 5 THEN 'Detailed'
					WHEN 6 THEN 'Detailed+'
					WHEN 7 THEN 'Verbose'
				END
					AS msg_level,
				d.message_type_id AS msg_type,
				a.msg_text,
				cwms_msg.parse_log_msg_prop_tab (
					CAST (
						MULTISET (SELECT		b.msg_id,
													b.prop_name,
													b.prop_type,
													b.prop_value,
													b.prop_text
										  FROM	at_log_message_properties b
										 WHERE	b.msg_id = a.msg_id
									 ORDER BY	b.prop_name) AS log_message_props_tab_t
					)
				)
					AS properties
	  FROM	at_log_message a, cwms_office c, cwms_log_message_types d
	 WHERE	c.office_code = a.office_code
				AND d.message_type_code = a.msg_type;

/

SHOW ERRORS;