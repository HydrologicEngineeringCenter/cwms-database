insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_STORE_RULE', null,
'
/**
 * Displays information about CWMS Store Rules
 *
 * @field store_rule_code The default sort order of the store rule for offices that don''t specify their own
 * @field store_rule_id   The store rule
 * @field description     Describes the behavior of the store rule
 *
 * @see view av_store_rule_ui
 */
');
create or replace force view av_store_rule(
   store_rule_code,
   store_rule_id,
   description)
as
   select store_rule_code, 
          store_rule_id, 
          description 
     from cwms_store_rule;
                                                                                          
