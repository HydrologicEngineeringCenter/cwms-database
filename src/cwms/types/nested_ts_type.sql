create or replace TYPE nested_ts_type
-- not documented, used only in body of retrieve_ts_multi
 AS OBJECT (
   SEQUENCE     INTEGER,
   tsid         VARCHAR2(191),
   units        VARCHAR2 (16),
   start_time   DATE,
   end_time     DATE,
   DATA         tsv_array
);
/


create or replace public synonym cwms_t_nested_ts for nested_ts_type;

