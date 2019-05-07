create or replace package cwms_log_ingest
/**
 * Provides routines deailing with application logs
 *
 * @since CWMS 3.2
 * @author Mike Perryman
 */
as
/**
 * Stores and application log directory in the database
 *
 * @param p_host_fqdn      The fully qualified domain name of the host that the log directory is on
 * @param p_log_dir        The absolute path of the log directory on the host. Can include links but not relative pathname parts
 * @param p_fail_if_exists A flag (T/F) specifying whether to fail if the directory already exists in the database
 * @param p_office_id      The office that owns the log directory. If unspecified or NULL, the current session's user is used
 */
procedure store_app_log_dir(
   p_host_fqdn      in varchar2,
   p_log_dir        in varchar2,
   p_fail_if_exists in varchar2 default 'F',
   p_office_id      in varchar2 default null);
/**
 * Deletes an application log directory from the database
 *
 * @param p_host_fqdn     The fully qualified domain name of the host that the log directory is on
 * @param p_log_dir       The absolute path of the log directory on the host. Can include links but not relative pathname parts
 * @param p_delete_action Specifies what to delete.  Actions are as follows:
 *                        <p>
 *                        <table class="descr">
 *                          <tr>
 *                            <th class="descr">p_delete_action</th>
 *                            <th class="descr">Action</th>
 *                          </tr>
 *                          <tr>
 *                            <td class="descr">cwms_util.delete_key</td>
 *                            <td class="descr">deletes only the matching log directory, and only then if is not referenced by any log files</td>
 *                          </tr>
 *                          <tr>
 *                            <td class="descr">cwms_util.delete_data</td>
 *                            <td class="descr">deletes only the log files (and associated log entries) that reference the log directory</td>
 *                          </tr>
 *                          <tr>
 *                            <td class="descr">cwms_util.delete_all</td>
 *                            <td class="descr">deletes the log directory, along with any referencing log files and log entries</td>
 *                          </tr>
 *                        </table>
 * @param p_office_id     The office that owns the log directory. If unspecified or NULL, the current session's user is used
 *
 * @see constant cwms_util.delete_key
 * @see constant cwms_util.delete_data
 * @see constant cwms_util.delete_all
 */
procedure delete_app_log_dir(
   p_host_fqdn     in varchar2,
   p_log_dir       in varchar2,
   p_delete_action in varchar2 default cwms_util.delete_key,
   p_office_id     in varchar2 default null);
/**
 * Catalogs existing application log directories in the databse. Matching is
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
 * @param p_cat_cursor     A cursor containing all matching application log directories. The cursor contains the following columns:
 *                         <p>
 *                         <table class="descr">
 *                           <tr>
 *                             <th class="descr">Column No.</th>
 *                             <th class="descr">Column Name</th>
 *                             <th class="descr">Data Type</th>
 *                             <th class="descr">Contents</th>
 *                           </tr>
 *                           <tr>
 *                             <td class="descr-center">1</td>
 *                             <td class="descr">office_id</td>
 *                             <td class="descr">varchar2(16)</td>
 *                             <td class="descr">The office that owns the log directory</td>
 *                           </tr>
 *                           <tr>
 *                             <td class="descr-center">2</td>
 *                             <td class="descr">host_fqdn</td>
 *                             <td class="descr">varchar2(128)</td>
 *                             <td class="descr">The fully qualified domain name of the host containing the log directory</td>
 *                           </tr>
 *                           <tr>
 *                             <td class="descr-center">3</td>
 *                             <td class="descr">log_dir_name</td>
 *                             <td class="descr">varchar2(256)</td>
 *                             <td class="descr">The name of the application log directory</td>
 *                           </tr>
 *                         </table>
 * @param p_host_mask      The host pattern to match. May be a host name or may have glob-style wildcards as described above. If not specified, defaults to '*'.
 * @param p_log_dir_mask   The log directory pattern to match. May be a directory name or may have glob-style wildcards as described above. If not specified, defaults to '*'.
 * @param p_office_id_mask The office pattern to match. May be an office name or have glob-style wildcards as described above. If not specified or NULL, the session user's office is used.
 */
procedure cat_app_log_dir(
   p_cat_cursor      out sys_refcursor,
   p_host_mask       in  varchar2 default '*',
   p_log_dir_mask    in  varchar2 default '*',
   p_office_id_mask  in  varchar2 default null);
