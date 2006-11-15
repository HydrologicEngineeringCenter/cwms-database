SET TIME ON
SELECT SYSDATE FROM DUAL;
SET ECHO ON

CREATE OR REPLACE PACKAGE test_ts AS

/*
function return_time_pipe(startdate in date, n_minutes in number, offset in number default 0, enddate in date)  return q1cwmspd.date_table_type pipelined;
*/

PROCEDURE retrieve_ts(officeid IN VARCHAR2, timeseries_desc IN VARCHAR2,
	units IN VARCHAR2, start_time IN DATE, end_time IN DATE, 
	at_tsv_rc OUT SYS_REFCURSOR, inclusive IN NUMBER DEFAULT NULL);

procedure store_ts (office_id IN VARCHAR2, timeseries_desc IN VARCHAR2, 
					units IN VARCHAR2, timeseries_data IN test_tsv_array,
					store_rule IN BINARY_INTEGER, override_protection IN BINARY_INTEGER);

procedure checkstore;
					
END;
/

SHOW ERRORS
SET ECHO OFF
SET TIME OFF
