create or replace package cwms_text
as 
--
-- store text with optional description 
--
procedure store_text(
   p_text_code      out number,                 -- the code for use in foreign keys
	p_text           in  clob,                   -- the text, unlimited length
	p_id             in  varchar2,               -- identifier with which to retrieve text (256 chars max)
	p_description    in  varchar2 default null,  -- description, defaults to null
	p_fail_if_exists in  varchar2 default 'T',   -- flag specifying whether to fail if p_id already exists
	p_office_id      in  varchar2 default null); -- office id, defaults current user's office

--
-- store text with optional description
--
function store_text(
	p_text           in clob,                   -- the text, unlimited length
	p_id             in varchar2,               -- identifier with which to retrieve text (256 chars max)
	p_description    in varchar2 default null,  -- description, defaults to null
	p_fail_if_exists in varchar2 default 'T',   -- flag specifying whether to fail if p_id already exists
	p_office_id      in varchar2 default null)  -- office id, defaults current user's office
   return number;                              -- the code for use in foreign keys

--
-- store text with optional description
--
procedure store_text(
   p_text_code      out number,                 -- the code for use in foreign keys
	p_text           in  varchar2,               -- the text, limited to varchar2 max size
	p_id             in  varchar2,               -- identifier with which to retrieve text (256 chars max)
	p_description    in  varchar2 default null,  -- description, defaults to null
	p_fail_if_exists in  varchar2 default 'T',   -- flag specifying whether to fail if p_id already exists
	p_office_id      in  varchar2 default null); -- office id, defaults current user's office

--
-- store text with optional description
--
function store_text(
	p_text           in varchar2,               -- the text, limited to varchar2 max size
	p_id             in varchar2,               -- identifier with which to retrieve text (256 chars max)
	p_description    in varchar2 default null,  -- description, defaults to null
	p_fail_if_exists in varchar2 default 'T',   -- flag specifying whether to fail if p_id already exists
	p_office_id      in varchar2 default null)  -- office id, defaults current user's office
   return number;                              -- the code for use in foreign keys

--	
-- retrieve text only
--
procedure retrieve_text(
	p_text      out clob,                   -- the text, unlimited length
	p_id        in  varchar2,               -- identifier used to store text (256 chars max)
	p_office_id in  varchar2 default null); -- office id, defaults current user's office

--	
-- retrieve text only
--
function retrieve_text(
	p_id        in  varchar2,              -- identifier used to store text (256 chars max)
	p_office_id in  varchar2 default null) -- office id, defaults current user's office
	return clob;                           -- the text, unlimited length

--	
-- retrieve text and description
--
procedure retrieve_text(
	p_text        out clob,                   -- the text, unlimited length
	p_description out varchar2,               -- the description
	p_id          in  varchar2,               -- identifier used to store text (256 chars max)
	p_office_id   in  varchar2 default null); -- office id, defaults current user's office

--
-- update text and/or description 
--
procedure update_text(
	p_text           in clob,                   -- the text, unlimited length
	p_id             in varchar2,               -- identifier with which to retrieve text (256 chars max)
	p_description    in varchar2 default null,  -- description, defaults to null
	p_ignore_nulls   in varchar2 default 'T',   -- flag specifying null inputs leave current values unchanged
	p_office_id      in varchar2 default null); -- office id, defaults current user's office

--
-- delete text
--
procedure delete_text(
	p_id        in  varchar2,               -- identifier used to store text (256 chars max)
	p_office_id in  varchar2 default null); -- office id, defaults current user's office

--
-- get matching ids in a cursor
--
procedure get_matching_ids(
	p_ids                  in out sys_refcursor,       -- cursor of the matching office ids, text ids, and optionally descriptions
	p_id_masks             in  varchar2 default '%',   -- delimited list of id masks, defaults to all ids               
	p_include_descriptions in  varchar2 default 'F',   -- flag specifying whether to retrieve descriptions also
	p_office_id_masks      in  varchar2 default null,  -- delimited list of office id masks, defaults to user's office
	p_delimiter            in  varchar2 default ',');  -- delimiter for masks, defaults to comma

--
-- get matching ids in a delimited clob
--
procedure get_matching_ids(
	p_ids                  out clob,                   -- delimited clob of the matching office ids, text ids, and optionally descriptions
	p_id_masks             in  varchar2 default '%',   -- delimited list of id masks, defaults to all ids               
	p_include_descriptions in  varchar2 default 'F',   -- flag specifying whether to retrieve descriptions also
	p_office_id_masks      in  varchar2 default null,  -- delimited list of office id masks, defaults to user's office
	p_delimiter            in  varchar2 default ',');  -- delimiter for masks, defaults to comma

--
-- get code for id
--
procedure get_text_code(
   p_text_code      out number,                 -- the code for use in foreign keys
	p_id             in  varchar2,               -- identifier with which to retrieve text (256 chars max)
	p_office_id      in  varchar2 default null); -- office id, defaults current user's office

--
-- get code for id
--
function get_text_code(
	p_id             in varchar2,               -- identifier with which to retrieve text (256 chars max)
	p_office_id      in varchar2 default null)  -- office id, defaults current user's office
   return number;                              -- the code for use in foreign keys

end;
/

show errors;
commit;