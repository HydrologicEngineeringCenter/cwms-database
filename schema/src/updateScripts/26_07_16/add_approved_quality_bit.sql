create table cwms_data_q_approval(
    approval_id varchar2(16) not null,
    description varchar2(80),
    constraint cwms_data_q_approval_pk primary key(approval_id)
)
pctfree 10
pctused 40
initrans 1
maxtrans 255
tablespace cwms_20at_data
storage(
    initial 10k
    next 10k
    minextents 1
    maxextents 200
    pctincrease 25
    freelists 1
    freelist groups 1
    buffer_pool default
);

insert into cwms_data_q_approval(approval_id, description) values('NOT_APPROVED', 'The value has not be manually approved');
insert into cwms_data_q_approval(approval_id, description) values('APPROVED', 'The value has been manually approved');

alter table cwms_data_quality add approval_id varchar2(16);
update cwms_data_quality set approval_id = 'NOT_APPROVED';
commit;
alter table cwms_data_quality modify approval_id not null;

alter table cwms_data_quality add constraint cwms_data_quality_fk0 foreign key(approval_id) references cwms_data_q_approval(approval_id);
comment on column cwms_data_quality.approval_id is 'Foreign key referencing cwms_data_q_approval table by its primary key';

create table tmp_quality as select * from cwms_data_quality;
insert
  into cwms_data_quality
select quality_code + 1073741824, -- 1 << 30
       screened_id,
       validity_id,
       range_id,
       changed_id,
       repl_cause_id,
       repl_method_id,
       test_failed_id,
       protection_id,
       'APPROVED'
  from tmp_quality
 where protection_id = 'PROTECTED';
commit;
drop table tmp_quality;

delete from at_clob where id in ('/VIEWDOCS/AV_DATA_Q_APPROVAL', '/VIEWDOCS/AV_DATA_QUALITY');
drop view av_data_quality;
@@../cwms/views/av_data_q_approval
create or replace public synonym cwms_v_data_q_approval for av_data_q_approval;
@@../cwms/views/av_data_quality
