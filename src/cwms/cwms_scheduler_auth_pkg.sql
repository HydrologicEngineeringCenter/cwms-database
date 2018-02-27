create or replace package cwms_scheduler_auth
/**
 * Database scheduler routines
 *
 * @author Mike Perryman
 * @since CWMS 3.1
 */
as
/**
 * Category of email recipients of unauthorized scheduler entry emails property 
 */
recipients_prop_category constant varchar2(6) default 'CWMSDB';
/**
 * Name of email recipients of unauthorized scheduler entry emails property 
 */
recipients_prop_name constant varchar2(45) default 'unauthorized_scheduler_entries.email_to_addrs';
/**
 * Office of email recipients of unauthorized scheduler entry emails property 
 */
recipients_prop_office constant varchar2(4) default 'CWMS';
/**
 * Name of job to monitor scheduler for unauthorized jobs
 */
monitor_scheduler_job_name constant varchar2(22) default 'MONITOR_SCHEDULER_JOBS';
/**
 * Authorizes existing scheduler entry. 
 *
 * @param p_job_owner     The owner of the scheduler entry in DBA_SCHEDULER_JOBS.OWNER 
 * @param p_job_name      The name of the scheduler entry in DBA_SCHEDULER_JOBS.JOB_NAME
 * @param p_database_name The name of the database the scheduler entry is authorized for. Standby databases use the name of the primary database. 'CWMS' specifies the entry is specified for all databases.
 *                        If not specified or NULL, the name of the database executing the procedure is used.
 *
 */
procedure store_auth_scheduler_entry(
   p_job_owner     in varchar2,
   p_job_name      in varchar2,
   p_database_name in varchar2 default null);
/**
 * Deletes (unauthorizes) an authorized scheduler entry. This does not remove the job from the scheduler. 
 *
 * @param p_job_owner     The owner of the scheduler entry in DBA_SCHEDULER_JOBS.OWNER 
 * @param p_job_name      The name of the scheduler entry in DBA_SCHEDULER_JOBS.JOB_NAME
 * @param p_database_name The name of the database the scheduler entry is authorized for. Standby databases use the name of the primary database. 'CWMS' specifies the entry is specified for all databases.
 *                        If not specified or NULL, the name of the database executing the procedure is used.
 *
 */
procedure delete_auth_scheduler_entry(
   p_job_owner     in varchar2,
   p_job_name      in varchar2,
   p_database_name in varchar2 default null);
