/* Formatted on 3/3/2011 8:04:47 AM (QP5 v5.163.1008.3004) */
CREATE OR REPLACE PACKAGE cwms_sec_policy
AS
	/******************************************************************************
		NAME: 		cwms_sec_policy
		PURPOSE:

		REVISIONS:
		Ver		  Date		  Author 			 Description
		---------  ----------  ---------------  ------------------------------------
		1.0		  1/3/2007				  1. Created this package.
	******************************************************************************/
	--FUNCTION read_ts_codes (ns IN VARCHAR2, na IN VARCHAR2)
		--RETURN VARCHAR2;

	--FUNCTION write_ts_codes (ns IN VARCHAR2, na IN VARCHAR2)
		--RETURN VARCHAR2;

	FUNCTION da_role_office_codes (ns IN VARCHAR2, na IN VARCHAR2)
		RETURN VARCHAR2;
END cwms_sec_policy;
/
