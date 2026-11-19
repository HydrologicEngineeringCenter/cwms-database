.. _ratings:

Ratings Overview
================



.. note::
    As of CWMS version 2.1, the CWMS Oracle database supports the
    storage, retrieval, cataloging and deleting of ratings
    via an application programming interface (API) specified in the
    CWMS_RATING package. In addition, the API also provides numerous
    routines to apply ratings. Several views also exist to allow users
    and developers to easily see the stored ratings. CWMS ratings have
    one or more independent (input) parameters and a single output
    (dependent) parameter. Currently the code allows up to nine
    independent parameters while the views will display up to five
    independent parameters. CWMS 3.1 adds support for new types of
    ratings which are constructed from the rating types included in CWMS
    2.1.

.. toctree::
    :maxdepth: 1

    Overview <overview/index>
    Rating Templates <rating-templates/index>
    Rating Specifications <rating-specifications/index>
    Rating Types <rating-types/index>
    Rating Examples <rating-examples/index>
