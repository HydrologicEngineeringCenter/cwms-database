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
   top_level)
as 
select office_id,
       office_code,
       project_id,
       project_location_code,
       pool_name,
       pool_name_code,
       definition_type,
       bottom_level,
       top_level 
  from (--------------------
        -- explicit pools --
        --------------------
         select 'EXPLICIT' as definition_type,
                o.office_id,
                o.office_code,
                bl.base_location_id
                ||substr('.', 1, length(pl.sub_location_id))
                ||pl.sub_location_id as project_id,
                pl.location_code as project_location_code,
                pn.pool_name,
                pn.pool_name_code,
                bl.base_location_id
                ||substr('.', 1, length(pl.sub_location_id))
                ||pl.sub_location_id
                ||'.'
                ||po.bottom_level as bottom_level,
                bl.base_location_id
                ||substr('.', 1, length(pl.sub_location_id))
                ||pl.sub_location_id
                ||'.'
                ||po.top_level as top_level
           from at_pool po,
                at_pool_name pn,
                at_physical_location pl,
                at_base_location bl,
                cwms_office o
          where pn.pool_name_code = po.pool_name_code
            and pl.location_code = po.project_code
            and bl.base_location_code = pl.base_location_code
            and o.office_code = bl.db_office_code
        union all
        --------------------
        -- implicit pools --
        --------------------
        select 'IMPLICIT' as definition_type,
               office_id,
               office_code,
               project_id,
               project_location_code,
               pool_name,
               pool_name_code,
               replace(top_level, 'Top of ', 'Bottom of ') as bottom_level,
               top_level
          from (select o.office_id,
                       o.office_code,
                       bl.base_location_id
                       ||substr('.', 1, length(pl.sub_location_id))
                       ||pl.sub_location_id as project_id,
                       pl.location_code as project_location_code,
                       trim(substr(sp.specified_level_id, 8)) as pool_name,
                       pn.pool_name_code,
                       bl.base_location_id
                       ||substr('.', 1, length(pl.sub_location_id))
                       ||pl.sub_location_id
                       ||'.'||bp.base_parameter_id
                       ||'.'||pt.parameter_type_id
                       ||'.'||d.duration_id
                       ||'.'||sp.specified_level_id as top_level,
                       max(ll.location_level_date) -- instead of select distinct
                  from at_location_level ll,
                       at_project pr,
                       at_physical_location pl,
                       at_base_location bl,
                       cwms_office o,
                       at_parameter p,
                       cwms_base_parameter bp,
                       cwms_parameter_type pt,
                       cwms_duration d,
                       at_specified_level sp,
                       at_pool_name pn
                 where pr.project_location_code = ll.location_code
                   and pl.location_code = pr.project_location_code
                   and bl.base_location_code = pl.base_location_code
                   and o.office_code = bl.db_office_code
                   and p.parameter_code = ll.parameter_code
                   and p.sub_parameter_id is null
                   and bp.base_parameter_code = p.base_parameter_code
                   and bp.base_parameter_id = 'Elev'
                   and pt.parameter_type_code = ll.parameter_type_code
                   and pt.parameter_type_id = 'Inst'
                   and d.duration_code = ll.duration_code
                   and d.duration_id = '0'
                   and sp.specified_level_code = ll.specified_level_code
                   and instr(sp.specified_level_id, 'Top of ') = 1
                   and attribute_value is null
                   and upper(pn.pool_name) = upper(trim(substr(sp.specified_level_id, 8)))
                   and pn.office_code in (o.office_code, 53)
                   and exists (select ll2.location_code,
                                      ll2.parameter_code,
                                      ll2.parameter_type_code,
                                      ll2.duration_code,
                                      sp2.specified_level_code
                                 from at_location_level ll2,
                                      at_specified_level sp2
                                where ll2.location_code = ll.location_code
                                  and ll2.parameter_code = ll.parameter_code
                                  and ll2.parameter_type_code = ll.parameter_type_code
                                  and ll2.duration_code = ll.duration_code
                                  and ll2.attribute_value is null
                                  and sp2.specified_level_code = ll2.specified_level_code
                                  and sp2.specified_level_id = replace(sp.specified_level_id, 'Top of ', 'Bottom of ')
                              )
                 group by o.office_id,
                       o.office_code, 
                       bl.base_location_id||substr('.', 1, length(pl.sub_location_id))||pl.sub_location_id,
                       pl.location_code,
                       trim(substr(specified_level_id, 8)),
                       pn.pool_name_code,
                       bl.base_location_id||substr('.', 1, length(pl.sub_location_id))||pl.sub_location_id||'.'||bp.base_parameter_id||'.'||pt.parameter_type_id||'.'||d.duration_id||'.'||sp.specified_level_id                     
               )
       );
  
create or replace public synonym cwms_v_pool for av_pool;  
