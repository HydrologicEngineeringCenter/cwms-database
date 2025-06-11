=======================
CWMS Database Locations
=======================

Contents
========

`Overview <#overview>`__\ `4 <#overview>`__

`Locations, Base Locations, and
Sub-Locations <#locations-base-locations-and-sub-locations>`__\ `4 <#locations-base-locations-and-sub-locations>`__

`The AT_BASE_LOCATION
Table <#the-at_base_location-table>`__\ `5 <#the-at_base_location-table>`__

`Identity <#identity>`__\ `5 <#identity>`__

`BASE_LOCATION_CODE <#base_location_code>`__\ `5 <#base_location_code>`__

`DB_OFFICE_CODE <#db_office_code>`__\ `5 <#db_office_code>`__

`BASE_LOCATION_ID <#base_location_id>`__\ `5 <#base_location_id>`__

`Other <#other>`__\ `5 <#other>`__

`ACTIVE_FLAG <#active_flag>`__\ `5 <#active_flag>`__

`The
AT_PHYSICAL_LOCATION_TABLE <#the-at_physical_location_table>`__\ `6 <#the-at_physical_location_table>`__

`Identity <#identity-1>`__\ `6 <#identity-1>`__

`LOCATION_CODE <#location_code>`__\ `6 <#location_code>`__

`BASE_LOCATION_CODE <#base_location_code-1>`__\ `6 <#base_location_code-1>`__

`SUB_LOCATION_ID <#sub_location_id>`__\ `6 <#sub_location_id>`__

`Label <#label>`__\ `6 <#label>`__

`PUBLIC_NAME <#public_name>`__\ `6 <#public_name>`__

`LONG_NAME <#long_name>`__\ `6 <#long_name>`__

`MAP_LABEL <#map_label>`__\ `6 <#map_label>`__

`DESCRIPTION <#description>`__\ `6 <#description>`__

`Geolocation <#geolocation>`__\ `7 <#geolocation>`__

`ELEVATION <#elevation>`__\ `7 <#elevation>`__

`VERTICAL_DATUM <#vertical_datum>`__\ `7 <#vertical_datum>`__

`LONGITUDE <#longitude>`__\ `7 <#longitude>`__

`LATITUDE <#latitude>`__\ `7 <#latitude>`__

`HORIZONTAL_DATUM <#horizontal_datum>`__\ `7 <#horizontal_datum>`__

`PUBLISHED_LATITUDE <#published_latitude>`__\ `7 <#published_latitude>`__

`PUBLISHED_LONGITUDE <#published_longitude>`__\ `8 <#published_longitude>`__

`Political <#political>`__\ `8 <#political>`__

`TIME_ZONE_CODE <#time_zone_code>`__\ `8 <#time_zone_code>`__

`COUNTY_CODE <#county_code>`__\ `8 <#county_code>`__

`NATION_CODE <#nation_code>`__\ `8 <#nation_code>`__

`NEAREST_CITY <#nearest_city>`__\ `8 <#nearest_city>`__

`OFFICE_CODE <#office_code>`__\ `8 <#office_code>`__

`Other <#other-1>`__\ `8 <#other-1>`__

`LOCATION_TYPE <#location_type>`__\ `8 <#location_type>`__

`LOCATION_KIND <#location_kind>`__\ `8 <#location_kind>`__

`ACTIVE_FLAG <#active_flag-1>`__\ `9 <#active_flag-1>`__

`LOCATION-BASED ITEM
TYPES <#location-based-item-types>`__\ `9 <#location-based-item-types>`__

`BASINS <#basins>`__\ `9 <#basins>`__

`The AT_BASIN
Table <#the-at_basin-table>`__\ `9 <#the-at_basin-table>`__

`BASIN_LOCATION_CODE <#basin_location_code>`__\ `9 <#basin_location_code>`__

`TOTAL_DRAINAGE_AREA <#total_drainage_area>`__\ `9 <#total_drainage_area>`__

`CONTRIBUTING_DRAINAGE_AREA <#contributing_drainage_area>`__\ `9 <#contributing_drainage_area>`__

`PRIMARY_STREAM_CODE <#primary_stream_code>`__\ `9 <#primary_stream_code>`__

`PARENT_BASIN_CODE <#parent_basin_code>`__\ `10 <#parent_basin_code>`__

`SORT_ORDER <#sort_order>`__\ `10 <#sort_order>`__

`STREAMS <#streams>`__\ `10 <#streams>`__

`The AT_STREAM
Table <#the-at_stream-table>`__\ `10 <#the-at_stream-table>`__

`STREAM_LOCATION_CODE <#stream_location_code>`__\ `10 <#stream_location_code>`__

`ZERO_STATION <#zero_station>`__\ `10 <#zero_station>`__

`DIVERTING_STREAM_CODE <#diverting_stream_code>`__\ `10 <#diverting_stream_code>`__

`DIVERSION_STATION <#diversion_station>`__\ `10 <#diversion_station>`__

