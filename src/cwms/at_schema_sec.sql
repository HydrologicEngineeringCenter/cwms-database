/* Formatted on 7/6/2009 7:18:08 AM (QP5 v5.115.810.9015) */
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

@@defines.sql

CREATE TABLE at_sec_locked_users
(
	db_office_code 					NUMBER,
	username 							VARCHAR2 (31 BYTE),
	is_locked							VARCHAR2 (1 BYTE)
)
TABLESPACE CWMS_20AT_DATA
PCTUSED 0
PCTFREE 10
INITRANS 1
MAXTRANS 255
STORAGE (INITIAL 64 K
			MINEXTENTS 1
			MAXEXTENTS UNLIMITED
			PCTINCREASE 0
			BUFFER_POOL DEFAULT
		  )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/

CREATE UNIQUE INDEX at_sec_locked_users_pk
	ON at_sec_locked_users (db_office_code, username)
	LOGGING
	tablespace CWMS_20AT_DATA
	PCTFREE 10
	INITRANS 2
	MAXTRANS 255
	STORAGE (INITIAL 64 K
				MINEXTENTS 1
				MAXEXTENTS UNLIMITED
				PCTINCREASE 0
				BUFFER_POOL DEFAULT
			  )
	NOPARALLEL
/

ALTER TABLE at_sec_locked_users ADD (
  CONSTRAINT at_sec_locked_users_pk
 PRIMARY KEY
 (db_office_code, username)
	 USING INDEX
	 tablespace CWMS_20AT_DATA
	 PCTFREE 	10
	 INITRANS	2
	 MAXTRANS	255
	 STORAGE 	(
					 INITIAL 			64K
					 MINEXTENTS 		1
					 MAXEXTENTS 		UNLIMITED
					 PCTINCREASE		0
					))
/


--------------------------------------------------------------------------------

--=============================================================================
--=============================================================================
--

CREATE TABLE cwms_sec_privileges
(
	privilege_bit						NUMBER,
	privilege_id						VARCHAR2 (16 BYTE)
)
TABLESPACE CWMS_20AT_DATA
PCTUSED 0
PCTFREE 10
INITRANS 1
MAXTRANS 255
STORAGE (INITIAL 64 K
			MINEXTENTS 1
			MAXEXTENTS 2147483645
			PCTINCREASE 0
			BUFFER_POOL DEFAULT
		  )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/

CREATE UNIQUE INDEX cwms_sec_privileges_pk
	ON cwms_sec_privileges (privilege_bit)
	LOGGING
	tablespace CWMS_20AT_DATA
	PCTFREE 10
	INITRANS 2
	MAXTRANS 255
	STORAGE (INITIAL 64 K
				MINEXTENTS 1
				MAXEXTENTS 2147483645
				PCTINCREASE 0
				BUFFER_POOL DEFAULT
			  )
	NOPARALLEL
/

ALTER TABLE cwms_sec_privileges ADD (
  CONSTRAINT cwms_sec_privileges_pk
 PRIMARY KEY
 (privilege_bit)
	 USING INDEX
	 tablespace CWMS_20AT_DATA
	 PCTFREE 	10
	 INITRANS	2
	 MAXTRANS	255
	 STORAGE 	(
					 INITIAL 			64 K
					 MINEXTENTS 		1
					 MAXEXTENTS 		2147483645
					 PCTINCREASE		0
					))
/
SET DEFINE OFF;

INSERT INTO cwms_sec_privileges (privilege_bit, privilege_id
										  )
  VALUES   (2, 'Write'
			  );

INSERT INTO cwms_sec_privileges (privilege_bit, privilege_id
										  )
  VALUES   (4, 'Read'
			  );

COMMIT;
--
--=============================================================================
--=============================================================================
--

SET define on

--
--=============================================================================
--=============================================================================
--

CREATE TABLE at_sec_user_groups
(
	db_office_code 					NUMBER,
	user_group_code					NUMBER,
	user_group_id						VARCHAR2 (32 BYTE),
	user_group_desc					VARCHAR2 (256 BYTE)
)
tablespace CWMS_20AT_DATA
PCTUSED 0
PCTFREE 10
INITRANS 1
MAXTRANS 255
STORAGE (INITIAL 64 K
			MINEXTENTS 1
			MAXEXTENTS 2147483645
			PCTINCREASE 0
			BUFFER_POOL DEFAULT
		  )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/

