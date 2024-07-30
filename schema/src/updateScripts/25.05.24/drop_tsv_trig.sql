set serveroutput on
whenever sqlerror continue
DECLARE
    l_exist PLS_INTEGER;
BEGIN
    -- get the trigger count
    SELECT COUNT(*) INTO l_exist
    FROM user_triggers
    WHERE trigger_name = upper('at_tsv_count_trig');
    
    -- if the trigger exist, drop it
    IF l_exist > 0 THEN 
        EXECUTE IMMEDIATE 'DROP TRIGGER at_tsv_count_trig';
    END IF;
END;
/
