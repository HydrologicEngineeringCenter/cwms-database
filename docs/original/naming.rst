====================
CWMS Database Naming
====================

Contents
========

`Nomenclature <#nomenclature>`__\ `1 <#nomenclature>`__

`Scope <#scope>`__\ `1 <#scope>`__

`Common
Restrictions <#common-restrictions>`__\ `2 <#common-restrictions>`__

`Offices <#offices>`__\ `2 <#offices>`__

`Locations <#locations>`__\ `4 <#locations>`__

`Parameters <#parameters>`__\ `5 <#parameters>`__

`Parameter Types <#parameter-types>`__\ `7 <#parameter-types>`__

`Intervals <#intervals>`__\ `7 <#intervals>`__

`Durations <#durations>`__\ `9 <#durations>`__

`Versions <#versions>`__\ `11 <#versions>`__

`Time Series <#time-series>`__\ `12 <#time-series>`__

`Rating Templates <#rating-templates>`__\ `12 <#rating-templates>`__

`Rating
Specifications <#rating-specifications>`__\ `14 <#rating-specifications>`__

`Specified Levels <#specified-levels>`__\ `16 <#specified-levels>`__

`Location Levels <#location-levels>`__\ `16 <#location-levels>`__

`Location Level
Indicators <#location-level-indicators>`__\ `16 <#location-level-indicators>`__

`Location and Time Series
Categories <#location-and-time-series-categories>`__\ `17 <#location-and-time-series-categories>`__

`Location and Time Series
Groups <#location-and-time-series-groups>`__\ `17 <#location-and-time-series-groups>`__

`Location and Time Series
Aliases <#location-and-time-series-aliases>`__\ `18 <#location-and-time-series-aliases>`__

`Units <#units>`__\ `18 <#units>`__

Nomenclature
============

Like other relational databases, the CWMS database uses *keys* to order
rows with tables and to link rows from different tables together. In the
CWMS database, these keys are normally integer values referred to as
*codes*. In most tables within the CWMS database, each row is also
represented by a text string referred to as an *identifier* (or *ID*)
and there normally exists a 1:1 association between codes and
identifiers (i.e., identifiers are normally unique within a given
table). This document discusses the requirements, relationships, and
conventions of the identifiers in the CWMS database.

Scope
=====

Most items in the CWMS database are accessed from outside the database
via their identifiers. The types of items accessed in this way are:

-  offices (“whose”)

-  locations (“where”)

-  parameters (“what”)

-  parameter types

-  intervals (“how often”)

-  durations (“over how long”)

-  versions (“which”)

-  time series

-  rating templates

-  rating specifications

-  specified levels

-  location levels

-  location level indicators

-  location and time series categories

-  location and time series groups

-  location and time series aliases

-  units

Some of these item types are constrained. That is, the items are
pre-defined and users aren’t allowed to add their own. Durations,
intervals, parameter types, and units are in this category. Parameters
are semi-constrained – the base portion is constrained but the user is
allowed to combine the pre-defined base parameters with user-defined
sub-parameters. Location levels, rating templates, rating
specifications, and time series are composite item types – they each
include a combination of other items types, some of which are
constrained. The remaining item types are unconstrained; users are free
to add their own items.

Common Restrictions
===================

All identifiers should avoid using the following characters as they can
be interpreted by the CWMS Database API as wildcards for matching
multiple identifiers.

-  \* (star, asterisk)

-  ? (question mark)

-  % (percent symbol)

-  \_ (underscore)

Offices
=======

Office identifiers are single-component identifiers that are
constrained. They may be no more than 16 characters long. They are
always in upper case, although they may be specified to the CWMS
Database API using any case.

Offices in the CWMS database normally represent ownership of other items
in the database.

+-------------------+-----------+---------------+---------+-----------+
| **Component**     | **Usage** | **            | **L     | **Case**  |
|                   |           | Constrained** | ength** |           |
+===================+===========+===============+=========+===========+
| office            | required  | yes           | 1..16   | upper     |
+-------------------+-----------+---------------+---------+-----------+

+---------+-----------------------------------------+-----+-----------+
| *       | **Long Name**                           | **  | **Office  |
| *Office |                                         | ERO | Type**    |
| ID**    |                                         | C** |           |
+=========+=========================================+=====+===========+
| UNK     | Corps of Engineers Office Unknown       | 0   | UNK       |
+---------+-----------------------------------------+-----+-----------+
| HQ      | Headquarters, U.S. Army Corps of        | S0  | HQ        |
|         | Engineers                               |     |           |
+---------+-----------------------------------------+-----+-----------+
| LRD     | Great Lakes and Ohio River Division     | H0  | MSC       |
+---------+-----------------------------------------+-----+-----------+
| LRDG    | Great Lakes Region                      | H8  | MSCR      |
+---------+-----------------------------------------+-----+-----------+
| LRC     | Chicago District                        | H6  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| LRE     | Detroit District                        | H7  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| LRB     | Buffalo District                        | H5  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| LRDO    | Ohio River Region                       | H0  | MSCR      |
+---------+-----------------------------------------+-----+-----------+
| LRH     | Huntington District                     | H1  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| LRL     | Louisville District                     | H2  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| LRN     | Nashville District                      | H3  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| LRP     | Pittsburgh District                     | H4  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| MVD     | Mississippi Valley Division             | B0  | MSC       |
+---------+-----------------------------------------+-----+-----------+
| MVK     | Vicksburg District                      | B4  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| MVM     | Memphis District                        | B1  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| MVN     | New Orleans District                    | B2  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| MVP     | St. Paul District                       | B6  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| MVR     | Rock Island District                    | B5  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| MVS     | St. Louis District                      | B3  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| NAD     | North Atlantic Division                 | E0  | MSC       |
+---------+-----------------------------------------+-----+-----------+
| NAB     | Baltimore District                      | E1  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| NAE     | New England District                    | E6  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| NAN     | New York District                       | E3  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| NAO     | Norfolk District                        | E4  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| NAP     | Philadelphia District                   | E5  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| NWD     | Northwestern Division                   | G0  | MSC       |
+---------+-----------------------------------------+-----+-----------+
| NWDP    | Pacific Northwest Region                | G0  | MSCR      |
+---------+-----------------------------------------+-----+-----------+
| NWP     | Portland District                       | G2  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| NWS     | Seattle District                        | G3  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| NWW     | Walla Walla District                    | G4  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| NWDM    | Missouri River Region                   | G7  | MSCR      |
+---------+-----------------------------------------+-----+-----------+
| NWK     | Kansas City District                    | G5  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| NWO     | Omaha District                          | G6  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| POD     | Pacific Ocean Division                  | J0  | MSC       |
+---------+-----------------------------------------+-----+-----------+
| POA     | Alaska District                         | J4  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| POH     | Hawaii District                         | J3  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| SAD     | South Atlantic Division                 | K0  | MSC       |
+---------+-----------------------------------------+-----+-----------+
| SAC     | Charleston District                     | K2  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| SAJ     | Jacksonville District                   | K3  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| SAM     | Mobile District                         | K5  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| SAS     | Savannah District                       | K6  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| SAW     | Wilmington District                     | K7  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| SPD     | South Pacific Division                  | L0  | MSC       |
+---------+-----------------------------------------+-----+-----------+
| SPA     | Albuquerque District                    | L4  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| SPK     | Sacramento District                     | L2  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| SPL     | Los Angeles District                    | L1  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| SPN     | San Francisco District                  | L3  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| SWD     | Southwestern Division                   | M0  | MSC       |
+---------+-----------------------------------------+-----+-----------+
| SWF     | Fort Worth District                     | M2  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| SWG     | Galveston District                      | M3  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| SWL     | Little Rock District                    | M4  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| SWT     | Tulsa District                          | M5  | DIS       |
+---------+-----------------------------------------+-----+-----------+
| LCRA    | Lower Colorado River Authority          | Z0  | UNK       |
+---------+-----------------------------------------+-----+-----------+
| CWMS    | All CWMS Offices                        | X0  | UNK       |
+---------+-----------------------------------------+-----+-----------+
| ERD     | Engineer Research and Development       | U0  | FOA       |
|         | Center                                  |     |           |
+---------+-----------------------------------------+-----+-----------+
| CRREL   | Cold Regions Research and Engineering   | U4  | FOA       |
|         | Lab                                     |     |           |
+---------+-----------------------------------------+-----+-----------+
| CHL     | Coastal and Hydraulics Laboratory       | U1  | FOA       |
+---------+-----------------------------------------+-----+-----------+
| CERL    | Construction Engineering Research       | U2  | FOA       |
|         | Laboratory                              |     |           |
+---------+-----------------------------------------+-----+-----------+
| EL      | Environmental Laboratory                | U3  | FOA       |
+---------+-----------------------------------------+-----+-----------+
| GSL     | Geotechnical and Structures Laboratory  | U5  | FOA       |
+---------+-----------------------------------------+-----+-----------+
| ITL     | Information Technology Laboratory       | U6  | FOA       |
+---------+-----------------------------------------+-----+-----------+
| TEC     | Topographic Engineering Center          | U7  | FOA       |
+---------+-----------------------------------------+-----+-----------+
| IWR     | Institute for Water Resources           | Q1  | FOA       |
+---------+-----------------------------------------+-----+-----------+
| NDC     | Navigation Data Center                  | Q2  | FOA       |
+---------+-----------------------------------------+-----+-----------+
| HEC     | Hydrologic Engineering Center           | Q0  | FOA       |
+---------+-----------------------------------------+-----+-----------+
| WCSC    | Waterborne Commerce Statistics Center   | Q3  | FOA       |
+---------+-----------------------------------------+-----+-----------+
| CPC     | Central Processing Center               | X1  | UNK       |
+---------+-----------------------------------------+-----+-----------+
| WPC     | Western Processing Center               | X2  | UNK       |
+---------+-----------------------------------------+-----+-----------+

