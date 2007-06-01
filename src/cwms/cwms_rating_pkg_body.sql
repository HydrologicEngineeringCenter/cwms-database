CREATE OR REPLACE package body CWMS_20.cwms_rating as

/******************************************************************************
*   Name:       CWMS_RATING 
*   Purpose:       
*
*   Revisions:  
*   Ver        Date        Author      Description  
*   ---------  ----------  ----------  ----------------------------------------
*   1.0        4/23/2007   Portin      Original  
******************************************************************************/

   -- package global table of rdb comment lines 

   type       vc132_tbl is table of varchar2(132) index by pls_integer;
   g_lines    vc132_tbl;


   -- package local functions      

   function type_ok (p_type in varchar2) return boolean is
      
      l_type_code     number;
      
   begin
   
      -- Test for valid rating type 

      select rating_type_code into l_type_code 
      from   cwms_rating_type 
      where  rating_type_id = p_type; 
      
      return sql%rowcount > 0;
       
   exception when others then return FALSE; 
   end;   

   function interp_ok (p_interp in varchar2) return boolean is
      
      l_interp_code   number;
      
   begin  
   
      -- Test for valid rating interpolation 

      select interpolate_code into l_interp_code 
      from   cwms_rating_interpolate 
      where  interpolate_id = p_interp; 
      
      return sql%rowcount > 0;

   exception when others then return FALSE; 
   end;   

   function check_T_or_F (p_flag varchar2, p_default varchar2) return varchar2 as

      l_flag   varchar2(1);
      l_msg    varchar2(256);

   begin

      -- Default null value, convert to upper case and validate  

      l_msg := 'VALUE MUST BE "T" OR "F" ('||p_flag||')';

      if length(p_flag) != 1 then
         raise_application_error (-20999,l_msg,TRUE);      
      end if; 
   
      l_flag := upper(nvl(p_flag,p_default));

      if l_flag <> 'T' and l_flag <> 'F' then
         raise_application_error (-20999,l_msg,TRUE);      
      end if;

      return l_flag;

   end;

   function get_rating_code (
      p_source   in   varchar2,              -- rating source ("USGS") 
      p_type     in   varchar2,              -- rating type ("STGQ") 
      p_office   in   varchar2 default null  -- db office id 
      ) 
      return integer is
      
      l_office_code   pls_integer;
      l_rating_code   pls_integer;
      l_msg           varchar2(256);

   begin
   
      -- Get the RATING_CODE for the rating table family     

      -- handle NULL default parameter  

      l_office_code := cwms_util.get_db_office_code(p_office); 

      dbms_output.put_line('db_office_code='||l_office_code);

      select rating_code into l_rating_code 
      from   at_rating inner join cwms_rating_type using (rating_type_code)
      where  db_office_code        = l_office_code 
        and  source                = p_source
        and  upper(rating_type_id) = upper(p_type);   
   
      dbms_output.put_line('rating_code='||to_char(l_rating_code));

      return l_rating_code;

   exception 
      when NO_DATA_FOUND then
      
         l_msg := 'cwms_rating: ';
      
         if not type_ok(p_type) then l_msg:=l_msg||'Invalid Type: ';
         else                        l_msg:=l_msg||'The rating family doesn''t exist: ';
         end if;
       
         l_msg := l_msg||' Source='||p_source||', Type='||p_type||', Office='||p_office;      

         raise_application_error (-20999,l_msg,TRUE);
      
      when others then
         dbms_output.put_line('get_rating_code '||SQLERRM);
         raise;

   end get_rating_code;


   function get_loc_code (
      p_source   in   varchar2,              -- rating source ("USGS")  
      p_type     in   varchar2,              -- rating type ("STGQ") 
      p_loc      in   varchar2,              -- cwms location ("BON-SB1")  
      p_office   in   varchar2 default null  -- db office id       
      )  
      return integer is
      
      l_rating_code   pls_integer;  
      l_loc_code      pls_integer;

   begin 
   
      -- Get the RATING_LOC_CODE for the rating table family and location      
   
      l_rating_code := get_rating_code (p_source,p_type,p_office);
   
      select rating_loc_code into l_loc_code  
      from   at_rating_loc  r,
             mv_cwms_ts_id  m
      where  upper(location_id) = upper(p_loc)
        and  r.location_code = m.location_code;    
    
      dbms_output.put_line('rating_loc_code='||to_char(l_loc_code));

      return l_loc_code;

   exception when others then
   
      -- ORA-01403: no data found 
      dbms_output.put_line('get_loc_code: '||SQLERRM);
      raise;

   end get_loc_code;
   
   
   function get_comment (
      p_str  in varchar2,                    -- search string 
      p_pos  in integer default 1,           -- 1=1st occurance, 2=2nd occurance, ... 
      p_line in char    default 'F'          -- if"T" then return the entire line  
      ) 
      return varchar2 is 
   
      l_pos  integer;       -- local copy, decremented on each occurance of p_str  
      l_line char(1);       -- local copy  
      l_val  varchar2(132); -- return value 
      j      pls_integer;   -- beginning of p_str in line(i) 
      k      pls_integer;   -- position of the "=" following p_str  
      m      pls_integer;   -- position of the beginning of the returned string 
      n      pls_integer;   -- position of the end of the return string 
      
   begin
   
      -- Parse the RDB file metadata 
      --
      -- Look for the string p_str in the package table g_lines and return the  
      -- associated value. The values are identified in one of the following  
      -- ways: 
      -- 
      --   1. p_str="value" 
      --   2. p_str=value                      (whitespace terminated) 
      --   3. RETRIEVED: 2006-10-16 20:45:56   (special string)
      -- 
      -- Some strings, like RATING_DATE BEGIN occure more than once. p_pos
      -- identifies which occurance of the string to find (default=1). 
      -- 
      -- When p_line="T" then return the entire line. This is simply the way I 
      -- choose to to get the correct BZONE or EZONE for RATING_DATETIME BEGIN.  
      -- Defaults to "F". 
      -- 
      -- This is not infallible parsing code. For example, it assumes that if 
      -- a quote appears after p_str, then the value is quoted, when in fact 
      -- the quote may be the delimiter for a subsequent string on the line.    

      -- handle NULL default parameters and case   

      l_pos  := nvl(p_pos,1);
      l_line := upper(nvl(p_line,'F'));
         
      l_val := null;
      for i in g_lines.first..g_lines.last loop     -- scan all lines for p_str 
         j := instr(g_lines(i),p_str); 
         if j>0 then                                -- found p_str 
            if l_pos > 1 then                       -- desired occurance? 
               l_pos := l_pos - 1;                  -- no, look for the next one  
            else                                    -- yes, get the value             
               if  l_line = 'T' then                --    want the whole line? 
                  m := 1;                           --    yes 
                  n := 132;                        
               else                                 --    no, find the delimiters  
                  k := instr(g_lines(i),'=',j);      
                  m := instr(g_lines(i),'"',j+1);
                  if p_str='RETRIEVED' then
                     m := 16;
                     n := 19;
                  elsif m>0 then
                     m := m+1;
                     n := instr(g_lines(i)||'"','"',m)-m;
                  else
                     m := k+1;
                     n := instr(g_lines(i)||' ',' ',m)-m;
                  end if;
               end if;
               --dbms_output.put_line(p_str||'  '||l_pos||','||i||','||m||','||n);
               --dbms_output.put_line(g_lines(i));            
               l_val := trim(substr(g_lines(i),m,n));
               exit;
            end if;
         end if;   
      end loop;
      return l_val;
      
   exception when others then
    
         dbms_output.put_line(SQLERRM);
         return null;
         
   end get_comment;

   function get_date (p_date in varchar2, p_tz in varchar2)
   return date is
   
      l_date  date; 
      
   begin
   
      -- Given a USGS RDB file date in the from 
      --
      --    yyyymmddhh24miss tzd 
      -- 
      -- such as  
      --
      --   "20070514120000 PDT" 
      -- 
      -- return the date converted to timezone p_zone. 

      -- Could check for invalid p_tz, for example, UTC and PDT are not  
      -- valid values. 
        
      l_date := to_date(substr(p_date,1,14),'yyyymmddhh24miss');
      
      return new_time(l_date,substr(p_date,16,3),p_tz); 

   exception when others then
    
         dbms_output.put_line(SQLERRM); 
         raise;
               
   end get_date;

