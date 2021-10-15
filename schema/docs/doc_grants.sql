set defines on
define user=&1;
grant select on dba_synonyms to &user;
grant select on dba_objects to &user;
grant select on all_tab_columns to &user;
grant select on cwms_20.at_clob to &user;
