/* Formatted on 7/10/2011 12:26:48 PM (QP5 v5.163.1008.3004) */
ALTER SESSION SET current_schema = sys;
SET SERVEROUTPUT ON
SET ECHO ON
--
--
-- create public synonyms for CWMS schema packages and views
-- grant execute on packages to CWMS_USER role
-- grant select on view to CWMS_USER role
--
-- exclude any package or view named like %_SEC_%
--

DECLARE
	name_already_used   EXCEPTION;
	PRAGMA EXCEPTION_INIT (name_already_used, -955);

	TYPE str_tab_t IS TABLE OF VARCHAR2 (30);

	l_package_names	  str_tab_t;
	l_view_names		  str_tab_t;
	l_type_names		  str_tab_t;
	l_public_synonyms   str_tab_t;
	l_sql_statement	  VARCHAR2 (128);
	l_synonym			  VARCHAR2 (40);
BEGIN
	--
	-- collect public synonyms for CWMS items
	--
	SELECT	synonym_name
	  BULK	COLLECT INTO l_public_synonyms
	  FROM	dba_synonyms
	 WHERE	owner = 'PUBLIC' AND SUBSTR (synonym_name, 1, 5) = 'CWMS_';

	--
	-- collect CWMS schema packages except for security
	--
	SELECT	object_name
	  BULK	COLLECT INTO l_package_names
	  FROM	dba_objects
	 WHERE		 owner = '&cwms_schema'
				AND object_type = 'PACKAGE'
				AND object_name NOT LIKE '%_SEC_%'
				AND object_name <> 'CWMS_ENV'
			        AND object_name <> 'CWMS_UPASS';

	--
	-- collect CWMS schema views except for security
	--
	SELECT	object_name
	  BULK	COLLECT INTO l_view_names
	  FROM	dba_objects
	 WHERE		 owner = '&cwms_schema'
				AND object_type LIKE '%VIEW'
				AND object_name NOT LIKE '%_SEC_%'
				AND REGEXP_LIKE (object_name, '^[AM]V_');

	--
	-- collect CWMS schema object types
	--
	SELECT	object_name
	  BULK	COLLECT INTO l_type_names
	  FROM	dba_objects
	 WHERE		 owner = '&cwms_schema'
				AND object_type = 'TYPE'
				AND object_name NOT LIKE 'SYS_%';

	--
	-- drop collected public synonyms
	--
	DBMS_OUTPUT.put_line ('--');

	FOR i IN 1 .. l_public_synonyms.COUNT
	LOOP
		l_sql_statement := 'DROP PUBLIC SYNONYM ' || l_public_synonyms (i);
		DBMS_OUTPUT.put_line ('-- ' || l_sql_statement);

		EXECUTE IMMEDIATE l_sql_statement;
	END LOOP;

	--
	-- create public synonyms for collected packages
	--
	DBMS_OUTPUT.put_line ('--');

	FOR i IN 1 .. l_package_names.COUNT
	LOOP
		l_sql_statement :=
				'CREATE PUBLIC SYNONYM '
			|| l_package_names (i)
			|| ' FOR &cwms_schema'
			|| '.'
			|| l_package_names (i);
		DBMS_OUTPUT.put_line ('-- ' || l_sql_statement);

		EXECUTE IMMEDIATE l_sql_statement;
	END LOOP;

	--
	-- create public synonyms for collected views
	--
	DBMS_OUTPUT.put_line ('--');

	FOR i IN 1 .. l_view_names.COUNT
	LOOP
		l_synonym :=
			REGEXP_REPLACE (l_view_names (i),
								 '^(Z)?(A|(M))V_(CWMS_)*',
								 'CWMS_V_\3\1'
								);

		IF LENGTH (l_synonym) > 30
		THEN
			raise_application_error (
				-20999,
					'Synonym ('
				|| l_synonym
				|| ') for type &cwms_schema..'
				|| l_view_names (i)
				|| ' is too long'
			);
		END IF;

		l_sql_statement :=
				'CREATE PUBLIC SYNONYM '
			|| l_synonym
			|| ' FOR &cwms_schema'
			|| '.'
			|| l_view_names (i);
		DBMS_OUTPUT.put_line ('-- ' || l_sql_statement);

		EXECUTE IMMEDIATE l_sql_statement;
	END LOOP;

	--
	-- create public synonyms for collected types
	--
	DBMS_OUTPUT.put_line ('--');

	FOR i IN 1 .. l_type_names.COUNT
	LOOP
		l_synonym :=
			REGEXP_REPLACE (l_type_names (i),
								 '^((AT|CWMS)_)?(\w+?)(_T(YPE)?)?$',
								 'CWMS_T_\3'
								);

		IF LENGTH (l_synonym) > 30
		THEN
			DBMS_OUTPUT.put_line (
					'-- Synonym ('
				|| l_synonym
				|| ') for type &cwms_schema..'
				|| l_type_names (i)
				|| ' is too long'
			);
			CONTINUE;
		END IF;

		FOR j IN 2 .. 999999
		LOOP
			l_sql_statement :=
					'CREATE PUBLIC SYNONYM '
				|| l_synonym
				|| ' FOR &cwms_schema'
				|| '.'
				|| l_type_names (i);
			DBMS_OUTPUT.put_line ('-- ' || l_sql_statement);

			BEGIN
				EXECUTE IMMEDIATE l_sql_statement;

				EXIT;
			EXCEPTION
				WHEN name_already_used
				THEN
					DBMS_OUTPUT.put_line ('--  name already used!');
					l_synonym := SUBSTR (l_synonym, 1, 29) || j;
			END;
		END LOOP;
	END LOOP;

	--
	-- grant execute on collected packages to CWMS_USER role
	--
	DBMS_OUTPUT.put_line ('--');

	FOR i IN 1 .. l_package_names.COUNT
	LOOP
		l_sql_statement :=
				'GRANT EXECUTE ON &cwms_schema'
			|| '.'
			|| l_package_names (i)
			|| ' TO CWMS_USER';
		DBMS_OUTPUT.put_line ('-- ' || l_sql_statement);

		EXECUTE IMMEDIATE l_sql_statement;
	END LOOP;

	--
	-- grant execute on collected types to CWMS_USER role
	--
	DBMS_OUTPUT.put_line ('--');

	FOR i IN 1 .. l_type_names.COUNT
	LOOP
		l_sql_statement :=
				'GRANT EXECUTE ON &cwms_schema'
			|| '.'
			|| l_type_names (i)
			|| ' TO CWMS_USER';
		DBMS_OUTPUT.put_line ('-- ' || l_sql_statement);

		EXECUTE IMMEDIATE l_sql_statement;
	END LOOP;

	--
	-- grant select on collected views to CWMS_USER role
	--
	DBMS_OUTPUT.put_line ('--');

	FOR i IN 1 .. l_view_names.COUNT
	LOOP
		l_sql_statement :=
				'GRANT SELECT ON &cwms_schema'
			|| '.'
			|| l_view_names (i)
			|| ' TO CWMS_USER';
		DBMS_OUTPUT.put_line ('-- ' || l_sql_statement);

		EXECUTE IMMEDIATE l_sql_statement;
	END LOOP;
END;
/
