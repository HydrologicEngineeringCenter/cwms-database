====================
CWMS LOCATION LEVELS
====================

1. **Overview.** CWMS location levels are named objects that store
   numeric values related to specific locations and parameters. Unlike
   CWMS Time Series, which can also be described as above, *normal*
   location levels can be constant in time, vary in time in a repeating
   pattern, or vary irregularly in time by being associated with an
   actual time series. In addition, *virtual* location levels can be
   defined as transformations (ratings or formulas) applied to inputs
   (location levels or time series). All location levels have defined
   beginning date/time values (effective dates) and may or may not have
   ending date/time values (expiration dates). Levels of the same
   *category* (normal or virtual) may have the same name (*identifier*)
   but different effective dates. In this case, each level is in effect
   from its effective date until its expiration date (if any) or the
   subsequent level’s effective date, whichever is earlier (the level’s
   *effective timespan*). Levels of different categories may have the
   same identifier and overlapping effective timespans. The API routines
   to retrieve location level values for a specified time window can
   specify of the precedence of categories to retrieve the values for,
   with the default value being to retrieve virtual location level
   values if they exist and fall back to retrieving normal location
   level values otherwise. In this way, one category of location level
   can override a location level with the same identifier but different
   category. Each CWMS location level may have an attribute defined by a
   name (identifier) and a constant value. Location levels with the same
   level identifier, same attribute identifier, but different attribute
   values can be used to define guide/rule curves. CWMS location levels
   can also have associated indicator names, each of which can have up
   to five indicators, each of which is set (on/true) or unset
   (off/false) based on a specified logical expression (*condition*) of
   a specified time series and the location level value. This document
   describes CWMS location levels.

2. **Location level Categories**. All CWMS location levels are in one of
   the following categories. Each category will be discussed in more
   detail below.

   a. **Normal**. Normal location levels are defined with actual values
      or references to time series with actual values.

   b. **Virtual**. Virtual location levels are defined as
      transformations on actual values or time series.

..

   Location levels in the same category with the same location level
   *key* (See section 6 below) but different effective dates supersede
   one another. Location levels in different categories with the same
   location level key may override one another, depending on the
   precedence specified in the routine to retrieve location level
   values.

3. **Specified Levels.** Each CWMS location level identifier includes an
   item called the specified level. A specified level is simply a
   name/identifier and is itself not associated with any location or
   parameter. The CWMS database pre-defines several specified levels,
   and each office can define its own if it has need to do so (256
   characters maximum).

..

   The pre-defined specified levels are:

.. table:: Table : Example Connection Strings

   +-------------------------------+--------------------------------------+
   | **Specified Level**           | **Description**                      |
   +===============================+======================================+
   | Bottom of Exclusive Flood     | Bottom of Exclusive Flood Control    |
   | Control                       | Level                                |
   +-------------------------------+--------------------------------------+
   | Bottom of Flood Control       | Bottom of Flood Control Level        |
   +-------------------------------+--------------------------------------+
   | Bottom of Inlet               | Bottom of Inlet Level                |
   +-------------------------------+--------------------------------------+
   | Bottom of Multi-Purpose       | Bottom of Multi-Purpose Level        |
   +-------------------------------+--------------------------------------+
   | Bottom of Normal              | Bottom of Normal Level               |
   +-------------------------------+--------------------------------------+
   | Bottom of Operating           | Bottom of Operating Level            |
   +-------------------------------+--------------------------------------+
   | Bottom of Power               | Bottom of Power Level                |
   +-------------------------------+--------------------------------------+
   | Design Capacity               | Design Capacity Level                |
   +-------------------------------+--------------------------------------+
   | Flood                         | Flood Level                          |
   +-------------------------------+--------------------------------------+
   | Max Non-Damaging              | Maximum Without Causing Damage Level |
   +-------------------------------+--------------------------------------+
   | Regulating                    | Regulating Level                     |
   +-------------------------------+--------------------------------------+
   | Streambed                     | Streambed Level                      |
   +-------------------------------+--------------------------------------+
   | Top of Conservation           | Top Conservation Level               |
   +-------------------------------+--------------------------------------+
   | Top of Dam                    | Top of Dam Level                     |
   +-------------------------------+--------------------------------------+
   | Top of Downstream             | Top of Downstream Level              |
   +-------------------------------+--------------------------------------+
   | Top of Exclusive Flood        | Top of Exclusive Flood Control Level |
   | Control                       |                                      |
   +-------------------------------+--------------------------------------+
   | Top of Flood                  | Top of Flood Level                   |
   +-------------------------------+--------------------------------------+
   | Top of Inactive               | Top of Inactive Level                |
   +-------------------------------+--------------------------------------+
   | Top of Induced Surcharge      | Top of Induced Surcharge Level       |
   +-------------------------------+--------------------------------------+
   | Top of Inlet                  | Top of Inlet Level                   |
   +-------------------------------+--------------------------------------+
   | Top of Multi-Purpose          | Top of Multi-Purpose Level           |
   +-------------------------------+--------------------------------------+
   | Top of Normal                 | Top of Normal Level                  |
   +-------------------------------+--------------------------------------+
   | Top of Operating              | Top of Operational Level             |
   +-------------------------------+--------------------------------------+
   | Top of Outlet                 | Top of Outlet Level                  |
   +-------------------------------+--------------------------------------+
   | Top of Overflow               | Top of Overflow Level                |
   +-------------------------------+--------------------------------------+
   | Top of Power                  | Top of Power Level                   |
   +-------------------------------+--------------------------------------+

