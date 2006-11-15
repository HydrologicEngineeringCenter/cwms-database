CREATE OR REPLACE procedure          cwms_ts_test

is

  l_cursor 		         sys_refcursor;
  office_id				 varchar2(100);
  st_date				 date;
  e_date				 date;
  ts_id					 varchar2(200);
  ts_code				 number;
  unit_val				 varchar2(20);
  
  begin
  	 office_id:='NWDP';
	 ts_id:='BCKO.Stage.Inst.0.0.WNC-RAW';
	 st_date:=to_date('12/20/2003','mm/dd/yyyy');
	 e_date	:=to_date('12/30/2003','mm/dd/yyyy');
	 unit_val:='ft';
	 
	 	   
	   
	 q1cwmspd.cwms_ts_retrieve(officeid=>office_id, timeseries_desc=>ts_id, units=>unit_val, start_time=>st_date, end_time=>e_date, at_tsv_rc=>l_cursor);
	 
	 q1cwmspd.cwms_ts_test_out(p_cursor=>l_cursor);
	    
	   
   end;
/

