/* Formatted on 2007/04/02 09:56 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE BODY cwms_priv
AS
   PROCEDURE passwd (p_username IN VARCHAR2, p_password IN VARCHAR2)
   IS
      l_username   VARCHAR2 (30)
                              := dbms_assert.enquote_name (TRIM (p_username));
      l_password   VARCHAR2 (30)
                       := dbms_assert.enquote_name (TRIM (p_password), FALSE);
      l_sql        VARCHAR2(32767);                       
   BEGIN
      -- Make sure there is not whitespace in either the username or password...
      IF REGEXP_INSTR (l_username, '\s') != 0
      THEN
         cwms_err.RAISE
                     ('GENERIC_ERROR',
                      'Invlaid Username - contains one or more blank spaces.'
                     );
      END IF;

      IF REGEXP_INSTR (l_password, '\s') != 0
      THEN
         cwms_err.RAISE
                     ('GENERIC_ERROR',
                      'Invlaid Password - contains one or more blank spaces.'
                     );
      END IF;

      IF l_username = l_password
      THEN
         cwms_err.RAISE ('GENERIC_ERROR',
                         'Password cannot be the same as the Username.'
                        );
      END IF;

      IF LENGTH (l_password) < 8
      THEN
         cwms_err.RAISE ('GENERIC_ERROR',
                         'Password must be at least eight charcters long'
                        );
      END IF;
                        
      l_sql := 'alter user '||l_username||' identified by '||l_password;
      cwms_util.check_dynamic_sql(l_sql);
      
      -- This works...
      EXECUTE IMMEDIATE l_sql;
      -- This return an ORA-01935: missing user or role name...
--      EXECUTE IMMEDIATE 'alter user :u identified by :p'
--                  USING l_username, l_password;
   END passwd;
END cwms_priv;
/