/**
 * Lists authorized scheduler entries matching specified parameters.
 * Matching is accomplished with glob-style wildcards, as shown below, instead
 * SQL-style wildcards.
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
 * @param p_cat_cursor         The cursor containing the authorized scheduler entries that match the specified parameters.
 *                             The cursor will contain the following columns:
 *                             <p>
 *                             <table class="descr">
 *                               <tr>
 *                                 <th class="descr">Column No.</th>
 *                                 <th class="descr">Column Name</th>
 *                                 <th class="descr">Data Type</th>
 *                                 <th class="descr">Contents</th>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">1</td>
 *                                 <td class="descr">office_id</td>
 *                                 <td class="descr">varchar2(16)</td>
 *                                 <td class="descr">The office that owns the database listed</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">2</td>
 *                                 <td class="descr">database_name</td>
 *                                 <td class="descr">varchar2(30)</td>
 *                                 <td class="descr">SID of the database or primary database is this is a standby database</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">3</td>
 *                                 <td class="descr">job_owner</td>
 *                                 <td class="descr">varchar2(30)</td>
 *                                 <td class="descr">Owner of the scheduled job</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">4</td>
 *                                 <td class="descr">job_name</td>
 *                                 <td class="descr">varchar2(30)</td>
 *                                 <td class="descr">Name of the scheduled job</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">5</td>
 *                                 <td class="descr">job_creator</td>
 *                                 <td class="descr">varchar2(30)</td>
 *                                 <td class="descr">Creator of the scheduled job</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">6</td>
 *                                 <td class="descr">job_style</td>
 *                                 <td class="descr">varchar2(11)</td>
 *                                 <td class="descr">''REGULAR'' or ''LIGHTWEIGHT''</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">7</td>
 *                                 <td class="descr">job_type</td>
 *                                 <td class="descr">varchar2(16)</td>
 *                                 <td class="descr">''PLSQL_BLOCK'', ''STORED_PROCEDURE'', ''EXECUTABLE'', or ''CHAIN''</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">8</td>
 *                                 <td class="descr">job_priority</td>
 *                                 <td class="descr">number</td>
 *                                 <td class="descr">Priority of the scheduled job</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">9</td>
 *                                 <td class="descr">schedule_type</td>
 *                                 <td class="descr">varchar2(12)</td>
 *                                 <td class="descr">''IMMEDIATE'', ''ONCE'', ''CALENDAR'', ''EVENT'', ''NAMED'', ''WINDOW'', ''WINDOW_GROUP''</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">10</td>
 *                                 <td class="descr">repeat_interval</td>
 *                                 <td class="descr">varchar2(4000)</td>
 *                                 <td class="descr">How often the job runs</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">11</td>
 *                                 <td class="descr">comments</td>
 *                                 <td class="descr">varchar2(240)</td>
 *                                 <td class="descr">Comments on the scheduled job</td>
 *                               </tr>          
 *                               <tr>
 *                                 <td class="descr-center">12</td>
 *                                 <td class="descr">job_action</td>
 *                                 <td class="descr">varchar2(4000)</td>
 *                                 <td class="descr">What actually gets executed</td>
 *                               </tr>          
 *                             </table>
 * @param p_job_owner_mask     The job owner pattern to match.
 *                             Defaults to '*' if NULL or not specified.
 *                             Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
 * @param p_job_name_mask      The job name pattern to match.
 *                             Defaults to '*' if NULL or not specified.
 *                             Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
 * @param p_database_name_mask The database name pattern to match.
 *                             Defaults to the current database if NULL or not specified.
 *                             Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
 */
procedure cat_auth_scheduler_entries(
   p_cat_cursor         out sys_refcursor,
   p_job_owner_mask     in  varchar2 default '*',
   p_job_name_mask      in  varchar2 default '*',
   p_database_name_mask in  varchar2 default null);
/**
 * Lists authorized scheduler entries matching specified parameters.
 * Matching is accomplished with glob-style wildcards, as shown below, instead
 * SQL-style wildcards.
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
 * @param p_job_owner_mask     The job owner pattern to match.
 *                             Defaults to '*' if NULL or not specified.
 *                             Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
 * @param p_job_name_mask      The job name pattern to match.
 *                             Defaults to '*' if NULL or not specified.
 *                             Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
 * @param p_database_name_mask The database name pattern to match.
 *                             Defaults to the current database if NULL or not specified.
 *                             Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
 *
 * @return The cursor containing the authorized scheduler entries that match the specified parameters.
 *         The cursor will contain the following columns:
 *         <p>
 *         <table class="descr">
 *           <tr>
 *             <th class="descr">Column No.</th>
 *             <th class="descr">Column Name</th>
 *             <th class="descr">Data Type</th>
 *             <th class="descr">Contents</th>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">1</td>
 *             <td class="descr">office_id</td>
 *             <td class="descr">varchar2(16)</td>
 *             <td class="descr">The office that owns the database listed</td>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">2</td>
 *             <td class="descr">database_name</td>
 *             <td class="descr">varchar2(30)</td>
 *             <td class="descr">SID of the database or primary database is this is a standby database</td>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">3</td>
 *             <td class="descr">job_owner</td>
 *             <td class="descr">varchar2(30)</td>
 *             <td class="descr">Owner of the scheduled job</td>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">4</td>
 *             <td class="descr">job_name</td>
 *             <td class="descr">varchar2(30)</td>
 *             <td class="descr">Name of the scheduled job</td>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">5</td>
 *             <td class="descr">job_creator</td>
 *             <td class="descr">varchar2(30)</td>
 *             <td class="descr">Creator of the scheduled job</td>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">6</td>
 *             <td class="descr">job_style</td>
 *             <td class="descr">varchar2(11)</td>
 *             <td class="descr">''REGULAR'' or ''LIGHTWEIGHT''</td>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">7</td>
 *             <td class="descr">job_type</td>
 *             <td class="descr">varchar2(16)</td>
 *             <td class="descr">''PLSQL_BLOCK'', ''STORED_PROCEDURE'', ''EXECUTABLE'', or ''CHAIN''</td>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">8</td>
 *             <td class="descr">job_priority</td>
 *             <td class="descr">number</td>
 *             <td class="descr">Priority of the scheduled job</td>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">9</td>
 *             <td class="descr">schedule_type</td>
 *             <td class="descr">varchar2(12)</td>
 *             <td class="descr">''IMMEDIATE'', ''ONCE'', ''CALENDAR'', ''EVENT'', ''NAMED'', ''WINDOW'', ''WINDOW_GROUP''</td>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">10</td>
 *             <td class="descr">repeat_interval</td>
 *             <td class="descr">varchar2(4000)</td>
 *             <td class="descr">How often the job runs</td>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">11</td>
 *             <td class="descr">comments</td>
 *             <td class="descr">varchar2(240)</td>
 *             <td class="descr">Comments on the scheduled job</td>
 *           </tr>          
 *           <tr>
 *             <td class="descr-center">12</td>
 *             <td class="descr">job_action</td>
 *             <td class="descr">varchar2(4000)</td>
 *             <td class="descr">What actually gets executed</td>
 *           </tr>          
 *         </table>
 */