/**
 * Catalogs existing application log directories in the databse. Matching is
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
 * @param p_host_mask       The host pattern to match. May be a host name or may have glob-style wildcards as described above. If not specified, defaults to '*'.
 * @param p_log_dir_mask    The log directory pattern to match. May be a directory name or may have glob-style wildcards as described above. If not specified, defaults to '*'.
 * @param p_office_id_mask  The office pattern to match. May be an office name or have glob-style wildcards as described above. If not specified or NULL, the session user's office is used.
 *
 * @return A cursor containing all matching application log directories. The cursor contains
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
 *     <td class="descr">The office that owns the log directory</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">host_fqdn</td>
 *     <td class="descr">varchar2(128)</td>
 *     <td class="descr">The fully qualified domain name of the host containing the log directory</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">log_dir_name</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The name of the application log directory</td>
 *   </tr>
 * </table>
 */
function cat_app_log_dir_f(
   p_host_mask       in varchar2 default '*',
   p_log_dir_mask    in varchar2 default '*',
   p_office_id_mask  in varchar2 default null)
   return sys_refcursor;
/**
 * Stores and application log file in the database
 *
 * @param p_host_fqdn      The fully qualified domain name of the host that the log directory is on
 * @param p_log_file       The absolute path of the log file on the host. Can include links but not relative pathname parts
 * @param p_fail_if_exists A flag (T/F) specifying whether to fail if the log file already exists in the database
 * @param p_office_id      The office that owns the log file. If unspecified or NULL, the current session's user is used
 */
procedure store_app_log_file(
   p_host_fqdn      in varchar2,
   p_log_file_name  in varchar2,
   p_fail_if_exists in varchar2 default 'F',
   p_office_id      in varchar2 default null);
/**
 * Deletes an application log file from the database
 *
 * @param p_host_fqdn      The fully qualified domain name of the host that the log file is on
 * @param p_log_file       The absolute path of the log file on the host. Can include links but not relative pathname parts
 * @param p_delete_action  Specifies what to delete.  Actions are as follows:
 *                         <p>
 *                         <table class="descr">
 *                           <tr>
 *                             <th class="descr">p_delete_action</th>
 *                             <th class="descr">Action</th>
 *                           </tr>
 *                           <tr>
 *                             <td class="descr">cwms_util.delete_key</td>
 *                             <td class="descr">deletes only the matching log file, and only then if is not referenced by any log entries</td>
 *                           </tr>
 *                           <tr>
 *                             <td class="descr">cwms_util.delete_data</td>
 *                             <td class="descr">deletes only the log entries that reference the log file</td>
 *                           </tr>
 *                           <tr>
 *                             <td class="descr">cwms_util.delete_all</td>
 *                             <td class="descr">deletes the log file and log entries</td>
 *                           </tr>
 *                         </table>
 * @param p_office_id      The office that owns the log file. If unspecified or NULL, the current session's user is used
 *
 * @see constant cwms_util.delete_key
 * @see constant cwms_util.delete_data
 * @see constant cwms_util.delete_all
 */
procedure delete_app_log_text(
   p_host_fqdn     in varchar2,
   p_log_file_name in varchar2,
   p_delete_action in varchar2 default cwms_util.delete_key,
   p_office_id     in varchar2 default null);
/**
 * Catalogs existing application log files in the databse. Matching is
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
 * @param p_cat_cursor      A cursor containing all matching application log directories. The cursor contains the following columns:
 *                          <p>
 *                          <table class="descr">
 *                            <tr>
 *                              <th class="descr">Column No.</th>
 *                              <th class="descr">Column Name</th>
 *                              <th class="descr">Data Type</th>
 *                              <th class="descr">Contents</th>
 *                            </tr>
 *                            <tr>
 *                              <td class="descr-center">1</td>
 *                              <td class="descr">office_id</td>
 *                              <td class="descr">varchar2(16)</td>
 *                              <td class="descr">The office that owns the log file</td>
 *                            </tr>
 *                            <tr>
 *                              <td class="descr-center">2</td>
 *                              <td class="descr">host_fqdn</td>
 *                              <td class="descr">varchar2(128)</td>
 *                              <td class="descr">The fully qualified domain name of the host containing the log file</td>
 *                            </tr>
 *                            <tr>
 *                              <td class="descr-center">3</td>
 *                              <td class="descr">log_dir_name</td>
 *                              <td class="descr">varchar2(256)</td>
 *                              <td class="descr">The name of the application log directory</td>
 *                            </tr>
 *                            <tr>
 *                              <td class="descr-center">4</td>
 *                              <td class="descr">log_file_name</td>
 *                              <td class="descr">varchar2(256)</td>
 *                              <td class="descr">The basename of the application log file</td>
 *                            </tr>
 *                          </table>
 * @param p_host_mask       The host pattern to match. May be a host name or may have glob-style wildcards as described above. If not specified, defaults to '*'.
 * @param p_log_file_mask   The log directory file to match. May be a file name or may have glob-style wildcards as described above. If not specified, defaults to '*'.
 * @param p_office_id_mask  The office pattern to match. May be an office name or have glob-style wildcards as described above. If not specified or NULL, the session user's office is used.
 */
