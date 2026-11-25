.. _virtual-rating-type:

Virtual Ratings
===================

Virtual ratings are ratings that are assembled by connecting the independent and/or
dependent parameters of two or more source ratings in order to create a rating that will
perform multiple rating steps in a single API call.

Each source rating may be a reference to another rating in the database or a formula
that defines a function of its input values. Source rating formulas are functionally
equivalent to source ratings referencing formula-based simple ratings. Formula-based
source ratings are often necessary to combine by addition or multiplication the outputs
of other source ratings into either the virtual rating output or the input to another
source rating.

Virtual ratings specify source ratings and rating parameter connections and were
introduced in CWMS 3.1.

.. toctree::
    :maxdepth: 1

    Virtual Rating Source Ratings <virtual-rating-source-ratings>
    Virtual Rating Connections <virtual-rating-connections>
    Virtual Rating Examples <virtual-rating
