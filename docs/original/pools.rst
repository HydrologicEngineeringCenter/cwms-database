==========
CWMS POOLS
==========

Introduction
============

CWMS pools are database constructs that include:

-  A CWMS project location

-  A CWMS pool name

-  A CWMS location level for the lower limit of the pool

-  A CWMS location level for the upper limit of the pool

Project locations and pool names are static. That is, a project or pool
may be renamed without breaking the relationship. However, the location
levels for the lower and upper limits are dynamic; they are specified by
name and resolved to actual location levels when used. This arrangement
accommodates the fact that multiple location levels of the same name may
form a time-related progression of definitions.

Pool Names
==========

A list of standard pool names are provided in the database. Local pool
names may also be created, renamed, or deleted in the database. However,
standard pool names cannot be renamed or deleted. Pool names retain the
character case used to store them, but local pool names that differ only
in case from another local or standard pool name cannot be created.
Local pool names created by one office do not affect the local pool
names that may be created by another office in the same database.

Pool Definitions
================

A pool definition is the association of a pool name with a project
location and bottom and top limit location levels. The bottom limit
location level is *exclusive*, while the top limit location level is
*inclusive*. That is, if pool A is limited by location levels A-Bottom
and A-Top and Pool B is limited by A-Top and B-Top, then the elevation
of exactly A-Top *is* in pool A and *is not* in pool B.

The associations that define pools may be *explicit* or *implicit*.

*Explicit* pool definitions store the association of project location,
pool name, bottom limit location level, and top limit location level in
a table in the database. The only restrictions are:

-  Each of the objects must already exist in the database

-  The bottom and top limit location levels must be of the form
   <project>.Elev.Inst.0.<specified_level>

-  The bottom and top limit location levels must be for the specified
   project

*Implicit* pool definitions are associations that are *not* stored in
the database, but that exist because for some project <project> and some
pool name <pool> that *are* stored in the database, there also exist the
following location levels:

-  <project>.Elev.Inst.0.Top of <pool>

-  <project>.Elev.Inst.0.Bottom of <pool>

Implicit pool definitions can be used anywhere explicit ones can be
used. The only difference is that deleting the bottom and/or top limit
location levels of an implicit pool definition silently removes the pool
definition. Deleting any location level used in an explicit pool
definition will fail unless the procedure
Cwms_Level.Delete_Location_Level_Ex2() is used with the P_Delete_Pools
parameter set to ‘T’.

Any implicit pool definition may be made explicit by storing the pool
definition with the Cwms_Pool.Store_Pool() procedure.

Elevation Orientation.
======================

Although only elevation location levels – specifically Elev.Inst.0 – are
used to define pools, the Cwms_Pool package includes routines that
return storage limits, storage offsets, and percent full. Two mechanisms
are provided to work with storages related to pools: storage location
levels and ratings.

Parameters Controlling Storage Determination
--------------------------------------------

Each procedure or function that uses storage has the following two
parameters:

-  P_Always_Rate Varchar2 Default ‘T’

-  P_Rating_Spec Varchar2 Default null

The P_Always_Rate parameter should be set to ‘T’ or ‘F’; if omitted, it
defaults to ‘T’. When set to ‘T’, storage values are always rated from
elevation values. When set to ‘F’, pool storage limits are determined
from storage location levels, if available. The storage limit location
levels used are the same as the elevation limit location levels with
‘Elev.Inst.0’ replaced with ‘Stor.Inst.0’. If the expected storage limit
location level doesn’t exist, then storage is rated from the elevation
limit location level, even if P_Always_Rate is set to ‘F’.

The P_Rating_Spec parameter is used to specify a rating specification to
use for rating elevation to storage, if specified or necessary. If not
set, the default value is null. If rating elevation to storage is
specified or necessary and P_Rating_Set is null, a standard rating
specification will be used, if available. In this case, if zero or more
than one standard rating specification is available, the routine will
raise an exception.

Standard Elevation to Storage Rating Specification
--------------------------------------------------

If a procedure or function is required to rate elevation to storage and
no rating specification is provided, the routine will look for a
standard rating specification. Given the rating specification format of
<location>.<parameters>.<template_version>.<specification_version>, a
standard elevation to storage rating is one that:

-  <location> is the same as the name of the project (P_Project_Id
   parameter)

