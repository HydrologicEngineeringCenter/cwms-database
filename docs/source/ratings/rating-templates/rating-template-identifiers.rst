.. _rating-template-identifiers:

Rating Template Identifiers
===========================

A rating template identifier includes the independent and dependent parameters
and a text field to allow for creating unique templates.

.. image:: /media/ratings/rating-template-id.png
    :alt: Rating Template ID Example
    :align: center

The information associated with a rating template includes identifying the methods
for interpolation between points on a curve and extrapolation for points below and
above the curve.

The independent parameters are the first portion of the rating template. When there
is more than one independent parameter, a comma is used to separate them. A semi-colon
is used to identify that the next parameter is the dependent parameter. The independent
and dependent parameters are standard CWMS parameter IDs. The dependent parameter is
followed by a 'dot' and then the rating template version, a text field, is specified.
Parameters used within a rating template do not have to exactly match the parameters
of the input data, although it is suggested for most simple applications.

``<Independent Parameter(s)>;<Dependent Parameter>.<Version>``

