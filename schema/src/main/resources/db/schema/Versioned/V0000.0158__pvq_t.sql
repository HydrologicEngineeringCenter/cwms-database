create type pvq_t
/**
 * Holds an undated value and quality code for a specified parameter
 *
 * @member parameter_code The unique parameter code for the value
 * @member value          The value for the parameter
 * @member quality_code   The quality code for the value
 *
 * @since CWMS schema 18.1.6
 * @see type pvq_tab_t
 */
as object(
   parameter_code integer,
   value          binary_double,
   quality_code   integer);
/
grant execute on pvq_t to cwms_user;
create or replace public synonym cwms_t_pvq for pvq_t;

