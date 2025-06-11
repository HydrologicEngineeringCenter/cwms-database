CWMS Properties Dictionary

Within the CWMS system properties are used to define and control the
behavior of many processes. As CWMS continues to develop more of its
properties are being defined with the CWMS database schema AT_PROPERTIES
table. This document identifies properties that are currently defined
and utilized within the CWMS database.

In the examples below the string:

OFF represents the Corps of Engineers Office ID (i.e., SWA, NAB, NWDP)

USER represents a CWMS user ID (i.e., B3HRDPJC, L0ENHSHN).

+-------------+---------------+-----------+---------+-----------------+
| PR          | PROP_ID       | P         | PROP_   | Notes           |
| OP_CATEGORY |               | ROP_VALUE | COMMENT |                 |
+=============+===============+===========+=========+=================+
|             |               |           |         |                 |
+-------------+---------------+-----------+---------+-----------------+
| Offi        | SHEF_Spe      | T         | Store   | Indicates if an |
| ce_Pref.OFF | c_Alias_Entry |           | l       | entry should be |
|             |               |           | ocation | made in a       |
|             |               |           | aliases | Location Alias  |
|             |               |           | for     | group of the    |
|             |               |           | this    | Agency Aliases  |
|             |               |           | office  | category. This  |
|             |               |           |         | should only be  |
|             |               |           |         | done when there |
|             |               |           |         | is a one-to-one |
|             |               |           |         | relationship    |
|             |               |           |         | between a SHEF  |
|             |               |           |         | Loc ID and a    |
|             |               |           |         | CWMS Location   |
|             |               |           |         | ID.             |
+-------------+---------------+-----------+---------+-----------------+
|             |               | F         | Don’t   |                 |
|             |               |           | store   |                 |
|             |               |           | l       |                 |
|             |               |           | ocation |                 |
|             |               |           | aliases |                 |
|             |               |           | for     |                 |
|             |               |           | this    |                 |
|             |               |           | office. |                 |
+-------------+---------------+-----------+---------+-----------------+
|             | DATA_STR      | DATA      | Use NWD | Controls if     |
|             | EAM_MGT_STYLE | FEEDS     | Data    | data streams    |
|             |               |           | Feed    | will have       |
|             |               |           | Ma      | sub-management  |
|             |               |           | nagment | using data      |
|             |               |           | Scheme. | feeds. Multiple |
|             |               |           |         | data feeds may  |
|             |               |           |         | be defined that |
|             |               |           |         | are             |
|             |               |           |         | individually    |
|             |               |           |         | managed, but    |
|             |               |           |         | operate as a    |
|             |               |           |         | single data     |
|             |               |           |         | stream.         |
+-------------+---------------+-----------+---------+-----------------+
|             |               | DATA      | Use     |                 |
|             |               | STREAMS   | S       |                 |
|             |               |           | tandard |                 |
|             |               |           | CWMS    |                 |
|             |               |           | Data    |                 |
|             |               |           | Streams |                 |
|             |               |           | Man     |                 |
|             |               |           | agement |                 |
|             |               |           | Scheme. |                 |
+-------------+---------------+-----------+---------+-----------------+
|             | East_M        |           |         | East boundary   |
|             | ost_Longitude |           |         | for all         |
|             |               |           |         | district        |
|             |               |           |         | locations       |
+-------------+---------------+-----------+---------+-----------------+
|             | West_M        |           |         | East boundary   |
|             | ost_Longitude |           |         | for all         |
|             |               |           |         | district        |
|             |               |           |         | locations       |
+-------------+---------------+-----------+---------+-----------------+
|             | North_        |           |         | North boundary  |
|             | Most_Latitude |           |         | for all         |
|             |               |           |         | district        |
|             |               |           |         | locations       |
+-------------+---------------+-----------+---------+-----------------+
|             | South_        |           |         | South boundary  |
|             | Most_Latitude |           |         | for all         |
|             |               |           |         | district        |
|             |               |           |         | locations       |
+-------------+---------------+-----------+---------+-----------------+
| Default_Us  | La            | D.D       |         | Decimal Degrees |
| er_Pref.OFF | t_Long_Format |           |         |                 |
+-------------+---------------+-----------+---------+-----------------+
|             |               | DM.M      |         | Degrees and     |
|             |               |           |         | decimal Minutes |
+-------------+---------------+-----------+---------+-----------------+
|             |               | DMS.S     |         | Degrees,        |
|             |               |           |         | Minutes and     |
|             |               |           |         | decimal seconds |
+-------------+---------------+-----------+---------+-----------------+
|             | Display_TZ    | [Time     |         | Initial default |
|             |               | zone      |         | time zone for   |
|             |               | name>]    |         | display on time |
|             |               |           |         | values for each |
|             |               |           |         | new user in     |
|             |               |           |         | office.         |
+-------------+---------------+-----------+---------+-----------------+
|             | Unit_System   | EN        |         | English Units   |
+-------------+---------------+-----------+---------+-----------------+
|             |               | SI        |         | System          |
|             |               |           |         | International   |
+-------------+---------------+-----------+---------+-----------------+
| User_Pr     | La            | [D.D|DM   |         | Users selected  |
| ef.USER.OFF | t_Long_Format | .M|DMS.S] |         | format          |
+-------------+---------------+-----------+---------+-----------------+
|             | Display_TZ    | [Time     |         | Users selected  |
|             |               | zone      |         | display time    |
|             |               | name>]    |         | zone            |
+-------------+---------------+-----------+---------+-----------------+
|             | Unit_System   | [EN|SI]   |         | Users selected  |
|             |               |           |         | Unit System     |
+-------------+---------------+-----------+---------+-----------------+