procedure add_rating (
   p_source     in   varchar2,               -- rating source ("USGS") 
   p_type       in   varchar2,               -- rating type ("STGQ") 
   p_interp     in   varchar2,               -- rating expansion ("LOGARITHMIC")  
   p_count      in   integer  default 1,     -- independent parameter count 
   p_desc       in   varchar2 default null,  -- description for this rating family 
   p_office     in   varchar2 default null   -- db office id 
    
   ) is 

   l_count         pls_integer;
   l_office_code   pls_integer;
   l_msg           varchar2(256);
   
begin

   -- Add a rating family 

   -- Handle NULL default parameters in the INSERT 

   -- REMOVE THESE LINES 
   --l_count       := nvl(p_count,1);
   --l_office_code := cwms_util.get_db_office_code(p_office); 
      
   insert into at_rating 
   select cwms_seq.nextval,
          cwms_util.get_db_office_code(p_office),
          p_source,
          t.rating_type_code,
          i.interpolate_code,
          nvl(p_count,1),
          p_desc
   from   cwms_rating_type t,
          cwms_rating_interpolate i
   where  upper(t.rating_type_id)=upper(p_type)
     and  upper(i.interpolate_id)=upper(p_interp);    

   dbms_output.put_line(to_char(sql%rowcount)||' row inserted into at_rating');

   if sql%rowcount=0 then
   
      l_msg := 'cwms_rating.add_rating failed: ';
      
      if    not type_ok  (p_type)   then l_msg:=l_msg||'Invalid Type: ';
      elsif not interp_ok(p_interp) then l_msg:=l_msg||'Invalid Interpolation: ';
      end if;
       
      l_msg := l_msg||' Source='||p_source||', Type='||p_type||', Interp='
               ||p_interp||', Office='||p_office;
                
      raise_application_error (-20999,l_msg,FALSE);
      
    end if;  

exception when others then
   -- ORA-00001: unique constraint (CWMS.AT_RATING_AK1) violated 
   -- ORA-01403: no data found 
   dbms_output.put_line(SQLERRM);
   raise;

end add_rating;   

