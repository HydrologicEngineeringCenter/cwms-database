insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_LOCATION_TYPE', null,
'
/**
 * Displays location types in the CWMS database.
 * <p>
 * The types reported are not taken from the location''s LOCATION_TYPE field but
 * are determined from the database relationships managed by the API for various location types.
 * <p>
 * Location types will be one of
 * <ul>
 *   <li>BASIN</li>
 *   <li>STREAM</li>
 *   <li>OUTLET</li>
 *   <li>TURBINE</li>
 *   <li>PROJECT</li>
 *   <li>EMBANKMENT</li>
 *   <li>LOCK</li>
 *   <li>NONE</li>
 * </ul>
 *
 * @since CWMS 2.1
 *
 * @field location_code    The unique numeric code that identifies the location
 * @field office_id        The office that owns the location
 * @field base_location_id The base location identifer
 * @field sub_location_id  The sub-location identifer
 * @field location_id      The full location identifier
 * @field location_type    The location type
 */
');
create or replace force view av_location_type
(
   location_code,
   office_id,
   base_location_id,
   sub_location_id,
   location_id,
   location_type
)
as
select pl.location_code,
       o.office_id,
       bl.base_location_id,
       pl.sub_location_id,
       bl.base_location_id
       ||substr('-', 1, length(pl.sub_location_id))
       ||pl.sub_location_id as location_id,
       cwms_loc.get_location_type(pl.location_code) as location_type
  from at_physical_location pl,
       at_base_location bl,
       cwms_office o
 where pl.location_code > 0
   and bl.base_location_code = pl.base_location_code
   and o.office_code = bl.db_office_code;
/
