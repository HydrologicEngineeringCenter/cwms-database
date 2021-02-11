Background
==========

This document describes the changes made to the CWMS Database Schema
from the previous production version (3.0.7) to the current version
(18.1.1). Schema version 3.0.7 was implemented as a series of
sub-versions (3.0.7.1 -- 3.0.7.9), with each sub-version being the state
of the schema files in the source code repository. However, the CWMS
Database cannot store the version in this fine of detail, being only
able to store the major, minor, and patch version numbers. Thus all
versions 3.0.7.1 -3.0.7.9 are labeled in the databases simply as 3.0.7.
Because of this situation, this document will describe the changes
between the 3.0.7 sub-versions as well as the changes from version
3.0.7.9 to 18.1.1.

The version numbering scheme has been changed from one loosely aligned
with the current version of the CWMS version, which was found to cause
confusion when discussion CWMS versions and database schema versions, to
a scheme in which:

-   The major version is the last two digits of the year the schema is
    released

-   The minor version is a serial number of releases within the same
    year, beginning at one

-   The patch version is the serial number of patches to the major.minor
    version, beginning at one

No sub-versions are expected to be used for the database schema from
this time forward.

Changes from 3.0.7.1 to 3.0.7.2
-------------------------------

Sub-version 3.0.7.2 was created on 6 Jul 2017.

-   Implement login triggers for RDL/CCP permissions

-   Loading RADAR XSL transforms

Changes from 3.0.7.2 to 3.0.7.3
-------------------------------

Sub-version 3.0.7.3 was created on 13 Jul 2017.

-   Added RETREIVE\_STREAM\_REACH2, removed AT\_STREAM\_REACH\_T01 and
    modified STORE\_STREAM\_REACH to perform checks formerly in trigger.

-   fixing delete\_turbine

Changes from 3.0.7.3 to 3.0.7.4
-------------------------------

Sub-version 3.0.7.4 was created on 21 Jul 2017.

-   Added CAT\_RATINGS2, CAT\_RATINGS2\_F, CAT\_EFF\_RATIINGS2,
    CAT\_EFF\_RATINGS2\_F to include ratings with parent ratings and
    into include info about the parents ratings

-   Add dest\_flag to TSV tables so that it easy to filter data to
    streams to National DB/DMZ

-   Added allowance for \"NAVD 88\" and \"NAVD-88\" instead of just
    \"NAVD88\" in STORE\_VERTICAL\_DATUM\_OFFSET (same for NGVD29).

Changes from 3.0.7.4 to 3.0.7.5
-------------------------------

Sub-version 3.0.7.5 was created on 29 Aug 2017.

-   Bugfixes for reverse rating through USGS-style stream ratings

-   Added rounding of shift on revesrse\_rate to produce same results as
    java code

-   Bug fixes for location level indicators

-   Modified AV\_LOC2 to improve performance. Added db\_office\_code to
    the end of the columns

-   Added capability to retrieve ratings XML without rating or extension
    points.

-   Added tables/view/routines for registering & unregistering named
    subscribers for queues.

-   Modified delete\_ratings, removed trigger at\_rating\_value\_trig

-   Modified to allow \$*n* in addition to I*n* and ARG*n* in formula
    specification.

Changes from 3.0.7.5 to 3.0.7.6
-------------------------------

Sub-version 3.0.7.6 was created on 12 Oct 2017.

-   Fixed missing time zone bug in streamflow\_meas\_t constructor from
    xml, also use location time zone if no time zone ID in date/time
    string

-   Fixes for ratings with extensions

-   Made log\_db\_message() an autonomous transaction

-   Modification to accommodate longer UPASS phone number

-   Modified so that a table rating with no values creates a dummy table
    of 0,0 instead of raising an exception.

-   Bugfix in RETRIEVE\_RATINGS for retrieving ratings with identical
    aliases.

-   Fixed: numbers weren\'t recognized as valid tokens in source rating
    expressions

-   Fixed: typo could poplulate transitional rating with source ratings
    in wrong order in constructor from xml

-   Cleaned up cursor leaks.

-   Added ability to filter out duplicate time/value/quality items when
    storing data. Also changed code for filtering NULLs from cursor
    loops to SQL statements.

-   Modified DELETE INSERT code to work consistently and filter
    duplicates if specified. Changed all GMT time zone references to UTC

Changes from 3.0.7.6 to 3.0.7.8
-------------------------------

Sub-version 3.0.7.8 was created on 24 Jun 2018. Sub-version 3.0.7.7 was
skipped.

-   Fixed bug in deleting ratings with extension values.

-   Fixed bug that prevented inactive shifts from being returned in
    usgs-rating-rating objects.

-   Fixed bugs in database ratings that prevented falling back from log
    to linear interpolation. Expected LOG(10, X) to raise an exception
    on X \<= 0. It doesn\'t.

-   Modified ctor from xml to raise an exception if a shift effective
    date is earlier than the rating effective date

-   Fixed bug in RETRIEVE\_RATING\_OBJ\_EX that would leave rows of the
    returned table NULL if the catalog returned a specific rating code
    in more than one row.

-   Added STORE\_CONTRACTS2() that allows specifying whether to ignore
    NULL values in the input data.

Changes from 3.0.7.9 to 3.0.7.9
-------------------------------

Sub-version 3.0.7.9 was created on 21 May 2018.

-   Allow \"Count\" to be used as a proxy for gate opening if no other
    suitable parameter exists.

Changes from 3.0.7.9 to 18.1.1
------------------------------

-   Changes for Access2Water

-   Added \'GENERAL\' configuration category, moved \<NULL\>/\'OTHER\'
    configuration to \'GENERAL/OTHER\'

-   Added AT\_TS\_EXTENTS table and modified time series extents
    routines.

-   Added historic time series flag

-   Added location level labels

-   Added location level sources

-   Added scheduler monitoring and job authorization

-   Added views for time series text

-   Adding CWMS Pools

-   Adding keyed log messages

-   Revoke public grants to restricted packages and grant them directly
    to CWMS user for STIG compliance

-   Changes to CWMS\_FORECAST

-   Changes to DELETE\_LOCATION\_LEVELxx

-   Database logging changes

-   Lengthend PUBLIC\_NAME from 32 to 57 bytes.

-   Lengthened BASE\_LOCATION\_ID from 16 to 24

-   Modified CWMS\_LOC.SET\_VERTICAL\_DATUM\_INFO to delete all current
    info before storing incoming infor.

-   Modified GET\_LOCATION\_ID to be able to retrieve location ID by
    public name (if unique in office)

-   Modified SEND\_MAIL to use CWMSDB property \"email.mail-exchanger\",
    but default to \"gw2.usace.army.mil\" for email server

-   Modified STORE\_GATE\_CHAGNES, RETRIEVE\_GATE\_CHANGES/\_F,
    STORE\_TURBINE\_CHANGES, and RETRIEVE\_TURBINE\_CHANGES/\_F to
    recognized the default vertical datum, if set, and to allow unit
    spec format of U=\<unit\>\|V=\<datum\>. Unit specs for retrieve
    routines are in P\_UNIT\_SYSTEM instead of units (e.g.,
    U=EN\|V=NAVD88) and are in individual change times (much easier to
    use default vertical datum) for store routines.

-   Moved common REGI \"lookup table\" data to CWMS-owned records

-   Rewrote RETRIEVE\_TURBINE\_CHANGES to improve performance

-   Added index on dep\_rating\_ind\_param\_code column for
    at\_rating\_value to prevent database lock up when deleting/updating
    ratings.

-   updates for virtual ratings
