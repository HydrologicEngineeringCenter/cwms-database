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

CREATE TABLE at_sec_dbi_user
(
	db_office_code 					NUMBER,
	dbi_username						VARCHAR2 (31 BYTE) NOT NULL
)
tablespace CWMS_20AT_DATA
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

CREATE UNIQUE INDEX at_dbi_user_pk
	ON at_sec_dbi_user (db_office_code)
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

ALTER TABLE at_sec_dbi_user ADD (
  CONSTRAINT at_dbi_user_pk
 PRIMARY KEY
 (db_office_code)
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
ALTER TABLE at_sec_dbi_user ADD (
  CONSTRAINT at_sec_dbi_user_r01
 FOREIGN KEY (db_office_code)
 REFERENCES cwms_office (office_code))
/

--------------------------------------------------------------------------------
--
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
CREATE TABLE at_sec_user_office
(
	username								VARCHAR2 (31 BYTE),
	user_db_office_code				NUMBER NOT NULL,
	fullname								VARCHAR2 (256 BYTE)
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

CREATE UNIQUE INDEX at_sec_user_office_pk
	ON at_sec_user_office (username)
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

CREATE OR REPLACE TRIGGER at_sec_user_office_trig
	BEFORE INSERT OR UPDATE OF username
	ON at_sec_user_office
	REFERENCING NEW AS new OLD AS old
	FOR EACH ROW
DECLARE
BEGIN
	:new.username := UPPER (:new.username);
END;
/

ALTER TABLE at_sec_user_office ADD (
  CONSTRAINT at_sec_user_office_pk
 PRIMARY KEY
 (username)
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
ALTER TABLE at_sec_user_office ADD (
  CONSTRAINT at_sec_user_office_r01
 FOREIGN KEY (user_db_office_code)
 REFERENCES cwms_office (office_code))
/
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
 REFERENCES at_sec_user_office (username))
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

--
--=============================================================================
-- av_sec_ts_group_mask
--=============================================================================
--

CREATE OR REPLACE FORCE VIEW av_sec_ts_group_mask
(
	db_office_id,
	ts_group_id,
	ts_group_desc,
	ts_group_mask_display,
	db_office_code,
	ts_group_code,
	ts_group_mask
)
AS
	SELECT	    c.office_id db_office_id, 
                b.ts_group_id, 
                b.ts_group_desc,
				CASE 
                  WHEN a.ts_group_mask IS NULL 
                  THEN 
                    NULL 
                  ELSE 
                    cwms_util.denormalize_wildcards (a.ts_group_mask) 
                  END ts_group_mask_display, 
                db_office_code, 
                ts_group_code,
				a.ts_group_mask
	  FROM		at_sec_ts_group_masks a
				RIGHT OUTER JOIN
					at_sec_ts_groups b
				USING (db_office_code, ts_group_code), cwms_office c
	 WHERE	db_office_code = c.office_code AND db_office_code != 0;

/

--
--=============================================================================
-- av_sec_user_groups
--=============================================================================
--

CREATE OR REPLACE FORCE VIEW av_sec_user_groups
(
	db_office_id,
	user_group_type,
	user_group_owner,
	user_group_id,
	user_group_desc,
	db_office_code,
	user_group_code
)
AS
	SELECT	b.office_id db_office_id,
				CASE WHEN a.user_group_code < 10 THEN 'Privilege User Group' ELSE 'TS Collection User Group' END user_group_type,
				CASE WHEN a.user_group_code < 20 THEN 'CWMS' ELSE b.office_id END user_group_owner, a.user_group_id, a.user_group_desc,
				a.db_office_code, a.user_group_code
	  FROM	at_sec_user_groups a, cwms_office b
	 WHERE	b.office_code = a.db_office_code AND a.db_office_code != 0;

/

--
--=============================================================================
-- av_sec_users
--=============================================================================
--

CREATE OR REPLACE FORCE VIEW av_sec_users
(
	username,
	user_db_office_id,
	db_office_id,
	user_group_type,
	user_group_owner,
	user_group_id,
	is_member,
	is_locked,
	user_group_desc,
	user_db_office_code,
	db_office_code,
	user_group_code
)
AS
	SELECT	username, user_db_office_id, db_office_id,
				CASE
					WHEN user_group_code < 10 THEN 'Privilege User Group'
					ELSE 'TS Collection User Group'
				END
					user_group_type,
				CASE WHEN user_group_code < 20 THEN 'CWMS' ELSE db_office_id END
					user_group_owner, user_group_id, is_member,
				CASE WHEN is_locked IS NULL THEN 'F' ELSE is_locked END is_locked,
				user_group_desc, user_db_office_code, db_office_code,
				user_group_code
	  FROM		(SELECT	 username, user_db_office_id, db_office_id,
								 user_group_id, user_group_desc, user_db_office_code,
								 db_office_code db_office_code, user_group_code,
								 CASE
									 WHEN ROWIDTOCHAR (b.ROWID) IS NOT NULL THEN 'T'
									 ELSE 'F'
								 END
									 is_member
						FROM		 (SELECT   a.username,
												  d.office_id user_db_office_id,
												  c.office_id db_office_id,
												  b.user_group_id, b.user_group_desc,
												  a.user_db_office_code, b.db_office_code,
												  b.user_group_code, 'T' is_member
										 FROM   at_sec_user_office a,
												  at_sec_user_groups b,
												  cwms_office c,
												  cwms_office d
										WHERE   b.db_office_code = c.office_code
												  AND a.user_db_office_code =
														  d.office_code) a
								 LEFT OUTER JOIN
									 at_sec_users b
								 USING (username, db_office_code, user_group_code)) a
				LEFT OUTER JOIN
					at_sec_locked_users
				USING (username, db_office_code);

/

--
--=============================================================================
-- av_sec_ts_privileges
--=============================================================================
--

CREATE OR REPLACE FORCE VIEW av_sec_ts_privileges
(
	db_office_code,
	username,
	ts_code,
	net_privilege_bit
)
AS
      SELECT   db_office_code, username, ts_code,
                  SUM (privilege_bit) net_privilege_bit
         FROM   (SELECT    UNIQUE db_office_code, username, ts_code, privilege_bit
                      FROM        (SELECT     db_office_code, username, ts_group_mask,
                                                 privilege_bit
                                        FROM             at_sec_users
                                                     JOIN
                                                         at_sec_allow
                                                     USING (db_office_code, user_group_code)
                                                 JOIN
                                                     at_sec_ts_group_masks
                                                 USING (db_office_code, ts_group_code))
                                JOIN
                                    mv_cwms_ts_id
                                USING (db_office_code)
                     WHERE    UPPER (cwms_ts_id) LIKE ts_group_mask ESCAPE '\')
    GROUP BY   db_office_code, username, ts_code
/
--
--=============================================================================
-- av_sec_ts_privileges_mv
--=============================================================================
--
CREATE OR REPLACE FORCE VIEW av_sec_ts_privileges_mv
(
    db_office_code,
    username,
    ts_code,
    net_privilege_bit
)
AS
    SELECT    db_office_code, username, ts_code, net_privilege_bit
      FROM        av_sec_ts_privileges
                JOIN
                    at_sec_locked_users
                USING (db_office_code, username)
     WHERE    is_locked != 'T'
/

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

CREATE TABLE CWMS_20.AT_SEC_CWMS_PERMISSIONS
(
  USERNAME        VARCHAR2(31 BYTE)             NOT NULL,
  DB_OFFICE_CODE  NUMBER,
  PERMISSIONS     VARCHAR2(1028 BYTE)           NOT NULL
)
TABLESPACE CWMS_20DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING

/

COMMENT ON TABLE CWMS_20.AT_SEC_CWMS_PERMISSIONS IS 'Table to store CWMS PERMISSIONS in the database'

/



CREATE UNIQUE INDEX CWMS_20.AT_SEC_CWMS_PERMISSIONS_PK1 ON CWMS_20.AT_SEC_CWMS_PERMISSIONS
(USERNAME)
LOGGING
TABLESPACE CWMS_20DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL

/


ALTER TABLE CWMS_20.AT_SEC_CWMS_PERMISSIONS ADD (
  CONSTRAINT AT_SEC_CWMS_PERMISSIONS_PK1
  PRIMARY KEY
  (USERNAME)
  USING INDEX CWMS_20.AT_SEC_CWMS_PERMISSIONS_PK1)

/

ALTER TABLE CWMS_20.AT_SEC_CWMS_PERMISSIONS ADD (
  CONSTRAINT AT_SEC_CWMS_PERMISSIONS_FK1 
  FOREIGN KEY (DB_OFFICE_CODE) 
  REFERENCES CWMS_20.CWMS_OFFICE (OFFICE_CODE),
  CONSTRAINT AT_SEC_CWMS_PERMISSIONS_FK2 
  FOREIGN KEY (USERNAME) 
  REFERENCES CWMS_20.AT_SEC_USER_OFFICE (USERNAME))

/
