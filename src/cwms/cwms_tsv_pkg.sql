CREATE OR REPLACE PACKAGE CWMS_TSV
IS
   -- Count the number of time series values inserted, updated or deleted per minute.
   -- Save the results in the at_tsv_count table.

   procedure count (p_dml IN number, p_date IN timestamp);

END cwms_tsv;
/

SHOW ERRORS;
COMMIT;