CREATE UNIQUE INDEX at_sec_user_groups_pk
	ON at_sec_user_groups (db_office_code, user_group_code)
	LOGGING
	tablespace CWMS_20AT_DATA
	PCTFREE 10
	INITRANS 2
	MAXTRANS 255
	STORAGE (INITIAL 64 K
				MINEXTENTS 1
				MAXEXTENTS 2147483645
				PCTINCREASE 0
				BUFFER_POOL DEFAULT
			  )
	NOPARALLEL
/

ALTER TABLE at_sec_user_groups ADD (
  CONSTRAINT at_sec_user_groups_pk
 PRIMARY KEY
 (db_office_code, user_group_code)
	 USING INDEX
	 tablespace CWMS_20AT_DATA
	 PCTFREE 	10
	 INITRANS	2
	 MAXTRANS	255
	 STORAGE 	(
					 INITIAL 			64 K
					 MINEXTENTS 		1
					 MAXEXTENTS 		2147483645
					 PCTINCREASE		0
					))
/
--
--=============================================================================
--=============================================================================
--

CREATE TABLE at_sec_users
(
	db_office_code 					NUMBER,
	user_group_code					NUMBER,
	username								VARCHAR2 (31 BYTE)
)
tablespace CWMS_20AT_DATA
PCTUSED 0
PCTFREE 10
INITRANS 1
MAXTRANS 255
STORAGE (INITIAL 64 K
			MINEXTENTS 1
			MAXEXTENTS 2147483645
			PCTINCREASE 0
			BUFFER_POOL DEFAULT
		  )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/

CREATE UNIQUE INDEX at_sec_users_pk
	ON at_sec_users (db_office_code, user_group_code, username)
	LOGGING
	tablespace CWMS_20AT_DATA
	PCTFREE 10
	INITRANS 2
	MAXTRANS 255
	STORAGE (INITIAL 64 K
				MINEXTENTS 1
				MAXEXTENTS 2147483645
				PCTINCREASE 0
				BUFFER_POOL DEFAULT
			  )
	NOPARALLEL
/

ALTER TABLE at_sec_users ADD (
  CONSTRAINT at_sec_users_pk
 PRIMARY KEY
 (db_office_code, user_group_code, username)
	 USING INDEX
	 tablespace CWMS_20AT_DATA
	 PCTFREE 	10
	 INITRANS	2
	 MAXTRANS	255
	 STORAGE 	(
					 INITIAL 			64 K
					 MINEXTENTS 		1
					 MAXEXTENTS 		2147483645
					 PCTINCREASE		0
					))
/
ALTER TABLE at_sec_users ADD (
  CONSTRAINT at_sec_users_r02
 FOREIGN KEY (username)
 REFERENCES at_sec_cwms_users (userid))
/
ALTER TABLE at_sec_users ADD (
  CONSTRAINT at_sec_users_r01
 FOREIGN KEY (db_office_code, user_group_code)
 REFERENCES at_sec_user_groups (db_office_code,user_group_code))
/
--
--=============================================================================
--=============================================================================
--

CREATE TABLE at_sec_ts_groups
(
	db_office_code 					NUMBER NOT NULL,
	ts_group_code						NUMBER NOT NULL,
	ts_group_id 						VARCHAR2 (32 BYTE) NOT NULL,
	ts_group_desc						VARCHAR2 (256 BYTE)
)
tablespace CWMS_20AT_DATA
PCTUSED 0
PCTFREE 10
INITRANS 1
MAXTRANS 255
STORAGE (INITIAL 64 K
			MINEXTENTS 1
			MAXEXTENTS 2147483645
			PCTINCREASE 0
			BUFFER_POOL DEFAULT
		  )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/

CREATE UNIQUE INDEX at_sec_ts_groups_pk
	ON at_sec_ts_groups (db_office_code, ts_group_code)
	LOGGING
	tablespace CWMS_20AT_DATA
	PCTFREE 10
	INITRANS 2
	MAXTRANS 255
	STORAGE (INITIAL 64 K
				MINEXTENTS 1
				MAXEXTENTS 2147483645
				PCTINCREASE 0
				BUFFER_POOL DEFAULT
			  )
	NOPARALLEL
/

CREATE UNIQUE INDEX at_sec_ts_groups_u01
	ON at_sec_ts_groups (db_office_code, UPPER ("TS_GROUP_ID"))
	LOGGING
	tablespace CWMS_20AT_DATA
	PCTFREE 10
	INITRANS 2
	MAXTRANS 255
	STORAGE (INITIAL 64 K
				MINEXTENTS 1
				MAXEXTENTS 2147483645
				PCTINCREASE 0
				BUFFER_POOL DEFAULT
			  )
	NOPARALLEL
