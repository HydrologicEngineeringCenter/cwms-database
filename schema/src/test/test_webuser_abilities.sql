CREATE OR REPLACE PACKAGE &cwms_schema..test_webuser_abilities AUTHID CURRENT_USER 
AS
    -- %suite(Test WEB SURE has it's extra priveleges in a varies contextx )
    
    -- %test(Can query an AT_ table directly.)
    procedure can_query_at_tables; 
    
    
END;
/

/* Formatted on 2/24/2022 3:11:58 PM (QP5 v5.381) */
CREATE OR REPLACE PACKAGE BODY &cwms_schema..test_webuser_abilities
AS
    procedure can_query_at_tables is
        l_count number;
    begin
      select count(*) into l_count from cwms_20.at_base_location;
      ut.expect(l_count).to_be_greater_or_equal(0);
    end;
END;
/