Locations
=========

Location identifiers are comprised of two components: a required base
location ID and an optional sub-location. If the sub-location is
present, the location identifier is formed by joining the components
with the dash, or hyphen, (-) character. Location identifiers are not
case sensitive, but are case retained. That is, no two location IDs for
the same office may differ only in character case, and a location may be
specified to the CWMS Database API using any case, but the character
case of the identifier as created is retained. CWMS convention is to use
title case - capitalizing the first, and only the first, letter of each
word.

Locations in the CWMS database may represent point geographic locations;
non-point geographies such as basins, reservoir, or streams; or
non-geographic objects such as locks, dams, embankments, or projects. In
the first case, location items such as latitude, longitude, and
elevation refer to the geographic point. In the other cases the location
items refer to some reference associated with the location. The CWMS
base location is intended to refer to the entire location. CWMS
sub-locations are intended to add qualification or specificity to one or
more locations that are associated with the base location. The latitude,
longitude, and elevation of a sub-location are interpreted to be the
same as its base location if it doesn’t specify its own values.

Base locations are stored in the CWMS database as locations. A location
who’s ID includes only a base location is stored as a single location.
The base location *is* the location. A location who’s ID includes a base
location is stored as two locations, the base location *and* the
sub-location. Every location with the same base location ID shares the
same base location in the database.

The base location may not include the dash character since the first
dash is interpreted as separating the base location from the
sub-location. Neither of the components should include the dot, or
period, character (.) since it would prevent the location from being
used in time series, rating, or location level identifiers. The maximum
length of a location ID is 49 characters.

+-----------------+-----------+----------------+---------+-----------+
| **Component**   | **Usage** | *              | **L     | **Case**  |
|                 |           | *Constrained** | ength** |           |
+=================+===========+================+=========+===========+
| base location   | required  | no             | 1..16   | retained  |
+-----------------+-----------+----------------+---------+-----------+
| sub-location    | optional  | no             | 1..32   | retained  |
+-----------------+-----------+----------------+---------+-----------+

 Parameters
==========

Like Location IDs, parameter identifiers are comprised of two
components: a required base parameter ID and an optional sub-parameter.
If the sub-parameter is present, the parameter identifier is formed by
joining the components with the dash, or hyphen, (-) character.
Parameter identifiers are not case sensitive, but are case retained.
That is, no two parameter IDs for the same office may differ only in
character case, and a parameter may be specified to the CWMS Database
API using any case, but the character case of the identifier as created
is retained. CWMS convention is to use title case - capitalizing the
first, and only the first, letter of each word.

Parameters in the CWMS database specify the physical attribute of a
value – the “what” of the value that was measured, estimated, or
computed. CWMS convention is to use a base parameter only unless doing
so results in ambiguity about the physical attribute. In such cases
sub-parameters should be used. **Care should be taken not to conflate
sub-parameters with (base or sub-) locations or with parameter types.**
If greater specificity is required about the location (the “where”) of a
measurement, estimate, or computation, it should be given in the
location, possibly by specifying a sub-location. The parameter type
identifier specifies qualifications such as “total”, “average”, etc….
Only when greater specificity is required about the physical attribute
(the “what”) of a measurement, estimate, or computation should a
sub-parameter be used.

Database storage units for time series, ratings, and location level
values are determined by base parameter. Default units for English and
SI unit systems are also determined by base parameter. Each base
parameter is associated with an abstract parameter. The list of valid
units for parameter (i.e., units that can be specified in the CWMS
Database API) is determined by the abstract parameter. Offices can also
set the display unit for English and SI unit systems for each parameter.

Sub-parameters should not include the dot, or period, character (.)
since it would prevent the parameter from being used in time series,
rating, or location level identifiers. They also should not contain the
semicolon (;) or comma (,) characters since these would prevent them
from being used in rating templates. The maximum length of a parameter
ID is 49 characters.

+-------------------+-----------+---------------+---------+-----------+
| **Component**     | **Usage** | **            | **L     | **Case**  |
|                   |           | Constrained** | ength** |           |
+===================+===========+===============+=========+===========+
| base parameter    | required  | yes           | 1..16   | retained  |
+-------------------+-----------+---------------+---------+-----------+
| sub-parameter     | optional  | no            | 1..32   | retained  |
+-------------------+-----------+---------------+---------+-----------+

+----------------+----------------------+-----------+---------+--------+
| **Base         | **Abstract Parameter | **Storage | **      | **SI   |
| Parameter ID** | ID**                 | Unit**    | English | Unit** |
|                |                      |           | Unit**  |        |
+================+======================+===========+=========+========+
| %              | None                 | %         | %       | %      |
+----------------+----------------------+-----------+---------+--------+
| Area           | Area                 | m2        | ft2     | m2     |
+----------------+----------------------+-----------+---------+--------+
| Code           | None                 | n/a       | n/a     | n/a    |
+----------------+----------------------+-----------+---------+--------+
| Coeff          | None                 | n/a       | n/a     | n/a    |
+----------------+----------------------+-----------+---------+--------+
| Conc           | Mass Concentration   | mg/l      | ppm     | mg/l   |
+----------------+----------------------+-----------+---------+--------+
| Cond           | Conductivity         | umho/cm   | umho/cm | u      |
|                |                      |           |         | mho/cm |
+----------------+----------------------+-----------+---------+--------+
| Count          | Count                | unit      | unit    | unit   |
+----------------+----------------------+-----------+---------+--------+
| Currency       | Currency             | $         | $       | $      |
+----------------+----------------------+-----------+---------+--------+
| Current        | Electric Charge Rate | ampere    | ampere  | ampere |
+----------------+----------------------+-----------+---------+--------+
| Depth          | Length               | mm        | in      | mm     |
+----------------+----------------------+-----------+---------+--------+
| Dir            | Angle                | deg       | deg     | deg    |
+----------------+----------------------+-----------+---------+--------+
| Dist           | Length               | km        | mi      | km     |
+----------------+----------------------+-----------+---------+--------+
| Elev           | Length               | m         | ft      | m      |
+----------------+----------------------+-----------+---------+--------+
| Energy         | Energy               | MWh       | MWh     | MWh    |
+----------------+----------------------+-----------+---------+--------+
| Evap           | Length               | mm        | in      | mm     |
+----------------+----------------------+-----------+---------+--------+
| EvapRate       | Linear Speed         | mm/day    | in/day  | mm/day |
+----------------+----------------------+-----------+---------+--------+
| Fish           | Count                | unit      | unit    | unit   |
+----------------+----------------------+-----------+---------+--------+
| Flow           | Volume Rate          | cms       | cfs     | cms    |
+----------------+----------------------+-----------+---------+--------+
| Frost          | Length               | cm        | in      | cm     |
+----------------+----------------------+-----------+---------+--------+
| Head           | Length               | m         | ft      | m      |
+----------------+----------------------+-----------+---------+--------+
| Height         | Length               | m         | ft      | m      |
+----------------+----------------------+-----------+---------+--------+
| Irrad          | Irradiance           | W/m2      | lang    | W/m2   |
|                |                      |           | ley/min |        |
+----------------+----------------------+-----------+---------+--------+
| Length         | Length               | m         | ft      | m      |
+----------------+----------------------+-----------+---------+--------+
| Opening        | Length               | m         | ft      | m      |
+----------------+----------------------+-----------+---------+--------+
| pH             | Hydrogen Ion Conc.   | su        | su      | su     |
|                | Index                |           |         |        |
+----------------+----------------------+-----------+---------+--------+
| Power          | Power                | MW        | MW      | MW     |
+----------------+----------------------+-----------+---------+--------+
| Precip         | Length               | mm        | in      | mm     |
+----------------+----------------------+-----------+---------+--------+
| Pres           | Pressure             | kPa       | in-hg   | kPa    |
+----------------+----------------------+-----------+---------+--------+
| Rad            | Irradiation          | J/m2      | langley | J/m2   |
+----------------+----------------------+-----------+---------+--------+
| Ratio          | None                 | n/a       | n/a     | n/a    |
+----------------+----------------------+-----------+---------+--------+
| Rotation       | Angle                | deg       | deg     | deg    |
+----------------+----------------------+-----------+---------+--------+
| Speed          | Linear Speed         | kph       | mph     | kph    |
+----------------+----------------------+-----------+---------+--------+
| SpinRate       | Angular Speed        | rpm       | rpm     | rpm    |
+----------------+----------------------+-----------+---------+--------+
| Stage          | Length               | m         | ft      | m      |
+----------------+----------------------+-----------+---------+--------+
| Stor           | Volume               | m3        | ac-ft   | m3     |
+----------------+----------------------+-----------+---------+--------+
| Temp           | Temperature          | C         | F       | C      |
+----------------+----------------------+-----------+---------+--------+
| Thick          | Length               | cm        | in      | cm     |
+----------------+----------------------+-----------+---------+--------+
| Timing         | Elapsed Time         | sec       | sec     | sec    |
+----------------+----------------------+-----------+---------+--------+
| Travel         | Length               | km        | mi      | km     |
+----------------+----------------------+-----------+---------+--------+
| Turb           | Turbidity            | JTU       | JTU     | JTU    |
+----------------+----------------------+-----------+---------+--------+
| TurbF          | Turbidity            | FNU       | FNU     | FNU    |
+----------------+----------------------+-----------+---------+--------+
| TurbJ          | Turbidity            | JTU       | JTU     | JTU    |
+----------------+----------------------+-----------+---------+--------+
| TurbN          | Turbidity            | NTU       | NTU     | NTU    |
+----------------+----------------------+-----------+---------+--------+
| Volt           | Electromotive        | volt      | volt    | volt   |
|                | Potential            |           |         |        |
+----------------+----------------------+-----------+---------+--------+
| Volume         | Volume               | m3        | ft3     | m3     |
+----------------+----------------------+-----------+---------+--------+
| Width          | Length               | m         | ft      | m      |
+----------------+----------------------+-----------+---------+--------+
| Text           | None                 | n/a       | n/a     | n/a    |
+----------------+----------------------+-----------+---------+--------+
| Binary         | None                 | n/a       | n/a     | n/a    |
+----------------+----------------------+-----------+---------+--------+