/

ALTER TABLE at_sec_ts_groups ADD (
  CONSTRAINT at_sec_ts_groups_pk
 PRIMARY KEY
 (db_office_code, ts_group_code)
	 USING INDEX
	 tablespace CWMS_20AT_DATA
	 PCTFREE 	10
	 INITRANS	2
	 MAXTRANS	255
	 STORAGE 	(
					 INITIAL 			64 K
					 MINEXTENTS 		1
					 MAXEXTENTS 		2147483645
					 PCTINCREASE		0
					))
/
--
--=============================================================================
--=============================================================================
--

CREATE TABLE at_sec_ts_group_masks
(
	db_office_code 					NUMBER,
	ts_group_code						NUMBER,
	ts_group_mask						VARCHAR2 (256 BYTE)
)
tablespace CWMS_20AT_DATA
PCTUSED 0
PCTFREE 10
INITRANS 1
MAXTRANS 255
STORAGE (INITIAL 64 K
			MINEXTENTS 1
			MAXEXTENTS 2147483645
			PCTINCREASE 0
			BUFFER_POOL DEFAULT
		  )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/

CREATE UNIQUE INDEX at_sec_ts_group_masks_pk
	ON at_sec_ts_group_masks (db_office_code, ts_group_code, ts_group_mask)
	LOGGING
	tablespace CWMS_20AT_DATA
	PCTFREE 10
	INITRANS 2
	MAXTRANS 255
	STORAGE (INITIAL 64 K
				MINEXTENTS 1
				MAXEXTENTS 2147483645
				PCTINCREASE 0
				BUFFER_POOL DEFAULT
			  )
	NOPARALLEL
/

CREATE OR REPLACE TRIGGER at_sec_ts_group_masks_trig
	BEFORE INSERT OR UPDATE OF ts_group_mask
	ON at_sec_ts_group_masks
	REFERENCING NEW AS new OLD AS old
	FOR EACH ROW
DECLARE
BEGIN
	:new.ts_group_mask := UPPER (:new.ts_group_mask);
END;
/

SHOW ERRORS;
ALTER TABLE at_sec_ts_group_masks ADD (
  CONSTRAINT at_sec_ts_group_masks_pk
 PRIMARY KEY
 (db_office_code, ts_group_code, ts_group_mask)
	 USING INDEX
	 tablespace CWMS_20AT_DATA
	 PCTFREE 	10
	 INITRANS	2
	 MAXTRANS	255
	 STORAGE 	(
					 INITIAL 			64 K
					 MINEXTENTS 		1
					 MAXEXTENTS 		2147483645
					 PCTINCREASE		0
					))
/
ALTER TABLE at_sec_ts_group_masks ADD (
  CONSTRAINT at_sec_ts_group_masks_r01
 FOREIGN KEY (db_office_code, ts_group_code)
 REFERENCES at_sec_ts_groups (db_office_code,ts_group_code))
/
--
--=============================================================================
--=============================================================================
--

CREATE TABLE at_sec_allow
(
	db_office_code 					NUMBER,
	ts_group_code						NUMBER,
	user_group_code					NUMBER,
	privilege_bit						NUMBER
)
tablespace CWMS_20AT_DATA
PCTUSED 0
PCTFREE 10
INITRANS 1
MAXTRANS 255
STORAGE (INITIAL 64 K
			MINEXTENTS 1
			MAXEXTENTS 2147483645
			PCTINCREASE 0
			BUFFER_POOL DEFAULT
		  )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/

CREATE UNIQUE INDEX at_sec_allow_pk
	ON at_sec_allow (db_office_code,
						  ts_group_code,
						  user_group_code,
						  privilege_bit
						 )
	LOGGING
	tablespace CWMS_20AT_DATA
	PCTFREE 10
	INITRANS 2
	MAXTRANS 255
	STORAGE (INITIAL 64 K
				MINEXTENTS 1
				MAXEXTENTS 2147483645
				PCTINCREASE 0
				BUFFER_POOL DEFAULT
			  )
	NOPARALLEL
/

