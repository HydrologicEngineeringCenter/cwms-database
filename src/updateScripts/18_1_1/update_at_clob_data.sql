delete from at_clob where clob_code < 0;
delete from at_clob where id = '/VIEWDOCS/AV_USGS_PARAMETER';
delete from at_clob where id = '/VIEWDOCS/MV_RATING_VALUES';
delete from at_clob where id = '/VIEWDOCS/MV_RATING_VALUES_NATIVE';
delete from at_clob where id = '/XSLT/CAT_TS_XML/HTML';
delete from at_clob where id = '/XSLT/CAT_TS_XML/TABBED_TEXT';
delete from at_clob where id = '/XSLT/IDENTITY';
commit;

insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_BASE_PARM_DISPLAY_UNITS', null, '
/**
 * Displays AV_BASE_PARM_DISPLAY_UNITS  information
 *
 * @since CWMS 3.0
 *
 * @field BASE_PARAMETER_CODE        The..
 * @field BASE_PARAMETER_ID          The..
 * @field UNIT_CODE                  The..
 * @field UNIT_ID                    The..
 * @field UNIT_SYSTEM                The..
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_CITIES_SP', null, '
/**
 * Displays AV_CITIES_SP information
 *
 * @since CWMS 2.1
 *
 * @field OBJECTID                   The..
 * @field CITY_FIPS                  The..
 * @field CITY_NAME                  The..
 * @field STATE_FIPS                 The..
 * @field STATE_NAME                 The..
 * @field STATE_CITY                 The..
 * @field TYPE                       The..
 * @field CAPITAL                    The..
 * @field SHAPE                      The..
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_CLOB', null, '
/**
 * Displays information about CLOBs in the database
 *
 * @field clob_code   Unique reference code for this CLOB
 * @field office_code Reference to CWMS office
 * @field id          Unique record identifier, may use hierarchical "/dir/subdir/.../file" format
 * @field description Description of this CLOB
 * @field value       The CLOB data
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_COMPOUND_OUTLET', null, '
/**
 * Displays information about compound outlets (gate sequences) at CWMS projects
 *
 * @since CWMS 3.1
 *
 * @field office_id            Office owning project
 * @field project_id           Name of project that contains the compound outlet
 * @field compound_outlet_id   Name of the compound oulet
 * @field outlet_id            Name of outlet that participates in compound outlet
 * @field next_outlet_id       Name of outlet is next downstream of outlet specified in outlet_id. If null, the outlet
 *                             specified in outlet_id is a downstream-most outlet of the compound outlet and discharges
 *                             into the downstream channel
 * @field project_code         Numeric code that identifies the project in the database
 * @field compound_outlet_code Numeric code that identifies the compound outlet in the database
 * @field outlet_code          Numeric code that identifies the outlet in the database
 * @field next_outlet_code     Numeric code that identifies the next downstream outlet in the database
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_COUNTY_SP', null, '
/**
 * Displays AV_COUNTY_SP information
 *
 * @since CWMS 2.1
 *
 * @field COUNTY_CODE                The..
 * @field OBJECTID                   The..
 * @field STATE                      The..
 * @field COUNTY                     The..
 * @field FIPS                       The..
 * @field SQUARE_MIL                 The..
 * @field SHAPE                      The..
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_CWMS_MEDIA_TYPE', null, '
/**
 * Displays information about internet media types (MIME types) in the database
 * *
 * @field media_type_code The unique numeric value that identifies the media type in the database
 * @field media_type_id   The text identifier of the media type
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_DOCUMENT', null, '
/**
 * Displays information about documents in the database
 *
 * @field db_office_id           The text identfier of the office that owns the document
 * @field base_location_id       The base location identifier of the location that owns the document
 * @field sub_location_id        The sub-location identifier of the location that owns the document
 * @field location_id            The full location identifier of the location that owns the document
 * @field document_code          The unique numeric value that identifies the document in the database
 * @field db_office_code         The foriegn key to the office that owns the document
 * @field document_id            The text identifier of the document.  Must be unique for within an office
 * @field document_type_code     The foreign key to the document type lookup table
 * @field document_location_code The foriegn key to the location that owns the document
 * @field document_url           The URL where the document can be found
 * @field document_date          The initial date of the document
 * @field document_mod_date      The last modified date of the document
 * @field document_obsolete_date The date the document becomes/became obsolete
 * @field document_preview_code  The foreign key to a clob of preview text
 * @field stored_document        The foreign key to at_blob/at_clob that stores the document
 * @field document_type_id       The document type of the document
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_DOCUMENT_TYPE', null, '
/**
 * Displays information about documents types in the database
 * *
 * @field db_office_id                The text identifier of the office that owns the document type
 * @field document_type_code          The unique numeric value that identifies the document type in the database
 * @field db_office_code              The foreign key to the office that owns the document
 * @field document_type_display_value The value to display for the document type
 * @field document_type_tooltop       The tooltip or meaning of the document type
 * @field document_type_active        Whether this document type is currently active
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_EMBANKMENT', null, '
/**
 * Displays information about embankments
 *
 * @field office_id                   The office that owns the project and the embankment
 * @field project_id                  The location text of project that the embankment belongs to
 * @field embankment_location_id      The location text of the embankment
 * @field structure_type_id           The structure type text of the embankment
 * @field upstream_prot_type_id       The protection type text for the upstream or water side of the embankment
 * @field downstream_prot_type_id     The protection type text for the downstream or land side of the embankment
 * @field upstream_sideslope          The upstream side slope (0..1)
 * @field downstream_sideslope        The downstream side slope (0..1)
 * @field unit_system                 The unit system for length, width, and height
 * @field unit_id                     The unit for length, width, and height
 * @field structure_length            The length of the embankment in the specified unit
 * @field height_max                  The maximum height of the embankment in the specified unit
 * @field top_width                   The top width of the embankment in the specified unit
 * @field embankment_project_loc_code The location numeric code of the project that the embankment belongs to
 * @field embankment_location_code    The location numeric code of the embankment
 * @field structure_type_code         The structure type numeric code of the embankment
 * @field upstream_prot_type_code     The protection type numeric code for the upstream or water side of the embankment
 * @field downstream_prot_type_code   The protection type numeric code for the downstream or land side of the embankment
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_EMBANK_PROTECTION_TYPE', null, '
/**
 * Displays information about embankment types
 *
 * @field db_office_id                  The office that owns the protection type
 * @field protection_type_display_value The text name of the protection type
 * @field protection_type_tooltip       A text description of the protection type
 * @field protection_type_active        A flag (T/F) specifying whether the protection type is active
 * @field db_office_code                The numeric code of the office that owns the protection type
 * @field protection_type_code          The numeric code of the protection type
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_EMBANK_STRUCTURE_TYPE', null, '
/**
 * Displays information about embankment types
 *
 * @field db_office_id                 The office that owns the structure type
 * @field structure_type_display_value The text name of the structure type
 * @field structure_type_tooltip       A text description of the structure type
 * @field structure_type_active        A flag (T/F) specifying whether the structure type is active
 * @field db_office_code               The numeric code of the office that owns the structure type
 * @field structure_type_code          The numeric code of the structure type
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_GAGE', null, '
/**
 * Displays CWMS Gages
 *
 * @since CWMS 3.0
 *
 * @field office_id                The office that owns the gage''s location
 * @field location_id              The location where the gage resides
 * @field gage_id                  The text identifier of the gage at this location
 * @field gage_type_id             The text identifier of the gage type
 * @field discontinued             A flag (''T''/''F'') specifying whether the gage has been discontinued
 * @field out_of_service           A flag (''T''/''F'') specifying whether the gage is currently out of service
 * @field manufacturer             The manufacturer of the gage
 * @field model_number             The model number of the gage
 * @field serial_number            The serial number of the gage
 * @field phone_number             The telephone number of the gage if applicable
 * @field internet_address         The internet address of the gage if applicable
 * @field other_access_id          The access identifier of some other communication method of with the gage if applicable
 * @field associated_location_id   The location associated with the gage
 * @field comments                 Any comments about the gage
 * @field gage_code                The unique numeric code that identifies the gage in the database
 * @field location_code            The unique numeric code that identifies the location in the database
 * @field associated_location_code The unique numeric code that identifies the associated location in the database
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_GAGE_METHOD', null, '
/**
 * Displays CWMS Gage Communication Methods
 *
 * @since CWMS 3.0
 *
 * @field method_code The unique numeric code that identifies the gage communication method in the database
 * @field method_id   The text identifier of the gage communication method
 * @field description The description of the gage communication method
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_GAGE_SENSOR', null, '
/**
 * Displays CWMS Gages
 *
 * @since CWMS 3.0
 *
 * @field office_id                The office that owns the location where the sensor''s gage resides
 * @field location_id              The location where the sensor''s gage resides
 * @field gage_id                  The text identifier of the sensor''s gage
 * @field sensor_id                The text identifier of the sensor at the gage
 * @field parameter_id             The parameter that is measured by the sensor
 * @field unit_id                  The unit that the sensor''s data is converted to at the gage
 * @field valid_range_min          The lowest value that the sensor can reliably and accurately measure, in unit_id units
 * @field valid_range_max          The greatest value that the sensor can reliably and accurately measure, in unit_id units
 * @field zero_reading_value       The datum value for the sensor
 * @field out_of_service           A flag (''T''/''F'') specifying whether this sensor is currently out of service
 * @field manufacturer             The manufacturer of the sensor
 * @field model_number             The model number of the sensor
 * @field serial_number            The serial number of the sensor
 * @field comments                 Any comments about the sensor
 * @field gage_code                The unique numeric code that identifies the sensor''s gage in the database
 * @field location_code            The unique numeric code that identifies the location where the sensor''s gage resides in the database
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_GAGE_TYPE', null, '
/**
 * Displays CWMS Gage Types
 *
 * @since CWMS 3.0
 *
 * @field gage_type_code  The unique numeric code that identifies the gage type in the database
 * @field gage_type_id    The text identifier of the gage type
 * @field manually_read   A flag (''T''/''F'') specifying whether the gage type must be manually read
 * @field inquiry_method  The communication type for inquiries to the gage
 * @field transmit_method The communication_type for gage transmissions
 * @field description     A description of the gage type
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_LOCATION_KIND', null, '
/**
 * Displays CWMS Location object types
 *
 * @since CWMS 3.0 (modified in CWMS 2.1)
 *
 * @field location_kind_code   The numeric primary key
 * @field location_kind_id     The text name of the location kind
 * @field parent_location_kind The text name of the parent location kind
 * @field representative_point The point represented by the lat/lon in the physical location table
 * @field description          Descriptive text about the location kind
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_LOC_TS_ID_COUNT', null, '
/**
 * Displays the number of time series associated with each location
 *
 * @since CWMS 2.1
 *
 * @field location_id   The text identifier of the location
 * @field ts_id_count   The number of time series identifiers associated with the location
 * @field location_code The unique numeric code associated with the location
 * @field db_office_id  The office that owns the location
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_NATION_SP', null, '
/**
 * Displays AV_NATION_SP information
 *
 * @since CWMS 2.1
 *
 * @field OBJECTID                   The..
 * @field FIPS_CNTRY                 The..
 * @field GMI_CNTRY                  The..
 * @field ISO_2DIGIT                 The..
 * @field ISO_3DIGIT                 The..
 * @field CNTRY_NAME                 The..
 * @field LONG_NAME                  The..
 * @field SOVEREIGN                  The..
 * @field POP_CNTRY                  The..
 * @field CURR_TYPE                  The..
 * @field CURR_CODE                  The..
 * @field LANDLOCKED                 The..
 * @field SQKM                       The..
 * @field SQMI                       The..
 * @field COLOR_MAP                  The..
 * @field SHAPE                      The..
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_NID', null, '
/**
 * Displays AV_NID information
 *
 * @since CWMS 2.1
 *
 * @field RECORDID                   The..
 * @field DAM_NAME                   The..
 * @field OTHER_DAM_NAME             The..
 * @field DAM_FORMER_NAME            The..
 * @field STATEID                    The..
 * @field NIDID                      The..
 * @field LONGITUDE                  The..
 * @field LATITUDE                   The..
 * @field SECTION                    The..
 * @field COUNTY                     The..
 * @field RIVER                      The..
 * @field CITY                       The..
 * @field DISTANCE                   The..
 * @field OWNER_NAME                 The..
 * @field USACE_CRITICAL             The..
 * @field OWNER_TYPE                 The..
 * @field DAM_DESIGNER               The..
 * @field PRIVATE_DAM                The..
 * @field DAM_TYPE                   The..
 * @field CORE                       The..
 * @field FOUNDATION                 The..
 * @field PURPOSES                   The..
 * @field YEAR_COMPLETED             The..
 * @field YEAR_MODIFIED              The..
 * @field DAM_LENGTH                 The..
 * @field DAM_HEIGHT                 The..
 * @field STRUCTURAL_HEIGHT          The..
 * @field HYDRAULIC_HEIGHT           The..
 * @field NID_HEIGHT                 The..
 * @field MAX_DISCHARGE              The..
 * @field MAX_STORAGE                The..
 * @field NORMAL_STORAGE             The..
 * @field NID_STORAGE                The..
 * @field SURFACE_AREA               The..
 * @field DRAINAGE_AREA              The..
 * @field SORT_CATEGORY              The..
 * @field SHAPE                      The..
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_OFFICE', null, '
/**
 * Displays Time Series Active Information for CWMS Data Stream
 *
 * @since CWMS 2.1
 *
 * @field office_id             The text identifier of the office
 * @field office_code           The unique numeric code that identifies the office in the database
 * @field eroc                  The office''s Corps of Engineers Reporting Organization Code as per ER-37-1-27.
 * @field office_type           UNK=unknown, HQ=corps headquarters, MSC=division headquarters, MSCR=division regional, DIS=district, FOA=field operating activity
 * @field long_name             The office''s descriptive name
 * @field db_host_office_id     The text identifier of the office that hosts the database for this office
 * @field db_host_office_code   The unique numeric code that identifies in the database the office that hosts the database for this office
 * @field report_to_office_id   The text identifier of the office that this office reports to in the organizational hierarchy
 * @field report_to_office_code The unique numeric code that identifies in the database the office that this office reports to in the organizational hierarchy
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_OFFICE_SP', null, '
/**
 * Displays Office Information
 *
 * @since CWMS 2.1
 *
 * @field office_id             The text identifier of the office
 * @field office_code           The unique numeric code that identifies the office in the database
 * @field eroc                  The office''s Corps of Engineers Reporting Organization Code as per ER-37-1-27.
 * @field office_type           UNK=unknown, HQ=corps headquarters, MSC=division headquarters, MSCR=division regional, DIS=district, FOA=field operating activity
 * @field long_name             The office''s descriptive name
 * @field db_host_office_id     The text identifier of the office that hosts the database for this office
 * @field db_host_office_code   The unique numeric code that identifies in the database the office that hosts the database for this office
 * @field report_to_office_id   The text identifier of the office that this office reports to in the organizational hierarchy
 * @field report_to_office_code The unique numeric code that identifies in the database the office that this office reports to in the organizational hierarchy
 * @field shape                 Office Boundary
 * @field shape_office_building Office Building Boundary
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_PROJECT_PURPOSE', null, '
/**
 * Displays information on purposes for specific projects
 *
 * @since CWMS 2.1
 *
 * @field project_location_code  The foreign key to the project this purpose relates to. This key found in AT_PROJECT
 * @field project_purpose_code   The foreign key to the project purpose.  This key is found in AT_PROJECT_PURPOSES
 * @field purpose_type           The purpose type.  Either OPERATIONAL or AUTHORIZED
 * @field additional_notes       Any additional notes pertinent to this project purpose
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_PROJECT_PURPOSES', null, '
/**
 * Displays information on purposes that can be associated with projects
 *
 * @since CWMS 2.1
 *
 * @field office_id              The office that owns the project purpose
 * @field purpose_code           Identifying key for the project purpose
 * @field purpose_display_value  The descriptive text to display for the project purpose
 * @field purpose_tooltip        The tooltip or short description of the project purpose
 * @field purpose_active         Flag (T/F) specifying whether the project purpose is active
 * @field purpose_nid_code       National Inventory of Dams code for this purpose
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_PROJECT_PURPOSES_UI', null, '
/**
 * Displays information on purposes that can be associated with projects
 *
 * @since CWMS 2.1
 *
 * @field office_id              The office for which the project purpose applies.  All offices can apply project purposes owned by the CWMS office.
 * @field purpose_code           Identifying key for the project purpose
 * @field purpose_display_value  The descriptive text to display for the project purpose
 * @field purpose_tooltip        The tooltip or short description of the project purpose
 * @field purpose_active         Flag (T/F) specifying whether the project purpose is active
 * @field purpose_nid_code       National Inventory of Dams code for this purpose
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_PROPERTY', null, '
/**
 * Displays information on properties
 *
 * @since CWMS 2.1
 *
 * @field office_id     Office that owns the property
 * @field prop_category The property category, analogous to the name of a property file
 * @field prop_id       The property identifier, analogous to the property key in a property file
 * @field prop_value    The property value
 * @field prop_comment  An optional comment or description of the property
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_SCREENING_CONTROL', null, '
/**
 * [description needed]
 *
 * @since CWMS 3.0
 *
 * @field screening_code               [description needed]
 * @field db_office_id                 [description needed]
 * @field screening_id                 [description needed]
 * @field range_active_flag            [description needed]
 * @field rate_change_active_flag     [description needed]
 * @field const_active_flag            [description needed]
 * @field dur_mag_active_flag            [description needed]
 * @field rate_change_disp_interval_id    [description needed]
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_SPECIFIED_LEVEL', null, '
/**
 * Displays information about CWMS Specified Levels
 *
 * @field specified_level_code The primary key of the AT_SPECIFIED_LEVEL table
 * @field office_id            The office that owns the specified level.  Levels owned by ''CWMS'' are available to all offices.
 * @field specified_level_id   The specified level
 * @field description          Describes the specified level
 *
 * @see view av_specified_level_ui
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_SPECIFIED_LEVEL_ORDER', null, '
/**
 * Displays AV_SPECIFIED_LEVEL_ORDER information
 *
 * @since CWMS 2.1
 *
 * @field db_office_id               The..
 * @field office_code                The..
 * @field specified_level_code       The..
 * @field specified_level_id         The..
 * @field description                The..
 * @field sort_order                 The..
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_SPECIFIED_LEVEL_UI', null, '
/**
 * Displays specified level sort order for UI components.
 *
 * @field office_id           The office for which the sort order information applies
 * @field specified_level_id  The specified_level
 * @field sort_order          An integer that specifies the order of this specified level in relationship with others
 *
 * @see view av_specified_level
 * @see cwms_display.set_specified_level_ui_info
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_STATE_SP', null, '
/**
 * Displays AV_STATE_SP information
 *
 * @since CWMS 2.1
 *
 * @field STATE_CODE                 The..
 * @field OBJECTID                   The..
 * @field AREA                       The..
 * @field STATE_NAME                 The..
 * @field STATE_FIPS                 The..
 * @field SUB_REGION                 The..
 * @field STATE_ABBR                 The..
 * @field SHAPE                      The..
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_STATION_NWS', null, '
/**
 * Displays AV_STATION_NWS information
 *
 * @since CWMS 2.1
 *
 * @field NWS_ID                     The..
 * @field NWS_NAME                   The..
 * @field LAT                        The..
 * @field LON                        The..
 * @field SHAPE                      The..
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_STATION_USGS', null, '
/**
 * Displays AV_STATION_USGS information
 *
 * @since CWMS 2.1
 *
 * @field AGENCY_CD                  The..
 * @field STATION_ID                 The..
 * @field STATION_NAME               The..
 * @field SITE_TYPE_CODE             The..
 * @field LAT                        The..
 * @field LON                        The..
 * @field COORD_ACY_CD               The..
 * @field DATUM_HORIZONTAL           The..
 * @field ALT_VA                     The..
 * @field ALT_ACY_VA                 The..
 * @field DATUM_VERTICAL             The..
 * @field STATE_ABBR                 The..
 * @field SHAPE                      The..
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_STORE_RULE', null, '
/**
 * Displays information about CWMS Store Rules
 *
 * @field store_rule_code The default sort order of the store rule for offices that don''t specify their own
 * @field store_rule_id   The store rule
 * @field description     Describes the behavior of the store rule
 *
 * @see view av_store_rule_ui
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_STORE_RULE_UI', null, '
/**
 * Displays information about store rule order and defaults for UI components.
 *
 * @field office_id          The office for which the store information applies
 * @field store_rule_id      The store rule
 * @field sort_order         An integer that specifies the order of this store rule in relationship with others
 * @field default_store_rule A flag (T/F) specifying whether the store rule is the default choice for the office
 *
 * @see view av_store_rule
 * @see cwms_display.set_store_rule_ui_info
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_STREAM', null, '
/**
 * Contains non-geographic information for streams
 *
 * @since CWMS 2.1
 *
 * @field stream_location_code  References stream location.
 * @field diverting_stream_code Reference to stream this stream diverts from, if any
 * @field receiving_stream_code Reference to stream this stream flows into, if any
 * @field db_office_id          Office that owns the stream location
 * @field location_id           The text identifier of stream
 * @field zero_station          Specifies whether streams stationing begins upstream or downstream
 * @field average_slope         Average slope in percent over the entire length of the stream
 * @field unit_system           The unit system for station and length values (EN or SI)
 * @field unit_id               The unit for station and length values (mi or km)
 * @field stream_length         The length of this streeam
 * @field diverting_stream_id   The text identifier of the stream this stream diverts, if any
 * @field diversion_station     The station on the diverting stream at which this stream departs
 * @field diversion_bank        The bank on the diverting stream from which this stream departs
 * @field receiving_stream_id   The text identifier of the stream this stream flows into, if any
 * @field confluence_station    The station of the recieving stream at which this stream joins
 * @field confluence_bank       The bank on the receiving stream at which this stream joins
 * @field comments              Additional comments for stream
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_STREAMFLOW_MEAS', null, '
/**
 * Displays information about stream flow measurements in the database
 *
 * @field office_id                The office that owns the location of the measurement
 * @field location_id              The location of the measurement
 * @field meas_number              The serial number of the measurement
 * @field date_time_utc            The date and time the measurement was performed in UTC
 * @field date_time_local          The date and time the measurement was performed in the location''s local time zone
 * @field measurement_used         Flag (T/F) indicating if the discharge measurement is marked as used
 * @field measuring_party          The person(s) that performed the measurement
 * @field measuring_agency         The agency that performed the measurement
 * @field unit_system              The unit system (EN/SI) for this record
 * @field height_unit              The unit for the gage_height, shift_used, and delta_height fields for this record
 * @field flow_unit                The unit for the flow field for this record
 * @field temperature_unit         The unit of the air_temperature and water_temperature fields for this record
 * @field gage_height              Gage height as shown on the inside staff gage or read off the recorder inside the gage house
 * @field flow                     The computed discharge
 * @field cur_rating_num           The number of the rating used to calculate the streamflow from the gage height
 * @field shift_used               The current shift being applied to the rating
 * @field pct_diff                 The percent difference between the measurement and the rating with the shift applied
 * @field quality                  The relative quality of the measurement
 * @field delta_height             The amount the gage height changed while the measurement was being made
 * @field delta_time               The amount of time elapsed while the measurement was being made (hours)
 * @field rating_control_condition The condition of the rating control at the time of the measurement
 * @field flow_adjustment          The adjustment code for the measured discharge
 * @field remarks                  Any remarks about the rating
 * @field air_temperature          The air temperature at the location when the measurement was performed
 * @field water_temperature        The water temperature at the location when the measurement was performed
 * @field wm_comments              Comments about the rating by water management personnel
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_TEXT_FILTER_ELEMENT', null, '
/**
 * Displays information on text filter elements stored in the database
 *
 * @since CWMS 2.2
 *
 * @field text_filter_code Unique numeric code identifying the text filter in the database
 * @field office_id        The office owning the text filter
 * @field text_filter_id   The text identifier (name) of the text filter
 * @field is_regex         A flag (T/F) specifying whether the text filter uses regular expressions
 * @field element_sequence The order in which this element is applied
 * @field inclusion        Specifies whether this element is used include or exclude text
 * @field filter_text      The glob-style wildcard mask or regular expression used to match text for this element
 * @field regex_flags      The Oracle regular expression flags (match parameter) used with this element
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_TIME_ZONE_SP', null, '
/**
 * Displays AV_TIME_ZONE_SP information
 *
 * @since CWMS 2.1
 *
 * @field OBJECTID                   The..
 * @field ZONE                       The..
 * @field SHAPE                      The..
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_USACE_DAM', null, '
/**
 * Displays AV_USACE_DAM information
 *
 * @since CWMS 2.1
 *
 * @field DAM_ID                     The..
 * @field NID_ID                     The..
 * @field STATE_ID_CODE              The..
 * @field DAM_NAME                   The..
 * @field DISTRICT_ID                The..
 * @field STATE_ID                   The..
 * @field COUNTY_ID                  The..
 * @field CITY_ID                    The..
 * @field CITY_DISTANCE              The..
 * @field SECTION                    The..
 * @field LONGITUDE                  The..
 * @field LATITUDE                   The..
 * @field NON_FED_ON_FED_PROPERTY    The..
 * @field RIVER_NAME                 The..
 * @field OWNER_ID                   The..
 * @field HAZARD_CLASS_ID            The..
 * @field EAP_STATUS_ID              The..
 * @field INSPECTION_FREQUENCY       The..
 * @field YEAR_COMPLTED              The..
 * @field CONDITION_ID               The..
 * @field CONDITION_DETAIL           The..
 * @field CONDITION_DATE             The..
 * @field LAST_INSPECTION_DATE       The..
 * @field DAM_LENGTH                 The..
 * @field DAM_HEIGHT                 The..
 * @field STRUCTURAL_HEIGHT          The..
 * @field HYDRAULIC_HEIGHT           The..
 * @field MAX_DISCHARGE              The..
 * @field MAX_STORAGE                The..
 * @field NORMAL_STORAGE             The..
 * @field SURFACE_AREA               The..
 * @field DRAINAGE_AREA              The..
 * @field SPILLWAY_TYPE              The..
 * @field SPILLWAY_WIDTH             The..
 * @field DAM_VOLUME                 The..
 * @field NUM_LOCKS                  The..
 * @field LENGTH_LOCK                The..
 * @field WIDTH_LOCK                 The..
 * @field FED_FUNDED_ID              The..
 * @field FED_DESIGNED_ID            The..
 * @field FED_OWNED_ID               The..
 * @field FED_OPERATED_ID            The..
 * @field FED_CONSTRUCTED_ID         The..
 * @field FED_REGULATED_ID           The..
 * @field FED_INSPECTED_ID           The..
 * @field FED_OTHER_ID               The..
 * @field DATE_UPDATED               The..
 * @field UPDATED_BY                 The..
 * @field DAM_PHOTO                  The..
 * @field OTHER_STRUCTURE_ID         The..
 * @field NUM_SEPERATE_STRUCT        The..
 * @field EXEC_SUMMARY_PATH          The..
 * @field DELETED                    The..
 * @field DELETED_DESCRIPTION        The..
 * @field PROJECT_DSAC_EXEMPT        The..
 * @field BUSINESS_LINE_ID           The..
 * @field SHAPE                      The..
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_USACE_DAM_COUNTY', null, '
/**
 * Displays AV_USACE_DAM_COUNTY information
 *
 * @since CWMS 2.1
 *
 * @field COUNTY_ID                  The..
 * @field STATE_ID                   The..
 * @field COUNTY_NAME                The..
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_USACE_DAM_STATE', null, '
/**
 * Displays AV_USACE_DAM_STATE information
 *
 * @since CWMS 2.1
 *
 * @field   STATE_ID                 The..
 * @field   STATE_NAME               The..
 * @field   STATE_ABBR               The..
 * @field   DISTRICT_ID              The..
 */
