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

**NULL.** When specified for out of range low or high method, return NULL for the
dependent value when the independent value is out of range. When specified for in range
method, return NULL for the dependent value if the independent value does not exactly
match an independent value in the rating. For example, when the independent value is
a count of gates open, it makes no sense to specify a fractional gate open count,
so return NULL.

**ERROR.** Same as NULL lookup method, except an exception is raised instead of
returning NULL.

**LINEAR.** When used for an in range method, linearly interpolate both independent and
dependent values. When specified as an out of range low or high method, linearly
extrapolate both independent and dependent values.

**LOGARITHMIC.** Same as the LINEAR lookup method, except logarithmic
interpolation/extrapolation is used if possible for both independent and dependent values.
Linear interpolation/extrapolation