procedure cat_app_log_file(
   p_cat_cursor      out sys_refcursor,
   p_host_mask       in  varchar2 default '*',
   p_log_file_mask   in  varchar2 default '*',
   p_office_id_mask  in  varchar2 default null);
/**
 * Catalogs existing application log files in the databse. Matching is
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
 * @param p_host_mask       The host pattern to match. May be a host name or may have glob-style wildcards as described above. If not specified, defaults to '*'.
 * @param p_log_file_mask   The log directory file to match. May be a file name or may have glob-style wildcards as described above. If not specified, defaults to '*'.
 * @param p_office_id_mask  The office pattern to match. May be an office name or have glob-style wildcards as described above. If not specified or NULL, the session user's office is used.
 *
 * @return A cursor containing all matching application log directories. The cursor contains
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
 *     <td class="descr">The office that owns the log file</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">host_fqdn</td>
 *     <td class="descr">varchar2(128)</td>
 *     <td class="descr">The fully qualified domain name of the host containing the log file</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">log_dir_name</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The name of the application log directory</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">log_file_name</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The basename of the application log file</td>
 *   </tr>
 * </table>
 */
function cat_app_log_file_f(
   p_host_mask       in varchar2 default '*',
   p_log_file_mask   in varchar2 default '*',
   p_office_id_mask  in varchar2 default null)
   return sys_refcursor;
/**
 * Stores and application log ingest control entry in the database
 *
 * @param p_host_fqdn          The fully qualified domain name of the host that the log directory is on
 * @param p_log_dir            The absolute path of the log file directory on the host. Can include links but not relative pathname parts
 * @param p_log_file_mask      The file name pattern for log files in the specified directory to ingest. Matching is accomplished with
 *                             glob-style wildcards, as shown below, instead of sql-style wildcards.
 *                             <p>
 *                             <table class="descr">
 *                               <tr>
 *                                 <th class="descr">Wildcard</th>
 *                                 <th class="descr">Meaning</th>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">*</td>
 *                                 <td class="descr">Match zero or more characters</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">?</td>
 *                                 <td class="descr">Match a single character</td>
 *                               </tr>
 *                             </table>
 * @param p_ingest_sub_dirs    A flag (T/F) specifying whether to ingest log file of the same file name mask in all sub-directories of the specified directory
 * @param p_max_entry_age      The maximum age of a log file entry (in <a href="https://www.w3.org/TR/xmlschema-2/#duration">XML schema duration format</a>) before it will be automatically deleted from the database regardless of log file size
 * @param p_max_file_size      The maximum size of all entries for a log file before the oldest entries will be automatically deleted from the database regardless of entry age
 * @param p_delete_empty_files A flag (T/F) specifying whether to automatically delete log files from the database that have no entries
 * @param p_fail_if_exists     A flag (T/F) specifying whether to fail if the log ingest control entry already exists in the database
 * @param p_office_id          The office that owns the log ingest control entry. If unspecified or NULL, the current session's user is used
 */
procedure store_app_log_ingest_control(
   p_host_fqdn          in varchar2,
   p_log_dir            in varchar2,
   p_log_file_mask      in varchar2 default '*',
   p_ingest_sub_dirs    in varchar2 default 'F',
   p_max_entry_age      in varchar2 default 'P1M',
   p_max_file_size      in integer  default 50 * 1024 * 1024,
   p_delete_empty_files in varchar2 default 'T',
   p_fail_if_exists     in varchar2 default 'T',
   p_office_id          in varchar2 default null);
