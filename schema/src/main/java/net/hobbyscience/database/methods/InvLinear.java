/*
 * Copyright 2022 Michael Neilson
 * Licensed Under MIT License. https://github.com/MikeNeilson/housedb/LICENSE.md
 */

package net.hobbyscience.database.methods;

import net.hobbyscience.database.ConversionMethod;
import net.hobbyscience.database.exceptions.BadMethodData;
import net.hobbyscience.math.Equations;

public class InvLinear implements ConversionMethod{
    private double a;
    private double b;

    public InvLinear(double a, double b){
        this.a = a;
        this.b = b;
    }

    public InvLinear(String data){
        String []parts = data.split("\\s+");
        if( parts.length != 2){
            throw new BadMethodData("InvLinear conversions consist of only 2 values. (" + data + ") has " + parts.length + " values");
        }
        try {
            a = Double.parseDouble(parts[0]);
            b = Double.parseDouble(parts[1]);
        } catch( NumberFormatException ex ){
            throw new BadMethodData("values must be doubles", ex);
        }
    }    

    @Override
    public String getAlgebra() {
        return String.format("(i-%.04f)/%.04f",b,a);
    }
    
    @Override
    public String getPostfix() {        
        return Equations.infixToPostfix(getAlgebra());
    }

	@Override
	public ConversionMethod getInversion() {		
		return new Linear(a,b);
	}

    @Override
    public boolean equals(Object other){
        if( !(other instanceof InvLinear)) return false;
        return getAlgebra().equals(((InvLinear)other).getAlgebra());
    }

    @Override
    public String render() {
        StringBuilder sb = new StringBuilder();
        sb.append("Provided -> ")
          .append(getAlgebra())
          .append(", postfix -> ")
          .append(getPostfix());
        return sb.toString();
    }

    

}
