create or replace package cwms_text
/**
 * Facilities for working with text in the database
 */
as
/**
 * Store (insert or update) text to the database
 *
 * @param p_text_code      A unique numeric value that identifies the text
 * @param p_text           The text to store
 * @param p_id             A text identifier for the text to store
 * @param p_description    A description of the text
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the routine should fail if the text identifier already exists in the database
 * @param p_office_id      The office that owns the text. If not specified or NULL, the session user's default office is used
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the text identifier already exists in the database
 */
procedure store_text(
   p_text_code      out number,                 -- the code for use in foreign keys
	p_text           in  clob,                   -- the text, unlimited length
	p_id             in  varchar2,               -- identifier with which to retrieve text (256 chars max)
	p_description    in  varchar2 default null,  -- description, defaults to null
	p_fail_if_exists in  varchar2 default 'T',   -- flag specifying whether to fail if p_id already exists
	p_office_id      in  varchar2 default null); -- office id, defaults current user's office
/**
 * Store (insert or update) text to the database
 *
 * @param p_text           The text to store
 * @param p_id             A text identifier for the text to store
 * @param p_description    A description of the text
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the routine should fail if the text identifier already exists in the database
 * @param p_office_id      The office that owns the text. If not specified or NULL, the session user's default office is used
 *
 * @return A unique numeric value that identifies the text
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the text identifier already exists in the database
 */
function store_text(
	p_text           in clob,                   -- the text, unlimited length
	p_id             in varchar2,               -- identifier with which to retrieve text (256 chars max)
	p_description    in varchar2 default null,  -- description, defaults to null
	p_fail_if_exists in varchar2 default 'T',   -- flag specifying whether to fail if p_id already exists
	p_office_id      in varchar2 default null)  -- office id, defaults current user's office
   return number;                              -- the code for use in foreign keys
/**
 * Store (insert or update) text to the database
 *
 * @param p_text_code      A unique numeric value that identifies the text
 * @param p_text           The text to store
 * @param p_id             A text identifier for the text to store
 * @param p_description    A description of the text
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the routine should fail if the text identifier already exists in the database
 * @param p_office_id      The office that owns the text. If not specified or NULL, the session user's default office is used
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the text identifier already exists in the database
 */
procedure store_text(
   p_text_code      out number,                 -- the code for use in foreign keys
	p_text           in  varchar2,               -- the text, limited to varchar2 max size
	p_id             in  varchar2,               -- identifier with which to retrieve text (256 chars max)
	p_description    in  varchar2 default null,  -- description, defaults to null
	p_fail_if_exists in  varchar2 default 'T',   -- flag specifying whether to fail if p_id already exists
	p_office_id      in  varchar2 default null); -- office id, defaults current user's office
/**
 * Store (insert or update) text to the database
 *
 * @param p_text           The text to store
 * @param p_id             A text identifier for the text to store
 * @param p_description    A description of the text
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the routine should fail if the text identifier already exists in the database
 * @param p_office_id      The office that owns the text. If not specified or NULL, the session user's default office is used
 *
 * @return A unique numeric value that identifies the text
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the text identifier already exists in the database
 */
function store_text(
	p_text           in varchar2,               -- the text, limited to varchar2 max size
	p_id             in varchar2,               -- identifier with which to retrieve text (256 chars max)
	p_description    in varchar2 default null,  -- description, defaults to null
	p_fail_if_exists in varchar2 default 'T',   -- flag specifying whether to fail if p_id already exists
	p_office_id      in varchar2 default null)  -- office id, defaults current user's office
   return number;                              -- the code for use in foreign keys
/**
 * Retrieve text from the database
 *
 * @param p_text      The retrieved text
 * @param p_id        A text identifier of the text to retrieve
 * @param p_office_id The office that owns the text. If not specified or NULL, the session user's default office is used
 */
procedure retrieve_text(
	p_text      out clob,                   -- the text, unlimited length
	p_id        in  varchar2,               -- identifier used to store text (256 chars max)
	p_office_id in  varchar2 default null); -- office id, defaults current user's office
/**
 * Retrieve text from the database
 *
 * @param p_id        A text identifier of the text to retrieve
 * @param p_office_id The office that owns the text. If not specified or NULL, the session user's default office is used
 *
 * @return The retrieved text
 */
function retrieve_text(
	p_id        in  varchar2,              -- identifier used to store text (256 chars max)
	p_office_id in  varchar2 default null) -- office id, defaults current user's office
	return clob;                           -- the text, unlimited length
/**
 * Retrieve text and description from the database
 *
 * @param p_text        The retrieved text
 * @param p_description The retrieved description
 * @param p_id          A text identifier of the text to retrieve
 * @param p_office_id   The office that owns the text. If not specified or NULL, the session user's default office is used
 */
procedure retrieve_text2(
	p_text        out clob,                   -- the text, unlimited length
	p_description out varchar2,               -- the description
	p_id          in  varchar2,               -- identifier used to store text (256 chars max)
	p_office_id   in  varchar2 default null); -- office id, defaults current user's office
/**
 * Update text in the database
 *
 * @param p_text         The text to store
 * @param p_id           A text identifier for the text to store
 * @param p_description  A description of the text
 * @param p_ignore_nulls A flag ('T' or 'F') that specifies whether to ignore NULL values on input ('T') or to update the database with NULL values ('F')
 * @param p_office_id    The office that owns the text. If not specified or NULL, the session user's default office is used
 */
procedure update_text(
	p_text           in clob,                   -- the text, unlimited length
	p_id             in varchar2,               -- identifier of text to update (256 chars max)
	p_description    in varchar2 default null,  -- description, defaults to null
	p_ignore_nulls   in varchar2 default 'T',   -- flag specifying null inputs leave current values unchanged
	p_office_id      in varchar2 default null); -- office id, defaults current user's office
/**
 * Append to text in the database
 *
 * @param p_new_text  The text to append
 * @param p_id        The text identifier for the existing text to append to
 * @param p_office_id The office that owns the text. If not specified or NULL, the session user's default office is used
 */
procedure append_text(
   p_new_text       in out nocopy clob,        -- the text to append, unlimited length
   p_id             in varchar2,               -- identifier of text to append to (256 chars max)
   p_office_id      in varchar2 default null); -- office id, defaults current user's office
/**
 * Append to text in the database
 *
 * @param p_new_text  The text to append
 * @param p_id        The text identifier for the existing text to append to
 * @param p_office_id The office that owns the text. If not specified or NULL, the session user's default office is used
 */
procedure append_text(
   p_new_text       in varchar2,               -- the text to append, limited to varchar2 max size
   p_id             in varchar2,               -- identifier of text to append to (256 chars max)
   p_office_id      in varchar2 default null); -- office id, defaults current user's office
/**
 * Delete text from the database
 *
 * @param p_id        The text identifier for the existing text to delete
 * @param p_office_id The office that owns the text. If not specified or NULL, the session user's default office is used
 */
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