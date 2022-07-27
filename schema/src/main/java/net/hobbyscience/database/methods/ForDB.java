/*
 * Copyright 2022 Michael Neilson
 * Licensed Under MIT License. https://github.com/MikeNeilson/housedb/LICENSE.md
 */

package net.hobbyscience.database.methods;

import net.hobbyscience.database.ConversionMethod;
import net.hobbyscience.database.exceptions.NotImplemented;
import net.hobbyscience.math.Equations;

public class ForDB implements ConversionMethod{
    private String postfix;

    public ForDB(String data){
        this.postfix = data;
    }

    @Override
    public String getAlgebra() {
        throw new NotImplemented("Infix notation for ForDB class is not implemented");
    }

	@Override
	public String getPostfix() {		
		return postfix;
	}

	@Override
	public ConversionMethod getInversion() {
		return new ForDB(Equations.invertPostfix(postfix));
	}

	@Override
	public boolean equals(Object other) {
		if( !( other instanceof ForDB )) return false;
		return this.postfix.equals( ((ForDB)other).postfix );
	}

	@Override
	public String render() {
		return getPostfix();		
	}

}