/**
 * Deletes an application log ingest control entry from the database
 *
 * @param p_host_fqdn     The fully qualified domain name of the host that the log files are on
 * @param p_log_dir       The absolute path of the log file directory on the host. Can include links but not relative pathname parts
 * @param p_delete_action Specifies what to delete.  Actions are as follows:
 *                        <p>
 *                        <table class="descr">
 *                          <tr>
 *                            <th class="descr">p_delete_action</th>
 *                            <th class="descr">Action</th>
 *                          </tr>
 *                          <tr>
 *                            <td class="descr">cwms_util.delete_key</td>
 *                            <td class="descr">deletes only the log ingest control entry</td>
 *                          </tr>
 *                          <tr>
 *                            <td class="descr">cwms_util.delete_data</td>
 *                            <td class="descr">deletes only the log files and log file entries matched by the log ingest control entry</td>
 *                          </tr>
 *                          <tr>
 *                            <td class="descr">cwms_util.delete_all</td>
 *                            <td class="descr">deletes the log ingest control entry and the log files and log file entries matched by the log ingest control entry</td>
 *                          </tr>
 *                        </table>
 * @param p_office_id     The office that owns the log ingest control entry. If unspecified or NULL, the current session's user is used
 *
 * @see constant cwms_util.delete_key
 * @see constant cwms_util.delete_data
 * @see constant cwms_util.delete_all
 */
procedure delete_app_log_ingest_control(
   p_host_fqdn     in varchar2,
   p_log_dir       in varchar2,
   p_log_file_mask in varchar2 default '*',
   p_delete_action in varchar2 default cwms_util.delete_key,
   p_office_id     in varchar2 default null);
/**
 * Catalogs existing application log ingest control entries in the databse. Matching is
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
 * @param p_cat_cursor      A cursor containing all matching application log directories. The cursor contains the following columns:
 *                          <p>
 *                          <table class="descr">
 *                            <tr>
 *                              <th class="descr">Column No.</th>
 *                              <th class="descr">Column Name</th>
 *                              <th class="descr">Data Type</th>
 *                              <th class="descr">Contents</th>
 *                            </tr>
 *                            <tr>
 *                              <td class="descr-center">1</td>
 *                              <td class="descr">office_id</td>
 *                              <td class="descr">varchar2(16)</td>
 *                              <td class="descr">The office that owns the log ingest control entry</td>
 *                            </tr>
 *                            <tr>
 *                              <td class="descr-center">2</td>
 *                              <td class="descr">host_fqdn</td>
 *                              <td class="descr">varchar2(128)</td>
 *                              <td class="descr">The fully qualified domain name of the host containing the log files</td>
 *                            </tr>
 *                            <tr>
 *                              <td class="descr-center">3</td>
 *                              <td class="descr">log_dir_name</td>
 *                              <td class="descr">varchar2(256)</td>
 *                              <td class="descr">The name of the application log directory</td>
 *                            </tr>
 *                            <tr>
 *                              <td class="descr-center">4</td>
 *                              <td class="descr">log_file_mask</td>
 *                              <td class="descr">varchar2(256)</td>
 *                              <td class="descr">The file name mask of log files in the directory to ingest</td>
 *                            </tr>
 *                            <tr>
 *                              <td class="descr-center">5</td>
 *                              <td class="descr">ingest_sub_dirs</td>
 *                              <td class="descr">varchar2(1)</td>
 *                              <td class="descr">A flag (T/F) specifying whether log files of the same file name mask are ingested from all sub-directories of the log direcotry</td>
 *                            </tr>
 *                            <tr>
 *                              <td class="descr-center">5</td>
 *                              <td class="descr">max_entry_age</td>
 *                              <td class="descr">varchar2(16)</td>
 *                              <td class="descr">The maximum age of a log file entry (in <a href="https://www.w3.org/TR/xmlschema-2/#duration">XML schema duration format</a>) before it will be automatically deleted from the database regardless of log file size</td>
 *                            </tr>
 *                            <tr>
 *                              <td class="descr-center">5</td>
 *                              <td class="descr">max_file_size</td>
 *                              <td class="descr">integer</td>
 *                              <td class="descr">The maximum size of all entries for a log file before the oldest entries will be automatically deleted from the database regardless of entry age</td>
 *                            </tr>
 *                            <tr>
 *                              <td class="descr-center">5</td>
 *                              <td class="descr">delete_empty_files</td>
 *                              <td class="descr">varchar2(1)</td>
 *                              <td class="descr">A flag (T/F) specifying whether to automatically delete log files from the database that have no entries</td>
 *                            </tr>
 *                          </table>
 * @param p_host_mask       The host pattern to match. May be a host name or may have glob-style wildcards as described above. If not specified, defaults to '*'.
 * @param p_log_dir_mask    The log directory to match. May be a directory name or may have glob-style wildcards as described above. If not specified, defaults to '*'.
 * @param p_log_file_mask   The log file name mask to match. May be a file name or may have glob-style wildcards as described above. If not specified, defaults to '*'.
 * @param p_file_wildcard   A flag (T/F) specifying whether p_log_file_mask is itself interpreted as a wildcard mask. If 'F', p_log_file_mask is interpreted as a literal string (e.g., '*' matches the literal log file mask of  '*' instead of matching all log file masks).
 * @param p_office_id_mask  The office pattern to match. May be an office name or have glob-style wildcards as described above. If not specified or NULL, the session user's office is used.
 */
