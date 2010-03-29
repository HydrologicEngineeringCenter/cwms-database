CREATE OR REPLACE
PACKAGE CWMS_EMBANK AS

-------------------------------------------------------------------------------
-- CAT_EMBANKMENT
--
-- These procedures and functions query and manipulate embankments in the CWMS/ROWCPS
-- database.

---Note
-- 
--

--type definitions:
--

-- security:
-- 
-------------------------------------------------------------------------------

--
-- cat_embankment
-- returns a listing of embankments.
--
-- security: 
--
--
-- The returned records contain the following columns:
--
--    Name                      Datatype      Description
--    ------------------------ ------------- ----------------------------
--    embankment_id	            varchar2(32 byte)	the identification (id) of the embankment structure
--    structure_length	            number(10,0)	the overall length of the embankment structure
--    upstream_sideslope	    number(10,0)	the upstream side slope of the embankment structure
--    downstream_sideslope	    number(10,0)	the downstream side slope of the embankment structure
--    height_max	            number(10,0)	the maximum height of the embankment structure
--    top_width	                    number(10,0)	the width at the top of the embankment structure
--
-------------------------------------------------------------------------------
-- errors will be issued as thrown exceptions.
--
PROCEDURE cat_embankment (
	--described above.
	p_embankment_cat	OUT		sys_refcursor,

	p_embankment_id		IN		VARCHAR2 DEFAULT NULL
);


-- Returns embankment data for a given embankment id. Returned data is encapsulated
-- in a embankment oracle type. 
--
-- security: can be called by user and dba group.
--
-- errors preventing the return of data will be issued as a thrown exception
--
PROCEDURE retrieve_embankment(
	--returns a filled in embankment object including location data
	p_embankment		OUT		embankment_obj_t,

	
	p_embankment_id		IN 		VARCHAR2 DEFAULT NULL

);

-- Stores the data contained within the embankment object into the database schema.
-- 
--
-- security: can only be called by dba group.
--
-- This procedure performs both insert and update functionality. 
--
--
-- errors will be issued as thrown exceptions.
--
procedure store_embankment(
	-- a populated embankment object type.
	p_embankment		IN		embankment_obj_t
);


-- Renames a embankment from one id to a new id.
--
-- security: can only be called by dba group.
--

--
-- errors will be issued as thrown exceptions.
--
procedure rename_embankment(
    
	p_embankment_id_old	IN	VARCHAR2,
	p_embankment_id_new	IN	VARCHAR2
	
);

-- Performs a  delete on the embankment.
--  ????Should this be a cascading delete?
--
-- security: can only be called by dba group.
--

--
-- errors will be issued as thrown exceptions.
--
procedure delete_embankment(
	-- base location id + "-" + sub-loc id (if it exists)
    p_embankment_id		IN   VARCHAR
);


END CWMS_EMBANK;