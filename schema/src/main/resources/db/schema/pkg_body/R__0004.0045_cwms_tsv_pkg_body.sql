create or replace PACKAGE BODY cwms_tsv
IS
   one_minute    constant NUMBER := 1/1440;
   STREAM_OFFSET constant number := 3;
   NORMAL_INSERT constant number := DML_INSERT;
   NORMAL_UPDATE constant number := DML_UPDATE;
   NORMAL_DELETE constant number := DML_DELETE;
   STREAM_INSERT constant number := DML_INSERT + STREAM_OFFSET;
   STREAM_UPDATE constant number := DML_UPDATE + STREAM_OFFSET;
   STREAM_DELETE constant number := DML_DELETE + STREAM_OFFSET;

   l_current_date TIMESTAMP;
   l_inserts      NUMBER := 0;
   l_updates      NUMBER := 0;
   l_deletes      NUMBER := 0;
   l_s_inserts    NUMBER := 0;
   l_s_updates    NUMBER := 0;
   l_s_deletes    NUMBER := 0;

procedure flush is
begin
   count(DML_FLUSH);
end flush;

procedure reset is
begin
   delete from at_tsv_count;
end reset;

procedure count (p_dml IN number) is

   -- Increment the posting counters (values/minute).
   -- Save counts in the at_tsv_count table.
   -- p_dml=0 causes the current counts to be written immediately, used by LOGOFF TRIGGER
   -- p_dml=1 (insert), 2 (update), 3 (delete), 4 (GG insert), 5 (GG update), 6 (GG delete)

   PRAGMA AUTONOMOUS_TRANSACTION;

      l_dml               NUMBER := p_dml;
      l_current_inserts   NUMBER;
      l_current_updates   NUMBER;
      l_current_deletes   NUMBER;
      l_s_current_inserts NUMBER;
      l_s_current_updates NUMBER;
      l_s_current_deletes NUMBER;
      l_date              TIMESTAMP;
      l_int               INTEGER;

   begin
      l_date := sys_extract_utc(systimestamp);

      if l_date > l_current_date or l_dml = DML_FLUSH then

         -- Store the counts for the current minute.

         -- NOTE: MERGE does not lock the row until AFTER evaluating the ON condition.
         --       INSERT's block on the same PK, try it first
         --       SELECT ... FOR UPDATE will lock an existing row

         begin
            insert into at_tsv_count
                   (data_entry_date, inserts, updates, deletes,
                    s_inserts, s_updates, s_deletes)
            values (l_current_date, l_inserts, l_updates, l_deletes,
                    l_s_inserts, l_s_updates, l_s_deletes);

         exception
            when DUP_VAL_ON_INDEX then

               select inserts, updates, deletes, s_inserts, s_updates, s_deletes
               into   l_current_inserts, l_current_updates, l_current_deletes,
                      l_s_current_inserts, l_s_current_updates, l_s_current_deletes
               from   at_tsv_count
               where  data_entry_date = l_current_date
               for update;

               update at_tsv_count
               set inserts = l_current_inserts + l_inserts,
                   updates = l_current_updates + l_updates,
                   deletes = l_current_deletes + l_deletes,
                   s_inserts = l_s_current_inserts + l_s_inserts,
                   s_updates = l_s_current_updates + l_s_updates,
                   s_deletes = l_s_current_deletes + l_s_deletes
               where data_entry_date = l_current_date;

         end store;

         -- Batch asynchronous commit to minimize contention
         
         commit WRITE NOWAIT BATCH;

         -- truncate l_date after minutes

         l_current_date := trunc(l_date + one_minute,'MI');
         l_inserts   := 0;
         l_updates   := 0;
         l_deletes   := 0;
         l_s_inserts := 0;
         l_s_updates := 0;
         l_s_deletes := 0;
      end if;

      if is_stream_session and l_dml != DML_FLUSH then
         l_dml := l_dml + STREAM_OFFSET;
      end if;
      case l_dml
         when DML_FLUSH     then null;
         when NORMAL_INSERT then l_inserts := l_inserts + 1;
         when NORMAL_UPDATE then l_updates := l_updates + 1;
         when NORMAL_DELETE then l_deletes := l_deletes + 1;
         when STREAM_INSERT then l_s_inserts := l_s_inserts + 1;
         when STREAM_UPDATE then l_s_updates := l_s_updates + 1;
         when STREAM_DELETE then l_s_deletes := l_s_deletes + 1;
      end case;

   exception
      when others then

         cwms_msg.log_db_message (
            cwms_msg.msg_level_normal,
            'CWMS_TSV: ' || sqlerrm);

         rollback;

   end count;

BEGIN
   -- Package initialization

   l_current_date := trunc(SYSTIMESTAMP AT TIME ZONE 'UTC' + one_minute,'MI');
   is_stream_session := USER='CWMS_STR_ADM' or substr(USER,1,2) = 'GG';

END cwms_tsv;
/
