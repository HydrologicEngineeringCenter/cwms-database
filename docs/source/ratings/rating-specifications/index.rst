.. _ratings-specifications:

Rating Specifications
=====================

A rating specification specifies a location, a rating template, and a set of characteristics.
A version identifier labels the set of characteristics associated with the location and rating
template. A complete rating specification identifier includes the CWMS location identifier,
rating template identifier, and rating specification version separated by the period (.) character
(e.g. ``TULA.Stage;FLOW.USGS-shifted.Production``, or ``ARCA.Count-Conduit_Gates,Opening-Conduit_Gates,
Elev-Pool;Flow-Conduit_Gates.Normal.Production``).

.. toctree::
    :maxdepth: 1

    Specification Identifiers <rating-specification-identifiers>
    Effective Dates and Temporal Behavior <rating-specification-effective-dates>
    Step vs. Distributed Behavior <rating-specification-temporal-behaviors>
    Specification Properties <rating-specification-properties>
