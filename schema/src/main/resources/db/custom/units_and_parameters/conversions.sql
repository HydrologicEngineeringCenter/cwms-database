/*CREATE TABLE CWMS_UNIT_CONVERSION
    (
      FROM_UNIT_ID        VARCHAR2(16 BYTE)       NOT NULL,
      TO_UNIT_ID          VARCHAR2(16 BYTE)       NOT NULL,
      ABSTRACT_PARAM_CODE NUMBER(14)              NOT NULL,
      FROM_UNIT_CODE      NUMBER(14)              NOT NULL,
      TO_UNIT_CODE        NUMBER(14)              NOT NULL,
      FACTOR              BINARY_DOUBLE,
      OFFSET              BINARY_DOUBLE,
      FUNCTION            VARCHAR2(64),*/
declare
    p_from_id varchar2(16) := ?;
    p_to_id varchar(16) := ?;
    p_abstract_param_code number(14) := ?
    p_from_unit_code
begin

end;
/