procedure add_parameters (
   p_source     in   varchar2,               -- rating source ("USGS") 
   p_type       in   varchar2,               -- rating type ("STGQ") 
   p_indep_1    in   varchar2,               -- 1st independent parameter 
   p_indep_2    in   varchar2 default null,  -- 2nd independent parameter (optional)   
   p_dep        in   varchar2,               -- dependent parameter 
   p_version_1  in   varchar2,               -- version for the 1st indep parameter  
   p_version_2  in   varchar2 default null,  -- version for the 2nd indep parameter   
   p_version_3  in   varchar2 default null,  -- version for the dependent parameter   
   p_desc       in   varchar2 default null,  -- description for this parameter set 
   p_office     in   varchar2 default null   -- db office id    
   ) is 

   l_rating_code   pls_integer;
   l_parms_code    pls_integer;
   l_parm_count    pls_integer;
   l_msg           varchar2(256);

begin

   -- Add a rating parameter and/or version 
   -- Version 2 and 3 default to version 1 

   -- Does the rating family exist?  
   
   l_rating_code := get_rating_code (p_source,p_type,p_office);

   -- Does the parameter set exist?   

   begin
      select parm_count, parms_code into l_parm_count, l_parms_code
      from   av_rating
      where  rating_code           = l_rating_code
        and  indep_parm_1          = p_indep_1
        and  nvl(indep_parm_2,'X') = nvl(p_indep_2,'X')
        and  dep_parm              = p_dep
        and  rownum                < 2;
        
   exception
      when NO_DATA_FOUND then l_parms_code := null;       
   end;

   dbms_output.put_line('rating_parms_code='||l_parms_code);

   -- Has the right number of independent parameters been provided?  

   if l_parm_count=2 and p_indep_2 is null then
      l_msg := 'cwms_rating.add_parameters: Second independent parameter is missing';
      raise_application_error (-20999,l_msg,TRUE);
   end if;

   -- If the parameter set doesn't exist, then add it   
  
   if l_parms_code is null then
      
      select cwms_seq.nextval into l_parms_code from dual;

      dbms_output.put_line('rating_parms_code='||l_parms_code);
      
      -- NOTE: If p_indep_1 or p_dep are bad, you get an ORA-01400: cannot insert NULL, 
      --       but if p_indep_2 is bad, it won't be caught because nulls are allowed. 
      --  
      -- NOTE: If I got the parmeter_codes in a separate SELECT, such as when I get  
      --       nextval above, then I could be more specific about invalid parameter_id's. 
      
      insert into  at_rating_parameters
      select l_parms_code, 
             l_rating_code, 
             (select parameter_code from mv_cwms_ts_id where upper(parameter_id)=upper(p_indep_1) and rownum=1),
             (select parameter_code from mv_cwms_ts_id where upper(parameter_id)=upper(p_indep_2) and rownum=1),
             (select parameter_code from mv_cwms_ts_id where upper(parameter_id)=upper(p_dep) and rownum=1),
             p_desc
      from   dual;                    

      -- ORA-01400: cannot insert NULL into ("CWMS_20"."AT_RATING_PARAMETERS"."INDEP_PARM_CODE_1") 

      dbms_output.put_line(sql%rowcount||' row inserted into at_rating_parameters');
   
      if sql%rowcount=0 then 
         l_msg := 'cwms_rating.add_parameters failed for Source="'||p_source 
                  ||'", Type="'||p_type||'", Indep_1="'||p_indep_1||'", Indep_2="' 
                  ||p_indep_2||'", Dep="'||p_dep||'"'; 
         raise_application_error (-20999,l_msg,TRUE);
       end if; 
      
   end if;

   -- Add the versions 
 
   begin 
      insert into at_rating_versions 
      values (cwms_seq.nextval,l_parms_code,p_version_1,
              nvl(p_version_2,p_version_1),nvl(p_version_3,p_version_1));
      
      dbms_output.put_line(to_char(sql%rowcount)||' row inserted into at_rating_version');
            
   exception
--      when DUP_VAL_ON_INDEX then
--         -- ORA-00001: unique constraint (CWMS.AT_RATING_VERSION_PK) violated 
--         l_msg := 'cwms_rating.add_parameters: ' 
--                  ||'The version already exists: Source="'||p_source 
--                  ||'", Type="'||p_type||'", Indep_1="'||p_indep_1||'", Indep_2="' 
--                  ||p_indep_2||'", Dep="'||p_dep||'", Version="'||p_version||'"';            
--         dbms_output.put_line(l_msg);
          
   when others then
      dbms_output.put_line(SQLERRM);
      raise;
                 
   end;

exception when others then
   dbms_output.put_line(SQLERRM);
   raise;

end add_parameters;

