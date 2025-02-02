CREATE OR REPLACE package cwms_err
is
   -- List all user-defined exceptions names and numbers here.  for example:
   -- Exception numbers are in the range -20000 to -20999.
   --
   --   EXCEPTION_NAME exception;
   --   pragma exception_init (exception_name,-20000);

--    TS_ID_NOT_FOUND       exception; pragma exception_init (ts_id_not_found,       -20001);
--    TS_IS_INVALID         exception; pragma exception_init (ts_is_invalid,         -20002);
--    TS_ALREADY_EXISTS     exception; pragma exception_init (ts_already_exists,     -20003);
--    INVALID_INTERVAL_ID   exception; pragma exception_init (invalid_interval_id,   -20004);
--    INVALID_DURATION_ID   exception; pragma exception_init (invalid_duration_id,   -20005);
--    INVALID_PARAM_ID      exception; pragma exception_init (invalid_param_id,      -20006);
--    INVALID_PARAM_TYPE    exception; pragma exception_init (invalid_param_type,    -20007);
--    INVALID_OFFICE_ID     exception; pragma exception_init (invalid_office_id,     -20010);
--    INVALID_STORE_RULE    exception; pragma exception_init (invalid_store_rule,    -20011);
--    INVALID_DELETE_ACTION exception; pragma exception_init (invalid_delete_action, -20012);
--    INVALID_UTC_OFFSET    exception; pragma exception_init (invalid_utc_offset,    -20013);
--    TS_ID_NOT_CREATED     exception; pragma exception_init (ts_id_not_created,     -20014);
--    XCHG_TS_ERROR         exception; pragma exception_init (xchg_ts_error,         -20015);
--    XCHG_RATING_ERROR     exception; pragma exception_init (xchg_rating_error,     -20016);
--    XCHG_TIME_VALUE       exception; pragma exception_init (xchg_time_value,       -20017);
--    XCHG_NO_DATA          exception; pragma exception_init (xchg_no_data,          -20018);
--    INVALID_ITEM          exception; pragma exception_init (invalid_item,          -20019);
--    ITEM_ALREADY_EXISTS   exception; pragma exception_init (item_already_exists,   -20020);
--    ITEM_NOT_CREATED      exception; pragma exception_init (item_not_created,      -20021);
--    UNIT_CONV_NOT_FOUND   exception; pragma exception_init (unit_conv_not_found,   -20102);
--    INVALID_TIMEZONE      exception; pragma exception_init (invalid_timezone,      -20103);
--    UNITS_NOT_SPECIFIED   exception; pragma exception_init (units_not_specified,   -20104);
--    UNKNOWN_EXCEPTION     exception; pragma exception_init (unknown_exception,     -20999);


   -- raise user-defined exception p_err
   -- substitute values p_1 - p_9 in the error message for %n

   procedure raise (
      p_err in varchar2,
      p_1   in varchar2 default null,
      p_2   in varchar2 default null,
      p_3   in varchar2 default null,
      p_4   in varchar2 default null,
      p_5   in varchar2 default null,
      p_6   in varchar2 default null,
      p_7   in varchar2 default null,
      p_8   in varchar2 default null,
      p_9   in varchar2 default null
      );

end;
/
