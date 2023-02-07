package net.hobbyscience.math;

import net.hobbyscience.database.exceptions.BadMathExpression;

public class EquationReducer {
    public static String reduce(String equation) {
        try {
            var operations = Equations.tokensToBin(equation);        
            operations = operations.simplify(); 
            var beautified = operations.beautify();       
            var infix = beautified.toString();
        
            return Equations.infixToPostfix(infix);
        } catch (BadMathExpression bme) {
            throw new BadMathExpression(String.format("Unable to reduce '%s'",equation),bme);
        } catch (Exception ex) {
            throw new BadMathExpression(String.format("Unable to reduce '%s'",equation),ex);
        }
    }
}
