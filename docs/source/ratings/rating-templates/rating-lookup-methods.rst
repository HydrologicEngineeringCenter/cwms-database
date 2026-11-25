.. _rating-lookup-methods:

Lookup Methods
==============

Each rating template specifies three lookup methods for each independent parameter:
one for the case of the independent value being less than the least independent value
in the rating (out of range low), one for the independent value being between the
least and greatest independent values in the rating, inclusive (in range), and one for
the independent value being greater than the greatest independent value in the rating
(out of range high). Only simple ratings with lookup tables use the lookup methods.
Valid lookup methods are:

NULL
----

When specified for out of range low or high method, return NULL for the dependent value
when the independent value is out of range. When specified for in range method, return
NULL for the dependent value if the independent value does not exactly match an independent
value in the rating. For example, when the independent value is a count of gates open, it
makes no sense to specify a fractional gate open count, so return NULL.

ERROR
-----

Same as NULL lookup method, except an exception is raised instead of returning NULL.

LINEAR
------

When used for an in range method, linearly interpolate both independent and dependent values.
When specified as an out of range low or high method, linearly extrapolate both independent
and dependent values.

LOGARITHMIC
-----------

Same as the LINEAR lookup method, except logarithmic interpolation/extrapolation is used if
possible for both independent and dependent values. Linear interpolation/extrapolation is used
where logarithmic is not possible.

LIN_LOG
-------

Same as the LOGARITHMIC lookup method except that logarithmic interpolation/extrapolation is
performed on the dependent values only. Linear interpolation/extrapolation is used for the
independent values.

LOG_LIN
-------

Same as the LOGARITHMIC lookup method except that logarithmic interpolation/extrapolation is
performed on the independent values only. Linear interpolation/extrapolation is used for the
dependent values.

PREVIOUS
--------

Return the dependent value of the rating point whose position in the rating would immediately
precede or be equal to a rating point whose independent value is the value to be rated.
Since CWMS ratings are always stored in order of increasing independent values, this method
is equivalent to the LOWER lookup method.

NEXT
----

Return the dependent value of the rating point whose position in the rating would immediately
follow or be equal to a rating point whose independent value is the value to be rated. Since
CWMS ratings are always stored in order of increasing independent values, this method is
equivalent to the HIGHER lookup method.

NEAREST
-------

Return the dependent value of the rating point whose position in the rating is the nearest
to a hypothetical point containing the independent value being rated. When specified as an
out of range low method, this is equivalent to NEXT. When specified as an out of range high
method, this is equivalent to PREVIOUS. This is not a valid in range method.

LOWER
-----

Return the dependent value of the rating point that has the greatest independent value that
is less than or equal to the independent value to be rated. If no such rating point exists,
raise an exception.

HIGHER
------

Return the dependent value of the rating point that has the least independent value that is
greater than or equal to the independent value to be rated. If no such rating point exists,
raise an exception.

CLOSEST
-------

Return the dependent value of the rating point whose independent value is closer to the
independent value to be rated than any other rating point.
