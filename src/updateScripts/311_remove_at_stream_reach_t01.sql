-----------------------------------------------------------------------
-- this should have been done in updating to 3.0.7, but got left out --
-----------------------------------------------------------------------
declare
   no_such_trigger exception;
   pragma exception_init(no_such_trigger, -04080);
begin
   execute immediate 'drop trigger at_stream_reach_t01';
   commit;
exception
   when no_such_trigger then null;
end;
/

