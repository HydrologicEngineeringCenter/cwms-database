whenever sqlerror continue;
insert into cwms_db_change_log (application,
                              ver_major,
                              ver_minor,
                              ver_build,
                              ver_date,
                              title,
                              description)
     values ('CWMS',
             3,
             0,
             1,
             to_date ('04SEP2015', 'DDMONYYYY'),
             'CWMS Database Release 3.0.1',
             'Added some new unit conversions.
Added some views for upward reporting.
Updated CMA support to version 2.02.
Added capability to send e-mail from database routines.
Added database schema versioning.
Various bug fixes and minor API improvements.');

insert into cwms_db_change_log (application,
                              ver_major,
                              ver_minor,
                              ver_build,
                              ver_date,
                              title,
                              description)
     values ('CWMS', 
             3,
             0,
             2,
             to_date ('21OCT2015', 'DDMONYYYY'),
             'CWMS Database Release 3.0.2',
             'Fixed bug where some routines consumed excessive amounts of sequence values.
Changed to allow multiple stream locations to share the same station on a stream             
Various other fixes.');

insert into cwms_db_change_log (application,
                              ver_major,
                              ver_minor,
                              ver_build,
                              ver_date,
                              title,
                              description)
     values ('CWMS', 
             3,
             0,
             3,
             to_date ('20JAN2016', 'DDMONYYYY'),
             'CWMS Database Release 3.0.3',
             'Added supoort for read-only implementation.
Added views needed for CCP datchk validation
');

insert into cwms_db_change_log (application,
                              ver_major,
                              ver_minor,
                              ver_build,
                              ver_date,
                              title,
                              description)
     values ('CWMS', 
             3,
             0,
             4,
             to_date ('01JUN2016', 'DDMONYYYY'),
             'CWMS Database Release 3.0.4',
             'Changed structure of stream reaches.
Added CWMS RADAR routines.
Improved functionality for retrieving ratings, time series, and stream measurements from USGS.
Modified source agency references for stream rating specifications and stream flow measurements.             
Modified location kind STREAMGAGE to STREAM_LOCATION.
Added location kinds ENTITY, PUMP, STREAM_GAGE, STREAM_REACH, and WEATHER_GAGE.
Added functionality for location kinds GATE and OVERFLOW.
');

insert into cwms_db_change_log (application,
                              ver_major,
                              ver_minor,
                              ver_build,
                              ver_date,
                              title,
                              description)
     values ('CWMS',
             3,
             0,
             5,
             to_date ('30NOV2016', 'DDMONYYYY'),
             'CWMS Database Release 3.0.5',
             'Fixed bug that prevented deletion of locations with named local vertical datums.
Fixed bugs that kept elevation location levels from observing default or explicit vertical datums.
Added unit ''knot''.
');

insert into cwms_db_change_log (application,
                              ver_major,
                              ver_minor,
                              ver_build,
                              ver_date,
                              title,
                              description)
     values ('CWMS',
             3,
             0,
             6,
             to_date ('19JAN2017', 'DDMONYYYY'),
             'CWMS Database Release 3.0.6',
             'Support for storing EDIPI number
Inserting RDL roles into cwms_user_sec_groups');

insert into cwms_db_change_log (application,
                              ver_major,
                              ver_minor,
                              ver_build,
                              ver_date,
                              title,
                              description)
     values ('CWMS',
             3,
             0,
             7,
             to_date ('10MAR2017', 'DDMONYYYY'),
             'CWMS Database Release 3.0.7',
             'Support for CAC authentication');
commit;
whenever sqlerror exit;

