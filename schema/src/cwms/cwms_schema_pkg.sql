create or replace package cwms_schema
/**
 * Routines to manage versioning of CWMS database
 *
 * @since CWMS 2.1
 *
 * @author Mike Perryman
 */
as

type object_tab_t is table of varchar2(30);

no_such_object exception;

/*
   select object_name
     from user_objects
    where object_type = 'TABLE'
      and regexp_like(object_name, '(CWMS|AT)_.+')
 order by object_name;
*/
table_names constant object_tab_t := object_tab_t(
   'AT_ALARM',
   'AT_ALARM_CRITERIA',
   'AT_ALARM_ID',
   'AT_BASE_LOCATION',
   'AT_BASIN',
   'AT_CLOB',
   'AT_COMPOUND_RATING',
   'AT_COMP_VT',
   'AT_CONSTRUCTION_HISTORY',
   'AT_CWMS_TS_ID',
   'AT_CWMS_TS_SPEC',
   'AT_DATA_FEED_ID',
   'AT_DATA_STREAM_ID',
   'AT_DATA_STREAM_PROPERTIES',
   'AT_DISPLAY_SCALE',
   'AT_DISPLAY_UNITS',
   'AT_DOCUMENT',
   'AT_DOCUMENT_TYPE',
   'AT_EMBANKMENT',
   'AT_EMBANK_PROTECTION_TYPE',
   'AT_EMBANK_STRUCTURE_TYPE',
   'AT_FORECAST_SPEC',
   'AT_FORECAST_TEXT',
   'AT_FORECAST_TS',
   'AT_GAGE',
   'AT_GAGE_SENSOR',
   'AT_GATE_CHANGE',
   'AT_GATE_CH_COMPUTATION_CODE',
   'AT_GATE_RELEASE_REASON_CODE',
   'AT_GATE_SETTING',
   'AT_GEOGRAPHIC_LOCATION',
   'AT_GOES',
   'AT_LOCATION_KIND',
   'AT_LOCATION_LEVEL',
   'AT_LOCATION_URL',
   'AT_LOCK',
   'AT_LOCKAGE',
   'AT_LOC_CATEGORY',
   'AT_LOC_GROUP',
   'AT_LOC_GROUP_ASSIGNMENT',
   'AT_LOC_LVL_INDICATOR',
   'AT_LOC_LVL_INDICATOR_COND',
   'AT_LOC_LVL_INDICATOR_TAB',
   'AT_LOG_MESSAGE',
   'AT_LOG_MESSAGE_PROPERTIES',
   'AT_OFFICE_SETTINGS',
   'AT_OPERATIONAL_STATUS_CODE',
   'AT_OUTLET',
   'AT_OUTLET_CHARACTERISTIC',
   'AT_PARAMETER',
   'AT_PHYSICAL_LOCATION',
   'AT_PHYSICAL_TRANSFER_TYPE',
   'AT_PROJECT',
   'AT_PROJECT_AGREEMENT',
   'AT_PROJECT_CONGRESS_DISTRICT',
   'AT_PROJECT_PURPOSE',
   'AT_PROJECT_PURPOSES',
   'AT_PROPERTIES',
   'AT_RATING',
   'AT_RATING_EXTENSION_VALUE',
   'AT_RATING_IND_PARAMETER',
   'AT_RATING_IND_PARAM_SPEC',
   'AT_RATING_IND_ROUNDING',
   'AT_RATING_SPEC',
   'AT_RATING_TEMPLATE',
   'AT_RATING_VALUE',
   'AT_RATING_VALUE_NOTE',
   'AT_REPORT_TEMPLATES',
   'AT_SCHEMA_OBJECT_DIFF',
   'AT_SCREENING',
   'AT_SCREENING_CONTROL',
   'AT_SCREENING_CRITERIA',
   'AT_SCREENING_DUR_MAG',
   'AT_SCREENING_ID',
   'AT_SEASONAL_LOCATION_LEVEL',
   'AT_SEC_ALLOW',
   'AT_SEC_LOCKED_USERS',
   'AT_SEC_TS_GROUPS',
   'AT_SEC_TS_GROUP_MASKS',
   'AT_SEC_USERS',
   'AT_SEC_USER_GROUPS',
   'AT_SEC_CWMS_USERS',
   'AT_SHEF_CRIT_FILE',
   'AT_SHEF_CRIT_FILE_REC',
   'AT_SHEF_DECODE',
   'AT_SHEF_IGNORE',
   'AT_SHEF_PE_CODES',
   'AT_SHEF_SPEC_MAPPING_UPDATE',
   'AT_SPECIFIED_LEVEL',
   'AT_STREAM',
   'AT_STREAM_LOCATION',
   'AT_STREAM_REACH',
   'AT_TRANSFORM_CRITERIA',
   'AT_TR_TEMPLATE',
   'AT_TR_TEMPLATE_ID',
   'AT_TR_TEMPLATE_SET',
   'AT_TR_TS_MASK',
   'AT_TSV',
   'AT_TSV_2002',
   'AT_TSV_2003',
   'AT_TSV_2004',
   'AT_TSV_2005',
   'AT_TSV_2006',
   'AT_TSV_2007',
   'AT_TSV_2008',
   'AT_TSV_2009',
   'AT_TSV_2010',
   'AT_TSV_2011',
   'AT_TSV_2012',
   'AT_TSV_2013',
   'AT_TSV_2014',
   'AT_TSV_2015',
   'AT_TSV_2016',
   'AT_TSV_2017',
   'AT_TSV_2018',
   'AT_TSV_2019',
   'AT_TSV_2020',
   'AT_TSV_ARCHIVAL',
   'AT_TSV_INF_AND_BEYOND',
   'AT_TS_CATEGORY',
   'AT_TS_DELETED_TIMES',
   'AT_TS_GROUP',
   'AT_TS_GROUP_ASSIGNMENT',
   'AT_TS_MSG_ARCHIVE_1',
   'AT_TS_MSG_ARCHIVE_2',
   'AT_TS_TABLE_PROPERTIES',
   'AT_TURBINE',
   'AT_TURBINE_CHANGE',
   'AT_TURBINE_CHARACTERISTIC',
   'AT_TURBINE_COMPUTATION_CODE',
   'AT_TURBINE_SETTING',
   'AT_TURBINE_SETTING_REASON',
   'AT_UNIT_ALIAS',
   'AT_USER_PREFERENCES',
   'AT_WATER_USER',
   'AT_WATER_USER_CONTRACT',
   'AT_WAT_USR_CONTRACT_ACCOUNTING',
   'AT_WS_CONTRACT_TYPE',
   'AT_XCHG_DATASTORE_DSS',
   'AT_XCHG_DSS_TS_MAPPINGS',
   'AT_XCHG_SET',
   'AT_XREF_WAT_USR_CONTRACT_DOCS',
   'CWMS_ABSTRACT_PARAMETER',
   'CWMS_APEX_ROLES',
   'CWMS_BASE_PARAMETER',
   'CWMS_COUNTY',
   'CWMS_DATA_QUALITY',
   'CWMS_DATA_Q_CHANGED',
   'CWMS_DATA_Q_PROTECTION',
   'CWMS_DATA_Q_RANGE',
   'CWMS_DATA_Q_REPL_CAUSE',
   'CWMS_DATA_Q_REPL_METHOD',
   'CWMS_DATA_Q_SCREENED',
   'CWMS_DATA_Q_TEST_FAILED',
   'CWMS_DATA_Q_VALIDITY',
   'CWMS_DSS_PARAMETER_TYPE',
   'CWMS_DSS_XCHG_DIRECTION',
   'CWMS_DURATION',
   'CWMS_ERROR',
   'CWMS_GAGE_METHOD',
   'CWMS_GAGE_TYPE',
   'CWMS_INTERPOLATE_UNITS',
   'CWMS_INTERVAL',
   'CWMS_INTERVAL_OFFSET',
   'CWMS_LOG_MESSAGE_PROP_TYPES',
   'CWMS_LOG_MESSAGE_TYPES',
   'CWMS_MSG_ID',
   'CWMS_NATION',
   'CWMS_OFFICE',
   'CWMS_PARAMETER_TYPE',
   'CWMS_RATING_METHOD',
   'CWMS_SCHEMA_OBJECT_VERSION',
   'CWMS_SEC_PRIVILEGES',
   'CWMS_SEC_TS_GROUPS',
   'CWMS_SEC_USER_GROUPS',
   'CWMS_SHEF_DURATION',
   'CWMS_SHEF_EXTREMUM_CODES',
   'CWMS_SHEF_PE_CODES',
   'CWMS_SHEF_TIME_ZONE',
   'CWMS_STATE',
   'CWMS_STREAM_TYPE',
   'CWMS_TIME_ZONE',
   'CWMS_TIME_ZONE_ALIAS',
   'CWMS_TR_TRANSFORMATIONS',
   'CWMS_TZ_USAGE',
   'CWMS_UNIT',
   'CWMS_UNIT_CONVERSION');
