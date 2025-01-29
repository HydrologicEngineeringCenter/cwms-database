begin
   dbms_utility.compile_schema('${CWMS_SCHEMA}',false);
   FOR cur IN (
			   SELECT OBJECT_NAME, OBJECT_TYPE, owner, 
			        (select count(1) from all_dependencies ad
			         where ad.owner = ao.owner and name = OBJECT_NAME
			        ) priority /* all_dependencies is transitive, therefore using simpler aggregate query instead of hierarchical*/
			   FROM all_objects ao
			   WHERE object_type in ('TYPE','TYPE BODY') and owner = '${CWMS_SCHEMA}' AND status = 'INVALID' 
			   order by priority
			) LOOP 
      BEGIN
         if cur.OBJECT_TYPE = 'TYPE BODY' then 
            EXECUTE IMMEDIATE 'alter type ' || cur.owner || '.' || cur.OBJECT_NAME || ' compile body'; 
         else 
            EXECUTE IMMEDIATE 'alter ' || cur.OBJECT_TYPE || ' ' || cur.owner || '.' || cur.OBJECT_NAME || ' compile'; 
         end if; 
      EXCEPTION
      WHEN OTHERS THEN NULL; 
      END;
   end loop;
end;
/
