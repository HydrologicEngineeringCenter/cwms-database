CREATE OR REPLACE PACKAGE &cwms_schema..test_multiple_office_perms AUTHID CURRENT_USER 
AS
    --%suite(Test User with multiple office permissions can login and do work )
    --%rollback(manual)

    --%test
    procedure can_create_hq_loc;

    --%test
    procedure can_create_poa_loc;

    --%test
    procedure can_create_build_office_loc;

END;
/

CREATE OR REPLACE PACKAGE BODY &cwms_schema..test_multiple_office_perms
AS

    procedure can_create_hq_loc is
        l_count number;
    begin
        cwms_env.set_session_office_id('HQ');
        cwms_loc.store_location(p_location_id=>'TestLocHQ',
                                p_active         => 'T',
                                p_db_office_id=>'HQ');
        select count(*) into l_count from cwms_20.av_loc where unit_system='EN' and location_id='TestLocHQ' and db_office_id='HQ';
        ut.expect(l_count).to_equal(1);
    end;

    procedure can_create_poa_loc is
        l_count number;
    begin
        cwms_env.set_session_office_id('POA');
        cwms_loc.store_location(p_location_id=>'TestLocPOA',
                                p_active         => 'T',
                                p_db_office_id=>'POA');
        select count(*) into l_count from cwms_20.av_loc where unit_system='EN' and location_id='TestLocPOA' and db_office_id='POA';
        ut.expect(l_count).to_equal(1);
    end;

    procedure can_create_build_office_loc is
        l_count number;
    begin
        cwms_env.set_session_office_id('&office_id');
        cwms_loc.store_location(p_location_id=>'TestLoc&office_id',
                                p_active         => 'T',
                                p_db_office_id=>'&office_id');
        select count(*) into l_count from cwms_20.av_loc where unit_system='EN' and location_id='TestLoc&office_id' and db_office_id='&office_id';
        ut.expect(l_count).to_equal(1);
    end;


END;
/
