create or replace package         runstats
as
   -- AUTOTRACE types

   type rec_t      is record (stat# number, name varchar2(40), value number);
   type rec_tab    is table of rec_t   index by pls_integer;
   type rec_tab_t  is table of rec_tab index by pls_integer;
   type num_t      is table of number  index by pls_integer;

   -- AUTOTRACE global variables
   --
   -- Note package global variables start with "g" to differentiate their scope
   --      from procedure local variables which start with "l".


   g_waiting constant integer := 0;
   g_started constant integer := 1;
   g_paused  constant integer := 2;
   g_resumed constant integer := 3;

   g_rec        rec_tab;   -- Statistics numbers, names and values
   g_rec2       rec_tab_t; -- Table of start statistics values
   g_rec3       rec_tab_t; -- Table of stop statistics values
   g_acc        rec_tab_t; -- Table of accumulated statistics values
   g_times      num_t;     -- Start times
   g_times2     num_t;     -- accumulated times
   g_at_status  num_t;     -- statuses
   g_at_resumes num_t;

   -- AUTOTRACE procedures

   procedure at_start    ( p_n          in number default 1,
                           p_paused     in varchar2 default 'F');

   procedure at_pause    ( p_n          in number default 1 );

   procedure at_resume   ( p_n          in number default 1 );

   procedure at_stop     ( p_lbl        in varchar2 default ' ',
                           p_n          in number   default 1,
                           p_threshold  in number   default 0 );

   function at_get_names ( p_n          in number   default 1)
      return str_tab_t;

   function at_get_value ( p_n          in number default 1,
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

