CREATE OR REPLACE PACKAGE BODY CWMS_TSV
IS
   one_minute constant NUMBER := 1/1440;

   l_current_date TIMESTAMP;
   l_inserts      NUMBER := 0;
   l_updates      NUMBER := 0;
   l_deletes      NUMBER := 0;
   l_int          INTEGER;

procedure count (p_dml IN number, p_date IN timestamp) is

   -- Increment the posting counters (values/minute).
   -- Save counts in the at_tsv_count table.
   -- p_dml=1 (insert), 2 (update), 3 (delete)

   PRAGMA AUTONOMOUS_TRANSACTION;

      l_current_inserts NUMBER;
      l_current_updates NUMBER;
      l_current_deletes NUMBER;
      l_found           BOOLEAN;
      l_date            TIMESTAMP;

   begin
      -- dbms_output.put_line ('count called with ' || to_date(p_date));
      -- dbms_output.put_line ('l_current_date is ' || to_date(l_current_date));
      -- dbms_output.put_line ('l_inserts=' || l_inserts);
      -- dbms_output.put_line ('l_updates=' || l_updates);
      -- dbms_output.put_line ('l_deletes=' || l_deletes);
      --cwms_20.cwms_utl.log ('tsv_count','l_current_date='||to_char(l_current_date)||p_date='||to_char(l_current_date));

      -- FIX THE TIME ZONE, SHOULD BE 'UTC'
      -- l_date := from_tz(p_date,'US/Pacific') AT TIME ZONE 'UTC';
      l_date := p_date;

      if l_date > l_current_date then

         -- Store the counts for the current minute.

         -- NOTE: MERGE does not lock the row until AFTER evaluating the ON condition.
         --       INSERT's block on the same PK, try it first
         --       SELECT ... FOR UPDATE will lock an existing row

         begin
            insert into at_tsv_count
                   (data_entry_date, inserts, updates, deletes, selects)
            values (l_current_date, l_inserts, l_updates, l_deletes, 0);

         exception
            when DUP_VAL_ON_INDEX then

               select inserts, updates, deletes
               into   l_current_inserts, l_current_updates, l_current_deletes
               from   at_tsv_count
               where  data_entry_date = l_current_date
               for update;

               update at_tsv_count
               set inserts = l_current_inserts + l_inserts,
                   updates = l_current_updates + l_updates,
                   deletes = l_current_deletes + l_deletes,
                   selects = 0
               where data_entry_date = l_current_date;

         end store;

         commit;

         -- truncate l_date after minutes

         l_current_date := trunc(l_date + one_minute,'MI');
         l_inserts := 0;
         l_updates := 0;
         l_deletes := 0;
      end if;

      if p_dml = 1 then
         l_inserts := l_inserts + 1;
      elsif p_dml = 2 then
         l_updates := l_updates + 1;
      elsif p_dml = 3 then
         l_deletes := l_deletes + 1;
      end if;

   exception
      when others then
         l_int:=cwms_msg.log_message (
            p_component   => 'CWMS_TSV',
            p_instance    => NULL,
            p_host        => NULL,
            p_port        => NULL,
            p_reported    => SYSTIMESTAMP AT TIME ZONE 'UTC',
            p_message     => sqlerrm,
            p_msg_level   => cwms_msg.msg_level_normal,
            p_publish     => FALSE,
            p_immediate   => FALSE);
         rollback;

   end count;

BEGIN
   -- Package initialization
   --l_current_date := trunc(SYSTIMESTAMP AT TIME ZONE 'US/Pacific' + one_minute,'MI');
   l_current_date := trunc(SYSTIMESTAMP AT TIME ZONE 'UTC' + one_minute,'MI');

END cwms_tsv;
/

SHOW ERRORS;
COMMIT;
