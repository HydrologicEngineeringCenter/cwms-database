--------------------------------------------------------
--  DDL for Table CWMS_USACE_DAM_STATE
--------------------------------------------------------

CREATE TABLE "CWMS_USACE_DAM_STATE"
(
   "STATE_ID"      INTEGER,
   "STATE_NAME"    VARCHAR2 (150 BYTE),
   "STATE_ABBR"    VARCHAR2 (30 BYTE),
   "DISTRICT_ID"   INTEGER
)
SEGMENT CREATION IMMEDIATE
PCTFREE 10
PCTUSED 40
INITRANS 1
MAXTRANS 255
NOCOMPRESS
LOGGING
STORAGE (INITIAL 65536
         NEXT 1048576
         MINEXTENTS 1
         MAXEXTENTS 2147483645
         PCTINCREASE 0
         FREELISTS 1
         FREELIST GROUPS 1
         BUFFER_POOL DEFAULT
         FLASH_CACHE DEFAULT
         CELL_FLASH_CACHE DEFAULT)
TABLESPACE CWMS_20DATA;

REM INSERTING into CWMS_USACE_DAM_STATE
SET DEFINE OFF;

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (1,
             'Alabama',
             'AL',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (2,
             'Alaska',
             'AK',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (3,
             'Arizona',
             'AZ',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (4,
             'Arkansas',
             'AR',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (5,
             'California',
             'CA',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (6,
             'Colorado',
             'CO',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (7,
             'Connecticut',
             'CT',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (8,
             'Delaware',
             'DE',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (9,
             'Florida',
             'FL',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (10,
             'Georgia',
             'GA',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (11,
             'Hawaii',
             'HI',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (12,
             'Idaho',
             'ID',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (13,
             'Illinois',
             'IL',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (14,
             'Indiana',
             'IN',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (15,
             'Iowa',
             'IA',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (16,
             'Kansas',
             'KS',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (17,
             'Kentucky',
             'KY',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (18,
             'Louisiana',
             'LA',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (19,
             'Maine',
             'ME',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (20,
             'Maryland',
             'MD',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (21,
             'Massachusetts',
             'MA',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (22,
             'Michigan',
             'MI',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (23,
             'Minnesota',
             'MN',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (24,
             'Mississippi',
             'MS',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (25,
             'Missouri',
             'MO',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (26,
             'Montana',
             'MT',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (27,
             'Nebraska',
             'NE',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (28,
             'Nevada',
             'NV',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (29,
             'New Hampshire',
             'NH',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (30,
             'New Jersey',
             'NJ',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (31,
             'New Mexico',
             'NM',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (32,
             'New York',
             'NY',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (33,
             'North Carolina',
             'NC',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (34,
             'North Dakota',
             'ND',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (35,
             'Ohio',
             'OH',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (36,
             'Oklahoma',
             'OK',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (37,
             'Oregon',
             'OR',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (38,
             'Pennsylvania',
             'PA',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (39,
             'Rhode Island',
             'RI',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (40,
             'South Carolina',
             'SC',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (41,
             'South Dakota',
             'SD',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (42,
             'Tennessee',
             'TN',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (43,
             'Texas',
             'TX',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (44,
             'Utah',
             'UT',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (45,
             'Vermont',
             'VT',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (46,
             'Virginia',
             'VA',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (47,
             'Washington',
             'WA',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (48,
             'West Virginia',
             'WV',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (49,
             'Wisconsin',
             'WI',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (50,
             'Wyoming',
             'WY',
             NULL);

INSERT INTO CWMS_USACE_DAM_STATE (STATE_ID,
                               STATE_NAME,
                               STATE_ABBR,
                               DISTRICT_ID)
     VALUES (51,
             'Puerto Rico',
             'PR',
             NULL);

--------------------------------------------------------
--  Constraints for Table CWMS_USACE_DAM_STATE
--------------------------------------------------------

  ALTER TABLE "CWMS_USACE_DAM_STATE" MODIFY ("STATE_ABBR" NOT NULL ENABLE);
  ALTER TABLE "CWMS_USACE_DAM_STATE" MODIFY ("STATE_NAME" NOT NULL ENABLE);
  ALTER TABLE "CWMS_USACE_DAM_STATE" MODIFY ("STATE_ID" NOT NULL ENABLE);
