-- SQL Loader Control and Data File created by TOAD
-- Variable length, terminated enclosed data formatting
-- 
-- The format for executing this file with SQL Loader is:
-- SQLLDR control=<filename> Be sure to substitute your
-- version of SQL LOADER and the filename for this file.
--
-- Note: Nested table datatypes are not supported here and
--       will be exported as nulls.
OPTIONS (DIRECT=FALSE, PARALLEL=FALSE)
LOAD DATA
INFILE *
BADFILE './CWMS_VERTCON_HEADER.BAD'
DISCARDFILE './CWMS_VERTCON_HEADER.DSC'
APPEND INTO TABLE CWMS_VERTCON_HEADER
Fields terminated by ";" Optionally enclosed by '"'
(
  DATASET_CODE NULLIF (DATASET_CODE="NULL"),
  OFFICE_CODE NULLIF (OFFICE_CODE="NULL"),
  DATASET_ID,
  MIN_LAT NULLIF (MIN_LAT="NULL"),
  MAX_LAT NULLIF (MAX_LAT="NULL"),
  MIN_LON NULLIF (MIN_LON="NULL"),
  MAX_LON NULLIF (MAX_LON="NULL"),
  MARGIN NULLIF (MARGIN="NULL"),
  DELTA_LAT NULLIF (DELTA_LAT="NULL"),
  DELTA_LON NULLIF (DELTA_LON="NULL")
)
BEGINDATA
1;53;"vertconw.94";24;50;-125;-102;0;0.05;0.05
2;53;"vertconc.94";24;50;-107;-84;0;0.05;0.05
3;53;"vertcone.94";24;50;-89;-66;0;0.05;0.05
