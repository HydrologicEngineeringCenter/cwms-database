.. _time-series-ratings:

Time Series of Ratings
======================

Multiple ratings with different effective dates can share a common rating specification,
which contains lookup methods that determine the behavior of applying the ratings to
independent values at a given time. Common in-range methods are PREVIOUS and LINEAR.
PREVIOUS or NEAREST, which have the same effect, are common for out-of-range-high.
The out-of-range-low method is commonly NEXT or NEAREST, which have the same effect,
or NULL or ERROR.

Specifying LINEAR for an in-range method causes the API to linearly interpolate between
the two ratings whose effective times bound the time of the value(s) to be rated. For
USGS-style stream ratings, the situation is more complicated. If the time of the value
to be rated is on or before the effective date of the latest shift of the previous
rating, then the previous rating is used, interpolating the shifts as necessary. If the
time of values to be rated is after the effective date latest shift of the previous
rating, then the interpolation occurs in the time span between the effective date of the
latest shift of the previous rating and the effective date of the next rating,
interpolating flows as necessary.

It is sometimes desirable to transition from one rating to another or from one shift to
another on USGS-style ratings over a much shorter time span prior to the new rating or
shift than the LINEAR lookup method would provide. This can be accomplished by duplicating
the previous rating or shift and setting the effective date of the duplicate to the start
of the desired transition time. This will cause the rating to remain constant in the
period between the effective dates of the original and duplicate ratings or shifts and
to transition linearly between the effective dates of the duplicate and next rating or shift.