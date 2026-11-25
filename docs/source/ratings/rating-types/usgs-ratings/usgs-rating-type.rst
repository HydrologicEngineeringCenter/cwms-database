.. _usgs-rating-type:

USGS-Style Stream Ratings
=========================

USGS-style stream ratings are comprised by a single stage/discharge lookup table
which defines the base relationship, an optional lookup table of stage/shift
rating points which is used to alter the stage before performing the base lookup,
and an optional lookup table of stage/offset rating points which is used to modify
the logarithmic interpolation between values in the base table.

USGS-style stream ratings specify base rating lookup table, stage shift lookup
table, and interpolation offset lookup table, and were introduced in CWMS 2.1.