4. **Location Level Identifiers.** Location levels apply specified
   levels to specific combinations of location, parameter, parameter
   type, and duration, with an optional attribute (see Section 5 below).
   CWMS location level identifiers join these various parts – minus the
   attribute – together using the dot character (‘.’) as a separator
   after the fashion of the CWMS time series identifiers, as shown:

..

   +-------------------------- Location

   \| +--------------------- Parameter

   \| \| +---------------- Parameter Type

   \| \| \| +----------- Duration

   \| \| \| \| +--------- Specified Level

   \| \| \| \| \|

   \| \| \| \| \|

   ---- ---- ---- - -------------------

   KEYS.Elev.Inst.0.Top of Conservation

   KEYS.Stor.Inst.0.Top of Conservation

5. **Location Level Attributes**. Attributes provide means of building
   guide/rule curves from CWMS location levels. Attributes are defined
   by an identifier and a value. The attribute identifier comprises a
   parameter, parameter type and duration, joined together using the dot
   (‘.’) character. The attribute identifier describes the attribute
   value. An example location level identifier with an associated
   attribute identifier is shown below. In this example, the guide curve
   is used to determine the maximum flow allowed at a location based on
   the percent of basin storage used and season of year. The guide curve
   is made from four seasonal (regularly varying) normal location levels
   with attributes of 20,000, 40,000, 60,000, and 150,000 cfs.

..

   +-------------------------------------- Location

   \| +--------------------------------- Parameter

   \| \| +----------------- Parameter Type

   \| \| \| +------------- Duration

   \| \| \| \| +------ Specified Level

   \| \| \| \| \|

   \| \| \| \| \|

   ---- --------------- --- ------ -----------

   VANB.%-of Basin Full.Ave.6Hours.Guide Curve

   +-------------- Attribute Parameter

   \| +--------- Attribute Parameter Type

   \| \| +----- Attribute Duration

   \| \| \|

   \| \| \|

   ---- --- ------

   Flow.Max.6Hours

   .. image:: ./levels/media/image1.png
      :width: 6.2298in
      :height: 4.51327in

6. **Location Level Keys**. For the purposes of the remainder of this
   document, a location level key comprises:

   a. **Location Level Identifier**. Required.

   b. **Attribute**. Optional, both or neither of the identifier and
      value must be null.

      -  **Attribute Identifier.**

      -  **Attribute Value.** In the API routines, the attribute value
            is specified by a numeric value and a unit.

7. **Common Metadata**.

   a. **Level-Specific Metadata.** The following items are defined for
      each level when storing location levels. They are not shared by
      different location levels that have the same location level key.

      -  **Effective Date**. Each location level is required to have an
            effective date. The value of the location level is as
            defined on or after this date/time. The value of the
            location level is undefined before this date/time. The
            effective date provides the ability to have a sequence of
            location level definitions for the same category and key.

      -  **Expiration Date**. Each location level may have an expiration
            date. The value of the location level is as defined before
            this date/time and undefined on or after. If present, the
            expiration date must be later than the effective date. Since
            this item belongs to an individual level, having another
            level with the same category and identifier and an effective
            date earlier than this level’s expiration date will make the
            expiration date meaningless as the location level value
            would be for any time on/after the expiration date would be
            provided by the subsequent level.

      -  **Level Comment**. Each location level may have a comment of up
            to 256 characters describing the level.

      -  **Attribute Comment**. location levels with attributes may have
            a comment of up to 256 characters describing the attribute.

   b. **Key-Associated Metadata.** The following optional items are
      associated with location levels by location level key. They apply
      to levels of any category or effective date with the associated
      key.

      -  **Sources**. Each location level may be associated with a
            source entity that is responsible for the definition of the
            level. The CWMS database pre-defines 141 entities which
            include USACE offices, NWS offices, EPA, FEMA, NOAA, NRCS,
            USBR, USGS, US states, power marketing administrations (APA,
            BPA, SEPA, SWPA, TVA, & WAPA), as well as one for
            unknown/unspecified. In addition, offices can add other
            entities if necessary.

      -  **Indicators**. Each location level may be associated with one
            or more sets of indicators, each set of which may be used to
            indicate the status of a time series with respect to the
            location level. location level indicators are described in
            detail below.

