insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_STORE_RULE_UI', null,
'
/**
 * Displays information about store rule order and defaults for UI components.
 *
 * @field office_id          The office for which the store information applies
 * @field store_rule_id      The store rule
 * @field sort_order         An integer that specifies the order of this store rule in relationship with others 
 * @field default_store_rule A flag (T/F) specifying whether the store rule is the default choice for the office
 *
 * @see view av_store_rule
 * @see cwms_display.set_store_rule_ui_info
 */
');
create or replace force view av_store_rule_ui(
   office_id,
   store_rule_id,
   sort_order,
   default_store_rule)
as
   select a.office_id,
          a.store_rule_id,
          nvl(b.sort_order, a.sort_order) as sort_order,
          nvl(c.default_store_rule, a.default_store_rule) as default_store_rule
     from (select co.office_id,
                  sr.store_rule_id,
                  sr.sort_order,
                  case 
                     when sr.store_rule_id = 'REPLACE WITH NON MISSING' then 'T' 
                     else 'F' 
                  end as default_store_rule
             from cwms_office co,
                  (  select store_rule_id, rownum + 100 as sort_order
                       from cwms_store_rule
                   order by store_rule_code
                  ) sr
          ) a
          left outer join (select co.office_id, sro.store_rule_id, sro.sort_order
                             from cwms_office co, at_store_rule_order sro
                            where sro.office_code = co.office_code
          ) b on b.office_id = a.office_id 
             and b.store_rule_id = a.store_rule_id
          left outer join
          (select co.office_id,
                  csr.store_rule_id,
                  case 
                     when srd.default_store_rule = csr.store_rule_id then 'T' 
                     else 'F'
                  end as default_store_rule
             from cwms_office co, at_store_rule_default srd, cwms_store_rule csr
            where srd.office_code = co.office_code
          ) c on c.office_id = a.office_id 
             and c.store_rule_id = a.store_rule_id
    order by 1, 3;             
                                                                                          
