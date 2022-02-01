CREATE TYPE wat_usr_contract_acct_tab_t
/**
 * Holds a collection of water user accounting records
 */
IS
  TABLE OF wat_usr_contract_acct_obj_t;
/


create or replace public synonym cwms_t_wat_usr_cntrct_acct_tab for wat_usr_contract_acct_tab_t;

