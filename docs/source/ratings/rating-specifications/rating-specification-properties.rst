.. _rating-specification-properties:

Rating Specification Properties
===============================

A rating specification has the following properties:

Source Agency
-------------

Specifies the agency, company, or organization that is the authoritative source for ratings
associated with this rating specification.

Active Flag
-----------

If false, no ratings associated with this rating specification will be used to rate data. If false,
ratings associated with this rating specification may be used, but note that individual ratings
may also be specified as active or inactive.

Auto Update Flag
----------------

If true, any automatic ratings update mechanism should load ratings associated with this rating
specification into the database as soon as they are available.

Auto Activate Flag
------------------

If true, any automatically loaded ratings associated with this rating specification should be
marked as active. If false, any automatically loaded ratings associated with this rating
specification should be marked as inactive.

Auto Migrate Extension Flag
---------------------------

If true, any automatically loaded ratings associated with this rating specification should have
any rating extension present on the next most recent rating applied to the newly loaded rating.

Rounding Specifications
-----------------------

USGS-style rounding criteria strings for each independent parameter, as well as for the dependent
parameter. Each rounding specification is a 10 digit string, with the first 9 digits specifying
the number of significant digits (not decimal places) the parameter should be rounded to for the
magnitude indicated by the digit's position in the string. The first digit indicates a magnitude
of less than .01, and the ninth digit indicates a magnitude of greater than or equal to 100,000.
Intermediate digits specify magnitudes of increasing powers of 10 from left to right. The last
digit specifies the maximum number of decimal places to be displayed for any magnitude.

For example, the rounding specification 2233344332 indicates the following:

.. list-table:: Formatting of example rounding specification of 2233344332
    :header-rows: 1
    :widths: 15 15

    * - Value
      - Rounded to significant digits
    * - value < 0.1
      - 2
    * - 0.1 <= value < 100
      - 3
    * - 100 <= value < 10,000
      - 4
    * - 10,000 <= value
      - 3

For all values, no more than 2 decimal places should be displayed. Ratings downloaded from the
National Weather Service NWIS ratings depot include rounding specifications for each parameter.

Description
-----------

Descriptive text about the rating specification, limited to 256 characters.