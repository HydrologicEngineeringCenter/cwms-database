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
1,53,/XSLT/RATINGS_V1_TO_RADAR_XML,XSL transform from CWMS Ratings v1 xml to CWMS RADAR xml format,data/Ratings_v1_to_RADAR_xml.xsl
2,53,/XSLT/RATINGS_V1_TO_RADAR_TAB,XSL transform from CWMS Ratings v1 xml to CWMS RADAR tab format,data/Ratings_v1_to_RADAR_tab.xsl
3,53,/XSLT/RATINGS_V1_TO_RADAR_JSON,XSL transform from CWMS Ratings v1 xml to CWMS RADAR json,data/Ratings_v1_to_RADAR_json.xsl
