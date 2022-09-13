package net.hobbyscience.math;

import jmc.cas.BinaryOperation;
import jmc.cas.Expression;
import jmc.cas.Operable;
import jmc.cas.Operation;
import jmc.cas.RawValue;
import jmc.cas.UnaryOperation;
import jmc.cas.Variable;
import jogamp.opengl.glu.nurbs.Bin;
import net.hobbyscience.database.exceptions.BadMathExpression;

public class EquationInverter {
    public static String invertPostfix(String postfix) {
        Operable rhs = Equations.tokensToBin(postfix);
        var lhs = invert(rhs,new Variable("i"));
        var infix = lhs.simplify().beautify().toString();
        return Equations.infixToPostfix(infix);
    }

    public static Operable invert(Operable rhs,Variable forVar) {
        if (rhs.numNodes()==1) {
            return rhs;
        } else if (rhs.numNodes() == 2) {
            return inverseFor(rhs);
        } else {
            return invertFor((BinaryOperation)rhs,forVar);
        }
    }

    private static Operable inverseFor(Operable op) {
        if( op instanceof UnaryOperation) {
            return inverseFor((UnaryOperation)op);
        } else if( op instanceof BinaryOperation) {
            return inverseFor((BinaryOperation)op);
        } else {
            throw new BadMathExpression("Can't handle finding inverse for given Operable" + op.getClass().getName());
        }

    }

    private static Operable inverseFor(UnaryOperation op) {
        Operable ret = null;
        var left = op.getLeftHand();
        switch(op.getName().toLowerCase()){
            case "log": {
                ret = Expression.interpret("10^"+left.toString());
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
    private static BinaryOperation inverseFor(BinaryOperation op) {
        if(op.is("*")) {
            return new BinaryOperation(null, "/", null);
        } else if(op.is("/")) {
            return new BinaryOperation(null,"*",null);
        } else if( op.is("+")) {
            return new BinaryOperation(null,"-",null);
        } else if( op.is("-")) {
            throw new BadMathExpression("Keep life simple, convert toAdditionOnly before calling this");
        } else if( op.is("^")) {
            return new BinaryOperation(null, "^", new BinaryOperation(RawValue.ONE, "/", op.getRightHand()));
        }

        return op;
    }

    private static Operable invertFor(BinaryOperation op,Variable forVar) {
        var tmp = op.copy().toAdditionOnly();
        return invertFor(forVar,tmp,forVar);
    }

    private static Operable invertFor(Operable lhs, Operable op,Variable forVar) {
        if( op.equals(forVar)) {
            return lhs;
        } else if (op instanceof BinaryOperation) {
            return invertFor(lhs,(BinaryOperation)op,forVar);
        }

        return lhs;
    }

    private static Operable invertFor(Operable lhs, BinaryOperation op,Variable forVar) {
        var startLeft = op.getRightHand().levelOf(forVar) > 0;
        var inverse = inverseFor(op);
        var exponent = inverse.is("^");
        if( inverse.is("^") && startLeft) {
            throw new BadMathExpression("We haven't implemented solving for variable inside exponent yet");
        }

        if( startLeft ) {
            inverse.setLeftHand(lhs);
            inverse.setRightHand(op.getLeftHand());
            lhs = inverse;
            return invertFor(lhs,op.getRightHand(),forVar);
        } else {            
            inverse.setLeftHand(lhs);
            if( !exponent) {
                // already taken care of
                inverse.setRightHand(op.getRightHand());
            }

            lhs = inverse;
            return invertFor(lhs,op.getLeftHand(),forVar);
        }
    }
}