`DIVERSION_BANK <#diversion_bank>`__\ `11 <#diversion_bank>`__

`RECEIVING_STREAM_CODE <#receiving_stream_code>`__\ `11 <#receiving_stream_code>`__

`CONFLUENCE_STATION <#confluence_station>`__\ `11 <#confluence_station>`__

`CONFLUENCE_BANK <#confluence_bank>`__\ `11 <#confluence_bank>`__

`STREAM_LENGTH <#stream_length>`__\ `11 <#stream_length>`__

`AVERAGE_SLOPE <#average_slope>`__\ `11 <#average_slope>`__

`COMMENTS <#comments>`__\ `11 <#comments>`__

`PROJECTS <#projects>`__\ `11 <#projects>`__

`The AT_PROJECT
Table <#the-at_project-table>`__\ `11 <#the-at_project-table>`__

`PROJECT_LOCATION_CODE <#project_location_code>`__\ `11 <#project_location_code>`__

`FEDERAL_COST <#federal_cost>`__\ `12 <#federal_cost>`__

`NONFEDERAL_COST <#nonfederal_cost>`__\ `12 <#nonfederal_cost>`__

`COST_YEAR <#cost_year>`__\ `12 <#cost_year>`__

`FEDERAL_OM_COST <#federal_om_cost>`__\ `12 <#federal_om_cost>`__

`NONFEDERAL_OM_COST <#nonfederal_om_cost>`__\ `12 <#nonfederal_om_cost>`__

`AUTHORIZING_LAW <#authorizing_law>`__\ `12 <#authorizing_law>`__

`PROJECT_OWNER <#project_owner>`__\ `12 <#project_owner>`__

`HYDROPOWER_DESCRIPTION <#hydropower_description>`__\ `12 <#hydropower_description>`__

`SEDIMENTATION_DESCRIPTION <#sedimentation_description>`__\ `12 <#sedimentation_description>`__

`DOWNSTREAM_URBAN_DESCRIPTION <#downstream_urban_description>`__\ `12 <#downstream_urban_description>`__

`BANK_FULL_CAPACITY_DESCRIPTION <#bank_full_capacity_description>`__\ `12 <#bank_full_capacity_description>`__

`PUMP_BACK_LOCATION_CODE <#pump_back_location_code>`__\ `12 <#pump_back_location_code>`__

`NEAR_GAGE_LOCATION_CODE <#near_gage_location_code>`__\ `13 <#near_gage_location_code>`__

`YIELD_TIME_FRAME_START <#yield_time_frame_start>`__\ `13 <#yield_time_frame_start>`__

`YIELD_TIME_FRAME_END <#yield_time_frame_end>`__\ `13 <#yield_time_frame_end>`__

`PROJECT_REMARKS <#project_remarks>`__\ `13 <#project_remarks>`__

`OUTLETS <#outlets>`__\ `13 <#outlets>`__

`The AT_OUTLET
Table <#the-at_outlet-table>`__\ `13 <#the-at_outlet-table>`__

`OUTLET_LOCATION_CODE <#outlet_location_code>`__\ `13 <#outlet_location_code>`__

`PROJECT_LOCATION_CODE <#project_location_code-1>`__\ `13 <#project_location_code-1>`__

`TURBINES <#turbines>`__\ `13 <#turbines>`__

`The AT_TURBINE
Table <#the-at_turbine-table>`__\ `14 <#the-at_turbine-table>`__

`TURBINE_LOCATION_CODE <#turbine_location_code>`__\ `14 <#turbine_location_code>`__

`PROJECT_LOCATION_CODE <#project_location_code-2>`__\ `14 <#project_location_code-2>`__

`EMBANKMENTS <#embankments>`__\ `14 <#embankments>`__

`The AT_EMBANKMENT
Table <#the-at_embankment-table>`__\ `14 <#the-at_embankment-table>`__

`EMBANKMENT_LOCATION_CODE <#embankment_location_code>`__\ `14 <#embankment_location_code>`__

`EMBANKMENT_PROJECT_LOC_CODE <#embankment_project_loc_code>`__\ `14 <#embankment_project_loc_code>`__

`STRUCTURE_TYPE_CODE <#structure_type_code>`__\ `14 <#structure_type_code>`__

`STRUCTURE_LENGTH <#structure_length>`__\ `14 <#structure_length>`__

`UPSTREAM_PROT_TYPE_CODE <#upstream_prot_type_code>`__\ `14 <#upstream_prot_type_code>`__

`UPSTREAM_SIDESLOPE <#upstream_sideslope>`__\ `15 <#upstream_sideslope>`__

`DOWNSTREAM_PROT_TYPE_CODE <#downstream_prot_type_code>`__\ `15 <#downstream_prot_type_code>`__

`DOWNSTREAM_SIDESLOPE <#downstream_sideslope>`__\ `15 <#downstream_sideslope>`__

`HEIGHT_MAX <#height_max>`__\ `15 <#height_max>`__

