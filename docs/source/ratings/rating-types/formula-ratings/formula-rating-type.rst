.. _rating-formulas:

Rating Formulas
===============

A formula-based rating specifies a mathematical expression that includes a variable
for each of the independent parameters, by position, to be used. The variable name for
the first independent parameter is **I1**, the name for the second is **I2**, etc.
Negated variables in the format **-I1**, **-I2**, etc. are allowed. (ARG1..ARGn, as
well as $1..$n are allowed, but generated XML will always have the normalized format of
I1..In). The mathematical expressions may be specified in infix notation (algebraic
notation) or postfix notation (reverse polish notation, or RPN). All numbers, variables,
operators, and function names must be separated from all others by at least one space,
with the exception that no spaces are required adjacent to parentheses (infix notation
only, postfix notation does not use parentheses). Mathematical expressions are not case
sensitive.

.. toctree::
    :maxdepth: 1
    :hidden:

    Rating Formula Example <formula-rating-examples>

Operators
---------

The following operators are supported. All operators are binary (take two arguments).

    :math:`+`  addition

    :math:`-`  subtraction

    :math:`*`  multiplication

    :math:`/`  division

    :math:`//` integer division

    %  modulus

    ^  exponentiation

Functions
---------

The following functions are supported. All functions are unary (take one argument).

    **ABS**    absolute value

    **ACOS**   arc cosine

    **ASIN**   arc sine

    **ATAN**   arc tangent

    **CEIL**   ceiling - smallest integer greater than or equal to argument

    **COS**    cosine

    **EXP**    exponent - e raised to the power of the argument

    **FLOOR**  floor - largest integer less than or equal to argument

    **INV**    inverse

    **LN**     natural logarithm - logarithm base e

    **LOG**    logarithm base 10

    **NEG**    negation

    **ROUND**  round to nearest integer

    **SIGN**   signum - sign of argument returned as -1, 0, or 1

    **SIN**    sine

    **SQRT**   square root

    **TAN**    tangent

    **TRUNC**  truncation - integer portion of argument

Constants
---------

The following constants are supported.

    **PI** the ratio of a circle's circumference to its diameter

    **E** Euler's number - the bse of the natural logarithm