ALTER TABLE at_sec_allow ADD (
  CONSTRAINT at_sec_allow_pk
 PRIMARY KEY
 (db_office_code, ts_group_code, user_group_code, privilege_bit)
	 USING INDEX
	 tablespace CWMS_20AT_DATA
	 PCTFREE 	10
	 INITRANS	2
	 MAXTRANS	255
	 STORAGE 	(
					 INITIAL 			64 K
					 MINEXTENTS 		1
					 MAXEXTENTS 		2147483645
					 PCTINCREASE		0
					))
/
ALTER TABLE at_sec_allow ADD (
  CONSTRAINT at_sec_allow_r01
 FOREIGN KEY (db_office_code, ts_group_code)
 REFERENCES at_sec_ts_groups (db_office_code,ts_group_code))
/
ALTER TABLE at_sec_allow ADD (
  CONSTRAINT at_sec_allow_r02
 FOREIGN KEY (db_office_code, user_group_code)
 REFERENCES at_sec_user_groups (db_office_code,user_group_code))
/
ALTER TABLE at_sec_allow ADD (
  CONSTRAINT at_sec_allow_r03
 FOREIGN KEY (privilege_bit)
 REFERENCES cwms_sec_privileges (privilege_bit))
/
--
--=============================================================================
--=============================================================================
--

CREATE TABLE cwms_sec_user_groups
(
	user_group_code					NUMBER,
	user_group_id						VARCHAR2 (32 BYTE) NOT NULL,
	user_group_desc					VARCHAR2 (256 BYTE) NOT NULL
)
tablespace CWMS_20AT_DATA
PCTUSED 0
PCTFREE 10
INITRANS 1
MAXTRANS 255
STORAGE (INITIAL 64 K
			MINEXTENTS 1
			MAXEXTENTS 2147483645
			PCTINCREASE 0
			BUFFER_POOL DEFAULT
		  )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/

CREATE UNIQUE INDEX cwms_sec_user_groups_pk
	ON cwms_sec_user_groups (user_group_code)
	LOGGING
	tablespace CWMS_20AT_DATA
	PCTFREE 10
	INITRANS 2
	MAXTRANS 255
	STORAGE (INITIAL 64 K
				MINEXTENTS 1
				MAXEXTENTS 2147483645
				PCTINCREASE 0
				BUFFER_POOL DEFAULT
			  )
	NOPARALLEL
/

ALTER TABLE cwms_sec_user_groups ADD (
  CONSTRAINT cwms_sec_user_groups_pk
 PRIMARY KEY
 (user_group_code)
	 USING INDEX
	 tablespace CWMS_20AT_DATA
	 PCTFREE 	10
	 INITRANS	2
	 MAXTRANS	255
	 STORAGE 	(
					 INITIAL 			64 K
					 MINEXTENTS 		1
					 MAXEXTENTS 		2147483645
					 PCTINCREASE		0
					))
/
SET DEFINE OFF;

INSERT INTO cwms_sec_user_groups (
												 user_group_code,
												 user_group_id,
												 user_group_desc
			  )
  VALUES   (
					0,
					'CWMS DBA Users',
					'Super CWMS Users - able to assign privileges and read/write to all objects in the database.'
			  );

INSERT INTO cwms_sec_user_groups (
												 user_group_code,
												 user_group_id,
												 user_group_desc
			  )
  VALUES   (
					1,
					'CWMS PD Users',
					'Users that can write to all objects in the database.'
			  );

INSERT INTO cwms_sec_user_groups (
												 user_group_code,
												 user_group_id,
												 user_group_desc
			  )
  VALUES   (
					2,
					'Data Exchange Mgr',
					'Users that will be editing/adding data exchange sets.'
			  );

INSERT INTO cwms_sec_user_groups (
												 user_group_code,
												 user_group_id,
												 user_group_desc
			  )
  VALUES   (
					3,
					'Data Acquisition Mgr',
					'Users that will be editing/changing/managing data streams and time series identifiers.'
			  );

INSERT INTO cwms_sec_user_groups (
												 user_group_code,
												 user_group_id,
												 user_group_desc
			  )
  VALUES   (
					4,
					'TS ID Creator',
					'Users that can add a time series identifier. Note that this privilege does not automatically give the user to read and/or write to the newly created time series id.'
			  );

INSERT INTO cwms_sec_user_groups (
												 user_group_code,
												 user_group_id,
												 user_group_desc
			  )
  VALUES   (
					5,
					'VT Mgr',
					'Users that will manage the validation/alarms/transformation of data.'
			  );

