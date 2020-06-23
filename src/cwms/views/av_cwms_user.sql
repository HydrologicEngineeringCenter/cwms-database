delete from at_clob where office_code = 53 and id = '/VIEWDOCS/AV_CWMS_USER';
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_CWMS_USER', null,
'
/**
 * Displays identifier and name information about CWMS users
 *
 * @since CWMS 18.1.6
 *
 * @field user_id       The user''s UPASS identifier
 * @field first_name    The user''s first name
 * @field last_name     The user''s last name
 * @field full_name     The user''s full name
 * @field phone         The user''s telephone number
 * @field email         The user''s email address
 * @field office_symbol The full office symbol for the user
 * @field office_id     The CWMS office identifier for the user
 */
');
create or replace view av_cwms_user (
   user_id,
   first_name,
   last_name,
   full_name,
   phone,
   email,
   office_symbol,
   office_id)
as
select user_id,
       first_name,
       last_name,
       full_name,
       case
       when length(phone) >= 10 then
          case
          when substr(nvl(phone, '0'), 1, 1) = '1' then
             substr(phone, 2, 3)
             ||'-'
             ||substr(phone, 5, 3)
             ||'-'
             ||substr(phone, 8, 4)
          else
             substr(phone, 1, 3)
             ||'-'
             ||substr(phone, 4, 3)
             ||'-'
             ||substr(phone, 7, 4)
          end
       else null
       end as phone,
       email,
       office_symbol,
       office_id
  from (select upper(userid) as user_id,
               initcap(substr(fullname, 1, instr(fullname, ' ') - 1)) as first_name,
               initcap(substr(fullname, instr(fullname, ' ', -1) + 1)) as last_name,
               initcap(fullname) as full_name,
               regexp_replace(phone, '\D', null) as phone,
               lower(email) as email,
               upper(office) as office_symbol,
               upper(org) as office_id
          from at_sec_cwms_users
       );

begin
	execute immediate 'grant select on av_cwms_user to cwms_user';
exception
	when others then null;
end;
create or replace public synonym cwms_v_user for av_cwms_user;