`TOP_WIDTH <#top_width>`__\ `15 <#top_width>`__

`LOCKS <#locks>`__\ `15 <#locks>`__

`The AT_LOCK Table <#the-at_lock-table>`__\ `15 <#the-at_lock-table>`__

`LOCK_LOCATION_CODE <#lock_location_code>`__\ `15 <#lock_location_code>`__

`PROJECT_LOCATION_CODE <#project_location_code-3>`__\ `15 <#project_location_code-3>`__

`LOCK_WIDTH <#lock_width>`__\ `15 <#lock_width>`__

`LOCK_LENGTH <#lock_length>`__\ `16 <#lock_length>`__

`VOLUME_PER_LOCKAGE <#volume_per_lockage>`__\ `16 <#volume_per_lockage>`__

`MINIMUM_DRAFT <#minimum_draft>`__\ `16 <#minimum_draft>`__

`NORMAL_LOCK_LIFT <#normal_lock_lift>`__\ `16 <#normal_lock_lift>`__

Overview
========

Locations are central to nearly every other type of information in the
CWMS database. This document describes the relationships and attributes
of locations in the database as well as the several location-based
classes of items in the database.

Locations, Base Locations, and Sub-Locations
============================================

Locations are named according to a two-tier scheme that differentiates
between a base location and a sub-location. However, in the database
they exist simply as locations. Every base location has an entry in the
AT_PHYSICAL_LOCATION table, as does every sub-location. The distinction
in the database between base locations and sub-locations is that:

-  Base locations also have entries in the AT_BASE_LOCATION table,
   sub-locations do not.

-  Base location entries in the AT_PHYSICAL_LOCATION table have the same
   values for the LOCATION_CODE and BASE_LOCATION_CODE columns.

-  Base location entries in the AT_PHYSICAL_LOCATION table have their
   SUB_LOCATION_ID column values set to NULL.

-  Sub-location entries in the AT_PHYSICAL_LOCATION table have their
   BASE_LOCATION_CODE column values set to the same value as the
   LOCATION_CODE column for their base locations.

-  Sub-location entries in the AT_PHYSICAL_LOCATION table have non-NULL
   values in the SUB_LOCATION_ID column.

This means that the text before and after the first hyphen (-) in the
location name are not just portions of a name, but that they each
represent locations in the database and are related in a two-tier system
in which each base location may have many sub-locations.

The AT_BASE_LOCATION Table
==========================

As mentioned above, each base location has an entry in the
AT_BASE_LOCATION table. Its columns are:

Identity
--------

BASE_LOCATION_CODE
~~~~~~~~~~~~~~~~~~

The BASE_LOCATION_CODE column contains the unique numeric code that
identifies the base location in the database. This is the same as the
LOCATION_CODE value in the AT_PHYSICAL_LOCATION table for the same
location.

DB_OFFICE_CODE
~~~~~~~~~~~~~~

The DB_OFFICE_CODE column contains the unique numeric code that
identifies the office that owns the base location and all of its
sub-locations, if any, in the database. This is the same as the
OFFICE_CODE value in the CWMS_OFFICE table for the owning office.

BASE_LOCATION_ID
~~~~~~~~~~~~~~~~

The BASE_LOCATION_ID column contains the text identifier of the base
location (i.e. the base location name, the portion of the location name
before the first hyphen (-)). The text may be up to 16 characters.

Other
-----

ACTIVE_FLAG
~~~~~~~~~~~

The ACTIVE_FLAG column is a 1-character text column limited to the
values of ‘T’ (for true) and ‘F’ for false). If ‘T’, the base location,
all of its sub-locations, and any database items related to those
locations are available for normal use within the CWMS Database API; if
‘F’, none of those items are allowed to be used by the API.

The AT_PHYSICAL_LOCATION_TABLE
==============================

As mentioned above, every location, whether base location or
sub-location, has an entry in the AT_PHYSICAL_LOCATION table. This is
where most of the information associated with a location is specified.

.. _identity-1:

Identity
--------

LOCATION_CODE
~~~~~~~~~~~~~

The LOCATION_CODE column contains the unique numeric code that
identifies the location in the database.

.. _base_location_code-1:

BASE_LOCATION_CODE
~~~~~~~~~~~~~~~~~~

The BASE_LOCATION_CODE column contains the unique numeric code that
identifies this location’s base location in the database. This is the
same as the BASE_LOCATION_CODE value in the AT_BASE_LOCATION table for
this location’s base location. If this location *is* a base location,
this value is also the same as the LOCATION_CODE column value.

SUB_LOCATION_ID
~~~~~~~~~~~~~~~

The SUB_LOCATION_ID column contains the sub-location identifier (the
portion of the location name after the first hyphen (-)). It is
unconstrained and may contain up to 32 characters. If this location is a
base location, this value must be NULL, otherwise, it must not be NULL.

Label
-----

PUBLIC_NAME
~~~~~~~~~~~

The PUBLIC_NAME column is one of two unconstrained text general purpose
labeling columns. It may contain up to 32 characters. This is the
primary labeling column used by CWMS applications and should always be
populated.