Parameter Types
===============

Parameter type identifiers are single-component identifiers that are
constrained. They may be no more than 16 characters long. They are not
case sensitive, but are case retained. That is, no two parameter type
IDs may differ only in character case, and a parameter type may be
specified to the CWMS Database API using any case, but the character
case of the identifier as created is retained. CWMS convention is to use
title case - capitalizing the first, and only the first, letter of the
identifier.

Parameter types add time-domain qualification to parameters.

+-------------------+-----------+---------------+---------+-----------+
| **Component**     | **Usage** | **            | **L     | **Case**  |
|                   |           | Constrained** | ength** |           |
+===================+===========+===============+=========+===========+
| parameter type    | required  | yes           | 1..16   | retained  |
+-------------------+-----------+---------------+---------+-----------+

+--------------------------------------+-------------------------------+
| **Parameter Type ID**                | **Description**               |
+======================================+===============================+
| Total                                | TOTAL                         |
+--------------------------------------+-------------------------------+
| Max                                  | MAXIMUM                       |
+--------------------------------------+-------------------------------+
| Min                                  | MINIMUM                       |
+--------------------------------------+-------------------------------+
| Const                                | CONSTANT                      |
+--------------------------------------+-------------------------------+
| Ave                                  | AVERAGE                       |
+--------------------------------------+-------------------------------+
| Inst                                 | INSTANTANEOUS                 |
+--------------------------------------+-------------------------------+

Intervals
=========

Interval identifiers are single-component identifiers that are
constrained. They may be no more than 16 characters long. They are not
case sensitive, but are case retained. That is, no two interval IDs may
differ only in character case, and an interval may be specified to the
CWMS Database API using any case, but the character case of the
identifier as created is retained. CWMS convention is to use title case
- capitalizing the first, and only the first, letter of each word.

Intervals in the CWMS database specify the recurrence period attribute
of time series values – the “how often” of the values measured,
estimated, or computed. The special interval of “0” (zero) indicates an
irregular interval. Intervals beginning with the tilde character (~)
also indicate irregular intervals, although they also indicate generally
expected recurrence intervals.

+-------------------+-----------+---------------+---------+-----------+
| **Component**     | **Usage** | **            | **L     | **Case**  |
|                   |           | Constrained** | ength** |           |
+===================+===========+===============+=========+===========+
| interval          | required  | yes           | 1..16   | retained  |
+-------------------+-----------+---------------+---------+-----------+

+----------+-----------------------------------------------------------+
| **       | **Description**                                           |
| Interval |                                                           |
| ID**     |                                                           |
+==========+===========================================================+
| 0        | Irregular recurrence interval                             |
+----------+-----------------------------------------------------------+
| ~1Minute | Irregular recurrence interval: expected recurrence        |
|          | interval of 1 minute                                      |
+----------+-----------------------------------------------------------+
| ~        | Irregular recurrence interval: expected recurrence        |
| 2Minutes | interval of 2 minutes                                     |
+----------+-----------------------------------------------------------+
| ~        | Irregular recurrence interval: expected recurrence        |
| 3Minutes | interval of 3 minutes                                     |
+----------+-----------------------------------------------------------+
| ~        | Irregular recurrence interval: expected recurrence        |
| 4Minutes | interval of 4 minutes                                     |
+----------+-----------------------------------------------------------+
| ~        | Irregular recurrence interval: expected recurrence        |
| 5Minutes | interval of 5 minutes                                     |
+----------+-----------------------------------------------------------+
| ~        | Irregular recurrence interval: expected recurrence        |
| 6Minutes | interval of 6 minutes                                     |
+----------+-----------------------------------------------------------+
| ~        | Irregular recurrence interval: expected recurrence        |
| 8Minutes | interval of 8 minutes                                     |
+----------+-----------------------------------------------------------+
| ~1       | Irregular recurrence interval: expected recurrence        |
| 0Minutes | interval of 10 minutes                                    |
+----------+-----------------------------------------------------------+
| ~1       | Irregular recurrence interval: expected recurrence        |
| 2Minutes | interval of 12 minutes                                    |
+----------+-----------------------------------------------------------+
| ~1       | Irregular recurrence interval: expected recurrence        |
| 5Minutes | interval of 15 minutes                                    |
+----------+-----------------------------------------------------------+
| ~2       | Irregular recurrence interval: expected recurrence        |
| 0Minutes | interval of 20 minutes                                    |
+----------+-----------------------------------------------------------+
| ~3       | Irregular recurrence interval: expected recurrence        |
| 0Minutes | interval of 30 minutes                                    |
+----------+-----------------------------------------------------------+
| ~1Hour   | Irregular recurrence interval: expected recurrence        |
|          | interval of 1 hour                                        |
+----------+-----------------------------------------------------------+
| ~2Hours  | Irregular recurrence interval: expected recurrence        |
|          | interval of 2 hours                                       |
+----------+-----------------------------------------------------------+
| ~3Hours  | Irregular recurrence interval: expected recurrence        |
|          | interval of 3 hours                                       |
+----------+-----------------------------------------------------------+
| ~4Hours  | Irregular recurrence interval: expected recurrence        |
|          | interval of 4 hours                                       |
+----------+-----------------------------------------------------------+
| ~6Hours  | Irregular recurrence interval: expected recurrence        |
|          | interval of 6 hours                                       |
+----------+-----------------------------------------------------------+
| ~8Hours  | Irregular recurrence interval: expected recurrence        |
|          | interval of 8 hours                                       |
+----------+-----------------------------------------------------------+
| ~12Hours | Irregular recurrence interval: expected recurrence        |
|          | interval of 12 hours                                      |
+----------+-----------------------------------------------------------+
| ~1Day    | Irregular recurrence interval: expected recurrence        |
|          | interval of 1 day                                         |
+----------+-----------------------------------------------------------+
| ~2Days   | Irregular recurrence interval: expected recurrence        |
|          | interval of 2 days                                        |
+----------+-----------------------------------------------------------+
| ~3Days   | Irregular recurrence interval: expected recurrence        |
|          | interval of 3 days                                        |
+----------+-----------------------------------------------------------+
| ~4Days   | Irregular recurrence interval: expected recurrence        |
|          | interval of 4 days                                        |
+----------+-----------------------------------------------------------+
| ~5Days   | Irregular recurrence interval: expected recurrence        |
|          | interval of 5 days                                        |
+----------+-----------------------------------------------------------+
| ~6Days   | Irregular recurrence interval: expected recurrence        |
|          | interval of 6 days                                        |
+----------+-----------------------------------------------------------+
| ~1Week   | Irregular recurrence interval: expected recurrence        |
|          | interval of 1 week                                        |
+----------+-----------------------------------------------------------+
| ~1Month  | Irregular recurrence interval: expected recurrence        |
|          | interval of 1 month                                       |
+----------+-----------------------------------------------------------+
| ~1Year   | Irregular recurrence interval: expected recurrence        |
|          | interval of 1 year                                        |
+----------+-----------------------------------------------------------+
| ~1Decade | Irregular recurrence interval: expected recurrence        |
|          | interval of 1 decade                                      |
+----------+-----------------------------------------------------------+
| 1Minute  | Regular recurrence interval of 1 minute                   |
+----------+-----------------------------------------------------------+
| 2Minutes | Regular recurrence interval of 2 minutes                  |
+----------+-----------------------------------------------------------+
| 3Minutes | Regular recurrence interval of 3 minutes                  |
+----------+-----------------------------------------------------------+
| 4Minutes | Regular recurrence interval of 4 minutes                  |
+----------+-----------------------------------------------------------+
| 5Minutes | Regular recurrence interval of 5 minutes                  |
+----------+-----------------------------------------------------------+
| 6Minutes | Regular recurrence interval of 6 minutes                  |
+----------+-----------------------------------------------------------+
| 8Minutes | Regular recurrence interval of 8 minutes                  |
+----------+-----------------------------------------------------------+
| 1        | Regular recurrence interval of 10 minutes                 |
| 0Minutes |                                                           |
+----------+-----------------------------------------------------------+
| 1        | Regular recurrence interval of 12 minutes                 |
| 2Minutes |                                                           |
+----------+-----------------------------------------------------------+
| 1        | Regular recurrence interval of 15 minutes                 |
| 5Minutes |                                                           |
+----------+-----------------------------------------------------------+
| 2        | Regular recurrence interval of 20 minutes                 |
| 0Minutes |                                                           |
+----------+-----------------------------------------------------------+
| 3        | Regular recurrence interval of 30 minutes                 |
| 0Minutes |                                                           |
+----------+-----------------------------------------------------------+
| 1Hour    | Regular recurrence interval of 1 hour                     |
+----------+-----------------------------------------------------------+
| 2Hours   | Regular recurrence interval of 2 hours                    |
+----------+-----------------------------------------------------------+
| 3Hours   | Regular recurrence interval of 3 hours                    |
+----------+-----------------------------------------------------------+
| 4Hours   | Regular recurrence interval of 4 hours                    |
+----------+-----------------------------------------------------------+
| 6Hours   | Regular recurrence interval of 6 hours                    |
+----------+-----------------------------------------------------------+
| 8Hours   | Regular recurrence interval of 8 hours                    |
+----------+-----------------------------------------------------------+
| 12Hours  | Regular recurrence interval of 12 hours                   |
+----------+-----------------------------------------------------------+
| 1Day     | Regular recurrence interval of 1 day                      |
+----------+-----------------------------------------------------------+
| 2Days    | Regular recurrence interval of 2 days                     |
+----------+-----------------------------------------------------------+
| 3Days    | Regular recurrence interval of 3 days                     |
+----------+-----------------------------------------------------------+
| 4Days    | Regular recurrence interval of 4 days                     |
+----------+-----------------------------------------------------------+
| 5Days    | Regular recurrence interval of 5 days                     |
+----------+-----------------------------------------------------------+
| 6Days    | Regular recurrence interval of 6 days                     |
+----------+-----------------------------------------------------------+
| 1Week    | Regular recurrence interval of 1 week                     |
+----------+-----------------------------------------------------------+
| 1Month   | Regular recurrence interval of 1 month                    |
+----------+-----------------------------------------------------------+
| 1Year    | Regular recurrence interval of 1 year                     |
+----------+-----------------------------------------------------------+
| 1Decade  | Regular recurrence interval of 1 decade                   |
+----------+-----------------------------------------------------------+

