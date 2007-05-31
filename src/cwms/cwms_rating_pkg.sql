CREATE OR REPLACE package CWMS_20.cwms_rating as

/******************************************************************************
*   Name:       CWMS_RATING 
*   Purpose:       
*
*   Revisions:  
*   Ver        Date        Author      Description  
*   ---------  ----------  ----------  ----------------------------------------
*   1.0        4/23/2007   Portin      Original  
******************************************************************************/

procedure add_rating (
   p_source     in   varchar2,               -- rating source ("USGS") 
   p_type       in   varchar2,               -- rating type ("STGQ") 
   p_interp     in   varchar2,               -- rating expansion ("LOGARITHMIC")  
   p_count      in   integer  default 1,     -- independent parameter count 
   p_desc       in   varchar2 default null,  -- description for this rating family 
   p_office     in   varchar2 default null   -- db office id 
   );

procedure add_parameters (
   p_source     in   varchar2,               -- rating source ("USGS") 
   p_type       in   varchar2,               -- rating type ("STGQ") 
   p_indep_1    in   varchar2,               -- 1st independent parameter 
   p_indep_2    in   varchar2 default null,  -- 2nd independent parameter (optional)   
   p_dep        in   varchar2,               -- dependent parameter 
   p_version    in   varchar2,               -- cwms pathname version 
   p_desc       in   varchar2 default null,  -- description for this parameter set 
   p_office     in   varchar2 default null   -- db office id    
   );     
 
function add_location (
   p_source     in   varchar2,               -- rating source ("USGS") 
   p_type       in   varchar2,               -- rating type ("STGQ") 
   p_loc        in   varchar2,               -- cwms base location ("BON") 
   p_load       in   char     default 'T',   -- auto load flag ("T" or F")   
   p_active     in   char     default 'F',   -- auto active flag ("T" or F")   
   p_filename   in   varchar2 default null,  -- cwms pathname version 
   p_desc       in   varchar2 default null,  -- description for this parameter set 
   p_office     in   varchar2 default null   -- db office id    
   
   ) return integer;                         -- return the rating_loc_code  

procedure delete_location (
   p_source     in   varchar2,               -- rating source ("USGS") 
   p_type       in   varchar2,               -- rating type ("STGQ") 
   p_loc        in   varchar2,               -- cwms base location ("BON") 
   p_office     in   varchar2 default null   -- db office id       
   );  

procedure extend_curve (
   p_source     in   varchar2,               -- rating source ("USGS") 
   p_type       in   varchar2,               -- rating type ("STGQ") 
   p_loc        in   varchar2,               -- cwms base location ("BON") 
   p_x          in   number,                 -- X value 
   p_y          in   number,                 -- Y value 
   p_x_units    in   varchar2 default null,  -- X value units ("ft"), default to db units 
   p_y_units    in   varchar2 default null,  -- Y value units ("cfm"), default to db units
   p_effective  in   timestamp with time zone 
                     default systimestamp, 
   p_active     in   char     default 'F',   -- active flag ("T" or F")  
   p_office     in   varchar2 default null   -- db office id                          
   );
                
procedure load_rdb_files ( 
   p_dir        in   varchar2,               -- directory object name       
   p_date       in   date                    -- load rdb files newer than p_date 
   );
 
procedure load_rdb_file ( 
   p_dir        in   varchar2,               -- directory object name   
   p_file       in   varchar2,               -- an rdb filename 
   p_cwms_id    in   varchar2,               -- cwms_id associated w/the rating table   
   p_active     in   char     := null,       -- activate flag ("T","F" or null)    
   p_max_y_diff in   number   := 0.0001,     -- max acceptable y diff is y times this number  
   p_max_y_errs in   integer  := 0           -- max y errors before aborting the load  
   );   

end cwms_rating;
/