-  <parameters> is ‘Elev;Stor’

-  <template_version> is one of:

   -  ‘Linear’

   -  ‘Log’

   -  ‘Custom’

   -  ‘Standard’

-  < specification \_version> is one of:

   -  ‘Step’

   -  ‘Distributed’

   -  ‘Custom’

   -  ‘Production’

Application Programming Interface
=================================

Views
-----

Applications may select against the following views.

Cwms_V_Pool_Name
~~~~~~~~~~~~~~~~

This view contains the following columns:

-  Office_Id Varchar2(16) The identifier of the office that owns the
   pool name

-  Office_Code Number(10) The numeric code of the office that owns the
   pool name

-  Pool_Name Varchar2(32) The name of the pool

-  Pool_Name_Code Number The numeric code of the pool

Cwms_V_Pool
~~~~~~~~~~~

This view contains the following columns:

-  Office_Id Varchar2(16) The identifier of the office that owns the
   pool name

-  Office_Code Number(10) The numeric code of the office that owns the
   pool name

-  Project_Id Varchar2(49) The identifier of the project that contains
   the pool

-  Project_Location_Code Number(10) The numeric code of the project

-  Pool_Name Varchar2(32) The name of the pool

-  Pool_Name_Code Number The numeric code of the pool

-  Definition_Type Char(8) ‘IMPLICIT’ or ‘EXPLICIT’

-  Bottom_Level Varchar2(357) Location level ID for bottom limit of pool

-  Top_Level Varchar2(357) Location level ID for top limit of pool

Managing Pool Names
-------------------

Pool names may be created, renamed, deleted, and cataloged via PL/SQL
procedures. A PL/SQL function also exists for cataloging information
pool names. In addition, a view exists for viewing pool name
information.

The cataloging routines include the same information as the
Cwms_V_Pool_Name view minus the numeric code columns.

+--------+----------------------+-------------------------------------+
| Item   | Name                 | Purpose                             |
| Type   |                      |                                     |
+========+======================+=====================================+
| Pro    | Cwms_                | Stores (creates or updates) a pool  |
| cedure | Pool.Store_Pool_Name | name                                |
+--------+----------------------+-------------------------------------+
| Pro    | C                    | Renames a pool                      |
| cedure | wms_Pool.Rename_Pool |                                     |
+--------+----------------------+-------------------------------------+
| Pro    | Cwms_P               | Deletes a pool name                 |
| cedure | ool.Delete_Pool_Name |                                     |
+--------+----------------------+-------------------------------------+
| Pro    | Cwms                 | Catalogs pool names                 |
| cedure | _Pool.Cat_Pool_Names |                                     |
+--------+----------------------+-------------------------------------+
| Fu     | Cwms_P               | Catalogs pool names                 |
| nction | ool.Cat_Pool_Names_F |                                     |
+--------+----------------------+-------------------------------------+
| View   | Cwms_V_Pool_Name     | Displays pool names                 |
+--------+----------------------+-------------------------------------+

Managing Pool Definitions
-------------------------

Explicit pool definitions may be created, retrieved, updated, deleted,
and cataloged. PL/SQL procedures exist for all of these uses. PL/SQL
functions also exist for retrieving and cataloging information.

The cataloging routines include the same information as the Cwms_V_Pool
view minus the numeric code columns and the Definition_Type column.

+--------+--------------------+---------------------------------------+
| Item   | Name               | Purpose                               |
| Type   |                    |                                       |
+========+====================+=======================================+
| Pro    | Cw                 | Stores (creates or updates) explicit  |
| cedure | ms_Pool.Store_Pool | pool information                      |
+--------+--------------------+---------------------------------------+
| Pro    | Cwms_              | Retrieves bottom and top limit        |
| cedure | Pool.Retrieve_Pool | location level names                  |
+--------+--------------------+---------------------------------------+
| Fu     | Cwms_Po            | Retrieves bottom and top limit        |
| nction | ol.Retrieve_Pool_F | location level names                  |
+--------+--------------------+---------------------------------------+
| Pro    | Cwm                | Deletes explicit pool information for |
| cedure | s_Pool.Delete_Pool | a project                             |
+--------+--------------------+---------------------------------------+
| Pro    | C                  | Catalogs pool definitions in the      |
| cedure | wms_Pool.Cat_Pools | database                              |
+--------+--------------------+---------------------------------------+
| Fu     | Cwm                | Catalogs pool definitions in the      |
| nction | s_Pool.Cat_Pools_F | database                              |
+--------+--------------------+---------------------------------------+
| View   | Cwms_V_Pool        | Displays pool definitions             |
+--------+--------------------+---------------------------------------+

