.. _virtual-rating-examples:

Virtual Rating Examples
=======================

Example 1
---------

Consider a virtual rating with one independent parameter - measured stage - and a
dependent parameter of flow with the following source ratings and connections string:

    - R1 is a rating with an independent parameter of measured stage and a dependent
      parameter of stage correction.
    - R2 is a formula which adds its 1st input - measured stage - to its 2nd input -
      stage correction - to generate an output of corrected stage.
    - R3 is a rating with an independent parameter of corrected stage and a dependent
      parameter of flow.
    - The connection string is R2I1=I1,R2I2=R1D,R3I1=R2D

The source rating connection points R1D, R2I1, R2I2, R2D, and R3I1 are all specified in
the connection string, leaving the source rating connection points R1I1 and R3D
unspecified. The last unspecified source rating connection point in order, R3D, becomes
the dependent parameter for the source rating, and R1I1 is connected by default to I1.

