/*
 * Copyright (c) 2026
 * United States Army Corps of Engineers - Hydrologic Engineering Center (USACE/HEC)
 * All Rights Reserved.  USACE PROPRIETARY/CONFIDENTIAL.
 * Source may not be released without written approval from HEC
 */
prompt Creating Oracle Text preferences and indexes

begin
   ctx_ddl.drop_preference('loc_search_ds');
exception when others then null;
end;
/
begin
   ctx_ddl.create_preference('loc_search_ds', 'USER_DATASTORE');
   ctx_ddl.set_attribute('loc_search_ds', 'PROCEDURE', '&cwms_schema..cwms_loc.build_search_doc');
   ctx_ddl.create_preference('loc_search_lexer', 'BASIC_LEXER');
   ctx_ddl.create_preference('loc_search_wordlist', 'BASIC_WORDLIST');
end;
/
commit;

begin
   execute immediate 'drop index at_physical_location_search_idx';
exception
   when others then
      if sqlcode != -1418 then raise; end if;
end;
/
create index at_physical_location_search_idx
   on at_physical_location (search_doc)
   indextype is ctxsys.context
   parameters ('datastore loc_search_ds
       lexer loc_search_lexer
       wordlist loc_search_wordlist
       sync (on commit)');
/

alter index CWMS_20.AT_PHYSICAL_LOCATION_SEARCH_IDX rebuild;

begin
   ctx_ddl.sync_index('AT_PHYSICAL_LOCATION_SEARCH_IDX');
end;
/
