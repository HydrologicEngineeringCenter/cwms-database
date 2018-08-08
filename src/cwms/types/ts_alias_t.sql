create type ts_alias_t
/**
 * Holds information about a time series alias.  This information doesn't contain
 * any context for the alias.
 *
 * @see ts_alias_tab_t
 *
 * @member ts_id        the time series identifier
 * @member ts_attribute a numeric attribute associated with the time series and alias.
 *         This can be used for sorting time series within a time series group or other
 *         user-defined purposes.
 * @member ts_alias_id  the alias for the time series
 * @member ts_ref_id    the time series identifier of a referenced time series
 */
AS OBJECT (
   ts_id         VARCHAR2 (183),
   ts_attribute  NUMBER,
   ts_alias_id   VARCHAR2 (256),
   ts_ref_id     VARCHAR2 (183)
);
/


create or replace public synonym cwms_t_ts_alias for ts_alias_t;

