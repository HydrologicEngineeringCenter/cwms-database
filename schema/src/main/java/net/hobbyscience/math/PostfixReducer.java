package net.hobbyscience.math;

import java.util.ArrayDeque;
import java.util.Deque;
import java.util.HashMap;

import net.hobbyscience.database.exceptions.BadMathExpression;
import net.objecthunter.exp4j.operator.Operator;
import net.objecthunter.exp4j.tokenizer.NumberToken;
import net.objecthunter.exp4j.tokenizer.OperatorToken;
import net.objecthunter.exp4j.tokenizer.Token;
import net.objecthunter.exp4j.tokenizer.VariableToken;

/**
 * Reduce a postfix expression to the smallest possible number of operations allowed given the information.
 * 
 * for Example MW -> W results in a conversion of i 1000 * 0 + 1000 * 0 + with the current graph search.
 * This can be simplified to i 1000000 * 0 + or even i 1000000 * 
 * 
 * The rough algorithm is as follows:
 * - go through the equation provided (rhs) in FIFO push on the the lhs stack (each new element last.)
 * - once an operator is found put said operation the holdOp register.
 * - pop that lhs stack LIFO to the holdStack until lhs is empty. (will end up in reverse order)
 * - for each element on the hold stack pop onto varStack FIFI -> LIFO
 * - (now it gets complicated)
 * - if varStack.size() == holdOp.size() && we only have values (variable or number)
 * -     pop to reg stack and apply operator or unwind to resultStack
 * - if holdStack element is an operator:
 *       determine what we have to do with the operator. If equiv to *(a+b) we deuplicate the last value from the varStack as we app
 * 
 * 
 * example: i 2 * 3 + 4 * 5 - (whitespace left out below for sizing.) "i" is just a variable
 * becomes: i 8 * 7 -
 * # | lhs      |      rhs  |holdOp| resultStack | holdStack | varStack | regStack | comment
 * 1 | i        |  2*3+4*5- |      |             |           |          |          |
 * 2 | i2       |  *3+4*5-  |      |             |           |          |          |
 * 3 |          | 3+4*5-    | *    |             | 2i        |          |          |
 * 4 |          | ignore    | *    |             | i         | 2        |          |
 * 5 |          |           | *    |             |           | 2i       |          |
 * 6 |          |           |      |             |           | i2       | i2       |since one of these is a variable this is as reduced as possible
 * 7 |          |           | *    | 2i          |           |          |          | hold stack empty, unwind to resultStack
 * 8 | i2*      | 3+4*5-    |      |             |           |          |          | current thought is if lhs(top) is var/num push holdOp, if op, do not was applied
 * 9 | i2*3     | +4*5-     |      |             |           |          |          |
 * 10|          | 4*5-      | +    |             | 3*2i      |          |          |
 * 11|          |           | +    |             | *2i       | 3        |          |
 * 12|          |           | +    | 3*          | 2i        |          |          | we have to know that 3+ does nothing with the *
 * 15| i2*3+    | 4*5-      |      |             |           |          |          | would just go through the process and then unwind. Possible instead of holdOp and 
 *                                                                                   resultStack should just be resultStack where the "holdOp" is always the first, as we 
 *                                                                                   sometimes just need to know the that plus the last operator in resultStack
 * 16| i2*3+4   | *5-       |      |             |           |          |          |
 * 17|          | 5-        | *    |             | 4+3*2i    |          |          | now it gets interesting. the 4 is applied to the 3 and 2 (i2*)
 * 18|          |           | *    |             | +3*2i     | 4        |          |
 * 19|          |           | *    | +           | 3*2i      | 4 4      |          | (*,+) dup the value but skip the evaluation this cycle (we have to know the (a+b)*c -> ac + bc) and that's what's happening
 * 20|          |           | *    | +           | *2i       | 4 4 3    |          | can now move to regStack
 * 21|          |           | *    | +           | *2i       | 4        | 3 4      |
 * 22|          |           | *    | +12         |           | 4        |          | why do we know we must do *this" here in the case of +.
 * 23|          |           | *    | +12*        | 2i        | 4        |          | (*,*) just store operator
 * 24|          |           | *    | +12*        | i         | 4 2      |          |
 * 25|          |           | *    | +12*        | i         |          | 2 4      |
 * 25|          |           | *    | +12*8       | i         |          |          | or should it go back to the varStack/stay in reg stack
 * 26|          |           | *    | +12*8       |           | i        |          |
 * 27|          |           | *    | +12*8i      |           |          |          | holdstack empty nothing to do, unwind
 * 30|i8*12+    | 5-        | *    |             |           |          |          |
 * <skipped>
 * 35(ish)|     |           | -    |             |  5+12*i8  |          |          |
 * 36|          |           | -    |             |  +12*i8   | 5        |          | 
 * 37|          |           | -    | +           |  12*i8    | 5        |          |
 * 38|          |           | -    | +           |  *i8      | 5 12     |          | fun question what if both negative? we never get "negative" values just "value -" 
 *                                                                                   have to track (-,+) (+,-), (-,-), etc including with * and /
 * 39|          |           | -    | +           | *i8       |          | 12 5     | just do the subtraction (what if 5-12 though and it was negative)
 * 40|          |           | -    | +7          | *i8       |          |          | why do we know this doesn't propagate? if we put back in regStack(bottom) would confuse next up but what if next op +/- and needs it
 * 41|          |           | -    | +7*         | i8        |          |          | now it will just unwind
 * 42|8i*7+     |           |      |             |           |          |          | lhs(top) is op, ignore hold op.
 */
