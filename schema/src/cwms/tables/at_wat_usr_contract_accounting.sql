CREATE TABLE at_wat_usr_contract_accounting
(
  wat_usr_contract_acct_code  NUMBER(14)      NOT NULL,
  water_user_contract_code  NUMBER(14)      NOT NULL,
  pump_location_code NUMBER(14) NOT NULL,
  phys_trans_type_code  NUMBER(14)      NOT NULL,
  -- accounting_credit_debit    VARCHAR2(6 BYTE)  NOT NULL,
  pump_flow       BINARY_DOUBLE     NOT NULL,
  transfer_start_datetime   DATE        NOT NULL,
  -- transfer_end_datetime      DATE        NOT NULL,
  accounting_remarks      VARCHAR2(255 BYTE)
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/
COMMENT ON COLUMN at_wat_usr_contract_accounting.wat_usr_contract_acct_code IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.';
COMMENT ON COLUMN at_wat_usr_contract_accounting.water_user_contract_code IS 'The contract identification number for this water movement. SEE AT_WATER_USER_CONTRACT.';
COMMENT ON COLUMN at_wat_usr_contract_accounting.pump_location_code IS 'The AT_PHYSICAL_LOCATION location_code of the pump as referred to in the contract (pump out, pump out below, pump in) used for this water movement.';
COMMENT ON COLUMN at_wat_usr_contract_accounting.phys_trans_type_code IS 'The type of transfer for this water movement.  See AT_phys_trans_type_CODE.';
COMMENT ON COLUMN at_wat_usr_contract_accounting.transfer_start_datetime IS 'The date this water movement began, the end date is defined as the start date of the next accounting.';
-- COMMENT ON COLUMN at_wat_usr_contract_accounting.transfer_end_datetime IS 'the date this water movement ended';
-- COMMENT ON COLUMN at_wat_usr_contract_accounting.accounting_credit_debit IS 'Whether this water movement is a credit or a debit to the contract';
COMMENT ON COLUMN at_wat_usr_contract_accounting.pump_flow IS 'The flow associated with the water accounting record, this value will always be positive.';
COMMENT ON COLUMN at_wat_usr_contract_accounting.accounting_remarks IS 'Any comments regarding this water accounting movement';

ALTER TABLE at_wat_usr_contract_accounting ADD (
  CONSTRAINT at_wat_usr_contr_accounting_pk
 PRIMARY KEY
 (wat_usr_contract_acct_code)
    USING INDEX
    TABLESPACE cwms_20at_data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

CREATE UNIQUE INDEX at_wat_usr_contr_account_idx1 ON at_wat_usr_contract_accounting
(water_user_contract_code,pump_location_code,transfer_start_datetime)
LOGGING
tablespace cwms_20at_data
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/

ALTER TABLE at_wat_usr_contract_accounting ADD (
  CONSTRAINT at_wat_usr_contr_accting_fk1
 FOREIGN KEY (water_user_contract_code)
 REFERENCES at_water_user_contract (water_user_contract_code))
/

ALTER TABLE at_wat_usr_contract_accounting ADD (
  CONSTRAINT at_wat_usr_contr_accting_fk2
 FOREIGN KEY (phys_trans_type_code)
 REFERENCES at_physical_transfer_type (phys_trans_type_code))
/

--ALTER TABLE at_wat_usr_contract_accounting ADD (
--CONSTRAINT acct_credit_or_debit_check
--CHECK ( upper(ACCOUNTING_CREDIT_DEBIT) = 'CREDIT' OR upper(ACCOUNTING_CREDIT_DEBIT) = 'DEBIT'))
--/

ALTER TABLE at_wat_usr_contract_accounting ADD (
  CONSTRAINT at_wat_usr_contr_accting_fk3
 FOREIGN KEY (pump_location_code)
 REFERENCES at_pump (pump_location_code))
/
