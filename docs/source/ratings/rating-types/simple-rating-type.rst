.. _simple-rating-type:

Simple Ratings
==============

Simple ratings are definned by either a single lookup table or by a formula. A lookup
table is an ordered set of rating points. A rating point is a set of values, one for
each independent parameter as well as one for the dependent parameter. The dependent
value is known when the independent value(s) match a rating point. Various methods are
provided to determine the dependent value when the independent value(s) do/does not
match a rating point. A formula is a mathematical expression which defines a function
of the independent parameter values.

Simple ratings specify either rating lookup table or a formula and were introduced in
CWMS 2.1.