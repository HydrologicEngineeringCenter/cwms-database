create type configuration_t
/**
 * Object representing a single configuration in the database
 *
 * @member office_id          The office that owns the configuration
 * @member category_id        Category describing the type of configuration
 * @member configuration_id   The text identifier of the configuration
 * @member configuration_name The name of the configuration
 */
as object (
   office_id          varchar2(16),
   category_id        varchar2(16),
   configuration_id   varchar2(32),
   configuration_name varchar2(128)
);
/

create or replace public synonym cwms_t_configuration for configuration_t;
