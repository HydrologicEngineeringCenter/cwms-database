alter table CWMS_STATE add nation_code VARCHAR2(2);

UPDATE CWMS_STATE
SET nation_code =  CASE
                        WHEN STATE_INITIAL in ('AB','BC','MB','NB','NF','NS','NT','NU','ON','PE','QC','SK','YT') THEN
                          'CA'
                        WHEN STATE_INITIAL = '00' THEN
                           null
                        ELSE
                          'US'
                     END;

alter table cwms_state add constraint cwms_state_fk1 foreign key (nation_code) references cwms_nation_sp (fips_cntry);
commit;