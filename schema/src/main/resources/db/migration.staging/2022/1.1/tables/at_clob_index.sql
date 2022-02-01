/*
  This must be run as the cwms_20 user. DO NOT run as SYS!
  This index was added as part of the CMA v2 project with CRREL
  Dated 28 May 2014
*/
DECLARE
  xcnt number;
BEGIN
  BEGIN
    ctx_ddl.drop_preference('at_clob_wordlist');
  EXCEPTION
    when others then
      null;
  END;
--
  BEGIN
    EXECUTE IMMEDIATE 'drop index at_clob_cidx';
    DBMS_OUTPUT.put_line ('Dropped index at_clob_cidx');
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;
--
  BEGIN
    ctx_ddl.create_preference ('at_clob_wordlist', 'BASIC_WORDLIST');
    ctx_ddl.set_attribute ('at_clob_wordlist', 'PREFIX_INDEX', 'TRUE');
    ctx_ddl.set_attribute ('at_clob_wordlist', 'PREFIX_MIN_LENGTH', 3);
    ctx_ddl.set_attribute ('at_clob_wordlist', 'PREFIX_MAX_LENGTH', 4);
    ctx_ddl.set_attribute ('at_clob_wordlist', 'SUBSTRING_INDEX', 'YES');
  END;
END;
/

CREATE INDEX at_clob_cidx
   ON at_clob (VALUE)
   INDEXTYPE IS CTXSYS.CONTEXT
      PARAMETERS ('datastore ctxsys.default_datastore WORDLIST at_clob_wordlist');

