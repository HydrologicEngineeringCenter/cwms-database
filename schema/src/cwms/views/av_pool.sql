whenever sqlerror continue
delete from at_clob where id = '/VIEWDOCS/AV_POOL';
whenever sqlerror exit sqlcode
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_POOL', null,
'
/**
 * Displays reservoir pool definitions in the database
 *
 * @since CWMS 3.1
 *
 * @field office_id             The office that owns the pool in the database
 * @field office_code           The numeric code of the office that owns the pool in the database
 * @field project_id            The location ID of the project that has the pool definition
 * @field project_location_code The numeric code of the location of the project that has the pool definition
 * @field pool_name             The name of the pool at the project
 * @field pool_name_code        The numeric code of the pool name in the database
 * @field definition_type       Specifies whether the pool is implicitly or explicitly defined
 * @field bottom_level          The location level ID that defines the bottom of the pool
 * @field top_level             The location_level ID that defines the top of the pool
 * @field attribute             The numeric attribute associated with the pool, normally used for sorting within a project
 * @field description           The text description of the pool
 * @field clob_code             The numeric code of the CLOB associated with the pool
 * @field clob_text             The text of the CLOB associated with the pool, normally structured as XML or JSON
 */
');
create or replace force view av_pool(
   office_id,
   office_code,
   project_id,
   project_location_code,
   pool_name,
   pool_name_code,
   definition_type,
   bottom_level,
   top_level,
   attribute,
   description,
   clob_code,
   clob_text)
as
select office_id,
       office_code,
       project_id,
       project_location_code,
       pool_name,
       pool_name_code,
       'EXPLICIT' as definition_type,
       bottom_level_id,
       top_level_id,
       attribute,
       description,
       q1.clob_code,
       q2.clob_text
  from (select o.office_id,
               o.office_code,
               bl.base_location_id||substr('.', 1, length(pl.sub_location_id))||pl.sub_location_id as project_id,
               pr.project_location_code,
               pn.pool_name,
               pn.pool_name_code,
               po.bottom_level as bottom_level_id,
               po.top_level as top_level_id,
               po.attribute,
               po.description,
               po.clob_code
          from at_pool po,
               at_pool_name pn,
               cwms_office o,
               at_project pr,
               at_physical_location pl,
               at_base_location bl
         where pr.project_location_code = po.project_code
           and pl.location_code = pr.project_location_code
           and bl.base_location_code = pl.base_location_code
           and o.office_code = bl.db_office_code
           and pn.pool_name_code = po.pool_name_code
       ) q1
       left outer join
       (select clob_code,
               value as clob_text
          from at_clob
       ) q2 on q2.clob_code = q1.clob_code
union all
select office_id,
       office_code,
       project_id,
       project_location_code,
       pool_name,
       null as pool_name_code,
       'IMPLICIT' as definition_type,
       'Elev.Inst.0.'||bottom_level_id as bottom_level_id,
       'Elev.Inst.0.'||top_level_id as top_level_id,
       null as attribute,
       null as description,
       null as clob_clode,
       null as clob_text
  from (select distinct
               o.office_id,
               o.office_code,
               bl.base_location_id||substr('.', 1, length(pl.sub_location_id))||pl.sub_location_id as project_id,
               pr.project_location_code,
               trim(replace(specified_level_id, 'Bottom of ', null)) as pool_name,
               specified_level_id as bottom_level_id,
               replace(specified_level_id, 'Bottom of ', 'Top of ') as top_level_id
          from at_specified_level sl,
               at_location_level ll,
               at_project pr,
               at_physical_location pl,
               at_base_location bl,
               cwms_office o
         where pr.project_location_code = ll.location_code
           and pl.location_code = pr.project_location_code
           and bl.base_location_code = pl.base_location_code
           and o.office_code = bl.db_office_code
           and ll.parameter_code = (select base_parameter_code from cwms_base_parameter where base_parameter_id = 'Elev')
           and ll.parameter_type_code = (select parameter_type_code from cwms_parameter_type where parameter_type_id = 'Inst')
           and ll.duration_code = (select duration_code from cwms_duration where duration_id = '0')
           and sl.specified_level_code = ll.specified_level_code
           and sl.specified_level_id like 'Bottom of %'
           and exists (select specified_level_id
                         from at_specified_level
                        where office_code = sl.office_code
                          and specified_level_id = replace(sl.specified_level_id, 'Bottom of', 'Top of')
                      )
           and not exists (select project_code,
                                  bottom_level,
                                  top_level
                             from at_pool
                            where project_code = pr.project_location_code
                              and upper(bottom_level) = upper('Elev.Inst.0.'||sl.specified_level_id)
                              and upper(top_level)    = upper('Elev.Inst.0.'||replace(sl.specified_level_id, 'Bottom of ', 'Top of '))
                          )
       );

begin
	execute immediate 'grant select on av_pool to cwms_user';
exception
	when others then null;
end;
/


create or replace public synonym cwms_v_pool for av_pool;
