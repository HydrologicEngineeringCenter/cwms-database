insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_SPECIFIED_LEVEL_UI', null,
'
/**
 * Displays specified level sort order for UI components.
 *
 * @field office_id           The office for which the sort order information applies
 * @field specified_level_id  The specified_level
 * @field sort_order          An integer that specifies the order of this specified level in relationship with others 
 *
 * @see view av_specified_level
 * @see cwms_display.set_specified_level_ui_info
 */
');
create or replace force view av_specified_level_ui(
   office_id,
   specified_level_id,
   sort_order)
as
     select co.office_id, 
            q2.specified_level_id, 
            q2.sort_order
       from cwms_office co,
            (select a.office_code, 
                    a.specified_level_id, 
                    nvl(b.sort_order, a.sort_order) as sort_order
               from (select co.office_code,
                            q1.specified_level_code,
                            q1.specified_level_id,
                            sort_order
                       from cwms_office co,
                            (select specified_level_code,
                                    owning_office_code,
                                    specified_level_id,
                                    rownum + 10000 as sort_order
                               from (select specified_level_code, 
                                            office_code as owning_office_code, 
                                            specified_level_id
                                       from at_specified_level
                                      order by upper(specified_level_id)
                                    )
                            ) q1
                      where q1.owning_office_code in (co.office_code, 53)
                    ) a
                    left outer join 
                    (select office_code, 
                            specified_level_code, 
                            sort_order 
                       from at_specified_level_order
                    ) b on b.office_code = a.office_code 
                       and b.specified_level_code = a.specified_level_code
            ) q2
      where co.office_code = q2.office_code
   order by co.office_id, q2.sort_order;

