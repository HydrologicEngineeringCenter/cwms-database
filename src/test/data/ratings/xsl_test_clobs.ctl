load data
	infile *
	append
	into table at_clob
	fields terminated by ','
	(CLOB_CODE "cwms_20.cwms_seq.nextval",
	 OFFICE_CODE,
	 ID char,
	 DESCRIPTION char,
	 filename FILLER char,
	 VALUE LOBFILE(filename) TERMINATED BY EOF)
begindata
-1,53,/XSLT_TEST/TEST_1,Null rating,xsl_test_1-null_rating.xml
-1,53,/XSLT_TEST/TEST_2,Single ind param simple rating,xsl_test_2-one_ind_param_simple_rating.xml
-1,53,/XSLT_TEST/TEST_3,Multiple ind param simple rating,xsl_test_3-multiple_ind_param_simple_rating.xml
-1,53,/XSLT_TEST/TEST_4,USGS stream rating,xsl_test_4-usgs_rating.xml
-1,53,/XSLT_TEST/TEST_5,Virtual rating,xsl_test_5-virtual_rating.xml
-1,53,/XSLT_TEST/TEST_6,Transitional rating,xsl_test_6-transitional_rating.xml

