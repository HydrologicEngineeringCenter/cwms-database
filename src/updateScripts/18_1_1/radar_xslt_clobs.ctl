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
-1,53,/XSLT/RATINGS_V1_TO_RADAR_XML,CWMS RADAR Rating Transform to XML,../../data/Ratings_v1_to_RADAR_xml.xsl
-1,53,/XSLT/RATINGS_V1_TO_RADAR_JSON,CWMS RADAR Rating Transform to JSON,../../data/Ratings_v1_to_RADAR_json.xsl
-1,53,/XSLT/RATINGS_V1_TO_RADAR_TAB,CWMS RADAR Rating Transform to TAB,../../data/Ratings_v1_to_RADAR_tab.xsl
