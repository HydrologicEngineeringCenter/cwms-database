.. _rating-specification-version:

Rating Specification Version
============================

The rating specification includes the ability to define the explicit interpolation behavior
between temporal curves. It also includes the ability to define the explicit extrapolation
behavior before the first curve and after the last curve in the family of curves. Each rating
curve is assigned an effective date, which is used to determine if and when this curve will be
used to rate data.

The most common interpolation or extrapolation behavior between temporal curves are:

- When the curve is updated the method used for values which fall between the curves is to use
  the newest curve. When this is the interpolation behavior, Step is the expected Version value.
- When the curve is updated the method used for values which fall between the curves is to
  linearly interpolate between the old curve and the new curve. When this is the interpolation,
  Distributed is the expected Version Value.

For these common parameter combinations the recommended rating template versions and associated
interpolation behaviors are shown in the following table.

.. list-table:: Recommended Rating Specification Versions (Between Curve Behavior)
    :header-rows: 1
    :widths: 10 15 15 15

    * - Version Value
      - In Range (within curve)
      - Out of Range Low (below the curve)
      - Out of Range High (above the curve)
    * - Step
      - Previous
      - Null
      - Previous
    * - Distributed
      - Linear
      - Null
      - Previous

Example rating specifications are:

    Loc1.Stage;Flow.Log.Step;USGS
    Loc1.Stage;Flow.Log.Distributed;USGS

Where Step or Distributed would be identified as the Rating Specification version based
on how the local office would like the data interpreted.

The step interpolation will always use the newest rating curve available before the
timestamp of the independent data to rate the value, with no concern for other rating
curves in the database. This will show jumps or "Steps" in the dependent data set whenever
a new rating curve becomes available. The distributed interpolation will use the rating
curve before and the rating curve after the timestamp of the independent data to pro-rate
the change between the before and after curve. This smooths or "Distributes" the jump in
the dependent data set equally over the values between the two curves.

The figure below shows the step and distributed behavior over a time period. This stage data
set in green is accompanied by two rating curve shifts that occurred on September 1 and
September 17. The Flow data in red displays the step behavior in which the rating curve from
shift 1 is applied for the entire period of September 1 through September 17. Once the new
rating curve becomes available after the September 17 shift, the new curve will be used from
September 17 forward and jump or "Step" in the flow data record will be present. The Flow
data in blue displays the distributed behavior where the difference between the first shifted
rating and second shift is equally distributed over each value between the curves.

.. image:: /media/ratings/step-and-distributed-rating-specification-behavior-example.png
    :alt: Step and Distributed Rating Specification Behavior Example
    :align: center

Both Distributed and Step temporal interpolations have proper and improper uses. The table
below provides the suggested uses of the temporal distributions for a variety of different
curves. Offices are welcome to deviate from the suggested distributions, but the offices
should have an expert understanding of the temporal distributions before doing so. Improperly
choosing a temporal distribution could cause problems.

When creating a rating specification if the interpolation behavior is Previous-Null-Previous,
the version value is expected to be Step.

If the interpolation behavior is Linear-Null_Previous, the version value is expected to be
Distributed.

If the interpolation behavior is defined as anything other than these two options, the rating
specification version value is expected to be Custom. When the rating specification term is
Custom, the user should be allowed to add a dash delimiter and add free-form text to define
or identify what Custom is indicating.

The following table lists the custom options available. Refer to the Rating Table Editor
documentation for a complete discussion of the interpolation and extrapolation behavior
between rating curves.

.. list-table:: Custom Temporal Behaviors for Rating Specification Versions (Between Curve Behavior)
    :header-rows: 1
    :widths: 10 15 15 15

    * - Value
      - In Range (between curves)
      - Out of Range Low (before the first curve)
      - Out of Range High (after the last curve)
    * - Null
      - X
      - X
      - X
    * - Error
      - X
      - X
      - X
    * - Linear
      - X
      - X
      - X
    * - Logarithmic
      -
      -
      -
    * - LinLog
      -
      -
      -
    * - LogLin
      -
      -
      -
    * - Previous
      - X
      -
      - X
    * - Next
      - X
      - X
      -
    * - Nearest
      -
      - X
      - X
    * - Lower
      - X
      -
      - X
    * - Higher
      - X
      - X
      -
    * - Closest
      - X
      - X
      - X

An example custom specification version is:

    Cairo.Stage;Flow.Linear.Custom-Closest

Where Custom-Closest is specified as

    In Range: **Closest**
    Out of Range Low: **Closest**
    Out of Range High: **Closest**

Currently, when defining a rating specification, the user has the ability to select the
**Source** for the rating. The Source should be appended at the end of the rating
specification version following a semi-colon delimiter. The CWMS database should maintain
a list of common sources including: USGS, USACE, TVA, BOR, etc. Local Offices may add a
source for state and local agencies, regional water districts and other agencies.

Recommendation: add terms USGS-Base and USGS-Expanded as additional pre-loaded sources
due to their widespread usage and familiarity.

Example recommended Rating Specification IDs:

One independent parameter:
    Cougar.Elev;Stor.Linear.Step;USACE
    Goshen.Stage;Flow.Log.Step;USGS
    Goshen.Stage;Flow.Log.Step;USGS-Base

Two independent parameters:
    Gavins Point-Spillway.Opening,Elev;Flow.Linear.Step;USACE
    Gavins Point-Spillway-Tainters.Opening,Elev;Flow.Linear.Step;USACE
    Detroit-Spillway-slides.Opening,Elev;Flow.Linear.Step;USACE