8. **Normal Location Levels**. Each normal location level is a constant
   level, a regularly varying level, or an irregularly varying level.

   a. **Constant Levels**. A constant location level specifies a single
      value that is constant for the effective timespan of the location
      level.

   b. **Regularly Varying Levels**. Also called seasonal or periodic
      levels, each regularly varying location level specifies a
      repeating pattern of values by defining the following.

   -  **Interval**. Either calendar-based or time-based timespan that
         defines the pattern repetition period. A calendar-based
         interval is one specified in terms of years and/or months; a
         time-based interval is one specified in terms of days and/or
         smaller units. The typical interval is one year, as many USACE
         reservoirs have operating plans that repeat on a yearly cycle,
         but any interval can be used to suit the purpose of the
         location level.

   -  **Interval Origin**. The interval origin specifies a starting
         date/time of any interval. For instance, a calendar year
         interval and a water year interval would both be specified as
         1-year intervals, but the calendar year interval would have an
         interval origin of 00:00:00 on January 1st of some year, while
         the water year interval would have an interval origin of
         00:00:00 on October 1st of some year.

   -  **Seasonal Values**. The location level values at two or more
         offsets into the interval. Each seasonal value includes:

      -  **Offset Months**. The calendar-based component of the offset.

      -  **Offset Minutes**. The time-based component of the offset.

      -  **Value**. The location level value at the offset into the
         interval.

..

   The start of the current interval for a date/time is computed by
   adding or subtracting the interval to/from the interval origin until
   the latest interval start on or before the date/time is found.

   The offset date/time is computed by adding the offset months to the
   start of the current interval and then adding the offset minutes to
   that.

   For example, to find the date/time for an offset of 1 month and
   20,880‬ minutes for a 1-year interval with an interval origin of
   2000-01-01 00:00 and the date/time of 2022-03-01 07:00, the interval
   origin is incremented by the interval 22 times, yielding 2022-01-01
   00:00, which is then incremented by 1 month, yielding 2022-02-01
   00:00 and then 20,880‬ minutes, resulting in 2022-02-15 12:00.

   A common mistake is to set the offset months to the month-of-year of
   the offset date/time and to set the offset minutes based on the
   day-of-month of the offset date/time. Making this mistake with the
   above example (offset date/time = 2022-02-15 12:00) would have caused
   the offset months to be set to 2 and the offset minutes to be set to
   22,320 (15 \* 24 \* 60 + 12 \* 60). Since both the month-of-year and
   day-of-month begin with 1, using these values would have resulted in
   the offset date/time being 2022-03-16 12:00.

-  **Interpolate Flag**. This determines what value is returned as the
      location level value for a specified time that is between two
      offset date/times in the seasonal values.

   -  **True**. The value returned is interpolated between the value at
      the previous offset date/time and the value at the next offset
      date/time.

   -  **False**. The value at the previous offset date/time it returned.

..

   Note that the seasonal values do not necessarily need to include
   values at the beginning and end of the interval. Any value returned
   for a date/time between the beginning of the interval and the first
   offset date/time will be determined using the value at the last
   offset date/time of the previous interval and the value at the first
   offset date/time of the current interval, as determined by the
   interpolate flag. Likewise, the value at a date/time after the last
   offset date/time and before the end of the interval will be
   determined using the value at the last offset date/time of the
   current interval and the value at the first offset date/time of the
   next interval.

c. **Irregularly Varying Levels**. Each irregularly varying location
   level specifies the following.

-  **Time Series Identifier**. The identifier of a CWMS time series
      existing in the CWMS database that provides the values for this
      location level.

-  **Interpolate Flag**. This determines what value is returned as the
      location level value for a specified time that is between two
      times in the underlying time series.

   -  **True**. The value returned is interpolated between the value of
      the previous time and the value of the next time in the time
      series.

   -  **False**. The value of the previous time in the time series it
      returned.

