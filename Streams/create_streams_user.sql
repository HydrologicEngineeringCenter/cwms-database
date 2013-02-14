Rem
Rem $Header: rdbms/demo/eds/create_adm.sql st_server_juyuan_eds_downstream_2/1 2008/08/26 09:27:03 juyuan Exp $
Rem
Rem create_adm.sql
Rem
Rem Copyright (c) 2007, 2008, Oracle. All rights reserved.
Rem
Rem    NAME
Rem      create_adm.sql - create Streams admin user script
Rem
Rem    DESCRIPTION
Rem      This script creates a Streams admin user and grant privilege
Rem      to load and run extended_data_type_support
Rem
Rem    NOTES
Rem      None.
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    juyuan      07/28/08 - grant priv to select sys.opqtype$
Rem    juyuan      05/28/08 - grant priv to select sys.lob$, sys.lobcomppart$
Rem                           and sys.partlob$
Rem    juyuan      11/26/07 - Created
Rem

prompt This script will create the Streams administrator user named STRADM
prompt
prompt Enter a user name for the new Streams administrator user:
define stradm = &1
prompt Enter the password to set for the new Streams administrator user:
define stradm_pw = &2
prompt
--------------------------------------------------------
--
-- Create the Streams user for rolling upgrade propagation.
--
--------------------------------------------------------
-- create tablespace &streams_tbs datafile size 100M  autoextend on maxsize unlimited;

CREATE USER &stradm
  IDENTIFIED BY "&stradm_pw"
  DEFAULT TABLESPACE &streams_tbs
  QUOTA UNLIMITED ON &streams_tbs;

grant connect, resource, dba to &stradm;

-- this user is used both for capture and apply
grant select any table to &stradm;
grant insert any table to &stradm;
grant update any table to &stradm;
grant delete any table to &stradm;
grant alter session to &stradm;

grant select_catalog_role to &stradm;
grant create any materialized view to &stradm;
grant execute on dbms_streams_adm to &stradm;
grant execute on dbms_apply_adm to &stradm;
grant execute on dbms_capture_adm to &stradm;
grant execute on dbms_propagation_adm to &stradm;
grant execute on dbms_flashback to cwms_str_adm;
grant execute on dbms_aqadm to &stradm;
grant execute on dbms_recoverable_script to &stradm;
grant execute on dbms_streams_mt to &stradm;
grant execute on dbms_reco_script_invok to &stradm;

grant select on dba_tables to &stradm;
grant select on dba_queues to &stradm;
grant select on dba_tab_columns to &stradm;
grant select on dba_types to &stradm;
grant select on dba_varrays to &stradm;
grant select on dba_indexes to &stradm;
grant select on dba_ind_columns to &stradm;
grant select on dba_tab_columns to &stradm;
grant select on dba_capture to &stradm;
grant select on dba_apply to &stradm;
grant select on dba_propagation to &stradm;
grant select on dba_directories to &stradm;
grant select on dba_recoverable_script to &stradm;
grant select on dba_recoverable_script_params to &stradm;
grant select on dba_streams_unsupported to &stradm;

-- Grant SELECT to certain SYS tables for use by Rolling Upgrade 
-- Workaround code
grant select on sys.obj$ to &stradm;
grant select on sys.tab$ to &stradm;
grant select on sys.col$ to &stradm;
grant select on sys.user$ to &stradm;
grant select on sys.attrcol$ to &stradm;
grant select on sys.coltype$ to &stradm;
grant select on sys.ts$ to &stradm;
grant select on sys.cdef$ to &stradm;
grant select on sys.lob$ to &stradm;
grant select on sys.lobcomppart$ to &stradm;
grant select on sys.partlob$ to &stradm;
grant select on sys.opqtype$ to &stradm;
grant select on sys.ind$ to &stradm;

grant create job to &stradm;