LONG_NAME
~~~~~~~~~

The LONG_NAME column is one of two unconstrained text general purpose
labeling columns. It may contain up to 80 characters. This column is
used by CWMS applications that need to use the location name for a title
(such as for a report or plot). If this column is null, the PUBLIC_NAME
column will be used for this purpose as well.

MAP_LABEL
~~~~~~~~~

The MAP_LABEL column contains unconstrained text that can be up to 50
characters. This column is not used for any national-scope information
and may be used for office-specific purposes.

DESCRIPTION
~~~~~~~~~~~

The DESCRIPTION column contains unconstrained text that can be up to
1024 characters. It is intended to contain descriptive text about the
location.

Geolocation
-----------

ELEVATION
~~~~~~~~~

The ELEVATION column contains the reference elevation of the location in
meters with respect to the specified vertical datum. For most locations
the reference elevation is the ground elevation at the specified
latitude and longitude.

VERTICAL_DATUM
~~~~~~~~~~~~~~

The VERTICAL_DATUM column contains the vertical datum of the specified
elevation. It is unconstrained and may contain up to 16 characters.
Although this column is currently unconstrained, it will likely be
constrained in a future schema version, with the valid contents being
restricted to “NGVD29”, “NAVD88”, and “LOCAL” (NULLs not allowed).
During the conversion process, NULL values will be converted (if the
elevation is specified) to “NGVD29”, as will any other text that can
reasonably be interpreted to be the same; values that can be interpreted
to be the same as “NAVD88” will be set to “NAVD88”; all other values
will be set to “LOCAL”, with the original value moved to an entry in the
AT_VERT_DATUM_LOCAL table for the location. As the need develops to
handle OCONUS locations, the appropriate vertical datum names will be
added to the constraint.

LONGITUDE
~~~~~~~~~

The LONGITUDE column contains the reference longitude of the location in
decimal degrees with respect to the specified horizontal datum. For
gaged locations the reference longitude is that of the gage location.

LATITUDE
~~~~~~~~

The LATITUDE column contains the reference latitude of the location in
decimal degrees with respect to the specified horizontal datum. For
gaged locations the reference latitude is that of the gage location.

HORIZONTAL_DATUM
~~~~~~~~~~~~~~~~

The HORIZONTAL_DATUM column contains the horizontal datum of the
specified latitude and longitude. It is unconstrained and may be up to
16 characters. Although this column is currently unconstrained, it may
be constrained in a future schema version with the contents being
restricted to “NAD27”, “NAD83”, and “WGS84”, with possible qualifiers
added for “NAD83” and “WGS84” (e.g. “(original)”, “(1986)”, “(2011)”,
“(G1674)”). It is unclear at this time how a conversion process would
handle NULL values with latitude and longitude specified, or values that
could not be recognized to be the same as one of the accepted values. As
the need develops to handle OCONUS locations, the appropriate horizontal
datum names would be added to the constraint.

PUBLISHED_LATITUDE
~~~~~~~~~~~~~~~~~~

The PUBLISHED_LATITUDE column contains the latitude of the location as
listed in publications, either historical or current. This may be due to
the published latitude using a different horizontal datum than the
actual latitude or due to inaccuracies in the published latitude. This
field may be NULL if the published latitude is the same as the actual
latitude.

PUBLISHED_LONGITUDE
~~~~~~~~~~~~~~~~~~~

The PUBLISHED_LONGITUDE column contains the longitude of the location as
listed in publications, either historical or current. This may be due to
the published longitude using a different horizontal datum than the
actual longitude or due to inaccuracies in the published longitude. This
field may be NULL if the published longitude is the same as the actual
longitude.

Political
---------

TIME_ZONE_CODE
~~~~~~~~~~~~~~

The TIME_ZONE_CODE column contains the unique numerical code that
identifies the location’s time zone in the database. This value is the
same as the TIME_ZONE_CODE column value in the CWMS_TIME_ZONE table for
the location’s time zone.

COUNTY_CODE
~~~~~~~~~~~

The COUNTY_CODE column contains the unique numerical code that
identifies the location’s county in the database. This value is the same
as the COUNTY_CODE column value in the CWMS_COUNTY table for the
location’s county, and is also the FIPS county code (which also includes
the FIPS state code). This column is applicable only for the United
States, its territories and possessions.

NATION_CODE
~~~~~~~~~~~

The NATION_CODE column contains a unique 2-character code that
identifies the location’s nation in the database. This value is the same
as the NATION_CODE column in the CWMS_NATION table for the location’s
nation.

NEAREST_CITY
~~~~~~~~~~~~

The NEAREST_CITY column contains unconstrained text of up to 50
characters and should contain the name of the city nearest the location.

OFFICE_CODE
~~~~~~~~~~~

