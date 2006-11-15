CREATE OR REPLACE function          return_time_pipe(startdate in date, n_minutes in number, offset in number default 0, enddate in date) 
return q1cwmspd.date_table_type
pipelined

is

x             pls_integer;
new_date	  date;

  begin
  x:=0;
  
  loop
     
      new_date:= startdate + (x*n_minutes)/1440 + offset/1440; 
  	  pipe row (new_date);
	
	  exit when  new_date>=enddate;
	  
	
	  x:=x + 1;
  end loop;
  
  return;
  
end;
/