/*
   select object_name
     from user_objects
    where object_type = 'PACKAGE'
 order by object_name;
*/
package_names constant object_tab_t := object_tab_t(
	'CWMS_APEX',
	'CWMS_BASIN',
	'CWMS_CAT',
	'CWMS_DISPLAY',
	'CWMS_EMBANK',
	'CWMS_ERR',
	'CWMS_FORECAST',
	'CWMS_GAGE',
	'CWMS_LEVEL',
	'CWMS_LOC',
	'CWMS_LOCK',
	'CWMS_LOOKUP',
	'CWMS_MSG',
	'CWMS_OUTLET',
	'CWMS_PRIV',
	'CWMS_PROJECT',
	'CWMS_PROPERTIES',
	'CWMS_RATING',
	'CWMS_ROUNDING',
   'CWMS_SCHEMA',
	'CWMS_SEC',
	'CWMS_SEC_POLICY',
	'CWMS_SHEF',
	'CWMS_STREAM',
	'CWMS_TEXT',
	'CWMS_TS',
	'CWMS_TS_ID',
	'CWMS_TURBINE',
	'CWMS_UTIL',
	'CWMS_VT',
	'CWMS_WATER_SUPPLY',
	'CWMS_XCHG');
/*
   select  '   '||CHR(39)||object_name||CHR(39)||','
     from user_objects
    where object_type = 'VIEW'
      and regexp_like(object_name, '(AV|ZAV|ZV)_.+')
 order by object_name;
*/
view_names constant object_tab_t := object_tab_t(
   'AV_A2W_TS_CODES_BY_LOC',
   'AV_A2W_TS_CODES_BY_LOC2',
   'AV_ACTIVE_FLAG',
   'AV_APPLICATION_LOGIN',
   'AV_APPLICATION_SESSION',
   'AV_AUTH_SCHED_ENTRIES',
   'AV_BASE_PARAMETER_UNITS',
   'AV_BASE_PARM_DISPLAY_UNITS',
   'AV_BASIN',
   'AV_CITIES_SP',
   'AV_CLOB',
   'AV_COMPOUND_OUTLET',
   'AV_CONFIGURATION',
   'AV_CONFIGURATION_CATEGORY',
   'AV_COUNTY',
   'AV_COUNTY_SP',
   'AV_CURRENT_MAP_DATA',
   'AV_CWMS_MEDIA_TYPE',
   'AV_CWMS_TS_ID',
   'AV_CWMS_TS_ID2',
   'AV_CWMS_USER',
   'AV_DATAEXCHANGE_JOB',
   'AV_DATA_QUALITY',
   'AV_DATA_Q_CHANGED',
   'AV_DATA_Q_PROTECTION',
   'AV_DATA_Q_RANGE',
   'AV_DATA_Q_REPL_CAUSE',
   'AV_DATA_Q_REPL_METHOD',
   'AV_DATA_Q_SCREENED',
   'AV_DATA_Q_TEST_FAILED',
   'AV_DATA_Q_VALIDITY',
   'AV_DATA_STREAMS',
   'AV_DATA_STREAMS_CURRENT',
   'AV_DB_CHANGE_LOG',
   'AV_DISPLAY_UNITS',
   'AV_DOCUMENT',
   'AV_DOCUMENT_TYPE',
   'AV_EMBANKMENT',
   'AV_EMBANK_PROTECTION_TYPE',
   'AV_EMBANK_STRUCTURE_TYPE',
   'AV_ENTITY',
   'AV_ENTITY_CATEGORY',
   'AV_ENTITY_LOCATION',
   'AV_FORECAST',
   'AV_FORECAST_EX',
   'AV_FORECAST_SPEC',
   'AV_GAGE',
   'AV_GAGE_METHOD',
   'AV_GAGE_SENSOR',
   'AV_GAGE_TYPE',
   'AV_GATE',
   'AV_GATE_CHANGE',
   'AV_GATE_SETTING',
   'AV_LOC',
   'AV_LOC2',
   'AV_LOC2_TEST',
   'AV_LOC5_TEST',
   'AV_LOCATION_KIND',
   'AV_LOCATION_LEVEL',
   'AV_LOCATION_LEVEL_CURVAL',
   'AV_LOCATION_TYPE',
   'AV_LOCK',
   'AV_LOC_ALIAS',
   'AV_LOC_CAT_GRP',
   'AV_LOC_GRP_ASSGN',
   'AV_LOC_LVL_ATTRIBUTE',
   'AV_LOC_LVL_CUR_MAX_IND',
   'AV_LOC_LVL_INDICATOR',
   'AV_LOC_LVL_INDICATOR_2',
   'AV_LOC_LVL_LABEL',
   'AV_LOC_LVL_SOURCE',
   'AV_LOC_LVL_TS_MAP',
   'AV_LOC_TS_ID_COUNT',
   'AV_LOC_VERT_DATUM',
   'AV_LOG_MESSAGE',
   'AV_MKFTEMP',
   'AV_NATION',
   'AV_NATION_SP',
   'AV_NID',
   'AV_OFFICE',
   'AV_OFFICE_SP',
   'AV_OUTLET',
   'AV_OVERFLOW',
   'AV_PARAMETER',
   'AV_POOL',
   'AV_POOL_NAME',
   'AV_PROJECT',
   'AV_PROJECT_PURPOSE',
   'AV_PROJECT_PURPOSES',
   'AV_PROJECT_PURPOSES_UI',
   'AV_PROPERTY',
   'AV_PUMP',
   'AV_QUEUE_MESSAGES',
   'AV_QUEUE_SUBSCRIBER_NAME',
   'AV_RATING',
   'AV_RATING_LOCAL',
   'AV_RATING_SPEC',
   'AV_RATING_TEMPLATE',
   'AV_RATING_VALUES',
   'AV_RATING_VALUES_NATIVE',
   'AV_SCREENED_TS_IDS',
   'AV_SCREENING_ASSIGNMENTS',
   'AV_SCREENING_CONTROL',
   'AV_SCREENING_CRITERIA',
   'AV_SCREENING_DUR_MAG',
   'AV_SCREENING_ID',
   'AV_SEC_TS_GROUP_MASK',
   'AV_SEC_TS_PRIVILEGES',
   'AV_SEC_TS_PRIVILEGES_MV',
   'AV_SEC_USERS',
   'AV_SEC_USER_GROUPS',
   'AV_SHEF_DECODE_SPEC',
   'AV_SHEF_PE_CODES',
   'AV_SPECIFIED_LEVEL',
   'AV_SPECIFIED_LEVEL_ORDER',
   'AV_SPECIFIED_LEVEL_UI',
   'AV_STATE',
   'AV_STATE_SP',
   'AV_STATION_NWS',
   'AV_STATION_USGS',
   'AV_STD_TEXT',
   'AV_STORAGE_UNIT',
   'AV_STORE_RULE',
   'AV_STORE_RULE_UI',
   'AV_STREAM',
   'AV_STREAMFLOW_MEAS',
   'AV_STREAM_LOCATION',
   'AV_TEXT_FILTER',
   'AV_TEXT_FILTER_ELEMENT',
   'AV_TIME_ZONE_SP',
   'AV_TRANSITIONAL_RATING',
   'AV_TSV',
   'AV_TSV_COUNT_DAY',
   'AV_TSV_COUNT_MINUTE',
   'AV_TSV_DQU',
   'AV_TSV_DQU_24H',
   'AV_TSV_DQU_30D',
   'AV_TSV_ELEV',
   'AV_TS_ALIAS',
   'AV_TS_ASSOCIATION',
   'AV_TS_CAT_GRP',
   'AV_TS_EXTENTS_LOCAL',
   'AV_TS_EXTENTS_UTC',
   'AV_TS_GRP_ASSGN',
   'AV_TS_MSG_ARCHIVE',
   'AV_TS_PROFILE',
   'AV_TS_PROFILE_INST',
   'AV_TS_PROFILE_INST_ELEV',
   'AV_TS_PROFILE_INST_SP',
   'AV_TS_PROFILE_INST_TS',
   'AV_TS_PROFILE_INST_TSV',
   'AV_TS_PROFILE_INST_TSV2',
   'AV_TS_PROFILE_PARSER',
   'AV_TS_PROFILE_PARSER_PARAM',
   'AV_TS_TEXT',
   'AV_TURBINE',
   'AV_TURBINE_CHANGE',
   'AV_TURBINE_SETTING',
   'AV_UNAUTH_SCHED_ENTRIES',
   'AV_UNIT',
   'AV_USACE_DAM',
   'AV_USACE_DAM_COUNTY',
   'AV_USACE_DAM_STATE',
   'AV_USGS_PARAMETER',
   'AV_USGS_PARAMETER_ALL',
   'AV_USGS_RATING',
   'AV_VERT_DATUM_OFFSET',
   'AV_VIRTUAL_RATING',
   'AV_WATER_USER_CONTRACT',
   'AV_WATER_USER_CONTRACT2',
   'ZAV_CWMS_TS_ID',
   'ZV_CURRENT_CRIT_FILE_CODE');