procedure cat_app_log_ingest_control(
   p_cat_cursor     out sys_refcursor,
   p_host_mask      in  varchar2 default '*',
   p_log_dir_mask   in  varchar2 default '*',
   p_log_file_mask  in  varchar2 default '*',
   p_file_wildcard  in  varchar2 default 'T',
   p_office_id_mask in  varchar2 default null);
/**
 * Catalogs existing application log ingest control entries in the databse. Matching is
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
 * @param p_host_mask       The host pattern to match. May be a host name or may have glob-style wildcards as described above. If not specified, defaults to '*'.
 * @param p_log_dir_mask    The log directory to match. May be a directory name or may have glob-style wildcards as described above. If not specified, defaults to '*'.
 * @param p_log_file_mask   The log file name mask to match. May be a file name or may have glob-style wildcards as described above. If not specified, defaults to '*'.
 * @param p_file_wildcard   A flag (T/F) specifying whether p_log_file_mask is itself interpreted as a wildcard mask. If 'F', p_log_file_mask is interpreted as a literal string (e.g., '*' matches the literal log file mask of  '*' instead of matching all log file masks).
 * @param p_office_id_mask  The office pattern to match. May be an office name or have glob-style wildcards as described above. If not specified or NULL, the session user's office is used.
 *
 * @return A cursor containing all matching application log directories. The cursor contains the following columns:
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
 *     <td class="descr">The office that owns the log ingest control entry</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">host_fqdn</td>
 *     <td class="descr">varchar2(128)</td>
 *     <td class="descr">The fully qualified domain name of the host containing the log files</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">log_dir_name</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The name of the application log directory</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">log_file_mask</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The file name mask of log files in the directory to ingest</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">ingest_sub_dirs</td>
 *     <td class="descr">varchar2(1)</td>
 *     <td class="descr">A flag (T/F) specifying whether log files of the same file name mask are ingested from all sub-directories of the log direcotry</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">max_entry_age</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The maximum age of a log file entry (in <a href="https://www.w3.org/TR/xmlschema-2/#duration">XML schema duration format</a>) before it will be automatically deleted from the database regardless of log file size</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">max_file_size</td>
 *     <td class="descr">integer</td>
 *     <td class="descr">The maximum size of all entries for a log file before the oldest entries will be automatically deleted from the database regardless of entry age</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">delete_empty_files</td>
 *     <td class="descr">varchar2(1)</td>
 *     <td class="descr">A flag (T/F) specifying whether to automatically delete log files from the database that have no entries</td>
 *   </tr>
 * </table>
 */
function cat_app_log_ingest_control_f(
   p_host_mask      in  varchar2 default '*',
   p_log_dir_mask   in  varchar2 default '*',
   p_log_file_mask  in  varchar2 default '*',
   p_file_wildcard  in  varchar2 default 'T',
   p_office_id_mask in  varchar2 default null)
   return sys_refcursor;
/**
 * Stores application log file text to the database
 *
 * @param p_host_fqdn     The fully qualified domain name of the host containing the log file
 * @param p_log_file_name The absolute path of the log file on the host. Can include links but not relative pathname parts
 * @param p_start_offset  The byte offset into the log file of the first byte of the text entry
 * @param p_entry_text    The log file text beginning at p_start_offset
 * @param p_office_id     The office that owns the log file in the database. If unspecified or NULL, the current session's user is used
 */
