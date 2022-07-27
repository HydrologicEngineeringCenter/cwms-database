/*
 * Copyright 2022 Michael Neilson
 * Licensed Under MIT License. https://github.com/MikeNeilson/housedb/LICENSE.md
 */

package net.hobbyscience.database.exceptions;

public class NoConversionFound extends RuntimeException{
    /**
	 *
	 */
	private static final long serialVersionUID = 1L;

	public NoConversionFound(String msg){
        super(msg);
    }
}
