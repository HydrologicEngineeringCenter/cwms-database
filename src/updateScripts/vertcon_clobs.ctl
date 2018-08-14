load data
	infile *
	append
	into table cwms_20.at_clob
	fields terminated by ','
	(CLOB_CODE, 
	 OFFICE_CODE,                         
	 ID char, 
	 DESCRIPTION char,                         
	 filename FILLER char,
	 VALUE LOBFILE(filename) TERMINATED BY EOF)                 
begindata
-1,53,/VERTCON/VERTASCE.94,VERTCON table for Eastern U.S.,data/vertASCe.94
-2,53,/VERTCON/VERTASCC.94,VERTCON table for Central U.S.,data/vertASCc.94
-3,53,/VERTCON/VERTASCW.94,VERTCON table for Western U.S.,data/vertASCw.94
