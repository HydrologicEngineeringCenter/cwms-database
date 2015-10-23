insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_USGS_AGENCY', null,'
/**
 * Contains agency ids and names used by the USGS
 *
 * @since CWMS 3.0
 *
 * @param agcy_id   The USGS ID for the agency
 * @param agcy_name The name of the agency 
 */
');
create or replace force view av_usgs_agency(
   agcy_id,
   agcy_name)
as
   select agcy_id, 
          agcy_name 
     from cwms_usgs_agency
     with read only 
/

create or replace public synonym cwms_v_usgs_agency for av_usgs_agency;