The OFFICE_CODE column contains the unique numerical code that
identifies the location’s bounding USACE office in the database. This
value is the same as the OFFICE_CODE column value in the CWMS_OFFICE
table for the lowest-level office whose boundary encompasses the
location. Note that this may be different from the office that owns the
location in the database.

.. _other-1:

Other
-----

LOCATION_TYPE
~~~~~~~~~~~~~

The LOCATION_TYPE column contains unconstrained text of up to 16
characters. This column is not used for any national-scope information
and may be used for office-specific purposes.

LOCATION_KIND
~~~~~~~~~~~~~

The LOCATION_KIND column contains the unique numerical code that
identifies the location’s kind as described in the AT_LOCATION_KIND
table. It is intended to specify the type of geometry represented by the
location as well as the meaning of the location’s latitude and longitude
with respect to that geometry. The value for this column is the same as
the LOCATION_KIND_CODE in the AT_LOCATION_KIND table for the location’s
kind. By default, the valid location kinds that can be referenced by
this code and their meanings are:

+-------------+--------------------------------------------------------+
| **Location  | **Description**                                        |
| Kind ID**   |                                                        |
+=============+========================================================+
| POINT       | A generic location that can be represented by a single |
|             | lat/lon.                                               |
+-------------+--------------------------------------------------------+
| STREAM      | A stream, the lat/lon represents the downstream-most   |
|             | point.                                                 |
+-------------+--------------------------------------------------------+
| BASIN       | A basin, the lat/lon represents the point on the major |
|             | stream draining the basin.                             |
+-------------+--------------------------------------------------------+

.. _active_flag-1:

ACTIVE_FLAG
~~~~~~~~~~~

The ACTIVE_FLAG column is a 1-character text column limited to the
values of ‘T’ (for true) and ‘F’ for false). If ‘T’, the location and
any database items related to it are available for normal use within the
CWMS Database API; if ‘F’, none of those items are allowed to be used by
the API.

LOCATION-BASED ITEM TYPES
=========================

As stated above, locations are central to nearly every other type of
information in the CWMS database. This is certainly true of time series,
location levels, and ratings, each of which includes location
information. However, unlike those item types, the ones discussed in
this section *are* locations; they extend or build on the locations in
ways specific to each item type.

BASINS
------

Basins are locations that represent rainfall catchments (“watersheds”)
in the CWMS database. Basins are of location kind BASIN (i.e. the
latitude and longitude represent the outlet of the basin). Basins are
normally base locations. Basin-specific information is stored in the
AT_BASIN table.

The AT_BASIN Table
------------------

BASIN_LOCATION_CODE
~~~~~~~~~~~~~~~~~~~

The BASIN_LOCATION_CODE column contains the unique numeric code that
identifies this basin in the database. This is the same value as the
LOCATION_CODE column value in the AT_PHYSICAL_LOCATION table for the
basin’s location record.

TOTAL_DRAINAGE_AREA
~~~~~~~~~~~~~~~~~~~

The TOTAL_DRAINAGE_AREA column contains the total geographical area of
the rainfall catchment in square meters.

CONTRIBUTING_DRAINAGE_AREA
~~~~~~~~~~~~~~~~~~~~~~~~~~

The CONTRIBUTING_DRAINAGE_AREA column contains the geographical area of
the rainfall catchment in square meters that contributes runoff to the
outlet of the basin.

PRIMARY_STREAM_CODE
~~~~~~~~~~~~~~~~~~~

The PRIMARY_STREAM_CODE column contains the unique numeric code that
identifies the basin’s primary stream in the database. This is the same
value as the STREAM_LOCATION_CODE column value in the AT_STREAM table as
well as the LOCATION_CODE column value in the AT_PHYSICAL_LOCATION table
for the basin’s primary stream.

PARENT_BASIN_CODE
~~~~~~~~~~~~~~~~~

The PARENT_BASIN_CODE column contains the unique numeric code that
identifies this basin’s parent basin in the database. This is the same
value as the BASIN_LOCATION_CODE in this table as well as the
LOCATION_CODE in the AT_PHYSICAL_LOCATION table for this basin’s parent
basin. This value is NULL if this basin has no parent basin in the
database (i.e. this basin is not a sub-basin).

SORT_ORDER
~~~~~~~~~~

The SORT_ORDER column contains a numeric value that orders this basin
with respect to other sub-basins of this basin’s parent basin. This
value is NULL if this basin has no parent basin in the database (i.e.
this basin is not a sub-basin) or if the sort order is undefined.

STREAMS
-------

Streams are locations that represent riverine objects (e.g. rivers,
streams, creeks, etc…) in the CWMS database. Streams are of location
kind STREAM (i.e. the latitude and longitude represent the
downstream-most point of the stream). Streams are normally base
locations. Stream-specific information is stored in the AT_STREAM table.

The AT_STREAM Table
-------------------

STREAM_LOCATION_CODE
~~~~~~~~~~~~~~~~~~~~

The STREAM_LOCATION_CODE column contains the unique numeric code that
identifies the stream in the database. This is the same value as the
LOCATION_CODE column value in the AT_PHYSICAL_LOCATION table for the
stream’s location record.

