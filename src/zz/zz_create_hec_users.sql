/* Formatted on 11/19/2008 6:44:25 AM (QP5 v5.115.810.9015) */
DECLARE
   TYPE username_array_t IS TABLE OF VARCHAR2 (31);

   l_username username_array_t
         := ('Q0HESWLF',
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
             'Q0CWMSPD') ;

   l_execute   VARCHAR2 (250);
   l_hash      VARCHAR2 (16) := 'FEDCCA9876543210';
BEGIN
   NULL;

   FOR i IN l_username.FIRST .. l_username.LAST
   LOOP
      BEGIN
         BEGIN
            l_execute   := 'drop user ' || l_username (i);
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;

         EXECUTE IMMEDIATE l_execute;

         l_execute   :=
               ' create user '
            || l_username (i)
            || ' identified by values '
            || l_hash
            || ' default tablespace cwms_20data
                 temporary tablespace temp
                 profile default
                 account unlock';

         EXECUTE IMMEDIATE l_execute;

         l_execute   := 'grant cwms_user to ' || l_username (i);

         EXECUTE IMMEDIATE l_execute;

         l_execute   :=
               'alter user '
            || l_username (i)
            || ' h1cwmspd default role cwms_user';

         EXECUTE IMMEDIATE l_execute;

         l_execute   :=
               'alter user '
            || l_username (i)
            || ' grant connect through h1cwmsdbi with role cwms_user';

         EXECUTE IMMEDIATE l_execute;


         DBMS_OUTPUT.put_line ('Dropped view ' || view_names (i));
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END LOOP;
END;