create table at_application_session (
   uuid       varchar2(32) not null,
   session_id integer      not null,
   constraint at_application_session_pk  primary key (uuid, session_id) using index,
   constraint at_application_session_fk1 foreign key (uuid) references at_application_login (uuid)
) tablespace cwms_20data;

comment on table  at_application_session is 'Holds session ids for logged-in applications';
comment on column at_application_session.uuid       is 'The unique identifier of the logged-in session';
comment on column at_application_session.session_id is 'The AUSID of a session connected from the logged-in application';

create index at_application_session_idx1 on at_application_session (session_id);