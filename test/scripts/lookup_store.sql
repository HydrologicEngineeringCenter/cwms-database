set serveroutput on
DECLARE
l_lookups lookup_type_tab_t;
l_db_office_id VARCHAR2(16);
l_lookup_category VARCHAR2(30);
l_lookup_prefix VARCHAR2(30);
l_cnt number;
BEGIN

l_lookups := lookup_type_tab_t();
l_db_office_id := 'SWT';
l_lookup_category := 'at_physical_transfer_type';
l_lookup_prefix := 'phys_trans';

l_lookups.EXTEND; l_lookups(1) := lookup_type_obj_t(l_db_office_id,'xfer type aa1','xfer type aa1 desc','T');
l_lookups.EXTEND; l_lookups(2) := lookup_type_obj_t(l_db_office_id,'xfer type bb1','xfer type bb1 desc','T');
l_lookups.EXTEND; l_lookups(3) := lookup_type_obj_t(l_db_office_id,'xfer type cc1','xfer type cc1 desc','T');

--SELECT *
--cwms_util.check_input(ltab.office_id),
--  cwms_util.check_input(ltab.display_value),
--  cwms_util.check_input(ltab.tooltip),
--  cwms_util.check_input(ltab.active) 
--from table (cast (l_lookups as lookup_type_tab_t)) ltab;

EXECUTE IMMEDIATE 'delete from '||l_lookup_category||' where db_office_code in (select cwms_util.get_office_code(ltab.office_id) from table (cast (:bv1 as lookup_type_tab_t)) ltab )'
  USING l_lookups;

EXECUTE IMMEDIATE 'INSERT INTO '||l_lookup_category||' 
    ( '||l_lookup_prefix||'_type_code,
    db_office_code,
    '||l_lookup_prefix||'_type_display_value,
    '||l_lookup_prefix||'_type_tooltip,
    '||l_lookup_prefix||'_type_active ) 
  SELECT cwms_seq.nextval code, 
    cwms_util.get_office_code(cwms_util.check_input_f(ltab.office_id)) office_id, 
    cwms_util.check_input_f(ltab.display_value) display_value, 
    cwms_util.check_input_f(ltab.tooltip) tooltip, 
    cwms_util.check_input_f(ltab.active) active 
  from table (cast (:bv1 as lookup_type_tab_t)) ltab'
  USING l_lookups;

dbms_output.put_line('retrieved '|| l_lookups.count || ' records.');

END;
