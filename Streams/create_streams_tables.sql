whenever sqlerror continue;
DROP TABLE &STREAMS_USER..cwms_heartbeat;
whenever sqlerror exit;

CREATE TABLE &STREAMS_USER..cwms_heartbeat
(
   source_db   VARCHAR2 (64) NOT NULL PRIMARY KEY,
   alive       TIMESTAMP
);


whenever sqlerror continue;
DROP TABLE &STREAMS_USER..errorlog; 
whenever sqlerror exit;
CREATE TABLE &STREAMS_USER..errorlog
(
   logdate        DATE,
   apply_name     VARCHAR2 (30),
   sender         VARCHAR2 (100),
   object_name    VARCHAR2 (32),
   command_type   VARCHAR2 (30),
   errnum         NUMBER,
   errmsg         VARCHAR2 (2000),
   text           VARCHAR2 (2000),
   lcr            SYS.LCR$_ROW_RECORD
);
     
COMMIT;

