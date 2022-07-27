/*
 * Copyright 2022 Michael Neilson
 * Licensed Under MIT License. https://github.com/MikeNeilson/housedb/LICENSE.md
 */

package net.hobbyscience.database.methods;

import java.util.Objects;

import net.hobbyscience.database.ConversionMethod;
import net.hobbyscience.database.exceptions.BadMethodData;
import net.hobbyscience.math.Equations;

public class USGS implements ConversionMethod {
    public double a;
    public double b;
    public double c;
    public double d;

    public USGS(double a, double b, double c, double d){
        this.a = a;
        this.b = b;
        this.c = c;
        this.d = d;
    }

    public USGS(String data) {
        String parts[] = data.split("\\.*");
        if( parts.length != 2){
            throw new BadMethodData("Linear conversions consist of only 2 values");
        }
        try {
            a = Double.parseDouble(parts[0]);
            b = Double.parseDouble(parts[1]);
            c = Double.parseDouble(parts[2]);
            d = Double.parseDouble(parts[3]);
        } catch( NumberFormatException ex ){
            throw new BadMethodData("values must be doubles", ex);
        }
    }

    @Override
    public String getAlgebra() {        
        return String.format("%0.4f * (%0.4f + i)^%0.4f + %0.4f",a,b,c,d);
    }

    @Override
    public String getPostfix() {        
        return Equations.infixToPostfix(getAlgebra());
    }

	public ConversionMethod getInversion() {
		return new InvUSGS(a,b,c,d);
	}

    @Override
    public boolean equals(Object other){
        if( !(other instanceof InvLinear)) return false;
        return getAlgebra().equals(((InvLinear)other).getAlgebra());
    }

    @Override
    public int hashCode() {
        return Objects.hash(a, b, c, d);
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