ZERO_STATION
~~~~~~~~~~~~

The ZERO_STATION column contains a two-character text code that is
constrained to the values “US” and “DS”, and indicates which extent of
the stream is considered stream station zero. If the value is “DS” (the
normal usage), stream stations increase with distance upstream;
otherwise stream stations increase with distance downstream.

DIVERTING_STREAM_CODE
~~~~~~~~~~~~~~~~~~~~~

The DIVERTING_STREAM_CODE column contains the unique numeric code that
identifies the source of this stream in the database. This value is the
same as the STREAM_LOCATION_CODE column value in this table as well as
the LOCATION_CODE column value in the AT_PHYSICAL_LOCATION table for
this stream’s source stream. This value is NULL if this stream does not
bifurcate or divert from a source stream.

DIVERSION_STATION
~~~~~~~~~~~~~~~~~

The DIVERTING_STREAM_STATION column contains the stream station in km on
the source stream from which this stream bifurcated or diverted. This
value is NULL if this stream does not bifurcate or divert from a source
stream.

DIVERSION_BANK
~~~~~~~~~~~~~~

The DIVERSION_BANK column contains a one-character text code that is
constrained to “R” and “L” and indicates the bank on the source stream
that this stream bifurcated or diverted from. If “R”, this stream left
the source stream from the right bank; if “L”, from the left. This value
is NULL if this stream does not bifurcate or divert from a source
stream.

RECEIVING_STREAM_CODE
~~~~~~~~~~~~~~~~~~~~~

The RECEIVING_STREAM_CODE column contains the unique numeric code that
identifies in the database the receiving stream of this stream. This
value is the same as the STREAM_LOCATION_CODE column value in this table
as well as the LOCATION_CODE column value in the AT_PHYSICAL_LOCTATION
table for the receiving stream of this stream. This value is NULL if
this stream does not join another stream at a confluence.

CONFLUENCE_STATION
~~~~~~~~~~~~~~~~~~

The CONFLUENCE_STATION column contains the stream station in km on the
receiving stream at which this stream joins. This value is NULL if this
stream does not join another stream at a confluence.

CONFLUENCE_BANK
~~~~~~~~~~~~~~~

The CONFLUENCE_BANK column contains a one-character text code that is
constrained to “R” and “L” and indicates the bank on the receiving
stream that this stream joins. If “R”, this stream joins the receiving
stream on its right bank; if “L”, on its left. This value is NULL if
this stream does not join another stream at a confluence.

STREAM_LENGTH
~~~~~~~~~~~~~

The STREAM_LENGTH column contains the length of this stream in
kilometers.

AVERAGE_SLOPE
~~~~~~~~~~~~~

The AVERAGE_SLOPE column contains the average slope of this stream in
percent.

COMMENTS
~~~~~~~~

The COMMENTS column contains an unconstrained text of up to 256
characters. It is intended to contain descriptive text or comments about
the stream.

PROJECTS 
--------

Projects are locations that represent physical structures used at least
in part for the USACE water management mission in the CWMS database.
Projects are of location kind POINT; a reference location for the
project, often a gage, is used for the latitude and longitude. Projects
are normally base locations. Project-specific information is stored in
the AT_PROJECT table.

The AT_PROJECT Table
--------------------

PROJECT_LOCATION_CODE
~~~~~~~~~~~~~~~~~~~~~

The PROJECT_LOCATION_CODE column contains the unique numeric code that
identifies the project in the database. This value is the same as the
LOCATION_CODE column value in the AT_PHYSICAL_LOCATION table for the
project’s location record.

FEDERAL_COST
~~~~~~~~~~~~

The FEDERAL_COST column contains the U.S. Government’s share of the
project’s construction cost, in U.S. dollars.

NONFEDERAL_COST
~~~~~~~~~~~~~~~

The NONFEDERAL_COST column contains the share of entities other than the
U.S. Government in the project’s construction cost, in U.S. dollars.

COST_YEAR
~~~~~~~~~

The COST_YEAR column contains the year that the cost columns are indexed
to.

FEDERAL_OM_COST
~~~~~~~~~~~~~~~

The FEDERAL_OM_COST column contains the U.S. Government’s share of the
annual operation and maintenance cost of the project.

NONFEDERAL_OM_COST
~~~~~~~~~~~~~~~~~~

The NONFEDERAL_OM_COST column contains the share of entities other than
the U.S. Government in the annual operation and maintenance cost of the
project.

AUTHORIZING_LAW
~~~~~~~~~~~~~~~

The AUTHORIZING_LAW column contains unconstrained text of up to 512
characters, and specifies the name of the legislation that authorized
the construction of the project.

PROJECT_OWNER
~~~~~~~~~~~~~

The PROJECT_OWNER column contains unconstrained text of up to 255
characters, and specifies the name of the entity that owns the project.

HYDROPOWER_DESCRIPTION
~~~~~~~~~~~~~~~~~~~~~~

