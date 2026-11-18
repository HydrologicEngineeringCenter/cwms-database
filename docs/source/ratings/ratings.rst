============
CWMS RATINGS
============

**Design and Usage Overview**

**USACE**

**Hydrologic Engineering Center**

**11 October 2017**

**
**

`1. Overview <#_Toc408306741>`__\ `4 <#_Toc408306741>`__

`a. Rating Types <#_Toc408306742>`__\ `4 <#_Toc408306742>`__

`i. Simple Ratings. <#_Toc408306743>`__\ `4 <#_Toc408306743>`__

`Simple ratings specify either rating lookup table or a formula and were
introduced in CWMS 2.1. <#_Toc408306744>`__\ `4 <#_Toc408306744>`__

`ii. USGS-Style Stream
Ratings. <#_Toc408306745>`__\ `4 <#_Toc408306745>`__

`USGS-style stream ratings specify base rating lookup table, stage shift
lookup table, and interpolation offset lookup table, and were introduced
in CWMS 2.1. <#_Toc408306746>`__\ `4 <#_Toc408306746>`__

`iii. Virtual Ratings. <#_Toc408306747>`__\ `4 <#_Toc408306747>`__

`iv. Transitional Ratings. <#_Toc408306748>`__\ `5 <#_Toc408306748>`__

`2. Specification <#_Toc283652571>`__\ `5 <#_Toc283652571>`__

`a. Rating Templates <#_Toc283652572>`__\ `5 <#_Toc283652572>`__

`i. Parameters <#_Toc283652573>`__\ `5 <#_Toc283652573>`__

`ii. Lookup methods <#Lookup_Methods>`__\ `5 <#Lookup_Methods>`__

`b. Rating Specifications <#_Toc283652575>`__\ `7 <#_Toc283652575>`__

`c. Ratings <#_Toc283652576>`__\ `9 <#_Toc283652576>`__

`3. Time Series of Ratings. <#_Toc408306755>`__\ `9 <#_Toc408306755>`__

`4. Rating Extensions <#_Toc408306756>`__\ `10 <#_Toc408306756>`__

`5. Rating Formulas <#_Toc283652578>`__\ `10 <#_Toc283652578>`__

`a. Operators <#_Toc283652579>`__\ `10 <#_Toc283652579>`__

`b. Functions <#_Toc283652580>`__\ `10 <#_Toc283652580>`__

`c. Constants <#_Toc283652581>`__\ `11 <#_Toc283652581>`__

`d. Example <#_Toc283652582>`__\ `11 <#_Toc283652582>`__

`6. Virtual Rating Source
Ratings <#_Toc408306762>`__\ `12 <#_Toc408306762>`__

`7. Virtual Rating
Connections <#_Toc408306763>`__\ `12 <#_Toc408306763>`__

`a. Connection Strings and Connection
Points <#_Toc408306764>`__\ `12 <#_Toc408306764>`__

`b. Connection Point Ordering and Default
Connections <#_Toc408306765>`__\ `12 <#_Toc408306765>`__

`c. Example 1 <#_Toc408306766>`__\ `14 <#_Toc408306766>`__

`d. Example 2 <#_Toc408306767>`__\ `15 <#_Toc408306767>`__

`e. Example 3 <#_Toc408306768>`__\ `16 <#_Toc408306768>`__

`8. Transitional Rating Selection
Criteria <#_Toc408306769>`__\ `17 <#_Toc408306769>`__

`a. Logical Expressions <#_Toc408306770>`__\ `17 <#_Toc408306770>`__

`b. Evaluations <#_Toc408306771>`__\ `17 <#_Toc408306771>`__

`9. Transitional Rating Source
Ratings <#_Toc408306772>`__\ `18 <#_Toc408306772>`__

`10. External
Representation <#_Toc408306773>`__\ `18 <#_Toc408306773>`__

`11. API <#_Toc283652584>`__\ `18 <#_Toc283652584>`__

