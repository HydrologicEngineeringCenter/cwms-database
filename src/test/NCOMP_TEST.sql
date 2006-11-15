CREATE OR REPLACE PACKAGE ncomp_test AS

  num   CONSTANT INTEGER     := 1000;

	procedure ncomp_demo;

	procedure plsql_demo;

END NCOMP_TEST;

/



CREATE OR REPLACE PACKAGE BODY ncomp_test AS

	

	PROCEDURE ncomp_demo

	AS language JAVA

	name 'ncomptest.NcompTest.runTest()';





	PROCEDURE plsql_demo

  IS

		tot NUMBER := 0;

	BEGIN

		FOR numIndex IN 1 .. num

		LOOP

			tot := numIndex;

		END LOOP;

		dbms_output.put_line(tot);

  END plsql_demo;



END ncomp_test;

/

EXIT;

