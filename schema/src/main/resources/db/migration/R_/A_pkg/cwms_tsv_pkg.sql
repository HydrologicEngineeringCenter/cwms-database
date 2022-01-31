create or replace PACKAGE cwms_tsv
IS
   DML_FLUSH         constant number := 0;
   DML_INSERT        constant number := 1;
   DML_UPDATE        constant number := 2;
   DML_DELETE        constant number := 3;
   IS_STREAM_SESSION boolean;

   -- Flushes in-memory counts to table. Same as count(DML_FLUSH);
   procedure flush;
   -- Count the number of timeseries values inserted, updated or deleted per minute.
   -- Count local and streamed DML separately.
   -- Streamed DML may be detected by looking for the Oracle GoldenGate USER
   -- Save the results in the at_tsv_count table.
   procedure count (p_dml IN number);

END cwms_tsv;
/

SHOW ERRORS;
COMMIT;
