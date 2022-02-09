-------------------------
-- AV_LOG_MESSAGE view.
--

insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_LOG_MESSAGE', null,
'
/**
 * Displays messages logged to the database
 *
 * @since CWMS 2.1
 *
 * @field msg_id               Unique message identifier, composed of a timestamp in java milliseconds and sequence within that millisecond
 * @field log_timestamp_utc    Time that the message was inserted in the log
 * @field report_timestamp_utc Time that the message was created by the reporting entity
 * @field office_id            Office of the reporting entity
 * @field component            CWMS component of the reporting entity
 * @field instance             Specific instance of component
 * @field host                 Internet address of reporting entity
 * @field port                 Internet port at which reporting entity resides on host
 * @field msg_level            The message level, viewers can filter on this to see more or less detail
 * @field msg_type             The message type (category)
 * @field msg_text             The text of the message
 * @field properties           Any properties associated with the message
 */
');
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
