CREATE OR REPLACE PACKAGE mrr AS
/******************************************************************************
   NAME:       mrr
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        5/26/2005             1. Created this package.
******************************************************************************/

  /*  PLSQL Array Types */
 TYPE Char1ArrayTyp IS TABLE OF VARCHAR2(1)
    INDEX BY BINARY_INTEGER;
  TYPE Char3ArrayTyp IS TABLE OF VARCHAR2(8)
    INDEX BY BINARY_INTEGER;
  TYPE Char8ArrayTyp IS TABLE OF VARCHAR2(8)
    INDEX BY BINARY_INTEGER;
  TYPE Char16ArrayTyp IS TABLE OF VARCHAR2(16)
    INDEX BY BINARY_INTEGER;
  TYPE Char32ArrayTyp IS TABLE OF VARCHAR2(32)
    INDEX BY BINARY_INTEGER;
  TYPE Char80ArrayTyp IS TABLE OF VARCHAR2(80)
    INDEX BY BINARY_INTEGER;
  TYPE Char200ArrayTyp IS TABLE OF VARCHAR2(200)
    INDEX BY BINARY_INTEGER;
  TYPE NumArrayTypIB IS TABLE OF NUMBER
    INDEX BY BINARY_INTEGER;
  TYPE BDArrayTyp IS TABLE OF BINARY_DOUBLE
    INDEX BY BINARY_INTEGER;
  TYPE IntArrayTyp IS TABLE OF INTEGER
    INDEX BY BINARY_INTEGER;
  TYPE DateArrayTyp IS TABLE OF DATE
    INDEX BY BINARY_INTEGER;
  TYPE RawArrayTyp IS TABLE OF RAW(4)
    INDEX BY BINARY_INTEGER;
  TYPE tsv_cur is ref cursor;
 -- TYPE TSVArray IS TABLE OF CWMS2.at_tsv_2002%ROWTYPE
 --    INDEX BY BINARY_INTEGER;
  TYPE rc is ref cursor;

/****************************************/
 PROCEDURE Select_Values_ref (
    cwms_tsid  IN VARCHAR2,
    start_date IN DATE,
	start_flag IN INTEGER,
	end_date   IN DATE,
	end_flag   IN INTEGER,
	units	   IN VARCHAR2,
    vals       OUT SYS_REFCURSOR,
    err_num    OUT INTEGER);
/****************************************/
 PROCEDURE build_inline_string (
    start_year    IN integer,
    end_year      IN integer,
	inline_string OUT varchar2,
    err_num       OUT INTEGER);
/****************************************/
  PROCEDURE insert_values_dyn (
    officeid  	 IN VARCHAR2,
    cwms_tsids   IN Char200ArrayTyp,
	units		 IN	OUT VARCHAR2,
    ora_dates    IN DateArrayTyp,
    vals         IN BDArrayTyp,
	qual_codes   IN NumArrayTypIB,
    num_vals     IN INTEGER,
    err_num      OUT INTEGER);
/****************************************/
 PROCEDURE Select_Values_pls (
    officeid   IN VARCHAR2,
    cwms_tsid  IN VARCHAR2,
    start_date IN DATE,
	start_flag IN INTEGER,
	end_date   IN DATE,
	end_flag   IN INTEGER,
	units	   IN OUT VARCHAR2,
    vals       OUT SYS_REFCURSOR,
	num_vals   OUT INTEGER,
    err_num    OUT INTEGER);
/****************************************/
END mrr;
/
