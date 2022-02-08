
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_APPLICATION_LOGIN', null,
'
/**
 * Displays application login information
 *
 * @since Schema 18.1
 *
 * @field uuid           Unique application session identifier
 * @field office_id      Office of user running the application
 * @field user_name      User running the application
 * @field app_name       Name of the application
 * @field host_name      Name of system user is running the application on
 * @field login_time     The time the application logged in
 * @field logout_time    The time the application logged out or was found to be disconnected
 * @field login_duration The time span the application was logged in
 * @field normal_logout  ''T'' if application logged out, ''F'' if its session was found to be disconnected
 * @field login_server   The URL of the login server handling the login or logout
 */
');

create or replace force view av_application_login(
   uuid,
   office_id,
   user_name,
   app_name,
   host_name,
   login_time,
   logout_time,
   login_duration,
   normal_logout,
   login_server
)
as
select al.uuid,
       co.office_id,
       al.user_name,
       al.app_name,
       al.host_name,
       cwms_util.to_timestamp(al.login_time),
       case
       when al.logout_time = 0 then null
       else cwms_util.to_timestamp(al.logout_time)
       end,
       case
       when al.logout_time = 0 then null
       else cwms_util.to_timestamp(al.logout_time) - cwms_util.to_timestamp(al.login_time)
       end,
       al.normal_logout,
       al.login_server
  from at_application_login al,
       cwms_office co
 where co.office_code = al.office_code;

begin
	execute immediate 'grant select on av_application_login to cwms_user';
exception
	when others then null;
end;
/


create or replace public synonym cwms_v_application_login for av_application_login;