');
insert into at_clob values(cwms_seq.nextval, 53, '/VIEWDOCS/AV_USGS_PARAMETER', null, '
/**
 * Contains information for converting USGS parameters to CWMS
 *
 * @since CWMS 2.2
 *
 * @member office_id           The office that owns the conversion
 * @member usgs_parameter_code The 5-digit USGS parameter code to convert
 * @member parameter_id        The CWMS Parameter
 * @member parameter_type_id   The CWMS Parameter Type
 * @member unit_id             The CWMS Unit
 * @member factor              CWMS = USGS * factor + offset
 * @member offset              CWMS = USGS * factor + offset
 */

 0000000	53	/VIEWDOCS/AV_USGS_RATING	None
/**
 * Contains information for retrieving ratings from USGS into the CWMS database
 *
 * @since CWMS 2.2
 *
 * @param office_id             The office that owns the rating
 * @param location_id           The CWMS text identifier of the location for the rating
 * @param usgs_site             The USGS station number
 * @param rating_spec           The CWMS text rating specification
 * @param auto_update_flag      A flag (T/F) specifying whether the rating should be auto-retrieved
 * @param auto_activate_flag    A flag (T/F) specifying whether the rating should be activated if it is auto-retrieved
 * @param auto_migrate_ext_flag A flag (T/F) specifying whether the rating should have any extension migrated if it is auto-retrieved
 * @param rating_method_id      The in-range rating behavior, used to help determine whether Base or EXSA rating should be retrieved
 * @param latest_effecitve      The latest effective date for the rating currently in the database
 * @param latest_create         The latest creation date for the rating currently in the database
 * @param location_code         The CWMS numeric code of the location for the rating
 * @param rating_spec_code      The CWMS numeric code of the rating specification
 */
');
commit;