Computations Using Pool Definitions
-----------------------------------

The bottom and top limit location levels have values that may be
constant, vary periodically, or vary regularly. In addition, location
levels may be redefined. Routines are provided that:

-  Return whether a specified elevation is in a specified pool

-  Return which pools a specified elevation is in

-  Return the bottom and/or top limit elevation or storage values

-  Return the offset of a specified elevation or storage from the bottom
   and/or top limit values

-  Return the percent full of a specified pool represented by a
   specified elevation or storage

Each of these can be computed for a specified elevation and/or storage
value and a specified date/time. Except for the first two items – which
are also restricted to elevations – computations are also supported for:

-  A specified table of values and a table of date/time rows

-  A table of (date/time, value, quality_code) rows

-  A time series identifier and a specified time window

PL/SQL procedures and function exist for all computations. Functions
that return compound table types may be directed to return the results
grouped by date/time or by type of information (e.g., bottom or top
limit values).

Many routines have the same name but are overloaded (i.e., they have
different parameters). See the CWMS Database API documentation for more
detailed information.

+--------+------------------------------+-----------------------------+
| Item   | Name                         | Purpose                     |
| Type   |                              |                             |
+========+==============================+=============================+
| Pro    | Cwms_Pool.In_Pool            | Retrieves whether a         |
| cedure |                              | specified elevation is in a |
|        |                              | specified pool at a         |
|        |                              | specified time              |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms_Pool.In_Pool_F          | Retrieves whether a         |
| nction |                              | specified elevation is in a |
|        |                              | specified pool at a         |
|        |                              | specified time              |
+--------+------------------------------+-----------------------------+
| Pro    | Cwms_Po                      | Catalogs pool names that    |
| cedure | ol.Cat_Containing_Pool_Names | contain a specified         |
|        |                              | elevation at a specified    |
|        |                              | time                        |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms_Pool                    | Catalogs pool names that    |
| nction | .Cat_Containing_Pool_Names_F | contain a specified         |
|        |                              | elevation at a specified    |
|        |                              | time                        |
+--------+------------------------------+-----------------------------+
| Pro    | C                            | Retrieves the pool top *or* |
| cedure | wms_Pool.Get_Pool_Limit_Elev | bottom limit elevation *at  |
|        |                              | a specified time*           |
+--------+------------------------------+-----------------------------+
| Fu     | Cwm                          | Retrieves the pool top *or* |
| nction | s_Pool.Get_Pool_Limit_Elev_F | bottom limit elevation *at  |
|        |                              | a specified time*           |
+--------+------------------------------+-----------------------------+
| Pro    | Cw                           | Retrieves the pool top      |
| cedure | ms_Pool.Get_Pool_Limit_Elevs | *and* bottom limit          |
|        |                              | elevation *at a specified   |
|        |                              | time*                       |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms                         | Retrieves the pool top      |
| nction | _Pool.Get_Pool_Limit_Elevs_F | *and* bottom limit          |
|        |                              | elevation *at a specified   |
|        |                              | time*                       |
+--------+------------------------------+-----------------------------+
| Pro    | Cw                           | Retrieves the pool top *or* |
| cedure | ms_Pool.Get_Pool_Limit_Elevs | bottom limit elevations *at |
|        |                              | multiple times*             |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms                         | Retrieves the pool top *or* |
| nction | _Pool.Get_Pool_Limit_Elevs_F | bottom limit elevations *at |
|        |                              | multiple times*             |
+--------+------------------------------+-----------------------------+
| Pro    | Cw                           | Retrieves the pool top      |
| cedure | ms_Pool.Get_Pool_Limit_Elevs | *and* bottom limit          |
|        |                              | elevations *at multiple     |
|        |                              | times*                      |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms                         | Retrieves the pool top      |
| nction | _Pool.Get_Pool_Limit_Elevs_F | *and* bottom limit          |
|        |                              | elevations *at multiple     |
|        |                              | times*                      |
+--------+------------------------------+-----------------------------+
| Pro    | Cw                           | Retrieves the pool top *or* |
| cedure | ms_Pool.Get_Pool_Limit_Elevs | bottom limit elevations *at |
|        |                              | times in a specified time   |
|        |                              | series*                     |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms                         | Retrieves the pool top *or* |
| nction | _Pool.Get_Pool_Limit_Elevs_F | bottom limit elevations *at |
|        |                              | times in a specified time   |
|        |                              | series*                     |
+--------+------------------------------+-----------------------------+
| Pro    | Cw                           | Retrieves the pool top      |
| cedure | ms_Pool.Get_Pool_Limit_Elevs | *and* bottom limit          |
|        |                              | elevations *at times in a   |
|        |                              | specified time series*      |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms                         | Retrieves the pool top      |
| nction | _Pool.Get_Pool_Limit_Elevs_F | *and* bottom limit          |
|        |                              | elevations *at times in a   |
|        |                              | specified time series*      |
+--------+------------------------------+-----------------------------+
| Pro    | Cw                           | Retrieves the pool top *or* |
| cedure | ms_Pool.Get_Pool_Limit_Elevs | bottom limit elevations *at |
|        |                              | times in a specified time   |
|        |                              | series identifier and time  |
|        |                              | window*                     |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms                         | Retrieves the pool top *or* |
| nction | _Pool.Get_Pool_Limit_Elevs_F | bottom limit elevations *at |
|        |                              | times in a specified time   |
|        |                              | series identifier and time  |
|        |                              | window*                     |
+--------+------------------------------+-----------------------------+
| Pro    | Cw                           | Retrieves the pool top      |
| cedure | ms_Pool.Get_Pool_Limit_Elevs | *and* bottom limit          |
|        |                              | elevations *at times in a   |
|        |                              | specified time series       |
|        |                              | identifier and time window* |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms                         | Retrieves the pool top      |
| nction | _Pool.Get_Pool_Limit_Elevs_F | *and* bottom limit          |
|        |                              | elevations *at times in a   |
|        |                              | specified time series       |
|        |                              | identifier and time window* |
+--------+------------------------------+-----------------------------+
| Pro    | C                            | Retrieves the pool top *or* |
| cedure | wms_Pool.Get_Pool_Limit_Stor | bottom limit storage *at a  |
|        |                              | specified time*             |
+--------+------------------------------+-----------------------------+
| Fu     | Cwm                          | Retrieves the pool top *or* |
| nction | s_Pool.Get_Pool_Limit_Stor_F | bottom limit storage *at a  |
|        |                              | specified time*             |
+--------+------------------------------+-----------------------------+
| Pro    | Cw                           | Retrieves the pool top      |
| cedure | ms_Pool.Get_Pool_Limit_Stors | *and* bottom limit storage  |
|        |                              | *at a specified time*       |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms                         | Retrieves the pool top      |
| nction | _Pool.Get_Pool_Limit_Stors_F | *and* bottom limit storage  |
|        |                              | *at a specified time*       |
+--------+------------------------------+-----------------------------+
| Pro    | Cw                           | Retrieves the pool top *or* |
| cedure | ms_Pool.Get_Pool_Limit_Stors | bottom limit storages *at   |
|        |                              | multiple times*             |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms                         | Retrieves the pool top *or* |
| nction | _Pool.Get_Pool_Limit_Stors_F | bottom limit storages *at   |
|        |                              | multiple times*             |
+--------+------------------------------+-----------------------------+
| Pro    | Cw                           | Retrieves the pool top      |
| cedure | ms_Pool.Get_Pool_Limit_Stors | *and* bottom limit storages |
|        |                              | *at multiple times*         |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms                         | Retrieves the pool top      |
| nction | _Pool.Get_Pool_Limit_Stors_F | *and* bottom limit storages |
|        |                              | *at multiple times*         |
+--------+------------------------------+-----------------------------+
| Pro    | Cw                           | Retrieves the pool top *or* |
| cedure | ms_Pool.Get_Pool_Limit_Stors | bottom limit storages *at   |
|        |                              | times in a specified time   |
|        |                              | series*                     |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms                         | Retrieves the pool top *or* |
| nction | _Pool.Get_Pool_Limit_Stors_F | bottom limit storages *at   |
|        |                              | times in a specified time   |
|        |                              | series*                     |
+--------+------------------------------+-----------------------------+
| Pro    | Cw                           | Retrieves the pool top      |
| cedure | ms_Pool.Get_Pool_Limit_Stors | *and* bottom limit storages |
|        |                              | *at times in a specified    |
|        |                              | time series*                |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms                         | Retrieves the pool top      |
| nction | _Pool.Get_Pool_Limit_Stors_F | *and* bottom limit storages |
|        |                              | *at times in a specified    |
|        |                              | time series*                |
+--------+------------------------------+-----------------------------+
| Pro    | Cw                           | Retrieves the pool top *or* |
| cedure | ms_Pool.Get_Pool_Limit_Stors | bottom limit storages *at   |
|        |                              | times in a specified time   |
|        |                              | series identifier and time  |
|        |                              | window*                     |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms                         | Retrieves the pool top *or* |
| nction | _Pool.Get_Pool_Limit_Stors_F | bottom limit storages *at   |
|        |                              | times in a specified time   |
|        |                              | series identifier and time  |
|        |                              | window*                     |
+--------+------------------------------+-----------------------------+
| Pro    | Cw                           | Retrieves the pool top      |
| cedure | ms_Pool.Get_Pool_Limit_Stors | *and* bottom limit storages |
|        |                              | *at times in a specified    |
|        |                              | time series identifier and  |
|        |                              | time window*                |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms                         | Retrieves the pool top      |
| nction | _Pool.Get_Pool_Limit_Stors_F | *and* bottom limit storages |
|        |                              | *at times in a specified    |
|        |                              | time series identifier and  |
|        |                              | time window*                |
+--------+------------------------------+-----------------------------+
| Pro    | Cwms_Pool.Get_Elev_Offset    | Retrieves the offset of an  |
| cedure |                              | elevation above the bottom  |
|        |                              | *or* top limit elevation at |
|        |                              | *a specified time*          |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms_Pool.Get_Elev_Offset_F  | Retrieves the offset of an  |
| nction |                              | elevation above the bottom  |
|        |                              | *or* top limit elevation at |
|        |                              | *a specified time*          |
+--------+------------------------------+-----------------------------+
| Pro    | Cwms_Pool.Get_Elev_Offsets   | Retrieves the offset of an  |
| cedure |                              | elevation above the bottom  |
|        |                              | *and* top limit elevations  |
|        |                              | at *a specified time*       |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms_Pool.Get_Elev_Offsets_F | Retrieves the offset of an  |
| nction |                              | elevation above the bottom  |
|        |                              | *and* top limit elevations  |
|        |                              | at *a specified time*       |
+--------+------------------------------+-----------------------------+
| Pro    | Cwms_Pool.Get_Elev_Offsets   | Retrieves the offsets of a  |
| cedure |                              | table of elevations above   |
|        |                              | the bottom *or* top limit   |
|        |                              | elevations at multiple      |
|        |                              | times                       |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms_Pool.Get_Elev_Offsets_F | Retrieves the offsets of a  |
| nction |                              | table of elevations above   |
|        |                              | the bottom *or* top limit   |
|        |                              | elevations at multiple      |
|        |                              | times                       |
+--------+------------------------------+-----------------------------+
| Pro    | Cwms_Pool.Get_Elev_Offsets   | Retrieves the offsets of a  |
| cedure |                              | table of elevations above   |
|        |                              | the bottom *and* top limit  |
|        |                              | elevations at multiple      |
|        |                              | times                       |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms_Pool.Get_Elev_Offsets_F | Retrieves the offsets of a  |
| nction |                              | table of elevations above   |
|        |                              | the bottom *and* top limit  |
|        |                              | elevations at multiple      |
|        |                              | times                       |
+--------+------------------------------+-----------------------------+
| Pro    | Cwms_Pool.Get_Elev_Offsets   | Retrieves the offsets of    |
| cedure |                              | elevations *in a specified  |
|        |                              | time series* above the      |
|        |                              | bottom *or* top limit       |
|        |                              | elevations                  |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms_Pool.Get_Elev_Offsets_F | Retrieves the offsets of    |
| nction |                              | elevations *in a specified  |
|        |                              | time series* above the      |
|        |                              | bottom *or* top limit       |
|        |                              | elevations                  |
+--------+------------------------------+-----------------------------+
| Pro    | Cwms_Pool.Get_Elev_Offsets   | Retrieves the offsets of    |
| cedure |                              | elevations *in a specified  |
|        |                              | time series* above the      |
|        |                              | bottom *and* top limit      |
|        |                              | elevations                  |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms_Pool.Get_Elev_Offsets_F | Retrieves the offsets of    |
| nction |                              | elevations *in a specified  |
|        |                              | time series* above the      |
|        |                              | bottom *and* top limit      |
|        |                              | elevations                  |
+--------+------------------------------+-----------------------------+
| Pro    | Cwms_Pool.Get_Elev_Offsets   | Retrieves the offsets of    |
| cedure |                              | elevations *in a specified  |
|        |                              | time series identifier and  |
|        |                              | time window* above the      |
|        |                              | bottom *or* top limit       |
|        |                              | elevations                  |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms_Pool.Get_Elev_Offsets_F | Retrieves the offsets of    |
| nction |                              | elevations *in a specified  |
|        |                              | time series identifier and  |
|        |                              | time window* above the      |
|        |                              | bottom *or* top limit       |
|        |                              | elevations                  |
+--------+------------------------------+-----------------------------+
| Pro    | Cwms_Pool.Get_Elev_Offsets   | Retrieves the offsets of    |
| cedure |                              | elevations *in a specified  |
|        |                              | time series identifier and  |
|        |                              | time window* above the      |
|        |                              | bottom *and* top limit      |
|        |                              | elevations                  |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms_Pool.Get_Elev_Offsets_F | Retrieves the offsets of    |
| nction |                              | elevations *in a specified  |
|        |                              | time series identifier and  |
|        |                              | time window* above the      |
|        |                              | bottom *and* top limit      |
|        |                              | elevations                  |
+--------+------------------------------+-----------------------------+
|        |                              |                             |
+--------+------------------------------+-----------------------------+
| Pro    | Cwms_Pool.Get_Stor_Offset    | Retrieves the offset of an  |
| cedure |                              | storage above the bottom    |
|        |                              | *or* top limit storage at   |
|        |                              | *a specified time*          |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms_Pool.Get_Stor_Offset_F  | Retrieves the offset of an  |
| nction |                              | storage above the bottom    |
|        |                              | *or* top limit storage at   |
|        |                              | *a specified time*          |
+--------+------------------------------+-----------------------------+
| Pro    | Cwms_Pool.Get_Stor_Offsets   | Retrieves the offset of an  |
| cedure |                              | storage above the bottom    |
|        |                              | *and* top limit storages at |
|        |                              | *a specified time*          |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms_Pool.Get_Stor_Offsets_F | Retrieves the offset of an  |
| nction |                              | storage above the bottom    |
|        |                              | *and* top limit storages at |
|        |                              | *a specified time*          |
+--------+------------------------------+-----------------------------+
| Pro    | Cwms_Pool.Get_Stor_Offsets   | Retrieves the offsets of a  |
| cedure |                              | table of storages above the |
|        |                              | bottom *or* top limit       |
|        |                              | storages at multiple times  |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms_Pool.Get_Stor_Offsets_F | Retrieves the offsets of a  |
| nction |                              | table of storages above the |
|        |                              | bottom *or* top limit       |
|        |                              | storages at multiple times  |
+--------+------------------------------+-----------------------------+
| Pro    | Cwms_Pool.Get_Stor_Offsets   | Retrieves the offsets of a  |
| cedure |                              | table of storages above the |
|        |                              | bottom *and* top limit      |
|        |                              | storages at multiple times  |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms_Pool.Get_Stor_Offsets_F | Retrieves the offsets of a  |
| nction |                              | table of storages above the |
|        |                              | bottom *and* top limit      |
|        |                              | storages at multiple times  |
+--------+------------------------------+-----------------------------+
| Pro    | Cwms_Pool.Get_Stor_Offsets   | Retrieves the offsets of    |
| cedure |                              | storages *in a specified    |
|        |                              | time series* above the      |
|        |                              | bottom *or* top limit       |
|        |                              | storages                    |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms_Pool.Get_Stor_Offsets_F | Retrieves the offsets of    |
| nction |                              | storages *in a specified    |
|        |                              | time series* above the      |
|        |                              | bottom *or* top limit       |
|        |                              | storages                    |
+--------+------------------------------+-----------------------------+
| Pro    | Cwms_Pool.Get_Stor_Offsets   | Retrieves the offsets of    |
| cedure |                              | storages *in a specified    |
|        |                              | time series* above the      |
|        |                              | bottom *and* top limit      |
|        |                              | storages                    |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms_Pool.Get_Stor_Offsets_F | Retrieves the offsets of    |
| nction |                              | storages *in a specified    |
|        |                              | time series* above the      |
|        |                              | bottom *and* top limit      |
|        |                              | storages                    |
+--------+------------------------------+-----------------------------+
| Pro    | Cwms_Pool.Get_Stor_Offsets   | Retrieves the offsets of    |
| cedure |                              | storages *in a specified    |
|        |                              | time series identifier and  |
|        |                              | time window* above the      |
|        |                              | bottom *or* top limit       |
|        |                              | storages                    |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms_Pool.Get_Stor_Offsets_F | Retrieves the offsets of    |
| nction |                              | storages *in a specified    |
|        |                              | time series identifier and  |
|        |                              | time window* above the      |
|        |                              | bottom *or* top limit       |
|        |                              | storages                    |
+--------+------------------------------+-----------------------------+
| Pro    | Cwms_Pool.Get_Stor_Offsets   | Retrieves the offsets of    |
| cedure |                              | storages *in a specified    |
|        |                              | time series identifier and  |
|        |                              | time window* above the      |
|        |                              | bottom *and* top limit      |
|        |                              | storages                    |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms_Pool.Get_Stor_Offsets_F | Retrieves the offsets of    |
| nction |                              | storages *in a specified    |
|        |                              | time series identifier and  |
|        |                              | time window* above the      |
|        |                              | bottom *and* top limit      |
|        |                              | storages                    |
+--------+------------------------------+-----------------------------+
| Pro    | Cwms_Pool.Get_Percent_Full   | Retrieves the percent full  |
| cedure |                              | computed from an elevation  |
|        |                              | or storage value *at single |
|        |                              | time*                       |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms_Pool.Get_Percent_Full_F | Retrieves the percent full  |
| nction |                              | computed from an elevation  |
|        |                              | or storage value *at single |
|        |                              | time*                       |
+--------+------------------------------+-----------------------------+
| Pro    | Cwms_Pool.Get_Percent_Full   | Retrieves the percent full  |
| cedure |                              | computed from a table of    |
|        |                              | elevation or storage values |
|        |                              | *at multiple times*         |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms_Pool.Get_Percent_Full_F | Retrieves the percent full  |
| nction |                              | computed from a table of    |
|        |                              | elevation or storage values |
|        |                              | *at multiple times*         |
+--------+------------------------------+-----------------------------+
| Pro    | Cwms_Pool.Get_Percent_Full   | Retrieves the percent full  |
| cedure |                              | computed from a elevation   |
|        |                              | or storage values *in a     |
|        |                              | time series*                |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms_Pool.Get_Percent_Full_F | Retrieves the percent full  |
| nction |                              | computed from a table of    |
|        |                              | elevation or storage values |
|        |                              | *in a time series*          |
+--------+------------------------------+-----------------------------+
| Pro    | Cwms_Pool.Get_Percent_Full   | Retrieves the percent full  |
| cedure |                              | computed from a elevation   |
|        |                              | or storage values *in a     |
|        |                              | time series identifier and  |
|        |                              | time window*                |
+--------+------------------------------+-----------------------------+
| Fu     | Cwms_Pool.Get_Percent_Full_F | Retrieves the percent full  |
| nction |                              | computed from a elevation   |
|        |                              | or storage values *in a     |
|        |                              | time series identifier and  |
|        |                              | time window*                |
+--------+------------------------------+-----------------------------+

ER-Diagram
==========

|image1|
========

.. |image1| image:: ./pools/media/image1.png
   :width: 6.21in
   :height: 4.71in
