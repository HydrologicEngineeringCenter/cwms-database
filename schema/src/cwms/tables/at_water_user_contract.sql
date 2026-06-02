CREATE TABLE at_water_user_contract
(
   water_user_contract_code      NUMBER(14)        NOT NULL,
   water_user_code               NUMBER(14)        NOT NULL,
   contract_name                 VARCHAR2(64 BYTE) NOT NULL,
   contracted_storage            BINARY_DOUBLE     NOT NULL,
--   contract_documents            VARCHAR2(64 BYTE) NOT NULL,
   water_supply_contract_type    NUMBER(14)        NOT NULL,
   ws_contract_effective_date    DATE,
   ws_contract_expiration_date   DATE,
   initial_use_allocation        BINARY_DOUBLE,
   future_use_allocation         BINARY_DOUBLE,
   future_use_percent_activated  BINARY_DOUBLE,
   total_alloc_percent_activated BINARY_DOUBLE,
   pump_out_location_code      NUMBER(14), --pump-out
   pump_out_below_location_code          NUMBER(14), --pump-out below
   pump_in_location_code         NUMBER(14),
   storage_unit_code             NUMBER(14)
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
COMMENT ON COLUMN at_water_user_contract.water_user_contract_code IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.';
COMMENT ON COLUMN at_water_user_contract.water_user_code IS 'The water user that has a contract for water storage at a project.  See table AT_WATER_USER.';
COMMENT ON COLUMN at_water_user_contract.contract_name IS 'The identification name for the contract for this water user contract';
COMMENT ON COLUMN at_water_user_contract.contracted_storage IS 'The contracted storage amount for this water user contract';
--COMMENT ON COLUMN at_water_user_contract.contract_documents IS 'The documents for the contract';
COMMENT ON COLUMN at_water_user_contract.water_supply_contract_type IS 'The type of water supply contract.  Constrained by a foreign key to a lookup table';
COMMENT ON COLUMN at_water_user_contract.ws_contract_effective_date IS 'The start date of the contract for this water user contract';
COMMENT ON COLUMN at_water_user_contract.ws_contract_expiration_date IS 'The expiration date for the contract of this water user contract';
COMMENT ON COLUMN at_water_user_contract.initial_use_allocation IS 'The initial contracted allocation for this water user contract';
COMMENT ON COLUMN at_water_user_contract.future_use_allocation IS 'The future contracted allocation for this water user contract';
COMMENT ON COLUMN at_water_user_contract.future_use_percent_activated IS 'The percent allocated future use for this water user contract';
COMMENT ON COLUMN at_water_user_contract.total_alloc_percent_activated IS 'The percentage of total allocation for this water user contract';
COMMENT ON COLUMN at_water_user_contract.pump_out_location_code IS 'The code for the AT_PHYSICAL_LOCATION record which is the location where this water with be withdrawn from the permanent pool';
COMMENT ON COLUMN at_water_user_contract.pump_out_below_location_code IS 'The AT_PHYSICAL_LOCATION record which is the location where this water will be obtained below the dam or within the outlet works';
COMMENT ON COLUMN at_water_user_contract.pump_in_location_code IS 'The AT_PHYSICAL_LOCATION record that identifies the project sub location where water is released into the permanent pool by pumping or gravity flow';
COMMENT ON COLUMN at_water_user_contract.storage_unit_code IS 'The unit of storage for this water user contract';

ALTER TABLE at_water_user_contract ADD (
  CONSTRAINT at_water_user_contract_pk
 PRIMARY KEY
 (water_user_contract_code)
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

CREATE UNIQUE INDEX at_water_user_contract_idx1 ON at_water_user_contract
(water_user_code,upper(contract_name))
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

ALTER TABLE at_water_user_contract ADD (
  CONSTRAINT at_water_user_contract_fk2
 FOREIGN KEY (water_user_code)
 REFERENCES at_water_user (water_user_code))
/

ALTER TABLE at_water_user_contract ADD (
  CONSTRAINT at_water_user_contract_fk3
 FOREIGN KEY (pump_out_location_code)
 REFERENCES at_pump (pump_location_code))
/
ALTER TABLE at_water_user_contract ADD (
  CONSTRAINT at_water_user_contract_fk1
 FOREIGN KEY (pump_out_below_location_code)
 REFERENCES at_pump (pump_location_code))
/
ALTER TABLE at_water_user_contract ADD (
  CONSTRAINT at_water_user_contract_fk6
 FOREIGN KEY (pump_in_location_code)
 REFERENCES at_pump (pump_location_code))
/

ALTER TABLE at_water_user_contract ADD (
  CONSTRAINT at_water_user_contract_fk4
 FOREIGN KEY (water_supply_contract_type)
 REFERENCES at_ws_contract_type (ws_contract_type_code))
/

ALTER TABLE at_water_user_contract ADD (
  CONSTRAINT at_water_user_contract_fk5
 FOREIGN KEY (storage_unit_code)
 REFERENCES cwms_unit (unit_code))
/

create or replace trigger at_water_user_contract_t01
for insert or update of pump_out_location_code, pump_out_below_location_code, pump_in_location_code
on at_water_user_contract
compound trigger

   type l_pumps_t is table of boolean index by varchar2(16);
   l_pumps l_pumps_t;

   before statement is
   begin
      for rec in (select pump_out_location_code as pump_code
                    from at_water_user_contract
                   where pump_out_location_code is not null
                  union all
                  select pump_out_below_location_code as pump_code
                    from at_water_user_contract
                   where pump_out_below_location_code is not null
                  union all
                  select pump_in_location_code as pump_code
                    from at_water_user_contract
                   where pump_in_location_code is not null
                 )
      loop
         l_pumps(to_char(rec.pump_code)) := true;
      end loop;
   end before statement;

   before each row is
   begin
      if :new.pump_out_location_code       = :new.pump_out_below_location_code or
         :new.pump_out_location_code       = :new.pump_in_location_code        or
         :new.pump_out_below_location_code = :new.pump_in_location_code
      then
         cwms_err.raise('ERROR', 'Water supply contract cannot have same pump in mulitple locations');
      end if;
      -----------------------
      -- pump_out_location --
      -----------------------
      if :new.pump_out_location_code is not null then
         if l_pumps.exists(:new.pump_out_location_code) and :new.pump_out_location_code != nvl(:old.pump_out_location_code, 0) then
            cwms_err.raise('ERROR', 'Pump out location is already used in another water supply contract');
         else
            l_pumps(to_char(:new.pump_out_location_code)) := true;
         end if;
      end if;
      -----------------------------
      -- pump_out_below_location --
      -----------------------------
      if :new.pump_out_below_location_code is not null then
         if l_pumps.exists(:new.pump_out_below_location_code) and :new.pump_out_below_location_code != nvl(:old.pump_out_below_location_code, 0)  then
            cwms_err.raise('ERROR', 'Pump out below location is already used in another water supply contract');
         else
            l_pumps(to_char(:new.pump_out_below_location_code)) := true;
         end if;
      end if;
      ----------------------
      -- pump_in_location --
      ----------------------
      if :new.pump_in_location_code is not null then
         if l_pumps.exists(:new.pump_in_location_code) and :new.pump_in_location_code != nvl(:old.pump_in_location_code, 0) then
            cwms_err.raise('ERROR', 'Pump in location is already used in another water supply contract');
         else
            l_pumps(to_char(:new.pump_in_location_code)) := true;
         end if;
      end if;
   end before each row;

end at_water_user_contract_t01;
/
