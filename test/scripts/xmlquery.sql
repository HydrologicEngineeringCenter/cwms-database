
declare
   ctx          dbms_xmlquery.ctxType;
   query_string VARCHAR2(256);
   id_pattern   VARCHAR2(256);
   id_pattern2  VARCHAR2(256);
   office_id    VARCHAR2(16);
   header_text  VARCHAR2(256);
   results      CLOB;            
   result_size  INT;
   offset       INT := 1;
   pos          INT;
   use_case     boolean := false;
   stylesheet   CLOB;
   startTime    TIMESTAMP;
   endTime      TIMESTAMP;
   elapsedTime  INTERVAL DAY TO SECOND; 
begin                
   select value into stylesheet from at_clob where id = 'TSID_HTML';        
   office_id   := 'hq';
   office_id   := upper(office_id);                                                 
   id_pattern  := 'a*';
   id_pattern  := replace(replace(id_pattern, '*', '%'), '?', '_');
   id_pattern2 := replace(replace(id_pattern, '%', '*'), '_', '?');
   if use_case then
      query_string := 
         'select   cwms_ts_id as "ID" '          ||
         'from     at_cwms_ts_id_mview '         ||
         'where    office_id = :office_id '      ||
         'and      cwms_ts_id like :id_pattern ' ||
         'order by cwms_ts_id';
      header_text  := '<MatchParams office="' || office_id || '" pattern="' || id_pattern2 || '" case_sensitive="TRUE"/>';
   else
      query_string := 
         'select   cwms_ts_id as "ID" '                        ||
         'from     at_cwms_ts_id_mview '                       ||
         'where    upper(office_id) = upper(:office_id) '      ||
         'and      upper(cwms_ts_id) like upper(:id_pattern) ' ||
         'order by cwms_ts_id';
      header_text  := '<MatchParams office="' || office_id || '" pattern="' || id_pattern2 || '" case_sensitive="FALSE"/>';
   end if;
   ctx := dbms_xmlquery.newContext(query_string);
   dbms_xmlquery.setBindValue(ctx, 'office_id', office_id);
   dbms_xmlquery.setBindValue(ctx, 'id_pattern', id_pattern);
   dbms_xmlquery.setRowsetTag(ctx, 'TimeSeriesIDSet');   
   dbms_xmlquery.setRowTag(ctx, '');
   dbms_xmlquery.setMaxRows(ctx, dbms_xmlquery.ALL_ROWS);
   dbms_xmlquery.setDataHeader(ctx, header_text, 'TimeSeriesIDMatch');
   dbms_xmlquery.setXSLT(ctx, stylesheet);
   startTime := systimestamp;   
   results := dbms_xmlquery.getXML(ctx);                     
   endTime := systimestamp;
   elapsedTime := endTime - startTime;   
   result_size := dbms_lob.getlength(results);
   loop
      pos := dbms_lob.instr(results, chr(10), offset, 1);
      if pos = 0 then
         dbms_output.put_line(dbms_lob.substr(results, result_size - offset + 1, offset));
         exit;      
      end if;
      dbms_output.put_line(dbms_lob.substr(results, pos - offset, offset));
      offset := pos + 1;       
   end loop;
   dbms_xmlquery.closeContext(ctx);
end;

    