1. **
   **\ **Overview.** As of CWMS version 2.1, the CWMS Oracle database
   supports the storage, retrieval, cataloging and deleting of ratings
   via an application programming interface (API) specified in the
   CWMS_RATING package. In addition, the API also provides numerous
   routines to apply ratings. Several views also exist to allow users
   and developers to easily see the stored ratings. CWMS ratings have
   one or more independent (input) parameters and a single output
   (dependent) parameter. Currently the code allows up to nine
   independent parameters while the views will display up to five
   independent parameters. CWMS 3.1 adds support for new types of
   ratings which are constructed from the rating types included in CWMS
   2.1.

   a. **Rating Types.** CWMS supports the following rating types:

      i. **Simple Ratings.** Simple ratings are defined by either a
         single lookup table or by a formula. A lookup table is an
         ordered set rating points. A rating point is a set of values,
         one for each independent parameter as well as one for the
         dependent parameter. The dependent value is known when the
         independent value(s) match a rating point. Various methods are
         provided to determine the dependent value when the independent
         value(s) do/does not match a rating point. A formula is a
         mathematical expression which defines a function of the
         independent parameter values.

..

   Simple ratings specify either rating lookup table or a formula and
   were introduced in CWMS 2.1.

ii. **USGS-Style Stream Ratings.** USGS-style stream ratings are
    comprised by a single stage/discharge lookup table which defines the
    base relationship, an optional lookup table of stage/shift rating
    points which is used to alter the stage before performing the base
    lookup, and an optional lookup table of stage/offset rating points
    which is used to modify the logarithmic interpolation between values
    in the base table.

..

   USGS-style stream ratings specify base rating lookup table, stage
   shift lookup table, and interpolation offset lookup table, and were
   introduced in CWMS 2.1.

iii. **Virtual Ratings.** Virtual ratings are ratings that are assembled
     by connecting the independent and/or dependent parameters of two or
     more source ratings in order to create a rating that will perform
     multiple rating steps in a single API call.

..

   Each source rating may be a reference to another rating in the
   database or a formula that defines a function of its input values.
   Source rating formulas are functionally equivalent to source ratings
   referencing formula-based simple ratings. Formula-based source
   ratings are often necessary to combine by addition or multiplication
   the outputs of other source ratings into either the virtual rating
   output or the input to another source rating.

   Virtual ratings specify source ratings and rating parameter
   connections and were introduced in CWMS 3.1.

iv. **Transitional Ratings.** Transitional ratings are ratings that
    compare independent parameter values against selection criteria and
    evaluate a formula associated with the selected case to determine
    the dependent parameter values.

..

   The formulas are mathematical expressions that define functions of
   their input values and/or references to source ratings. Each source
   rating is a reference to another rating in the database.

   Transitional ratings specify selection criteria, mathematical
   expressions, and source ratings and were introduced in CWMS 3.1.

2. **Specification.** CWMS ratings are specified in a hierarchical
   manner. One or more ratings can share a rating specification, and one
   or more rating specifications can share a rating template.

   a. **Rating Templates.** A rating template specifies the independent
      and dependent parameters and the lookup methods to use for every
      rating associated with the template (if the rating uses a lookup
      table). A rating template identifier is comprised of a list of the
      parameters and a version. The parameters list is a comma-separated
      list of the one or more independent parameters followed by a
      semi-colon and the dependent parameter. The version is limited to
      32 characters and uniquely identifies the lookup method(s) used
      with the specified parameter list. A complete rating template
      identifier is the parameters list followed by a period and the
      version (e.g., Stage;Flow.USGS-shifted or
      Count-Conduit_Gates,Opening-Conduit_Gates,Elev-Pool;Flow-Conduit_Gates.Normal).

      i.  **Parameters.** Rating parameters are the same as parameters
          used in time series identifiers. Each has a base parameter
          portion which is constrained to the list of valid CWMS base
          parameters and an optional sub-parameter portion which is
          unconstrained except for its maximum length of 32 characters.
          If a parameter includes a sub-parameter, the sub-parameter is
          separated from the base parameter by the hyphen/dash (-)
          character. Thus the base parameter Elev can be made more
          specific by adding a sub-parameter, as in Elev-Tailwater or
          Elev-Pool.

      ii. **Lookup methods.** Each rating template specifies three
          lookup methods for each independent parameter: one for the
          case of the independent value being less than the least
          independent value in the rating (out of range low), one for
          the independent value being between the least and greatest
          independent values in the rating, inclusive (in range), and
          one for the independent value being greater than the greatest
          independent value in the rating (out of range high). Only
          simple ratings with lookup tables use the lookup methods.
          Valid lookup methods are:

