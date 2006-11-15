create or replace PACKAGE ORACLE_TEST AS
	procedure testRmi;
END;
/
create or replace PACKAGE BODY ORACLE_TEST AS
	procedure testRmi
	as language java
	name 'testoracle.TestOracle.testRmi()';
END ORACLE_TEST;
/