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
-1,53,/XSD/HEC-DATATYPES-TEMPLATE.XSD,XML schema document template for hec-datatypes.xsd,data/hec-datatypes-template.xsd
