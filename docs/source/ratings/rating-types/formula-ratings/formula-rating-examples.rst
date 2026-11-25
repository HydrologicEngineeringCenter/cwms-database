.. _rating-formula-example:

Rating Formula Example
======================

Assume we need to use the formula :math:`Q = C_s L h_s \sqrt{2gh}` to compute the flow
through submerged gates. Given the following definitions and independent parameters,
the mathematical expressions would be as shown.

**Definitions:**

    :math:`C_s` = submerged gate coefficient

    :math:`L` = :math:`60.0 ft`

    :math:`h` = pool elevation - tailwater elevation in feet

    :math:`h_s` = tailwater elevation in feet - sill elevation (:math:`506.0 ft`)

    :math:`g` = acceleration due to gravity (:math:`32.2 ft/sec^2`)

**Parameters:**

    Independent parameter 1: Elev-Pool

    Independent parameter 2: Elev-Tailwater

    Independent parameter 3: Coeff-Gate-Submerged

**Native Units:**

    Native units for the rating would be ft, ft, n/a, and cfs. Other units could be
    specified and/or requested and the rating procedure would handle the unit
    conversions, ensuring the appropriate units are used with the formula.

**Expressions:**

    Infix (Algebraic):

        ``I3 * 60 * (I2 - 506) * SQRT(64.4 * (I2-I1))``

    Postfix (RPN):

        ``I2 I1 - 64.4 * SQRT I2 506 - * 60 * I3 *``
