package net.hobbyscience.math;

import org.opendcs.jas.core.Compiler;
import org.opendcs.jas.core.Node;
import org.opendcs.jas.core.components.RawValue;
import org.opendcs.jas.core.components.Variable;
import org.opendcs.jas.core.operations.Binary;
import org.opendcs.jas.core.operations.Unary;
import net.hobbyscience.database.exceptions.BadMathExpression;

public class EquationInverter {
    public static String invertPostfix(String postfix) {
        Node rhs = Equations.tokensToBin(postfix);
        var lhs = invert(rhs,new Variable("i"));
        var infix = lhs.simplify().beautify().toString();
        return Equations.infixToPostfix(infix);
    }

    public static Node invert(Node rhs, Variable forVar) {
        if (rhs.numNodes()==1) {
            return rhs;
        } else if (rhs.numNodes() == 2) {
            return inverseFor(rhs);
        } else {
            return invertFor((Binary)rhs,forVar);
        }
    }

    private static Node inverseFor(Node op) {
        if( op instanceof Unary) {
            return inverseFor((Unary)op);
        } else if( op instanceof Binary) {
            return inverseFor((Binary)op);
        } else {
            throw new BadMathExpression("Can't handle finding inverse for given Operable" + op.getClass().getName());
        }

    }

    private static Node inverseFor(Unary op) {
        Node ret = null;
        var left = op.getOperand();
        switch(op.getName().toLowerCase()){
            case "log": {
                ret = Compiler.compile("10^"+left.toString());
                break;
            }
            default: {
                throw new BadMathExpression(String.format("Operation '%s' is not supported for inverse.",op.getName()));
            }
        }
        return ret;
    }

    /**
     *
     * @param op operation we want the opposite of
     * @return BinaryOperator with left and right Hand null;
     */
    private static Binary inverseFor(Binary op) {
        if(op.is("*")) {
            return new Binary(null, "/", null);
        } else if(op.is("/")) {
            return new Binary(null,"*",null);
        } else if( op.is("+")) {
            return new Binary(null,"-",null);
        } else if( op.is("-")) {
            throw new BadMathExpression("Keep life simple, convert toAdditionOnly before calling this");
        } else if( op.is("^")) {
            return new Binary(null, "^", new Binary(RawValue.ONE, "/", op.getRight()));
        }

        return op;
    }

    private static Node invertFor(Binary op,Variable forVar) {
        var tmp = op.copy().toAdditionOnly();
        return invertFor(forVar,tmp,forVar);
    }

    private static Node invertFor(Node lhs, Node op,Variable forVar) {
        if( op.equals(forVar)) {
            return lhs;
        } else if (op instanceof Binary) {
            return invertFor(lhs,(Binary)op,forVar);
        }

        return lhs;
    }

    private static Node invertFor(Node lhs, Binary op,Variable forVar) {
        var startLeft = op.getRight().levelOf(forVar) > 0;
        var inverse = inverseFor(op);
        var exponent = inverse.is("^");
        if( inverse.is("^") && startLeft) {
            throw new BadMathExpression("We haven't implemented solving for variable inside exponent yet");
        }

        if( startLeft ) {
            inverse.setLeft(lhs);
            inverse.setRight(op.getLeft());
            lhs = inverse;
            return invertFor(lhs,op.getRight(),forVar);
        } else {            
            inverse.setLeft(lhs);
            if( !exponent) {
                // already taken care of
                inverse.setRight(op.getRight());
            }

            lhs = inverse;
            return invertFor(lhs,op.getLeft(),forVar);
        }
    }
}
