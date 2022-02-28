/**
 * Displays information about outlets at CWMS spillways and weirs
 *
 * @since CWMS 3.0
 *
 * @field office_id            The office owning the spillway or weir
 * @field overflow_location_id The text location identifier of the spillway or weir
 * @field unit_system          The unit system (''EN''/''SI'') for this record
 * @field crest_elevation      The crest elevation in the specified unit
 * @field elevation_unit       The elevation unit for this record''s unit system
 * @field length_or_diameter   The length or diameter of the structure in the the specified unit
 * @field length_unit          The length unit for this record''s unit system
 * @field is_circular          A flag (''T''/''F'') specifying whether this structure is circular
 * @field rating_spec_id       The discharge rating specification for this structure
 * @field description          A description of the structure
 * @field overflow_location_code The unique numeric code that identifies the overflow location in the database
 * @field rating_spec_code       The unique numeric code that identifies the rating specification in the database
 */
create or replace force view av_overflow (
   office_id,
   overflow_location_id,
   unit_system,
   crest_elevation,
   elevation_unit,
   length_or_diameter,
   length_unit,
   is_circular,
   rating_spec_id,
   description,
   overflow_location_code,
   rating_spec_code)
as
select q1.office_id,
       q1.overflow_location_id,
       q1.unit_system,
       q1.crest_elevation,
       q1.elevation_unit,
       q1.length_or_diameter,
       q1.length_unit,
       q1.is_circular,
       q2.rating_spec_id,
       q1.description,
       q1.overflow_location_code,
       q1.rating_spec_code
 from (select co.office_id,
              bl.base_location_id
              ||substr('-', 1, length(pl.sub_location_id))
              ||pl.sub_location_id as overflow_location_id,
              us.unit_system,
              cwms_rounding.round_dt_f(
                case when us.unit_system = 'SI' then crest_elevation
                     else cwms_util.convert_units(crest_elevation, 'm', 'ft')
                     end,
                '7777777777') as crest_elevation,
              case when us.unit_system = 'SI' then 'm'
                   else 'ft'
                   end as elevation_unit,
              cwms_rounding.round_dt_f(
                case when us.unit_system = 'SI' then length_or_diameter
                     else cwms_util.convert_units(length_or_diameter, 'm', 'ft')
                     end,
                '7777777777') as length_or_diameter,
              case when us.unit_system = 'SI' then 'm'
                   else 'ft'
                   end as length_unit,
              ao.is_circular,
              ao.description,
              ao.overflow_location_code,
              ao.rating_spec_code
         from at_overflow ao,
              at_physical_location pl,
              at_base_location bl,
              cwms_office co,
              (select 'EN' as unit_system from dual
               union all
               select 'SI' as unit_system from dual
              ) us
        where pl.location_code = ao.overflow_location_code
          and bl.base_location_code = pl.base_location_code
          and co.office_code = bl.db_office_code
      ) q1
      left outer join
      (select bl.base_location_id
              ||substr('-', 1, length(pl.sub_location_id))
              ||pl.sub_location_id
              ||'.'
              ||rt.parameters_id
              ||'.'
              ||rt.version
              ||'.'
              ||rs.version as rating_spec_id,
              rs.rating_spec_code
         from at_rating_spec rs,
              at_rating_template rt,
              at_physical_location pl,
              at_base_location bl
        where rt.template_code = rs.template_code
          and pl.location_code = rs.location_code
          and bl.base_location_code = pl.base_location_code
      ) q2 on q2.rating_spec_code = q1.rating_spec_code;



create or replace public synonym cwms_v_overflow for av_overflow;
