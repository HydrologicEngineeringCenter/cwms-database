.. _rating-curves-points:

Rating Curves or Rating Points
==============================

Rating curves are used to associate dependent parameters with independent
parameters for the purpose of converting from what can be measured (independent
value or values) to what can be derived from the measurements (dependent value).

The **rating template** provides a means to identify the independent and
dependent parameters and the inter-point processing when deriving the dependent value.
See :ref:`Rating Templates <rating-templates/index.rst>`.

The **rating specification** defines the application of a rating template at
a location including the processing temporally between curves when deriving the
dependent value. See :ref:`Rating Specifications <rating-specifications/index.rst>`.

A rating contains either the formula, the rating points, or a combination of the two
used to transform the independent parameter values to the dependent parameter values.
Each rating is associated with a rating specification and has an effective date,
which identifies it uniquely with the rating specification. Other information stored
with the rating includes:

    - Creation date
    - Active flag
    - Native units
    - Description

Included in CWMS is the capacity to transition between ratings stored as points and
ratings stored as formulas and vice versa. This feature is not in common use. As
experience is gained with this feature, the naming convention may need to be expanded
to address identification of these types of ratings.

The most common rating in use consists of rating points. When some expertise on storing
a rating curve as a formula is developed within the organization, a naming convention
should be developed.