..

   Note that unlike constant and regularly varying levels – which are
   always defined during the effective timespan – irregularly varying
   levels may be undefined for a portion (up to and including all) of
   the effective timespan because the associated time series may not
   have values for all that period.

9. **Virtual Location Levels.** Each virtual location level includes the
   following.

   a. **Constituents**. Each virtual location level is computed from a
      set of *constituents*, each of which is either an *input* or a
      *transform*. Input constituents may be either other location
      levels or time series. Transform constituents are ratings or
      formulas. Each virtual location level requires at least one input
      constituent and one transform constituent, but complex virtual
      location levels may have more than one of each.

..

   Each constituent as a type and name:

.. table:: Table : Mathematical Expression Components

   +------------------+-------------+-------------------------------------+
   | **Type**         | **Name**    | **Example**                         |
   +==================+=============+=====================================+
   | LOCATION_LEVEL   | Location    | Freemont.Elev.Inst.0.Top of Flood   |
   |                  | Level       |                                     |
   |                  | Identifier  |                                     |
   +------------------+-------------+-------------------------------------+
   | TIME_SERIES      | Time Series | Freemont.Elev.Inst.0.0.rev-ccp      |
   |                  | Identifier  |                                     |
   +------------------+-------------+-------------------------------------+
   | RATING           | Rating      | Free                                |
   |                  | Sp          | mont.Elev;Stor.Linear.Standard.Step |
   |                  | ecification |                                     |
   +------------------+-------------+-------------------------------------+
   | FORMULA          | M           | (ARG1 + ARG2) / 2                   |
   |                  | athematical | {ac-ft,ac-ft;ac-ft}                 |
   |                  | Expression  |                                     |
   |                  | with        |                                     |
   |                  | Units       |                                     |
   |                  | \ :sup:`\*` |                                     |
   +------------------+-------------+-------------------------------------+

..

   :sup:`\*`\ A mathematical expression (see Table 2: Mathematical
   Expression Components) followed by a units string. The units string
   is a comma-separated string of units for each argument followed by a
   semicolon and the unit of the result of the expression, all enclosed
   in curly braces (e.g.,
   {*arg1_unit*,a\ *rg2_unit*\ …;r\ *esult_unit*}).

   In addition, each constituent has an abbreviation which is used in
   the connection string. The rules for constituent abbreviations are:

-  Must be 2-4 characters in length

-  The first character must be the same as the first character of the
   constituent’s type (i.e., ‘L’, ‘T’, ‘R,’ or ‘F’)

..

   Normally, constituent abbreviations are simply the required first
   character appended with the order of the constituent’s type within
   the set of constituents (e.g., L1 for the first LOCATION_LEVEL
   constituent, R2 for the second rating constituent, etc.) but this is
   not required.

a. **Connection String.** Each constituent has one or more connection
   points which connect it to one or more of the other constituents.
   Input constituents have only one connection point, which is named the
   same as the constituent’s abbreviation. Transform constituents have a
   minimum of two connection points: they have one or more independent
   (normally input) connection points and one dependent (normally
   output). These connection points are named by appending I1, I2,
   etc... to the constituent abbreviation for independent connection
   points and appending D to the abbreviation for dependent connection
   points (e.g., R1I1, F2I1, R2D, etc...). Only when the transform
   constituent is a reversible rating (monotonic single independent
   parameter rating) can the dependent connection point be an input and
   the independent connection point be an output.

..

   The connection string specifies one or more sets of connected
   connection points by placing them on either side of an equals sign
   character (‘=’). If more than one connection is required, the sets of
   connected connection points are separated by the comma character
   (‘,’). The connections string must connect every input connection
   point to the independent connection point of one or more transforms
   and must leave exactly one transform dependent connection point
   unconnected. Complex virtual location levels may connect input
   connection points or transform dependent connection points to more
   than one transform independent connection points. Some example
   connection strings are shown in Table 1: Example Connection Strings.

10. **Location Level Indicators.** Location level indicators are devices
    that indicate the status of time series values with respect to
    location levels. Each indicator can define up to five conditions
    against which to compare time series values. Each condition has a
    value in the range of [1..5] and a Boolean test. If the comparison
    for any condition yields a value of TRUE, the condition is
    considered to be set for the time series value. Condition tests need
    not be mutually exclusive, so a single time series value may set
    multiple conditions of an indicator. Regardless of mutual
    exclusivity, higher valued conditions are normally considered to be
    of greater importance or severity than lower valued conditions, so
    the API provides a routine to retrieve the maximum indicator values
    set.

..

   Condition tests have an *evaluation time* and a *tested value time*.

