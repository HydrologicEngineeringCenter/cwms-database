CREATE OR REPLACE function          return_time_pipe(startdate in date, n_minutes in number, offset in number default 0, enddate in date)
return date_table_type
pipelined

is

x             pls_integer;
new_date	  date;
  begin
  x:=0;
  loop
      new_date:= startdate + (x*n_minutes)/1440 + offset/1440;
	  exit when  new_date>=enddate;
  	  pipe row (new_date);
	  x:=x + 1;
  end loop;
  return;
end;
/


