====================================
CWMS Location and Time Series Groups
====================================

Contents
========

`Overview <#overview>`__\ `1 <#overview>`__

`Organization <#organization>`__\ `1 <#organization>`__

`Structure <#structure>`__\ `1 <#structure>`__

`Category
Structure <#category-structure>`__\ `1 <#category-structure>`__

`Group Structure <#group-structure>`__\ `1 <#group-structure>`__

`Group Membership
Structure <#group-membership-structure>`__\ `2 <#group-membership-structure>`__

`Using Aliases <#using-aliases>`__\ `2 <#using-aliases>`__

`Uniqueness <#uniqueness>`__\ `3 <#uniqueness>`__

`Partially-Aliased
Identifiers <#partially-aliased-identifiers>`__\ `3 <#partially-aliased-identifiers>`__

`Naming Standards <#naming-standards>`__\ `4 <#naming-standards>`__

`Views <#views>`__\ `4 <#views>`__

Overview
========

The CWMS database supports collecting locations and time series items
into groups of related items. The nature of the relation for any group
is defined by the user. The database structure imposes no semantic
requirements on the groups and provides a variety of fields to support
various uses. Location groups and time series groups are nearly
identical in their structure and usage and are treated together in this
document, with the few differences specified in the appropriate
sections.

Organization
============

Grouping uses a two tier hierarchy. The top tier is the *category* and
the bottom tier is the *group*. Each category can contain many groups,
while each group belongs to only one category. Each group may contain
many locations or time series, and locations and time series may be
assigned to many groups.

Each category and each group is owned by a single office in the CWMS
database. Each office can use the CWMS database API to manage their
categories and groups programmatically or use the CWMS Management
Application (CMA) to do so interactively. Groups can belong *only* to
categories owned by the same office that owns the group or by the CWMS
pseudo-office. Locations and time series can be assigned *only* to
groups owned by the same office that owns the location or time series or
by the CWMS pseudo-office. No category or group owned by the CWMS
pseudo-office may be deleted or renamed by any office either
programmatically or via CMA.

Structure
=========

Category Structure
------------------

Categories contain only enough information to identify and describe
them, and to relate them to offices and groups. This information is
contained in the tables AT_LOC_CATEGORY and AT_TS_CATEGORY.

-  **Office Code:** a numeric value that relates the category to the
   owning office.

-  **Category Code:** a numeric value that relates the category to the
   groups it contains.

-  **Category ID:** a string of up to 32 characters that identifies the
   category. This identifier is case-retained; it may be located using
   any character case, but the original character case id retained.

-  **Category Description:** a string of up to 256 characters that
   describes the category.

Group Structure
---------------

Groups contain information similar to categories plus some additional
items. This information is contained in the tables AT_LOC_GROUP and
AT_TS_GROUP.

-  **Office Code:** a numeric value that relates the group to the owning
   office.

-  **Category Code** a numeric value that relates the group to the
   category that contains it.

-  **Group Code:** a numeric value that relates the group to the
   locations or time series it contains.

-  **Group ID:** a string of up to 65 characters that identifies the
   group. This identifier is case-retained; it may be located using any
   character case, but the original character case id retained.

-  **Group Description:** a string of up to 256 characters that
   describes the group.

-  **Shared Alias ID:** an optional text string of up to 256 characters
   that can be used as a many-to-one alias for the contained locations
   or time series.

-  **Shared Reference Code:** an optional numeric value that can be used
   to relate all contained locations or time series to a single location
   or time series. Location groups may reference only locations and time
   series groups may reference only time series.

Group Membership Structure
--------------------------

Group membership contains information to relate a location or time
series to a group as well as information that may be used to
differentiate the members within the group or apply to the location or
time series as a result of group membership. This information is
contained in the tables AT_LOC_GROUP_ASSIGNMENT and
AT_TS_GROUP_ASSIGNMENT.

-  **Location or Time Series Code:** a numeric value that relates the
   membership to the location or time series.

-  **Office Code:** a numeric value that relates the location or time
   series to its owning office. Although this information is implicit in
   the location or time series code, it is also explicitly specified to
   facilitate indexed lookups of locations or time series by office and
   alias ID.

-  **Group Code:** a numeric value that relates the membership to the
   group.