-  The evaluation time is the specified time for the condition to be
   evaluated.

-  The tested value time may be earlier than the evaluation time. Only
   time series values that are not marked as missing or rejected are
   used in the tests, so the tested value time will be the time of the
   latest time series value not marked as missing or rejected that is on
   or before the evaluation time.

..

   Location level indicators are identified by extending a location
   level key with an indicator name. A full location level indicator
   identifier is shown:

   +------------------------------------- Location

   \| +-------------------------------- Parameter

   \| \| +--------------------------- Parameter Type

   \| \| \| +---------------------- Duration

   \| \| \| \| +-------------------- Specified Level

   \| \| \| \| \| +------- Indicator

   \| \| \| \| \| \|

   \| \| \| \| \| \|

   ---- ---- ---- - ------------ ------------

   KEYS.Stor.Inst.0.Top of Flood.PERCENT FULL

   In this document, *indicator identifier* means the entire location
   level identifier as shown above, and *indicator name* means the last
   portion of the location level identifier (PERCENT FULL in the above
   example).

   Each location level indicator has the following:

a. **Indicator Name (Required)**. Maximum length of 32 characters. Upper
   case.

b. **Location level key (Required)**. As noted above, location level
   indicators are key-associated with location levels. This allows an
   indicator to apply to a succession of location levels with the same
   key instead of being tied to any specific level within the
   succession.

c. **Reference location level key (Optional)**. Location level
   indicators may reference a second location level, provided that the
   referenced level shares the same location, parameter, parameter type
   and duration with the associated location level. Only the specified
   level and/or attribute value may differ between the associated level
   and the reference level. This allows conditions to test the fraction
   a time series value represents within the difference of two levels.
   For example, a condition for an indicator associated with the
   location level KEYS.Stor.Inst.0.Top of Flood could reference the
   level KEYS.Stor.Inst.0. Bottom of Flood to use a time series of
   storages to determine what zone within the flood control pool they
   represent.

d. **Minimum Duration (Optional)**. If unset or zero, only the tested
   value time is used. If set to greater than zero, the comparison is
   evaluated at the tested value time and all previous times within the
   Minimum Duration. The condition is set only if the evaluation at the
   tested value time yields TRUE and none of the comparisons at previous
   times yield FALSE. For example, if the minimum duration is set to 6
   Hours while testing a 1-Hour interval time series, any comparisons
   that yield FALSE at the tested value time or previous five interval
   times causes the condition to be unset

e. **Maximum Age (Optional)**. If unset or zero, there is no constraint
   on how far the tested value time precedes the evaluation time.
   Otherwise, if the tested value time is earlier that the evaluation
   time minus the maximum age, no comparisons are performed and no
   conditions are set for the indicator.

f. **Conditions (Optional)**. Although an indicator with no conditions
   is not useful, the only constraints on conditions are that there can
   be no more than five, their values must be in the range [1..5], and
   only one condition per value is allowed.

..

   Each condition evaluates a mathematical expression of the time series
   value V, associated location level value L (or L1) and possibly the
   reference location level value L2\ :sup:`\*`. The result of the
   expression is then compared against a specified value using a
   specified numeric comparison operator\ :sup:`+`. Optionally, a
   2\ :sup:`nd` comparison for the expression result (using a separate
   comparison value and separate numeric comparison operator) may be
   specified and combined with the 1\ :sup:`st` comparison via a
   specified logical connector\ :sup:`$`. The result of this process
   (with or without the 2\ :sup:`nd` comparison) yields a logical value
   (TRUE or FALSE) called the *value comparison*.

   Additionally, each condition may specify a *rate comparison*, which
   is performed similarly to the value comparison (including an optional
   2\ :sup:`nd` comparison and logical connector) except that the rate
   expression is an expression of the variable R and not V, L (or L1)
   and L2\ :sup:`\*`. The rate comparison is only performed if the value
   comparison yields TRUE.

   The indicator value for the condition is set as follows:

-  If a rate comparison is specified, the indicator value is set only if
   the value comparison and rate comparison both evaluate to TRUE;
   otherwise it is unset.

-  If no rate condition is specified, the indicator value is the result
   of the value comparison.

..

   Each location level indicator condition includes:

-  **Indicator Value (Required)**. An integer in the range of 1..5
   inclusive

-  **Value Expression (Required)**. A mathematical expression with
   special arguments V, L (or L1) and L2\ :sup:`\*`

-  **Value Comparison Operator 1 (Required)**. The comparison
   operator\ :sup:`+` for the 1\ :sup:`st` comparison of the value
   comparison

