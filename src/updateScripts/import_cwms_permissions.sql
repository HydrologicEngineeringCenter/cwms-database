accept permissions_dir  char prompt 'Enter the name of the directory where the permissions file is stored         : '
accept office_id  char prompt 'Enter the office id         : '

PROMPT Importing CWMS Permissions

DECLARE
   PROCEDURE IMPORT_CWMS_PERMISSIONS (P_DIR            IN VARCHAR2,
                                      P_DB_OFFICE_ID      VARCHAR2)
   AS
      l_file          UTL_FILE.FILE_TYPE;
      l_log           UTL_FILE.FILE_TYPE;
      l_line          VARCHAR2 (1024);
      l_user          VARCHAR2 (16);
      l_permissions   VARCHAR2 (1024);
      l_fullname      VARCHAR2 (64);
      l_count         NUMBER;

      PROCEDURE PARSE_LINE (P_LINE          IN     VARCHAR2,
                            P_USER             OUT VARCHAR2,
                            P_PERMISSIONS      OUT VARCHAR2,
                            P_FULLNAME         OUT VARCHAR2)
      IS
         l_start_pos   NUMBER;
         l_end_pos     NUMBER;
      BEGIN
         l_start_pos := 1;
         l_end_pos := INSTR (p_line, '|');
         p_user := SUBSTR (p_line, 1, l_end_pos - l_start_pos);

         l_start_pos :=
            INSTR (p_line,
                   '|',
                   1,
                   2);
         l_end_pos :=
            INSTR (p_line,
                   '|',
                   1,
                   3);

         p_permissions :=
            SUBSTR (p_line, l_start_pos + 1, l_end_pos - l_start_pos - 1);
         l_start_pos :=
            INSTR (p_permissions,
                   ',',
                   1,
                   2);
         p_permissions := SUBSTR (p_permissions, l_start_pos + 1);

         l_start_pos :=
            INSTR (p_line,
                   '|',
                   1,
                   3);
         l_end_pos :=
            INSTR (p_line,
                   '|',
                   1,
                   4);
         p_fullname :=
            SUBSTR (p_line, l_start_pos + 1, l_end_pos - l_start_pos - 1);
      END;
   BEGIN
      EXECUTE IMMEDIATE
            'CREATE OR REPLACE DIRECTORY CWMS_PERMISSIONS_DIR AS '''
         || P_DIR
         || '''';

      l_file :=
         UTL_FILE.FOPEN ('CWMS_PERMISSIONS_DIR', 'cwms.permissions', 'r');
      l_log :=
         UTL_FILE.FOPEN ('CWMS_PERMISSIONS_DIR',
                         'CWMS-PERMISSIONS-IMPORT.LOG',
                         'w');

      LOOP
         BEGIN
            UTL_FILE.GET_LINE (l_file, l_line);
            PARSE_LINE (L_LINE,
                        L_USER,
                        L_PERMISSIONS,
                        L_FULLNAME);

            L_COUNT := 0;
            L_USER := UPPER (L_USER);

            SELECT COUNT (*)
              INTO L_COUNT
              FROM ALL_USERS
             WHERE USERNAME = L_USER;

            IF (L_COUNT = 0)
            THEN
               UTL_FILE.PUT_LINE (
                  L_LOG,
                  L_USER
                  || ' is not a valid database user. User permissions not imported');
            ELSE
               UTL_FILE.PUT_LINE (L_LOG, 'Importing user entry ' || L_USER);

               SELECT COUNT (*)
                 INTO L_COUNT
                 FROM AT_SEC_CWMS_USERS
                WHERE USERID = L_USER;

               IF (L_COUNT = 0)
               THEN
                  UTL_FILE.PUT_LINE (
                     L_LOG,
                     L_USER
                     || ' is not a cwms user. Adding the user metadata');
                  CWMS_SEC.UPDATE_USER_DATA (L_USER,
                                             L_FULLNAME,
                                             NULL,
                                             NULL,
                                             NULL,
                                             NULL);

                  INSERT
                    INTO AT_SEC_CWMS_PERMISSIONS (USERNAME,
                                                  PERMISSIONS,
                                                  DB_OFFICE_CODE)
                  VALUES (
                            L_USER,
                            L_PERMISSIONS,
                            CWMS_UTIL.GET_OFFICE_CODE (P_DB_OFFICE_ID));
               ELSE
                  UTL_FILE.PUT_LINE (
                     L_LOG,
                        'Adding CWMS Permissions for '
                     || L_USER
                     || ':'
                     || L_PERMISSIONS);
                  CWMS_SEC.UPDATE_USER_CWMS_PERMISSIONS (L_USER,
                                                         L_PERMISSIONS,
                                                         P_DB_OFFICE_ID);
               END IF;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               EXIT;
         END;
      END LOOP;

      UTL_FILE.FCLOSE (L_LOG);
      UTL_FILE.FCLOSE (L_FILE);
   END IMPORT_CWMS_PERMISSIONS;
BEGIN
   IMPORT_CWMS_PERMISSIONS ('&permissions_dir', '&office_id');
   execute immediate 'insert into at_sec_cwms_users(userid,createdby) select username,''&cwms_schema'' from at_sec_user_office minus select userid,''&cwms_schema'' from at_sec_cwms_users';
   COMMIT;
END;
/

