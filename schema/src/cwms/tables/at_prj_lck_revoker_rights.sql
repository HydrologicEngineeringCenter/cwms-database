create table at_prj_lck_revoker_rights (
   user_id         varchar2(128),
   office_code     number(14),
   application_id  varchar2(64),
   allow_flag      varchar2(1),
   project_list    varchar2(256),
   constraint at_prj_lck_revoker_rights_pk  primary key (user_id, office_code, application_id, allow_flag),
   constraint at_prj_lck_revoker_rights_ck1 check (user_id = lower(user_id)),
   constraint at_prj_lck_revoker_rights_ck2 check (application_id = lower(application_id)),
   constraint at_prj_lck_revoker_rights_ck3 check (allow_flag in ('T','F'))
)
tablespace cwms_20at_data
/

comment on table at_prj_lck_revoker_rights is 'Contains information about who can revoke project locks';
comment on column at_prj_lck_revoker_rights.user_id        is 'The user whose rights are described';
comment on column at_prj_lck_revoker_rights.office_code    is 'The office the user rights are described for';
comment on column at_prj_lck_revoker_rights.application_id is 'The application the user rights are described for';
comment on column at_prj_lck_revoker_rights.allow_flag     is 'Specifies whether this list is the ALLOW or DISALLOW list';
comment on column at_prj_lck_revoker_rights.project_list   is 'Comma-separated list of project identiers and/or project identifer masks';
