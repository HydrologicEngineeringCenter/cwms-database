insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_OFFICE', null,
'
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

create or replace force view cwms_20.av_office(
   office_id,
   office_code,
   eroc,
   office_type,
   long_name,
   db_host_office_id,
   db_host_office_code,
   report_to_office_id,
   report_to_office_code)
as
   select o1.office_id,
          o1.office_code,
          o1.eroc,
          o1.office_type,
          o1.long_name,
          o2.office_id   as db_host_office_id,
          o2.office_code as db_host_office_code,
          o3.office_id   as report_to_office_id,
          o3.office_code as report_to_office_code
     from cwms_office o1, 
          cwms_office o2, 
          cwms_office o3
    where o2.office_code = o1.db_host_office_code 
      and o3.office_code = o1.report_to_office_code;
/