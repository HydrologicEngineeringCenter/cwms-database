DECLARE
  l_PROJECT_ID VARCHAR2(200);
  l_db_office_id varchar2(200);
  l_project_out cwms_dev.project_obj_t;
  l_project_cat sys_refcursor;
  l_basin_cat sys_refcursor;
  
  l_cat_office_id VARCHAR2(200);
  l_cat_base_id varchar2(200);
  l_cat_sub_id VARCHAR2(200);

 l_embankments embankment_tab_t;
  l_project_loc_ref_in location_ref_t ;
  
begin
  
  l_project_id := 'AAAAA';
  l_db_office_id := 'SWT';
 
  l_project_loc_ref_in := location_ref_t(l_project_id,null,l_db_office_id);
  cwms_embank.retrieve_embankments(l_embankments,l_project_loc_ref_in);

END;
