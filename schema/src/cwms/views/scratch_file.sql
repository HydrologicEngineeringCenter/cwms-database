with paged_ref as (
   select
      r.location_level_code,
      r.location_level_id,
      r.attribute_id,
      r.office_id,
      r.location_level_date,
      r.location_id,
      r.parameter_id,
      r.parameter_type_id,
      r.duration_id,
      r.specified_level_id,
      r.expiration_date
   from av_location_level_ref r
   where r.office_id = 'NWDP'
   order by
      r.location_id,
      r.parameter_id,
      r.parameter_type_id,
      r.duration_id,
      r.specified_level_id,
      r.location_level_date
   offset 1000 rows fetch next 1000 rows only
)
select
   p.office_id,
   p.location_level_id,
   p.attribute_id,
   p.location_level_id,
   p.location_level_date,
   p.location_id,
   p.parameter_id,
   p.parameter_type_id,
   p.duration_id,
   p.specified_level_id,
   p.expiration_date,
   v.constant_level_si,
   v.seasonal_value_si,
   v.tsid,
   v.attribute_value_si,
   v.level_unit_si,
   v.attribute_unit_si,
   v.connections,
   v.default_label,
   v.source
from paged_ref p
        left join av_location_level_values v
                  on v.location_level_code = p.location_level_code
order by
   p.location_id,
   p.parameter_id,
   p.parameter_type_id,
   p.duration_id,
   p.specified_level_id,
   p.location_level_date; --[2026-01-29 20:18:40] 500 rows retrieved starting from 1 in 2 s 470 ms (execution: 1 s 731 ms, fetching: 739 ms)
