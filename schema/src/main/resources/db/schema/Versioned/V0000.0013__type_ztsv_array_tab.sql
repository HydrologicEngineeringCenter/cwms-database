create type ztsv_array_tab
/**
 * Table of <code><big>ztsv_array</big></code> records. This collection specifies
 * multiple time series.  There is no implicit constraint that all of the time series
 * are for the same location or time range, although any routine that uses this type
 * may impose these constraints.  This type does not carrytime zone information, so
 * any usage of it should explicitly declare the time zone. External specification of
 * time series attributes is also required for proper usage.
 *
 * @see type ztsv_type
 * @see type ztsv_array
 * @see type tsv_array_tab
 */
as table of ztsv_array;
/


create or replace public synonym cwms_t_ztsv_array_tab for ztsv_array_tab;

