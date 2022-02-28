--whenever sqlerror continue
delete from at_clob where id = '/VIEWDOCS/AV_APPLICATION_SESSION';
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_APPLICATION_SESSION', null,
'
/**
 * Displays sessions of currently-logged-in applications
 *
 * @since Schema 18.1
 *
 * @field uuid           Unique application session identifier
 * @field office_id      Office of user running the application
 * @field user_name      User running the application
 * @field app_name       Name of the application
 * @field host_name      Name of system user is running the application on
 * @field login_time     The time the application logged in
 * @field session_id     The AUSID of the session connected from the logged-in application
 * @field login_server   The URL of the login server handling the login or logout
 */
');

create or replace force view av_application_session(
   uuid,
   office_id,
   user_name,
   app_name,
   host_name,
   login_time,
   session_id,
   login_server
)
as
select l.uuid,
       o.office_id,
       l.user_name,
       l.app_name,
       l.host_name,
       cwms_util.to_timestamp(l.login_time),
       s.session_id,
       l.login_server
  from at_application_login l,
       at_application_session s,
       cwms_office o
 where o.office_code = l.office_code
   and s.uuid = l.uuid
   and s.session_id in (select column_value from table(cwms_util.current_session_ids));

begin
	execute immediate 'grant select on av_application_session to cwms_user';
exception
	when others then null;
end;
/


create or replace public synonym cwms_v_application_session for av_application_session;