public class PostfixReducer {
    private static final HashMap<String,Boolean> opMap = new HashMap<>();
    static {    
        opMap.put("*,+", true);
        opMap.put("*,*", false);
        opMap.put("/,+", true);
        opMap.put("+,+", false);
        opMap.put("-,+",false);
        opMap.put("-,-",false);
        opMap.put("+,-",false);
        opMap.put("*,/",false);
        opMap.put("/,*",false);
        opMap.put("+,*",false);
    };

    Deque<Token> rhs = null;
    Deque<Token> lhs = new ArrayDeque<>(10);
    OperatorToken holdOp = null;
    Deque<Token> returnStack = new ArrayDeque<>(10);
    Deque<Token> holdStack = new ArrayDeque<>(10);
    Deque<Token> varStack = new ArrayDeque<>(4);
    Deque<Token> regStack = new ArrayDeque<>(4);
    
    /**
     * TODO: actually implement this!
     * @param postfix postfix expression that needs to be reduced to as few operations as possible.
     * @return a version of the expression with the fewest operations possible
     */
    public String reduce( String postfix ){
        rhs = Equations.stringToTokens(postfix);
                          
        Token token = null;
        while ((token = rhs.pollFirst()) != null) {
            switch (token.getType()) {
                case Token.TOKEN_OPERATOR: {
                    OperatorToken holdOp = (OperatorToken)token;
                    while(!lhs.isEmpty()){
                        holdStack.addLast(lhs.pollLast());
                    };
                    applyHoldOp(holdOp,lhs,holdStack);
                    break;                    
                }
                case Token.TOKEN_NUMBER: // fall through
                case Token.TOKEN_VARIABLE: {
                    lhs.addLast(token);
                    break;
                }

            }
        }


        if (!rhs.isEmpty() || !holdStack.isEmpty()) {
            throw new BadMathExpression(String.format("Unable to properly reduce {%s} is it properly formed?", postfix));
        }

        return Equations.tokensToString(lhs);
    }
    
    private void applyHoldOp(OperatorToken holdOp, Deque<Token> lhs, Deque<Token> holdStack) {
        Token r1 = null, r2 = null; // can be number or variable
        boolean distribute = true;
        r1 = holdStack.pollFirst(); // get what we're going to apply to everything. 
        Token toApply = null;
        while( (toApply = holdStack.pollFirst()) != null) {
            switch( toApply.getType() ) {
                case Token.TOKEN_OPERATOR: {
                    distribute = doWeDistribute(holdOp.getOperator(), ((OperatorToken)toApply).getOperator());
                    lhs.addFirst(toApply); // return original operation to lhs
                    break;
                }
                case Token.TOKEN_NUMBER:
                case Token.TOKEN_VARIABLE: {
                    r2 = toApply;
                    break;
                }
                default: {
                    throw new BadMathExpression(String.format("Token Type %s not implemented in this simplifier yet",toApply.toString()));
                }
            }            
            if (r2 instanceof NumberToken ) {
                double newVal = holdOp.getOperator().apply(((NumberToken)r1).getValue(),((NumberToken)r2).getValue());
                lhs.addFirst(new NumberToken(newVal));
                r2 = null; // done with value
            } else if (r2 instanceof VariableToken && holdStack.isEmpty()) {
                if(distribute) {
                    lhs.addFirst(holdOp);
                    lhs.addFirst(r1);
                    lhs.addFirst(r2);
                }                
            }            
        }        
        
    }

    private boolean doWeDistribute(Operator desiredOp, Operator nextOpInChain) {
        return opMap.get(String.format("%s,%s",desiredOp.getSymbol(),nextOpInChain.getSymbol()));        
    }
}