-  **Attribute:** an optional numeric value that may be used to
   differentiate the members of the group by some user-defined measure.
   A common use is to provide membership order for groups in which order
   is meaningful.

-  **Alias ID:** an optional string of up to 256 characters that is used
   as a one-to-one alias for the location or time series as a result of
   membership in the group.

-  **Reference Code:** an optional numeric value that may be used to
   relate the location or time series to another location or time series
   as a result of membership in the group. Location group memberships
   may reference only locations and time series group memberships may
   reference only time series.

Using Aliases
=============

One of the more common uses of groups within the CWMS database is to
provide aliases for locations or time series. The CWMS database provides
a CWMS-owned location category named “Agency Aliases” which contains the
following CWMS-owned groups, all expressly for the purpose of providing
location aliases:

-  CBT Station ID

-  DCP Platform ID

-  NRCS Station ID

-  NWS Handbook 5 ID

-  SHEF Location ID

-  TVA Station ID

-  USBR Station ID

-  USGS Station Name

-  USGS Station Number

Uniqueness
----------

Aliases must be unique within groups. That is, no location or time
series group may contain different locations or time series with the
same alias.

The same location alias may be used in multiple location groups *only*
if the same location is aliased in each instance. Attempting to use an
existing location alias for a location other than the one it is already
used for will cause the database to raise an exception and abort the
operation. The exception text is:

ERROR: Alias (<alias_id>) would reference multiple locations. If you
want to allow this, set the CWMSDB/Allow_multiple_locations_for_alias
property to 'T' for office id <office_id>. Note that this action will
eliminate the ability to look up a location using the alias or any
others that reference multiple locations.

Note that the text specifies that an office may relax the requirement
that an alias identifier resolve to a single location for its office. If
the need arises to have multiple locations share a single alias,
consider creating a location group for that purpose and using the shared
alias identifier before relaxing the requirement.

While time series aliases must be unique within time series groups, the
database does not currently enforce a globally unique time series alias
to time series relationship as it does for locations.

Partially-Aliased Identifiers
-----------------------------

Since compound identifiers in the CWMS database normally contain
location identifiers as one of their components, location aliases can
allow the compound identifiers for the aliased location to be identified
by text comprised of the normal compound id with the location portion
replaced with the location alias.

For example, suppose there is a location named “KeystoneDam” with
aliases “KEYO2”, “07164200 “, and “CE609B50”; and a time series named
“KeystoneDam.Elev.Inst.1Hour.0.Goes-rev”. Because of the location
aliases, all of the following may be used to access the same time
series:

-  KeystoneDam.Elev.Inst.1Hour.0.Goes-rev

-  KEYO2.Elev.Inst.1Hour.0.Goes-rev

-  07164200.Elev.Inst.1Hour.0.Goes-rev

-  CE609B50.Elev.Inst.1Hour.0.Goes-rev

Further suppose that “KeystoneDam” has a sub-location named
“SluiceGate1” with an associated time series name
“KeystoneDam-SluiceGate1.Opening.Inst.0.0.Manual-rev”. Although only the
base location portion of the time series identifier is aliased, all of
the following may be used to access the same time series:

-  KeystoneDam-SluiceGate1.Opening.Inst.0.0.Manual-rev

-  KEYO2-SluiceGate1.Opening.Inst.0.0.Manual-rev

-  07164200-SluiceGate1.Opening.Inst.0.0.Manual-rev

-  CE609B50-SluiceGate1.Opening.Inst.0.0.Manual-rev

Note that these are not time series aliases in the sense that they are
aliases specified in a time series group, but are a by-product of the
fact that the time series identifier includes a location identifier that
is aliased.

Naming Standards
----------------

Locations and time series both have requirements on the text format of
their respective identifiers. Location and time series aliases are not
required to conform to those same formats, but may contain any text up
to 256 characters in length. Be aware that while this capability may be
desirable in some contexts, using aliases that do not conform to the
format requirements of the aliased identifiers may cause the aliases to
be unavailable or otherwise unusable in software that expects the
required formats.

Views
-----

Some views in the CWMS database have been modified to include location
and/or time series aliases, while other views have been added for this
purpose. Views that contain aliases will have multiple rows that contain
the same location code or time series code, which is a departure from
views that don’t contain aliases. The modified or new views have the
following columns to help identify aliases.

