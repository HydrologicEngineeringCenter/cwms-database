/*
 * Copyright 2022 Michael Neilson
 * Licensed Under MIT License. https://github.com/MikeNeilson/housedb/LICENSE.md
 */

package net.hobbyscience.math;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Deque;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.Queue;
import java.util.Stack;

import net.hobbyscience.database.exceptions.BadMathExpression;
import net.hobbyscience.database.exceptions.NoInverse;
import net.hobbyscience.database.exceptions.NotImplemented;
import net.objecthunter.exp4j.operator.Operator;
import net.objecthunter.exp4j.shuntingyard.ShuntingYard;
import net.objecthunter.exp4j.tokenizer.*;

public class Equations {
    private static HashSet<String> vars = new HashSet<>();
    static {
        vars.add("i");
    }

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

    /**
     * 
     * @param infix Infix algebraic expression
     * @return a postfix preresentation of the equation
     */
    public static String infixToPostfix( String infix) throws BadMathExpression {        
        try {
            Token tokens[] = ShuntingYard.convertToRPN(infix, null, null, vars, false);
            return tokensToString(tokens);
        } catch ( IllegalArgumentException ex ) {
            throw new BadMathExpression(String.format("Bad data in '%s'",infix),ex);
        }        
    }

    private static boolean isOperand(String token ){
        switch( token ){
            case "+": // fallthrough
            case "-": // fallthrough
            case "^": // fallthrough
            case "*": // fallthrough
            case "/": // fallthrough
            case "i": //
            case "nroot": {
                return true;
            }
            default: {
                return false;
            }
        }
    }

    private static String inverseFor(String operand){
        switch( operand ){
            case "+": return "-";
            case "-": return "+";
            case "^": return "nroot";
            case "*": return "/";
            case "/": return "*";
            case "nroot": return "^";
            default: {
                throw new NoInverse("Cannot find inverser for operator " + operand);
            }
        }
    }

    private static NumberToken calc(NumberToken left, NumberToken right, Token operand) {
        double r1 = left.getValue();
        double r2 = right.getValue();
        
        return new NumberToken(Double.parseDouble(calc(r1,r2,operand.toString())));
    }

    private static String calc(String left, String right, String operand) {
        double r1 = Double.parseDouble(left);
        double r2 = Double.parseDouble(right);
        return calc(r1,r2,operand);
    }

    private static String calc(double r1, double r2, String operand ){
        
        switch( operand ){
            case "+": return Double.toString( r1+r2 );
            case "-": return Double.toString( r1-r2 );
            case "^": return Double.toString( Math.pow(r1,r2) );
            case "*": return Double.toString( r1*r2 );
            case "/": return Double.toString( r1/r2 );
            case "nroot": return Double.toString( Math.pow(r1,1.0/r2) );
            default: {
                throw new NotImplemented("Cannot calculate for operator " + operand);
            }
        }
    }

    /**
     * Invert a function so when writing out units we don't have to do anything in both directions.
     * @param postfix
     * @return postfix but the function inverse
     */
    public static String invertPostfix( String postfix){
        Queue<String> lhs = new LinkedList<>();
        Stack<String> rhs = new Stack<>();
        Stack<String> hold = new Stack<>();
        for( String tok: postfix.split("\\s+") ){
            rhs.push(tok);
        }
    
        while( !rhs.empty() ){
            var token = rhs.pop();
            switch( token ){
                case "i":{
                    break;
                }
                case "+": // fallthrough                                    
                case "-": // fallthrough
                case "^": // fallthrough
                case "*": // fallthrough
                case "/": // fallthrough
                case "nroot": {
                    String r = rhs.pop();
                    String l = rhs.pop();
                    if( r.equals("i") ){
                        hold.add(rhs.pop());
                        hold.add(token);
                        rhs.push(l);                        
                    } else if( !isOperand(r) && !isOperand(l) ){
                        lhs.add(calc(l, r, token));
                        lhs.add(inverseFor(token));
                    } else if( !isOperand(r) ) {
                        lhs.add(r);
                        lhs.add(inverseFor(token));
                        rhs.push(l);
                    }
                    break;
                }
                default: {
                    lhs.add(token);
                }
            }
        }
        if( !hold.isEmpty() ){
            lhs.add(inverseFor(hold.pop())); // for now we'll assume only one "var op" will ever be present here.
        }
        StringBuilder builder = new StringBuilder();
        builder.append("i ");
        lhs.forEach( t -> {
            builder.append(t).append(" ");
        });

        return builder.toString().trim();
    }

    /**
     * 
     * @param expression postfix expression
     * @return series of tokens for further operations
     */
    private static Deque<Token> stringToTokens(String expression) {
        Deque<Token> rhs = new LinkedList<>();
        var tokenizer = new Tokenizer(expression,null,null,vars,false);

        while(tokenizer.hasNext()) {
            var token = tokenizer.nextToken();
            if( token.getType() != Token.TOKEN_SEPARATOR ) {
                rhs.add(token);
            }            
        }
        return rhs;
    }

    private static String tokensToString(Token[] tokens ) {
        return tokensToString(new LinkedList<>(Arrays.asList(tokens)));
    }

    private static String tokensToString(Queue<Token> tokens) {
        StringBuilder builder = new StringBuilder();        
        for( Token tok: tokens ){
            switch(tok.getType()){
                case Token.TOKEN_FUNCTION: { builder.append(((FunctionToken)tok).getFunction().getName()).append(" "); break;}
                case Token.TOKEN_NUMBER: { builder.append(((NumberToken)tok).getValue()).append(" "); break;}
                case Token.TOKEN_VARIABLE: { builder.append( ((VariableToken)tok).getName() ).append(" "); break;  }
                case Token.TOKEN_OPERATOR: { builder.append( ((OperatorToken)tok).getOperator().getSymbol() ).append(" "); break; }
                default: { break;}
            }
        }
        return builder.toString().trim();        
    }

    /**
     * TODO: actually implement this!
     * @param postfix postfix expression that needs to be reduced to as few operations as possible.
     * @return a version of the expression with the fewest operations possible
     */
    public static String reduce( String postfix ){
        Deque<Token> rhs = stringToTokens(postfix);
        Deque<Token> lhs = new LinkedList<>();

        Deque<Token> holdStack = new LinkedList<>();        
                
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

        return tokensToString(lhs);
    }
    
    private static void applyHoldOp(OperatorToken holdOp, Deque<Token> lhs, Deque<Token> holdStack) {
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

    private static boolean doWeDistribute(Operator desiredOp, Operator nextOpInChain) {
        return opMap.get(String.format("%s,%s",desiredOp.getSymbol(),nextOpInChain.getSymbol()));        
    }

    /**
     * 
     * @param receiving postfix equation in fix the i will be substituted
     * @param inserting the new "value" of i
     * @return a postfix equation
     */
    public static String combine( String receiving, String inserting){
        return receiving.replace("i", inserting);
    }

}
