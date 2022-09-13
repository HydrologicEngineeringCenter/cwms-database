/*
 * Copyright 2022 Michael Neilson
 * Licensed Under MIT License. https://github.com/MikeNeilson/housedb/LICENSE.md
 */

package net.hobbyscience.math;

import java.text.NumberFormat;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Deque;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.Queue;
import java.util.Stack;
import java.util.regex.Pattern;

import jmc.cas.BinaryOperation;
import jmc.cas.Operable;
import jmc.cas.RawValue;
import jmc.cas.UnaryOperation;
import jmc.cas.Variable;
import net.hobbyscience.database.exceptions.BadMathExpression;
import net.hobbyscience.database.exceptions.NoInverse;
import net.hobbyscience.database.exceptions.NotImplemented;
import net.objecthunter.exp4j.function.Function;
import net.objecthunter.exp4j.operator.Operator;
import net.objecthunter.exp4j.operator.Operators;
import net.objecthunter.exp4j.shuntingyard.ShuntingYard;
import net.objecthunter.exp4j.tokenizer.*;

public class Equations {
    private static HashSet<String> vars = new HashSet<>();
    static {
        vars.add("i");
    }

    

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

    private static boolean isOperator(Token token ) {
        return token.getType() == Token.TOKEN_OPERATOR;
    }

    private static boolean isNumber(Token token ) {
        return token.getType() == Token.TOKEN_NUMBER;
    }

    /**
     * @param operand 
     * @return the opossite function
     */
    private static Token inverseFor(OperatorToken operand){
        Operator op = null;
        switch( operand.getOperator().getSymbol() ){
            case "+": {
                op = Operators.getBuiltinOperator('-', 2);
                break;
            }
            case "-": {
                op = Operators.getBuiltinOperator('+', 2);
                break;
            } 
            case "^": { 
                return new FunctionToken(null);                
            }
            case "*": {
                op = Operators.getBuiltinOperator('/', 2);
                break;
            }
            case "/": {
                op = Operators.getBuiltinOperator('*', 2);
                break;
            }
            case "nroot":{
                 op = Operators.getBuiltinOperator('^', 2);
                 break;
            }
            default: {
                throw new NoInverse("Cannot find inverser for operator " + operand);
            }            
        }
        return new OperatorToken(op);
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
     * 
     * @param expression postfix expression
     * @return series of tokens for further operations
     */
    public static Deque<Token> stringToTokens(String expression) {
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

    /**
     * Convert a postfix expression into a series of Tokens
     * @param postfix equation, expects all elements to be seperated by space
     * @return
     */
    public static Deque<Token> postfixToTokens(String postfix) {
        var isNumeric = Pattern.compile("^\\d+(\\.\\d+)$");
        var isAlpha = Pattern.compile("^[a-zA-Z]+$");
        Deque<Token> rhs = new LinkedList<>();
        String elements[] = postfix.split("\\s+");
        for( String item: elements) {
            switch (item) {
                case "*":
                case "/":
                case "^": 
                case "-":
                case "+":
                case "operator": {
                    rhs.add(new OperatorToken(Operators.getBuiltinOperator(item.charAt(0), 2)));
                    break;
                }                
                default: {
                    if (isNumeric.matcher(item).matches()) {
                        rhs.add(new NumberToken(Double.parseDouble(item)));
                    } else if (isAlpha.matcher(item).matches()) {
                        rhs.add(new VariableToken(item));
                    } else {
                        throw new NotImplemented(String.format("token %s is not implemented",item));
                    }
                    break;
                }
            }

        }        
        return rhs;
    }

    public static String tokensToString(Token[] tokens ) {
        return tokensToString(new LinkedList<>(Arrays.asList(tokens)));
    }

    public static String tokensToString(Queue<Token> tokens) {
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
     * 
     * @param receiving postfix equation in fix the i will be substituted
     * @param inserting the new "value" of i
     * @return a postfix equation
     */
    public static String combine( String receiving, String inserting){
        return receiving.replace("i", inserting);
    }


    /**
     * Convert a postfix string equation into a Binary tree
     * @param postfix
     * @return jmc.cas binary tree
     */
    public static Operable tokensToBin(String postfix) {
        // just gotta go through the stack
        Token current = null;
        
        Deque<Token> tokens = Equations.postfixToTokens(postfix);

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
            throw new BadMathExpression(String.format("Not all elements of the provided equation '%s' where converted",postfix) );
        }
        
    }
}
