.. _ratings-templates:

Rating Templates
================

A **rating template** specifies the independent and dependent parameters and the lookup
methods to use for every rating associated with the template (if the rating uses a
lookup table). A rating template identifier is comprised of a list of the parameters and
a version. The parameters list is a comma-separated list of one or more independent
parameters followed by a semi-colon and the dependent parameter. The version is limited
to 32 characters and uniquely identifies the lookup method(s) used with the specified
parameters list. A complete rating template identifier is the parameters list followed
by a period and the version (e.g., Stage;Flow.USGS-shifted or Count-Conduit_Gates,
Opening-Conduit_Gates, Elev-Pool; Flow-Conduit_Gates.Normal).

.. toctree::
    :maxdepth: 1

    Template Identifiers <rating-template-identifiers>
    Rating Parameters <rating-template-parameters>
    Lookup Methods <rating-lookup-methods>
    Rating Template Version <rating-template-version>
