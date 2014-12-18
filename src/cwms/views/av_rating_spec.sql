--------------------
-- AV_RATING_SPEC --
--------------------
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_RATING_SPEC', null,
'
/**
 * Displays information on ratings specifications
 *
 * @since CWMS 2.1
 *
 * @see CWMS_ROUNDING
 *
 * @field office_id             The office owning the rating spec
 * @field rating_id             The rating spec identifier
 * @field location_id           The location for the rating spec - may be an actual location or a location alias
 * @field template_id           The rating template identifier for this rating spec
 * @field source_agency         The agency that supplies ratings for this rating spec
 * @field version               The version identifier for this rating spec
 * @field active_flag           Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code>) specifying whether this rating spec is active
 * @field auto_update_flag      Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code>) specifying whether new ratings under this spec automatically be loaded
 * @field auto_activate_flag    Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code>) specifying whether newly loaded ratings under this spec should automatically be activated
 * @field auto_migrate_ext_flag Flag (<code><big>''T''</big></code> or <code><big>''F''</big></code>) specifying whether newly loaded ratings under this spec should automatically inherit rating extenions from a previous rating
 * @field date_methods,         Specifies behavior rating methods will use when rating values with times before the earliest effective date, between first and last effective dates, and after last effective date
 * @field ind_rounding_specs    Specifies USGS-style rounding specification(s) for displaying independent parameter(s)
 * @field dep_rounding_spec     Specifies USGS-style rounding specification for displaying dependent parameter
 * @field description           The description for this rating specification
 * @field aliased_item          Null if the location_id is not an alias, ''LOCATION'' if the entire location_id is aliased, or ''BASE LOCATION'' if only the base_location_id is alaised.  
 * @field loc_alias_category    The location category that owns the location group to which the alias for the location_id or base_location_id belongs. Null if location_id is not an alias.  
 * @field loc_alias_group       The location group to which the alias for the location_id or base_location_id belongs. Null if location_id is not an alias.              
 * @field rating_spec_code      The unique numeric code that identifies the rating specification in the database
 * @field template_code         The unique numeric code that identifies the specification''s template in the database              
 */
');

create or replace force view av_rating_spec
(
   office_id,
   rating_id,
   location_id,
   template_id,
   version,
   source_agency,
   active_flag,
   auto_update_flag,
   auto_activate_flag,
   auto_migrate_ext_flag,
   date_methods,
   ind_rounding_specs,
   dep_rounding_spec,
   description,
   aliased_item,
   loc_alias_category,
   loc_alias_group,
   rating_spec_code,
   template_code
)
as
select distinct
       office_id,
       rating_id,
       location_id,
       template_id,
       version,
       cwms_util.split_text(source_agency, 1) as source_agency,
       active_flag,
       auto_update_flag,
       auto_activate_flag,
       auto_migrate_ext_flag,
       date_methods,
       ind_rounding_specs,
       dep_rounding_spec,
       description,
       aliased_item,
       loc_alias_category,
       loc_alias_group,
       a.rating_spec_code,
       a.template_code
  from (select rs.rating_spec_code, 
               rs.template_code, 
               v.db_office_id as office_id,
               v.location_id 
               || '.' 
               || rt.parameters_id 
               || '.' 
               || rt.version 
               || '.' 
               || rs.version as rating_id,
               v.location_id,
               rt.parameters_id 
               || '.' 
               || rt.version as template_id,
               rs.version,
               replace(lg.loc_group_id, 'Default', '') as source_agency,
               rs.active_flag, 
               rs.auto_update_flag,
               rs.auto_activate_flag, 
               rs.auto_migrate_ext_flag,
               rm2.rating_method_id 
               || ',' 
               || rm1.rating_method_id 
               || ',' 
               || rm3.rating_method_id as date_methods,
               rs.dep_rounding_spec, 
               rs.description,
               v.aliased_item,
               v.loc_alias_category,
               v.loc_alias_group
          from at_rating_spec rs,
               at_rating_template rt,
               av_loc2 v,
               at_loc_group lg,
               cwms_rating_method rm1,
               cwms_rating_method rm2,
               cwms_rating_method rm3
         where rt.template_code = rs.template_code
           and v.location_code = rs.location_code
           and lg.loc_group_code = nvl(rs.source_agency_code, 0)
           and rm1.rating_method_code = rs.in_range_rating_method
           and rm2.rating_method_code = rs.out_range_low_rating_method
           and rm3.rating_method_code = rs.out_range_high_rating_method
       ) a
      join
      (select p1.rating_spec_code,
              p1.rounding_spec
              || substr('/', 1, length(p2.rounding_spec)) 
              || p2.rounding_spec 
              || substr('/', 1, length(p3.rounding_spec)) 
              || p3.rounding_spec 
              || substr('/', 1, length(p4.rounding_spec)) 
              || p4.rounding_spec 
              || substr('/', 1, length(p5.rounding_spec)) 
              || p5.rounding_spec as ind_rounding_specs
        from (select rating_spec_code, 
                     rounding_spec
                from at_rating_ind_rounding
               where parameter_position = 1
             ) p1
             left outer join 
            (select rating_spec_code,
                    rounding_spec
               from at_rating_ind_rounding
              where parameter_position = 2
            ) p2 on p2.rating_spec_code = p1.rating_spec_code
            left outer join 
            (select rating_spec_code,
                    rounding_spec
               from at_rating_ind_rounding
              where parameter_position = 3
            ) p3 on p3.rating_spec_code = p1.rating_spec_code
            left outer join 
            (select rating_spec_code,
                    rounding_spec
               from at_rating_ind_rounding
              where parameter_position = 4
            ) p4 on p4.rating_spec_code = p1.rating_spec_code
            left outer join 
            (select rating_spec_code,
                    rounding_spec
               from at_rating_ind_rounding
              where parameter_position = 5
            ) p5 on p5.rating_spec_code = p1.rating_spec_code
       ) b on b.rating_spec_code = a.rating_spec_code;
/
