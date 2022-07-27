/*
 * Copyright 2022 Michael Neilson
 * Licensed Under MIT License. https://github.com/MikeNeilson/housedb/LICENSE.md
 */

package net.hobbyscience.database.methods;

import net.hobbyscience.database.ConversionMethod;
import net.hobbyscience.database.exceptions.BadMethodData;
import net.hobbyscience.math.Equations;

public class Function implements ConversionMethod{
    private String data;

    public Function(String data){
        if( data == null || data.isEmpty() ){
            throw new BadMethodData("an equation must be provided");
        }
        this.data = data;
    }

    @Override
    public String getAlgebra() {        
        return data;
    }

    @Override
    public String getPostfix() {        
        return Equations.infixToPostfix(data);
    }

	@Override
	public ConversionMethod getInversion() {		
		return new ForDB(Equations.invertPostfix(getPostfix()));
	}

    @Override
    public boolean equals(Object other){
        if( !(other instanceof Function )) return false;
        return this.data.equals(((Function)other).data);
    }

    @Override
    public String render() {
        StringBuilder sb = new StringBuilder();
        sb.append("Provided -> ")
          .append(data)
          .append(", postfix -> ")
          .append(getPostfix());
        return sb.toString();
    }

    
    
}
