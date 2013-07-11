INSERT INTO cwms_sec_user_groups (
                                                 user_group_code,
                                                 user_group_id,
                                                 user_group_desc
              )
  VALUES   (-1, 'CCP Proc', 'Intended for Service Accounts that will be running CCP daemon services in the background, e.g., the service account running compproc.'
              );
              
INSERT INTO cwms_sec_user_groups (
                                                 user_group_code,
                                                 user_group_id,
                                                 user_group_desc
              )
  VALUES   (-2, 'CCP Mgr', 'Users that will be managing (i.e., adding/modifying) CCP computations. This privilege is intended to be assigned to real people/user accounts.'
              );
              
INSERT INTO cwms_sec_user_groups (
                                                 user_group_code,
                                                 user_group_id,
                                                 user_group_desc
              )
  VALUES   (-3, 'CCP Reviewer', 'Users who will be allowed to review (i.e., read only) an office’s CCP computations.'
              );

DECLARE
BEGIN
        INSERT INTO at_sec_user_groups
                SELECT  a.office_code, b.user_group_code, b.user_group_id,
                                        b.user_group_desc
                  FROM  cwms_office a, cwms_sec_user_groups b
		  WHERE b.user_group_code in (-1,-2,-3);
END;
/

COMMIT;
