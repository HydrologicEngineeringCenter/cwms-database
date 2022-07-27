/*
 * Copyright 2022 Michael Neilson
 * Licensed Under MIT License. https://github.com/MikeNeilson/housedb/LICENSE.md
 */

package net.hobbyscience.database.exceptions;

public class NoInverse extends RuntimeException{

    /**
     *
     */
    private static final long serialVersionUID = 1L;
    public NoInverse(String msg ){
        super(msg);
    }
}