function cat_auth_scheduler_entries_f(
   p_job_owner_mask     in varchar2 default '*',
   p_job_name_mask      in varchar2 default '*',
   p_database_name_mask in varchar2 default null)
   return sys_refcursor;
/**
 * Lists unauthorized scheduler entries matching specified parameters.
 * Matching is accomplished with glob-style wildcards, as shown below, instead
 * SQL-style wildcards.
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
 * @param p_cat_cursor         The cursor containing the unauthorized scheduler entries that match the specified parameters.
 *                             The cursor will contain the following columns:
 *                             <p>
 *                             <table class="descr">
 *                               <tr>
 *                                 <th class="descr">Column No.</th>
 *                                 <th class="descr">Column Name</th>
 *                                 <th class="descr">Data Type</th>
 *                                 <th class="descr">Contents</th>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">1</td>
 *                                 <td class="descr"office_id></td>
 *                                 <td class="descr">varchar2(16)</td>
 *                                 <td class="descr">The office that owns the database listed</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">2</td>
 *                                 <td class="descr">database_name</td>
 *                                 <td class="descr">varchar2(30)</td>
 *                                 <td class="descr">SID of the database or primary database is this is a standby database</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">3</td>
 *                                 <td class="descr">job_owner</td>
 *                                 <td class="descr">varchar2(30)</td>
 *                                 <td class="descr">Owner of the scheduled job</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">4</td>
 *                                 <td class="descr">job_name</td>
 *                                 <td class="descr">varchar2(30)</td>
 *                                 <td class="descr">Name of the scheduled job</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">5</td>
 *                                 <td class="descr">first_detected</td>
 *                                 <td class="descr">date</td>
 *                                 <td class="descr">The UTC date/time that the unauthorized job was first detected</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">6</td>
 *                                 <td class="descr">job_creator</td>
 *                                 <td class="descr">varchar2(30)</td>
 *                                 <td class="descr">Creator of the scheduled job</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">7</td>
 *                                 <td class="descr">job_style</td>
 *                                 <td class="descr">varchar2(11)</td>
 *                                 <td class="descr">''REGULAR'' or ''LIGHTWEIGHT''</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">8</td>
 *                                 <td class="descr">job_type</td>
 *                                 <td class="descr">varchar2(16)</td>
 *                                 <td class="descr">''PLSQL_BLOCK'', ''STORED_PROCEDURE'', ''EXECUTABLE'', or ''CHAIN''</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">9</td>
 *                                 <td class="descr">job_priority</td>
 *                                 <td class="descr">number</td>
 *                                 <td class="descr">Priority of the scheduled job</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">10</td>
 *                                 <td class="descr">schedule_type</td>
 *                                 <td class="descr">varchar2(12)</td>
 *                                 <td class="descr">''IMMEDIATE'', ''ONCE'', ''CALENDAR'', ''EVENT'', ''NAMED'', ''WINDOW'', ''WINDOW_GROUP''</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">11</td>
 *                                 <td class="descr">repeat_interval</td>
 *                                 <td class="descr">varchar2(4000)</td>
 *                                 <td class="descr">How often the job runs</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">12</td>
 *                                 <td class="descr">comments</td>
 *                                 <td class="descr">varchar2(240)</td>
 *                                 <td class="descr">Comments on the scheduled job</td>
 *                               </tr>          
 *                               <tr>
 *                                 <td class="descr-center">13</td>
 *                                 <td class="descr">job_action</td>
 *                                 <td class="descr">varchar2(4000)</td>
 *                                 <td class="descr">What actually gets executed</td>
 *                               </tr>          
 *                             </table>
 * @param p_job_owner_mask     The job owner pattern to match.
 *                             Defaults to '*' if NULL or not specified.
 *                             Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
 * @param p_job_name_mask      The job name pattern to match.
 *                             Defaults to '*' if NULL or not specified.
 *                             Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
 * @param p_database_name_mask The database name pattern to match.
 *                             Defaults to the current database if NULL or not specified.
 *                             Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
 */