The HYDROPOWER_DESCRIPTION column contains unconstrained text of up to
255 characters, and describes the hydropower facilities at the project,
if applicable.

SEDIMENTATION_DESCRIPTION
~~~~~~~~~~~~~~~~~~~~~~~~~

The SEDIMENTATION_DESCRIPTION column contains unconstrained text of up
to 255 characters, and describes the sedimentation characteristics at
the project, if applicable.

DOWNSTREAM_URBAN_DESCRIPTION
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The DOWNSTREAM_URBAN_DESCRIPTION column contains unconstrained text of
up to 255 characters, and describes the urban area downstream of the
project, if applicable.

BANK_FULL_CAPACITY_DESCRIPTION
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The BANK_FULL_CAPACITY_DESCRIPTION column contains unconstrained text of
up to 255 characters, and describes the bank-full capacity of the
project, if applicable.

PUMP_BACK_LOCATION_CODE
~~~~~~~~~~~~~~~~~~~~~~~

The PUMP_BACK_LOCATION_CODE contains the unique numeric code that
identifies in the database the location that water from this project is
pumped back to, if applicable. This value is the same as the
LOCATION_CODE column value in the AT_PHYSICAL_LOCATION table for the
project’s pump-back location.

NEAR_GAGE_LOCATION_CODE
~~~~~~~~~~~~~~~~~~~~~~~

The NEAR_GAGE_LOCATION_CODE contains the unique numeric code that
identifies in the database the gaged location nearest the project. This
value is the same as the LOCATION_CODE column value in the
AT_PHYSICAL_LOCATION table for the gaged location nearest the project.

YIELD_TIME_FRAME_START
~~~~~~~~~~~~~~~~~~~~~~

The YIELD_TIME_FRAME_START column contains the beginning date of the
critical period used in the most recent yield analysis for this project,
if applicable.

YIELD_TIME_FRAME_END
~~~~~~~~~~~~~~~~~~~~

The YIELD_TIME_FRAME_END column contains the ending date of the critical
period used in the most recent yield analysis for this project, if
applicable.

PROJECT_REMARKS
~~~~~~~~~~~~~~~

The PROJECT_REMARKS column contains unconstrained text of up to 1000
characters. It is intended to specify any description or comments about
the project.

OUTLETS
-------

Outlets are locations that represent structures through or over which
water can be release from a project. Outlets are of location kind POINT;
they can usually be sufficiently located by a single latitude and
longitude. If not, a reference location such as the exit point may be
chosen. Outlets are normally sub-locations, with the base location being
the project they belong to. Outlet-specific information is stored in the
AT_OUTLET table.

The AT_OUTLET Table
-------------------

OUTLET_LOCATION_CODE
~~~~~~~~~~~~~~~~~~~~

The OUTLET_LOCATION_CODE column contains the unique numeric code that
identifies the outlet in the database. This value is the same as the
LOCATION_CODE column value in the AT_PHYSICAL_LOCATION table for the
outlet’s location record.

.. _project_location_code-1:

PROJECT_LOCATION_CODE
~~~~~~~~~~~~~~~~~~~~~

The PROJECT_LOCATION_CODE column contains the unique numeric code that
identifies in the database the project that the outlet belongs to. This
value is the same as the PROJECT_LOCATION_CODE column value in the
AT_PROJECT table as well as the LOCATION_CODE value in the
AT_PHYSICAL_LOCATION table of the project the outlet belongs to.

TURBINES
--------

Turbines are locations that represent structures through which water can
be release from a project to generate electricity. Turbines are of
location kind POINT; the turbine is located by single latitude and
longitude. Turbines are normally sub-locations, with the base location
being the project they belong to. Turbine-specific information is stored
in the AT_TURBINE table.

The AT_TURBINE Table
--------------------

TURBINE_LOCATION_CODE
~~~~~~~~~~~~~~~~~~~~~

The TURBINE_LOCATION_CODE column contains the unique numeric code that
identifies the turbine in the database. This value is the same as the
LOCATION_CODE column value in the AT_PHYSICAL_LOCATION table for the
turbine’s location record.

.. _project_location_code-2:

PROJECT_LOCATION_CODE
~~~~~~~~~~~~~~~~~~~~~

The PROJECT_LOCATION_CODE column contains the unique numeric code that
identifies in the database the project that the turbine belongs to. This
value is the same as the PROJECT_LOCATION_CODE column value in the
AT_PROJECT table as well as the LOCATION_CODE value in the
AT_PHYSICAL_LOCATION table of the project the turbine belongs to.

EMBANKMENTS
-----------

Embankments are locations that represent raised structures constructed
to restrict or direct the flow of water. Although embankments are
usually geometrically represented by lines or poly-lines, they are of
location kind POINT. A single reference location, such as the mid-point
of the center line, is chosen for the single latitude and longitude.
Embankments are normally sub-locations, with the base location being the
project they belong to. Embankment-specific information is stored in the
AT_EMBANKMENT table.

