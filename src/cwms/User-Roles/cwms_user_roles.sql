--
-- ignore errors
--
whenever sqlerror continue
   
drop role cwms_dev;
drop role cwms_user;

--
-- notice errors
--
whenever sqlerror exit sql.sqlcode

create role cwms_user not identified;
grant create session to cwms_user;
-- execute on packages granted later

create role cwms_dev not identified;
grant cwms_user to cwms_dev;
-- select on views granted later