-  **Value Comparison Value 1 (Required)**. The comparison value for the
   1\ :sup:`st` comparison of the value comparison

-  **Value Comparison Connector (Optional)**. The logical connector for
   the 1\ :sup:`st` and 2\ :sup:`nd` comparisons of the value comparison

-  **Value Comparison Operator 2 (Optional)**. The comparison
   operator\ :sup:`+` for the 2\ :sup:`nd` comparison of the value
   comparison

-  **Value Comparison Value 2 (Optional)**. The comparison value for the
   2\ :sup:`nd` comparison of the value comparison

-  **Rate Expression (Optional)**. A mathematical expression with
   special argument R\ :sup:`\*`

-  **Rate Comparison Operator 1 (Optional)**. The comparison
   operator\ :sup:`+` for the 1\ :sup:`st` comparison of the rate
   comparison

-  **Rate Comparison Value 1 (Optional)**. The comparison rate for the
   1\ :sup:`st` comparison of the rate comparison

-  **Rate Comparison Connector (Optional)**. The logical connector for
   the 1\ :sup:`st` and 2\ :sup:`nd` comparisons of the rate comparison

-  **Rate Comparison Operator 2 (Optional)**. The comparison
   operator\ :sup:`+` for the 2\ :sup:`nd` comparison of the rate
   comparison

-  **Rate Comparison Value 2 (Optional)**. The comparison rate for the
   2\ :sup:`nd` comparison of the rate comparison

..

   :sup:`\*`\ See Table 2: Mathematical Expression Components

   :sup:`+`\ See Table 3: Comparison Operators

   :sup:`$`\ See Table 4: Logical Connectors

.. table:: Table : Comparison Operators

   +-----+----------------+---+-----+------+------------------------------+
   | **  | **Name**       | * | **C | **Ou | **Description**              |
   | Typ |                | * | onn | tput |                              |
   | e** |                | A | ect | Conn |                              |
   |     |                | b | ion | ecti |                              |
   |     |                | b | St  | on** |                              |
   |     |                | r | rin |      |                              |
   |     |                | * | g** |      |                              |
   |     |                | * |     |      |                              |
   +=====+================+===+=====+======+==============================+
   | LO  | Freemont.E     | L | L   | R1D  | Storage location level rated |
   | CAT | lev.Inst.0.Top | 1 | 1=R |      | from elevation location      |
   | ION | of Flood       |   | 1I1 |      | level                        |
   | _LE |                |   |     |      |                              |
   | VEL |                |   |     |      |                              |
   +-----+----------------+---+-----+------+------------------------------+
   | RAT | Fr             | R |     |      |                              |
   | ING | eemont.Elev;St | 1 |     |      |                              |
   |     | or.Linear.Step |   |     |      |                              |
   +-----+----------------+---+-----+------+------------------------------+
   |     |                |   |     |      |                              |
   +-----+----------------+---+-----+------+------------------------------+
   | TI  | Freem          | T | T1= | F1D  | Elevation location level as  |
   | ME_ | ont.Elev-Upper | 1 | F1I |      | average of two time series   |
   | SER | End.Ave.6Hour. |   | 1,T |      |                              |
   | IES | 0.Computed-ccp |   | 2=F |      |                              |
   |     |                |   | 1I2 |      |                              |
   +-----+----------------+---+-----+------+------------------------------+
   | TI  | Freem          | T |     |      |                              |
   | ME_ | ont.Elev-Lower | 2 |     |      |                              |
   | SER | End.Ave.6Hour. |   |     |      |                              |
   | IES | 0.Computed-ccp |   |     |      |                              |
   +-----+----------------+---+-----+------+------------------------------+
   | F   | (ARG1 + ARG2)  | F |     |      |                              |
   | ORM | / 2 {ft,ft;ft} | 1 |     |      |                              |
   | ULA |                |   |     |      |                              |
   +-----+----------------+---+-----+------+------------------------------+
   |     |                |   |     |      |                              |
   +-----+----------------+---+-----+------+------------------------------+
   | LO  | Freemont.E     | L | L   | F1D  | Elevation location level     |
   | CAT | lev.Inst.0.Top | 1 | 1=F |      | with imposed max value       |
   | ION | of Flood       |   | 1I1 |      |                              |
   | _LE |                |   |     |      |                              |
   | VEL |                |   |     |      |                              |
   +-----+----------------+---+-----+------+------------------------------+
   | F   | MIN($I1,       | F |     |      |                              |
   | ORM | 1070.35)       | 1 |     |      |                              |
   | ULA | {ft;ft}        |   |     |      |                              |
   +-----+----------------+---+-----+------+------------------------------+

