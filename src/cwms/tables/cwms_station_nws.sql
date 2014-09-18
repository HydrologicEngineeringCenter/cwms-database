CREATE TABLE CWMS_STATION_NWS
(
   "NWS_ID"     VARCHAR2 (5 BYTE),
   "NWS_NAME"   VARCHAR2 (1999 BYTE),
   "LAT"        NUMBER,
   "LON"        NUMBER,
   "SHAPE"      "MDSYS"."SDO_GEOMETRY",
   CONSTRAINT "CWMS_STATION_NWS_PK" PRIMARY KEY
      ("NWS_ID")
      USING INDEX PCTFREE 10
                  INITRANS 2
                  MAXTRANS 255
                  COMPUTE STATISTICS
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
                  TABLESPACE CWMS_20DATA
      ENABLE
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