Durations
=========

Duration identifiers are single-component identifiers that are
constrained. They may be no more than 16 characters long. They are not
case sensitive, but are case retained. That is, no two duration IDs may
differ only in character case, and a duration may be specified to the
CWMS Database API using any case, but the character case of the
identifier as created is retained. CWMS convention is to use title case
- capitalizing the first, and only the first, letter of each word.

Durations in the CWMS database specify the time length attribute of a
value – the “over how long” of the value that was measured, estimated,
or computed. The special duration of “0” (zero) indicates the absence of
a duration, and must be paired with the “Inst” parameter type in CWMS
time series IDs. Otherwise, unless the duration ends with the characters
“BOP”, values are interpreted to apply at the end of the duration.
Duration IDs ending with the characters “BOP” indicate that the values
should be interpreted to apply at the beginning of the duration.

+-------------------+-----------+---------------+---------+-----------+
| **Component**     | **Usage** | **            | **L     | **Case**  |
|                   |           | Constrained** | ength** |           |
+===================+===========+===============+=========+===========+
| duration          | required  | yes           | 1..16   | retained  |
+-------------------+-----------+---------------+---------+-----------+

+-----------+----------------------------------------------------------+
| *         | **Description**                                          |
| *Duration |                                                          |
| ID**      |                                                          |
+===========+==========================================================+
| 1Minute   | Measurement applies over 1 minute, time stamped at       |
|           | period end                                               |
+-----------+----------------------------------------------------------+
| 2Minutes  | Measurement applies over 2 minutes, time stamped at      |
|           | period end                                               |
+-----------+----------------------------------------------------------+
| 3Minutes  | Measurement applies over 3 minutes, time stamped at      |
|           | period end                                               |
+-----------+----------------------------------------------------------+
| 4Minutes  | Measurement applies over 4 minutes, time stamped at      |
|           | period end                                               |
+-----------+----------------------------------------------------------+
| 5Minutes  | Measurement applies over 5 minutes, time stamped at      |
|           | period end                                               |
+-----------+----------------------------------------------------------+
| 6Minutes  | Measurement applies over 6 minutes, time stamped at      |
|           | period end                                               |
+-----------+----------------------------------------------------------+
| 8Minutes  | Measurement applies over 8 minutes, time stamped at      |
|           | period end                                               |
+-----------+----------------------------------------------------------+
| 12Minutes | Measurement applies over 12 minutes, time stamped at     |
|           | period end                                               |
+-----------+----------------------------------------------------------+
| 15Minutes | Measurement applies over 15 minutes, time stamped at     |
|           | period end                                               |
+-----------+----------------------------------------------------------+
| 20Minutes | Measurement applies over 20 minutes, time stamped at     |
|           | period end                                               |
+-----------+----------------------------------------------------------+
| 30Minutes | Measurement applies over 30 minutes, time stamped at     |
|           | period end                                               |
+-----------+----------------------------------------------------------+
| 1Hour     | Measurement applies over 1 hour, time stamped at period  |
|           | end                                                      |
+-----------+----------------------------------------------------------+
| 2Hours    | Measurement applies over 2 hours, time stamped at period |
|           | end                                                      |
+-----------+----------------------------------------------------------+
| 3Hours    | Measurement applies over 3 hours, time stamped at period |
|           | end                                                      |
+-----------+----------------------------------------------------------+
| 4Hours    | Measurement applies over 4 hours, time stamped at period |
|           | end                                                      |
+-----------+----------------------------------------------------------+
| 6Hours    | Measurement applies over 6 hours, time stamped at period |
|           | end                                                      |
+-----------+----------------------------------------------------------+
| 8Hours    | Measurement applies over 8 hours, time stamped at period |
|           | end                                                      |
+-----------+----------------------------------------------------------+
| 12Hours   | Measurement applies over 12 hours, time stamped at       |
|           | period end                                               |
+-----------+----------------------------------------------------------+
| 1Day      | Measurement applies over 1 day, time stamped at period   |
|           | end                                                      |
+-----------+----------------------------------------------------------+
| 2Days     | Measurement applies over 2 days, time stamped at period  |
|           | end                                                      |
+-----------+----------------------------------------------------------+
| 3Days     | Measurement applies over 3 days, time stamped at period  |
|           | end                                                      |
+-----------+----------------------------------------------------------+
| 4Days     | Measurement applies over 4 days, time stamped at period  |
|           | end                                                      |
+-----------+----------------------------------------------------------+
| 5Days     | Measurement applies over 5 days, time stamped at period  |
|           | end                                                      |
+-----------+----------------------------------------------------------+
| 6Days     | Measurement applies over 6 days, time stamped at period  |
|           | end                                                      |
+-----------+----------------------------------------------------------+
| 1Week     | Measurement applies over 1 week, time stamped at period  |
|           | end                                                      |
+-----------+----------------------------------------------------------+
| 1Month    | Measurement applies over 1 month, time stamped at period |
|           | end                                                      |
+-----------+----------------------------------------------------------+
| 1Year     | Measurement applies over 1 year, time stamped at period  |
|           | end                                                      |
+-----------+----------------------------------------------------------+
| 1Decade   | Measurement applies over 1 decade, time stamped at       |
|           | period end                                               |
+-----------+----------------------------------------------------------+
| 0         | Measurement applies instantaneously at time stamp        |
+-----------+----------------------------------------------------------+
| 1         | Measurement applies over 1 minute, time stamped at       |
| MinuteBOP | period beginning                                         |
+-----------+----------------------------------------------------------+
| 2M        | Measurement applies over 2 minutes, time stamped at      |
| inutesBOP | period beginning                                         |
+-----------+----------------------------------------------------------+
| 3M        | Measurement applies over 3 minutes, time stamped at      |
| inutesBOP | period beginning                                         |
+-----------+----------------------------------------------------------+
| 4M        | Measurement applies over 4 minutes, time stamped at      |
| inutesBOP | period beginning                                         |
+-----------+----------------------------------------------------------+
| 5M        | Measurement applies over 5 minutes, time stamped at      |
| inutesBOP | period beginning                                         |
+-----------+----------------------------------------------------------+
| 6M        | Measurement applies over 1 minutes, time stamped at      |
| inutesBOP | period beginning                                         |
+-----------+----------------------------------------------------------+
| 8M        | Measurement applies over 8 minutes, time stamped at      |
| inutesBOP | period beginning                                         |
+-----------+----------------------------------------------------------+
| 12M       | Measurement applies over 12 minutes, time stamped at     |
| inutesBOP | period beginning                                         |
+-----------+----------------------------------------------------------+
| 15M       | Measurement applies over 15 minutes, time stamped at     |
| inutesBOP | period beginning                                         |
+-----------+----------------------------------------------------------+
| 20M       | Measurement applies over 20 minutes, time stamped at     |
| inutesBOP | period beginning                                         |
+-----------+----------------------------------------------------------+
| 30M       | Measurement applies over 30 minutes, time stamped at     |
| inutesBOP | period beginning                                         |
+-----------+----------------------------------------------------------+
| 1HourBOP  | Measurement applies over 1 hour, time stamped at period  |
|           | beginning                                                |
+-----------+----------------------------------------------------------+
| 2HoursBOP | Measurement applies over 2 hours, time stamped at period |
|           | beginning                                                |
+-----------+----------------------------------------------------------+
| 3HoursBOP | Measurement applies over 3 hours, time stamped at period |
|           | beginning                                                |
+-----------+----------------------------------------------------------+
| 4HoursBOP | Measurement applies over 4 hours, time stamped at period |
|           | beginning                                                |
+-----------+----------------------------------------------------------+
| 6HoursBOP | Measurement applies over 6 hours, time stamped at period |
|           | beginning                                                |
+-----------+----------------------------------------------------------+
| 8HoursBOP | Measurement applies over 8 hours, time stamped at period |
|           | beginning                                                |
+-----------+----------------------------------------------------------+
| 1         | Measurement applies over 12 hours, time stamped at       |
| 2HoursBOP | period beginning                                         |
+-----------+----------------------------------------------------------+
| 1DayBOP   | Measurement applies over 1 day, time stamped at period   |
|           | beginning                                                |
+-----------+----------------------------------------------------------+
| 2DaysBOP  | Measurement applies over 2 days, time stamped at period  |
|           | beginning                                                |
+-----------+----------------------------------------------------------+
| 3DaysBOP  | Measurement applies over 3 days, time stamped at period  |
|           | beginning                                                |
+-----------+----------------------------------------------------------+
| 4DaysBOP  | Measurement applies over 4 days, time stamped at period  |
|           | beginning                                                |
+-----------+----------------------------------------------------------+
| 5DaysBOP  | Measurement applies over 5 days, time stamped at period  |
|           | beginning                                                |
+-----------+----------------------------------------------------------+
| 6DaysBOP  | Measurement applies over 6 days, time stamped at period  |
|           | beginning                                                |
+-----------+----------------------------------------------------------+
| 1WeekBOP  | Measurement applies over 1 week, time stamped at period  |
|           | beginning                                                |
+-----------+----------------------------------------------------------+
| 1MonthBOP | Measurement applies over 1 month, time stamped at period |
|           | beginning                                                |
+-----------+----------------------------------------------------------+
| 1YearBOP  | Measurement applies over 1 year, time stamped at period  |
|           | beginning                                                |
+-----------+----------------------------------------------------------+
| 1         | Measurement applies over 1 decade, time stamped at       |
| DecadeBOP | period beginning                                         |
+-----------+----------------------------------------------------------+
| 10Minutes | Measurement applies over 10 minutes, time stamped at     |
|           | period end                                               |
+-----------+----------------------------------------------------------+
| 10M       | Measurement applies over 10 minutes, time stamped at     |
| inutesBOP | period beginning                                         |
+-----------+----------------------------------------------------------+