.. table:: Table : Logical Connectors

   +--------+-----------+------------------------------------------------+
   | **Num  |           |                                                |
   | bers** |           |                                                |
   +========+===========+================================================+
   | 1,     |           | integer, floating point, or scientific         |
   | 2.5,   |           | notation                                       |
   | 3.2E-3 |           |                                                |
   +--------+-----------+------------------------------------------------+
   | *      |           |                                                |
   | *Argum |           |                                                |
   | ents** |           |                                                |
   +--------+-----------+------------------------------------------------+
   | ARG1,  |           | normalized argument form for generalized       |
   | ARG2,  |           | mathematical expressions (not indicator        |
   | …      |           | condition expressions)                         |
   +--------+-----------+------------------------------------------------+
   | $I1,   |           | alternate argument form for generalized        |
   | $I2, … |           | mathematical expressions (not indicator        |
   |        |           | condition expressions)                         |
   +--------+-----------+------------------------------------------------+
   | V      |           | represents time series value in indicator      |
   |        |           | condition expressions                          |
   +--------+-----------+------------------------------------------------+
   | R      |           | represents the rate of change of the time      |
   |        |           | series value V in indicator condition          |
   |        |           | expressions                                    |
   +--------+-----------+------------------------------------------------+
   | L, L1  |           | represents associated location level value in  |
   |        |           | indicator condition expressions                |
   +--------+-----------+------------------------------------------------+
   | L2     |           | represents reference location level value in   |
   |        |           | indicator condition expressions                |
   +--------+-----------+------------------------------------------------+
   | **Expr |           |                                                |
   | ession |           |                                                |
   | Oper   |           |                                                |
   | ator** |           |                                                |
   +--------+-----------+------------------------------------------------+
   | (…)    | override  | infix (algebraic) notation only, not used in   |
   |        | order of  | postfix notation (RPN)                         |
   |        | o         |                                                |
   |        | perations |                                                |
   +--------+-----------+------------------------------------------------+
   | *      |           |                                                |
   | *Unary |           |                                                |
   | Oper   |           |                                                |
   | ator** |           |                                                |
   +--------+-----------+------------------------------------------------+
   | -      | negation  | prepend to item without space, can used only   |
   |        |           | on numbers and arguments (not expressions –    |
   |        |           | use NEG for that)                              |
   +--------+-----------+------------------------------------------------+
   | **     |           |                                                |
   | Binary |           |                                                |
   | Opera  |           |                                                |
   | tors** |           |                                                |
   +--------+-----------+------------------------------------------------+
   | +      | addition  |                                                |
   +--------+-----------+------------------------------------------------+
   | -      | su        |                                                |
   |        | btraction |                                                |
   +--------+-----------+------------------------------------------------+
   | \*     | multi     |                                                |
   |        | plication |                                                |
   +--------+-----------+------------------------------------------------+
   | /      | division  |                                                |
   +--------+-----------+------------------------------------------------+
   | //     | integer   | like python operator                           |
   |        | division  |                                                |
   +--------+-----------+------------------------------------------------+
   | %      | modulus   | like python math.fmod(), not python %          |
   +--------+-----------+------------------------------------------------+
   | ^      | expon     |                                                |
   |        | entiation |                                                |
   +--------+-----------+------------------------------------------------+
   | *      |           |                                                |
   | *Unary |           |                                                |
   | Funct  |           |                                                |
   | ions** |           |                                                |
   +--------+-----------+------------------------------------------------+
   | ABS    | absolute  |                                                |
   |        | value     |                                                |
   +--------+-----------+------------------------------------------------+
   | ACOS   | arccosine |                                                |
   +--------+-----------+------------------------------------------------+
   | ASIN   | arcsine   |                                                |
   +--------+-----------+------------------------------------------------+
   | ATAN   | a         |                                                |
   |        | rctangent |                                                |
   +--------+-----------+------------------------------------------------+
   | CEIL   | ceiling   | smallest integer >= argument                   |
   +--------+-----------+------------------------------------------------+
   | COS    | cosine    |                                                |
   +--------+-----------+------------------------------------------------+
   | EXP    | ex        | *e* raised to power of argument                |
   |        | ponential |                                                |
   +--------+-----------+------------------------------------------------+
   | FLOOR  | floor     | Largest integer <= argument                    |
   +--------+-----------+------------------------------------------------+
   | INV    | inverse   | 1 / argument                                   |
   +--------+-----------+------------------------------------------------+
   | LN     | natural   |                                                |
   |        | logarithm |                                                |
   +--------+-----------+------------------------------------------------+
   | LOG    | base 10   |                                                |
   |        | logarithm |                                                |
   +--------+-----------+------------------------------------------------+
   | NEG    | negation  |                                                |
   +--------+-----------+------------------------------------------------+
   | ROUND  | round to  |                                                |
   |        | nearest   |                                                |
   |        | integer   |                                                |
   +--------+-----------+------------------------------------------------+
   | SIGN   | signum    | sign of argument: -1 or +1                     |
   +--------+-----------+------------------------------------------------+
   | SIN    | sine      |                                                |
   +--------+-----------+------------------------------------------------+
   | SQRT   | square    |                                                |
   |        | root      |                                                |
   +--------+-----------+------------------------------------------------+
   | TAN    | tangent   |                                                |
   +--------+-----------+------------------------------------------------+
   | TRUNC  | truncate  |                                                |
   |        | to        |                                                |
   |        | integer   |                                                |
   |        | portion   |                                                |
   +--------+-----------+------------------------------------------------+
   | **     |           |                                                |
   | Binary |           |                                                |
   | Funct  |           |                                                |
   | ions** |           |                                                |
   +--------+-----------+------------------------------------------------+
   | MAX    | maximum   |                                                |
   |        | of two    |                                                |
   |        | arguments |                                                |
   +--------+-----------+------------------------------------------------+
   | MIN    | minimum   |                                                |
   |        | of two    |                                                |
   |        | arguments |                                                |
   +--------+-----------+------------------------------------------------+
   | *      |           |                                                |
   | *Const |           |                                                |
   | ants** |           |                                                |
   +--------+-----------+------------------------------------------------+
   | E      | *e*       | Euler’s number                                 |
   +--------+-----------+------------------------------------------------+
   | PI     | π         | ratio of a circle’s circumference to its       |
   |        |           | diameter                                       |
   +--------+-----------+------------------------------------------------+

