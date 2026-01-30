delete from at_clob where id = '/VIEWDOCS/AV_LOCATION_LEVEL_REF';
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_LOCATION_LEVEL_REF', null,
                            '
                            /**
                             * Displays information about concrete location levels
                             *
                             * @since CWMS 2.1 (extended in 3.0)
                             *
                             * @field office_id           Office that owns the location level
                             * @field attribute_id        The attribute identifier, if any, for the location level
                             * @field location_level_date          The effective data for the location level
                             * @field base_location_id    The base location portion of the location level
                             * @field sub_location_id     The sub-location portion of the location level
                             * @field location_id         The full location portion of the location level
                             * @field base_parameter_id   The base parameter portion of the location level
                             * @field sub_parameter_id    The sub-parameter portion of the location level
                             * @field parameter_id        The full parameter portion of the location level
                             * @field duration_id         The duration portion of the location level
                             * @field specified_level_id  The specified level portion of the location level
                             * @field location_code       The unique numeric code that identifies the location in the database
                             * @field location_level_code The unique numeric code that identifies the location level in the database
                             * @field expiration_date             The date/time at which the level expires
                             * @field parameter_type_id           The parameter type of the location level
                             * @field attribute_parameter_id      The attribute of the parameter, if any
                             * @field attribute_base_parameter_id The base parameter of the attribute, if any
                             * @field attribute_sub_parameter_id  The sub-parameter of the attribute, if any
                             * @field attribute_parameter_type_id The parameter type of the attribute, if any
                             * @field attribute_duration_id       The duration of the attribute, if any
                             * @field default_label               The label assoicated with the location level and the ''GENERAL/OTHER'' configuration, if any
                             * @field source                      The source entity for the location level values
                             */
                            ');

-- office_id
--
-- location_level_code
-- location_level_date
-- expiration_date
--
-- base_location_id
-- sub_location_id
-- location_id
-- location_code
--
-- base_parameter_id
-- sub_parameter_id
-- parameter_id
-- parameter_type_id
-- duration_id
-- specified_level_id
--
-- attribute_parameter_id
-- attribute_base_parameter_id
-- attribute_sub_parameter_id
-- attribute_parameter_type_id
-- attribute_duration_id

create or replace force view av_location_level_ref
      (
       office_id,
       location_level_id,
       attribute_id,
       location_level_code,
       location_level_date,
       expiration_date,

       base_location_id,
       sub_location_id,
       location_id,
       location_code,

       base_parameter_id,
       sub_parameter_id,
       parameter_id,
       parameter_type_id,
       duration_id,
       specified_level_id,

       attribute_parameter_id,
       attribute_base_parameter_id,
       attribute_sub_parameter_id,
       attribute_parameter_type_id,
       attribute_duration_id
         )
as

/* ===========================
 * PHYSICAL LOCATION LEVELS
 * =========================== */
select
   c_o.office_id,

   (dash(a_bl.base_location_id, a_pl.sub_location_id) || '.' || dash(c_bp1.base_parameter_id, a_p1.sub_parameter_id) || '.' || c_pt1.parameter_type_id || '.' || c_d1.duration_id || '.' || a_sl.specified_level_id) as location_level_id,
   (dash(c_bp2.base_parameter_id, a_p2.sub_parameter_id) || substr ('.', 1, length (c_pt2.parameter_type_id)) || c_pt2.parameter_type_id || substr ('.', 1, length (c_d2.duration_id)) || c_d2.duration_id) as attribute_id,
   a_ll.location_level_code,
   a_ll.location_level_date,
   a_ll.expiration_date,

   a_bl.base_location_id,
   a_pl.sub_location_id,
   dash(a_bl.base_location_id, a_pl.sub_location_id)      as location_id,
   a_ll.location_code,

   c_bp1.base_parameter_id,
   a_p1.sub_parameter_id,
   dash(c_bp1.base_parameter_id, a_p1.sub_parameter_id)   as parameter_id,
   c_pt1.parameter_type_id,
   c_d1.duration_id,
   a_sl.specified_level_id,

   dash(c_bp2.base_parameter_id, a_p2.sub_parameter_id)   as parameter_id,
   c_bp2.base_parameter_id as attribute_base_parameter_id,
   a_p2.sub_parameter_id as attribute_sub_parameter_id,
   c_pt2.parameter_type_id as attribute_parameter_type_id,
   c_d2.duration_id as attribute_duration_id
