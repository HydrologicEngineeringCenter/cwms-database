create or replace trigger at_pool_t01
   before insert or update
   of bottom_level, top_level
   on at_pool
   for each row
declare
   l_rec  at_location_level%rowtype;
   l_text varchar2(64);
begin
   -----------------------------
   -- assert different levels --
   -----------------------------
   if :new.bottom_level = :new.top_level then
      cwms_err.raise('ERROR', 'Top and bottom levels cannot be the same');
   end if;
   -----------------------------------------------
   -- validate bottom level is 'Elev.Inst.0...' --
   -----------------------------------------------
   if instr(:new.bottom_level, 'Elev.Inst.0.') != 1 then
      cwms_err.raise('ERROR', 'Bottom location level ID must start with ''Elev.Inst.0''');
   end if;
   --------------------------------------------
   -- validate top level is 'Elev.Inst.0...' --
   --------------------------------------------
   if instr(:new.top_level, 'Elev.Inst.0.') != 1 then
      cwms_err.raise('ERROR', 'Top location level ID must start with ''Elev.Inst.0''');
   end if;
end at_pool_t01;
/