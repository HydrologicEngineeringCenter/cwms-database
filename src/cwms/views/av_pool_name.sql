whenever sqlerror continue
delete from at_clob where id = '/VIEWDOCS/AV_POOL_NAME';
whenever sqlerror exit sqlcode
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_POOL_NAME', null,
'
/**
 * Displays reservoir pool names stored in the database
 *
 * @since CWMS 3.1
 *
 * @field office_id       The office that owns the pool name in the database
 * @field office_code     The numeric code of office that owns the pool name in the database
 * @field pool_name       The name of the pool in the database
 * @field pool_name_code  The numeric code of the pool name in the database
 */
');
create or replace force view av_pool_name(
   office_id,
   office_code,
   pool_name,
   pool_name_code)
as
select o.office_id,
       o.office_code,
       pn.pool_name,
       pn.pool_name_code
  from at_pool_name pn,
       cwms_office o
 where o.office_code = pn.office_code;

begin
	execute immediate 'grant select on av_pool_name to cwms_user';
exception
	when others then null;
end;

create or replace public synonym cwms_v_pool_name for av_pool_name;