procedure store_app_log_file_entry(
   p_host_fqdn     in varchar2,
   p_log_file_name in varchar2,
   p_start_offset  in integer,
   p_entry_text    in clob,
   p_office_id     in varchar2 default null);
/**
 * Retrieves application log file text by time window from the database. The time window applies to the times the log file entries were stored in the
 * database, not any timestamps <b>within</b> the log file text, nor when the text was written to the log file itself.
 *
 * @param p_log_file_text The retrieved application log file text. If NULL on input, no text is retrieved but times are still reported.
 * @param p_start_time    The earliest date to retrieve text for, in the specified or default time zone.
                          If NULL on input, the time window will start with the earliest available log file entry.
                          On output this will be set to the time of the earliest log file entrry retrieved
 * @param p_end_time      The lastest date to retrieve text for, in the specified or default time zone.
                          If NULL on input, the time window will end with the latest available log file entry.
                          On output this will be set to the time of the latest log file entrry retrieved
 * @param p_host_fqdn     The fully qualified domain name of the host containing the log file
 * @param p_log_file_name The absolute path of the log file on the host. Can include links but not relative pathname parts
 * @param p_time_zone     The time zone that p_start_time and p_end_time are interpreted in and are reported in. If unspecified, 'UTC' is used
 * @param p_office_id     The office that owns the log file in the database. If unspecified or NULL, the current session's user is used
 */
procedure retrieve_app_log_text_time(
   p_log_file_text in out nocopy clob,
   p_start_time    in out nocopy date,
   p_end_time      in out nocopy date,
   p_host_fqdn     in varchar2,
   p_log_file_name in varchar2,
   p_time_zone     in varchar2 default 'UTC',
   p_office_id     in varchar2 default null);
/**
 * Retrieves application log file text by time window from the database. The time window applies to the times the log file entries were stored in the
 * database, not any timestamps <b>within</b> the log file text, nor when the text was written to the log file itself.
 *
 * @param p_host_fqdn     The fully qualified domain name of the host containing the log file
 * @param p_log_file_name The absolute path of the log file on the host. Can include links but not relative pathname parts
 * @param p_start_time    The earliest date to retrieve text for, in the specified or default time zone
 * @param p_start_time    The earliest date to retrieve text for, in the specified or default time zone.
                          If NULL, the time window will start with the earliest available log file entry.
 * @param p_end_time      The lastest date to retrieve text for, in the specified or default time zone.
                          If NULL, the time window will end with the latest available log file entry.
 * @param p_time_zone     The time zone that p_start_time and p_end_time are interpreted in. If unspecified, 'UTC' is used
 * @param p_office_id     The office that owns the log file in the database. If unspecified or NULL, the current session's user is used
 *
 * @return The retrieved application log file text
 */
function retrieve_app_log_text_time_f(
   p_host_fqdn     in varchar2,
   p_log_file_name in varchar2,
   p_start_time    in date default null,
   p_end_time      in date default null,
   p_time_zone     in varchar2 default 'UTC',
   p_office_id     in varchar2 default null)
   return clob;
/**
 * Retrieves application log file text by byte offset window from the database. This will retrieve partial log file text entries if required.
 *
 * @param p_log_file_text   The retrieved application log file text. If NULL on input, no text is retrieved but offsets are still reported.
 * @param p_start_offset    The beginning byte offset to retrieve text for. If NULL on input, the smallest available offset will be used.
                            On output this will be set to the byte offset of the first character of the retrieved text
 * @param p_end_offset      The ending byte offset to retrieve text for. If NULL on input, the largest available offset will be used.
                            On output this will be set to the byte offset of the last character of the retrieved text
 * @param p_host_fqdn       The fully qualified domain name of the host containing the log file
 * @param p_log_file_name   The absolute path of the log file on the host. Can include links but not relative pathname parts
 * @param p_start_inclusive A flag (T/F) specifying whether to retrieve the entire log file entry containing the text at p_start_offset
 * @param p_end_inclusive   A flag (T/F) specifying whether to retrieve the entire log file entry containing the text at p_end_offset
 * @param p_office_id       The office that owns the log file in the database. If unspecified or NULL, the current session's user is used
 */
