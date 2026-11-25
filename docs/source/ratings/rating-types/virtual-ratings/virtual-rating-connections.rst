.. _virtual-rating-connections:

Virtual Rating Connections
==========================

Virtual ratings specify how the independent parameters are connected to the source
ratings and how the independent and/or dependent parameters of the source ratings
are connected to each other.

Connection Strings and Connection Points
----------------------------------------

A virtual rating *connection string* is a comma-separated string of individual
connections. Each individual connection is two different *connection points*
separated by an equals sign (=). Connection points are comprised of the set of all
independent parameters to the virtual rating plus all independent parameters of
each source rating plus all dependent parameters of each source rating. Connection
points are of following formats. Note that 'I' is upper case 'i', not lower case 'L'.

- **In** - Input independent parameter *n*, referencing the independent parameters
  of the virtual rating. Independent parameters are ordered by their position in the
  parameters identifier in the rating template. Connection point I2 specifies the 2nd
  independent parameter of the virtual rating.
- **RmIn** - Source rating *m* independent parameter *n*. Connection point R1I2 specifies
  the 2nd independent parameter of the 1st source rating.
- **RmD** - Source rating *m* dependent parameter. Connection point R2D specifies the
  dependent parameter of the 2nd source rating.

Example Connection strings:
    - ``R1I1=R2I1``
    - ``R1D=R3I1,R2D=R3I2``
    - ``R2I1=I1,R2I2=R1D,R3I1=R2D``

Connection Point Ordering and Default Connections
-------------------------------------------------

Source rating connection points are ordered first by the position of the source rating
and then the position of the independent parameter to that rating, with the dependent
parameter of any source rating ordered after the last independent parameter of that same
source rating. For example "R2D" would sort after "R2I3" and before "R3I1".

At least one of the source rating connection points must be left unspecified in the
connections string. The maximum number of source rating connection points that may be
left unspecified is one greater than the number of independent parameters of the virtual
rating. The last (or only) unspecified source rating connection point - according to the
order specified above - is the dependent parameter for the virtual rating. Any additional
unspecified source rating connection points are by default connected to the independent
parameters of the virtual rating in order (i.e., I1 is connected to the first unspecified
source rating connection point, I2 is connected to the second one, etc.). All source
rating connection points that are connected to independent parameters of the virtual
rating may be specified for clarity; only the source rating connection point connected
to the dependent parameter of the virtual rating is required to remain unspecified.