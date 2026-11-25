.. _rating-extensions:

Rating Extensions
=================

A USGS-style stream rating may include a separately-specified lookup table of stage/discharge
values called a rating extension. A rating extension specifies rating points (extension
points) outside the base stage/discharge lookup table and is used to provide historic high
(normally) or low stage/discharge values. When a rating with an extension is applied, the base
lookup table is first extended above and/or below its specified range by including the
appropriate extension points. Any extension points that are within the range of the base
rating table are ignored.