SET serveroutput on


CREATE OR REPLACE PACKAGE BODY CWMS_PROJECT AS

PROCEDURE cat_project (
	--described above.
	p_project_cat		OUT		sys_refcursor, 
	
	--defaults to the user's office if null.
	p_db_office_id		IN		VARCHAR2 DEFAULT NULL
) AS
BEGIN
    /* TODO implementation required */
    NULL;
END cat_project;


PROCEDURE retrieve_project(
	--returns a filled in project object
	p_project					OUT		project_obj_t,
	
	-- base location id + "-" + sub-loc id (if it exists)
	p_project_id				IN 		VARCHAR2, 
	
	-- defaults to the user's office if null
	p_db_office_id				IN		VARCHAR2 DEFAULT NULL 
) AS
BEGIN
    /* TODO implementation required */
    NULL;
END retrieve_project;


--stores the data contained within the project object into the database schema
--will this alter the referenced location types?
procedure store_project(
	p_project					IN		project_obj_t
) AS
BEGIN
	/* TODO implementation required */
    NULL;
END store_project;

-- renames a project from one id to a new one.
-- this should probably just call cwms_loc.rename_location().
procedure rename_project(
	p_project_id_old	IN	VARCHAR2,
	p_project_id_new	IN	VARCHAR2,
	p_db_office_id		IN	VARCHAR2 DEFAULT NULL
) AS
BEGIN
	/* TODO implementation required */
    NULL;
END rename_project;

-- deletes a project, this does not affect any of the location code data.
procedure delete_project(
      p_project_id		IN   VARCHAR2,
      p_db_office_id    IN   VARCHAR2 DEFAULT NULL
   ) AS
BEGIN
	/* TODO implementation required */
    NULL;
END delete_project;

END CWMS_PROJECT;
 
/
show errors;