Versions
========

Version identifiers are single-component identifier components that are
unconstrained. They may be no more than 32 characters long. They are not
case sensitive, but are case retained. That is, a version may be
specified to the CWMS Database API using any case, but the character
case of the identifier component as created is retained. CWMS convention
is to use title case - capitalizing the first, and only the first,
letter of each word. Versions are not stand-alone identifiers in the
CWMS database; there is no table of versions. Rather, they are
components of compound identifiers.

Versions in the CWMS database specify an additional qualifying attribute
of a value – the “which” of the value that was measured, estimated, or
computed. Versions may indicate any type of qualifier desired by the
user; some qualifications might be:

-  test vs. production

-  data source or delivery channel

-  observed vs. estimated or computed

-  computation method

The version identifier component may not include the dot, or period,
character (.) since that character is used to separate the top-level
components of the identifier that contains the version.

+-------------------+-----------+---------------+---------+-----------+
| **Component**     | **Usage** | **            | **L     | **Case**  |
|                   |           | Constrained** | ength** |           |
+===================+===========+===============+=========+===========+
| version           | required  | no            | 1..32   | retained  |
+-------------------+-----------+---------------+---------+-----------+

Time Series
===========

Time series identifiers are comprised of six required components:
location ID, parameter ID, parameter type ID, interval ID, duration ID,
and version ID, separated by the dot, or period, character (.) as a
delimiter. No two time series for the same office may have the same time
series identifier.

Time series in the CWMS database represent recurring time-stamped values
of some measured, estimated, or computed values of some physical
attribute.

The requirements on the characters used in time series identifiers are
the sum of the restrictions on the individual components. The maximum
length of a time series ID is 183 characters when using non-aliased
locations. Using location aliases increases the maximum length to 390
characters.

+-------------------+-----------+---------------+---------+-----------+
| **Component**     | **Usage** | **            | **L     | **Case**  |
|                   |           | Constrained** | ength** |           |
+===================+===========+===============+=========+===========+
| location          | required  | no            | 1..49   | retained  |
+-------------------+-----------+---------------+---------+-----------+
| parameter         | required  | partially     | 1..49   | retained  |
+-------------------+-----------+---------------+---------+-----------+
| parameter type    | required  | yes           | 1..16   | retained  |
+-------------------+-----------+---------------+---------+-----------+
| interval          | required  | yes           | 1..16   | retained  |
+-------------------+-----------+---------------+---------+-----------+
| duration          | required  | yes           | 1..16   | retained  |
+-------------------+-----------+---------------+---------+-----------+
| version           | required  | no            | 1..32   | retained  |
+-------------------+-----------+---------------+---------+-----------+

Rating Templates
================

Rating template identifiers are comprised of two top level components:
parameters ID and version ID, separated by the dot, or period, character
(.) as a delimiter. The parameters identifier is comprised of two second
level components: independent parameters ID and dependent parameter ID
separated by the semicolon character (;) as a delimiter. If the rating
template specifies more than one independent parameter, the independent
parameters ID is comprised of the individual independent parameter IDs
separated by the comma character (,) as a delimiter. No two rating
templates for the same office may have the same time series identifier.

Rating templates in the CWMS database represent combinations of
parameters and independent parameter lookup behaviors.

The requirements on the characters used in rating template identifiers
are the sum of the restrictions on the individual components. The
maximum length of a rating template ID is 289 characters.

+---+---+------+---+-----+---+---+---+-----+---+---+---+-----+---+---+
| * |   |      |   |     |   |   |   |     |   |   | * | **C | * | * |
| * |   |      |   |     |   |   |   |     |   |   | * | ons | * | * |
| C |   |      |   |     |   |   |   |     |   |   | U | tra | L | C |
| o |   |      |   |     |   |   |   |     |   |   | s | ine | e | a |
| m |   |      |   |     |   |   |   |     |   |   | a | d** | n | s |
| p |   |      |   |     |   |   |   |     |   |   | g |     | g | e |
| o |   |      |   |     |   |   |   |     |   |   | e |     | t | * |
| n |   |      |   |     |   |   |   |     |   |   | * |     | h | * |
| e |   |      |   |     |   |   |   |     |   |   | * |     | * |   |
| n |   |      |   |     |   |   |   |     |   |   |   |     | * |   |
| t |   |      |   |     |   |   |   |     |   |   |   |     |   |   |
| * |   |      |   |     |   |   |   |     |   |   |   |     |   |   |
| * |   |      |   |     |   |   |   |     |   |   |   |     |   |   |
+===+===+======+===+=====+===+===+===+=====+===+===+===+=====+===+===+
| p | * |      |   |     |   |   | * | **C | * | * | r | par | 1 | r |
| a | * |      |   |     |   |   | * | ons | * | * | e | tia | . | e |
| r | C |      |   |     |   |   | U | tra | L | C | q | lly | . | t |
| a | o |      |   |     |   |   | s | ine | e | a | u |     | 2 | a |
| m | m |      |   |     |   |   | a | d** | n | s | i |     | 5 | i |
| e | p |      |   |     |   |   | g |     | g | e | r |     | 6 | n |
| t | o |      |   |     |   |   | e |     | t | * | e |     |   | e |
| e | n |      |   |     |   |   | * |     | h | * | d |     |   | d |
| r | e |      |   |     |   |   | * |     | * |   |   |     |   |   |
| s | n |      |   |     |   |   |   |     | * |   |   |     |   |   |
|   | t |      |   |     |   |   |   |     |   |   |   |     |   |   |
|   | * |      |   |     |   |   |   |     |   |   |   |     |   |   |
|   | * |      |   |     |   |   |   |     |   |   |   |     |   |   |
+---+---+------+---+-----+---+---+---+-----+---+---+---+-----+---+---+
|   | i | *    | * | **C | * | * | r | par |   | r |   |     |   |   |
|   | n | *Com | * | ons | * | * | e | tia |   | e |   |     |   |   |
|   | d | pone | U | tra | L | C | q | lly |   | t |   |     |   |   |
|   | p | nt** | s | ine | e | a | u |     |   | a |   |     |   |   |
|   | a |      | a | d** | n | s | i |     |   | i |   |     |   |   |
|   | r |      | g |     | g | e | r |     |   | n |   |     |   |   |
|   | a |      | e |     | t | * | e |     |   | e |   |     |   |   |
|   | m |      | * |     | h | * | d |     |   | d |   |     |   |   |
|   | s |      | * |     | * |   |   |     |   |   |   |     |   |   |
|   |   |      |   |     | * |   |   |     |   |   |   |     |   |   |
+---+---+------+---+-----+---+---+---+-----+---+---+---+-----+---+---+
|   |   | ind  | r | par | 1 | r |   |     |   |   |   |     |   |   |
|   |   | p    | e | tia | . | e |   |     |   |   |   |     |   |   |
|   |   | aram | q | lly | . | t |   |     |   |   |   |     |   |   |
|   |   | eter | u |     | 4 | a |   |     |   |   |   |     |   |   |
|   |   |      | i |     | 9 | i |   |     |   |   |   |     |   |   |
|   |   |      | r |     |   | n |   |     |   |   |   |     |   |   |
|   |   |      | e |     |   | e |   |     |   |   |   |     |   |   |
|   |   |      | d |     |   | d |   |     |   |   |   |     |   |   |
+---+---+------+---+-----+---+---+---+-----+---+---+---+-----+---+---+
|   |   | …    | … | …   | … | … |   |     |   |   |   |     |   |   |
+---+---+------+---+-----+---+---+---+-----+---+---+---+-----+---+---+
|   | d |      |   |     |   |   | r | par | 1 | r |   |     |   |   |
|   | e |      |   |     |   |   | e | tia | . | e |   |     |   |   |
|   | p |      |   |     |   |   | q | lly | . | t |   |     |   |   |
|   | e |      |   |     |   |   | u |     | 4 | a |   |     |   |   |
|   | n |      |   |     |   |   | i |     | 9 | i |   |     |   |   |
|   | d |      |   |     |   |   | r |     |   | n |   |     |   |   |
|   | e |      |   |     |   |   | e |     |   | e |   |     |   |   |
|   | n |      |   |     |   |   | d |     |   | d |   |     |   |   |
|   | t |      |   |     |   |   |   |     |   |   |   |     |   |   |
|   | p |      |   |     |   |   |   |     |   |   |   |     |   |   |
|   | a |      |   |     |   |   |   |     |   |   |   |     |   |   |
|   | r |      |   |     |   |   |   |     |   |   |   |     |   |   |
|   | a |      |   |     |   |   |   |     |   |   |   |     |   |   |
|   | m |      |   |     |   |   |   |     |   |   |   |     |   |   |
|   | e |      |   |     |   |   |   |     |   |   |   |     |   |   |
|   | t |      |   |     |   |   |   |     |   |   |   |     |   |   |
|   | e |      |   |     |   |   |   |     |   |   |   |     |   |   |
|   | r |      |   |     |   |   |   |     |   |   |   |     |   |   |
+---+---+------+---+-----+---+---+---+-----+---+---+---+-----+---+---+
| v |   |      |   |     |   |   |   |     |   |   | r | no  |   | r |
| e |   |      |   |     |   |   |   |     |   |   | e |     | 1 | e |
| r |   |      |   |     |   |   |   |     |   |   | q |     | . | t |
| s |   |      |   |     |   |   |   |     |   |   | u |     | . | a |
| i |   |      |   |     |   |   |   |     |   |   | i |     | 3 | i |
| o |   |      |   |     |   |   |   |     |   |   | r |     | 2 | n |
| n |   |      |   |     |   |   |   |     |   |   | e |     |   | e |
|   |   |      |   |     |   |   |   |     |   |   | d |     |   | d |
+---+---+------+---+-----+---+---+---+-----+---+---+---+-----+---+---+

