package cwms.units;

import java.util.ArrayDeque;
import java.util.Deque;

import jmc.cas.BinaryOperation;
import jmc.cas.Operable;
import jmc.cas.RawValue;
import jmc.cas.UnaryOperation;
import jmc.cas.Variable;
import net.hobbyscience.database.exceptions.BadMathExpression;
import net.hobbyscience.math.Equations;
import net.objecthunter.exp4j.tokenizer.NumberToken;
import net.objecthunter.exp4j.tokenizer.OperatorToken;
import net.objecthunter.exp4j.tokenizer.Token;
import net.objecthunter.exp4j.tokenizer.VariableToken;

public class Reducer {
    


    public static String reduce(String equation) {
        var operations = tokensToBin(equation);
        operations = operations.simplify();        
        var infix = operations.beautify().toString();
        return Equations.infixToPostfix(infix);
    }

    public static Operable tokensToBin(String equation) {
        // just gotta go through the stack
        Token current = null;
        
        Deque<Token> tokens = Equations.stringToTokens(equation);

        Deque<Operable> stack = new ArrayDeque<>(3);
        while ((current = tokens.pollFirst()) != null) {
            switch(current.getType()) {
                case Token.TOKEN_NUMBER: {
                    stack.add(new RawValue(((NumberToken)current).getValue()));
                    break;
                }
                case Token.TOKEN_VARIABLE: {
                    stack.add(new Variable(((VariableToken)current).getName()));
                    break;
                }
                case Token.TOKEN_OPERATOR: {
                    var tmp = (OperatorToken)current;
                    var numOperands = tmp.getOperator().getNumOperands();
                    switch (numOperands) {
                        case 1: {
                            var operand = stack.pollLast();
                            var op = new UnaryOperation(operand, tmp.getOperator().getSymbol());
                            stack.add(op);
                            break;
                        }
                        case 2: {
                            var right = stack.pollLast();
                            var left = stack.pollLast();
                            var op = new BinaryOperation(left, tmp.getOperator().getSymbol(), right);
                            stack.add(op);
                            break;
                        }
                    }
                    break;
                }
                default: {
                    throw new BadMathExpression("Element " + current.toString() + " not yet implemented");
                }
            }
        }
        if( stack.size() == 1 ) {
            return stack.poll();
        } else {
            throw new BadMathExpression(String.format("Not all elements of the provided equation '%s' where converted",equation) );
        }
        
    }
}