..

   **NULL**. When specified for out of range low or high method, return
   NULL for the dependent value when the independent value is out of
   range. When specified for in range method, return NULL for the
   dependent value if the independent value does not exactly match an
   independent value in the rating. For example, when the independent
   value is a count of gates open, it makes no sense to specify a
   fractional gate open count, so return NULL.

   **ERROR.** Same as the NULL lookup method, except an exception is
   raised instead of returning NULL.

   **LINEAR**. When used for an in range method, linearly interpolate
   both independent and dependent values. When specified as an out of
   range low or high method, linearly extrapolate both independent and
   dependent values.

   **LOGARITHMIC.** Same as the LINEAR lookup method, except logarithmic
   interpolation/extrapolation is used if possible for both independent
   and dependent values. Linear interpolation/extrapolation is used
   where logarithmic is not possible.

   **LIN_LOG.** Same as the LOGARITHMIC lookup method except that
   logarithmic interpolation/extrapolation is performed on the dependent
   values only. Linear interpolation/extrapolation is used for the
   independent values.

   **LOG_LIN.** Same as the LOGARITHMIC lookup method except that
   logarithmic interpolation/extrapolation is performed on the
   independent values only. Linear interpolation/extrapolation is used
   for the dependent values.

   **PREVIOUS.** Return the dependent value of the rating point whose
   position in the rating would immediately precede or be equal to a
   rating point whose independent value is the value to be rated. Since
   CWMS ratings are always stored in order of increasing independent
   values, this method is equivalent to the LOWER lookup method.

   **NEXT.** Return the dependent value of the rating point whose
   position in the rating would immediately follow or be equal to a
   rating point whose independent value is the value to be rated. Since
   CWMS ratings are always stored in order of increasing independent
   values, this method is equivalent to the HIGHER lookup method.

   **NEAREST.** Return the dependent value of the rating point whose
   position in the rating is the nearest to a hypothetical point
   containing the independent value being rated. When specifies as an
   out of range low method this is equivalent to NEXT. When specified as
   an out of range high method this is equivalent to PREVIOUS. This is
   not a valid in range method.

   **LOWER.** Return the dependent value of the rating point that has
   the greatest independent value that is less than or equal to the
   independent value to be rated. If no such rating point exists, raise
   an exception.

   **HIGHER.** Return the dependent value of the rating point that has
   the least independent value that is greater than or equal to the
   independent value to be rated. If no such rating point exists, raise
   an exception.

   **CLOSEST.** Return the dependent value of the rating point whose
   independent value is closer to the independent value to be rated than
   any other rating point.

b. **Rating Specifications.** A rating specification specifies a
   location, a rating template, and a set of characteristics. A version
   identifier labels the set of characteristics associated with the
   location and rating template. A complete rating specification
   identifier includes the CWMS location identifier, rating template
   identifier, and rating specification version separated by the period
   (.) character (e.g. TULA.Stage;Flow.USGS-shifted.Production, or
   ARCA.Count-Conduit_Gates,Opening-Conduit_Gates,Elev-Pool;Flow-Conduit_Gates.Normal.Production).
   The characteristics associated with a rating specification are:

..

   **Source Agency.** Specifies the agency, company, or organization
   that is the authoritative source for ratings associated with this
   rating specification.

   **Lookup Methods.** Each rating specification contains information on
   how to handle multiple ratings with different effective dates. The
   lookup methods are the same as specified in 3.a.ii, but the
   independent value is time and the dependent value is the rated value
   returned by the various ratings. In this context, out of range low
   means that the time of the data to be rated is earlier than the
   earliest effective date of any rating with this rating specification,
   out of range high means that the time of the data to be rated is
   later than the latest effective date of any rating with this rating
   specification, and in range means that the time of the data to be
   rated is bounded by the earliest and latest effective dates.

   **Active Flag.** If false, no ratings associated with this rating
   specification will be used to rate data. If false, ratings associated
   with this rating specification may be used, but note that individual
   ratings may also be specified as active or inactive.

   **Auto Update Flag.** If true, any automatic ratings update mechanism
   should load ratings associated with this rating specification into
   the database as soon as they are available.

   **Auto Activate Flag.** If true, any automatically loaded ratings
   associated with this rating specification should be marked as active.
   If false, any automatically loaded ratings associated with this
   rating specification should be marked as inactive.

   **Auto Migrate Extension Flag.** If true, any automatically loaded
   ratings associated with this rating specification should have any
   rating extension present on the next most recent rating applied to
   the newly loaded rating.

   **Rounding Specifications.** USGS-style rounding criteria strings for
   each independent parameter, as well as for the dependent parameter.
   Each rounding specification is a 10 digit string, with the first 9
   digits specifying the number of significant digits (not decimal
   places) the parameter should be rounded to for the magnitude
   indicated by the digit’s position in the string. The first digit
   indicates a magnitude of less than .01, and the ninth digit indicates
   a magnitude of greater than or equal to 100,000. Intermediate digits
   specify magnitudes of increasing powers of 10 from left to right. The
   last digit specifies the maximum number of decimal places to be
   displayed for any magnitude. For example, the rounding specification
   2233344332 indicates that values less than 1 should be rounded to 2
   significant digits, values of greater to or equal than .1 and less
   than 100 should be rounded to 3 significant digits, values greater
   than or equal to 100 and less than 10,000 should be rounded to 4
   significant digits, and values greater than or equal t0 10,000 should
   be rounded to 3 significant digits. For all values, no more than 2
   decimal places should be displayed. Ratings downloaded from the
   National Weather Service NWIS ratings depot include rounding
   specifications for each parameter.

   **Description.** Descriptive text about the rating specification,
   limited to 256 characters.