The AT_EMBANKMENT Table
-----------------------

EMBANKMENT_LOCATION_CODE
~~~~~~~~~~~~~~~~~~~~~~~~

The EMBANKMENT_LOCATION_CODE contains the unique numeric code that
identifies the embankment in the database. This value is the same as the
LOCATION_CODE column value in the AT_PHYSICAL_LOCATION table for the
embankment’s location record.

EMBANKMENT_PROJECT_LOC_CODE
~~~~~~~~~~~~~~~~~~~~~~~~~~~

The EMBANKMENT_PROJECT_LOC_CODE table contains the unique numeric code
that identifies in the database the project to which the embankment
belongs. This value is the same as the PROJECT_LOCATION_CODE column
value in the AT_PROJECT table as well as the LOCATION_CODE column value
in the AT_PHYSICAL_LOCATION table for the project to which the
embankment belongs.

STRUCTURE_TYPE_CODE
~~~~~~~~~~~~~~~~~~~

The STRUCTURE_TYPE_CODE column contains the unique numeric code that
identifies the embankment’s structure type in the database. This value
is the same as the STRUCTURE_TYPE_CODE column value in the
AT_EMBANK_STRUCTURE_TYPE table for the embankment’s structure type.

STRUCTURE_LENGTH
~~~~~~~~~~~~~~~~

The STRUCTURE_LENGTH column contains the length of the embankment in
meters.

UPSTREAM_PROT_TYPE_CODE
~~~~~~~~~~~~~~~~~~~~~~~

The UPSTREAM_PROT_TYPE_CODE column contains the unique numeric code that
identifies the embankment’s upstream (or wet) side protection type in
the database. This value is the same as the PROTECTION_TYPE_CODE column
value in the AT_EMBANK_PROTECTION_TYPE table for the embankment’s
upstream (or wet) side protection type.

UPSTREAM_SIDESLOPE
~~~~~~~~~~~~~~~~~~

The UPSTREAM_SIDESLOPE column contains the slope of the embankment’s
upstream (or wet) side as a value between 0 and 1.

DOWNSTREAM_PROT_TYPE_CODE
~~~~~~~~~~~~~~~~~~~~~~~~~

The DOWNSTREAM_PROT_TYPE_CODE column contains the unique numeric code
that identifies the embankment’s downstream (or dry) side protection
type in the database. This value is the same as the PROTECTION_TYPE_CODE
column value in the AT_EMBANK_PROTECTION_TYPE table for the embankment’s
downstream (or dry) side protection type.

DOWNSTREAM_SIDESLOPE
~~~~~~~~~~~~~~~~~~~~

The DOWNSTREAM_SIDESLOPE column contains the slope of the embankment’s
downstream (or dry) side as a value between 0 and 1.

HEIGHT_MAX
~~~~~~~~~~

The HEIGHT_MAX column contains the maximum height of the embankment, in
meters.

TOP_WIDTH
~~~~~~~~~

The TOP_WIDTH column contains the width in meters of the top of the
embankment.

LOCKS
-----

Locks are locations that represent raised river locks. Locks are of
location kind POINT. A single reference location, such as a gage
location or the mid-point of the lock, is chosen for the single latitude
and longitude. Locks are normally sub-locations, with the base location
being the project they belong to. Lock-specific information is stored in
the AT_LOCK table.

The AT_LOCK Table
-----------------

LOCK_LOCATION_CODE
~~~~~~~~~~~~~~~~~~

The LOCK_LOCATION_CODE column contains the unique numeric code that
identifies the lock in the database. This value is the same as the
LOCATION_CODE column value in the AT_PHYSICAL_LOCATION table for the
lock’s location record.

.. _project_location_code-3:

PROJECT_LOCATION_CODE
~~~~~~~~~~~~~~~~~~~~~

The PROJECT_LOC_CODE table contains the unique numeric code that
identifies in the database the project to which the lock belongs. This
value is the same as the PROJECT_LOCATION_CODE column value in the
AT_PROJECT table as well as the LOCATION_CODE column value in the
AT_PHYSICAL_LOCATION table for the project to which the lock belongs.

LOCK_WIDTH
~~~~~~~~~~

The LOCK_WIDTH column contains the width of the interior of the lock in
meters.

LOCK_LENGTH
~~~~~~~~~~~

The LOCK_LENGTH column contains the length of the interior of the lock
in meters.

VOLUME_PER_LOCKAGE
~~~~~~~~~~~~~~~~~~

The VOLUME_PER_LOCKAGE column contains the volume of water in cubic
meters that is discharged through the lock for a single lockage at
normal headwater and tailwater elevations.

MINIMUM_DRAFT
~~~~~~~~~~~~~

The MINIMUM_DRAFT column contains the minimum water depth in meters of
this lock.

NORMAL_LOCK_LIFT
~~~~~~~~~~~~~~~~

The NORMAL_LOCK_LIFT column contains the difference between the normal
headwater and tailwater elevations, in meters, of this lock.
