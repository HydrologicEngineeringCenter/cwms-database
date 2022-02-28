create or replace trigger at_application_login_t01
before insert or update on at_application_login
for each row
declare
   procedure update_error(p_item in varchar2) is
   begin
      cwms_err.raise('Cannot update existing '||p_item);
   end update_error;
begin
   --------------------------
   -- upper-case the names --
   --------------------------
   :new.user_name := upper(:new.user_name);
   :new.app_name  := upper(:new.app_name);
   :new.host_name := upper(:new.host_name);
   case
   when updating then
      ---------------------------
      -- prevent modifications --
      ---------------------------
      case
      when :new.uuid         != :old.uuid         then update_error('application session (primary) key');
      when :new.office_code  != :old.office_code  then update_error('office code');
      when :new.user_name    != :old.user_name    then update_error('user name');
      when :new.app_name     != :old.app_name     then update_error('app name');
      when :new.host_name    != :old.host_name    then update_error('host name');
      when :new.login_time   != :old.login_time   then update_error('login time');
      when :new.login_server != :old.login_server then update_error('login server');
      else null;
      end case;
   else null;
   end case;
end at_application_login_t01;
/