c. **Ratings.** A rating contains the data as specified in 2.a that is
   used to transform the independent parameter values to dependent
   parameter values. Each rating is associated with a rating
   specification and has an effective date which identifies it uniquely
   within the rating specification. In addition to the effective date
   and the formula or rating points, each rating also contains the
   following information:

..

   **Creation Date.** The date and time that the rating was first known.
   This information is used when performing historical ratings (ratings
   at a past point in time) to filter out information that was not known
   at the time. If not specified in the external representation, this
   field is set to the current time when the rating is loaded into the
   database. This information is output when ratings are retrieved from
   the database to preserve the information.

   **Active Flag.** If true, the rating is available for use. If false,
   the rating will not be used in any rating operation.

   **Native Units.** Specifies the units of the independent and
   dependent parameters of the external representation.

   **Description.** Descriptive text of the rating, limited to 256
   characters.

3. **Time Series of Ratings**. As described in the preceding sections,
   multiple ratings with different effective dates can share a common
   rating specification which contains lookup methods that determine the
   behavior of applying the ratings to independent values at a given
   time. Common in-range methods are PREVIOUS and LINEAR, while PREVIOUS
   or NEAREST, which have the same effect, are common for
   out-of-range-high. The out-of-range-low method is commonly NEXT or
   NEAREST, which have the same effect, or NULL or ERROR.

..

   Specifying LINEAR for an in-range method causes the API to linearly
   interpolate between the two ratings whose effective times bound the
   time of the values(s) to be rated. For USGS-style stream ratings, the
   situation is more complicated. If the time of the value to be rated
   is on or before the effective date of the latest shift of the
   previous rating, then the previous rating is used, interpolating the
   shifts as necessary. If the time of the values to be rated is after
   the effective date latest shift of the previous rating, then the
   interpolation occurs in the time span between the effective date of
   the latest shift of the previous rating and the effective date of the
   next rating, interpolating flows as necessary.

   It is sometimes desirable to transition from one rating to another or
   from one shift to another on USGS-style ratings over a much shorter
   time span prior to the new rating or shift than the LINEAR lookup
   method would provide. This can be accomplished by duplicating the
   previous rating or shift and setting the effective date of the
   duplicate to the start of the desired transition time. This will
   cause the rating to remain constant in the period between the
   effective dates of the original and duplicate ratings or shifts and
   to transition linearly between the effective dates of the duplicate
   and next rating or shift.

4. **Rating Extensions.** A USGS-style stream rating may include a
   separately-specified lookup table of stage/discharge values called a
   rating extension. A rating extension specifies rating points
   (extension points) outside the base stage/discharge lookup table and
   is used to provide historic high (normally) or low stage/discharge
   values. When a rating with an extension is applied, the base lookup
   table is first extended above and/or below its specified range by
   including the appropriate extension points. Any extension points that
   are within the range of the base rating table are ignored.