Rating Specifications
=====================

Rating specification identifiers are comprised of four top level
components: location Id, template parameters ID, template version ID and
specification version ID, separated by the dot, or period, character (.)
as a delimiter. Note that the second and third components make up the
rating template identifier used by the specification.

Rating specifications in the CWMS database represent combinations of
locations, rating templates, and temporal lookup behavior.

The requirements on the characters used in rating specification
identifiers are the sum of the restrictions on the individual
components. The maximum length of a rating specification ID is 372
characters when using a non-aliased location. Using a location alias
increases the maximum length to 579 characters.

+---+---+------+---+-----+---+---+---+-----+---+---+---+-----+---+---+
| * |   |      |   |     |   |   |   |     |   |   | * | **C | * | * |
| * |   |      |   |     |   |   |   |     |   |   | * | ons | * | * |
| C |   |      |   |     |   |   |   |     |   |   | U | tra | L | C |
| o |   |      |   |     |   |   |   |     |   |   | s | ine | e | a |
| m |   |      |   |     |   |   |   |     |   |   | a | d** | n | s |
| p |   |      |   |     |   |   |   |     |   |   | g |     | g | e |
| o |   |      |   |     |   |   |   |     |   |   | e |     | t | * |
| n |   |      |   |     |   |   |   |     |   |   | * |     | h | * |
| e |   |      |   |     |   |   |   |     |   |   | * |     | * |   |
| n |   |      |   |     |   |   |   |     |   |   |   |     | * |   |
| t |   |      |   |     |   |   |   |     |   |   |   |     |   |   |
| * |   |      |   |     |   |   |   |     |   |   |   |     |   |   |
| * |   |      |   |     |   |   |   |     |   |   |   |     |   |   |
+===+===+======+===+=====+===+===+===+=====+===+===+===+=====+===+===+
| l |   |      |   |     |   |   |   |     |   |   | r | no  | 1 | r |
| o |   |      |   |     |   |   |   |     |   |   | e |     | . | e |
| c |   |      |   |     |   |   |   |     |   |   | q |     | . | t |
| a |   |      |   |     |   |   |   |     |   |   | u |     | 4 | a |
| t |   |      |   |     |   |   |   |     |   |   | i |     | 9 | i |
| i |   |      |   |     |   |   |   |     |   |   | r |     |   | n |
| o |   |      |   |     |   |   |   |     |   |   | e |     |   | e |
| n |   |      |   |     |   |   |   |     |   |   | d |     |   | d |
+---+---+------+---+-----+---+---+---+-----+---+---+---+-----+---+---+
| p | * |      |   |     |   |   | * | **C | * | * | r | par | 1 | r |
| a | * |      |   |     |   |   | * | ons | * | * | e | tia | . | e |
| r | C |      |   |     |   |   | U | tra | L | C | q | lly | . | t |
| a | o |      |   |     |   |   | s | ine | e | a | u |     | 2 | a |
| m | m |      |   |     |   |   | a | d** | n | s | i |     | 5 | i |
| e | p |      |   |     |   |   | g |     | g | e | r |     | 6 | n |
| t | o |      |   |     |   |   | e |     | t | * | e |     |   | e |
| e | n |      |   |     |   |   | * |     | h | * | d |     |   | d |
| r | e |      |   |     |   |   | * |     | * |   |   |     |   |   |
| s | n |      |   |     |   |   |   |     | * |   |   |     |   |   |
|   | t |      |   |     |   |   |   |     |   |   |   |     |   |   |
|   | * |      |   |     |   |   |   |     |   |   |   |     |   |   |
|   | * |      |   |     |   |   |   |     |   |   |   |     |   |   |
+---+---+------+---+-----+---+---+---+-----+---+---+---+-----+---+---+
|   | i | *    | * | **C | * | * | r | par |   | r |   |     |   |   |
|   | n | *Com | * | ons | * | * | e | tia |   | e |   |     |   |   |
|   | d | pone | U | tra | L | C | q | lly |   | t |   |     |   |   |
|   | p | nt** | s | ine | e | a | u |     |   | a |   |     |   |   |
|   | a |      | a | d** | n | s | i |     |   | i |   |     |   |   |
|   | r |      | g |     | g | e | r |     |   | n |   |     |   |   |
|   | a |      | e |     | t | * | e |     |   | e |   |     |   |   |
|   | m |      | * |     | h | * | d |     |   | d |   |     |   |   |
|   | s |      | * |     | * |   |   |     |   |   |   |     |   |   |
|   |   |      |   |     | * |   |   |     |   |   |   |     |   |   |
+---+---+------+---+-----+---+---+---+-----+---+---+---+-----+---+---+
|   |   | ind  | r | par | 1 | r |   |     |   |   |   |     |   |   |
|   |   | p    | e | tia | . | e |   |     |   |   |   |     |   |   |
|   |   | aram | q | lly | . | t |   |     |   |   |   |     |   |   |
|   |   | eter | u |     | 4 | a |   |     |   |   |   |     |   |   |
|   |   |      | i |     | 9 | i |   |     |   |   |   |     |   |   |
|   |   |      | r |     |   | n |   |     |   |   |   |     |   |   |
|   |   |      | e |     |   | e |   |     |   |   |   |     |   |   |
|   |   |      | d |     |   | d |   |     |   |   |   |     |   |   |
+---+---+------+---+-----+---+---+---+-----+---+---+---+-----+---+---+
|   |   | …    | … | …   | … | … |   |     |   |   |   |     |   |   |
+---+---+------+---+-----+---+---+---+-----+---+---+---+-----+---+---+
|   | d |      |   |     |   |   | r | par | 1 | r |   |     |   |   |
|   | e |      |   |     |   |   | e | tia | . | e |   |     |   |   |
|   | p |      |   |     |   |   | q | lly | . | t |   |     |   |   |
|   | e |      |   |     |   |   | u |     | 4 | a |   |     |   |   |
|   | n |      |   |     |   |   | i |     | 9 | i |   |     |   |   |
|   | d |      |   |     |   |   | r |     |   | n |   |     |   |   |
|   | e |      |   |     |   |   | e |     |   | e |   |     |   |   |
|   | n |      |   |     |   |   | d |     |   | d |   |     |   |   |
|   | t |      |   |     |   |   |   |     |   |   |   |     |   |   |
|   | p |      |   |     |   |   |   |     |   |   |   |     |   |   |
|   | a |      |   |     |   |   |   |     |   |   |   |     |   |   |
|   | r |      |   |     |   |   |   |     |   |   |   |     |   |   |
|   | a |      |   |     |   |   |   |     |   |   |   |     |   |   |
|   | m |      |   |     |   |   |   |     |   |   |   |     |   |   |
|   | e |      |   |     |   |   |   |     |   |   |   |     |   |   |
|   | t |      |   |     |   |   |   |     |   |   |   |     |   |   |
|   | e |      |   |     |   |   |   |     |   |   |   |     |   |   |
|   | r |      |   |     |   |   |   |     |   |   |   |     |   |   |
+---+---+------+---+-----+---+---+---+-----+---+---+---+-----+---+---+
| t |   |      |   |     |   |   |   |     |   |   | r | no  | 1 | r |
| e |   |      |   |     |   |   |   |     |   |   | e |     | . | e |
| m |   |      |   |     |   |   |   |     |   |   | q |     | . | t |
| p |   |      |   |     |   |   |   |     |   |   | u |     | 3 | a |
| l |   |      |   |     |   |   |   |     |   |   | i |     | 2 | i |
| a |   |      |   |     |   |   |   |     |   |   | r |     |   | n |
| t |   |      |   |     |   |   |   |     |   |   | e |     |   | e |
| e |   |      |   |     |   |   |   |     |   |   | d |     |   | d |
| v |   |      |   |     |   |   |   |     |   |   |   |     |   |   |
| e |   |      |   |     |   |   |   |     |   |   |   |     |   |   |
| r |   |      |   |     |   |   |   |     |   |   |   |     |   |   |
| s |   |      |   |     |   |   |   |     |   |   |   |     |   |   |
| i |   |      |   |     |   |   |   |     |   |   |   |     |   |   |
| o |   |      |   |     |   |   |   |     |   |   |   |     |   |   |
| n |   |      |   |     |   |   |   |     |   |   |   |     |   |   |
+---+---+------+---+-----+---+---+---+-----+---+---+---+-----+---+---+
| s |   |      |   |     |   |   |   |     |   |   | r | no  | 1 | r |
| p |   |      |   |     |   |   |   |     |   |   | e |     | . | e |
| e |   |      |   |     |   |   |   |     |   |   | q |     | . | t |
| c |   |      |   |     |   |   |   |     |   |   | u |     | 3 | a |
| i |   |      |   |     |   |   |   |     |   |   | i |     | 2 | i |
| f |   |      |   |     |   |   |   |     |   |   | r |     |   | n |
| i |   |      |   |     |   |   |   |     |   |   | e |     |   | e |
| c |   |      |   |     |   |   |   |     |   |   | d |     |   | d |
| a |   |      |   |     |   |   |   |     |   |   |   |     |   |   |
| t |   |      |   |     |   |   |   |     |   |   |   |     |   |   |
| i |   |      |   |     |   |   |   |     |   |   |   |     |   |   |
| o |   |      |   |     |   |   |   |     |   |   |   |     |   |   |
| n |   |      |   |     |   |   |   |     |   |   |   |     |   |   |
| v |   |      |   |     |   |   |   |     |   |   |   |     |   |   |
| e |   |      |   |     |   |   |   |     |   |   |   |     |   |   |
| r |   |      |   |     |   |   |   |     |   |   |   |     |   |   |
| s |   |      |   |     |   |   |   |     |   |   |   |     |   |   |
| i |   |      |   |     |   |   |   |     |   |   |   |     |   |   |
| o |   |      |   |     |   |   |   |     |   |   |   |     |   |   |
| n |   |      |   |     |   |   |   |     |   |   |   |     |   |   |
+---+---+------+---+-----+---+---+---+-----+---+---+---+-----+---+---+

