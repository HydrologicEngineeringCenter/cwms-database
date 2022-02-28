create or replace TYPE nested_ts_type
-- not documented, used only in body of retrieve_ts_multi
 AS OBJECT (
   SEQUENCE           INTEGER,
   tsid               VARCHAR2(191),
   units              VARCHAR2 (16),
   start_time         date,
   end_time           date,
   DATA               tsv_array,
   location_time_zone VARCHAR2(28)
);
/


create or replace public synonym cwms_t_nested_ts2 for nested_ts2_type;