/*
--------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation                                    | Name                          | Rows  | Bytes |TempSpc| Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                             |                               | 89111 |  1392M|       | 21972   (1)| 00:00:01 |
|   1 |  NESTED LOOPS OUTER                          |                               | 89111 |  1392M|       | 21972   (1)| 00:00:01 |
|*  2 |   VIEW                                       |                               |  2000 |    15M|       |  1962   (1)| 00:00:01 |
|*  3 |    WINDOW SORT PUSHED RANK                   |                               |  1031 |  8249K|  8256K|  1962   (1)| 00:00:01 |
|   4 |     VIEW                                     | AV_LOCATION_LEVEL_REF         |  1031 |  8249K|       |   203   (1)| 00:00:01 |
|   5 |      UNION-ALL                               |                               |       |       |       |            |          |
        |   6 |       NESTED LOOPS OUTER                     |                               |   967 |   223K|       |   105   (1)| 00:00:01 |
        |*  7 |        HASH JOIN                             |                               |   967 |   216K|       |   105   (1)| 00:00:01 |
        |   8 |         TABLE ACCESS BY INDEX ROWID          | CWMS_PARAMETER_TYPE           |     7 |    56 |       |     2   (0)| 00:00:01 |
        |*  9 |          INDEX RANGE SCAN                    | CWMS_PARAMETER_TYPE_PK        |     7 |       |       |     1   (0)| 00:00:01 |
        |* 10 |         HASH JOIN                            |                               |   987 |   213K|       |   102   (0)| 00:00:01 |
        |  11 |          TABLE ACCESS FULL                   | AT_BASE_LOCATION              |  5598 | 89568 |       |     7   (0)| 00:00:01 |
        |* 12 |          HASH JOIN                           |                               |  2963 |   593K|       |    95   (0)| 00:00:01 |
        |  13 |           TABLE ACCESS FULL                  | AT_PHYSICAL_LOCATION          |  6709 |   104K|       |    71   (0)| 00:00:01 |
        |* 14 |           HASH JOIN RIGHT OUTER              |                               |  2961 |   546K|       |    24   (0)| 00:00:01 |
        |  15 |            TABLE ACCESS FULL                 | CWMS_BASE_PARAMETER           |    51 |   561 |       |     3   (0)| 00:00:01 |
        |  16 |            NESTED LOOPS OUTER                |                               |  2961 |   514K|       |    21   (0)| 00:00:01 |
        |* 17 |             HASH JOIN                        |                               |  2961 |   456K|       |    21   (0)| 00:00:01 |
        |  18 |              TABLE ACCESS FULL               | AT_SPECIFIED_LEVEL            |   126 |  3276 |       |     3   (0)| 00:00:01 |
        |  19 |              NESTED LOOPS OUTER              |                               |  2961 |   381K|       |    18   (0)| 00:00:01 |
        |* 20 |               HASH JOIN                      |                               |  2961 |   344K|       |    18   (0)| 00:00:01 |
        |  21 |                TABLE ACCESS BY INDEX ROWID   | CWMS_DURATION                 |    61 |   793 |       |     2   (0)| 00:00:01 |
        |* 22 |                 INDEX RANGE SCAN             | CWMS_DURATION_PK              |    61 |       |       |     1   (0)| 00:00:01 |
        |* 23 |                HASH JOIN                     |                               |  2962 |   306K|       |    16   (0)| 00:00:01 |
        |* 24 |                 HASH JOIN                    |                               |   545 | 21255 |       |     7   (0)| 00:00:01 |
        |  25 |                  NESTED LOOPS                |                               |    51 |   969 |       |     4   (0)| 00:00:01 |
        |  26 |                   TABLE ACCESS BY INDEX ROWID| CWMS_OFFICE                   |     1 |     8 |       |     1   (0)| 00:00:01 |
        |* 27 |                    INDEX UNIQUE SCAN         | CWMS_OFFICE_UK                |     1 |       |       |     0   (0)| 00:00:01 |
        |  28 |                   TABLE ACCESS FULL          | CWMS_BASE_PARAMETER           |    51 |   561 |       |     3   (0)| 00:00:01 |
        |  29 |                  TABLE ACCESS FULL           | AT_PARAMETER                  |   545 | 10900 |       |     3   (0)| 00:00:01 |
        |* 30 |                 TABLE ACCESS FULL            | AT_LOCATION_LEVEL             |  2962 |   193K|       |     9   (0)| 00:00:01 |
        |  31 |               TABLE ACCESS BY INDEX ROWID    | CWMS_DURATION                 |     1 |    13 |       |     0   (0)| 00:00:01 |
        |* 32 |                INDEX UNIQUE SCAN             | CWMS_DURATION_PK              |     1 |       |       |     0   (0)| 00:00:01 |
        |  33 |             TABLE ACCESS BY INDEX ROWID      | AT_PARAMETER                  |     1 |    20 |       |     0   (0)| 00:00:01 |
        |* 34 |              INDEX UNIQUE SCAN               | AT_PARAMETER_PK               |     1 |       |       |     0   (0)| 00:00:01 |
        |  35 |        TABLE ACCESS BY INDEX ROWID           | CWMS_PARAMETER_TYPE           |     1 |     8 |       |     0   (0)| 00:00:01 |
        |* 36 |         INDEX UNIQUE SCAN                    | CWMS_PARAMETER_TYPE_PK        |     1 |       |       |     0   (0)| 00:00:01 |
        |* 37 |       HASH JOIN                              |                               |    64 | 13760 |       |    98   (0)| 00:00:01 |
        |  38 |        TABLE ACCESS FULL                     | AT_SPECIFIED_LEVEL            |   126 |  3276 |       |     3   (0)| 00:00:01 |
        |* 39 |        HASH JOIN                             |                               |    64 | 12096 |       |    95   (0)| 00:00:01 |
        |  40 |         TABLE ACCESS BY INDEX ROWID          | CWMS_DURATION                 |    61 |   793 |       |     2   (0)| 00:00:01 |
        |* 41 |          INDEX RANGE SCAN                    | CWMS_DURATION_PK              |    61 |       |       |     1   (0)| 00:00:01 |
        |* 42 |         HASH JOIN                            |                               |    64 | 11264 |       |    93   (0)| 00:00:01 |
        |  43 |          TABLE ACCESS FULL                   | CWMS_BASE_PARAMETER           |    51 |   561 |       |     3   (0)| 00:00:01 |
        |* 44 |          HASH JOIN                           |                               |    64 | 10560 |       |    90   (0)| 00:00:01 |
        |* 45 |           HASH JOIN RIGHT OUTER              |                               |    64 |  9280 |       |    87   (0)| 00:00:01 |
        |  46 |            TABLE ACCESS FULL                 | CWMS_BASE_PARAMETER           |    51 |   561 |       |     3   (0)| 00:00:01 |
        |  47 |            NESTED LOOPS OUTER                |                               |    64 |  8576 |       |    84   (0)| 00:00:01 |
        |  48 |             NESTED LOOPS OUTER               |                               |    64 |  7296 |       |    84   (0)| 00:00:01 |
        |  49 |              NESTED LOOPS OUTER              |                               |    64 |  6784 |       |    84   (0)| 00:00:01 |
        |* 50 |               HASH JOIN                      |                               |    64 |  5952 |       |    84   (0)| 00:00:01 |
        |* 51 |                HASH JOIN                     |                               |   193 | 14861 |       |    77   (0)| 00:00:01 |
        |* 52 |                 HASH JOIN                    |                               |   193 | 11773 |       |     6   (0)| 00:00:01 |
        |  53 |                  NESTED LOOPS                |                               |     7 |   112 |       |     3   (0)| 00:00:01 |
        |  54 |                   TABLE ACCESS BY INDEX ROWID| CWMS_OFFICE                   |     1 |     8 |       |     1   (0)| 00:00:01 |
        |* 55 |                    INDEX UNIQUE SCAN         | CWMS_OFFICE_UK                |     1 |       |       |     0   (0)| 00:00:01 |
        |  56 |                   TABLE ACCESS BY INDEX ROWID| CWMS_PARAMETER_TYPE           |     7 |    56 |       |     2   (0)| 00:00:01 |
        |* 57 |                    INDEX RANGE SCAN          | CWMS_PARAMETER_TYPE_PK        |     7 |       |       |     1   (0)| 00:00:01 |
        |* 58 |                  TABLE ACCESS FULL           | AT_VIRTUAL_LOCATION_LEVEL     |   197 |  8865 |       |     3   (0)| 00:00:01 |
        |  59 |                 TABLE ACCESS FULL            | AT_PHYSICAL_LOCATION          |  6709 |   104K|       |    71   (0)| 00:00:01 |
        |  60 |                TABLE ACCESS FULL             | AT_BASE_LOCATION              |  5598 | 89568 |       |     7   (0)| 00:00:01 |
        |  61 |               TABLE ACCESS BY INDEX ROWID    | CWMS_DURATION                 |     1 |    13 |       |     0   (0)| 00:00:01 |
        |* 62 |                INDEX UNIQUE SCAN             | CWMS_DURATION_PK              |     1 |       |       |     0   (0)| 00:00:01 |
        |  63 |              TABLE ACCESS BY INDEX ROWID     | CWMS_PARAMETER_TYPE           |     1 |     8 |       |     0   (0)| 00:00:01 |
        |* 64 |               INDEX UNIQUE SCAN              | CWMS_PARAMETER_TYPE_PK        |     1 |       |       |     0   (0)| 00:00:01 |
        |  65 |             TABLE ACCESS BY INDEX ROWID      | AT_PARAMETER                  |     1 |    20 |       |     0   (0)| 00:00:01 |
        |* 66 |              INDEX UNIQUE SCAN               | AT_PARAMETER_PK               |     1 |       |       |     0   (0)| 00:00:01 |
        |  67 |           TABLE ACCESS FULL                  | AT_PARAMETER                  |   545 | 10900 |       |     3   (0)| 00:00:01 |
        |  68 |   VIEW PUSHED PREDICATE                      | AV_LOCATION_LEVEL_VALUES      |     1 |  8176 |       |    10   (0)| 00:00:01 |
        |  69 |    NESTED LOOPS OUTER                        |                               |     1 |   355 |       |    10   (0)| 00:00:01 |
        |  70 |     NESTED LOOPS OUTER                       |                               |     1 |   336 |       |     4   (0)| 00:00:01 |
        |  71 |      NESTED LOOPS OUTER                      |                               |     1 |   308 |       |     4   (0)| 00:00:01 |
        |  72 |       NESTED LOOPS OUTER                     |                               |     1 |   298 |       |     4   (0)| 00:00:01 |
        |  73 |        NESTED LOOPS OUTER                    |                               |     1 |   270 |       |     4   (0)| 00:00:01 |
        |  74 |         NESTED LOOPS OUTER                   |                               |     1 |   260 |       |     4   (0)| 00:00:01 |
        |  75 |          NESTED LOOPS OUTER                  |                               |     1 |   148 |       |     3   (0)| 00:00:01 |
        |  76 |           NESTED LOOPS OUTER                 |                               |     1 |   133 |       |     2   (0)| 00:00:01 |
        |  77 |            NESTED LOOPS OUTER                |                               |     1 |    89 |       |     2   (0)| 00:00:01 |
        |  78 |             TABLE ACCESS BY INDEX ROWID      | AT_LOCATION_LEVEL             |     1 |    63 |       |     2   (0)| 00:00:01 |
        |* 79 |              INDEX UNIQUE SCAN               | AT_LOCATION_LEVEL_PK          |     1 |       |       |     1   (0)| 00:00:01 |
        |  80 |             TABLE ACCESS BY INDEX ROWID      | AT_LOC_LVL_SOURCE             |     1 |    26 |       |     0   (0)| 00:00:01 |
        |* 81 |              INDEX UNIQUE SCAN               | AT_LOC_LVL_SOURCE_PK          |     1 |       |       |     0   (0)| 00:00:01 |
        |* 82 |            TABLE ACCESS BY INDEX ROWID       | AT_LOC_LVL_LABEL              |     1 |    44 |       |     0   (0)| 00:00:01 |
        |* 83 |             INDEX UNIQUE SCAN                | AT_LOC_LVL_LABEL_PK           |     1 |       |       |     0   (0)| 00:00:01 |
        |  84 |           TABLE ACCESS BY INDEX ROWID        | AT_VIRTUAL_LOCATION_LEVEL     |     1 |    15 |       |     1   (0)| 00:00:01 |
        |* 85 |            INDEX UNIQUE SCAN                 | AT_VIRTUAL_LOCATION_LEVEL_PK  |     1 |       |       |     0   (0)| 00:00:01 |
        |  86 |          TABLE ACCESS BY INDEX ROWID         | AT_CWMS_TS_ID                 |     1 |   112 |       |     1   (0)| 00:00:01 |
        |* 87 |           INDEX UNIQUE SCAN                  | AT_CWMS_TS_ID_PK              |     1 |       |       |     0   (0)| 00:00:01 |
        |* 88 |         INDEX UNIQUE SCAN                    | CWMS_UNIT_CONVERSION_PK       |     1 |    10 |       |     0   (0)| 00:00:01 |
        |* 89 |        INDEX UNIQUE SCAN                     | CWMS_UNIT_CONVERSION_PK       |     1 |    28 |       |     0   (0)| 00:00:01 |
        |* 90 |       INDEX UNIQUE SCAN                      | CWMS_UNIT_CONVERSION_PK       |     1 |    10 |       |     0   (0)| 00:00:01 |
        |* 91 |      INDEX UNIQUE SCAN                       | CWMS_UNIT_CONVERSION_PK       |     1 |    28 |       |     0   (0)| 00:00:01 |
        |* 92 |     VIEW                                     |                               |     1 |    19 |       |     6   (0)| 00:00:01 |
        |  93 |      NESTED LOOPS                            |                               |     1 |   100 |       |     6   (0)| 00:00:01 |
        |  94 |       NESTED LOOPS OUTER                     |                               |     1 |    82 |       |     2   (0)| 00:00:01 |
        |  95 |        NESTED LOOPS OUTER                    |                               |     1 |    72 |       |     2   (0)| 00:00:01 |
        |  96 |         NESTED LOOPS OUTER                   |                               |     1 |    62 |       |     2   (0)| 00:00:01 |
        |  97 |          NESTED LOOPS OUTER                  |                               |     1 |    34 |       |     2   (0)| 00:00:01 |
        |  98 |           TABLE ACCESS BY INDEX ROWID        | AT_LOCATION_LEVEL             |     1 |    24 |       |     2   (0)| 00:00:01 |
        |* 99 |            INDEX UNIQUE SCAN                 | AT_LOCATION_LEVEL_PK          |     1 |       |       |     1   (0)| 00:00:01 |
        |*100 |           INDEX UNIQUE SCAN                  | CWMS_UNIT_CONVERSION_PK       |     1 |    10 |       |     0   (0)| 00:00:01 |
        |*101 |          INDEX UNIQUE SCAN                   | CWMS_UNIT_CONVERSION_PK       |     1 |    28 |       |     0   (0)| 00:00:01 |
        |*102 |         INDEX UNIQUE SCAN                    | CWMS_UNIT_CONVERSION_PK       |     1 |    10 |       |     0   (0)| 00:00:01 |
        |*103 |        INDEX UNIQUE SCAN                     | CWMS_UNIT_CONVERSION_PK       |     1 |    10 |       |     0   (0)| 00:00:01 |
        | 104 |       TABLE ACCESS BY INDEX ROWID            | AT_SEASONAL_LOCATION_LEVEL    |     1 |    18 |       |     4   (0)| 00:00:01 |
        |*105 |        INDEX RANGE SCAN                      | AT_SEASONAL_LOCATION_LEVEL_PK |     1 |       |       |     3   (0)| 00:00:01 |
--------------------------------------------------------------------------------------------------------------------------------------
*/