Specified Levels
================

Specified level identifiers are single-component identifiers that are
not constrained. They may be no more than 256 characters long. They not
case sensitive, but are case retained. That is, no two specified level
IDs for the same office may differ only in character case, and a
specified level may be passed to the CWMS Database API using any case,
but the character case of the identifier as created is retained. CWMS
convention is to use title case - capitalizing the first, and only the
first, letter of each significant word.

Specified levels in the CWMS database represent abstract thresholds,
limits, or other quantities that can be applied to the combination of
location and parameter information to produce concrete thresholds,
limits, or quantities.

+-------------------+-----------+---------------+---------+-----------+
| **Component**     | **Usage** | **            | **L     | **Case**  |
|                   |           | Constrained** | ength** |           |
+===================+===========+===============+=========+===========+
| specified level   | required  | no            | 1..256  | retained  |
+-------------------+-----------+---------------+---------+-----------+

Location Levels
===============

Location level identifiers are comprised of five required components:
location ID, parameter ID, parameter type ID, duration ID, and specified
level ID, separated by the dot, or period, character (.) as a delimiter.
No two location levels for the same office may have the same location
level identifier.

Location levels in the CWMS database specify thresholds, limits, or
other quantities that apply to the combination of the identifier
components.

The requirements on the characters used in location level identifiers
are the sum of the restrictions on the individual components. The
maximum length of a location level ID is 390 characters when using
non-aliased locations. Using location aliases increases the maximum
length to 695 characters.

+-------------------+-----------+---------------+---------+-----------+
| **Component**     | **Usage** | **            | **L     | **Case**  |
|                   |           | Constrained** | ength** |           |
+===================+===========+===============+=========+===========+
| location          | required  | no            | 1..49   | retained  |
+-------------------+-----------+---------------+---------+-----------+
| parameter         | required  | partially     | 1..49   | retained  |
+-------------------+-----------+---------------+---------+-----------+
| parameter type    | required  | yes           | 1..16   | retained  |
+-------------------+-----------+---------------+---------+-----------+
| duration          | required  | yes           | 1..16   | retained  |
+-------------------+-----------+---------------+---------+-----------+
| specified level   | required  | no            | 1..256  | retained  |
+-------------------+-----------+---------------+---------+-----------+

Location Level Indicators
=========================

Location level indicator identifiers are comprised of six required
components: location ID, parameter ID, parameter type ID, duration ID,
specified level ID, and indicator ID separated by the dot, or period,
character (.) as a delimiter. The indicator identifier is unconstrained,
may be no more than 32 characters, and is always upper case. No two
location level indicators for the same office may have the same location
level indicator identifier.

Location level indicators in the CWMS database specify classifications
of conditions with respect to location levels or a pair of location
levels.

The requirements on the characters used in location level identifiers
are the sum of the restrictions on the individual components. The
maximum length of a location level ID is 390 characters when using
non-aliased locations. Using location aliases increases the maximum
length to 695 characters.

+-------------------+-----------+---------------+---------+-----------+
| **Component**     | **Usage** | **            | **L     | **Case**  |
|                   |           | Constrained** | ength** |           |
+===================+===========+===============+=========+===========+
| location          | required  | no            | 1..49   | retained  |
+-------------------+-----------+---------------+---------+-----------+
| parameter         | required  | partially     | 1..49   | retained  |
+-------------------+-----------+---------------+---------+-----------+
| parameter type    | required  | yes           | 1..16   | retained  |
+-------------------+-----------+---------------+---------+-----------+
| duration          | required  | yes           | 1..16   | retained  |
+-------------------+-----------+---------------+---------+-----------+
| specified level   | required  | no            | 1..256  | retained  |
+-------------------+-----------+---------------+---------+-----------+
| indicator         | required  | no            | 1..32   | upper     |
+-------------------+-----------+---------------+---------+-----------+

Location and Time Series Categories
===================================

Location category identifiers and time series category identifiers are
single-component identifiers that are not constrained. They may be no
more than 32 characters long. They not case sensitive, but are case
retained. That is, no two location category IDs and no two time series
category IDs for the same office may differ only in character case; they
may be passed to the CWMS Database API using any case, but the character
case of the identifier as created is retained. CWMS convention is to use
title case - capitalizing the first, and only the first, letter of each
significant word.

Location and time series categories in the CWMS database specify the
first tier of a two-tier grouping system into which locations and time
series may be collected.

+-------------------+-----------+---------------+---------+-----------+
| **Component**     | **Usage** | **            | **L     | **Case**  |
|                   |           | Constrained** | ength** |           |
+===================+===========+===============+=========+===========+
| category          | required  | no            | 1..32   | retained  |
+-------------------+-----------+---------------+---------+-----------+

Location and Time Series Groups
===============================

Location group identifiers and time series group identifiers are
single-component identifiers that are not constrained. They may be no
more than 65 characters long. They not case sensitive, but are case
retained. That is, no two location group IDs and no two time series
group IDs for the same office may differ only in character case; they
may be passed to the CWMS Database API using any case, but the character
case of the identifier as created is retained. CWMS convention is to use
title case - capitalizing the first, and only the first, letter of each
significant word.

Location and time series groups in the CWMS database specify the second
tier of a two-tier grouping system into which locations and time series
may be collected.

+-------------------+-----------+---------------+---------+-----------+
| **Component**     | **Usage** | **            | **L     | **Case**  |
|                   |           | Constrained** | ength** |           |
+===================+===========+===============+=========+===========+
| category          | required  | no            | 1..65   | retained  |
+-------------------+-----------+---------------+---------+-----------+

Location and Time Series Aliases
================================

Location aliases and time series aliases are single-component
identifiers that are not constrained. They may be no more than 256
characters long. They not case sensitive, but are case retained. That
is, they may be passed to the CWMS Database API using any case, but the
character case of the identifier as created is retained. CWMS convention
is to use title case - capitalizing the first, and only the first,
letter of each significant word.

Location and time series aliases in the CWMS database specify
alternative identifiers for locations and time series items. The aliases
are not constrained to the format of location IDs or time series IDs;
they may free form text. However, aliases that do not conform to the
naming requirements of the aliased item type may not be compatible with
all software that access the CWMS database.

+-------------------+-----------+---------------+---------+-----------+
| **Component**     | **Usage** | **            | **L     | **Case**  |
|                   |           | Constrained** | ength** |           |
+===================+===========+===============+=========+===========+
| alias             | optional  | no            | 1..256  | retained  |
+-------------------+-----------+---------------+---------+-----------+

Units
=====

Unit identifiers are single-component identifiers that are constrained.
They may be no more than 16 characters long. They are case sensitive.
That is, two unit IDs may differ only in character case. The same unit
ID may also be used for more than one abstract parameter, with different
meanings for each.

Units in the CWMS database specify the measurement units of values and
are determined by abstract parameters. All unit IDs of a given abstract
parameter are convertible to each other except for where the various
units imply incompatible measurement methodologies (as in turbidity).

+-------------------+-----------+---------------+---------+-----------+
| **Component**     | **Usage** | **            | **L     | **Case**  |
|                   |           | Constrained** | ength** |           |
+===================+===========+===============+=========+===========+
| unit              | required  | yes           | 1..16   | sensitive |
+-------------------+-----------+---------------+---------+-----------+