function add_location (
   p_source     in   varchar2,               -- rating source ("USGS")  
   p_type       in   varchar2,               -- rating type ("STGQ") 
   p_loc        in   varchar2,               -- cwms location ("BON-SB8") 
   p_load       in   char     default 'T',   -- auto load flag ("T" or F")   
   p_active     in   char     default 'F',   -- auto active flag ("T" or F")    
   p_filename   in   varchar2 default null,  -- cwms pathname version 
   p_desc       in   varchar2 default null,  -- description for this location 
   p_office     in   varchar2 default null   -- db office id       
   ) return integer is
   
   l_rating_code     pls_integer;
   l_loc_code        pls_integer; 
   l_load            char(1);   
   l_active          char(1); 
   l_msg             varchar2(256);  
   
begin 

   -- Add a CWMS location to a rating family 

   -- Check and condition T/F parameters    
   
   l_load   := check_T_or_F(p_load,'T');
   l_active := check_T_or_F(p_active,'F');

   -- Does the rating family exist? 

   l_rating_code := get_rating_code (p_source,p_type,p_office);

   -- Add the location 
 
   select cwms_seq.nextval into l_loc_code from dual;

   
   insert into at_rating_loc
   ( rating_loc_code, rating_code, location_code, auto_load_flag,
     auto_active_flag, filename, description )  
   select l_loc_code,
          l_rating_code, 
          location_code,
          l_load,
          l_active,
          p_filename,
          p_desc
   from   mv_cwms_ts_id
   where  upper(location_id) = upper(p_loc); 

   dbms_output.put_line(to_char(sql%rowcount)||' row inserted into at_rating_loc');

   if sql%rowcount=0 then   
      l_msg := 'cwms_rating.add_location failed for Source="'||p_source 
               ||'", Type="'||p_type||'", Location="'||p_loc||'"';      
      raise_application_error (-20999,l_msg,TRUE);
    end if;    

   return l_loc_code;

exception
   when DUP_VAL_ON_INDEX then
      -- ORA-00001: unique constraint (CWMS.AT_RATING_LOC_AK1) violated  
      l_msg := 'cwms_rating.add_location: '
               ||'The location already exists: Source='||p_source
               ||', Type='||p_type||', Location='||p_loc;         
      dbms_output.put_line(l_msg);
        
   when others then
      dbms_output.put_line(SQLERRM);
      raise;

end add_location;


procedure delete_location (
   p_source     in   varchar2,               -- rating source ("USGS") 
   p_type       in   varchar2,               -- rating type ("STGQ") 
   p_loc        in   varchar2,               -- cwms base location ("BON") 
   p_office     in   varchar2 default null   -- db office id       
   ) is
   
   l_loc_code        pls_integer;    
   
begin
   
   -- Get the rating_loc_code  
  
   l_loc_code := get_loc_code (p_source,p_type,p_loc,p_office);
   
   -- Delete all the base curves, shifts and extension points for a location 
   -- in a rating family 
   
   delete at_rating_loc where rating_loc_code = l_loc_code;

   dbms_output.put_line('cwms_rating.delete_location: Source='||p_source
      ||', Type='||p_type||', Location='||p_loc||', '||sql%rowcount||' row deleted'); 
      
exception when others then dbms_output.put_line(SQLERRM); raise;           
    
end delete_location; 


procedure extend_curve (
   p_source     in   varchar2,               -- rating source ("USGS") 
   p_type       in   varchar2,               -- rating type ("STGQ") 
   p_loc        in   varchar2,               -- cwms base location ("BON") 
   p_x          in   number,                 -- X value 
   p_y          in   number,                 -- Y value 
   p_x_units    in   varchar2 default null,  -- X value units ("ft"), default to db units  
   p_y_units    in   varchar2 default null,  -- Y value units ("cfm"), default to db units 
   p_effective  in   timestamp with time zone     -- defaults to the current day  
                     default trunc(systimestamp),  
   p_active     in   char     default 'F',   -- active flag ("T" or F") 
   p_office     in   varchar2 default null   -- db office id                           
   ) is
   
   l_effective   timestamp with time zone;
   l_active      char(1); 
   l_loc_code    pls_integer;
   l_ext_code    pls_integer;
   l_msg         varchar2(256);
   
begin

   -- Add X/Y values to extend all rating curves at this location   
   -- 
   -- NOTE: Could make the x,y parameters an array  

   -- Handle NULL default parameter    
   -- Check and condition T/F parameter     
   
   l_effective := nvl(p_effective,trunc(systimestamp));
   l_active    := check_T_or_F(p_active,'F');
     
   -- Get the rating_loc_code  
  
   l_loc_code := get_loc_code (p_source,p_type,p_loc,p_office);

   -- Does the rating table extension specification exist? 

   begin
   
      select rating_extension_code into l_ext_code
      from   at_rating_extension_spec
      where  rating_loc_code = l_loc_code
        and  effective_date  = l_effective;

   exception when no_data_found then
   
      -- No, add it  
   
      insert into at_rating_extension_spec
      (rating_extension_code, rating_loc_code, effective_date, active_flag) 
      values (cwms_seq.nextval, l_loc_code, l_effective, l_active)
      returning rating_extension_code into l_ext_code; 

      dbms_output.put_line(to_char(sql%rowcount)||' row inserted into at_rating_extension_spec');

   end;

   dbms_output.put_line('rating_extension_code='||l_ext_code);


   -- Add the x,y points 

   -- NOTE: Will need to do units conversion   

   begin
   
      insert into at_rating_extension_value
      (rating_extension_code,x,y) values (l_ext_code,p_x,p_y);

      dbms_output.put_line(to_char(sql%rowcount)||' row inserted into at_rating_extension_value');

   exception when DUP_VAL_ON_INDEX then
      -- ORA-00001: unique constraint violated  
      l_msg := 'cwms_rating.extend_curve: '
               ||'The point already exists: Source='||p_source||', Type='
               ||p_type||', Location='||p_loc||', Effective Date='
               ||l_effective||', x='||p_x||', y='||p_y;         
      raise_application_error (-20999,l_msg,TRUE);   
         
   end; 


exception when others then
   dbms_output.put_line(SQLERRM);
   raise;

end extend_curve;


procedure load_rdb_files ( 

   p_dir        in   varchar2,               -- a directory object name       
   p_date       in   date,                   -- load rdb files newer than p_date 
   p_office     in   varchar2 default null   -- db office id                             
   ) is
   
   type          vc132_nt is table of varchar2(132);
   l_files       vc132_nt;   
   l_path        varchar2(132);              -- os path for the directory object 
   l_cwms_id     varchar2(32); 

begin 

   -- Load all RDB files in the directory indentified by p_dir that have  
   -- a modified date newer than or equal to p_date.
               
   --  get the directory name for the directory object p_dir 
   
   select directory_path into l_path 
   from   sys.all_directories 
   where  directory_name = upper(p_dir);  

   dbms_output.put_line(l_path);

   -- load a directory listing for p_dir into the global temporary table 
   
   get_dir_list(l_path);

   -- NOTE: The EXECUTE IMMEDIATE in the called procedure, load_rdb_files,  
   --       caused a problem when used with a CURSOR FOR LOOP  
   -- 
   --          ORA-01410: invalid ROWID
   --          ORA-08103: object no longer exists
   -- 
   --       For this reason, I used a nested table and a FOR LOOP below  

   -- process all RDB files that have been updated on or after p_date   

   select filename bulk collect into l_files 
   from   gt_directory_list
   where  upper(substr(filename,-3))='RDB' 
      and last_modified >= p_date;
       
   dbms_output.put_line('files in table='||l_files.count);
   
   for i in l_files.first .. l_files.last loop
      dbms_output.put_line(l_files(i));
      l_cwms_id := substr(l_files(i),1,instr(l_files(i),'.')-1);
      cwms_rating.load_rdb_file('RDBFILES',l_files(i),l_cwms_id);   
   end loop;
      
exception when others then
   -- ORA-06502: PL/SQL: numeric or value error: character string buffer too small       
   -- ORA-01403: no data found  
   --cwms_err.raise('unit_conv_not_found',l_key);
   dbms_output.put_line(SQLERRM);

end load_rdb_files;


procedure load_rdb_file ( 
   p_dir        in   varchar2,               -- directory object name  
   p_file       in   varchar2,               -- an rdb filename 
   p_loc        in   varchar2,               -- base location id associated w/the rating table  
   p_active     in   char     := null,       -- activate flag ("T","F" or null)  
   p_max_y_diff in   number   := 0.0001,     -- max acceptable y diff is y times this number 
   p_max_y_errs in   integer  := 0,          -- max y errors before aborting the load 
   p_office     in   varchar2 default null   -- db office id                              
   ) is   

   l_sql         varchar2(80);
   l_source      at_rating.source%type;
   l_type        cwms_rating_type.rating_type_id%type;
   l_desc        at_rating_loc.description%type;
   l_loc         varchar2(16);
   l_loc_code    integer;
   l_base        varchar2(18);
   l_base_date   date;
   l_shift       varchar2(18);
   l_shift_date  date;
   l_msg         varchar2(256);
   l_spec_code   at_rating_spec.rating_spec_code%type;
   l_rating_id   at_rating_spec.version%type;
   l_version     at_rating_spec.version%type;
   l_base_active at_rating_spec.active_flag%type;
   l_curve_code  at_rating_curve.rating_curve_code%type;
   l_parm_num    at_rating_curve.indep_parm_number%type;
   l_parm_val    at_rating_curve.indep_parm_value%type;
   l_shift_code  at_rating_shift_spec.rating_shift_code%type;
   

   
   type         curve_type is table of at_rating_value%rowtype       index by pls_integer;
   type         rdb_type   is table of et_rdb_value%rowtype          index by pls_integer;
   curve        curve_type;  -- current base values     
   rdb          rdb_type;    -- rdb table array 

   type         curve_nt_type is table of at_rating_value%rowtype;   
   type         shift_nt_type is table of at_rating_shift_value%rowtype;   
   new_nt       curve_nt_type;  -- new base values 
   shift_nt     shift_nt_type;  -- new shift values 
   last_shift   number;
   next_i       boolean;

   i            pls_integer; -- pointer for rdb 
   j            pls_integer; -- pointer for curve 
   n            pls_integer; -- pointer for new 
   s            pls_integer; -- counter for shifts 
   same         pls_integer; -- counter for same (x,y) values 
   diff         number;      -- difference between current and new values 
   small_diff   constant number := 0.0001; -- used when comparing x values for equality 
   l_x_diff     number;      -- largest difference in similar x values 
   l_y_diff     pls_integer; -- largest difference in y values for similar x values 
   l_y_pct      number;      -- l_y_diff expressed as a percent 
   l_max_y_diff number;      -- max acceptable y diff is y times this number 
   l_max_y_errs pls_integer; -- max y errors before aborting the load 
   l_y_errs     pls_integer; -- counter where y diff > y * l_max_y_diff 


begin

   -- Load a USGS RDB formatted rating table into the database 


   -- Handle NULL parameters 


   l_max_y_diff := abs(nvl(p_max_y_diff,0.0001));
   l_max_y_errs := nvl(p_max_y_errs,0);


   -- Point the external tables to p_file 
  

   l_sql := 'alter table et_rdb_comment location('||p_dir||':'''||p_file||''')';
 
   execute immediate l_sql; 
   
   l_sql := 'alter table et_rdb_value location('||p_dir||':'''||p_file||''')';
 
   execute immediate l_sql; 


   -- Load the rdb file comments into the package global array  
   
   
   select line bulk collect into g_lines from et_rdb_comment;

   -- dbms_output.put_line(g_lines(17));
   -- dbms_output.put_line(g_lines.count||'comment lines');
   -- dbms_output.put_line('RETRIEVED='||get_comment('RETRIEVED'));
   -- dbms_output.put_line('STATION AGENCY='||get_comment('STATION AGENCY'));
   -- dbms_output.put_line('STATION NAME='||get_comment('STATION NAME'));
   -- dbms_output.put_line('NUMBER='||get_comment('" NUMBER'));
   -- dbms_output.put_line('RATING SHIFTED='||get_comment('RATING SHIFTED'));
   -- dbms_output.put_line('RATING ID='||get_comment('RATING ID'));
   -- dbms_output.put_line('TYPE='||get_comment('" TYPE'));
   -- dbms_output.put_line('DST_FLAG='||get_comment('DST_FLAG'));
   -- dbms_output.put_line('RATING_DATETIME BEGIN='||get_comment('RATING_DATETIME BEGIN',null,'T'));
   -- dbms_output.put_line('RATING_DATETIME BEGIN='||get_comment('RATING_DATETIME BEGIN',2,'T'));


   -- Get the loc_rating_code 


   -- Note: The location name could come from 3 sources (I'm using #3)  
   --    1. a parameter 
   --    2. the usgs station number and the alias schema   
   --    3. the filename (that's what we do)  

   -- Was doing #3 but changed to #1 
   -- l_loc    := substr(p_file,1,instr(p_file,'.')-1); 

   l_source := get_comment('STATION AGENCY');
   l_type   := get_comment('" TYPE');
   l_loc    := p_loc;

   begin
      l_loc_code := get_loc_code (l_source,l_type,l_loc,p_office);
      
   exception when no_data_found then
      -- ORA-06503: PL/SQL: Function returned without value 
   
      -- Add the location   
      -- Assume that the rating family and the CWMS location exist 
        
      l_msg := 'cwms_rating.load_rdb_file: Adding location; Source='||l_source
               ||', Type='||l_type||', Location='||l_loc;      
      
      dbms_output.put_line(l_msg); 
      
      l_desc     := get_comment('STATION NAME')||' ('||get_comment('" NUMBER')||')'; 
      l_loc_code := add_location (l_source,l_type,l_loc,null,null,p_file,l_desc); 
        
   end; 

    
   -- Get the version & effective dates (in UTC) for the base table and shift  

   
   l_rating_id  := get_comment('RATING ID'); 
   l_shift      := get_comment('RATING SHIFTED');
   l_msg        := get_comment('RATING_DATETIME BEGIN',1,'T');  -- 1st occur, full line 
   l_base       := substr(l_msg,27,15)||substr(l_msg,48,3);

   l_shift_date := get_date(l_shift,'GMT');
   l_base_date  := get_date(l_base, 'GMT');
   
   dbms_output.put_line('base date ='||to_char(l_base_date, 'dd-MON-yyyy hh24:mi:ss'));
   dbms_output.put_line('shift date='||to_char(l_shift_date,'dd-MON-yyyy hh24:mi:ss'));

   if l_base_date > l_shift_date then
      dbms_output.put_line('cwms_rating.load_rdb_file: SHIFTED date is older '
         ||'than the BEGIN date; File='||p_file);
   end if;
      

   -- Does the rating table specification exist?  


   begin

      select rating_spec_code, version, active_flag
      into   l_spec_code, l_version, l_base_active
      from   at_rating_spec
      where  rating_loc_code = l_loc_code
        and  effective_date  = l_base_date;
   
   exception when no_data_found then
 
      -- No, add it  
           
      l_msg := 'cwms_rating.load_rdb_file: Adding rating table specification; ' 
               ||'Location='||l_loc||', Effective Date='
               ||to_char(l_base_date,'dd-Mon-yyyy hh24:mi:ss')||' UTC';
               
      dbms_output.put_line(l_msg);

      -- get_loc_code doesn't return the auto_active_flag 
      
      select upper(nvl(p_active,auto_active_flag)) 
      into   l_base_active
      from   at_rating_loc
      where  rating_loc_code = l_loc_code;      
           
      insert into at_rating_spec 
      (rating_spec_code, rating_loc_code, effective_date, create_date, version, active_flag) 
      values (cwms_seq.nextval, l_loc_code, l_base_date, sysdate, l_rating_id, l_base_active)
      returning rating_spec_code, version into l_spec_code, l_version;

      dbms_output.put_line(to_char(sql%rowcount)||' row inserted into at_rating_spec');    
 
   end;     
                   
   dbms_output.put_line('rating_spec_code ='||l_spec_code);

      
   -- Note: It appears we need a way to get the meta-data out of the tables 
   --       Perhaps a record or a cursor? 
   --
   -- Note: Will also need to do unit conversion, but for now it will be easier 
   --       to test w/o it. 
   
   
   -- Does the rating curve exit? 
   
   
   begin

      select rating_curve_code, indep_parm_number, indep_parm_value
      into   l_curve_code, l_parm_num, l_parm_val
      from   at_rating_curve
      where  rating_spec_code = l_spec_code;
   
   exception when no_data_found then
 
      -- This appears to be a new base curve 
      -- Add it to the curve table      

      insert into at_rating_curve
      (rating_curve_code, rating_spec_code, indep_parm_number)
      values (cwms_seq.nextval, l_spec_code, 1)
      returning rating_curve_code into l_curve_code;      

      dbms_output.put_line(to_char(sql%rowcount)||' row inserted into at_rating_curve');

      if sql%rowcount=0 then 
         l_msg := 'cwms_rating.load_rdb_file failed for file: '||p_file;
         raise_application_error (-20999,l_msg);
       end if;       

      when others then dbms_output.put_line(SQLERRM); raise;   
   end;        
              
   dbms_output.put_line('rating_curve_code ='||l_curve_code);
  

   -- I'm going to use nested tables here for compatibility with the general 
   -- add_rating procedure which will accept an array of values. This appears 
   -- to be consistent with implementation of passing an array of records as
   -- implemented in cwms_ts.store_ts.
   --
   -- I could also have used sql to do most of the following, the array 
   -- method appears to be more efficient and could easily make an "almost 
   -- equal" join between independent values in the rdb file and the existing 
   -- curve.  
   --
   -- It would also be possible to process a set of rating tables using sql 
   -- but I considered process logging and reporting more important in this 
   -- application than performance.
   
   
   -- Get the rating values from the rdb file    


   select x+shift, shift, y, stor bulk collect into rdb 
   from   et_rdb_value;
   
   
   -- Get the rating values for the base curve from the db     


   select * bulk collect into curve from at_rating_value 
   where  rating_curve_code = l_curve_code; 

   dbms_output.put_line(to_char(rdb.count)||' values in '||p_file);
   dbms_output.put_line(to_char(curve.count)||' values in current base curve');

   -- NOTE: May need to consider rounding done by the USGS when comparing Stages 
   
   i := 1;        -- rdb array index 
   j := 1;        -- base curve array index 
   same := 0;     -- counts x values that are the same in rdb and stored curve 
   l_x_diff := 0; -- largest difference in x values that are similar 
   l_y_diff := 0; -- largest difference in y values for similar x values  
   l_y_pct  := 0; -- l_y_diff expressed as a percent 
   l_y_errs := 0; -- counts y value "errors" (diff in y values exceeds y*p_max_y_diff) 

   new_nt     := curve_nt_type();  -- initialize the nested table to empty  
   shift_nt   := shift_nt_type();  -- initialize the nested table to empty   
   next_i     := FALSE; 
   
   -- Note: next assignment will raise no_data_found if rdb is empty   
   
   last_shift := rdb(1).shift;  

   loop
      --dbms_output.put_line('i,j,same='||i||', '||j||', '||same); 
      
      exit when  i > rdb.count;             -- processed all rdb values? 

      if (rdb(i).shift != last_shift) then  -- new shift? 
         shift_nt.extend;                   -- yes, save the shift 
         s := shift_nt.count;               -- and expanded x value 
         shift_nt(s).stage := rdb(i-1).x - last_shift;
         shift_nt(s).shift := last_shift;
         last_shift := rdb(i).shift;
      end if;

       
      if j <= curve.count then              -- current values left to process? 
         diff := rdb(i).x - curve(j).x;     -- yes, continue comparing curves  
      else                                  -- no, this value will cause "diff < 0"  
         diff := -small_diff;               -- to add the value 
      end if;
      
      if abs(diff) < small_diff then        -- similar x values?    
                                            -- yes 
         l_x_diff := greatest(diff,abs(l_x_diff));  -- save max x diff    
         diff     := abs(rdb(i).y - curve(j).y);    -- get y diff  
         l_y_diff := greatest(diff,l_y_diff);       -- save max y diff 
         l_y_pct  := greatest(l_y_pct,100*diff/curve(j).y);

         if diff < l_max_y_diff * curve(j).y then   -- y diff within limit?   
            same   := same + 1;                     -- yes 
         else                                       -- no   
            l_y_errs := l_y_errs + 1;               -- abort after p_max_y_errors            
            if l_y_errs <= l_max_y_errs then
               l_msg := 'y values differ: rdb=('||rdb(i).x||', '||rdb(i).y
                        ||'), curve=('||curve(j).x||', '||curve(j).y||')';
               dbms_output.put_line(l_msg);
            else 
               l_msg := 'load_rdb_file: Warning! Base curves appear different; File='
                        ||trim(p_file)||', Location='||l_loc||', Effective Date='
                        ||to_char(l_base_date,'dd-Mon-yyyy hh24:mi:ss')||' UTC';
                  raise_application_error (-20999,l_msg);
            end if;               
         end if;

         next_i := TRUE;
         j := j+1;

      elsif diff < 0 then                   -- no, rdb is less, add and try next one  
         
         new_nt.extend;
         n := new_nt.count;
         new_nt(n).rating_curve_code := l_curve_code;
         new_nt(n).x    := rdb(i).x;
         new_nt(n).y    := rdb(i).y;
         new_nt(n).stor := rdb(i).stor;

         if n<10 then dbms_output.put_line('new base stage for '||rdb(i).x); end if;
         if n=10 then dbms_output.put_line('more than 10 stages to add ...'); end if;

         next_i := TRUE;
                  
      elsif diff > 0 then                   -- no, curve is less, try next one  
          
         dbms_output.put_line('no base stage in new curve for '||curve(j).x);
         j := j+1;
         
      end if;

      if next_i then                        -- increment i until x values differ 
         loop 
            i := i + 1;
            exit when i> rdb.count;
            exit when rdb(i).x != rdb(i-1).x;  -- new x? then exit 
            if rdb(i).y != rdb(i-1).y then     -- same x, different y? 
               l_msg := 'duplicate x values but y values differ: rdb('||i-1||') x,y='||rdb(i-1).x||','
                        ||rdb(i-1).y||', rdb('||i||') x,y='||rdb(i).x||','||rdb(i).y;
               dbms_output.put_line(l_msg);            
            end if; 
         end loop;
         next_i := FALSE;
      end if;              
         
   end loop;   


   -- No shifts? Add a zero shift  
   -- Ended with a non-zero shift? Add the last shift    


   if shift_nt.count=0 or last_shift!=0 then
      shift_nt.extend;
      s := shift_nt.count;
      shift_nt(s).stage := rdb(i-1).x - last_shift;
      shift_nt(s).shift := last_shift;  
   end if;   

   
   -- Statistics 

   
   l_msg := same||' values compared. Max X diff='||l_x_diff||', Max Y diff='
                ||l_y_diff||' ('||to_char(l_y_pct,'90.90')||'%), '
                ||l_y_errs||' Y values exceeding'
                ||to_char(l_max_y_diff*100,'90.90')||'%';
                
   dbms_output.put_line(l_msg);
   dbms_output.put_line(new_nt.count||' values to add');
   dbms_output.put_line(shift_nt.count||' shifts to add');

   if new_nt.count > 0 then
      for i in new_nt.first..least(10,new_nt.last) loop
         if n<10 then dbms_output.put_line('new base stage for '||new_nt(i).x); end if;
         if n=10 then dbms_output.put_line('more new base stage ...'); end if;
      end loop;
   end if;
   
   if shift_nt.count > 0 then
      for i in shift_nt.first..shift_nt.last loop
         dbms_output.put_line('stage='||shift_nt(i).stage||', shift='||shift_nt(i).shift);
      end loop;
   end if;


   -- Store base table values 

   
   if new_nt.count > 0 then 

      forall i in new_nt.first..new_nt.last
      insert into at_rating_value
      values new_nt(i);

      dbms_output.put_line(sql%rowcount||' rows inserted into at_rating_value');   

   end if; 


   -- Store shifts 


   if shift_nt.count > 0 then
   
      -- Add the shift specification  
   
      begin

         insert into at_rating_shift_spec
         values (cwms_seq.nextval, l_spec_code, l_shift_date, l_base_active, 'F')
         returning rating_shift_code into l_shift_code;      

         dbms_output.put_line(sql%rowcount||' row inserted into at_rating_shift_spec');

         if sql%rowcount !=1 then 
            l_msg := 'cwms_rating.load_rdb_file: Error adding shift spec, '
                     ||'sql%rowcount='||sql%rowcount;
            raise_application_error (-20999,l_msg);
          end if;       

      exception 
         when dup_val_on_index then  -- a shift already exists at this time 

            l_msg := 'cwms_rating.load_rdb_file: Shift already exists; File='
                    ||trim(p_file)||', Location='||l_loc||', Effective Date='
                    ||to_char(l_base_date,'dd-Mon-yyyy hh24:mi:ss')||' UTC';
                     
            raise_application_error (-20999,l_msg);
      end;        
              
      dbms_output.put_line('rating_shift_code ='||l_shift_code);

      -- Add the shift values 

      for i in shift_nt.first..shift_nt.last loop
         shift_nt(i).rating_shift_code := l_shift_code;
      end loop;
      
      forall i in shift_nt.first..shift_nt.last
      insert into at_rating_shift_value
      values shift_nt(i);

      dbms_output.put_line(sql%rowcount||' rows inserted into at_rating_shift_value');      

   end if;

    
exception when others then
   -- ORA-00001: unique constraint (CWMS.AT_RATING_SHIFT_SPEC_AK1) violated 
   -- ORA-01403: no data found  
   -- ORA-06502: PL/SQL: numeric or value error: character string buffer too small       
   dbms_output.put_line(SQLERRM);
   --cwms_err.raise('unit_conv_not_found',l_key);
   raise;
   
end load_rdb_file;


procedure rate_value ( 
   p_loc_code   in   integer,                -- rating_loc_code for the rating family and location    
   p_date_time  in   date,                   -- timestamp for value   
   p_value      in   binary_double,          -- value to rate 
   p_rated      out  binary_double           -- rated value     
   ) is
  
begin

   -- Get the base stage 
/*
      select max(shift) keep (dense_rank first order by stage) shift
        into y  
        from   at_rating_shift_value 
       where  rating_shift_code=sn and stage >= val;


      select * into xy from (   
      select x,y,lead(x) over(order by x) x2, lead(y) over(order by x) y2 from (
      select x, y from at_rating_value where rating_curve_code=cn 
         and x>= (select max(x) from at_rating_value where rating_curve_code=cn and x < val)
      ) where rownum<3
      ) where rownum=1;

*/

   null; 

exception when others then
   dbms_output.put_line(SQLERRM);
   raise;
   
end rate_value;  


-- Package Initialization Follows 

begin
   null;
end cwms_rating;
/