SELECT * FROM AV_LOCATION_LEVEL v
order by v.location_id, v.PARAMETER_ID, v.PARAMETER_TYPE_ID, v.DURATION_ID, v.SPECIFIED_LEVEL_ID, v.LEVEL_DATE
offset 1000 rows fetch next 1000 rows only; -- [2026-01-29 20:17:05] 500 rows retrieved starting from 1 in 35 s 768 ms (execution: 35 s 134 ms, fetching: 634 ms)

/*
 Plan hash value: 1262105393

-------------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation                                           | Name                        | Rows  | Bytes |TempSpc| Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                                    |                             |  2000 |    43M|       |    41M  (1)| 00:27:01 |
|*  1 |  VIEW                                               |                             |  2000 |    43M|       |    41M  (1)| 00:27:01 |
|*  2 |   WINDOW SORT PUSHED RANK                           |                             |  7126K|   124G|    54G|    41M  (1)| 00:27:01 |
|   3 |    VIEW                                             | AV_LOCATION_LEVEL           |  7126K|   124G|       |    13M  (1)| 00:08:59 |
|   4 |     TEMP TABLE TRANSFORMATION                       |                             |       |       |       |            |          |
|   5 |      LOAD AS SELECT (CURSOR DURATION MEMORY)        | SYS_TEMP_0FD9D9019_C78235CC |       |       |       |            |          |
|*  6 |       HASH JOIN                                     |                             |  2961 |   286K|       |    53   (0)| 00:00:01 |
|   7 |        VIEW                                         | index$_join$_073            |    68 |   544 |       |     2   (0)| 00:00:01 |
|*  8 |         HASH JOIN                                   |                             |       |       |       |            |          |
|   9 |          INDEX FAST FULL SCAN                       | CWMS_OFFICE_PK              |    68 |   544 |       |     1   (0)| 00:00:01 |
|  10 |          INDEX FAST FULL SCAN                       | CWMS_OFFICE_UK              |    68 |   544 |       |     1   (0)| 00:00:01 |
|* 11 |        HASH JOIN                                    |                             |  2961 |   263K|       |    51   (0)| 00:00:01 |
|  12 |         TABLE ACCESS FULL                           | AT_BASE_LOCATION            |  5598 | 55980 |       |     7   (0)| 00:00:01 |
|* 13 |         HASH JOIN                                   |                             |  2964 |   234K|       |    44   (0)| 00:00:01 |
|  14 |          VIEW                                       | index$_join$_075            |  6709 | 93926 |       |    35   (0)| 00:00:01 |
|* 15 |           HASH JOIN                                 |                             |       |       |       |            |          |
|  16 |            INDEX FAST FULL SCAN                     | AT_PHYSICAL_LOCATION_PK     |  6709 | 93926 |       |    21   (0)| 00:00:01 |
|  17 |            INDEX FAST FULL SCAN                     | AT_PHYSICAL_LOCATION_U1     |  6709 | 93926 |       |    23   (0)| 00:00:01 |
|  18 |          TABLE ACCESS FULL                          | AT_LOCATION_LEVEL           |  2962 |   193K|       |     9   (0)| 00:00:01 |
|  19 |      LOAD AS SELECT (CURSOR DURATION MEMORY)        | SYS_TEMP_0FD9D901A_C78235CC |       |       |       |            |          |
|  20 |       FAST DUAL                                     |                             |     1 |       |       |     2   (0)| 00:00:01 |
|  21 |       FAST DUAL                                     |                             |     1 |       |       |     2   (0)| 00:00:01 |
|* 22 |       HASH JOIN OUTER                               |                             |    54 |  6372 |       |    43   (5)| 00:00:01 |
|* 23 |        HASH JOIN OUTER                              |                             |    54 |  5886 |       |    41   (5)| 00:00:01 |
|  24 |         NESTED LOOPS OUTER                          |                             |    54 |  5076 |       |    38   (6)| 00:00:01 |
|* 25 |          HASH JOIN OUTER                            |                             |    54 |  3996 |       |    38   (6)| 00:00:01 |
|* 26 |           HASH JOIN OUTER                           |                             |    54 |  3510 |       |    36   (6)| 00:00:01 |
|* 27 |            HASH JOIN OUTER                          |                             |    54 |  2700 |       |    33   (7)| 00:00:01 |
|  28 |             MERGE JOIN CARTESIAN                    |                             |    54 |  1620 |       |    30   (7)| 00:00:01 |
|  29 |              VIEW                                   |                             |     2 |     8 |       |     4   (0)| 00:00:01 |
|  30 |               UNION-ALL                             |                             |       |       |       |            |          |
|  31 |                FAST DUAL                            |                             |     1 |       |       |     2   (0)| 00:00:01 |
|  32 |                FAST DUAL                            |                             |     1 |       |       |     2   (0)| 00:00:01 |
|  33 |              BUFFER SORT                            |                             |    27 |   702 |       |    30   (7)| 00:00:01 |
|  34 |               VIEW                                  |                             |    27 |   702 |       |    13   (8)| 00:00:01 |
|  35 |                HASH UNIQUE                          |                             |    27 |   459 |       |    13   (8)| 00:00:01 |
|  36 |                 VIEW                                |                             |  2955 | 50235 |       |    12   (0)| 00:00:01 |
|  37 |                  TABLE ACCESS FULL                  | SYS_TEMP_0FD9D9019_C78235CC |  2955 |   285K|       |    12   (0)| 00:00:01 |
|  38 |             TABLE ACCESS FULL                       | AT_PARAMETER                |   545 | 10900 |       |     3   (0)| 00:00:01 |
|  39 |            TABLE ACCESS FULL                        | CWMS_BASE_PARAMETER         |    51 |   765 |       |     3   (0)| 00:00:01 |
|  40 |           VIEW                                      | index$_join$_082            |   133 |  1197 |       |     2   (0)| 00:00:01 |
|* 41 |            HASH JOIN                                |                             |       |       |       |            |          |
|  42 |             INDEX FAST FULL SCAN                    | CWMS_UNIT_PK                |   133 |  1197 |       |     1   (0)| 00:00:01 |
|  43 |             INDEX FAST FULL SCAN                    | CWMS_UNIT_UK                |   133 |  1197 |       |     1   (0)| 00:00:01 |
|  44 |          TABLE ACCESS BY INDEX ROWID                | AT_PARAMETER                |     1 |    20 |       |     0   (0)| 00:00:01 |
|* 45 |           INDEX UNIQUE SCAN                         | AT_PARAMETER_PK             |     1 |       |       |     0   (0)| 00:00:01 |
|  46 |         TABLE ACCESS FULL                           | CWMS_BASE_PARAMETER         |    51 |   765 |       |     3   (0)| 00:00:01 |
|  47 |        VIEW                                         | index$_join$_081            |   133 |  1197 |       |     2   (0)| 00:00:01 |
|* 48 |         HASH JOIN                                   |                             |       |       |       |            |          |
|  49 |          INDEX FAST FULL SCAN                       | CWMS_UNIT_PK                |   133 |  1197 |       |     1   (0)| 00:00:01 |
|  50 |          INDEX FAST FULL SCAN                       | CWMS_UNIT_UK                |   133 |  1197 |       |     1   (0)| 00:00:01 |
|  51 |      SORT ORDER BY                                  |                             |  7126K|    60G|    54G|    13M  (1)| 00:08:59 |
|* 52 |       HASH JOIN RIGHT OUTER                         |                             |  7126K|    60G|       |   265K  (1)| 00:00:11 |
|  53 |        TABLE ACCESS FULL                            | AT_LOC_LVL_SOURCE           |     1 |   130 |       |     2   (0)| 00:00:01 |
|* 54 |        HASH JOIN RIGHT OUTER                        |                             |  7126K|    59G|       |   265K  (1)| 00:00:11 |
|* 55 |         TABLE ACCESS FULL                           | AT_LOC_LVL_LABEL            |     1 |   148 |       |     2   (0)| 00:00:01 |
|  56 |         MERGE JOIN OUTER                            |                             |  7126K|    58G|       |   265K  (1)| 00:00:11 |
|* 57 |          HASH JOIN OUTER                            |                             |   131K|    84M|       |   349   (1)| 00:00:01 |
|* 58 |           HASH JOIN RIGHT OUTER                     |                             |  2955 |  1829K|       |   142   (0)| 00:00:01 |
|  59 |            TABLE ACCESS BY INDEX ROWID BATCHED      | CWMS_PARAMETER_TYPE         |     7 |    56 |       |     2   (0)| 00:00:01 |
|* 60 |             INDEX RANGE SCAN                        | CWMS_PARAMETER_TYPE_PK      |     7 |       |       |     1   (0)| 00:00:01 |
|  61 |            NESTED LOOPS OUTER                       |                             |  2955 |  1806K|       |   140   (0)| 00:00:01 |
|  62 |             NESTED LOOPS OUTER                      |                             |  2955 |  1783K|       |   140   (0)| 00:00:01 |
|* 63 |              HASH JOIN RIGHT OUTER                  |                             |  2955 |  1460K|       |    95   (0)| 00:00:01 |
|  64 |               TABLE ACCESS FULL                     | AT_BASE_LOCATION            |  5598 | 72774 |       |     7   (0)| 00:00:01 |
|* 65 |               HASH JOIN RIGHT OUTER                 |                             |  2955 |  1422K|       |    88   (0)| 00:00:01 |
|  66 |                TABLE ACCESS FULL                    | AT_PHYSICAL_LOCATION        |  6709 |   104K|       |    71   (0)| 00:00:01 |
|* 67 |                HASH JOIN RIGHT OUTER                |                             |  2955 |  1376K|       |    17   (0)| 00:00:01 |
|  68 |                 TABLE ACCESS FULL                   | AT_SPECIFIED_LEVEL          |   126 |  3276 |       |     3   (0)| 00:00:01 |
|* 69 |                 HASH JOIN RIGHT OUTER               |                             |  2955 |  1301K|       |    14   (0)| 00:00:01 |
|  70 |                  TABLE ACCESS BY INDEX ROWID BATCHED| CWMS_DURATION               |    61 |   793 |       |     2   (0)| 00:00:01 |
|* 71 |                   INDEX RANGE SCAN                  | CWMS_DURATION_PK            |    61 |       |       |     1   (0)| 00:00:01 |
|  72 |                  NESTED LOOPS OUTER                 |                             |  2955 |  1263K|       |    12   (0)| 00:00:01 |
|  73 |                   VIEW                              |                             |  2955 |  1226K|       |    12   (0)| 00:00:01 |
|  74 |                    TABLE ACCESS FULL                | SYS_TEMP_0FD9D9019_C78235CC |  2955 |   285K|       |    12   (0)| 00:00:01 |
|  75 |                   TABLE ACCESS BY INDEX ROWID       | CWMS_DURATION               |     1 |    13 |       |     0   (0)| 00:00:01 |
|* 76 |                    INDEX UNIQUE SCAN                | CWMS_DURATION_PK            |     1 |       |       |     0   (0)| 00:00:01 |
|  77 |              TABLE ACCESS BY INDEX ROWID            | AT_CWMS_TS_ID               |     1 |   112 |       |     1   (0)| 00:00:01 |
|* 78 |               INDEX UNIQUE SCAN                     | AT_CWMS_TS_ID_PK            |     1 |       |       |     0   (0)| 00:00:01 |
|  79 |             TABLE ACCESS BY INDEX ROWID             | CWMS_PARAMETER_TYPE         |     1 |     8 |       |     0   (0)| 00:00:01 |
|* 80 |              INDEX UNIQUE SCAN                      | CWMS_PARAMETER_TYPE_PK      |     1 |       |       |     0   (0)| 00:00:01 |
|  81 |           TABLE ACCESS FULL                         | AT_SEASONAL_LOCATION_LEVEL  |   129K|  4302K|       |   206   (1)| 00:00:01 |
|  82 |          BUFFER SORT                                |                             |    54 |   431K|       |   265K  (1)| 00:00:11 |
|  83 |           VIEW                                      | VW_LAT_AD2A4E83             |    54 |   431K|       |     2   (0)| 00:00:01 |
|  84 |            NESTED LOOPS OUTER                       |                             |    54 |   430K|       |     2   (0)| 00:00:01 |
|  85 |             NESTED LOOPS OUTER                      |                             |    54 |   429K|       |     2   (0)| 00:00:01 |
|* 86 |              VIEW                                   |                             |    54 |   427K|       |     2   (0)| 00:00:01 |
|  87 |               TABLE ACCESS FULL                     | SYS_TEMP_0FD9D901A_C78235CC |    54 |  6372 |       |     2   (0)| 00:00:01 |
|* 88 |              INDEX UNIQUE SCAN                      | CWMS_UNIT_CONVERSION_PK     |     1 |    28 |       |     0   (0)| 00:00:01 |
|* 89 |             INDEX UNIQUE SCAN                       | CWMS_UNIT_CONVERSION_PK     |     1 |    28 |       |     0   (0)| 00:00:01 |
---------------------------------------------------------------------------------------------------------------------------

 */