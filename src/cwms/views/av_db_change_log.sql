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
 * @field office_id      The office that owns the database
 * @field database_id    The database to which this record applies
 * @field application    The application to which this versioning information has relevance.
 * @field version        The version of the update or install.
 * @field version_date   The date of the version.
 * @field apply_date     The date the version was applied to the database.
 * @field title          The name or title of the version.
 * @field description    A detailed description of the update or install.
*/
');
create or replace force view av_db_change_log
(
   office_id,
   database_id,
   application,
   version,
   version_date,
   apply_date,
   title,
   description
)
as
     select o.office_id,
            l.database_id,
            l.application,
            l.ver_major || '.' || ver_minor || '.' || ver_build,
            l.ver_date,
            l.apply_date,
            l.title,
            l.description
       from cwms_db_change_log l,
            cwms_office o
      where o.office_code = l.office_code
   order by ver_major desc, ver_minor desc, ver_build desc;

show errors;

create or replace public synonym cwms_v_db_change_log for av_db_change_log;