/*
   select object_name
     from user_objects
    where object_type = 'TYPE'
      and object_name not like 'SYS\_%' escape '\'
 order by object_name;
*/
type_names constant object_tab_t := object_tab_t(
	'ABS_RATING_IND_PARAM_T',
	'CAT_COUNTY_OBJ_T',
	'CAT_COUNTY_OTAB_T',
	'CAT_DSS_FILE_OBJ_T',
	'CAT_DSS_FILE_OTAB_T',
	'CAT_DSS_XCHG_SET_OBJ_T',
	'CAT_DSS_XCHG_SET_OTAB_T',
	'CAT_DSS_XCHG_TSMAP_OTAB_T',
	'CAT_DSS_XCHG_TS_MAP_OBJ_T',
	'CAT_LOCATION2_OBJ_T',
	'CAT_LOCATION2_OTAB_T',
	'CAT_LOCATION_KIND_OBJ_T',
	'CAT_LOCATION_KIND_OTAB_T',
	'CAT_LOCATION_OBJ_T',
	'CAT_LOCATION_OTAB_T',
	'CAT_LOC_ALIAS_OBJ_T',
	'CAT_LOC_ALIAS_OTAB_T',
	'CAT_LOC_OBJ_T',
	'CAT_LOC_OTAB_T',
	'CAT_PARAM_OBJ_T',
	'CAT_PARAM_OTAB_T',
	'CAT_STATE_OBJ_T',
	'CAT_STATE_OTAB_T',
	'CAT_SUB_LOC_OBJ_T',
	'CAT_SUB_LOC_OTAB_T',
	'CAT_SUB_PARAM_OBJ_T',
	'CAT_SUB_PARAM_OTAB_T',
	'CAT_TIMEZONE_OBJ_T',
	'CAT_TIMEZONE_OTAB_T',
	'CAT_TS_CWMS_20_OBJ_T',
	'CAT_TS_CWMS_20_OTAB_T',
	'CAT_TS_OBJ_T',
	'CAT_TS_OTAB_T',
	'CHARACTERISTIC_OBJ_T',
	'CHARACTERISTIC_REF_T',
	'CHARACTERISTIC_TAB_T',
	'CHAR_16_ARRAY_TYPE',
	'CHAR_183_ARRAY_TYPE',
	'CHAR_32_ARRAY_TYPE',
	'CHAR_49_ARRAY_TYPE',
	'CWMS_TS_ID_ARRAY',
	'CWMS_TS_ID_T',
	'DATE_TABLE_TYPE',
	'DOCUMENT_OBJ_T',
	'DOCUMENT_TAB_T',
	'DOUBLE_TAB_T',
	'DOUBLE_TAB_TAB_T',
	'EMBANKMENT_OBJ_T',
	'EMBANKMENT_TAB_T',
	'GATE_CHANGE_OBJ_T',
	'GATE_CHANGE_TAB_T',
	'GATE_SETTING_OBJ_T',
	'GATE_SETTING_TAB_T',
	'GROUP_ARRAY',
	'GROUP_ARRAY2',
	'GROUP_CAT_T',
	'GROUP_CAT_TAB_T',
	'GROUP_TYPE',
	'GROUP_TYPE2',
	'JMS_MAP_MSG_TAB_T',
	'LOCATION_LEVEL_T',
	'LOCATION_LEVEL_TAB_T',
	'LOCATION_OBJ_T',
	'LOCATION_REF_T',
	'LOCATION_REF_TAB_T',
	'LOCK_OBJ_T',
	'LOC_ALIAS_ARRAY',
	'LOC_ALIAS_ARRAY2',
	'LOC_ALIAS_ARRAY3',
	'LOC_ALIAS_TYPE',
	'LOC_ALIAS_TYPE2',
	'LOC_ALIAS_TYPE3',
	'LOC_LVL_INDICATOR_COND_T',
	'LOC_LVL_INDICATOR_T',
	'LOC_LVL_INDICATOR_TAB_T',
	'LOC_LVL_IND_COND_TAB_T',
	'LOC_REF_TIME_WINDOW_OBJ_T',
	'LOC_REF_TIME_WINDOW_TAB_T',
	'LOC_TYPE_DS',
	'LOG_MESSAGE_PROPERTIES_T',
	'LOG_MESSAGE_PROPS_TAB_T',
	'LOOKUP_TYPE_OBJ_T',
	'LOOKUP_TYPE_TAB_T',
	'NESTED_TS_TABLE',
	'NESTED_TS_TYPE',
	'NUMBER_TAB_T',
	'PROJECT_OBJ_T',
	'PROJECT_STRUCTURE_OBJ_T',
	'PROJECT_STRUCTURE_TAB_T',
	'PROPERTY_INFO2_T',
	'PROPERTY_INFO2_TAB_T',
	'PROPERTY_INFO_T',
	'PROPERTY_INFO_TAB_T',
	'RATING_IND_PARAMETER_T',
	'RATING_IND_PARAM_SPEC_T',
	'RATING_IND_PARAM_TAB_T',
	'RATING_IND_PAR_SPEC_TAB_T',
	'RATING_SPEC_T',
	'RATING_SPEC_TAB_T',
	'RATING_T',
	'RATING_TAB_T',
	'RATING_TEMPLATE_T',
	'RATING_TEMPLATE_TAB_T',
	'RATING_VALUE_NOTE_T',
	'RATING_VALUE_NOTE_TAB_T',
	'RATING_VALUE_T',
	'RATING_VALUE_TAB_T',
	'SCREENING_CONTROL_T',
	'SCREEN_ASSIGN_ARRAY',
	'SCREEN_ASSIGN_T',
	'SCREEN_CRIT_ARRAY',
	'SCREEN_CRIT_TYPE',
	'SCREEN_DUR_MAG_ARRAY',
	'SCREEN_DUR_MAG_TYPE',
	'SEASONAL_LOCATION_LEVEL_T',
	'SEASONAL_LOC_LVL_TAB_T',
	'SEASONAL_VALUE_T',
	'SEASONAL_VALUE_TAB_T',
	'SHEF_SPEC_ARRAY',
	'SHEF_SPEC_TYPE',
	'SOURCE_ARRAY',
	'SOURCE_TYPE',
	'SPECIFIED_LEVEL_T',
	'SPECIFIED_LEVEL_TAB_T',
	'STREAM_RATING_T',
	'STRING_AGG_TYPE',
	'STR_TAB_T',
	'STR_TAB_TAB_T',
	'TIMESERIES_ARRAY',
	'TIMESERIES_REQ_ARRAY',
	'TIMESERIES_REQ_TYPE',
	'TIMESERIES_TYPE',
	'TIME_SERIES_RANGE_T',
	'TIME_SERIES_RANGE_TAB_T',
	'TR_TEMPLATE_SET_ARRAY',
	'TR_TEMPLATE_SET_TYPE',
	'TSV_ARRAY',
	'TSV_TYPE',
	'TS_ALIAS_T',
	'TS_ALIAS_TAB_T',
	'TURBINE_CHANGE_OBJ_T',
	'TURBINE_CHANGE_TAB_T',
	'TURBINE_SETTING_OBJ_T',
	'TURBINE_SETTING_TAB_T',
	'WATER_USER_CONTRACT_OBJ_T',
	'WATER_USER_CONTRACT_REF_T',
	'WATER_USER_CONTRACT_TAB_T',
	'WATER_USER_OBJ_T',
	'WATER_USER_TAB_T',
	'WAT_USR_CONTRACT_ACCT_OBJ_T',
	'WAT_USR_CONTRACT_ACCT_TAB_T',
	'ZLOCATION_LEVEL_T',
	'ZLOC_LVL_INDICATOR_T',
	'ZLOC_LVL_INDICATOR_TAB_T',
	'ZTIMESERIES_ARRAY',
	'ZTIMESERIES_TYPE',
	'ZTSV_ARRAY',
	'ZTSV_ARRAY_TAB',
	'ZTSV_TYPE');
