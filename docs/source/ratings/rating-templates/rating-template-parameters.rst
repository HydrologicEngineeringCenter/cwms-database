.. _rating-template-parameters:

Rating Parameters
=================

Rating parameters are the same as parameters used in time series identifiers. Each has
a base parameter portion which is constrained to the list of valid CWMS base parameters
and an optional sub-parameter portion which is unconstrained except for its maximum
length of 32 characters. If a parameter includes a sub-parameter, the sub-parameter is
separated from the base parameter by the hyphen/dash (-) character. Thus the base
parameter `Elev` can be made more specific by adding a sub-parameter, as in `Elev-Tailwater`
or `Elev-Pool`.

Parameter Order
---------------

The parameter order matters when the curve has multiple independent parameters. The
independent parameter closest to the dependent parameter is used on the y-axis when
visually representing the rating within current CWMS applications.

An example Rating Specification with the Rating Template in bold looks like:

`Location.Opening,Elev;Flow.Linear.Step;USACE`

where `Elev` is the independent parameter closest to the dependent parameter in the string
order would be displayed properly as shown in the following figure.

.. image:: /media/ratings/rating-template-parameters-proper-independent-parameter-order-example.png
    :alt: Gate Rating Curve: Proper Independent Parameter Order Example
    :align: center

Where `Opening` is the independent parameter closest to the depending parameter in the
string order would, `Location.Elev,Opening;Flow.Linear.Step;USACE be displayed awkwardly
as seen in the following figure.

.. image:: /media/ratings/rating-template-parameters-improper-independent-parameter-order-example.png
    :alt: Gate Rating Curve: Improper Independent Parameter Order Example
    :align: center

Both representations are correct but one might have more use than the other.

Special Sub-Parameters
----------------------

There are two special cases for sub-parameter for an independent parameter for a
rating template ID. These cases attempt to be more helpful in understanding what the
rating is intended to be used for. A common rating might be making use of the gate
opening, pool elevation and tailwater elevation (independent parameters) to determine
the project outflow (dependent parameter). To differentiate the pool elevation and the
tailwater elevation in the rating template the parameters would be listed as follows:

`Opening,Elev-Downstream,Elev;Flow.Linear`

Where `Elev-Downstream` could be a tailwater gage associated with the project or a
downstream gage while `Elev` is assumed to be associated with the location or
base-location of the dependent parameter when the rating template is used within a
rating specification.

.. list-table:: Naming Tailwater Elements in Rating Curves
    :header-rows: 1
    :widths: 10 30

    * - Parameter ID
      -
    * - Elev-Downstream
      - This could be a tailwater gage associated with the project or a downstream gage
    * - Stage-Downstream
      - This could be a tailwater gage associated with the project or a downstream gage
    * - Elev-Upstream
      - This is not intended to be the project's pool elevation
    * - Stage-Upstream
      - This is not intended to be the project's pool elevation

These parameters are not intended to be used in time-series for storing observed or
derived data. They are intended for use solely within the context of rating template IDs.