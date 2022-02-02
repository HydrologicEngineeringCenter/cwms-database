--
-- STRAGG  (Function)
--
--  Dependencies:
--   STANDARD (Package)
--   SYS_STUB_FOR_PURITY_ANALYSIS (Package)
--   STRING_AGG_TYPE (Type)
--
CREATE OR REPLACE FUNCTION stragg(input varchar2 )
    RETURN varchar2
    PARALLEL_ENABLE AGGREGATE USING string_agg_type;
/