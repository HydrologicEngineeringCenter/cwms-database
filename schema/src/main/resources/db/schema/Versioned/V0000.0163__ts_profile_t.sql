create type ts_profile_t
/**
 * Holds a definition of a time series profile
 *
 * @param location               The location for the profile
 * @param profile_params         A table of parameters for the profile, in defined position order
 * @param key_parameter_position The 1-based position in the profile_params table of the key parameter
 * @param reference_ts_id        A time series identifier of a reference parameter value (normally Elev) for this profile
 * @param description            A text description of the profile.
 *
 * @since CWMS schema 18.1.6
 * @see type location_ref_t
 */
as object(
   location               location_ref_t,
   key_parameter_id       varchar2(49),
   profile_params         str_tab_t,
   reference_ts_id        varchar2(191),
   description            varchar2(256));
/
grant execute on ts_profile_t to cwms_user;
create or replace public synonym cwms_t_ts_profile for ts_profile_t;

