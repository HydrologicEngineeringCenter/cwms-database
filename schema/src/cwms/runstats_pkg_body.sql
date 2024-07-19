create or replace package body         runstats
as
   -- RUNSTATS global variables

   g_start  number;
   g_run1   number;
   g_run2   number;
   g_middle boolean := FALSE;

   -- AUTOTRACE global variables
   --
   -- Note package global variables start with "g" to differentiate their scope
   --      from procedure local variables which start with "l".

   g_waiting           constant integer := 0;
   g_started           constant integer := 1;
   g_paused            constant integer := 2;
   g_resumed           constant integer := 3;

   g_rec        rec_tab;   -- Statistics numbers, names and values
   g_rec2       rec_tab_t; -- Table of start statistics values
   g_rec3       rec_tab_t; -- Table of stop statistics values
   g_acc        rec_tab_t; -- Table of accumulated statistics values
   g_times      num_t;     -- Start times
   g_times2     num_t;     -- accumulated times
   g_at_status  num_t;     -- statuses
   g_at_resumes num_t;
   g_at_output  integer := g_output_warning;

   procedure rs_start
   is
   begin
       delete from run_stats;

       insert into run_stats
       select 'before', stats.* from stats;

       g_start  := dbms_utility.get_time;
       g_middle := FALSE;

   end rs_start;

   procedure rs_middle
   is
   begin
       g_run1 := (dbms_utility.get_time - g_start);

       insert into run_stats
       select 'after 1', stats.* from stats;

       g_start  := dbms_utility.get_time;
       g_middle := TRUE;

   end rs_middle;

   function ratio (p_r1 in number, p_r2 in number) return number
   is
   begin
      return case when p_r2 >= p_r1 then  p_r2 / greatest(p_r1,1)
             else                        -p_r1 / greatest(p_r2,1)
             end;
   end ratio;

   function format_stat2 ( p_name  in varchar2,
                           p_r1    in  number,
                           p_r2    in  number,
                           p_ratio in  number )
   return varchar2
   is
   begin
      return rpad( p_name, 50 ) ||
             to_char( p_r1,              '999,999,999' ) ||
             to_char( p_r2,              '999,999,999' ) ||
             to_char( p_r2 - p_r1,       '999,999,999' ) ||
             to_char( round(p_ratio,1),  '9,999,990.0' );

   end format_stat2;

   procedure print_stat2 ( p_lbl in varchar2, p_stat in varchar2 )
   is
     l_name  varchar2(64);
     l_r1    number;
     l_r2    number;
     l_ratio number;
   begin
     -- Print run1 and run2 statistics for p_stat
     -- Used by runstat Summary

      select a.name, b.value-a.value, c.value-b.value
      into   l_name, l_r1, l_r2
      from   run_stats a, run_stats b, run_stats c
      where  a.name = b.name
         and b.name = c.name
         and a.runid = 'before'
         and b.runid = 'after 1'
         and c.runid = 'after 2'
         and lower(a.name) like p_stat
         and rownum < 2;

      dbms_output.put_line ( p_lbl || format_stat2 (l_name, l_r1, l_r2, ratio(l_r1,l_r2)) );

   exception when others then
     dbms_output.put_line(sqlerrm);
   end print_stat2;

   procedure print_stat ( p_lbl in varchar2, p_stat in varchar2 )
   is
     l_diff number;
     l_stat varchar2(120);
   begin
     -- Print single (run1) statistic when no middle
     -- Used by run1 Summary

     select b.value-a.value, to_char(b.value-a.value, '999999999') || ' ' || a.name
       into l_diff, l_stat
       from run_stats a, run_stats b
      where a.name = b.name
        and a.runid = 'before'
        and b.runid = 'after 1'
        and lower(a.name) like p_stat
        and rownum<2;

      if l_diff > 0 then dbms_output.put_line (p_lbl || l_stat); end if;

   exception when others then
     dbms_output.put_line(sqlerrm);
   end print_stat;

   procedure rs_stop
   ( p_lbl        in varchar2 default ' ',
     p_threshold  in number   default 1
   )
   is
      l_lbl varchar2(10);
      l_h1  varchar2(10);
      l_h2  varchar2(10);
   begin
      g_run2 := (dbms_utility.get_time - g_start);

      insert into run_stats
      select 'after 2', stats.* from stats;

      if NOT g_middle then
         -- No middle call
         -- Report only on first run
         -- Store middle statistics

         rs_middle;

         -- Main Statistics Loop

         l_lbl := case when p_lbl is null then '' else rpad(p_lbl,10) end;

         dbms_output.put_line (' ');

         for rec in ( select a.name, b.value-a.value r1
                        from run_stats a, run_stats b
                       where a.name  = b.name
                         and a.runid = 'before'
                         and b.runid = 'after 1'
                         and b.value-a.value >= p_threshold
                       order by abs(b.value-a.value), 1 )
         loop
           dbms_output.put_line ( l_lbl || to_char(rec.r1, '999999999')||' '||rec.name );
         end loop;

         -- Summary

         dbms_output.put_line (' ');
         dbms_output.put_line ( l_lbl ||to_char( round((g_run1)/100,2),'999990.99' )||' elapsed time (sec)' );

         print_stat (l_lbl, '%recursive calls%');
         print_stat (l_lbl, '%opened cursors cumulative%');
         print_stat (l_lbl, '%execute count%');
         print_stat (l_lbl, '%consistent gets%');

         -- SUM(Latches)

         for rec in ( select sum(b.value-a.value) r1
                        from run_stats a, run_stats b
                       where a.name  = b.name
                         and a.runid = 'before'
                         and b.runid = 'after 1'
                         and a.name like 'LATCH%' )
         loop
            dbms_output.put_line ( l_lbl || to_char(rec.r1, '999999999') || ' LATCH..Total Latches' );
         end loop;

         -- other Summary Statistics

         print_stat (l_lbl, '%result cache: rc latch');
         print_stat (l_lbl, '%.enqueue hash chains');
         print_stat (l_lbl, '%cache buffers chains%');
         print_stat (l_lbl, '%shared pool%');
         print_stat (l_lbl, '%physical read bytes%');
         print_stat (l_lbl, '%index range scans%');
         print_stat (l_lbl, '%index fetch by key%');
         print_stat (l_lbl, '%table fetch by rowid%');
         print_stat (l_lbl, '%table scans (short tables)%');
         print_stat (l_lbl, '%table scan blocks gotten%');
         print_stat (l_lbl, '%sorts (memory)%');
         print_stat (l_lbl, '%sorts (disk)%');
         print_stat (l_lbl, '%sorts (rows)%');
         print_stat (l_lbl, '%user commits%');

         return;
      end if;


       -- Main Statistics Loop
       -- This is a comparison between run1 and run2

       dbms_output.put_line
       ( rpad( 'Name', 50 ) || lpad( 'Run1', 12 ) || lpad( 'Run2', 12 ) ||
         lpad( 'Diff', 12 ) || lpad( 'Ratio', 12 ));

       for x in
       ( select * from
          ( select name, r1, r2, r2-r1 diff, ratio(r1, r2) ratio
            from   ( select a.name, b.value-a.value r1, c.value-b.value r2
                     from   run_stats a, run_stats b, run_stats c
                     where  a.name  = b.name
                        and b.name  = c.name
                        and a.runid = 'before'
                        and b.runid = 'after 1'
                        and c.runid = 'after 2'
                        --and c.value-a.value <> 0
                   )
            )
         where  abs( ratio ) > p_threshold
         order  by abs( ratio )
       )
       loop
         dbms_output.put_line( l_lbl || format_stat2 (x.name, x.r1, x.r2, x.ratio) );
       end loop;

       -- Summary

       -- Include the non-null label in front of every summary line

       l_lbl := case when p_lbl is null then '' else rpad(p_lbl,10) end;
       l_h1  := case when p_lbl is null then '' else rpad('Label',10) end;
       l_h2  := case when p_lbl is null then '' else '--------  ' end;

       dbms_output.put_line( chr(9) );
       dbms_output.put_line
       ( l_h1 ||
         rpad('Summary',50) ||
         lpad( 'Run1', 12 ) || lpad( 'Run2',  12 ) ||
         lpad( 'Diff', 12 ) || lpad( 'Ratio', 12 ) );
       dbms_output.put_line( l_h2||
         lpad('  ',50,'-') || replace('xxxx','x','  ----------') );

       -- Run Time

       dbms_output.put_line ( l_lbl || format_stat2 ('Run Time (hsec)', g_run1, g_run2, ratio(g_run1,g_run2)) );

       print_stat2 (l_lbl, '%recursive calls%' );
       print_stat2 (l_lbl, '%opened cursors cumulative%' );
       print_stat2 (l_lbl, '%execute count%' );
       print_stat2 (l_lbl, '%consistent gets%' );

       -- SUM(Latches)

       for x in
       ( select l_lbl ||
                rpad('Total Latches  ',50) ||
                to_char( r1,   '999,999,999' ) ||
                to_char( r2,   '999,999,999' ) ||
                to_char( diff, '999,999,999' ) ||
                to_char( round(ratio(r1,r2),1),  '9,999,990.0' ) data
           from ( select sum(b.value-a.value) r1, sum(c.value-b.value) r2,
                         sum( (c.value-b.value)-(b.value-a.value)) diff
                    from run_stats a, run_stats b, run_stats c
                   where a.name = b.name
                     and b.name = c.name
                     and a.runid = 'before'
                     and b.runid = 'after 1'
                     and c.runid = 'after 2'
                     and a.name like 'LATCH%'
                   )
       ) loop
           dbms_output.put_line( x.data );
       end loop;

       -- other Summary Statistics

       print_stat2 (l_lbl, '%result cache: rc latch' );
       print_stat2 (l_lbl, '%.enqueue hash chains' );
       print_stat2 (l_lbl, '%cache buffers chains%' );
       print_stat2 (l_lbl, '%shared pool%' );
       print_stat2 (l_lbl, '%physical read bytes%' );
       print_stat2 (l_lbl, '%index range scans%' );
       print_stat2 (l_lbl, '%index fetch by key%' );
       print_stat2 (l_lbl, '%table fetch by rowid%' );
       print_stat2 (l_lbl, '%table scans (short tables)%' );
       print_stat2 (l_lbl, '%table scan blocks gotten%' );
       print_stat2 (l_lbl, '%sorts (memory)%' );
       print_stat2 (l_lbl, '%sorts (disk)%' );
       print_stat2 (l_lbl, '%sorts (rows)%' );
       print_stat2 (l_lbl, '%user commits%' );

   end rs_stop;

   procedure output_call_stack is
      l_call_stack str_tab_tab_t := cwms_util.get_call_stack;
   begin
      dbms_output.put_line('RUNSTATS: Call stack:');
      for i in 3..l_call_stack.count loop
         dbms_output.put_line(to_char(i-2, '999')||' : '||l_call_stack(i)(1)||':'||l_call_stack(i)(2));
      end loop;
   end output_call_stack;
   
   procedure at_adjust_rc is
      i    number;     -- for itterating over the collection
   begin
      -- Bump AUTOTRACE recursive calls count up by 1
      i := g_rec2.first;
      while i is not null loop
            --dbms_output.put_line ( 'start: i='||i||', rc='||g_rec2(i)(1).value);
            g_rec2(i)(1).value := g_rec2(i)(1).value + 1;
            i := g_rec2.next(i);
      end loop;
   end at_adjust_rc;

   procedure at_start    ( p_n          in number default 1,
                           p_paused     in varchar2 default 'F')
   is
   begin
      -- Save current AUTOTRACE statistics
      
      if g_at_output >= g_output_trace then
         dbms_output.put_line('RUNSTATS: Starting bucket '||p_n||' (paused = '||p_paused||')');
         if g_at_output = g_output_call_stack then
            output_call_stack;
         end if;   
      end if;   

      if g_at_output >= g_output_warning then
         if g_at_status.exists(p_n) then
            case g_at_status(p_n)
            when g_waiting then
               null;
            when g_started then
               dbms_output.put_line( 'RUNSTATS: Forcing restart of started bucket '||p_n);
            when g_paused then
               dbms_output.put_line( 'RUNSTATS: Forcing restart of paused bucket '||p_n);
            when g_resumed then
               dbms_output.put_line( 'RUNSTATS: Forcing restart of resumed bucket '||p_n);
            end case;
         end if;
      end if;

      select statistic#, name, v.value
      bulk   collect into g_rec2(p_n)
      from   v$mystat v right join table(g_rec) t on (v.statistic# = t.stat#);

      at_adjust_rc;

      g_times(p_n) := to_number(to_char(systimestamp, 'sssss.ff'));  -- microsecond
      g_at_resumes(p_n) := 0;

      select statistic#, name, 0
      bulk   collect into g_acc(p_n)
      from   v$mystat v right join table(g_rec) t on (v.statistic# = t.stat#);

      g_times2(p_n) := 0;

      g_at_status(p_n) := case when p_paused = 'T' then g_paused else g_started end;

   end at_start;

   procedure at_pause ( p_n in number default 1) is
   begin
      -- Accumulate current AUTOTRACE statistics and stop monitoring
      
      if g_at_output >= g_output_trace then
         dbms_output.put_line('RUNSTATS: Pausing bucket '||p_n);
         if g_at_output = g_output_call_stack then
            output_call_stack;
         end if;   
      end if;   

      if g_at_output >= g_output_error then
         if g_at_status.exists(p_n) then
            case g_at_status(p_n)
            when g_waiting then
               dbms_output.put_line ( 'RUNSTATS: Statistics don''t exist for bucket '||p_n);
               return;
            when g_started then
               null;
            when g_paused then
               dbms_output.put_line( 'RUNSTATS: Bucket '||p_n||' was already paused.');
               return;
            when g_resumed then
               null;
            end case;
         else
            dbms_output.put_line ( 'RUNSTATS: Statistics don''t exist for bucket '||p_n);
            return;
         end if;
      end if;

     -- Get current  statistics

      select statistic#, name, v.value
      bulk   collect into g_rec3(p_n)
      from   v$mystat v right join table(g_rec) t on (v.statistic# = t.stat#);

      at_adjust_rc;

      g_times2(p_n) := g_times2(p_n) + to_number(to_char(systimestamp, 'sssss.ff')) - g_times(p_n);

      for i in 1..g_rec3(p_n).count loop
         g_acc(p_n)(i).value := g_acc(p_n)(i).value + g_rec3(p_n)(i).value - g_rec2(p_n)(i).value;
      end loop;

      g_at_status(p_n) := g_paused;
   end at_pause;

   procedure at_resume ( p_n in number default 1) is
   begin
      -- Resume monitoring AUTOTRACE statistics
      
      if g_at_output >= g_output_trace then
         dbms_output.put_line('RUNSTATS: Resuming bucket '||p_n);
         if g_at_output = g_output_call_stack then
            output_call_stack;
         end if;   
      end if;   

      if g_at_output >= g_output_error then
         if g_at_status.exists(p_n) then
            case g_at_status(p_n)
            when g_waiting then
               dbms_output.put_line ( 'RUNSTATS: Statistics don''t exist for bucket '||p_n);
               return;
            when g_started then
               dbms_output.put_line( 'RUNSTATS: Bucket '||p_n||' has not been paused');
               return;
            when g_paused then
               null;
            when g_resumed then
               dbms_output.put_line( 'RUNSTATS: Bucket '||p_n||' has not been paused');
               return;
            end case;
         else
            dbms_output.put_line ( 'RUNSTATS: Statistics don''t exist for bucket '||p_n);
            return;
         end if;
      end if;   

      select statistic#, name, v.value
      bulk   collect into g_rec2(p_n)
      from   v$mystat v right join table(g_rec) t on (v.statistic# = t.stat#);

      at_adjust_rc;

      g_times(p_n) := to_number(to_char(systimestamp, 'sssss.ff'));  -- microsecond
      g_at_resumes(p_n) := g_at_resumes(p_n)  + 1;

      g_at_status(p_n) := g_resumed;

   end at_resume;

   procedure at_stop
      ( p_lbl        in varchar2 default ' ',
        p_n          in number   default 1,
        p_threshold  in number   default 0 )
   is
   begin
      -- Stop monitoring and output accumulated AUTOTRACE statistics
      
      if g_at_output >= g_output_trace then
         dbms_output.put_line('RUNSTATS: Stopping bucket '||p_n);
         if g_at_output = g_output_call_stack then
            output_call_stack;
         end if;   
      end if;   

      if g_at_output >= g_output_error then
         if g_at_status.exists(p_n) then
            case g_at_status(p_n)
            when g_waiting then
               dbms_output.put_line ( 'RUNSTATS: Statistics don''t exist for bucket '||p_n);
               return;
            when g_started then
               at_pause(p_n);
            when g_paused then
               null;
            when g_resumed then
               at_pause(p_n);
            end case;
         else
            dbms_output.put_line ( 'RUNSTATS: Statistics don''t exist for bucket '||p_n);
            return;
         end if;
      end if;   

      dbms_output.put_line (' ');
      dbms_output.put_line ( rpad(p_lbl,9) || to_char( g_times2(p_n),'990.999999' )||' elapsed time (sec)' );

      for i in 1..g_acc(p_n).count loop
         if g_acc(p_n)(i).value >= p_threshold then
            dbms_output.put_line ( rpad(p_lbl,9)||to_char(g_acc(p_n)(i).value, '9999999999')||' '||g_acc(p_n)(i).name );
         end if;
      end loop;
      if g_at_resumes(p_n) > 0 then
         dbms_output.put_line(rpad(p_lbl, 9)||to_char(g_at_resumes(p_n), '9999999999')||' times resumed');
      end if;

      g_at_status(p_n) := g_waiting;

   end at_stop;

   procedure at_set_output ( p_level      in integer)
   is
   begin
      if p_level between g_output_none and g_output_call_stack then
         g_at_output := p_level;
      else
         cwms_err.raise('ERROR', 'P_Level must be in the range of '||g_output_none||'..'||g_output_call_stack);
      end if;
   end at_set_output;

   function at_get_names ( p_n          in number   default 1)
      return str_tab_t
   is
      l_names str_tab_t := str_tab_t();
   begin
      for i in 1..g_acc(p_n).count loop
         l_names.extend;
         l_names(l_names.count) := g_acc(p_n)(i).name;
      end loop;
      return l_names;
   end at_get_names;

   function at_get_value ( p_n          in number,
                           p_name       in varchar2 )
      return number
   is
      l_value number;
   begin
      if instr('elapsed time (sec)', p_name) = 1 then
         l_value := g_times2(p_n);
      else
         for i in 1..g_acc(p_n).count loop
            if g_acc(p_n)(i).name = p_name then
               l_value := g_acc(p_n)(i).value;
               exit;
            end if;
         end loop;
      end if;
      return l_value;
   end at_get_value;

begin
   -- Initialize the AUTOTRACE statistics collection g_rec
   -- Removed: 'CPU used by this session'

   select statistic#, name, null
   bulk   collect into g_rec
   from   v$statname
   where  name in ( 'recursive calls',
                    'db block gets',
                    'consistent gets',
                    'physical reads',
                    'redo size',
                    'SQL*Net roundtrips to/from client',
                    'sorts (memory)',
                    'sorts (disk)',
                    'sorts (rows)'
                  );

end runstats;
/

