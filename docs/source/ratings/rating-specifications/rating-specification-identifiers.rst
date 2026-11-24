.. _rating-specification-identifiers:

Rating Specification Identifiers
================================

A rating specification includes a location, a rating template, and a text field to allow
for creating unique rating specification IDs.

.. image:: /media/ratings/rating-specification-id.png
    :alt: Rating Specification ID Example
    :align: center

Other information associated with a rating specification includes :

    - Source agency;
    - Whether the rating is currently active;
    - Behavior selections for when a new rating (with an initial effective date) is added to the database;
    - Identifying the methods for interpolation between curves and extrapolation for data before the first
      curve or after the last curve; and
    - Rounding rules for the returned values.

These topics are discussed further in :ref:`Specification Properties <rating-specification-properties>`.