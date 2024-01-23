CREATE OR REPLACE package body cwms_err
is
   procedure raise (
      p_err in varchar2,               -- exception name in cwms_error table
      p_1   in varchar2 default null,  -- optional substitution value for %1  
      p_2   in varchar2 default null,  -- optional substitution value for %2  
      p_3   in varchar2 default null,  -- optional substitution value for %3  
      p_4   in varchar2 default null,  -- optional substitution value for %4  
      p_5   in varchar2 default null,  -- optional substitution value for %5  
      p_6   in varchar2 default null,  -- optional substitution value for %6  
      p_7   in varchar2 default null,  -- optional substitution value for %7  
      p_8   in varchar2 default null,  -- optional substitution value for %8  
      p_9   in varchar2 default null   -- optional substitution value for %9 
      ) is
      l_code  number;
      l_errm  varchar2(32767);
   begin
      -- raise user-defined exception p_err
      -- substitute optional values p_1 - p_9 in the error message for %n
      -- add the exception to the error stack  
   
      begin
         select err_code, err_name||': '||err_msg into l_code, l_errm
         from cwms_error where err_name=upper(p_err);

      exception when NO_DATA_FOUND then
         l_code := -20999;
         l_errm := 'UNKNOWN_EXCEPTION: The requested exception not in the CWMS_ERROR table: "'||p_err||'"';
      end;
      
      -- The error message could contain %1 and %2 but p_1 is null. %2 should still be replaced with p_2.
      -- Only look for %n if message contained %n-1

      if instr(l_errm, '%1') != 0 then
           if p_1 is not null then
               l_errm := replace(l_errm, '%1', p_1);
           end if;
           if instr(l_errm, '%2') != 0 then
               if p_2 is not null then
                   l_errm := replace(l_errm, '%2', p_2);
               end if;
               if instr(l_errm, '%3') != 0 then
                   if p_3 is not null then
                       l_errm := replace(l_errm, '%3', p_3);
                   end if;
                   if instr(l_errm, '%4') != 0 then
                       if p_4 is not null then
                           l_errm := replace(l_errm, '%4', p_4);
                       end if;
                       if instr(l_errm, '%5') != 0 then
                           if p_5 is not null then
                               l_errm := replace(l_errm, '%5', p_5);
                           end if;
                           if instr(l_errm, '%6') != 0 then
                               if p_6 is not null then
                                   l_errm := replace(l_errm, '%6', p_6);
                               end if;
                               if instr(l_errm, '%7') != 0 then
                                   if p_7 is not null then
                                       l_errm := replace(l_errm, '%7', p_7);
                                   end if;
                                   if instr(l_errm, '%8') != 0 then
                                       if p_8 is not null then
                                           l_errm := replace(l_errm, '%8', p_8);
                                       end if;
                                       if instr(l_errm, '%9') != 0 then
                                           if p_9 is not null then
                                               l_errm := replace(l_errm, '%9', p_9);
                                           end if;
                                       end if;
                                   end if;
                               end if;
                           end if;
                       end if;
                   end if;
               end if;
           end if;
       end if;

      raise_application_error(l_code, l_errm, TRUE);

   end raise;

end;
/
