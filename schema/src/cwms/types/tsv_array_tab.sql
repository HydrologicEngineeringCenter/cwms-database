create type tsv_array_tab
/**
 * Table of <code><big>tsv_array</big></code> records. This collection specifies
 * multiple time series.  There is no implicit constraint that all of the time series
 * are for the same location or time range, although any routine that uses this type
 * may impose these constraints.  This type carries time zone information, so
 * any usage of it should not explicitly declare the time zone. External specification of
 * time series attributes is also required for proper usage.
 *
 * @see type tsv_type
 * @see type tsv_array
 */
as table of tsv_array;
/


create or replace public synonym cwms_t_tsv_array_tab for tsv_array_tab;

