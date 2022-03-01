DECLARE
   pd_group_list  "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE"('CWMS PD Users');
   group_list     "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE";
BEGIN
   if '${CWMS_TEST_USERS}' = 'create' then
      "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}cwmspd', group_list, '${CWMS_OFFICE_ID}');

      "${CWMS_SCHEMA}"."CWMS_SEC"."ASSIGN_TS_GROUP_USER_GROUP" ('All Rev TS IDs', 'Viewer Users', 'Read', '${CWMS_OFFICE_ID}');

      "${CWMS_SCHEMA}"."CWMS_SEC"."ASSIGN_TS_GROUP_USER_GROUP" ('All TS IDs', 'CWMS Users', 'Read-Write', '${CWMS_OFFICE_ID}');

         group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('TS ID Creator', 'CWMS Users');
         "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}hectest', group_list, '${CWMS_OFFICE_ID}');
         --
         -- hectest_ro
         group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('CWMS Users', 'Viewer Users');
         "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}hectest_ro', group_list, '${CWMS_OFFICE_ID}');
         --
         -- hectest_dba
         group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('CWMS DBA Users');
         "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}hectest_db', group_list, '${CWMS_OFFICE_ID}');
         --
         -- hectest_ua
         group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('CWMS User Admins', 'TS ID Creator', 'Viewer Users');
         "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}hectest_ua', group_list, '${CWMS_OFFICE_ID}');
         --
         -- hectest_pu
         group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('CWMS User Admins', 'CWMS PD Users','TS ID Creator', 'Viewer Users');
         "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}hectest_pu', group_list, '${CWMS_OFFICE_ID}');
         --
         -- hectest_dx
         group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('Data Exchange Mgr', 'TS ID Creator', 'CWMS Users');
         "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}hectest_dx', group_list, '${CWMS_OFFICE_ID}');
         --
         -- hectest_da
         group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('Data Acquisition Mgr', 'TS ID Creator', 'CWMS Users');
         "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}hectest_da', group_list, '${CWMS_OFFICE_ID}');
         --
         -- hectest_vt
         group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('VT Mgr', 'TS ID Creator', 'CWMS Users');
         "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}hectest_vt', group_list, '${CWMS_OFFICE_ID}');
         --
         -- hectest_dv
         group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('Data Acquisition Mgr', 'VT Mgr', 'TS ID Creator', 'CWMS Users');
         "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}hectest_dv', group_list, '${CWMS_OFFICE_ID}');
         --
         -- hectest_ccp_p
         group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('CWMS PD Users', 'CCP Proc', 'TS ID Creator', 'CWMS Users');
         "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}hectest_ccp_p', group_list, '${CWMS_OFFICE_ID}');
         --
         -- hectest_ccp_m
         group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('CWMS PD Users', 'CCP Mgr', 'TS ID Creator', 'CWMS Users');
         "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}hectest_ccp_m', group_list, '${CWMS_OFFICE_ID}');
         --
         -- hectest_ccp_r
         group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('CWMS PD Users', 'CCP Reviewer', 'TS ID Creator', 'CWMS Users');
         "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}hectest_ccp_r', group_list, '${CWMS_OFFICE_ID}');

         -- hectest_rdl_r
         group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('CWMS PD Users', 'RDL Reviewer', 'TS ID Creator', 'CWMS Users');
         "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}hectest_rdl_r', group_list, '${CWMS_OFFICE_ID}');
         -- hectest_rdl_m
         group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('CWMS PD Users', 'RDL Mgr', 'TS ID Creator', 'CWMS Users');
         "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}hectest_rdl_m', group_list, '${CWMS_OFFICE_ID}');
   end if;
END;
/
