.. _rating-effective-creation-dates:

Rating Information
==================

Each rating contains the following information:

Effective Date
--------------

The date and time used to uniquely identify a rating with the rating specification.
This determines if and when this curve will be  used to rate data.

Creation Date
-------------

The date and time that the rating was first known. This information is used when
performing historical ratings (ratings at a past point in time) to filter out
information that was not known at the time. If not specified in the external
representation, this field is set tot he current time when the rating is loaded
into the database. This information is output when ratings are retrieved from the
database to preserve the information.

Active Flag
-----------

If true, the rating is available for use. If false, the rating will not be used in
any rating operation.

Native Units
------------

Specifies the units of the independent and dependent parameters of the external
representation.

Description
-----------

Descriptive text of the rating, limited to 256 characters.