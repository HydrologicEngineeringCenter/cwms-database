CREATE OR REPLACE procedure          cwms_ts_test_out(p_cursor in sys_refcursor, html in number default null)

is

  type l_rec_type is table of q1cwmspd.at_tsv_dqu_view%rowtype index by binary_integer;
  
  l_rec l_rec_type;
  
--  l_rec q1cwmspd.at_tsv_id_view%rowtype;
  
  begin
  
  
  	   loop
		   fetch p_cursor bulk collect into l_rec limit 500;
		   for i in 1 .. l_rec.count
		   loop
		   	   if html is null then 
			      dbms_output.put_line(l_rec(i).ts_code||', '|| l_rec(i).date_time||', '||l_rec(i).data_entry_date||', '||
				  					   l_rec(i).value||', '||l_rec(i).office_id||','||l_rec(i).unit_id||', '||l_rec(i).cwms_ts_id||', '||
									   l_rec(i).changed_id);
				else	
				  htp.p(l_rec(i).ts_code||', '|| l_rec(i).date_time||', '||l_rec(i).data_entry_date||', '||', '||
				  					   l_rec(i).value||', '||l_rec(i).office_id||','||l_rec(i).unit_id||', '||l_rec(i).cwms_ts_id);
			   end if;
		    end loop;
		    exit when p_cursor%notfound;	
		end loop;
		
-- 		loop
-- 		  fetch p_cursor into l_rec;
-- 		  if html is null then 
-- 			 dbms_output.put_line(l_rec.ts_code||', '|| l_rec.date_time||', '||l_rec.data_entry_date||', '||l_rec.quality||', '||
-- 				    			  l_rec.value||', '||l_rec.office_id||','||l_rec.unit_id||', '||l_rec.cwms_ts_id);
-- 			else	
-- 			 htp.p(l_rec.ts_code||', '|| l_rec.date_time||', '||l_rec.data_entry_date||', '||l_rec.quality||', '||
-- 				    			  l_rec.value||', '||l_rec.office_id||','||l_rec.unit_id||', '||l_rec.cwms_ts_id);
-- 		  end if;
-- 		  exit when p_cursor%notfound;	
-- 		end loop;
		
		close p_cursor;
   end;
/

