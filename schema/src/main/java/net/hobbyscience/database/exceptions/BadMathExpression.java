package net.hobbyscience.database.exceptions;

public class BadMathExpression extends RuntimeException {

    /**
     *
     */
    private static final long serialVersionUID = 1L;
    
    public BadMathExpression(String msg){
        super(msg);
    }

    public BadMathExpression(String msg, Throwable ex){
        super(msg, ex);
    }
    
}
