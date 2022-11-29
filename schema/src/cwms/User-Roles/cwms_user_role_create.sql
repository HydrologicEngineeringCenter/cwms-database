--
-- ignore errors
--
whenever sqlerror continue

drop role cwms_user;
drop role web_user;
--
-- notice errors
--
whenever sqlerror exit sql.sqlcode

create role cwms_user not identified;
create role web_user not identified;