+------------------------------+---------------------------------------+
| **Comparison Operators**     |                                       |
+==============================+=======================================+
| LT, <                        | less than                             |
+------------------------------+---------------------------------------+
| LE, <=                       | less than or equal to                 |
+------------------------------+---------------------------------------+
| EQ, =                        | equal to                              |
+------------------------------+---------------------------------------+
| NE, !=, <>                   | not equal to                          |
+------------------------------+---------------------------------------+
| GE, >=                       | greater than or equal to              |
+------------------------------+---------------------------------------+
| GT, >                        | greater than                          |
+------------------------------+---------------------------------------+

+---------------------------+------------------------------------------+
| **Logical Connectors**    |                                          |
+===========================+==========================================+
| AND                       | +----------+----------+--------------+   |
|                           | | **A**    | **B**    | **A AND B**  |   |
|                           | +==========+==========+==============+   |
|                           | | FALSE    | FALSE    | FALSE        |   |
|                           | +----------+----------+--------------+   |
|                           | | FALSE    | TRUE     | FALSE        |   |
|                           | +----------+----------+--------------+   |
|                           | | TRUE     | FALSE    | FALSE        |   |
|                           | +----------+----------+--------------+   |
|                           | | TRUE     | TRUE     | TRUE         |   |
|                           | +----------+----------+--------------+   |
+---------------------------+------------------------------------------+
| OR                        | +----------+----------+--------------+   |
|                           | | **A**    | **B**    | **A OR B**   |   |
|                           | +==========+==========+==============+   |
|                           | | FALSE    | FALSE    | FALSE        |   |
|                           | +----------+----------+--------------+   |
|                           | | FALSE    | TRUE     | TRUE         |   |
|                           | +----------+----------+--------------+   |
|                           | | TRUE     | FALSE    | TRUE         |   |
|                           | +----------+----------+--------------+   |
|                           | | TRUE     | TRUE     | TRUE         |   |
|                           | +----------+----------+--------------+   |
+---------------------------+------------------------------------------+
| XOR                       | +----------+----------+--------------+   |
|                           | | **A**    | **B**    | **A XOR B**  |   |
|                           | +==========+==========+==============+   |
|                           | | FALSE    | FALSE    | FALSE        |   |
|                           | +----------+----------+--------------+   |
|                           | | FALSE    | TRUE     | TRUE         |   |
|                           | +----------+----------+--------------+   |
|                           | | TRUE     | FALSE    | TRUE         |   |
|                           | +----------+----------+--------------+   |
|                           | | TRUE     | TRUE     | FALSE        |   |
|                           | +----------+----------+--------------+   |
+---------------------------+------------------------------------------+
