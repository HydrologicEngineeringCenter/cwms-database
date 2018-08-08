BEGIN
   FOR C IN (SELECT UNIQUE username
               FROM at_sec_user_office
              WHERE username IN (SELECT username
                                   FROM all_users))
   LOOP
      CWMS_SEC.CREATE_LOGON_TRIGGER (c.username);
   END LOOP;
END;
/
