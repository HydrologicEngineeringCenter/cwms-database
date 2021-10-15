declare
   l_currval         integer;
   l_new_start_value integer;
   l_decrement       integer;
begin
   l_currval := cwms_seq.nextval;
   l_new_start_value := mod(cwms_seq.currval, 1000) + 100;
   l_decrement := -(l_currval - l_new_start_value);
   execute immediate 'alter sequence cwms_seq increment by '||l_decrement;
   l_currval := cwms_seq.nextval;
   execute immediate 'alter sequence cwms_seq increment by 1000';
end;
/
