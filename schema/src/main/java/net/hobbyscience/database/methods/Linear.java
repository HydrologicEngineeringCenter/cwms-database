/*
 * Copyright 2022 Michael Neilson
 * Licensed Under MIT License. https://github.com/MikeNeilson/housedb/LICENSE.md
 */

package net.hobbyscience.database.methods;

import java.util.Objects;

import net.hobbyscience.database.ConversionMethod;
import net.hobbyscience.database.exceptions.BadMathExpression;
import net.hobbyscience.database.exceptions.BadMethodData;
import net.hobbyscience.math.Equations;

public class Linear implements ConversionMethod{
    private double a;
    private double b;

    public Linear(double a, double b){
        this.a = a;
        this.b = b;
    }

    public Linear(String data){
        String []parts = data.split("\\s+");
        if( parts.length != 2){
            throw new BadMethodData("Linear conversions consist of only 2 values. (" + data + ") has " + parts.length + " values");
        }
        try {
            a = Double.valueOf(parts[0]);
            b = Double.valueOf(parts[1]);
        } catch( NumberFormatException ex ){
            throw new BadMethodData("values must be doubles", ex);
        }
    }    

    @Override
    public String getAlgebra() {
        return String.format("i*%.06f+%.06f",a,b);
    }

    @Override
    public String getPostfix() throws BadMathExpression {
        return Equations.infixToPostfix(getAlgebra());
    }

	@Override
	public ConversionMethod getInversion() {		
		return new InvLinear(a,b);
	}

    @Override
    public boolean equals(Object other){
        if( !(other instanceof Linear)) return false;
        return getAlgebra().equals(((Linear)other).getAlgebra());
    }

    @Override
    public int hashCode() {
        return Objects.hash(a, b);
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

    
