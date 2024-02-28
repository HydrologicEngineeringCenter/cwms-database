
create or replace package cwms_text
/**
 * Facilities for working with text in the database
 */
as
   /**
    * Store (insert or update) binary to the database
    *
    * @param p_binary_code       A unique numeric value that identifies the binary
    * @param p_binary            The binary to store
    * @param p_id                A text identifier for the binary to store
    * @param p_media_type_or_ext The MIME media type or file extension for the binary
    * @param p_description       A description of the binary
    * @param p_fail_if_exists    A flag ('T' or 'F') that specifies whether the routine should fail if the text identifier already exists in the database
    * @param p_ignore_nulls      A flag ('T' or 'F') that specifies whether the routine should ignore null parameters when updating existing an binary
    * @param p_office_id         The office that owns the binary. If not specified or NULL, the session user's default office is used
    *
    * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the text identifier already exists in the database
    */
   procedure store_binary(
      p_binary_code          out number, -- the code for use in foreign keys
      p_binary            in     blob, -- the binary, unlimited length
      p_id                in     varchar2, -- identifier with which to retrieve binary (256 chars max)
      p_media_type_or_ext in     varchar2, -- the MIME media type or file extension
      p_description       in     varchar2 default null, -- description, defaults to null
      p_fail_if_exists    in     varchar2 default 'T', -- flag specifying whether to fail if p_id already exists
      p_ignore_nulls      in     varchar2 default 'T', -- flag specifying whether to ignore null parameters on update
      p_office_id         in     varchar2 default null); -- office id, defaults current user's office

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
      p_text_code         out number, -- the code for use in foreign keys
      p_text           in     clob, -- the text, unlimited length
      p_id             in     varchar2, -- identifier with which to retrieve text (256 chars max)
      p_description    in     varchar2 default null, -- description, defaults to null
      p_fail_if_exists in     varchar2 default 'T', -- flag specifying whether to fail if p_id already exists
      p_office_id      in     varchar2 default null); -- office id, defaults current user's office

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
      p_text           in clob, -- the text, unlimited length
      p_id             in varchar2, -- identifier with which to retrieve text (256 chars max)
      p_description    in varchar2 default null, -- description, defaults to null
      p_fail_if_exists in varchar2 default 'T', -- flag specifying whether to fail if p_id already exists
      p_office_id      in varchar2 default null) -- office id, defaults current user's office
      return number; -- the code for use in foreign keys

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
      p_text_code         out number, -- the code for use in foreign keys
      p_text           in     varchar2, -- the text, limited to varchar2 max size
      p_id             in     varchar2, -- identifier with which to retrieve text (256 chars max)
      p_description    in     varchar2 default null, -- description, defaults to null
      p_fail_if_exists in     varchar2 default 'T', -- flag specifying whether to fail if p_id already exists
      p_office_id      in     varchar2 default null); -- office id, defaults current user's office

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
      p_text           in varchar2, -- the text, limited to varchar2 max size
      p_id             in varchar2, -- identifier with which to retrieve text (256 chars max)
      p_description    in varchar2 default null, -- description, defaults to null
      p_fail_if_exists in varchar2 default 'T', -- flag specifying whether to fail if p_id already exists
      p_office_id      in varchar2 default null) -- office id, defaults current user's office
      return number; -- the code for use in foreign keys

   /**
    * Retrieve binary from the database
    *
    * @param p_binary      The retrieved binary
    * @param p_id          A text identifier of the binary to retrieve
    * @param p_office_id   The office that owns the binary. If not specified or NULL, the session user's default office is used
    */
   procedure retrieve_binary(
      p_binary       out blob, -- the binary, unlimited length
      p_id        in     varchar2, -- identifier used to store binary (256 chars max)
      p_office_id in     varchar2 default null); -- office id, defaults current user's office

   /**
    * Retrieve binary from the database
    *
    * @param p_id          A text identifier of the binary to retrieve
    * @param p_office_id   The office that owns the binary. If not specified or NULL, the session user's default office is used
    *
    * @return      The retrieved binary
    */
   function retrieve_binary(
      p_id        in     varchar2, -- identifier used to store binary (256 chars max)
      p_office_id in     varchar2 default null) -- office id, defaults current user's office
      return blob;

   /**
    * Retrieve binary and associated information from the database
    *
    * @param p_binary      The retrieved binary
    * @param p_description The retrieved description
    * @param p_media_type  The MIME media type of the binary
    * @param p_file_extensions  A comma-separated list of file extensions, if any
    * @param p_id          A text identifier of the binary to retrieve
    * @param p_office_id   The office that owns the binary. If not specified or NULL, the session user's default office is used
    */
   procedure retrieve_binary2(
      p_binary             out blob, -- the binary, unlimited length
      p_description        out varchar2, -- the description
      p_media_type         out varchar2, -- the MIME media type
      p_file_extensions    out varchar2, -- comma-separated list of file extensions, if any
      p_id              in     varchar2, -- identifier used to store binary (256 chars max)
      p_office_id       in     varchar2 default null); -- office id, defaults current user's office

   /**
    * Retrieve text from the database
    *
    * @param p_text      The retrieved text
    * @param p_id        A text identifier of the text to retrieve
    * @param p_office_id The office that owns the text. If not specified or NULL, the session user's default office is used
    */
   procedure retrieve_text(
      p_text      out clob, -- the text, unlimited length
      p_id        in  varchar2, -- identifier used to store text (256 chars max)
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
      p_id        in varchar2, -- identifier used to store text (256 chars max)
      p_office_id in varchar2 default null) -- office id, defaults current user's office
      return clob; -- the text, unlimited length

   /**
    * Retrieve text and description from the database
    *
    * @param p_text        The retrieved text
    * @param p_description The retrieved description
    * @param p_id          A text identifier of the text to retrieve
    * @param p_office_id   The office that owns the text. If not specified or NULL, the session user's default office is used
    */
   procedure retrieve_text2(
      p_text           out clob, -- the text, unlimited length
      p_description    out varchar2, -- the description
      p_id          in     varchar2, -- identifier used to store text (256 chars max)
      p_office_id   in     varchar2 default null); -- office id, defaults current user's office

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
      p_text         in clob, -- the text, unlimited length
      p_id           in varchar2, -- identifier of text to update (256 chars max)
      p_description  in varchar2 default null, -- description, defaults to null
      p_ignore_nulls in varchar2 default 'T', -- flag specifying null inputs leave current values unchanged
      p_office_id    in varchar2 default null); -- office id, defaults current user's office

   /**
    * Append to text in the database
    *
    * @param p_new_text  The text to append
    * @param p_id        The text identifier for the existing text to append to
    * @param p_office_id The office that owns the text. If not specified or NULL, the session user's default office is used
    */
   procedure append_text(p_new_text  in out nocopy clob, -- the text to append, unlimited length
                         p_id        in varchar2, -- identifier of text to append to (256 chars max)
                         p_office_id in varchar2 default null); -- office id, defaults current user's office

   /**
    * Append to text in the database
    *
    * @param p_new_text  The text to append
    * @param p_id        The text identifier for the existing text to append to
    * @param p_office_id The office that owns the text. If not specified or NULL, the session user's default office is used
    */
   procedure append_text(p_new_text  in varchar2, -- the text to append, limited to varchar2 max size
                         p_id        in varchar2, -- identifier of text to append to (256 chars max)
                         p_office_id in varchar2 default null); -- office id, defaults current user's office

   /**
    * Delete a binary from the database
    *
    * @param p_id        The text identifier for the existing binary to delete
    * @param p_office_id The office that owns the binary. If not specified or NULL, the session user's default office is used
    */
   procedure delete_binary(p_id        in varchar2, -- identifier used to store binary (256 chars max)
                           p_office_id in varchar2 default null); -- office id, defaults current user's office

   /**
    * Delete text from the database
    *
    * @param p_id        The text identifier for the existing text to delete
    * @param p_office_id The office that owns the text. If not specified or NULL, the session user's default office is used
    */
   procedure delete_text(p_id        in varchar2, -- identifier used to store text (256 chars max)
                         p_office_id in varchar2 default null); -- office id, defaults current user's office

   --
   -- get matching ids in a cursor
   --
   procedure get_matching_ids(
      p_ids                  in out sys_refcursor, -- cursor of the matching office ids, text ids, and optionally descriptions
      p_id_masks             in     varchar2 default '%', -- delimited list of id masks, defaults to all ids
      p_include_descriptions in     varchar2 default 'F', -- flag specifying whether to retrieve descriptions also
      p_office_id_masks      in     varchar2 default null, -- delimited list of office id masks, defaults to user's office
      p_delimiter            in     varchar2 default ','); -- delimiter for masks, defaults to comma

   --
   -- get matching ids in a delimited clob
   --
   procedure get_matching_ids(
      p_ids                     out clob, -- delimited clob of the matching office ids, text ids, and optionally descriptions
      p_id_masks             in     varchar2 default '%', -- delimited list of id masks, defaults to all ids
      p_include_descriptions in     varchar2 default 'F', -- flag specifying whether to retrieve descriptions also
      p_office_id_masks      in     varchar2 default null, -- delimited list of office id masks, defaults to user's office
      p_delimiter            in     varchar2 default ','); -- delimiter for masks, defaults to comma

   --
   -- get code for id
   --
   procedure get_text_code(p_text_code out number, -- the code for use in foreign keys
                                                  p_id in varchar2, -- identifier with which to retrieve text (256 chars max)
                                                                   p_office_id in varchar2 default null); -- office id, defaults current user's office

   --
   -- get code for id
   --
   function get_text_code(p_id in varchar2, -- identifier with which to retrieve text (256 chars max)
                                           p_office_id in varchar2 default null) -- office id, defaults current user's office
      return number; -- the code for use in foreign keys

   /**
    * Stores (inserts or updates) standard text.  Standard text is text that is expected to be used many times
    * and is identified by a short text identifier.  If the identifier is self-describing, it may exist without
    * descriptive text; otherwise it is used a handle for a longer description.
    *
    * @param p_std_text_id    The standard text identifier. Maximum length is 16 bytes. Case is preserved, but case insensitive uniqueness is required.
    * @param p_std_text       The descriptive text. May be NULL if p_std_text_id is self-descriptive
    * @param p_fail_if_exists A flag ('T' or 'F') specifying whether to fail if p_std_text_id already exists
    * @param p_office_id      The office owning the standard text. If not specified or NULL the session user's default office is used.
    */
   procedure store_std_text(
      p_std_text_id    in varchar2,
      p_std_text       in clob default null,
      p_fail_if_exists in varchar2 default 'T',
      p_office_id      in varchar2 default null);

   /**
    * Retrieves the descriptive text for a standard text identifier
    *
    * @param p_std_text    The descriptive text
    * @param p_std_text_id The standard text identifier to retrieve the description for. This may be owned by p_office_id or the CWMS "office".
    * @param p_office_id   The office owning the standard text. If not specified or NULL the session user's default office is used.
    */
   procedure retrieve_std_text(p_std_text out clob, p_std_text_id in varchar2, p_office_id in varchar2 default null);

   /**
    * Retrieves the descriptive text for a standard text identifier
    *
    * @param p_std_text_id The standard text identifier to retrieve the description for. This may be owned by p_office_id or the CWMS "office".
    * @param p_office_id   The office owning the standard text. If not specified or NULL the session user's default office is used.
    *
    * @return The descriptive text
    */
   function retrieve_std_text_f(p_std_text_id in varchar2, p_office_id in varchar2 default null)
      return clob;

   /**
    * Deletes standard text
    *
    * @see constant cwms_util.delete_key
    * @see constant cwms_util.delete_data
    * @see constant cwms_util.delete_all
    *
    * @param p_std_text_id The standard text identifier to delete
    * @param p_delete_action Specifies what to delete.  Actions are as follows:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">p_delete_action</th>
    *     <th class="descr">Action</th>
    *   </tr>
    *   <tr>
    *     <td class="descr">cwms_util.delete_key</td>
    *     <td class="descr">deletes only the standard text, and then only if it is not used in any time series</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">cwms_util.delete_data</td>
    *     <td class="descr">deletes only the time series references to the standard text</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">cwms_util.delete_all</td>
    *     <td class="descr">deletes the standard text and all time series references to it</td>
    *   </tr>
    * </table>
    * @param p_office_id   The office owning the standard text. If not specified or NULL the session user's default office is used.
    */
   procedure delete_std_text(
      p_std_text_id   in varchar2,
      p_delete_action in varchar2 default cwms_util.delete_key,
      p_office_id     in varchar2 default null);

   /**
    * Catalogs standard text that matches specified criteria. Matching is
    * accomplished with glob-style wildcards, as shown below, instead of sql-style
    * wildcards.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_cusror A cursor containing all matching standard text.  The cursor contains
    * the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the standard text</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">std_text_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The standard text identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">std_text</td>
    *     <td class="descr">clob</td>
    *     <td class="descr">The descriptive text, if any, for the standard text identifier</td>
    *   </tr>
    * </table>
    *
    * @param p_std_text_id_mask The standard text identifier pattern to match. Use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.

    * @param p_office_id_mask The office pattern to match.  If the routine is called
    * without this parameter, or if this parameter is set to NULL, the session user's
    * default office will be used. For matching multiple office, use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    */
   procedure cat_std_text(
      p_cursor              out sys_refcursor,
      p_std_text_id_mask in     varchar2 default '*',
      p_office_id_mask   in     varchar2 default null);

   /**
    * Catalogs standard text that matches specified criteria. Matching is
    * accomplished with glob-style wildcards, as shown below, instead of sql-style
    * wildcards.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_std_text_id_mask The standard text identifier pattern to match. Use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.

    * @param p_office_id_mask The office pattern to match.  If the routine is called
    * without this parameter, or if this parameter is set to NULL, the session user's
    * default office will be used. For matching multiple office, use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @return A cursor containing all matching standard text. The cursor contains
    * the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the standard text</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">std_text_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The standard text identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">std_text</td>
    *     <td class="descr">clob</td>
    *     <td class="descr">The descriptive text, if any, for the standard text identifier</td>
    *   </tr>
    * </table>
    */
   function cat_std_text_f(p_std_text_id_mask in varchar2 default '*', p_office_id_mask in varchar2 default null)
      return sys_refcursor;

   /**
    * Store standard text for all times in a time window to a time series. The text can be:
    * <ul>
    *   <li>associated with a "normal" time series with numeric values and quality codes</li>
    *   <li>associated with a binary time series (base parameter = "Binary") that contains images, documents, etc...</li>
    *   <li>the contents of a text time series (base parameter = "Text")</li>
    * </ul>
    * Unlike a "normal" time series, which can have only one value/quality pair at any time/version date combination,
    * binary and text time series can have multiple entries at each time/version date combination.  Entries are retrieved
    * in the order they are stored.
    *
    * @param p_tsid         The time series identifier
    * @param p_std_text_id  The identifier of the standard text to store.
    * @param p_start_time   The first (or only) time for the text
    * @param p_end_time     The last time for the text. If specified the text is associated with all times from p_start_time to p_end_time (inclusive). Times must already exist for irregular time series.
    * @param p_version_date The version date for the time series.  If not specified or NULL, the minimum or maximum version date (depending on p_max_version) is used.
    * @param p_time_zone    The time zone for p_start_time, p_end_time, and p_version_date. If not specified or NULL, the local time zone of the time series' location is used.
    * @param p_max_version  A flag ('T' or 'F') specifying whether to use the maximum version date if p_version_date is not specifed or NULL.
    * @param p_existing     A flag ('T' or 'F') specifying whether to store the text for times that already exist in the specified time series. Used only for regular time series.
    * @param p_non_existing A flag ('T' or 'F') specifying whether to store the text for times that don't already exist in the specified time series. Used only for regular time series.
    * @param p_replace_all  A flag ('T' or 'F') specifying whether to replace any and all existing standard text with the specified text
    * @param p_attribute    A numeric attribute that can be used for sorting or other purposes
    * @param p_office_id    The office that owns the time series. If not specified or NULL, the session user's default office is used.
    */
   procedure store_ts_std_text(
      p_tsid         in varchar2,
      p_std_text_id  in varchar2,
      p_start_time   in date,
      p_end_time     in date default null,
      p_version_date in date default null,
      p_time_zone    in varchar2 default null,
      p_max_version  in varchar2 default 'T',
      p_existing     in varchar2 default 'T',
      p_non_existing in varchar2 default 'F',
      p_replace_all  in varchar2 default 'F',
      p_attribute    in number default null,
      p_office_id    in varchar2 default null);

   /**
    * Store standard text for specific times in a time series. The text can be:
    * <ul>
    *   <li>associated with a "normal" time series with numeric values and quality codes</li>
    *   <li>associated with a binary time series (base parameter = "Binary") that contains images, documents, etc...</li>
    *   <li>the contents of a text time series (base parameter = "Text")</li>
    * </ul>
    * Unlike a "normal" time series, which can have only one value/quality pair at any time/version date combination,
    * binary and text time series can have multiple entries at each time/version date combination.  Entries are retrieved
    * in the order they are stored.
    *
    * @param p_tsid         The time series identifier
    * @param p_std_text_id  The identifier of the standard text to store.
    * @param p_times        The times for the text
    * @param p_version_date The version date for the time series.  If not specified or NULL, the minimum or maximum version date (depending on p_max_version) is used.
    * @param p_time_zone    The time zone for p_start_time, p_end_time, and p_version_date. If not specified or NULL, the local time zone of the time series' location is used.
    * @param p_max_version  A flag ('T' or 'F') specifying whether to use the maximum version date if p_version_date is not specifed or NULL.
    * @param p_replace_all  A flag ('T' or 'F') specifying whether to replace any and all existing standard text with the specified text
    * @param p_attribute    A numeric attribute that can be used for sorting or other purposes
    * @param p_office_id    The office that owns the time series. If not specified or NULL, the session user's default office is used.
    */
   procedure store_ts_std_text(
      p_tsid         in varchar2,
      p_std_text_id  in varchar2,
      p_times        in date_table_type,
      p_version_date in date default null,
      p_time_zone    in varchar2 default null,
      p_max_version  in varchar2 default 'T',
      p_replace_all  in varchar2 default 'F',
      p_attribute    in number default null,
      p_office_id    in varchar2 default null);

   /**
    * Retrieves standard text that matches specified criteria from a time series.
    * The text can be:
    * <ul>
    *   <li>associated with a "normal" time series with numeric values and quality codes</li>
    *   <li>associated with a binary time series (base parameter = "Binary") that contains images, documents, etc...</li>
    *   <li>the contents of a text time series (base parameter = "Text")</li>
    * </ul>
    * Unlike a "normal" time series, which can have only one value/quality pair at any time/version date combination,
    * binary and text time series can have multiple entries at each time/version date combination.  Entries are retrieved
    * in the order they are stored.
    * Matching is accomplished with glob-style wildcards, as shown below, instead of sql-style
    * wildcards.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_cursor A cursor containing the standard text. The cursor contains the following columns
    * (column 6 is included only if p_retrieve_text is 'T') and is sorted by columns 1, 2, 5, and 3:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">date_time</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The date/time for which the standard text applies. No date/times without standard text are included, even for regular time series.</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">version_date</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The date/time for which the standard text applies. No date/times without standard text are included, even for regular time series.</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">data_entry_date</td>
    *     <td class="descr">timestamp(6)</td>
    *     <td class="descr">The time the standard text was stored</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">std_text_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The standard text identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">attribute</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The numeric attribute, if any, for the standard text identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">std_text</td>
    *     <td class="descr">clob</td>
    *     <td class="descr">The descriptive text, if any, for the standard text identifier</td>
    *   </tr>
    * </table>
    * @param p_tsid             The time series identifier
    * @param p_std_text_id_mask The standard text identifier pattern to match. Use glob-style  wildcard characters as shown above instead of sql-style wildcard characters for pattern  matching.
    * @param p_start_time       The start of the time window
    * @param p_end_time         The end of the time window. If not specified or NULL the time window contains only p_start_time.
    * @param p_version_date     The version date for the time series.  If not specified or NULL, the minimum or maximum version date (depending on p_max_version) is used.
    * @param p_time_zone        The time zone for p_start_time, p_end_time, and p_version_date. If not specified or NULL, the local time zone of the time series' location is used.
    * @param p_max_version      A flag ('T' or 'F') specifying whether to use the maximum version date if p_version_date is not specifed or NULL.
    * @param p_retrieve_text    A flag ('T' or 'F') specifying whether to retrieve descriptive text.
    * @param p_min_attribute    The minimum attribute value to retrieve text for. If not specified or NULL, no minimum value is used.
    * @param p_max_attribute    The maximum attribute value to retrieve text for. If not specified or NULL, no maximum value is used.
    * @param p_office_id        The office that owns the time series. If not specified or NULL, the session user's default office is used.
    */
   procedure retrieve_ts_std_text(
      p_cursor              out sys_refcursor,
      p_tsid             in     varchar2,
      p_std_text_id_mask in     varchar2,
      p_start_time       in     date,
      p_end_time         in     date default null,
      p_version_date     in     date default null,
      p_time_zone        in     varchar2 default null,
      p_max_version      in     varchar2 default 'T',
      p_retrieve_text    in     varchar2 default 'T',
      p_min_attribute    in     number default null,
      p_max_attribute    in     number default null,
      p_office_id        in     varchar2 default null);

   /**
    * Retrieves standard text that match a specified identifier pattern from a time series.
    * The text can be:
    * <ul>
    *   <li>associated with a "normal" time series with numeric values and quality codes</li>
    *   <li>associated with a binary time series (base parameter = "Binary") that contains images, documents, etc...</li>
    *   <li>the contents of a text time series (base parameter = "Text")</li>
    * </ul>
    * Unlike a "normal" time series, which can have only one value/quality pair at any time/version date combination,
    * binary and text time series can have multiple entries at each time/version date combination.  Entries are retrieved
    * in the order they are stored for each time.
    * Matching is accomplished with glob-style wildcards, as shown below, instead of sql-style
    * wildcards.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_tsid             The time series identifier
    * @param p_std_text_id_mask The standard text identifier pattern to match. Use glob-style  wildcard characters as shown above instead of sql-style wildcard characters for pattern  matching.
    * @param p_start_time       The start of the time window
    * @param p_end_time         The end of the time window. If not specified or NULL the time window contains only p_start_time.
    * @param p_version_date     The version date for the time series.  If not specified or NULL, the minimum or maximum version date (depending on p_max_version) is used.
    * @param p_time_zone        The time zone for p_start_time, p_end_time, and p_version_date. If not specified or NULL, the local time zone of the time series' location is used.
    * @param p_max_version      A flag ('T' or 'F') specifying whether to use the maximum version date if p_version_date is not specifed or NULL.
    * @param p_retrieve_text    A flag ('T' or 'F') specifying whether to retrieve descriptive text.
    * @param p_min_attribute    The minimum attribute value to retrieve text for. If not specified or NULL, no minimum value is used.
    * @param p_max_attribute    The maximum attribute value to retrieve text for. If not specified or NULL, no maximum value is used.
    * @param p_office_id        The office that owns the time series. If not specified or NULL, the session user's default office is used.
    *
    * @return A cursor containing the standard text. The cursor contains the following columns
    * (column 6 is included only if p_retrieve_text is 'T') and is sorted by columns 1, 2, 5, and 3:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">date_time</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The date/time for which the standard text applies. No date/times without standard text are included, even for regular time series.</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">version_date</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The date/time for which the standard text applies. No date/times without standard text are included, even for regular time series.</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">data_entry_date</td>
    *     <td class="descr">timestamp(6)</td>
    *     <td class="descr">The time the standard text was stored</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">std_text_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The standard text identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">attribute</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The numeric attribute, if any, for the standard text identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">std_text</td>
    *     <td class="descr">clob</td>
    *     <td class="descr">The descriptive text, if any, for the standard text identifier</td>
    *   </tr>
    * </table>
    */
   function retrieve_ts_std_text_f(
      p_tsid             in varchar2,
      p_std_text_id_mask in varchar2,
      p_start_time       in date,
      p_end_time         in date default null,
      p_version_date     in date default null,
      p_time_zone        in varchar2 default null,
      p_max_version      in varchar2 default 'T',
      p_retrieve_text    in varchar2 default 'T',
      p_min_attribute    in number default null,
      p_max_attribute    in number default null,
      p_office_id        in varchar2 default null)
      return sys_refcursor;

   /**
    * Retrieves the number of standard text items in a time window that matches specified criteria
    * The text can be:
    * <ul>
    *   <li>associated with a "normal" time series with numeric values and quality codes</li>
    *   <li>associated with a binary time series (base parameter = "Binary") that contains images, documents, etc...</li>
    *   <li>the contents of a text time series (base parameter = "Text")</li>
    * </ul>
    * Unlike a "normal" time series, which can have only one value/quality pair at any time/version date combination,
    * binary and text time series can have multiple entries at each time/version date combination.  Entries are retrieved
    * in the order they are stored for each time.
    * Matching is accomplished with glob-style wildcards, as shown below, instead of sql-style
    * wildcards.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_tsid             The time series identifier
    * @param p_std_text_id_mask The standard text identifier pattern to match. Use glob-style  wildcard characters as shown above instead of sql-style wildcard characters for pattern  matching.
    * @param p_start_time       The start of the time window
    * @param p_end_time         The end of the time window. If not specified or NULL the time window contains only p_start_time.
    * @param p_date_times       The specific times to use instead of a time window.
    * @param p_version_date     The version date for the time series.  If not specified or NULL, the minimum or maximum version date (depending on p_max_version) is used.
    * @param p_time_zone        The time zone for p_start_time, p_end_time, and p_version_date. If not specified or NULL, the local time zone of the time series' location is used.
    * @param p_max_version      A flag ('T' or 'F') specifying whether to use the maximum version date if p_version_date is not specifed or NULL.
    * @param p_min_attribute    The minimum attribute value to include in the count. If not specified or NULL, no minimum value is used.
    * @param p_max_attribute    The maximum attribute value to include in the count. If not specified or NULL, no maximum value is used.
    * @param p_office_id        The office that owns the time series. If not specified or NULL, the session user's default office is used.
    *
    * @return The number of standard text items in the time window that matche the specified criteria. This may be more than the number of times in the time window.
    */
   function get_ts_std_text_count(
      p_tsid             in varchar2,
      p_std_text_id_mask in varchar2,
      p_start_time       in date,
      p_end_time         in date default null,
      p_date_times       in date_table_type default null,
      p_version_date     in date default null,
      p_time_zone        in varchar2 default null,
      p_max_version      in varchar2 default 'T',
      p_min_attribute    in number default null,
      p_max_attribute    in number default null,
      p_office_id        in varchar2 default null)
      return pls_integer;

   /**
    * Deletes standard text that match a specified parameters from a time series.
    * The text can be:
    * <ul>
    *   <li>associated with a "normal" time series with numeric values and quality codes</li>
    *   <li>associated with a binary time series (base parameter = "Binary") that contains images, documents, etc...</li>
    *   <li>the contents of a text time series (base parameter = "Text")</li>
    * </ul>
    * Unlike a "normal" time series, which can have only one value/quality pair at any time/version date combination,
    * binary and text time series can have multiple entries at each time/version date combination.  Entries are retrieved
    * in the order they are stored for each time.
    * Matching is accomplished with glob-style wildcards, as shown below, instead of sql-style
    * wildcards.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_tsid             The time series identifier
    * @param p_std_text_id_mask The standard text identifier pattern to match. Use glob-style  wildcard characters as shown above instead of sql-style wildcard characters for pattern  matching.
    * @param p_start_time       The first (or only) time for the text
    * @param p_end_time         The last time for the text. If specified the text associated with all times from p_start_time to p_end_time (inclusive) is deleted.
    * @param p_version_date     The version date for the time series.  If not specified or NULL, the minimum or maximum version date (depending on p_max_version) is used.
    * @param p_time_zone        The time zone for p_start_time, p_end_time, and p_version_date. If not specified or NULL, the local time zone of the time series' location is used.
    * @param p_max_version      A flag ('T' or 'F') specifying whether to use the maximum version date if p_version_date is not specifed or NULL.
    * @param p_min_attribute    The minimum attribute value to delete. If not specified or NULL, no minimum value is used.
    * @param p_max_attribute    The maximum attribute value to delete. If not specified or NULL, no maximum value is used.
    * @param p_office_id        The office that owns the time series. If not specified or NULL, the session user's default office is used.
    */
   procedure delete_ts_std_text(
      p_tsid             in varchar2,
      p_std_text_id_mask in varchar2,
      p_start_time       in date,
      p_end_time         in date default null,
      p_version_date     in date default null,
      p_time_zone        in varchar2 default null,
      p_max_version      in varchar2 default 'T',
      p_min_attribute    in number default null,
      p_max_attribute    in number default null,
      p_office_id        in varchar2 default null);

   /**
    * Store nonstandard text to a time series. The text can be:
    * <ul>
    *   <li>associated with a "normal" time series with numeric values and quality codes</li>
    *   <li>associated with a binary time series (base parameter = "Binary") that contains images, documents, etc...</li>
    *   <li>the contents of a text time series (base parameter = "Text")</li>
    * </ul>
    * Unlike a "normal" time series, which can have only one value/quality pair at any time/version date combination,
    * binary and text time series can have multiple entries at each time/version date combination.  Entries are retrieved
    * in the order they are stored.
    *
    * @param p_tsid         The time series identifier
    * @param p_text         The text to store.
    * @param p_start_time   The first (or only) time for the text
    * @param p_end_time     The last time for the text. If specified the text is associated with all times from p_start_time to p_end_time (inclusive). Times must already exist for irregular time series.
    * @param p_version_date The version date for the time series.  If not specified or NULL, the minimum or maximum version date (depending on p_max_version) is used.
    * @param p_time_zone    The time zone for p_start_time, p_end_time, and p_version_date. If not specified or NULL, the local time zone of the time series' location is used.
    * @param p_max_version  A flag ('T' or 'F') specifying whether to use the maximum version date if p_version_date is not specifed or NULL.
    * @param p_existing     A flag ('T' or 'F') specifying whether to store the text for times that already exist in the specified time series. Used only for regular time series.
    * @param p_non_existing A flag ('T' or 'F') specifying whether to store the text for times that don't already exist in the specified time series. Used only for regular time series.
    * @param p_replace_all  A flag ('T' or 'F') specifying whether to replace any and all existing text with the specified text
    * @param p_attribute    A numeric attribute that can be used for sorting or other purposes
    * @param p_office_id    The office that owns the time series. If not specified or NULL, the session user's default office is used.
    */
   procedure store_ts_text(
      p_tsid         in varchar2,
      p_text         in clob,
      p_start_time   in date,
      p_end_time     in date default null,
      p_version_date in date default null,
      p_time_zone    in varchar2 default null,
      p_max_version  in varchar2 default 'T',
      p_existing     in varchar2 default 'T',
      p_non_existing in varchar2 default 'F',
      p_replace_all  in varchar2 default 'F',
      p_attribute    in number default null,
      p_office_id    in varchar2 default null);

   /**
    * Store nonstandard text to a time series. The text can be:
    * <ul>
    *   <li>associated with a "normal" time series with numeric values and quality codes</li>
    *   <li>associated with a binary time series (base parameter = "Binary") that contains images, documents, etc...</li>
    *   <li>the contents of a text time series (base parameter = "Text")</li>
    * </ul>
    * Unlike a "normal" time series, which can have only one value/quality pair at any time/version date combination,
    * binary and text time series can have multiple entries at each time/version date combination.  Entries are retrieved
    * in the order they are stored.
    *
    * @param p_tsid         The time series identifier
    * @param p_text         The text to store.
    * @param p_times        The times for the text
    * @param p_version_date The version date for the time series.  If not specified or NULL, the minimum or maximum version date (depending on p_max_version) is used.
    * @param p_time_zone    The time zone for p_start_time, p_end_time, and p_version_date. If not specified or NULL, the local time zone of the time series' location is used.
    * @param p_max_version  A flag ('T' or 'F') specifying whether to use the maximum version date if p_version_date is not specifed or NULL.
    * @param p_replace_all  A flag ('T' or 'F') specifying whether to replace any and all existing text with the specified text
    * @param p_attribute    A numeric attribute that can be used for sorting or other purposes
    * @param p_office_id    The office that owns the time series. If not specified or NULL, the session user's default office is used.
    */
   procedure store_ts_text(
      p_tsid         in varchar2,
      p_text         in clob,
      p_times        in date_table_type,
      p_version_date in date default null,
      p_time_zone    in varchar2 default null,
      p_max_version  in varchar2 default 'T',
      p_replace_all  in varchar2 default 'F',
      p_attribute    in number default null,
      p_office_id    in varchar2 default null);

   /**
    * Stores existing time series nonstandard text to a time series. The text can be:
    * <ul>
    *   <li>associated with a "normal" time series with numeric values and quality codes</li>
    *   <li>associated with a binary time series (base parameter = "Binary") that contains images, documents, etc...</li>
    *   <li>the contents of a text time series (base parameter = "Text")</li>
    * </ul>
    * Unlike a "normal" time series, which can have only one value/quality pair at any time/version date combination,
    * binary and text time series can have multiple entries at each time/version date combination.  Entries are retrieved
    * in the order they are stored.
    *
    * @param p_tsid         The time series identifier
    * @param p_text_id      The identifier of the existing time series nonstandard text to associate with the time series, as retrieved from retrieve_ts_text.
    * @param p_start_time   The first (or only) time for the text
    * @param p_end_time     The last time for the text. If specified the text is associated with all times from p_start_time to p_end_time (inclusive). Times must already exist for irregular time series.
    * @param p_version_date The version date for the time series.  If not specified or NULL, the minimum or maximum version date (depending on p_max_version) is used.
    * @param p_time_zone    The time zone for p_start_time, p_end_time, and p_version_date. If not specified or NULL, the local time zone of the time series' location is used.
    * @param p_max_version  A flag ('T' or 'F') specifying whether to use the maximum version date if p_version_date is not specifed or NULL.
    * @param p_existing     A flag ('T' or 'F') specifying whether to store the text for times that already exist in the specified time series. Used only for regular time series.
    * @param p_non_existing A flag ('T' or 'F') specifying whether to store the text for times that don't already exist in the specified time series. Used only for regular time series.
    * @param p_replace_all  A flag ('T' or 'F') specifying whether to replace any and all existing text with the specified text
    * @param p_attribute    A numeric attribute that can be used for sorting or other purposes
    * @param p_office_id    The office that owns the time series. If not specified or NULL, the session user's default office is used.
    */
   procedure store_ts_text_id(
      p_tsid         in varchar2,
      p_text_id      in varchar2,
      p_start_time   in date,
      p_end_time     in date default null,
      p_version_date in date default null,
      p_time_zone    in varchar2 default null,
      p_max_version  in varchar2 default 'T',
      p_existing     in varchar2 default 'T',
      p_non_existing in varchar2 default 'F',
      p_replace_all  in varchar2 default 'F',
      p_attribute    in number default null,
      p_office_id    in varchar2 default null);

   /**
    * Stores existing time series nonstandard text to a time series. The text can be:
    * <ul>
    *   <li>associated with a "normal" time series with numeric values and quality codes</li>
    *   <li>associated with a binary time series (base parameter = "Binary") that contains images, documents, etc...</li>
    *   <li>the contents of a text time series (base parameter = "Text")</li>
    * </ul>
    * Unlike a "normal" time series, which can have only one value/quality pair at any time/version date combination,
    * binary and text time series can have multiple entries at each time/version date combination.  Entries are retrieved
    * in the order they are stored.
    *
    * @param p_tsid         The time series identifier
    * @param p_text_id      The identifier of the existing time series nonstandard text to associate with the time series, as retrieved from retrieve_ts_text.
    * @param p_times        The times for the text
    * @param p_version_date The version date for the time series.  If not specified or NULL, the minimum or maximum version date (depending on p_max_version) is used.
    * @param p_time_zone    The time zone for p_start_time, p_end_time, and p_version_date. If not specified or NULL, the local time zone of the time series' location is used.
    * @param p_max_version  A flag ('T' or 'F') specifying whether to use the maximum version date if p_version_date is not specifed or NULL.
    * @param p_replace_all  A flag ('T' or 'F') specifying whether to replace any and all existing text with the specified text
    * @param p_attribute    A numeric attribute that can be used for sorting or other purposes
    * @param p_office_id    The office that owns the time series. If not specified or NULL, the session user's default office is used.
    */
   procedure store_ts_text_id(
      p_tsid         in varchar2,
      p_text_id      in varchar2,
      p_times        in date_table_type,
      p_version_date in date default null,
      p_time_zone    in varchar2 default null,
      p_max_version  in varchar2 default 'T',
      p_replace_all  in varchar2 default 'F',
      p_attribute    in number default null,
      p_office_id    in varchar2 default null);

   /**
    * Retrieve nonstandard text that matches specified criteria from a time series. The text can be:
    * <ul>
    *   <li>associated with a "normal" time series with numeric values and quality codes</li>
    *   <li>associated with a binary time series (base parameter = "Binary") that contains images, documents, etc...</li>
    *   <li>the contents of a text time series (base parameter = "Text")</li>
    * </ul>
    * Unlike a "normal" time series, which can have only one value/quality pair at any time/version date combination,
    * binary and text time series can have multiple entries at each time/version date combination.  Entries are retrieved
    * in the order they are stored.
    * Matching is accomplished with glob-style wildcards, as shown below, instead of sql-style
    * wildcards.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_cursor A cursor containing the text. The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">date_time</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The date/time for which the text applies. No date/times without text are included, even for regular time series.</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">version_date</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The date/time for which the text applies. No date/times without standard text are included, even for regular time series.</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">data_entry_date</td>
    *     <td class="descr">timestamp(6)</td>
    *     <td class="descr">The time the nonstandard text was stored</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">text_id</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">A unique identifier for the nonstandard text</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">attribute</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The numeric attribute, if any, for the text</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">text</td>
    *     <td class="descr">clob</td>
    *     <td class="descr">The nonstandard text</td>
    *   </tr>
    * </table>
    * @param p_tsid           The time series identifier
    * @param p_text_mask      The text pattern to match. Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
    * @param p_start_time     The start of the time window.
    * @param p_end_time       The end of the time window. If specified the text associated with all times from p_start_time to p_end_time (inclusive) is retrieved.
    * @param p_version_date   The version date for the time series.  If not specified or NULL, the minimum or maximum version date (depending on p_max_version) is used.
    * @param p_time_zone      The time zone for p_start_time, p_end_time, and p_version_date. If not specified or NULL, the local time zone of the time series' location is used.
    * @param p_max_version    A flag ('T' or 'F') specifying whether to use the maximum version date if p_version_date is not specifed or NULL.
    * @param p_min_attribute  The minimum attribute value to retrieve text for. If not specified or NULL, no minimum value is used.
    * @param p_max_attribute  The maximum attribute value to retrieve text for. If not specified or NULL, no maximum value is used.
    * @param p_office_id      The office that owns the time series. If not specified or NULL, the session user's default office is used.
    */
   procedure retrieve_ts_text(
      p_cursor           out sys_refcursor,
      p_tsid          in     varchar2,
      p_text_mask     in     varchar2,
      p_start_time    in     date,
      p_end_time      in     date default null,
      p_version_date  in     date default null,
      p_time_zone     in     varchar2 default null,
      p_max_version   in     varchar2 default 'T',
      p_min_attribute in     number default null,
      p_max_attribute in     number default null,
      p_office_id     in     varchar2 default null);

   /**
    * Retrieve nonstandard text that matches specified criteria from a time series. The text can be:
    * <ul>
    *   <li>associated with a "normal" time series with numeric values and quality codes</li>
    *   <li>associated with a binary time series (base parameter = "Binary") that contains images, documents, etc...</li>
    *   <li>the contents of a text time series (base parameter = "Text")</li>
    * </ul>
    * Unlike a "normal" time series, which can have only one value/quality pair at any time/version date combination,
    * binary and text time series can have multiple entries at each time/version date combination.  Entries are retrieved
    * in the order they are stored.
    * Matching is accomplished with glob-style wildcards, as shown below, instead of sql-style
    * wildcards.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_tsid           The time series identifier
    * @param p_text_mask      The text pattern to match. Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
    * @param p_start_time     The start of the time window.
    * @param p_end_time       The end of the time window. If specified the text associated with all times from p_start_time to p_end_time (inclusive) is retrieved.
    * @param p_version_date   The version date for the time series.  If not specified or NULL, the minimum or maximum version date (depending on p_max_version) is used.
    * @param p_time_zone      The time zone for p_start_time, p_end_time, and p_version_date. If not specified or NULL, the local time zone of the time series' location is used.
    * @param p_max_version    A flag ('T' or 'F') specifying whether to use the maximum version date if p_version_date is not specifed or NULL.
    * @param p_min_attribute  The minimum attribute value to retrieve text for. If not specified or NULL, no minimum value is used.
    * @param p_max_attribute  The maximum attribute value to retrieve text for. If not specified or NULL, no maximum value is used.
    * @param p_office_id      The office that owns the time series. If not specified or NULL, the session user's default office is used.
    *
    * @return A cursor containing the text. The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">date_time</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The date/time for which the text applies. No date/times without text are included, even for regular time series.</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">version_date</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The date/time for which the text applies. No date/times without standard text are included, even for regular time series.</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">data_entry_date</td>
    *     <td class="descr">timestamp(6)</td>
    *     <td class="descr">The time the nonstandard text was stored</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">text_id</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">A unique identifier for the nonstandard text</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">attribute</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The numeric attribute, if any, for the text</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">text</td>
    *     <td class="descr">clob</td>
    *     <td class="descr">The nonstandard text</td>
    *   </tr>
    * </table>
    */
   function retrieve_ts_text_f(
      p_tsid          in varchar2,
      p_text_mask     in varchar2,
      p_start_time    in date,
      p_end_time      in date default null,
      p_version_date  in date default null,
      p_time_zone     in varchar2 default null,
      p_max_version   in varchar2 default 'T',
      p_min_attribute in number default null,
      p_max_attribute in number default null,
      p_office_id     in varchar2 default null)
      return sys_refcursor;

   /**
    * Retrieves the number of times a time series has nonstandard text that matches specified criteria
    * The text can be:
    * <ul>
    *   <li>associated with a "normal" time series with numeric values and quality codes</li>
    *   <li>associated with a binary time series (base parameter = "Binary") that contains images, documents, etc...</li>
    *   <li>the contents of a text time series (base parameter = "Text")</li>
    * </ul>
    * Unlike a "normal" time series, which can have only one value/quality pair at any time/version date combination,
    * binary and text time series can have multiple entries at each time/version date combination.  Entries are retrieved
    * in the order they are stored for each time.
    * Matching is accomplished with glob-style wildcards, as shown below, instead of sql-style
    * wildcards.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_tsid             The time series identifier
    * @param p_text_mask        The text pattern to match. Use glob-style  wildcard characters as shown above instead of sql-style wildcard characters for pattern  matching.
    * @param p_start_time       The start of the time window
    * @param p_end_time         The end of the time window. If not specified or NULL the time window contains only p_start_time.
    * @param p_date_times       The specific times to use instead of a time window.
    * @param p_version_date     The version date for the time series.  If not specified or NULL, the minimum or maximum version date (depending on p_max_version) is used.
    * @param p_time_zone        The time zone for p_start_time, p_end_time, and p_version_date. If not specified or NULL, the local time zone of the time series' location is used.
    * @param p_max_version      A flag ('T' or 'F') specifying whether to use the maximum version date if p_version_date is not specifed or NULL.
    * @param p_min_attribute    The minimum attribute value to include in the count. If not specified or NULL, no minimum value is used.
    * @param p_max_attribute    The maximum attribute value to include in the count. If not specified or NULL, no maximum value is used.
    * @param p_office_id        The office that owns the time series. If not specified or NULL, the session user's default office is used.
    *
    * @return The number of times in the time window that have nonstandard text that matches the specified criteria
    */
   function get_ts_text_count(
      p_tsid          in varchar2,
      p_text_mask     in varchar2,
      p_start_time    in date,
      p_end_time      in date default null,
      p_date_times    in date_table_type default null,
      p_version_date  in date default null,
      p_time_zone     in varchar2 default null,
      p_max_version   in varchar2 default 'T',
      p_min_attribute in number default null,
      p_max_attribute in number default null,
      p_office_id     in varchar2 default null)
      return pls_integer;

   /**
    * Delete nonstandard text that matches specified criteria from a time series. The text can be:
    * <ul>
    *   <li>associated with a "normal" time series with numeric values and quality codes</li>
    *   <li>associated with a binary time series (base parameter = "Binary") that contains images, documents, etc...</li>
    *   <li>the contents of a text time series (base parameter = "Text")</li>
    * </ul>
    * Unlike a "normal" time series, which can have only one value/quality pair at any time/version date combination,
    * binary and text time series can have multiple entries at each time/version date combination.  Entries are retrieved
    * in the order they are stored.
    * Matching is accomplished with glob-style wildcards, as shown below, instead of sql-style
    * wildcards.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_tsid           The time series identifier
    * @param p_text_mask      The text pattern to match. Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
    * @param p_start_time     The start of the time window.
    * @param p_end_time       The end of the time window. If specified the text associated with all times from p_start_time to p_end_time (inclusive) is retrieved.
    * @param p_version_date   The version date for the time series.  If not specified or NULL, the minimum or maximum version date (depending on p_max_version) is used.
    * @param p_time_zone      The time zone for p_start_time, p_end_time, and p_version_date. If not specified or NULL, the local time zone of the time series' location is used.
    * @param p_max_version    A flag ('T' or 'F') specifying whether to use the maximum version date if p_version_date is not specifed or NULL.
    * @param p_min_attribute  The minimum attribute value to delete. If not specified or NULL, no minimum value is used.
    * @param p_max_attribute  The maximum attribute value to delete. If not specified or NULL, no maximum value is used.
    * @param p_office_id      The office that owns the time series. If not specified or NULL, the session user's default office is used.
     */
   procedure delete_ts_text(
      p_tsid          in varchar2,
      p_text_mask     in varchar2,
      p_start_time    in date,
      p_end_time      in date default null,
      p_version_date  in date default null,
      p_time_zone     in varchar2 default null,
      p_max_version   in varchar2 default 'T',
      p_min_attribute in number default null,
      p_max_attribute in number default null,
      p_office_id     in varchar2 default null);

   /**
    * Delete nonstandard text that matches specified criteria from a time series. The text can be:
    * <ul>
    *   <li>associated with a "normal" time series with numeric values and quality codes</li>
    *   <li>associated with a binary time series (base parameter = "Binary") that contains images, documents, etc...</li>
    *   <li>the contents of a text time series (base parameter = "Text")</li>
    * </ul>
    * Unlike a "normal" time series, which can have only one value/quality pair at any time/version date combination,
    * binary and text time series can have multiple entries at each time/version date combination.  Entries are retrieved
    * in the order they are stored.
    *
    * @see constant cwms_util.delete_key
    * @see constant cwms_util.delete_data
    * @see constant cwms_util.delete_all
    *
    * @param p_text_id The unique identifier for the nonstandard text as retrieved in retrieve_ts_text.
    * @param p_delete_action Specifies what to delete.  Actions are as follows:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">p_delete_action</th>
    *     <th class="descr">Action</th>
    *   </tr>
    *   <tr>
    *     <td class="descr">cwms_util.delete_key</td>
    *     <td class="descr">deletes only the text, and then only if it is not used in any time series</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">cwms_util.delete_data</td>
    *     <td class="descr">deletes only the time series references to the text</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">cwms_util.delete_all</td>
    *     <td class="descr">deletes the text and all time series references to it</td>
    *   </tr>
    * </table>
    * @param p_office_id The office that owns the nonstandard text to delete.
    */
   procedure delete_ts_text(
      p_text_id       in varchar2,
      p_delete_action in varchar2 default cwms_util.delete_key,
      p_office_id     in varchar2);

   /**
    * Store binary data to a time series. The binary data can be:
    * <ul>
    *   <li>associated with a "normal" time series with numeric values and quality codes</li>
    *   <li>associated with a text time series (base parameter = "Text")</li>
    *   <li>the contents of a binary time series (base parameter = "Binary") that contains images, documents, etc...</li>
    * </ul>
    * Unlike a "normal" time series, which can have only one value/quality pair at any time/version date combination,
    * binary and text time series can have multiple entries at each time/version date combination.  Entries are retrieved
    * in the order they are stored.
    *
    * @param p_tsid         The time series identifier
    * @param p_binary       The binary data to store.
    * @param p_binary_type  The data type expressed as either an internet media type (e.g. 'application/pdf') or a file extension (e.g. '.pdf')
    * @param p_start_time   The first (or only) time for the for the binary data
    * @param p_end_time     The last time for the binary data. If specified the binary data is associated with all times from p_start_time to p_end_time (inclusive). Times must already exist for irregular time series.
    * @param p_version_date The version date for the time series.  If not specified or NULL, the minimum or maximum version date (depending on p_max_version) is used.
    * @param p_time_zone    The time zone for p_start_time, p_end_time, and p_version_date. If not specified or NULL, the local time zone of the time series' location is used.
    * @param p_max_version  A flag ('T' or 'F') specifying whether to use the maximum version date if p_version_date is not specifed or NULL.
    * @param p_existing     A flag ('T' or 'F') specifying whether to store the binary data for times that already exist in the specified time series. Used only for regular time series.
    * @param p_non_existing A flag ('T' or 'F') specifying whether to store the binary data for times that don't already exist in the specified time series. Used only for regular time series.
    * @param p_replace_all  A flag ('T' or 'F') specifying whether to replace any and all existing text with the specified text
    * @param p_attribute    A numeric attribute that can be used for sorting or other purposes
    * @param p_office_id    The office that owns the time series. If not specified or NULL, the session user's default office is used.
    */
   procedure store_ts_binary(
      p_tsid         in varchar2,
      p_binary       in blob,
      p_binary_type  in varchar2,
      p_start_time   in date,
      p_end_time     in date default null,
      p_version_date in date default null,
      p_time_zone    in varchar2 default null,
      p_max_version  in varchar2 default 'T',
      p_existing     in varchar2 default 'T',
      p_non_existing in varchar2 default 'F',
      p_replace_all  in varchar2 default 'F',
      p_attribute    in number default null,
      p_office_id    in varchar2 default null);

   /**
    * Store binary data to a time series. The binary data can be:
    * <ul>
    *   <li>associated with a "normal" time series with numeric values and quality codes</li>
    *   <li>associated with a text time series (base parameter = "Text")</li>
    *   <li>the contents of a binary time series (base parameter = "Binary") that contains images, documents, etc...</li>
    * </ul>
    * Unlike a "normal" time series, which can have only one value/quality pair at any time/version date combination,
    * binary and text time series can have multiple entries at each time/version date combination.  Entries are retrieved
    * in the order they are stored.
    *
    * @param p_tsid         The time series identifier
    * @param p_binary       The binary data to store.
    * @param p_binary_type  The data type expressed as either an internet media type (e.g. 'application/pdf') or a file extension (e.g. '.pdf')
    * @param p_times        The times for the for the binary data
    * @param p_version_date The version date for the time series.  If not specified or NULL, the minimum or maximum version date (depending on p_max_version) is used.
    * @param p_time_zone    The time zone for p_start_time, p_end_time, and p_version_date. If not specified or NULL, the local time zone of the time series' location is used.
    * @param p_max_version  A flag ('T' or 'F') specifying whether to use the maximum version date if p_version_date is not specifed or NULL.
    * @param p_replace_all  A flag ('T' or 'F') specifying whether to replace any and all existing binary data with the specified text
    * @param p_attribute    A numeric attribute that can be used for sorting or other purposes
    * @param p_office_id    The office that owns the time series. If not specified or NULL, the session user's default office is used.
    */
   procedure store_ts_binary(
      p_tsid         in varchar2,
      p_binary       in blob,
      p_binary_type  in varchar2,
      p_times        in date_table_type,
      p_version_date in date default null,
      p_time_zone    in varchar2 default null,
      p_max_version  in varchar2 default 'T',
      p_replace_all  in varchar2 default 'F',
      p_attribute    in number default null,
      p_office_id    in varchar2 default null);

   /**
    * Stores existing time series binary data to a time series. The binary data can be:
    * <ul>
    *   <li>associated with a "normal" time series with numeric values and quality codes</li>
    *   <li>associated with a text time series (base parameter = "Text")</li>
    *   <li>the contents of a binary time series (base parameter = "Binary") that contains images, documents, etc...</li>
    * </ul>
    * Unlike a "normal" time series, which can have only one value/quality pair at any time/version date combination,
    * binary and text time series can have multiple entries at each time/version date combination.  Entries are retrieved
    * in the order they are stored.
    *
    * @param p_tsid         The time series identifier
    * @param p_binary_id    The unique identifier for the existing time series binary data as retrieved in retrieve_ts_binary.
    * @param p_start_time   The first (or only) time for the for the binary data
    * @param p_end_time     The last time for the binary data. If specified the binary data is associated with all times from p_start_time to p_end_time (inclusive). Times must already exist for irregular time series.
    * @param p_version_date The version date for the time series.  If not specified or NULL, the minimum or maximum version date (depending on p_max_version) is used.
    * @param p_time_zone    The time zone for p_start_time, p_end_time, and p_version_date. If not specified or NULL, the local time zone of the time series' location is used.
    * @param p_max_version  A flag ('T' or 'F') specifying whether to use the maximum version date if p_version_date is not specifed or NULL.
    * @param p_existing     A flag ('T' or 'F') specifying whether to store the binary data for times that already exist in the specified time series. Used only for regular time series.
    * @param p_non_existing A flag ('T' or 'F') specifying whether to store the binary data for times that don't already exist in the specified time series. Used only for regular time series.
    * @param p_replace_all  A flag ('T' or 'F') specifying whether to replace any and all existing text with the specified text
    * @param p_attribute    A numeric attribute that can be used for sorting or other purposes
    * @param p_office_id    The office that owns the time series. If not specified or NULL, the session user's default office is used.
    */
   procedure store_ts_binary_id(
      p_tsid         in varchar2,
      p_binary_id    in varchar2,
      p_start_time   in date,
      p_end_time     in date default null,
      p_version_date in date default null,
      p_time_zone    in varchar2 default null,
      p_max_version  in varchar2 default 'T',
      p_existing     in varchar2 default 'T',
      p_non_existing in varchar2 default 'F',
      p_replace_all  in varchar2 default 'F',
      p_attribute    in number default null,
      p_office_id    in varchar2 default null);

   /**
    * Stores existing time series binary data to a time series. The binary data can be:
    * <ul>
    *   <li>associated with a "normal" time series with numeric values and quality codes</li>
    *   <li>associated with a text time series (base parameter = "Text")</li>
    *   <li>the contents of a binary time series (base parameter = "Binary") that contains images, documents, etc...</li>
    * </ul>
    * Unlike a "normal" time series, which can have only one value/quality pair at any time/version date combination,
    * binary and text time series can have multiple entries at each time/version date combination.  Entries are retrieved
    * in the order they are stored.
    *
    * @param p_tsid         The time series identifier
    * @param p_binary_id    The unique identifier for the existing time series binary data as retrieved in retrieve_ts_binary.
    * @param p_times        The times for the for the binary data
    * @param p_version_date The version date for the time series.  If not specified or NULL, the minimum or maximum version date (depending on p_max_version) is used.
    * @param p_time_zone    The time zone for p_start_time, p_end_time, and p_version_date. If not specified or NULL, the local time zone of the time series' location is used.
    * @param p_max_version  A flag ('T' or 'F') specifying whether to use the maximum version date if p_version_date is not specifed or NULL.
    * @param p_replace_all  A flag ('T' or 'F') specifying whether to replace any and all existing binary data with the specified text
    * @param p_attribute    A numeric attribute that can be used for sorting or other purposes
    * @param p_office_id    The office that owns the time series. If not specified or NULL, the session user's default office is used.
    */
   procedure store_ts_binary_id(
      p_tsid         in varchar2,
      p_binary_id    in varchar2,
      p_times        in date_table_type,
      p_version_date in date default null,
      p_time_zone    in varchar2 default null,
      p_max_version  in varchar2 default 'T',
      p_replace_all  in varchar2 default 'F',
      p_attribute    in number default null,
      p_office_id    in varchar2 default null);

   /**
    * Retrieve binary data that matches a specified criteria from a time series. The binary data can be:
    * <ul>
    *   <li>associated with a "normal" time series with numeric values and quality codes</li>
    *   <li>associated with a text time series (base parameter = "Text")</li>
    *   <li>the contents of a binary time series (base parameter = "Binary") that contains images, documents, etc...</li>
    * </ul>
    * Unlike a "normal" time series, which can have only one value/quality pair at any time/version date combination,
    * binary and text time series can have multiple entries at each time/version date combination.  Entries are retrieved
    * in the order they are stored.
    * Matching is accomplished with glob-style wildcards, as shown below, instead of sql-style
    * wildcards.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_cursor A cursor containing the binary data. The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">date_time</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The date/time for which the text applies. No date/times without text are included, even for regular time series.</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">version_date</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The date/time for which the standard text applies. No date/times without standard text are included, even for regular time series.</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">data_entry_date</td>
    *     <td class="descr">timestamp(6)</td>
    *     <td class="descr">The time the nonstandard text was stored</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">binary_id</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">A unique identifier for the binary data</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">attribute</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The numeric attribute, if any, for the binary data</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">file_extension</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The file extension of the binary data</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">7</td>
    *     <td class="descr">media_type</td>
    *     <td class="descr">varchar2(84)</td>
    *     <td class="descr">The internet media type of the binary data</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">8</td>
    *     <td class="descr">binary_data</td>
    *     <td class="descr">blob</td>
    *     <td class="descr">The binary data. Only present if p_retrieve_binary is 'T'</td>
    *   </tr>
    * </table>
    * @param p_tsid             The time series identifier
    * @param p_binary_type_mask The data type pattern expressed as either an internet media type (e.g. 'image/*') or a file extension (e.g. '.*').
    *                           Since a media type may be associated with multiple file extensions, if the pattern matches one or more file extensions,
    *                           p_cursor will only contain items that match the matched file extension(s). If the pattern does not match any
    *                           file extension, p_cursor will include all file extensions associated with the matched media type.
    *                           Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
    * @param p_start_time       The start of the time window
    * @param p_end_time         The end of the time window. If specified the binary data associated with all times from p_start_time to p_end_time (inclusive) is retrieved.
    * @param p_version_date     The version date for the time series.  If not specified or NULL, the minimum or maximum version date (depending on p_max_version) is used.
    * @param p_time_zone        The time zone for p_start_time, p_end_time, and p_version_date. If not specified or NULL, the local time zone of the time series' location is used.
    * @param p_max_version      A flag ('T' or 'F') specifying whether to use the maximum version date if p_version_date is not specifed or NULL.
    * @param p_retreive_binary  A flag ('T' or 'F') specifying whether to retrieve the actual binary data.
    * @param p_min_attribute    The minimum attribute value to retrieve binary data for. If not specified or NULL, no minimum value is used.
    * @param p_max_attribute    The maximum attribute value to retrieve binary data for. If not specified or NULL, no maximum value is used.
    * @param p_office_id        The office that owns the time series. If not specified or NULL, the session user's default office is used.
    */
   procedure retrieve_ts_binary(
      p_cursor              out sys_refcursor,
      p_tsid             in     varchar2,
      p_binary_type_mask in     varchar2,
      p_start_time       in     date,
      p_end_time         in     date default null,
      p_version_date     in     date default null,
      p_time_zone        in     varchar2 default null,
      p_max_version      in     varchar2 default 'T',
      p_retrieve_binary  in     varchar2 default 'T',
      p_min_attribute    in     number default null,
      p_max_attribute    in     number default null,
      p_office_id        in     varchar2 default null);

   /**
    * Retrieve binary data that matches a specified type pattern from a time series. The binary data can be:
    * <ul>
    *   <li>associated with a "normal" time series with numeric values and quality codes</li>
    *   <li>associated with a text time series (base parameter = "Text")</li>
    *   <li>the contents of a binary time series (base parameter = "Binary") that contains images, documents, etc...</li>
    * </ul>
    * Unlike a "normal" time series, which can have only one value/quality pair at any time/version date combination,
    * binary and text time series can have multiple entries at each time/version date combination.  Entries are retrieved
    * in the order they are stored.
    * Matching is accomplished with glob-style wildcards, as shown below, instead of sql-style
    * wildcards.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_tsid             The time series identifier
    * @param p_binary_type_mask The data type pattern expressed as either an internet media type (e.g. 'image/*') or a file extension (e.g. '.*').
    *                           Since a media type may be associated with multiple file extensions, if the pattern matches one or more file extensions,
    *                           the returned cursor will only contain items that match the matched file extension(s). If the pattern does not match any
    *                           file extension, the returned cursor will include all file extensions associated with the matched media type.
    *                           Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
    * @param p_start_time       The start of the time window
    * @param p_end_time         The end of the time window. If specified the binary data associated with all times from p_start_time to p_end_time (inclusive) is retrieved.
    * @param p_version_date     The version date for the time series.  If not specified or NULL, the minimum or maximum version date (depending on p_max_version) is used.
    * @param p_time_zone        The time zone for p_start_time, p_end_time, and p_version_date. If not specified or NULL, the local time zone of the time series' location is used.
    * @param p_max_version      A flag ('T' or 'F') specifying whether to use the maximum version date if p_version_date is not specifed or NULL.
    * @param p_retreive_binary  A flag ('T' or 'F') specifying whether to retrieve the actual binary data.
    * @param p_min_attribute    The minimum attribute value to retrieve binary data for. If not specified or NULL, no minimum value is used.
    * @param p_max_attribute    The maximum attribute value to retrieve binary data for. If not specified or NULL, no maximum value is used.
    * @param p_office_id        The office that owns the time series. If not specified or NULL, the session user's default office is used.
    *
    * @return A cursor containing the binary data. The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">date_time</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The date/time for which the text applies. No date/times without text are included, even for regular time series.</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">version_date</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The date/time for which the standard text applies. No date/times without standard text are included, even for regular time series.</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">data_entry_date</td>
    *     <td class="descr">timestamp(6)</td>
    *     <td class="descr">The time the nonstandard text was stored</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">binary_id</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">A unique identifier for the binary data</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">attribute</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The numeric attribute, if any, for the binary data</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">file_extension</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The file extension of the binary data</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">7</td>
    *     <td class="descr">media_type</td>
    *     <td class="descr">varchar2(84)</td>
    *     <td class="descr">The internet media type of the binary data</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">8</td>
    *     <td class="descr">binary_data</td>
    *     <td class="descr">blob</td>
    *     <td class="descr">The binary data. Only present if p_retrieve_binary is 'T'</td>
    *   </tr>
    * </table>
    */
   function retrieve_ts_binary_f(
      p_tsid             in varchar2,
      p_binary_type_mask in varchar2,
      p_start_time       in date,
      p_end_time         in date default null,
      p_version_date     in date default null,
      p_time_zone        in varchar2 default null,
      p_max_version      in varchar2 default 'T',
      p_retrieve_binary  in varchar2 default 'T',
      p_min_attribute    in number default null,
      p_max_attribute    in number default null,
      p_office_id        in varchar2 default null)
      return sys_refcursor;

   /**
    * Retrieves the number of times a time series has binary data that matches specified criteria
    * The text can be:
    * <ul>
    *   <li>associated with a "normal" time series with numeric values and quality codes</li>
    *   <li>associated with a binary time series (base parameter = "Binary") that contains images, documents, etc...</li>
    *   <li>the contents of a text time series (base parameter = "Text")</li>
    * </ul>
    * Unlike a "normal" time series, which can have only one value/quality pair at any time/version date combination,
    * binary and text time series can have multiple entries at each time/version date combination.  Entries are retrieved
    * in the order they are stored for each time.
    * Matching is accomplished with glob-style wildcards, as shown below, instead of sql-style
    * wildcards.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_tsid             The time series identifier
    * @param p_binary_type_mask The data type pattern expressed as either an internet media type (e.g. 'image/*') or a file extension (e.g. '.*').
    *                           Since a media type may be associated with multiple file extensions, if the pattern matches one or more file extensions,
    *                           the returned count will only include items that match the matched file extension(s). If the pattern does not match any
    *                           file extension, the returned count will include all file extensions associated with the matched media type.
    *                           Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
    * @param p_start_time       The start of the time window
    * @param p_end_time         The end of the time window. If not specified or NULL the time window contains only p_start_time.
    * @param p_date_times       The specific times to use instead of a time window.
    * @param p_version_date     The version date for the time series.  If not specified or NULL, the minimum or maximum version date (depending on p_max_version) is used.
    * @param p_time_zone        The time zone for p_start_time, p_end_time, and p_version_date. If not specified or NULL, the local time zone of the time series' location is used.
    * @param p_max_version      A flag ('T' or 'F') specifying whether to use the maximum version date if p_version_date is not specifed or NULL.
    * @param p_min_attribute    The minimum attribute value to include in the count. If not specified or NULL, no minimum value is used.
    * @param p_max_attribute    The maximum attribute value to include in the count. If not specified or NULL, no maximum value is used.
    * @param p_office_id        The office that owns the time series. If not specified or NULL, the session user's default office is used.
    *
    * @return The number of times in the time window that have binary data that matches the specified criteria
    */
   function get_ts_binary_count(
      p_tsid             in varchar2,
      p_binary_type_mask in varchar2,
      p_start_time       in date,
      p_end_time         in date default null,
      p_date_times       in date_table_type default null,
      p_version_date     in date default null,
      p_time_zone        in varchar2 default null,
      p_max_version      in varchar2 default 'T',
      p_min_attribute    in number default null,
      p_max_attribute    in number default null,
      p_office_id        in varchar2 default null)
      return pls_integer;

   /**
    * Deletes binary data that matches a specified criteria from a time series. The binary data can be:
    * <ul>
    *   <li>associated with a "normal" time series with numeric values and quality codes</li>
    *   <li>associated with a text time series (base parameter = "Text")</li>
    *   <li>the contents of a binary time series (base parameter = "Binary") that contains images, documents, etc...</li>
    * </ul>
    * Unlike a "normal" time series, which can have only one value/quality pair at any time/version date combination,
    * binary and text time series can have multiple entries at each time/version date combination.  Entries are retrieved
    * in the order they are stored.
    * Matching is accomplished with glob-style wildcards, as shown below, instead of sql-style
    * wildcards.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_tsid             The time series identifier
    * @param p_binary_type_mask The data type pattern expressed as either an internet media type (e.g. 'image/&asterisk;') or a file extension (e.g. '.*'). Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
    * @param p_start_time       The start of the time window
    * @param p_end_time         The end of the time window. If specified the binary data associated with all times from p_start_time to p_end_time (inclusive) is deleted.
    * @param p_version_date     The version date for the time series.  If not specified or NULL, the minimum or maximum version date (depending on p_max_version) is used.
    * @param p_time_zone        The time zone for p_start_time, p_end_time, and p_version_date. If not specified or NULL, the local time zone of the time series' location is used.
    * @param p_max_version      A flag ('T' or 'F') specifying whether to use the maximum version date if p_version_date is not specifed or NULL.
    * @param p_min_attribute    The minimum attribute value to delete. If not specified or NULL, no minimum value is used.
    * @param p_max_attribute    The maximum attribute value to delete. If not specified or NULL, no maximum value is used.
    * @param p_office_id        The office that owns the time series. If not specified or NULL, the session user's default office is used.
    */
   procedure delete_ts_binary(
      p_tsid             in varchar2,
      p_binary_type_mask in varchar2,
      p_start_time       in date,
      p_end_time         in date default null,
      p_version_date     in date default null,
      p_time_zone        in varchar2 default null,
      p_max_version      in varchar2 default 'T',
      p_min_attribute    in number default null,
      p_max_attribute    in number default null,
      p_office_id        in varchar2 default null);

   /**
    * Delete binary data from a time series. The binary data can be:
    * <ul>
    *   <li>associated with a "normal" time series with numeric values and quality codes</li>
    *   <li>associated with a binary time series (base parameter = "Binary") that contains images, documents, etc...</li>
    *   <li>the contents of a text time series (base parameter = "Text")</li>
    * </ul>
    * Unlike a "normal" time series, which can have only one value/quality pair at any time/version date combination,
    * binary and text time series can have multiple entries at each time/version date combination.  Entries are retrieved
    * in the order they are stored.
    *
    * @see constant cwms_util.delete_key
    * @see constant cwms_util.delete_data
    * @see constant cwms_util.delete_all
    *
    * @param p_binary_id The unique identifier for the binary data as retrieved in retrieve_ts_binary.
    * @param p_delete_action Specifies what to delete.  Actions are as follows:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">p_delete_action</th>
    *     <th class="descr">Action</th>
    *   </tr>
    *   <tr>
    *     <td class="descr">cwms_util.delete_key</td>
    *     <td class="descr">deletes only the binary data, and then only if it is not used in any time series</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">cwms_util.delete_data</td>
    *     <td class="descr">deletes only the time series references to the binary data</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">cwms_util.delete_all</td>
    *     <td class="descr">deletes the binary data and all time series references to it</td>
    *   </tr>
    * </table>
    * @param p_office_id The office that owns the binary data to delete.
    */
   procedure delete_ts_binary(
      p_binary_id     in varchar2,
      p_delete_action in varchar2 default cwms_util.delete_key,
      p_office_id     in varchar2 default null);

   /**
    * Stores a file extension and associates it with a specific media type for an office.
    *
    * @param p_file_extension The file extension.  Only the portion after the last '.' character, if present, is used
    * @param p_media_type     The CWMS media type to associate the file extension with.
    * @param p_fail_if_exists A flag ('T' or 'F') specifying whether to abort if the specified file extension already exists
    * @param p_office_id      The office owning the file extension.  If not specified or NULL, the session user's default office will be used.
    */
   procedure store_file_extension(
      p_file_extension in varchar2,
      p_media_type     in varchar2,
      p_fail_if_exists in varchar2 default 'T',
      p_office_id      in varchar2 default null);

   /**
    * Deletes a file extension for an office.
    *
    * @param p_file_extension The file extension.  Only the portion after the last '.' character, if present, is used
    * @param p_office_id      The office owning the file extension.  If not specified or NULL, the session user's default office will be used.
    */
   procedure delete_file_extension(p_file_extension in varchar2, p_office_id in varchar2 default null);

   /**
    * Catalogs file extensions and associated media types matching a specified mask. Matching is
    * accomplished with glob-style wildcards, as shown below, instead of sql-style
    * wildcards.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_cusror A cursor containing all matching file extensions.  The cursor contains
    * the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the file extension</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">file_extension</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The matching file extension</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">media_type</td>
    *     <td class="descr">varchar2(84)</td>
    *     <td class="descr">The media type associated with the file extension</td>
    *   </tr>
    * </table>
    *
    * @param p_file_extension_mask The file extension pattern to mask. Only the portion after the
    * last '.' character (if any) will be used.  Use glob-style wildcard characters as shown above
    * instead of sql-style wildcard characters for pattern matching.
    *
    * @param p_office_id_mask The office pattern to match.  If the routine is called
    * without this parameter, or if this parameter is set to NULL, the session user's
    * default office will be used. For matching multiple office, use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    */
   procedure cat_file_extensions(
      p_cursor                 out sys_refcursor,
      p_file_extension_mask in     varchar2 default '*',
      p_office_id_mask      in     varchar2 default null);

   /**
    * Catalogs file extensions and associated media types matching a specified mask. Matching is
    * accomplished with glob-style wildcards, as shown below, instead of sql-style
    * wildcards.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_file_extension_mask The file extension pattern to mask. Only the portion after the
    * last '.' character (if any) will be used.  Use glob-style wildcard characters as shown above
    * instead of sql-style wildcard characters for pattern matching.
    *
    * @param p_office_id_mask The office pattern to match.  If the routine is called
    * without this parameter, or if this parameter is set to NULL, the session user's
    * default office will be used. For matching multiple office, use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @return A cursor containing all matching file extensions.  The cursor contains
    * the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the file extension</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">file_extension</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The matching file extension</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">media_type</td>
    *     <td class="descr">varchar2(84)</td>
    *     <td class="descr">The media type associated with the file extension</td>
    *   </tr>
    * </table>
    */
   function cat_file_extensions_f(p_file_extension_mask in varchar2 default '*', p_office_id_mask in varchar2 default null)
      return sys_refcursor;

   /**
    * Catalogs media types and associated file extensions matching a specified mask. Matching is
    * accomplished with glob-style wildcards, as shown below, instead of sql-style
    * wildcards.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_cusror A cursor containing all matching file extensions.  The cursor contains
    * the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the file extension</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">media_type</td>
    *     <td class="descr">varchar2(84)</td>
    *     <td class="descr">The matching media type</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">file_extension</td>
    *     <td class="descr">varchar2(84)</td>
    *     <td class="descr">The file extension associated with the media type</td>
    *   </tr>
    * </table>
    *
    * @param p_media_type_mask The media type pattern to mask. Use glob-style wildcard characters as shown above
    * instead of sql-style wildcard characters for pattern matching.
    *
    * @param p_office_id_mask The office pattern to match.  If the routine is called
    * without this parameter, or if this parameter is set to NULL, the session user's
    * default office will be used. For matching multiple office, use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    */
   procedure cat_media_types(
      p_cursor             out sys_refcursor,
      p_media_type_mask in     varchar2 default '*',
      p_office_id_mask  in     varchar2 default null);

   /**
    * Catalogs media types and associated file extensions matching a specified mask. Matching is
    * accomplished with glob-style wildcards, as shown below, instead of sql-style
    * wildcards.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_media_type_mask The media type pattern to mask. Use glob-style wildcard characters as shown above
    * instead of sql-style wildcard characters for pattern matching.
    *
    * @param p_office_id_mask The office pattern to match.  If the routine is called
    * without this parameter, or if this parameter is set to NULL, the session user's
    * default office will be used. For matching multiple office, use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @return A cursor containing all matching file extensions.  The cursor contains
    * the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the file extension</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">media_type</td>
    *     <td class="descr">varchar2(84)</td>
    *     <td class="descr">The matching media type</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">file_extension</td>
    *     <td class="descr">varchar2(84)</td>
    *     <td class="descr">The file extension associated with the media type</td>
    *   </tr>
    * </table>
    */
   function cat_media_types_f(p_media_type_mask in varchar2 default '*', p_office_id_mask in varchar2 default null)
      return sys_refcursor;

   /**
    * Stores a text filter to the database
    *
    * @param p_text_filter_id  The text identifier (name) of the text filter to store. May be up to 32 characters.
    * @param p_description     Description of the text filter and/or its use. May be up to 256 characters.
    * @param p_text_filter     The text filter elements.  Each element is a string composed of the following items concatenated together:
    * <p>
    * <table class="descr">
    *   <tr>
    *    <th class="descr">Item</th>
    *    <th class="descr">Usage</th>
    *    <th class="descr">Format</th>
    *    <th class="descr">Examples</th>
    *   </tr>
    *   <tr>
    *    <td class="descr">Inclusion</td>
    *    <td class="descr">Required</td>
    *    <td class="descr">"INCLUDE:" or "EXCLUDE:" (any case, may be abbreviated)</td>
    *    <td class="descr"><ul><li>in:</li><li>EXCL:</li><li>I:</li></ul></td>
    *   </tr>
    *   <tr>
    *    <td class="descr">Element-specific regex flags</td>
    *    <td class="descr">Optional</td>
    *    <td class="descr">"FLAGS=&lt;flags&gt;:" (any case, may be abbreviated)</td>
    *    <td class="descr"><ul><li>FLAGS=IM:</li><li>f=n:</li></ul></td>
    *   </tr>
    *   <tr>
    *    <td class="descr">Filter text</td>
    *    <td class="descr">Required</td>
    *    <td class="descr">One of:<ul><li>glob-style wildcard mask (uses * and ?)</li><li>Oracle regular expression</li></ul></td>
    *    <td class="descr"></td>
    *   </tr>
    * </table>
    * @param p_fail_if_exists  A flag (T/F) specifying whether to fail if a text filter of the same name already exists. F = overwrite any existing text filter
    * @param p_uses_regex      A flag (T/F) specifying whether the text filter uses regular expressions. F = filter uses glob-style wildcards (*, ?)
    * @param p_regex_flags     The regular expression flags (Oracle match parameter) to use with all elements. Can be overridden by specific element flags.
    * @param p_office_id       The text identifier of the office that owns the text filter.  If not specified or NULL, the session user's default office is used.
    */
   procedure store_text_filter(
      p_text_filter_id in varchar2,
      p_description    in varchar2,
      p_text_filter    in str_tab_t,
      p_fail_if_exists in varchar2 default 'T',
      p_uses_regex     in varchar2 default 'F',
      p_regex_flags    in varchar2 default null,
      p_office_id      in varchar2 default null);

   /**
    * Stores a text filter to the database
    *
    * @param p_text_filter_id    The text identifier (name) of the text filter to store. May be up to 32 characters.
    * @param p_description       Description of the text filter and/or its use. May be up to 256 characters.
    * @param p_configuration_id  The text identifier (name) of the configuration this text filter belongs to. If unknown or not important, use the other signature of this procedure.
    * @param p_text_filter       The text filter elements.  Each element is a string composed of the following items concatenated together:
    * <p>
    * <table class="descr">
    *   <tr>
    *    <th class="descr">Item</th>
    *    <th class="descr">Usage</th>
    *    <th class="descr">Format</th>
    *    <th class="descr">Examples</th>
    *   </tr>
    *   <tr>
    *    <td class="descr">Inclusion</td>
    *    <td class="descr">Required</td>
    *    <td class="descr">"INCLUDE:" or "EXCLUDE:" (any case, may be abbreviated)</td>
    *    <td class="descr"><ul><li>in:</li><li>EXCL:</li><li>I:</li></ul></td>
    *   </tr>
    *   <tr>
    *    <td class="descr">Element-specific regex flags</td>
    *    <td class="descr">Optional</td>
    *    <td class="descr">"FLAGS=&lt;flags&gt;:" (any case, may be abbreviated)</td>
    *    <td class="descr"><ul><li>FLAGS=IM:</li><li>f=n:</li></ul></td>
    *   </tr>
    *   <tr>
    *    <td class="descr">Filter text</td>
    *    <td class="descr">Required</td>
    *    <td class="descr">One of:<ul><li>glob-style wildcard mask (uses * and ?)</li><li>Oracle regular expression</li></ul></td>
    *    <td class="descr"></td>
    *   </tr>
    * </table>
    * @param p_fail_if_exists  A flag (T/F) specifying whether to fail if a text filter of the same name already exists. F = overwrite any existing text filter
    * @param p_uses_regex      A flag (T/F) specifying whether the text filter uses regular expressions. F = filter uses glob-style wildcards (*, ?)
    * @param p_regex_flags     The regular expression flags (Oracle match parameter) to use with all elements. Can be overridden by specific element flags.
    * @param p_office_id       The text identifier of the office that owns the text filter.  If not specified or NULL, the session user's default office is used.
    */
   procedure store_text_filter(
      p_text_filter_id   in varchar2,
      p_description      in varchar2,
      p_configuration_id in varchar2,
      p_text_filter      in str_tab_t,
      p_fail_if_exists   in varchar2 default 'T',
      p_uses_regex       in varchar2 default 'F',
      p_regex_flags      in varchar2 default null,
      p_office_id        in varchar2 default null);

   /**
    * Retrieves a text filter from the database
    *
    * @param p_text_filter     The text filter elements.  Each element is a string composed of the following items concatenated together:
    * <p>
    * <table class="descr">
    *   <tr>
    *    <th class="descr">Item</th>
    *    <th class="descr">Present?</th>
    *    <th class="descr">Format</th>
    *   </tr>
    *   <tr>
    *    <td class="descr">Inclusion</td>
    *    <td class="descr">Always</td>
    *    <td class="descr">"INCLUDE:" or "EXCLUDE:"</td>
    *   </tr>
    *   <tr>
    *    <td class="descr">Element-specific regex flags</td>
    *    <td class="descr">Only if filter is regular expression and element uses flags</td>
    *    <td class="descr">"FLAGS=&lt;flags&gt;:"</td>
    *   </tr>
    *   <tr>
    *    <td class="descr">Filter text</td>
    *    <td class="descr">Always</td>
    *    <td class="descr">The actual filter text (regular expression or glob-style wildcard mask)</td>
    *   </tr>
    * </table>
    * @param p_uses_regex      A flag (T/F) specifying whether the retrieved text filter uses regular expressions. F = filter uses glob-style wildcards (*, ?).
    * @param p_text_filter_id  The text identifier (name) of the text filter to retrieve. May be up to 32 characters.
    * @param p_office_id       The text identifier of the office that owns the text filter.  If not specified or NULL, the session user's default office is used.
    */
   procedure retrieve_text_filter(
      p_text_filter    out str_tab_t,
      p_uses_regex     out varchar2,
      p_text_filter_id in  varchar2,
      p_office_id      in  varchar2 default null);

   /**
    * Retrieves a text filter from the database
    *
    * @param p_text_filter     The text filter elements.  Each element is a string composed of the following items concatenated together:
    * <p>
    * <table class="descr">
    *   <tr>
    *    <th class="descr">Item</th>
    *    <th class="descr">Present?</th>
    *    <th class="descr">Format</th>
    *   </tr>
    *   <tr>
    *    <td class="descr">Inclusion</td>
    *    <td class="descr">Always</td>
    *    <td class="descr">"INCLUDE:" or "EXCLUDE:"</td>
    *   </tr>
    *   <tr>
    *    <td class="descr">Element-specific regex flags</td>
    *    <td class="descr">Only if filter is regular expression and element uses flags</td>
    *    <td class="descr">"FLAGS=&lt;flags&gt;:"</td>
    *   </tr>
    *   <tr>
    *    <td class="descr">Filter text</td>
    *    <td class="descr">Always</td>
    *    <td class="descr">The actual filter text (regular expression or glob-style wildcard mask)</td>
    *   </tr>
    * </table>
    * @param p_uses_regex        A flag (T/F) specifying whether the retrieved text filter uses regular expressions. F = filter uses glob-style wildcards (*, ?).
    * @param p_configuration_id  The text identifier of the configuration this text filter belongs to. May be up to 32 characters
    * @param p_text_filter_id    The text identifier (name) of the text filter to retrieve. May be up to 32 characters.
    * @param p_office_id         The text identifier of the office that owns the text filter.  If not specified or NULL, the session user's default office is used.
    */
   procedure retrieve_text_filter(
      p_text_filter      out str_tab_t,
      p_uses_regex       out varchar2,
      p_configuration_id out varchar2,
      p_text_filter_id   in  varchar2,
      p_office_id        in  varchar2 default null);
   /**
    * Deletes a text filter from the database
    *
    * @param p_text_filter_id  The text identifier (name) of the text filter to delete. May be up to 32 characters.
    * @param p_office_id       The text identifier of the office that owns the text filter.  If not specified or NULL, the session user's default office is used.
    */
   procedure delete_text_filter(
      p_text_filter_id in varchar2,
      p_office_id      in varchar2 default null);
   /**
    * Renames a text filter in the database
    *
    * @param p_old_text_filter_id  The existing text identifier (name) of the text filter to rename. May be up to 32 characters.
    * @param p_new_text_filter_id  The new text identifier (name) of the text filter.
    * @param p_office_id           The text identifier of the office that owns the text filter.  If not specified or NULL, the session user's default office is used.
    */
   procedure rename_text_filter(
      p_old_text_filter_id in varchar2,
      p_new_text_filter_id in varchar2,
      p_office_id          in varchar2 default null);
   /**
    * Filters a table of strings using a stored text filter
    *
    * @param p_text_filter_id The text identifier (name) of the text filter to use.
    * @param p_values         A table of strings to filter
    * @param p_office_id      The text identifier of the office that owns the text filter. If not specified or NULL, the session user's default office is used.
    *
    * @return A table of strings that passed the filter
    */
   function filter_text(
      p_text_filter_id in varchar2,
      p_values         in str_tab_t,
      p_office_id      in varchar2 default null)
      return str_tab_t;
   /**
    * Filters a string using a stored text filter
    *
    * @param p_text_filter_id The text identifier (name) of the text filter to use.
    * @param p_value          The string to filter
    * @param p_office_id      The text identifier of the office that owns the text filter. If not specified or NULL, the session user's default office is used.
    *
    * @return The input string if it passed the filter, otherwise NULL
    */
   function filter_text(
      p_text_filter_id in varchar2,
      p_value          in varchar2,
      p_office_id      in varchar2 default null)
      return varchar2;
   /**
    * Filters a table of strings using an ad-hoc text filter
    *
    * @param p_filter The filter to use. The filter is comprised of a table of string elements. Each element is a string composed of the following items concatenated together:
    * <p>
    * <table class="descr">
    *   <tr>
    *    <th class="descr">Item</th>
    *    <th class="descr">Usage</th>
    *    <th class="descr">Format</th>
    *    <th class="descr">Examples</th>
    *   </tr>
    *   <tr>
    *    <td class="descr">Inclusion</td>
    *    <td class="descr">Required</td>
    *    <td class="descr">"INCLUDE:" or "EXCLUDE:" (any case, may be abbreviated)</td>
    *    <td class="descr"><ul><li>in:</li><li>EXCL:</li><li>I:</li></ul></td>
    *   </tr>
    *   <tr>
    *    <td class="descr">Element-specific regex flags</td>
    *    <td class="descr">Optional</td>
    *    <td class="descr">"FLAGS=&lt;flags&gt;:" (any case, may be abbreviated)</td>
    *    <td class="descr"><ul><li>FLAGS=IM:</li><li>f=n:</li></ul></td>
    *   </tr>
    *   <tr>
    *    <td class="descr">Filter text</td>
    *    <td class="descr">Required</td>
    *    <td class="descr">One of:<ul><li>glob-style wildcard mask (uses * and ?)</li><li>Oracle regular expression</li></ul></td>
    *    <td class="descr"></td>
    *   </tr>
    * </table>
    * @param p_values A table of strings to filter
    * @param p_regex  A flag (T/F) specifying whether the filter uses regular expressions
    *
    * @return A table of strings that passed the filter
    */
   function filter_text(
      p_filter in str_tab_t,
      p_values in str_tab_t,
      p_regex  in varchar2 default 'F')
      return str_tab_t;
   /**
    * Filters a string using an ad-hoc text filter
    *
    * @param p_filter The filter to use. The filter is comprised of a table of string elements. Each element is a string composed of the following items concatenated together:
    * <p>
    * <table class="descr">
    *   <tr>
    *    <th class="descr">Item</th>
    *    <th class="descr">Usage</th>
    *    <th class="descr">Format</th>
    *    <th class="descr">Examples</th>
    *   </tr>
    *   <tr>
    *    <td class="descr">Inclusion</td>
    *    <td class="descr">Required</td>
    *    <td class="descr">"INCLUDE:" or "EXCLUDE:" (any case, may be abbreviated)</td>
    *    <td class="descr"><ul><li>in:</li><li>EXCL:</li><li>I:</li></ul></td>
    *   </tr>
    *   <tr>
    *    <td class="descr">Element-specific regex flags</td>
    *    <td class="descr">Optional</td>
    *    <td class="descr">"FLAGS=&lt;flags&gt;:" (any case, may be abbreviated)</td>
    *    <td class="descr"><ul><li>FLAGS=IM:</li><li>f=n:</li></ul></td>
    *   </tr>
    *   <tr>
    *    <td class="descr">Filter text</td>
    *    <td class="descr">Required</td>
    *    <td class="descr">One of:<ul><li>glob-style wildcard mask (uses * and ?)</li><li>Oracle regular expression</li></ul></td>
    *    <td class="descr"></td>
    *   </tr>
    * </table>
    * @param p_value  The string to filter
    * @param p_regex  A flag (T/F) specifying whether the filter uses regular expressions
    *
    * @return The input string if it passed the filter, otherwise NULL
    */
   function filter_text(
      p_filter in str_tab_t,
      p_value  in varchar2,
      p_regex  in varchar2 default 'F')
      return varchar2;
end;
/
