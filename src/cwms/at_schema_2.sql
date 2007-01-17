/* Formatted on 2006/12/19 11:53 (Formatter Plus v4.8.8) */
-------------------------
-- AV_LOC view.
-- 
CREATE OR REPLACE VIEW av_loc (location_code,
                               base_location_code,
                               db_office_id,
                               base_location_id,
                               sub_location_id,
                               location_id,
                               location_type,
                               unit_system,
                               elevation,
                               unit_id,
                               vertical_datum,
                               longitude,
                               latitude,
                               horizontal_datum,
                               time_zone_name,
                               county_name,
                               state_initial,
                               public_name,
                               long_name,
                               description,
                               active_flag
                              )
AS
   SELECT apl.location_code, abl.base_location_code,
          co.office_id db_office_id, abl.base_location_id,
          apl.sub_location_id,
             abl.base_location_id
          || SUBSTR ('-', 1, LENGTH (apl.sub_location_id))
          || apl.sub_location_id location_id,
          apl.location_type, adu.unit_system,
          TO_NUMBER (apl.elevation * cuc.factor + cuc.offset) elevation,
          cuc.to_unit_id unit_id, apl.vertical_datum, apl.longitude,
          apl.latitude, apl.horizontal_datum, ctz.time_zone_name,
          cc.county_name, cs.state_initial, apl.public_name, apl.long_name,
          apl.description, apl.active_flag
     FROM at_physical_location apl,
          at_base_location abl,
          cwms_county cc,
          cwms_office co,
          cwms_state cs,
          cwms_time_zone ctz,
          at_display_units adu,
          cwms_unit_conversion cuc
    WHERE (cc.county_code = NVL (apl.county_code, 0))
      AND (cs.state_code = NVL (cc.state_code, 0))
      AND (abl.db_office_code = co.office_code)
      AND (ctz.time_zone_code = NVL (apl.time_zone_code, 0))
      AND apl.base_location_code = abl.base_location_code
      AND apl.location_code != 0
      AND adu.parameter_code =
                         cwms_ts.get_parameter_code ('Elev', NULL, 'ALL', 'F')
      AND cuc.from_unit_id = 'm'
      AND cuc.to_unit_code = adu.display_unit_code
      AND adu.db_office_code = abl.db_office_code;
/
SHOW ERRORS;
COMMIT;
-----------------------------
-- AT_DSS_TS_SPEC trigger
--
create or replace trigger at_dss_ts_spec_units
before insert or update of unit_id
on at_dss_ts_spec
referencing new as new old as old
for each row
declare
   l_count number;
begin
   select count(unit_id)
     into l_count
     from (
            select unit_id from cwms_unit
            union
            select alias_id unit_id from at_unit_alias 
             where db_office_code in (
                                      select db_office_code from cwms_office where office_code = 'ALL'
                                      union
                                      select db_office_code from cwms_office where office_code = :new.office_code
                                     )
          )
    where unit_id = :new.unit_id;
   
   if l_count = 0 then
      cwms_err.raise('INVALID_ITEM', :new.unit_id, 'unit');
   end if;
end at_dss_ts_spec_units;
/
show errors;
commit;
