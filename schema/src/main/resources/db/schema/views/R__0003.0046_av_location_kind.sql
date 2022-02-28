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
create or replace force view av_location_kind(
   location_kind_code,
   location_kind_id,
   parent_location_kind,
   representative_point,
   description)
as
     select lk1.location_kind_code,
            lk1.location_kind_id,
            lk2.location_kind_id as parent_location_kind,
            lk1.representative_point,
            lk1.description
       from cwms_location_kind lk1, cwms_location_kind lk2
      where lk2.location_kind_code(+) = lk1.parent_location_kind
   order by lk1.location_kind_code;
