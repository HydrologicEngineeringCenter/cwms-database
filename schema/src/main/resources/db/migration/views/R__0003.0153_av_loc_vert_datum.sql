delete from at_clob where id = '/VIEWDOCS/AV_LOC_VERT_DATUM';
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_LOC_VERT_DATUM', null,'
/**
 * Displays information on vertical datum offsets
 *
 * @since CWMS 3.2
 *
 * @field location_code           The unique numeric code that identifies the location
 * @field office_id               Office that owns the location
 * @field location_id             The location identifier
 * @field native_datum            The native datum of the location (the datum of the location''s elevation values in the database)
 * @field local_datum_name        The name of the local datum, if any
 * @field ngvd29_offset_si        The SI unit offset from the native dattum to NGVD-29
 * @field ngvd29_offset_en        The English unit offset from the native dattum to NGVD-29
 * @field ngvd29_offset_estimated A flag (T/F) specifying whether offset from the native dattum to NGVD-29 is estimated
 * @field navd88_offset_si        The SI unit offset from the native dattum to NAVD-88
 * @field navd88_offset_en        The English unit offset from the native dattum to NAVD-88
 * @field navd88_offset_estimated A flag (T/F) specifying whether offset from the native dattum to NAVD-88 is estimated
 * @field si_unit                 The unit of the SI unit offset (''m'')
 * @field en_unit                 The unit of the English unit offset (''ft'')
 */
');

create or replace force view av_loc_vert_datum (
   location_code,
   office_id,
   location_id,
   native_datum,
   local_datum_name,
   ngvd29_offset_si,
   ngvd29_offset_en,
   ngvd29_offset_estimated,
   navd88_offset_si,
   navd88_offset_en,
   navd88_offset_estimated,
   si_unit,
   en_unit)
as
select q1.location_code,
       q2.office_id,
       q2.location_id,
       q1.native_datum,
       q1.local_datum_name,
       q1.ngvd29_offset as ngvd29_offset_si,
       round(q1.ngvd29_offset * uc.factor, 4) as ngvd29_offset_en,
       q1.ngvd29_offset_estimated,
       q1.navd88_offset as navd88_offset_si,
       round(q1.navd88_offset * uc.factor, 4) as navd88_offset_en,
       q1.navd88_offset_estimated,
       'm' as si_unit,
       'ft' as en_unit
  from (select location_code,
               case native_datum
                  when 'NGVD-29' then 'NGVD29'
                  when 'NAVD-88' then 'NAVD88'
                  else native_datum
               end as native_datum,
               local_datum_name,
               case native_datum
                  when 'NGVD-29' then 0
                  else ngvd29_offset
               end as ngvd29_offset,
               case native_datum
                  when 'NGVD-29' then 'F'
                  else case ngvd29_offset_estimated
                          when 'true'  then 'T'
                          when 'false' then 'F'
                          else ngvd29_offset_estimated
                       end
               end as ngvd29_offset_estimated,
               case native_datum
                  when 'NAVD-88' then 0
                  else navd88_offset
               end as navd88_offset,
               case native_datum
                  when 'NAVD-88' then 'F'
                  else case navd88_offset_estimated
                          when 'true'  then 'T'
                          when 'false' then 'F'
                          else navd88_offset_estimated
                        end
               end as navd88_offset_estimated
          from(select q11.location_code,
                      cwms_util.get_xml_text  (q11.offset_info, '/vertical-datum-info/native-datum') as native_datum,
                      q12.local_datum_name,
                      cwms_util.get_xml_number(q11.offset_info, '/vertical-datum-info/offset/to-datum[text() = "NGVD-29"]/following-sibling::value') as ngvd29_offset,
                      cwms_util.get_xml_text  (q11.offset_info, '/vertical-datum-info/offset/to-datum[text() = "NGVD-29"]/parent::offset/@estimate') as ngvd29_offset_estimated,
                      cwms_util.get_xml_number(q11.offset_info, '/vertical-datum-info/offset/to-datum[text() = "NAVD-88"]/following-sibling::value') as navd88_offset,
                      cwms_util.get_xml_text  (q11.offset_info, '/vertical-datum-info/offset/to-datum[text() = "NAVD-88"]/parent::offset/@estimate') as navd88_offset_estimated
                 from ((select location_code,
                               xmltype(cwms_loc.get_vertical_datum_info_f(location_code, 'm')) as offset_info
                          from at_physical_location
                       ) q11
                       left outer join
                       (select location_code,
                               local_datum_name
                          from at_vert_datum_local
                       ) q12 on q12.location_code = q11.location_code
                      )
              )
       ) q1
       join
       (select distinct
               location_code,
               location_id,
               db_office_id as office_id
          from av_loc2
       ) q2 on q2.location_code = q1.location_code,
       cwms_unit_conversion uc
 where uc.from_unit_id = 'm'
   and uc.to_unit_id = 'ft';

begin
	execute immediate 'grant select on av_loc_vert_datum to cwms_user';
exception
	when others then null;
end;
/


create or replace public synonym cwms_v_loc_vert_datum for av_loc_vert_datum;