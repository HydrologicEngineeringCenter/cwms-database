--exec sys.utl_recomp.recomp_serial('CWMS_DBA');
--exec sys.utl_recomp.recomp_serial('&cwms_schema');
BEGIN
    FOR c
        IN (SELECT object_name, object_type
              FROM dba_objects
             WHERE     owner IN ('&cwms_schema', 'CWMS_DBA')
                   AND object_type IN ('PACKAGE', 'TYPE')
                   AND status <> 'VALID')
    LOOP
        DBMS_OUTPUT.PUT_LINE ('Compiling ' || c.object_name);

        EXECUTE IMMEDIATE
               'ALTER '
            || c.object_type
            || ' '
            || c.object_name
            || ' COMPILE '
            || c.object_type;
    END LOOP;

    FOR c
        IN (SELECT object_name, REGEXP_SUBSTR (object_type, '(\S*)') ot
              FROM dba_objects
             WHERE     owner IN ('&cwms_schema', 'CWMS_DBA')
                   AND object_type IN ('PACKAGE BODY', 'TYPE BODY')
                   AND status <> 'VALID')
    LOOP
        DBMS_OUTPUT.PUT_LINE ('Compiling ' || c.object_name);

        EXECUTE IMMEDIATE
            'ALTER ' || c.ot || ' ' || c.object_name || ' COMPILE BODY';
    END LOOP;

    FOR c
        IN (SELECT object_name, object_type
              FROM dba_objects
             WHERE     owner IN ('&cwms_schema', 'CWMS_DBA')
                   AND object_type IN ('VIEW', 'TRIGGER','PROCEDURE','FUNCTION')
                   AND status <> 'VALID')
    LOOP
        DBMS_OUTPUT.PUT_LINE ('Compiling ' || c.object_name);

        EXECUTE IMMEDIATE
               'ALTER '
            || c.object_type
            || ' '
            || c.object_name
            || ' COMPILE';
    END LOOP;
END;
/