/*
   select object_name
     from user_objects
    where object_type = 'TYPE BODY'
      and object_name not like 'SYS\_%' escape '\'
 order by object_name;
*/
type_body_names constant object_tab_t := object_tab_t(
	'ABS_RATING_IND_PARAM_T',
	'LOCATION_LEVEL_T',
	'LOCATION_OBJ_T',
	'LOCATION_REF_T',
	'LOC_LVL_INDICATOR_COND_T',
	'LOC_LVL_INDICATOR_T',
	'RATING_IND_PARAMETER_T',
	'RATING_IND_PARAM_SPEC_T',
	'RATING_SPEC_T',
	'RATING_T',
	'RATING_TEMPLATE_T',
	'RATING_VALUE_NOTE_T',
	'RATING_VALUE_T',
	'SEASONAL_VALUE_T',
	'SPECIFIED_LEVEL_T',
	'STREAM_RATING_T',
	'STRING_AGG_TYPE',
	'ZLOCATION_LEVEL_T',
	'ZLOC_LVL_INDICATOR_T');
   
dependent_type_names constant object_tab_t := object_tab_t(
   'INDEX',
   'OBJECT_GRANT',
   'TRIGGER'
);
/* (Non-javadoc)
 * Sets the schema version for the current database object state. The database
 * object state is the current state of tables, views, package specs and bodies,
 * and type specs and bodies.  Each object is hashed and the hash code is stored
 * with the current UTC date/time, the specified cwms version, and optional comments.
 *
 *
 * @param p_cwms_version A version string for the current object state. The full
 * version will the UTC date/time this procedure is called (yyyy/mm/dd hh:mm:ss)
 * followed by the specified version string.
 *
 * @param p_comments Optional comments that get stored about the database object
 * state for each object.
 */
