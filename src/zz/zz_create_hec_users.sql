/* Formatted on 11/19/2008 8:15:45 AM (QP5 v5.115.810.9015) */
DECLARE
   TYPE username_array_t IS TABLE OF VARCHAR2 (31);

   l_username username_array_t
         := username_array_t ('Q0HECWLF',
                              'Q0HECARW',
                              'Q0HECSRL',
                              'Q0HECSJN',
                              'Q0HECRHG',
                              'Q0HECAMC',
                              'Q0HECGCM',
                              'Q0HECTAE',
                              'Q0HECSSP',
                              'Q0HECPSM',
                              'Q0HECPRB',
                              'Q0HECPBE',
                              'Q0HECMMM',
                              'Q0HECMDP',
                              'Q0HECMBH',
                              'Q0HECJDK',
                              'Q0HECFUH',
                              'Q0HECDDN',
                              'Q0HECCWF',
                              'Q0HECWJC',
                              'Q0HECGHK',
                              'Q0HECPOF',
                              'Q0CWMSPD'
            ) ;

   l_execute   VARCHAR2 (250);
   l_hash      VARCHAR2 (16) := 'FEDCCA9876543210';
   l_1         VARCHAR2 (1) := '1';
   l_2         VARCHAR2 (1) := '2';
   l_3         VARCHAR2 (1) := '3';
   l_4         VARCHAR2 (1) := '4';
   l_5         VARCHAR2 (1) := '5';
   l_6         VARCHAR2 (1) := '+';
   l_7         VARCHAR2 (1) := '+';
   l_8         VARCHAR2 (1) := '+';
BEGIN
   NULL;

   FOR i IN l_username.FIRST .. l_username.LAST
   LOOP
      BEGIN
         BEGIN
            l_execute   := 'drop user ' || l_username (i);

            EXECUTE IMMEDIATE l_execute;

            l_1         := 'd';
         EXCEPTION
            WHEN OTHERS
            THEN
               l_1   := 'D';
         END;



         l_execute   :=
               ' create user '
            || l_username (i)
            || ' identified by values '''
            || l_hash
            || ''' default tablespace cwms_20data
                 temporary tablespace temp
                 profile default
                 account unlock';

         EXECUTE IMMEDIATE l_execute;

         l_2         := 'c';

         l_execute   := 'grant cwms_user to ' || l_username (i);

         EXECUTE IMMEDIATE l_execute;

         l_3         := 'g';

         l_execute   :=
            'alter user ' || l_username (i) || ' default role cwms_user';

         EXECUTE IMMEDIATE l_execute;

         l_4         := 'a';

         l_execute   :=
               'alter user '
            || l_username (i)
            || ' grant connect through h1cwmsdbi with role cwms_user';

         EXECUTE IMMEDIATE l_execute;

         l_5         := 'p';
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      BEGIN
         INSERT INTO cwms_20.at_sec_user_office
        (
            user_id, user_db_office_code
        )
         VALUES (l_username (i), 8);

         l_6   := 'p';
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      BEGIN
         INSERT INTO cwms_20.at_sec_users
        (
            db_office_code, user_group_code, user_id
        )
         VALUES (8, 1, l_username (i));

         l_7   := 'p';
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      BEGIN
         INSERT INTO cwms_20.at_sec_users
        (
            db_office_code, user_group_code, user_id
        )
         VALUES (8, 10, l_username (i));

         l_8   := 'p';
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      DBMS_OUTPUT.put_line(   l_1
                           || l_2
                           || l_3
                           || l_4
                           || l_5
                           || l_6
                           || l_7
                           || l_8
                           || ' '
                           || l_username (i));
   END LOOP;
END;
/
