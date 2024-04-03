create or replace package         runstats
as
   -- AUTOTRACE types

   type rec_t      is record (stat# number, name varchar2(40), value number);
   type rec_tab    is table of rec_t   index by pls_integer;
   type rec_tab_t  is table of rec_tab index by pls_integer;
   type num_t      is table of number  index by pls_integer;

   -- AUTOTRACE public global variables

   g_output_none       constant integer := 0; -- no output
   g_output_error      constant integer := 1; -- only output errors
   g_output_warning    constant integer := 2; -- also output warnings
   g_output_trace      constant integer := 3; -- also output operations
   g_output_call_stack constant integer := 4; -- also output call stack

   -- AUTOTRACE procedures

   procedure at_start      ( p_n          in number default 1,
                             p_paused     in varchar2 default 'F');

   procedure at_pause      ( p_n          in number default 1 );

   procedure at_resume     ( p_n          in number default 1 );

   procedure at_stop       ( p_lbl        in varchar2 default ' ',
                             p_n          in number   default 1,
                             p_threshold  in number   default 0 );

   procedure at_set_output ( p_level      in integer);

   function at_get_names   ( p_n          in number   default 1)
      return str_tab_t;

   function at_get_value   ( p_n          in number,
                             p_name       in varchar2 )
      return number;


   -- RUNSTATS procedures

   procedure rs_start;

   procedure rs_middle;

   procedure rs_stop  ( p_lbl        in varchar2 default ' ',
                        p_threshold  in number   default 1 );

   -- helper function called by SQL

   function ratio (p_r1 in number, p_r2 in number) return number;

end runstats;
/

