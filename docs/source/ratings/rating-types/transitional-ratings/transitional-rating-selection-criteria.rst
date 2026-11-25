.. _transitional-rating-selection-criteria:

Transitional Rating Selection Criteria
======================================

Transitional rating selection criteria are comprised of an ordered list of zero or more
*logical expressions*, with an *evaluation* associated with each expression, followed
by a default evaluation. The logical expressions are tested in order, using the current
set of independent parameter values. If an expression yields "True" when tested, then
the evaluation associated with that expression is performed to generate the dependent
parameter value for the transitional rating and the selection process ceases. If none of
the expressions yield "True" when tested, then the default evaluation is performed to
generate the dependent parameter value for the transitional rating.

Logical Expressions
-------------------

Logical expressions are expressions that evaluate to **True** or **False**. They are
comprised of mathematical expressions (see :ref:`rating-formulas`) combined with
the following comparison and combination operators:

+--------------------------+--------------------+-------------------------------------+
| Operator                 | Class              | Description                         |
+===============+==========+====================+=====================================+
| =             | EQ       | comparator         | equal to                            |
+-------+-------+----------+--------------------+-------------------------------------+
| !=    | <>    | NE       | comparator         | not equal to                        |
+-------+-------+----------+--------------------+-------------------------------------+
| >             | GT       | comparator         | greater than                        |
+---------------+----------+--------------------+-------------------------------------+
| >=            | GE       | comparator         | greater than or equal to            |
+---------------+----------+--------------------+-------------------------------------+
| <             | LT       | comparator         | less than                           |
+---------------+----------+--------------------+-------------------------------------+
| <=            | LE       | comparator         | less than or equal to               |
+---------------+----------+--------------------+-------------------------------------+
| AND                      | combinator         | conjunction                         |
+--------------------------+--------------------+-------------------------------------+
| OR                       | combinator         | disjunction (inclusive)             |
+--------------------------+--------------------+-------------------------------------+
| XOR                      | combinator         | disjunction (exclusive)             |
+--------------------------+--------------------+-------------------------------------+
| NOT                      | combinator         | negation                            |
+--------------------------+--------------------+-------------------------------------+

Logical expressions may be specified in infix (algebraic) or postfix (RPN) notation, but
notations may not be mixed in the same expression.

    - ``I3 < 11.1 AND I1 - I2 < 7.5``    correct (infix)
    - ``I3 11.1 < I1 I2 - 7.5 < AND``    correct (postfix)
    - ``I3 < 11.1 AND I1 I2 - 7.5 <``    incorrect (mixed notation)

If multiple combinators are included in infix notation, attention must be paid to operator
precedence: NOT, AND, XOR, OR. NOT has the highest precedence and so binds the most tightly
to its argument; OR has the lowest precedence and so binds the least tightly to its
arguments. Parentheses may be used to alter the order of operations. All mathematical
operators have higher precedence than any comparison operator, and all comparison operators
have higher precedence than any combination operator.

Evaluations
-----------

Each evaluation is a formula as defined in :ref:`rating-formulas`.