+-----------+-----------+---------------------------------------------+
| **Column  | *         | **Comments**                                |
| Name**    | *Values** |                                             |
+===========+===========+=============================================+
| ALI       | BASE      | Identifier is partially aliased; the base   |
| ASED_ITEM | LOCATION  | location is aliased.                        |
+-----------+-----------+---------------------------------------------+
|           | LOCATION  | If identifier is a location, it is aliased. |
+-----------+-----------+---------------------------------------------+
|           |           | If identifier is compound, it is partially  |
|           |           | aliased; the location portion is aliased.   |
+-----------+-----------+---------------------------------------------+
|           | TIME      | Time series identifier is aliased.          |
|           | SERIES\   |                                             |
|           | :sup:`\*` |                                             |
+-----------+-----------+---------------------------------------------+
| LOC_ALIAS | <Loc      | Null if location or base location is not    |
| _CATEGORY | Category  | aliased.                                    |
|           | ID>       |                                             |
+-----------+-----------+---------------------------------------------+
| LOC_AL    | <Loc      | Null if location or base location is not    |
| IAS_GROUP | Group ID> | aliased.                                    |
+-----------+-----------+---------------------------------------------+
| T         | <TS       | Null if time series is not aliased.         |
| S_ALIAS_C | Category  |                                             |
| ATEGORY\  | ID>       |                                             |
| :sup:`\*` |           |                                             |
+-----------+-----------+---------------------------------------------+
| TS_ALIA   | <TS Group | Null if time series is not aliased.         |
| S_GROUP\  | ID>       |                                             |
| :sup:`\*` |           |                                             |
+-----------+-----------+---------------------------------------------+

:sup:`\*`\ Applicable only in views that contain time series
identifiers.

The views that contain aliases are:

+----------------------------+----------+------------------------------+
| **View Name**              | **       | **Column Containing Alias**  |
|                            | Status** |                              |
+============================+==========+==============================+
| CWMS_V_CWMS_TS_ID2         | New      | CWMS_TS_ID                   |
+----------------------------+----------+------------------------------+
| CWMS_V_LOC2                | New      | LOCATION_ID                  |
+----------------------------+----------+------------------------------+
| CWMS_V_RATING              | Updated  | RATING_ID                    |
+----------------------------+----------+------------------------------+
| CWMS_V_RATING_LOCAL        | Updated  | RATING_ID                    |
+----------------------------+----------+------------------------------+
| CWMS_V_RATING_SPEC         | Updated  | RATING_ID                    |
+----------------------------+----------+------------------------------+
| CWMS_V_TSV_DQU             | Updated  | CWMS_TS_ID                   |
+----------------------------+----------+------------------------------+

In these views, use the ALIASED_ITEM column to interpret the contents of
the column containing the alias. Note that other columns will not be
modified, so from the example above with a sub-location and an aliased
base location, the CWMS_V_LOC2 view would contain the following:

+----------------+---------------+---------------------+--------------+
| **BASE         | **SUB_        | **LOCATION_ID**     | **AL         |
| _LOCATION_ID** | LOCATION_ID** |                     | IASED_ITEM** |
+================+===============+=====================+==============+
| KeystoneDam    | SluiceGate1   | Keys                |              |
|                |               | toneDam-SluiceGate1 |              |
+----------------+---------------+---------------------+--------------+
| KeystoneDam    | SluiceGate1   | KEYO2-SluiceGate1   | BASE         |
|                |               |                     | LOCATION     |
+----------------+---------------+---------------------+--------------+
| KeystoneDam    | SluiceGate1   | 0                   | BASE         |
|                |               | 7164200-SluiceGate1 | LOCATION     |
+----------------+---------------+---------------------+--------------+
| KeystoneDam    | SluiceGate1   | C                   | BASE         |
|                |               | E609B50-SluiceGate1 | LOCATION     |
+----------------+---------------+---------------------+--------------+

To use the new or updated views to retrieve only non-aliased
identifiers, add the text “AND ALIAISED_ITEM IS NULL” to the WHERE
clause in your query. If the query doesn’t have a WHERE clause, add the
text “WHERE ALIASED_ITEM IS NULL” to create one.
