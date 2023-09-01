insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_NATION', null,
'
/**
 * Displays nations
 *
 * @since CWMS 2.1
 *
 * @field nation_id     The unique nation identifier
 * @field nation_name   The name of the nation
 */
');
create or replace force view av_nation
(
   nation_id,
   nation_name
)
as
select fips_cntry as nation_id,
       long_name as nation_name
  from cwms_nation_sp;
