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
create or replace force view av_embankment(
   office_id,
   project_id,
   embankment_location_id,
   structure_type_id,
   upstream_prot_type_id,
   downstream_prot_type_id,
   upstream_sideslope,
   downstream_sideslope,
   unit_system,
   unit_id,
   structure_length,
   height_max,
   top_width,
   embankment_project_loc_code,
   embankment_location_code,
   structure_type_code,
   upstream_prot_type_code,
   downstream_prot_type_code)
as
   select l1.db_office_id as office_id,
          l2.location_id as project_id,
          l1.location_id as embankment_location_id,
          est.structure_type_display_value as structure_type_id,
          ept1.protection_type_display_value as upstream_prot_type_id,
          ept2.protection_type_display_value as downstream_prot_type_id,
          e.upstream_sideslope,
          e.downstream_sideslope,
          l1.unit_system,
          case when l1.unit_system = 'SI' then 'm' else 'ft' end as unit_id,
          case
             when l1.unit_system = 'SI' then to_number(cwms_rounding.round_dt_f(e.structure_length, '7777777777'))
             else to_number(cwms_rounding.round_dt_f(cwms_util.convert_units(e.structure_length, 'm', 'ft'), '7777777777'))
          end
             as structure_length,
          case
             when l1.unit_system = 'SI' then to_number(cwms_rounding.round_dt_f(e.height_max, '7777777777'))
             else to_number(cwms_rounding.round_dt_f(cwms_util.convert_units(e.height_max, 'm', 'ft'), '7777777777'))
          end
             as height_max,
          case
             when l1.unit_system = 'SI' then to_number(cwms_rounding.round_dt_f(e.top_width, '7777777777'))
             else to_number(cwms_rounding.round_dt_f(cwms_util.convert_units(e.top_width, 'm', 'ft'), '7777777777'))
          end
             as top_width,
          e.embankment_project_loc_code,
          l1.location_code as embankment_location_code,
          e.structure_type_code,
          e.upstream_prot_type_code,
          e.downstream_prot_type_code
     from at_embankment e,
          cwms_v_loc l1,
          cwms_v_loc l2,
          at_embank_protection_type ept1,
          at_embank_protection_type ept2,
          at_embank_structure_type est
    where e.embankment_location_code = l1.location_code
      and e.embankment_project_loc_code = l2.location_code
      and l1.unit_system = l2.unit_system
      and e.upstream_prot_type_code = ept1.protection_type_code(+)
      and e.downstream_prot_type_code = ept2.protection_type_code(+)
      and e.structure_type_code = est.structure_type_code;

create or replace public synonym cwms_v_embankment for av_embankment;
