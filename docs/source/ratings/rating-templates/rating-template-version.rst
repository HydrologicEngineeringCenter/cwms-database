.. _rating-template-version:

Rating Template Version
=======================

The rating template includes the ability to define the interpolation behavior between
points on a curve. It also includes the ability to define the explicit extrapolation
behavior above and below the curve.

Some common rating parameter combinations for water managers are:

    - ``Stage;Flow``
    - ``Elevation;Storage``
    - ``Elevation;Area``
    - ``Opening,Elev;Flow``

For these common parameter combinations, the recommended template versions and their
associated interpolation behaviors are shown in the following table.

.. list-table:: Recommended Rating Template Versions (Between Points Interpolation)
    :header-rows: 1
    :widths: 10 15 15 15

    * - Version Value
      - In Range (within curve)
      - Out of Range Low (below the curve)
      - Out of Range High (above the curve)
    * - Linear
      - Linear
      - Null
      - Null
    * - Log
      - Log
      - Null
      - Null

An example rating template with one independent parameter is:

``Stage;Flow.Log``

An example rating template with two independent parameters is:

``Opening,Elev;Flow.Linear``

Within the rating template, one can define the interpolation behavior for multiple
independent parameters. If the interpolation behavior is Linear-Null-Null for every
independent parameter the rating specification version value is expected to be ``Linear``.

If the interpolation behavior is Log-Null-Null for every independent parameter the
rating template version value is expected to be ``Log``.

If the interpolation behavior is defined as anything other than these two options the
rating template version value is expected to be ``Custom``. When the rating template
term is Custom, the user should be allowed to add a dash delimiter and add free-form text
to define or identify what Custom is indicating.

The following table provides the custom interpolation options that are available.

.. list-table:: Recommended Rating Template Versions (Between Points Interpolation)
    :header-rows: 1
    :widths: 10 15 15 15

    * - Version Value
      - In Range (within curve)
      - Out of Range Low (below the curve)
      - Out of Range High (above the curve)
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
      - X
      - X
      - X
    * - LinLog
      - X
      - X
      - X
    * - LogLin
      - X
      - X
      - X
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

Refer to the rating table editor documentation for a complete discussion of the
interpolation and extrapolation behavior between points in a rating curve.

An example custom rating template with one independent parameter is:

``Stage;Flow.Custom-Extrapolate``

Where Custom-Extrapolate represents:

    - In Range: **Linear**
    - Out of Range Low: **NULL**
    - Out of Range High: **Linear**