INSERT INTO cwms_sec_user_groups (
												 user_group_code,
												 user_group_id,
												 user_group_desc
			  )
  VALUES   (7, 'CWMS User Admins', 'User who administrates CWMS Users.'
			  );

INSERT INTO cwms_sec_user_groups (
												 user_group_code,
												 user_group_id,
												 user_group_desc
			  )
  VALUES   (10, 'All Users', 'General CWMS Users.'
			  );

INSERT INTO cwms_sec_user_groups (
												 user_group_code,
												 user_group_id,
												 user_group_desc
			  )
  VALUES   (11, 'CWMS Users', 'Routine CWMS Users.'
			  );

INSERT INTO cwms_sec_user_groups (
												 user_group_code,
												 user_group_id,
												 user_group_desc
			  )
  VALUES   (12, 'Viewer Users', 'Limited Access CWMS Users.'
			  );

INSERT INTO cwms_sec_user_groups (
                                                 user_group_code,
                                                 user_group_id,
                                                 user_group_desc
              )
  VALUES   (-1, 'CCP Proc', 'Intended for Service Accounts that will be running CCP daemon services in the background, e.g., the service account running compproc.'
              );
              
INSERT INTO cwms_sec_user_groups (
                                                 user_group_code,
                                                 user_group_id,
                                                 user_group_desc
              )
  VALUES   (-2, 'CCP Mgr', 'Users that will be managing (i.e., adding/modifying) CCP computations. This privilege is intended to be assigned to real people/user accounts.'
              );
              
INSERT INTO cwms_sec_user_groups (
                                                 user_group_code,
                                                 user_group_id,
                                                 user_group_desc
              )
  VALUES   (-3, 'CCP Reviewer', 'Users who will be allowed to review (i.e., read only) an office’s CCP computations.'
              );
COMMIT;
--
--=============================================================================
--=============================================================================
--
-- Load at_sec_user_groups table.

DECLARE
BEGIN
	INSERT INTO at_sec_user_groups
		SELECT	a.office_code, b.user_group_code, b.user_group_id,
					b.user_group_desc
		  FROM	cwms_office a, cwms_sec_user_groups b;
END;
/

--
--=============================================================================
--=============================================================================
--

SET define on
CREATE TABLE cwms_sec_ts_groups
(
	ts_group_code						NUMBER NOT NULL,
	ts_group_id 						VARCHAR2 (32 BYTE) NOT NULL,
	ts_group_desc						VARCHAR2 (256 BYTE) NOT NULL,
	ts_group_mask						VARCHAR2 (183 BYTE) NOT NULL
)
tablespace CWMS_20AT_DATA
PCTUSED 0
PCTFREE 10
INITRANS 1
MAXTRANS 255
STORAGE (INITIAL 64 K
			MINEXTENTS 1
			MAXEXTENTS 2147483645
			PCTINCREASE 0
			BUFFER_POOL DEFAULT
		  )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/

CREATE UNIQUE INDEX cwms_sec_ts_groups_pk
	ON cwms_sec_ts_groups (ts_group_code)
	LOGGING
	tablespace CWMS_20AT_DATA
	PCTFREE 10
	INITRANS 2
	MAXTRANS 255
	STORAGE (INITIAL 64 K
				MINEXTENTS 1
				MAXEXTENTS 2147483645
				PCTINCREASE 0
				BUFFER_POOL DEFAULT
			  )
	NOPARALLEL
/

ALTER TABLE cwms_sec_ts_groups ADD (
  CONSTRAINT cwms_sec_ts_groups_pk
 PRIMARY KEY
 (ts_group_code)
	 USING INDEX
	 tablespace CWMS_20AT_DATA
	 PCTFREE 	10
	 INITRANS	2
	 MAXTRANS	255
	 STORAGE 	(
					 INITIAL 			64 K
					 MINEXTENTS 		1
					 MAXEXTENTS 		2147483645
					 PCTINCREASE		0
					))
/
SET DEFINE OFF;

INSERT INTO cwms_sec_ts_groups (
											  ts_group_code,
											  ts_group_id,
											  ts_group_desc,
											  ts_group_mask
			  )
  VALUES   (0, 'All TS Ids', 'All Time Series Ids', '%'
			  );

INSERT INTO cwms_sec_ts_groups (
											  ts_group_code,
											  ts_group_id,
											  ts_group_desc,
											  ts_group_mask
			  )
  VALUES   (1, 'All Raw TS Ids', 'All Raw Time Series Ids', '%-raw'
			  );