procedure cat_unauth_scheduler_entries(
   p_cat_cursor         out sys_refcursor,
   p_job_owner_mask     in  varchar2 default '*',
   p_job_name_mask      in  varchar2 default '*',
   p_database_name_mask in  varchar2 default null);
/**
 * Lists unauthorized scheduler entries matching specified parameters.
 * Matching is accomplished with glob-style wildcards, as shown below, instead
 * SQL-style wildcards.
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
 * @param p_job_owner_mask     The job owner pattern to match.
 *                             Defaults to '*' if NULL or not specified.
 *                             Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
 * @param p_job_name_mask      The job name pattern to match.
 *                             Defaults to '*' if NULL or not specified.
 *                             Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
 * @param p_database_name_mask The database name pattern to match.
 *                             Defaults to the current database if NULL or not specified.
 *                             Use glob-style wildcard characters as shown above instead of sql-style wildcard characters for pattern matching.
 *
 * @return The cursor containing the unauthorized scheduler entries that match the specified parameters.
 *         The cursor will contain the following columns:
 *         <p>
 *         <table class="descr">
 *           <tr>
 *             <th class="descr">Column No.</th>
 *             <th class="descr">Column Name</th>
 *             <th class="descr">Data Type</th>
 *             <th class="descr">Contents</th>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">1</td>
 *             <td class="descr"office_id></td>
 *             <td class="descr">varchar2(16)</td>
 *             <td class="descr">The office that owns the database listed</td>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">2</td>
 *             <td class="descr">database_name</td>
 *             <td class="descr">varchar2(30)</td>
 *             <td class="descr">SID of the database or primary database is this is a standby database</td>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">3</td>
 *             <td class="descr">job_owner</td>
 *             <td class="descr">varchar2(30)</td>
 *             <td class="descr">Owner of the scheduled job</td>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">4</td>
 *             <td class="descr">job_name</td>
 *             <td class="descr">varchar2(30)</td>
 *             <td class="descr">Name of the scheduled job</td>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">5</td>
 *             <td class="descr">first_detected</td>
 *             <td class="descr">date</td>
 *             <td class="descr">The UTC date/time that the unauthorized job was first detected</td>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">6</td>
 *             <td class="descr">job_creator</td>
 *             <td class="descr">varchar2(30)</td>
 *             <td class="descr">Creator of the scheduled job</td>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">7</td>
 *             <td class="descr">job_style</td>
 *             <td class="descr">varchar2(11)</td>
 *             <td class="descr">''REGULAR'' or ''LIGHTWEIGHT''</td>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">8</td>
 *             <td class="descr">job_type</td>
 *             <td class="descr">varchar2(16)</td>
 *             <td class="descr">''PLSQL_BLOCK'', ''STORED_PROCEDURE'', ''EXECUTABLE'', or ''CHAIN''</td>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">9</td>
 *             <td class="descr">job_priority</td>
 *             <td class="descr">number</td>
 *             <td class="descr">Priority of the scheduled job</td>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">10</td>
 *             <td class="descr">schedule_type</td>
 *             <td class="descr">varchar2(12)</td>
 *             <td class="descr">''IMMEDIATE'', ''ONCE'', ''CALENDAR'', ''EVENT'', ''NAMED'', ''WINDOW'', ''WINDOW_GROUP''</td>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">11</td>
 *             <td class="descr">repeat_interval</td>
 *             <td class="descr">varchar2(4000)</td>
 *             <td class="descr">How often the job runs</td>
 *           </tr>
 *           <tr>
 *             <td class="descr-center">12</td>
 *             <td class="descr">comments</td>
 *             <td class="descr">varchar2(240)</td>
 *             <td class="descr">Comments on the scheduled job</td>
 *           </tr>          
 *           <tr>
 *             <td class="descr-center">13</td>
 *             <td class="descr">job_action</td>
 *             <td class="descr">varchar2(4000)</td>
 *             <td class="descr">What actually gets executed</td>
 *           </tr>          
 *         </table>
 */
