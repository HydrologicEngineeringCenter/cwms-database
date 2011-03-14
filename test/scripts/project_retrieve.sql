DECLARE
  l_PROJECT_ID VARCHAR2(200);
  l_db_office_id varchar2(200);
  l_project_out cwms_dev.project_obj_t;
  l_project_cat sys_refcursor;
  l_basin_cat sys_refcursor;
  
  l_cat_office_id VARCHAR2(200);
  l_cat_base_id varchar2(200);
  l_cat_sub_id VARCHAR2(200);
  
begin
  
  l_project_id := 'TestProject1';
  l_db_office_id := 'SWT';
  
  cwms_project.cat_project(l_project_cat, l_basin_cat, l_db_office_id);

  select db_office_id, base_loction_id, sub_location_id 
  into  l_cat_office_id, l_cat_base_id, l_cat_sub_id
  from l_project_cat 
  where db_office_id = 'SWT'
  and base_location_id = 'TestProject1';
  
if l_cat_base_id is null then
      cwms_err.raise('ERROR', 'cat base loc id should not be null');
   end if; 
  
if l_cat_office_id is null then
      cwms_err.raise('ERROR', 'cat office id should not be null');
   end if; 

cwms_project.retrieve_project(
    l_project_out,l_project_id,l_db_office_id
  );
  
  --l_project_out.project_location.location_ref.base_location_id
  --l_project_out.project_location.location_ref.sub_location_id
  --l_project_out.project_location.location_ref.office_id
  
if l_project_out.project_location.location_ref.base_location_id is null then
      cwms_err.raise('ERROR', 'base loc id should not be null');
   end if; 

if l_project_out.project_location.location_ref.office_id is null then
      cwms_err.raise('ERROR', 'office id should not be null');
   end if; 

END;