5. **Rating Formulas.** A formula-based rating specifies a mathematical
   expression that includes a variable for each of the independent
   parameters, by position, to be used. The variable name for the first
   independent parameter is I1, the name for the second is I2, etc….
   Negated variables in the format -I1, -I2, etc… are allowed.
   (ARG1..ARGn, as well as $1..$n are allowed, but generated XML will
   always have the normalized format of I1..In.) The mathematical
   expressions may be specified in infix notation (algebraic notation)
   or postfix notation (reverse polish notation, or RPN). All numbers,
   variables, operators, and function names must be separated from all
   others by at least one space, with the exception that no spaces are
   required adjacent to parentheses (infix notation only, postfix
   notation does not use parentheses). Mathematical expressions are not
   case sensitive.

   a. **Operators.** The following operators are supported. All
      operators are binary (take two arguments).

..

   **+** addition

   **-** subtraction

   **\*** multiplication

   **/** division

   **//** integer division

   **%** modulus

   **^** exponentiation

b. **Functions.** The following functions are supported. All functions
   are unary (take one argument).

..

   **ABS** absolute value

   **ACOS** arc cosine

   **ASIN** arc sine

   **ATAN** arc tangent

   **CEIL** ceiling – smallest integer greater than or equal to argument

   **COS** cosine

   **EXP** exponent – e raised to the power of the argument

   **FLOOR** floor – largest integer less than or equal to argument

   **INV** inverse

   **LN** natural logarithm – logarithm base e

   **LOG** logarithm base 10

   **NEG** negation

   **ROUND** round to nearest integer

   **SIGN** signum – sign of argument returned as -1, 0, or 1

   **SIN** sine

   **SQRT** square root

   **TAN** tangent

   **TRUNC** truncation – integer portion of argument

c. **Constants.** The following constants are supported.

..

   **PI** the ratio of a circle’s circumference to its diameter

   **E** Euler’s number – the base of the natural logarithm

d. **Example.** Assume we need to use the formula
   :math:`Q = C_{s}Lh_{s}\sqrt{2gh}` to compute the flow through
   submerged gates. Given the following definitions and independent
   parameters, the mathematical expressions would be as shown.

..

   **Definitions**:

   :math:`C_{s}` = submerged gate coefficient

   :math:`L` = 60.0 ft

   :math:`h` = pool elevation – tail water elevation in feet

   :math:`h_{s}` = tailwater elevation in feet - sill elevation (506.0
   ft)

   :math:`g` = acceleration due to gravity (32.2 ft/sec\ :sup:`2`)

   **Parameters**:

   Independent parameter 1: Elev-Pool

   Independent parameter 2: Elev-Tailwater

   Independent parameter 3: Coeff-Gate-Submerged

   **Native Units**:

   Native units for the rating would be ft, ft, n/a, and cfs. Other
   units could be specified and/or requested and the rating procedure
   would handle the unit conversions, ensuring the appropriate units are
   used with the formula.

   **Expressions**:

   Infix (Algebraic):

   I3 \* 60 \* (I2 - 506) \* SQRT(64.4 \* (I2 - I1))

   Postfix (RPN):

   I2 I1 - 64.4 \* SQRT I2 506 - \* 60 \* I3 \*

6. **Virtual Rating Source Ratings.** Source ratings specified in
   virtual ratings may be rating specification identifiers or formulas.
   Rating specification identifiers must be for the same location as for
   the virtual rating. Formulas have the same format specified in
   Section 5.

7. **Virtual Rating Connections.** Virtual ratings specify how the
   independent parameters are connected to the source ratings and how
   the independent and/or dependent parameters of the source ratings are
   connected to each other.

   a. **Connection Strings and Connection Points.** A virtual rating
      *connection string* is a comma-separated string of individual
      connections. Each individual connection is two different
      *connection points* separated by an equals sign (=). Connection
      points are comprised of the set of all independent parameters to
      the virtual rating plus all independent parameters of each source
      rating plus all dependent parameters of each source rating.
      Connection points are of the following formats. Note that ‘I’ is
      upper case ‘i’, not lower case ‘L’.

-  **I\ n** – Input independent parameter *n*, referencing the
      independent parameters of the virtual rating. Independent
      parameters are ordered by their position in the parameters
      identifier in the rating template. Connection point I2 specifies
      the 2\ :sup:`nd` independent parameter of the virtual rating.

-  **R\ m\ I\ n** – Source rating *m* independent parameter *n*.
      Connection point R1I2 specifies the 2\ :sup:`nd` independent
      parameter of the 1\ :sup:`st` source rating.

-  **R\ m\ D** – Source rating *m* dependent parameter. Connection point
      R2D specifies the dependent parameter of the 2\ :sup:`nd` source
      rating.

..

   Example connection strings:

-  R1I1=R2I1

-  R1D=R3I1,R2D=R3I2

-  R2I1=I1,R2I2=R1D,R3I1=R2D

   a. **Connection Point Ordering and Default Connections.** Source
      rating connection points are ordered first by the position of the
      source rating and then the position of the independent parameter
      to that rating, with the dependent parameter of any source rating
      ordered after the last independent parameter of that same source
      rating. For example “R2D” would sort after “R2I3” and before
      “R3I1”.

..

   At least one of the source rating connection points must be left
   unspecified in the connections string. The maximum number of source
   rating connection points that may be left unspecified is one greater
   than the number of independent parameters of the virtual rating. The
   last (or only) unspecified source rating connection point – according
   to the order specified above – is the dependent parameter for the
   virtual rating. Any additional unspecified source rating connection
   points are by default connected to the independent parameters of the
   virtual rating in order (i.e., I1 is connected to the first
   unspecified source rating connection point, I2 is connected to the
   second one, etc…). All source rating connection points that are
   connected to independent parameters of the virtual rating may be
   specified for clarity; only the source rating connection point
   connected to the dependent parameter of the virtual rating is
   required to remain unspecified.

**
**

b. **Example 1.** Consider a virtual rating with one independent
   parameter – measured stage – and a dependent parameter of flow with
   the following source ratings and connections string:

-  R1 is a rating with an independent parameter of measured stage and a
   dependent parameter of stage correction.

-  R2 is a formula which adds its 1\ :sup:`st` input – measured stage –
   to its 2\ :sup:`nd` input – stage correction – to generate an output
   of corrected stage.

-  R3 is a rating with an independent parameter of corrected stage and
   an dependent parameter of flow.

-  The connection string is R2I1=I1,R2I2=R1D,R3I1=R2D

..

   The source rating connection points R1D, R2I1, R2I2, R2D, and R3I1
   are all specified in the connection string, leaving the source rating
   connection points R1I1 and R3D unspecified. The last unspecified
   source rating connection point in order, R3D, becomes the dependent
   parameter for the source rating, and R1I1 is connected by default to
   I1.

   .. image:: media/ratings/virtual-rating.svg

a. **Example 2.** Consider a virtual rating with independent parameters
   of index velocity and stage and a dependent parameter of flow with
   the following source ratings and connections string:

-  R1 is a rating with an independent parameter of index speed and a
   dependent parameter of stage correction.

-  R2 is a rating with an independent parameter of stage and an
   dependent parameter of cross-sectional area.

-  R3 is a formula which multiplies its 1\ :sup:`st` input – average
   speed – to its 2\ :sup:`nd` input – cross-sectional area – to
   generate an output of flow.

-  The connection string is R1D=R3I1,R2D=R3I2

..

   The source rating connection points R1D, R2D, R3I1, and R3I3 are all
   specified in the connection string, leaving the source rating
   connection points R1I1, R2I1 and R3D unspecified. The last
   unspecified source rating connection point in order, R3D, becomes the
   dependent parameter for the source rating, while R1I1 and R2I1 are
   connected by default to I1 and I2, respectively.

   .. image:: media/ratings/virtual-rating-2.svg

a. **Example 3.** Consider a virtual rating with an independent
   parameter of reservoir storage and a dependent parameter of surface
   with the following source ratings and connections string:

-  R1 is a rating with an independent parameter of reservoir elevation
   and a dependent parameter of storage.

-  R2 is a rating with an independent parameter of reservoir elevation
   and a dependent parameter of surface area.

-  The connection string is R1I1=R2I1

..

   The source rating connection points R1I1 and R2I1 are both specified
   in the connection string, leaving the source rating connection points
   R1D and R2D unspecified. The last unspecified source rating
   connection point in order, R2D, becomes the dependent parameter for
   the source rating, while R1D is connected by default to I1.

   .. image:: media/ratings/virtual-rating-link.svg

8. **Transitional Rating Selection Criteria.** Transitional rating
   selection criteria are comprised of an ordered list of zero or more
   *logical expressions*, with an *evaluation* associated with each
   expression, followed by a default evaluation. The logical expressions
   are tested in order, using the current set of independent parameter
   values. If an expression yields “True” when tested, then the
   evaluation associated with that expression is performed to generate
   the dependent parameter value for the transitional rating and the
   selection process ceases. If none of the expressions yield “True”
   when tested, then the default evaluation is performed to generate the
   dependent parameter value for the transitional rating.

   a. **Logical Expressions. L**\ ogical expressions are expressions
      that evaluate to True or False. They are comprised of mathematical
      expressions (see Section 5) combined with the following comparison
      and combination operators:

+------+----+--------+----------------------+-------------------------+
| **Op |    |        | **Class**            | **Description**         |
| erat |    |        |                      |                         |
| or** |    |        |                      |                         |
+======+====+========+======================+=========================+
| =    |    | EQ     | comparator           | equal to                |
+------+----+--------+----------------------+-------------------------+
| !=   | <> | NE     | comparator           | not equal to            |
+------+----+--------+----------------------+-------------------------+
| >    |    | GT     | comparator           | greater than            |
+------+----+--------+----------------------+-------------------------+
| >=   |    | GE     | comparator           | greater than or equal   |
|      |    |        |                      | to                      |
+------+----+--------+----------------------+-------------------------+
| <    |    | LT     | comparator           | less than               |
+------+----+--------+----------------------+-------------------------+
| <=   |    | LE     | comparator           | less than or equal to   |
+------+----+--------+----------------------+-------------------------+
| AND  |    |        | combinator           | conjunction             |
+------+----+--------+----------------------+-------------------------+
| OR   |    |        | combinator           | disjunction (inclusive) |
+------+----+--------+----------------------+-------------------------+
| XOR  |    |        | combinator           | disjunction (exclusive) |
+------+----+--------+----------------------+-------------------------+
| NOT  |    |        | combinator           | negation                |
+------+----+--------+----------------------+-------------------------+

..

   Logical expressions may be specified in infix (algebraic) or postfix
   (RPN) notation, but notations may not be mixed in the same
   expression.

-  I3 < 11.1 AND I1 – I2 < 7.5 correct (infix)

-  I3 11.1 < I1 I2 – 7.5 < AND correct (postfix)

-  I3 < 11.1 AND I1 I2 – 7.5 < incorrect (mixed notation)

..

   If multiple combinators are included in infix notation, attention
   must be paid to operator precedence: NOT, AND, XOR, OR. NOT has the
   highest precedence and so binds the most tightly to its argument; OR
   has the lowest precedence and so binds the least tightly to its
   arguments. Parentheses may be used to alter the order of operations.
   All mathematical operators have higher precedence than any comparison
   operator, and all comparison operators have higher precedence than
   any combination operator.

a. **Evaluations.** Each evaluation is a formula as defined in Section
   5, with the addition of the term **R\ n** which references the
   dependent parameter value of source rating *n* (e.g., R1 references
   the dependent parameter value of source rating 1) using the current
   set of input parameter values. Source rating terms may be included in
   larger evaluation formulas; they may also be the only term in an
   evaluation, specifying that the source rating *is* the evaluation.

9.  **Transitional Rating Source Ratings.** Source ratings in
    transitional ratings are specified as rating specification
    identifiers. Each source rating must be for the same location as the
    transitional rating and must also have the same parameters
    identifier.

10. **External Representation.** The external representations of rating
    templates, rating specifications, and ratings that are handled by
    the CWMS_RATING package for storage and retrieval is an XML format
    formally described in the XML schema document
    http://www.hec.usace.army.mil/xmlSchema/cwms/Ratings.xsd, which is
    documented at
    http://www.hec.usace.army.mil/xmlSchema/cwms/Ratings.htm. The
    document root is “ratings”, and may include zero or more
    “rating-template” elements followed by zero or more “rating-spec”
    elements, followed by zero or more “simple-rating”,
    “usgs-stream-rating”, “virtual-rating”, and/or “transitional-rating”
    elements, in that order.

11. **API.** The CWMS Database API provides routines for storing,
    retrieving, cataloging and deleting rating templates, rating
    specifications, and ratings. It also provides routines for applying
    ratings in various manners. See the following items in the CWMS
    Database API documentation:

-  CWMS_RATING package

-  CWMS_V_RATING view

-  CWMS_V_RATING_LOCAL view

-  CWMS_V_RATING_SPEC view

-  CWMS_V_RATING_TEMPLATE view

-  CWMS_V_RATING_VALUES view

-  CWMS_V_RATING_VALUES_NATIVE view

-  CWMS_V_TRANSITIONAL_RATING view

-  CWMS_V_VIRTUAL_RATING view