function cat_unauth_scheduler_entries_f(
   p_job_owner_mask     in varchar2 default '*',
   p_job_name_mask      in varchar2 default '*',
   p_database_name_mask in varchar2 default null)
   return sys_refcursor;
/**
 * Sets the email recipients for unauthorized scheduler entry emails.
 *
 * @param p_email_recipients The email addresses to send noticies of unauthorized scheduler entry emails to. This replaces any current list. If NULL, all existing recipients are removed.
 */
procedure store_email_recipients(
   p_email_recipients in str_tab_t);
/**
 * Sets the email recipients for unauthorized scheduler entry emails.
 *
 * @param p_email_recipients The email addresses to send noticies of unauthorized scheduler entry emails to, in comma-separated form. This replaces any current list. If NULL, all existing recipients are removed.
 */
procedure store_email_recipients(
   p_email_recipients in varchar2);
/**
 * Adds a single email recipient for unauthorized scheduler entry emails.
 *
 * @param p_email_recipient An additional email addresses to send noticies of unauthorized scheduler entry emails to.
 */
procedure add_email_recipient(
   p_email_recipient in varchar2);
/**
 * Removes a single email recipient for unauthorized scheduler entry emails.
 *
 * @param p_email_recipient The email addresses to remove from noticies of unauthorized scheduler entry emails.
 */
procedure delete_email_recipient(
   p_email_recipient in varchar2);
/**
 * Removes all email recipients from noticies of unauthorized scheduler entry emails.
 */
procedure delete_email_recipients;
/**
 * Retrieves all email recipients of unathorized scheduler entry emails.
 *
 * @param p_email_recipients The current email recipients of unauthorized scheduler entry emails.
 */
procedure retrieve_email_recipients(
   p_email_recipients out str_tab_t);
/**
 * Retrieves all email recipients of unathorized scheduler entry emails.
 *
 * @return The current email recipients of unauthorized scheduler entry emails.
 */
function retrieve_email_recipients_f
   return str_tab_t;
/**
 * Retrieves a catalog of email recipients of unauthorized scheduler entry emails.
 *
 * @param p_cat_cursor The list of recipient email addresses in a single varchar2(256) field named ''recipient''
 */
procedure cat_email_recipients(
   p_cat_cursor out sys_refcursor);
/**
 * Retrieves a catalog of email recipients of unauthorized scheduler entry emails.
 *
 * @return The list of recipient email addresses in a single varchar2(256) field named ''recipient''
 */
function cat_email_recipients_f
   return sys_refcursor;
/*
 * Not documented
 */
procedure check_scheduler_entries;
procedure start_check_sched_entries_job;
procedure stop_check_sched_entries_job;

end cwms_scheduler_auth;
/
show errors