from
   at_location_level a_ll
      join at_physical_location a_pl
           on a_pl.location_code = a_ll.location_code
      join at_base_location a_bl
           on a_bl.base_location_code = a_pl.base_location_code
      join cwms_office c_o
           on c_o.office_code = a_bl.db_office_code
      join at_specified_level a_sl
           on a_sl.specified_level_code = a_ll.specified_level_code
      join cwms_duration c_d1
           on c_d1.duration_code = a_ll.duration_code
      join cwms_parameter_type c_pt1
           on c_pt1.parameter_type_code = a_ll.parameter_type_code
      join at_parameter a_p1
           on a_p1.parameter_code = a_ll.parameter_code
      join cwms_base_parameter c_bp1
           on c_bp1.base_parameter_code = a_p1.base_parameter_code
      left join at_parameter a_p2
                on a_p2.parameter_code = a_ll.attribute_parameter_code
      left join cwms_base_parameter c_bp2
                on c_bp2.base_parameter_code = a_p2.base_parameter_code
      left join cwms_parameter_type c_pt2
                on c_pt2.parameter_type_code = a_ll.attribute_parameter_type_code
      left join cwms_duration c_d2
                on c_d2.duration_code = a_ll.attribute_duration_code

union all

/* ===========================
 * VIRTUAL LOCATION LEVELS
 * =========================== */
select
   c_o.office_id,

   (dash(a_bl.base_location_id, a_pl.sub_location_id) || '.' || dash(c_bp1.base_parameter_id, a_p1.sub_parameter_id) || '.' || c_pt1.parameter_type_id || '.' || c_d1.duration_id || '.' || a_sl.specified_level_id) as location_level_id,
   (dash(c_bp2.base_parameter_id, a_p2.sub_parameter_id) || substr ('.', 1, length (c_pt2.parameter_type_id)) || c_pt2.parameter_type_id || substr ('.', 1, length (c_d2.duration_id)) || c_d2.duration_id) as attribute_id,
   v_ll.location_level_code,
   v_ll.effective_date          as location_level_date,
   v_ll.expiration_date,

   a_bl.base_location_id,
   a_pl.sub_location_id,
   dash(a_bl.base_location_id, a_pl.sub_location_id)      as location_id,
   v_ll.location_code,

   c_bp1.base_parameter_id,
   a_p1.sub_parameter_id,
   dash(c_bp1.base_parameter_id, a_p1.sub_parameter_id)   as parameter_id,
   c_pt1.parameter_type_id,
   c_d1.duration_id,
   a_sl.specified_level_id,

   dash(c_bp2.base_parameter_id, a_p2.sub_parameter_id)   as parameter_id,
   c_bp2.base_parameter_id as attribute_base_parameter_id,
   a_p2.sub_parameter_id as attribute_sub_parameter_id,
   c_pt2.parameter_type_id as attribute_parameter_type_id,
   c_d2.duration_id as attribute_duration_id
from
   at_virtual_location_level v_ll
      join at_physical_location a_pl
           on a_pl.location_code = v_ll.location_code
      join at_base_location a_bl
           on a_bl.base_location_code = a_pl.base_location_code
      join cwms_office c_o
           on c_o.office_code = a_bl.db_office_code
      join at_specified_level a_sl
           on a_sl.specified_level_code = v_ll.specified_level_code
      join cwms_duration c_d1
           on c_d1.duration_code = v_ll.duration_code
      join cwms_parameter_type c_pt1
           on c_pt1.parameter_type_code = v_ll.parameter_type_code
      join at_parameter a_p1
           on a_p1.parameter_code = v_ll.parameter_code
      join cwms_base_parameter c_bp1
           on c_bp1.base_parameter_code = a_p1.base_parameter_code
      left join at_parameter a_p2
                on a_p2.parameter_code = v_ll.attribute_parameter_code
      left join cwms_base_parameter c_bp2
                on c_bp2.base_parameter_code = a_p2.base_parameter_code
      left join cwms_parameter_type c_pt2
                on c_pt2.parameter_type_code = v_ll.attribute_parameter_type_code
      left join cwms_duration c_d2
                on c_d2.duration_code = v_ll.attribute_duration_code;


/


begin
   execute immediate 'grant select on av_location_level_ref to cwms_user';
exception
   when others then null;
end;
/


create or replace public synonym cwms_v_location_level_ref for av_location_level_ref;