procedure retrieve_app_log_text_offset(
   p_log_file_text   in out nocopy clob,
   p_start_offset    in out nocopy integer,
   p_end_offset      in out nocopy integer,
   p_host_fqdn       in varchar2,
   p_log_file_name   in varchar2,
   p_start_inclusive in varchar2 default 'T',
   p_end_inclusive   in varchar2 default 'T',
   p_office_id       in varchar2 default null);
/**
 * Retrieves application log file text by byte offset window from the database.
 *
 * @param p_host_fqdn       The fully qualified domain name of the host containing the log file
 * @param p_log_file_name   The absolute path of the log file on the host. Can include links but not relative pathname parts
 * @param p_start_offset    The beginning byte offset to retrieve text for. If NULL, the smallest available offset will be used.
 * @param p_end_offset      The ending byte offset to retrieve text for. If NULL, the largest available offset will be used.
 * @param p_start_inclusive A flag (T/F) specifying whether to retrieve the entire log file entry containing the text at p_start_offset
 * @param p_end_inclusive   A flag (T/F) specifying whether to retrieve the entire log file entry containing the text at p_end_offset
 * @param p_office_id       The office that owns the log file in the database. If unspecified or NULL, the current session's user is used
 *
 * @return   The retrieved application log file text
 */
function retrieve_app_log_text_offset_f(
   p_host_fqdn       in varchar2,
   p_log_file_name   in varchar2,
   p_start_offset    in integer default null,
   p_end_offset      in integer default null,
   p_start_inclusive in varchar2 default 'T',
   p_end_inclusive   in varchar2 default 'T',
   p_office_id       in varchar2 default null)
   return clob;
/**
 * Deletes application log file text by time window from the database. The time window applies to the times the log file entries were stored in the
 * database, not any timestamps <b>within</b> the log file text, nor when the text was written to the log file itself.
 *
 * @param p_host_fqdn     The fully qualified domain name of the host containing the log file
 * @param p_log_file_name The absolute path of the log file on the host. Can include links but not relative pathname parts
 * @param p_start_time    The earliest date to retrieve text for, in the specified or default time zone
 * @param p_start_time    The earliest date to retrieve text for, in the specified or default time zone.
                          If NULL, the time window will start with the earliest available log file entry.
 * @param p_end_time      The lastest date to retrieve text for, in the specified or default time zone.
                          If NULL, the time window will end with the latest available log file entry.
 * @param p_time_zone     The time zone that p_start_time and p_end_time are interpreted in. If unspecified, 'UTC' is used
 * @param p_office_id     The office that owns the log file in the database. If unspecified or NULL, the current session's user is used
 */
procedure delete_app_log_text_time(
   p_host_fqdn     in varchar2,
   p_log_file_name in varchar2,
   p_start_time    in date default null,
   p_end_time      in date default null,
   p_time_zone     in varchar2 default 'UTC',
   p_office_id     in varchar2 default null);
/**
 * Deletes application log file text by byte offset window from the database. Unlike retrieve_app_log_text_offset, which will retrieve
 * partial log file text entries, this routine deletes only entire entries.
 *
 * @param p_host_fqdn       The fully qualified domain name of the host containing the log file
 * @param p_log_file_name   The absolute path of the log file on the host. Can include links but not relative pathname parts
 * @param p_start_offset    The beginning byte offset to retrieve text for. If NULL, the smallest available offset will be used.
 * @param p_end_offset      The ending byte offset to retrieve text for. If NULL, the largest available offset will be used.
 * @param p_start_inclusive A flag (T/F) specifying whether to delete the log file entry containing the text at p_start_offset.
                            If 'F', only entries that start on or after p_start_offset are deleted.
 * @param p_end_inclusive   A flag (T/F) specifying whether to delete the log file entry containing the text at p_end_offset.
                            If 'F', only entries that end on or before p_start_offset are deleted.
 * @param p_office_id       The office that owns the log file in the database. If unspecified or NULL, the current session's user is used
 *
 * @return   The retrieved application log file text
 */
procedure delete_app_log_text_offset(
   p_host_fqdn       in varchar2,
   p_log_file_name   in varchar2,
   p_start_offset    in integer default null,
   p_end_offset      in integer default null,
   p_start_inclusive in varchar2 default 'T',
   p_end_inclusive   in varchar2 default 'T',
   p_office_id       in varchar2 default null);
/*
 * Not documented
 */
procedure auto_delete_app_log_texts;

end cwms_log_ingest;
/