INSERT INTO cwms_sec_ts_groups (
											  ts_group_code,
											  ts_group_id,
											  ts_group_desc,
											  ts_group_mask
			  )
  VALUES   (2, 'All Rev TS Ids', 'All Revised Time Series Ids', '%-rev'
			  );

COMMIT;
--
--=============================================================================
--=============================================================================
--
-- Load at_sec_ts_group and at_sec_allow tables.

/* Formatted on 7/9/2009 12:21:50 PM (QP5 v5.115.810.9015) */
/* Formatted on 7/9/2009 12:27:26 PM (QP5 v5.115.810.9015) */
DECLARE
BEGIN
	--
	INSERT INTO at_sec_ts_groups
		SELECT	a.office_code, b.ts_group_code, b.ts_group_id, b.ts_group_desc
		  FROM	cwms_office a, cwms_sec_ts_groups b;

	INSERT INTO at_sec_ts_group_masks
		SELECT	a.db_office_code, a.ts_group_code, b.ts_group_mask
		  FROM	at_sec_ts_groups a, cwms_sec_ts_groups b
		 WHERE	a.ts_group_code = b.ts_group_code;

	--
	-- set read/write to all ts_ids for cwmspd user
	-- ts_group_code = 0
	-- user_group_code = 1
	-- privilege bits 2 & 4
	--
	INSERT INTO at_sec_allow
		SELECT	office_code, 0, 1, 2
		  FROM	cwms_office
		 WHERE	office_code != 0;

	INSERT INTO at_sec_allow
		SELECT	office_code, 0, 1, 4
		  FROM	cwms_office
		 WHERE	office_code != 0;

	--
	-- set read/write to all ts_ids for cwmspd user
	-- ts_group_code = 0
	-- user_group_code = 0
	-- privilege bits 2 & 4
	--
	INSERT INTO at_sec_allow
		SELECT	office_code, 0, 0, 2
		  FROM	cwms_office
		 WHERE	office_code != 0;

	INSERT INTO at_sec_allow
		SELECT	office_code, 0, 0, 4
		  FROM	cwms_office
		 WHERE	office_code != 0;
END;
/

@@cwms/views/av_sec_ts_privileges_mv
@@cwms/views/av_sec_ts_group_mask
@@cwms/views/av_sec_ts_privileges
@@cwms/views/av_sec_users
@@cwms/views/av_sec_user_groups

--
--=============================================================================
-- mv_sec_ts_privileges
--=============================================================================
--

SET DEFINE ON
CREATE MATERIALIZED VIEW MV_SEC_TS_PRIVILEGES
tablespace CWMS_20AT_DATA
PCTUSED	  0
PCTFREE	  10
INITRANS   2
MAXTRANS   255
STORAGE	  (
				INITIAL			  64K
				NEXT				  1M
				MINEXTENTS		  1
				MAXEXTENTS		  UNLIMITED
				PCTINCREASE 	  0
				BUFFER_POOL 	  DEFAULT
			  )
NOCACHE
LOGGING
NOCOMPRESS
NOPARALLEL
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
WITH PRIMARY KEY
AS
  SELECT   db_office_code, username, ts_code, net_privilege_bit
     FROM  av_sec_ts_privileges_mv
/

COMMENT ON MATERIALIZED VIEW mv_sec_ts_privileges IS
'snapshot table for snapshot MV_SEC_TS_PRIVILEGES'
/

CREATE INDEX mv_sec_ts_privileges_i01
	ON mv_sec_ts_privileges (db_office_code, username)
	LOGGING
	tablespace CWMS_20AT_DATA
	PCTFREE 10
	INITRANS 2
	MAXTRANS 255
	STORAGE (INITIAL 64 K
				NEXT 1 M
				MINEXTENTS 1
				MAXEXTENTS UNLIMITED
				PCTINCREASE 0
				BUFFER_POOL DEFAULT
			  )
	NOPARALLEL;

CREATE INDEX mv_sec_ts_privileges_i02
	ON mv_sec_ts_privileges (username)
	LOGGING
	tablespace CWMS_20AT_DATA
	PCTFREE 10
	INITRANS 2
	MAXTRANS 255
	STORAGE (INITIAL 64 K
				NEXT 1 M
				MINEXTENTS 1
				MAXEXTENTS UNLIMITED
				PCTINCREASE 0
				BUFFER_POOL DEFAULT
			  )
	NOPARALLEL

/

