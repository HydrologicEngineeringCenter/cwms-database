/* Formatted on 2007/04/02 06:56 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE BODY cwms_priv
AS
   PROCEDURE passwd (p_username IN VARCHAR2, p_password IN VARCHAR2)
   IS
      l_username   VARCHAR2 (30) := UPPER (TRIM (p_username));
      l_password   VARCHAR2 (30) := UPPER (TRIM (p_password));
   BEGIN
      IF l_username = l_password
      THEN
         cwms_err.RAISE ('GENERIC',
                         'Password cannot be the same as the Username.'
                        );
      END IF;

      IF LENGTH (l_password) < 8
      THEN
         cwms_err.RAISE ('GENERIC',
                         'Password must be at least eight charcters long'
                        );
      END IF;

      -- This works...
      EXECUTE IMMEDIATE    'alter user '
                        || l_username
                        || ' identified by '
                        || l_password;
      -- This return an ORA-01935: missing user or role name...
--      EXECUTE IMMEDIATE 'alter user :u identified by :p'
--                  USING l_username, l_password;
   END;
END cwms_priv;
/