+-----------------------+--------+-------------------------------------+
| **Abstract Parameter  | **Unit | **Unit Description**                |
| ID**                  | ID**   |                                     |
+=======================+========+=====================================+
| Angle                 | deg    | Angle of 1 degree                   |
+-----------------------+--------+-------------------------------------+
| Angle                 | rev    | Angle of 360 degrees                |
+-----------------------+--------+-------------------------------------+
| Angular Speed         | rpm    | Angular speed of 1 revolution per   |
|                       |        | minute                              |
+-----------------------+--------+-------------------------------------+
| Area                  | 1000   | Area of 1E+03 square meters         |
|                       | m2     |                                     |
+-----------------------+--------+-------------------------------------+
| Area                  | acre   | Area of 1 acre                      |
+-----------------------+--------+-------------------------------------+
| Area                  | ft2    | Area of 1 square foot               |
+-----------------------+--------+-------------------------------------+
| Area                  | ha     | Area of 1 hectare                   |
+-----------------------+--------+-------------------------------------+
| Area                  | km2    | Area of a square kilometer          |
+-----------------------+--------+-------------------------------------+
| Area                  | m2     | Area of 1 square meter              |
+-----------------------+--------+-------------------------------------+
| Area                  | mile2  | Area of 1 square mile               |
+-----------------------+--------+-------------------------------------+
| Areal Volume Rate     | c      | Volume rate of 1 cfs per area of 1  |
|                       | fs/mi2 | square mile                         |
+-----------------------+--------+-------------------------------------+
| Areal Volume Rate     | c      | Volume rate of 1 cms per area of 1  |
|                       | ms/km2 | square kilometer                    |
+-----------------------+--------+-------------------------------------+
| Conductance           | mho    | Conductance of 1 mho (1/ohm)        |
+-----------------------+--------+-------------------------------------+
| Conductance           | S      | Conductance of 1 Siemens            |
+-----------------------+--------+-------------------------------------+
| Conductance           | umho   | Conductance of 1E-06 mhos           |
+-----------------------+--------+-------------------------------------+
| Conductance           | uS     | Conductance of 1E-06 Siemens        |
+-----------------------+--------+-------------------------------------+
| Conductivity          | u      | Conductivity of 1 micro-mho per     |
|                       | mho/cm | centimeter                          |
+-----------------------+--------+-------------------------------------+
| Count                 | unit   | Number of items counted             |
+-----------------------+--------+-------------------------------------+
| Currency              | $      | Monetary value of 1 United States   |
|                       |        | dollar                              |
+-----------------------+--------+-------------------------------------+
| Elapsed Time          | hr     | Time span of 1 hour                 |
+-----------------------+--------+-------------------------------------+
| Elapsed Time          | min    | Time span of 1 minute               |
+-----------------------+--------+-------------------------------------+
| Elapsed Time          | sec    | Time span of 1 second               |
+-----------------------+--------+-------------------------------------+
| Electric Charge Rate  | ampere | Current of 6.241E+18 electrons (1   |
|                       |        | coulomb) per second                 |
+-----------------------+--------+-------------------------------------+
| Electromotive         | volt   | Electromotive Potential of 1 volt   |
| Potential             |        |                                     |
+-----------------------+--------+-------------------------------------+
| Energy                | GWh    | Energy of 1E+09 watt-hours          |
+-----------------------+--------+-------------------------------------+
| Energy                | kWh    | Energy of 1E+03 watt-hours          |
+-----------------------+--------+-------------------------------------+
| Energy                | MWh    | Energy of 1E+06 watt-hours          |
+-----------------------+--------+-------------------------------------+
| Energy                | TWh    | Energy of 1E+12 watt-hours          |
+-----------------------+--------+-------------------------------------+
| Energy                | Wh     | Energy of 3.6E+03 Kilogram-square   |
|                       |        | meter per square second             |
+-----------------------+--------+-------------------------------------+
| Force                 | lb     | Force of 1 pound                    |
+-----------------------+--------+-------------------------------------+
| Hydrogen Ion          | su     | Potential of hydrogen               |
| Concentration Index   |        | (acidity/alkalinity)                |
+-----------------------+--------+-------------------------------------+
| Irradiance            | langl  | Radiant power of 1 langley per      |
|                       | ey/min | minute                              |
+-----------------------+--------+-------------------------------------+
| Irradiance            | W/m2   | Radiant power of 1 watt per area of |
|                       |        | 1 square meter                      |
+-----------------------+--------+-------------------------------------+
| Irradiation           | J/m2   | Radiant energy 1 joule per area of  |
|                       |        | 1 square meter                      |
+-----------------------+--------+-------------------------------------+
| Irradiation           | l      | Radiant energy of 1 langley         |
|                       | angley |                                     |
+-----------------------+--------+-------------------------------------+
| Length                | cm     | Length of 1E-02 meter               |
+-----------------------+--------+-------------------------------------+
| Length                | ft     | Length of 1 foot                    |
+-----------------------+--------+-------------------------------------+
| Length                | in     | Length of 1 inch                    |
+-----------------------+--------+-------------------------------------+
| Length                | km     | Length of 1E+03 meters              |
+-----------------------+--------+-------------------------------------+
| Length                | m      | Length of 1 meter                   |
+-----------------------+--------+-------------------------------------+
| Length                | mi     | Length of 1 mile                    |
+-----------------------+--------+-------------------------------------+
| Length                | mm     | Length of 1 millimeter              |
+-----------------------+--------+-------------------------------------+
| Linear Speed          | ft/s   | Velocity of 1 foot per second       |
+-----------------------+--------+-------------------------------------+
| Linear Speed          | in/day | Velocity of 1 inch per day          |
+-----------------------+--------+-------------------------------------+
| Linear Speed          | in/hr  | Velocity of 1 inch per hour         |
+-----------------------+--------+-------------------------------------+
| Linear Speed          | kph    | Velocity of 1 kilometer per Hour    |
+-----------------------+--------+-------------------------------------+
| Linear Speed          | m/s    | Velocity of 1 meter per second      |
+-----------------------+--------+-------------------------------------+
| Linear Speed          | mm/day | Velocity of 1 millimeter per day    |
+-----------------------+--------+-------------------------------------+
| Linear Speed          | mm/hr  | Velocity of 1 millimeter per hour   |
+-----------------------+--------+-------------------------------------+
| Linear Speed          | mph    | Velocity of 1 mile per hour         |
+-----------------------+--------+-------------------------------------+
| Mass Concentration    | g/l    | Mass concentration of 1 gram per    |
|                       |        | liter                               |
+-----------------------+--------+-------------------------------------+
| Mass Concentration    | gm/cm3 | Mass concentration of 1 gram per    |
|                       |        | cubic centimeter                    |
+-----------------------+--------+-------------------------------------+
| Mass Concentration    | mg/l   | Mass concentration of 1E-03 gram    |
|                       |        | per liter                           |
+-----------------------+--------+-------------------------------------+
| Mass Concentration    | ppm    | Mass concentration of 1 mg/l        |
+-----------------------+--------+-------------------------------------+
| None                  | %      | Ratio of 1E-02                      |
+-----------------------+--------+-------------------------------------+
| None                  | n/a    | Unitless value such as a ratio or   |
|                       |        | code                                |
+-----------------------+--------+-------------------------------------+
| Phase Change Rate     | in/d   | Phase change of 1 inch per day per  |
| Index                 | eg-day | Fahrenheit degree                   |
+-----------------------+--------+-------------------------------------+
| Phase Change Rate     | mm/d   | Phase change of 1 millimeter per    |
| Index                 | eg-day | day per Celsius degree              |
+-----------------------+--------+-------------------------------------+
| Power                 | GW     | Power of 1E+09 watts                |
+-----------------------+--------+-------------------------------------+
| Power                 | kW     | Power of 1E+03 watts                |
+-----------------------+--------+-------------------------------------+
| Power                 | MW     | Power of 1E+06 watts                |
+-----------------------+--------+-------------------------------------+
| Power                 | TW     | Power of 1E+12 watts                |
+-----------------------+--------+-------------------------------------+
| Power                 | W      | Power of 1 watt (kilogram-square    |
|                       |        | meter per cubic second)             |
+-----------------------+--------+-------------------------------------+
| Pressure              | in-hg  | Barometric pressure                 |
+-----------------------+--------+-------------------------------------+
| Pressure              | kPa    | Pressure of 1 kilonewton per square |
|                       |        | meter                               |
+-----------------------+--------+-------------------------------------+
| Pressure              | mb     | Pressure of 1E-03 bar               |
+-----------------------+--------+-------------------------------------+
| Pressure              | mm-hg  | Barometric pressure                 |
+-----------------------+--------+-------------------------------------+
| Pressure              | psi    | Pressure of 1 pound per square inch |
+-----------------------+--------+-------------------------------------+
| Temperature           | C      | Celsius Degree                      |
+-----------------------+--------+-------------------------------------+
| Temperature           | F      | Fahrenheit Degree                   |
+-----------------------+--------+-------------------------------------+
| Turbidity             | FNU    | Measure of scattered light          |
|                       |        | (90+/-2.5 deg) from monochrome      |
|                       |        | light (860+/-60 nm)                 |
+-----------------------+--------+-------------------------------------+
| Turbidity             | JTU    | Jackson Turbidity Unit              |
|                       |        | (approximates nephelometric         |
|                       |        | turbidity unit)                     |
+-----------------------+--------+-------------------------------------+
| Turbidity             | NTU    | Measure of scattered light (90+/-30 |
|                       |        | deg) from a white light             |
|                       |        | (540+/-140nm)                       |
+-----------------------+--------+-------------------------------------+
| Volume                | 1000   | Volume of 1E+03 cubic meters        |
|                       | m3     |                                     |
+-----------------------+--------+-------------------------------------+
| Volume                | ac-ft  | Volume equal to the area of 1 acre  |
|                       |        | times the length of 1 foot          |
+-----------------------+--------+-------------------------------------+
| Volume                | dsf    | Volume of water accumulated in one  |
|                       |        | day by a flow of one cfs            |
+-----------------------+--------+-------------------------------------+
| Volume                | ft3    | Volume of 1 cubic foot              |
+-----------------------+--------+-------------------------------------+
| Volume                | gal    | Volume of 1 United States Gallon    |
+-----------------------+--------+-------------------------------------+
| Volume                | kaf    | Volume equal to the area of 1E+03   |
|                       |        | acres times the length of 1 foot    |
+-----------------------+--------+-------------------------------------+
| Volume                | kgal   | Volume of 1E+03 gallons             |
+-----------------------+--------+-------------------------------------+
| Volume                | km3    | Volume of a cubic kilometer         |
+-----------------------+--------+-------------------------------------+
| Volume                | m3     | Volume of 1 cubic meter             |
+-----------------------+--------+-------------------------------------+
| Volume                | mgal   | Volume of 1E+06 gallons             |
+-----------------------+--------+-------------------------------------+
| Volume                | mile3  | Volume of 1 cubic mile              |
+-----------------------+--------+-------------------------------------+
| Volume Rate           | cfs    | Volume rate of 1 cubic foot per     |
|                       |        | second                              |
+-----------------------+--------+-------------------------------------+
| Volume Rate           | cms    | Volume rate of 1 cubic meter per    |
|                       |        | second                              |
+-----------------------+--------+-------------------------------------+
| Volume Rate           | gpm    | Volume rate of 1 gallon per minute  |
+-----------------------+--------+-------------------------------------+
| Volume Rate           | kcfs   | Volume rate of 1E+03 cfs            |
+-----------------------+--------+-------------------------------------+
| Volume Rate           | mgd    | Volume rate of 1E+06 gallons per    |
|                       |        | day                                 |
+-----------------------+--------+-------------------------------------+
