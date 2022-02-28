/**
 * Displays information on water entities
 *
 * @since CWMS 3.0
 *
 * @field location_office_id   The office that owns the location in the database
 * @field base_location_id     The base location
 * @field sub_location_id      The sub-location, if any
 * @field location_id          The location identifier
 * @field entity_office_id     The office that owns the entity in the database
 * @field entity_id            The text identifier of the entity
 * @field parent_entity_id     The text identifier of the parent entity, if any
 * @field entity_category_id   The category of the entity
 * @field entity_name          The entity name
 * @field aliased_item         Null if the location_id is not an alias, ''LOCATION'' if the entire location_id is aliased, or ''BASE LOCATION'' if only the base_location_id is alaised.
 * @field loc_alias_category   The location category that owns the location group to which the alias for the location_id or base_location_id belongs. Null if location_id is not an alias.
 * @field loc_alias_group      The location group to which the alias for the location_id or base_location_id belongs. Null if location_id is not an alias.
 * @field location_office_code The numeric code that identifies the location office in the database
 * @field base_location_code   The numeric code that identifies the base location in the database
 * @field location_code        The numeric code that identifies the location in the database
 * @field entity_office_code   The numeric code that identifies the entity office in the database
 * @field entity_code          The numeric code that idenifies the entity in the database
 * @field parent_entity_code   The numeric code that identifies the parent entity in the database
 */
create or replace force view av_entity_location (
   location_office_id,
   base_location_id,
   sub_location_id,
   location_id,
   entity_office_id,
   entity_id,
   parent_entity_id,
   entity_category_id,
   entity_name,
   aliased_item,
   loc_alias_category,
   loc_alias_group,
   location_office_code,
   base_location_code,
   location_code,
   entity_office_code,
   entity_code,
   parent_entity_code)
as
select q1.office_id as location_office_id,
       q1.base_location_id,
       q1.sub_location_id,
       q1.location_id,
       q2.office_id as entity_office_id,
       q2.entity_id,
       q2.parent_entity_id,
       q2.category_id as entity_category_id,
       q2.entity_name,
       q1.aliased_item,
       q1.loc_alias_category,
       q1.loc_alias_group,
       q1.office_code as location_office_code,
       q1.base_location_code,
       q1.location_code,
       q2.office_code as entity_office_code,
       q2.entity_code,
       q2.parent_code as parent_entity_code
  from (select o.office_id,
               bl.base_location_id,
               pl.sub_location_id,
               bl.base_location_id
               ||substr('-', 1, length(pl.sub_location_id))
               ||pl.sub_location_id as location_id,
               null as aliased_item,
               null as loc_alias_category,
               null as loc_alias_group,
               bl.db_office_code as office_code,
               bl.base_location_code,
               pl.location_code
          from at_physical_location pl,
               at_base_location bl,
               cwms_office o
         where bl.base_location_code = pl.base_location_code
           and o.office_code = bl.db_office_code
        union all
        select o.office_id,
               lga.loc_alias_id as base_location_id,
               null as sub_location_id,
               lga.loc_alias_id as location_id,
               'LOCATION' as aliased_item,
               lc.loc_category_id as loc_alias_category,
               lg.loc_group_id as loc_alias_group,
               bl.db_office_code as office_code,
               bl.base_location_code,
               pl.location_code
          from at_physical_location pl,
               at_base_location bl,
               at_loc_category lc,
               at_loc_group lg,
               at_loc_group_assignment lga,
               cwms_office o
         where lga.loc_alias_id is not null
           and lga.location_code = pl.location_code
           and lg.loc_group_code = lga.loc_group_code
           and lc.loc_category_code = lg.loc_category_code
           and bl.base_location_code = pl.base_location_code
           and o.office_code = bl.db_office_code
        union all
        select o.office_id,
               lga.loc_alias_id as base_location_id,
               pl.sub_location_id,
               lga.loc_alias_id
               ||'-'
               ||pl.sub_location_id as location_id,
               'BASE LOCATION' as aliased_item,
               lc.loc_category_id as loc_alias_category,
               lg.loc_group_id as loc_alias_group,
               bl.db_office_code as office_code,
               bl.base_location_code,
               pl.location_code
          from at_physical_location pl,
               at_base_location bl,
               at_loc_category lc,
               at_loc_group lg,
               at_loc_group_assignment lga,
               cwms_office o
         where lga.loc_alias_id is not null
           and lga.location_code = bl.base_location_code
           and lg.loc_group_code = lga.loc_group_code
           and lc.loc_category_code = lg.loc_category_code
           and bl.base_location_code = pl.base_location_code
           and pl.location_code != pl.base_location_code
           and o.office_code = bl.db_office_code
       ) q1,
       (select q2_1.office_id,
               q2_1.office_code,
               q2_1.entity_id,
               q2_2.entity_id as parent_entity_id,
               q2_1.category_id,
               q2_1.entity_name,
               q2_1.entity_code,
               q2_1.parent_code
        from (select o.office_id,
                     o.office_code,
                     e.entity_id,
                     e.entity_code,
                     e.parent_code,
                     e.category_id,
                     e.entity_name
                from at_entity e,
                     cwms_office o
               where o.office_code = e.office_code
             ) q2_1
             left outer join
             (select entity_code,
                     entity_id
                from at_entity
             ) q2_2 on q2_2.entity_code = q2_1.parent_code
       ) q2,
       at_entity_location e
 where q1.location_code = e.location_code
   and q2.entity_code = e.entity_code;

create or replace public synonym cwms_v_entity_location for av_entity_location;