procedure set_schema_version(
   p_cwms_version  in varchar2,
   p_comments      in varchar2 default null);

/**
 * Checks the current database object state against the latest stored version. If
 * any table, view, package spec or body, or type spec or body does not hash to
 * the hash code stored for that object for the latest version, a line will be
 * logged and printed identifying the object type, object name and matched version,
 * if any. All log entries and printed output begin with 'CHECK_SCHEMA_VERSION : '.
 */
procedure check_schema_version;

/**
 * Dumps the current contents of the table that stores database object versions
 * in a format that the output can be used to generate or update scripts used
 * to populate the table when building the database.
 */
procedure output_schema_versions;

/**
 * Outputs (via dbms_output) the results of the latest completed execution of
 * check_schema_vesion.
 */
procedure output_latest_results;

/**
 * Loads the deployed and current ddl for a specified schema object into the
 * AT_SCHEMA_OBJECT_DIFF table for comparison
 *
 * @param p_object_type The type of the schema object (table, package, etc...)
 * @param p_object_name The name of the schema object
 */
procedure compare_ddl(
   p_object_type in varchar2,
   p_object_name in varchar2);
   
/**
 * Schedules background execution of check_schema_version. The default schedule is
 * to run once a day, starting when this procedure is executed. The property
 * CWMSDB/check_schema.interval can be set to the number of minutes between runs
 * if desired.
 */
procedure start_check_schema_job;

/**
 * Returns the currently-deployed schema version
 */
function get_schema_version
   return varchar2;

procedure cleanup_schema_version_table;

function get_latest_hash(
   p_object_type in varchar2,
   p_object_name in varchar2)
   return varchar2;

function get_latest_ddl(
   p_object_type in varchar2,
   p_object_name in varchar2)
   return clob;

function get_latest_static_data
   return clob;

function get_current_ddl(
   p_object_type in varchar2,
   p_object_name in varchar2)
   return clob;
   
pragma exception_init(no_such_object, -31603);

end cwms_schema;
/
show errors
