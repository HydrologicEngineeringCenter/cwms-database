create global temporary table run_stats(
   runid varchar2(15), 
   name  varchar2(80), 
   value number(*,0)
) on commit preserve rows;
