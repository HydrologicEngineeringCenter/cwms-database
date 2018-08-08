--
-- AV_DB_CHANGE_LOG    (View)
--
--  Dependencies:
--   AT_DB_CHANGE_LOG
--

insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_DB_CHANGE_LOG', null,
'
/**
 * Displays DB Updates and Changes
 *
 * @since CWMS 3.0
 *
 * @field application     The application that this versioning information has relevance.
 * @field version        The version of the update or install.
 * @field version_date   The date of the version.
 * @field apply_date     The date the version was applied to the database.
 * @field title          The name or title of the version.
 * @field description    A detailed description of the update or install.
*/
');
create or replace force view av_db_change_log
(
   application,
   version,
   version_date,
   apply_date,
   title,
   description
)
as
     select application,
            ver_major || '.' || ver_minor || '.' || ver_build,
            ver_date,
            apply_date,
            title,
            description
       from cwms_db_change_log
   order by ver_major desc, ver_minor desc, ver_build desc;

/

show errors;