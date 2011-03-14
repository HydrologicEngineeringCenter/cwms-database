set serveroutput on;
declare
  
  l_lookup_category varchar2(40);
  -- the lookups have a prefix on the column name.
  l_lookup_prefix varchar2(40);
  -- defaults to the connected user's office if null
  l_db_office_id varchar2(40);

  l_lookup_tab_in  lookup_type_tab_t;
  l_lookup_tab_out lookup_type_tab_t;
  
  l_query_string varchar2(4000);
  l_cnt number;

begin
  l_lookup_category := 'at_embank_structure_type';
  l_lookup_prefix := 'structure_type';
  l_db_office_id    := 'SWT';
  l_lookup_tab_in := lookup_type_tab_t();

  l_lookup_tab_in.extend();
  l_lookup_tab_in(1) := lookup_type_obj_t(
    l_db_office_id,
    'st1',
    'st1 desc',
    'T'    
  );
  -- cwms_cat.set_lookup_table(l_lookup_tab_in,l_lookup_category,l_lookup_prefix);
  
  merge into at_embank_structure_type st
    using (select cwms_util.get_office_code(cwms_util.check_input_f(ltab.office_id)) office_code, 
                cwms_util.check_input_f(ltab.display_value) display_value, 
                cwms_util.check_input_f(ltab.tooltip) tooltip, 
                cwms_util.check_input_f(ltab.active) active 
            from table (cast (l_lookup_tab_in as lookup_type_tab_t)) ltab
    ) mtab
    on (  st.db_office_code = mtab.office_code 
          AND upper(st.structure_type_display_value) = upper(mtab.display_value)
    )  
    WHEN MATCHED THEN
        update set 
          st.structure_type_tooltip = mtab.tooltip,
          st.structure_type_active = mtab.active
    WHEN NOT MATCHED THEN 
        insert 
        ( st.structure_type_code,
          st.db_office_code,
          st.structure_type_display_value,
          st.structure_type_tooltip,
          st.structure_type_active 
        )
        VALUES (
          cwms_seq.nextval,
          mtab.office_code,
          mtab.display_value,
          mtab.tooltip,
          mtab.active
        );
  
  
  
  
  l_lookup_tab_out := lookup_type_tab_t();
  cwms_cat.get_lookup_table(l_lookup_tab_out,l_lookup_category,l_lookup_prefix,l_db_office_id);
  
  dbms_output.put_line('retrieved '|| l_lookup_tab_out.count || ' records.');
  
--  SELECT CAST (MULTISET
--    (SELECT l_db_office_id,
--      structure_type_display_value,
--      structure_type_tooltip,
--      structure_type_active
--    FROM at_embank_structure_type
--    WHERE db_office_code = cwms_util.get_office_code(l_db_office_id)
--    ) AS lookup_type_tab_t)
--  INTO l_lookup_type_tab
--  FROM dual;

--    office_id     VARCHAR2 (16),      -- the office id for this lookup type
--    display_value VARCHAR2(25 byte),  --The value to display for this lookup record
--    tooltip       VARCHAR2(255 byte), --The tooltip or meaning of this lookup record
--    active        varchar2(1 byte)    --Whether this lookup record entry is currently active

--l_query_string := 'SELECT CAST (MULTISET (SELECT "'||l_db_office_id||'",
--      '|| l_lookup_prefix || 'type_display_value,
--      '|| l_lookup_prefix || 'type_tooltip,
--      '|| l_lookup_prefix || 'type_active 
--    FROM '||l_lookup_category||'
--    WHERE db_office_code = cwms_util.get_office_code("'||l_db_office_id||'")
--    ) AS lookup_type_tab_t) FROM dual';
--dbms_output.put_line('query: '|| l_query_string);
  
--  execute immediate 'SELECT CAST (MULTISET (SELECT :bv1 office_id,
--      '|| l_lookup_prefix || 'type_display_value display_value,
--      '|| l_lookup_prefix || 'type_tooltip tooltip,
--      '|| l_lookup_prefix || 'type_active active
--    FROM '||l_lookup_category||'
--    WHERE db_office_code = cwms_util.get_office_code(:bv2)
--    ) AS lookup_type_tab_t) FROM dual'
--  into l_lookup_type_tab
--  using l_db_office_id, l_db_office_id;

--  execute immediate 'SELECT count(*) 
--    FROM '||l_lookup_category
--  into l_cnt;

end;


