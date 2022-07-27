/*
 * Copyright 2022 Michael Neilson
 * Licensed Under MIT License. https://github.com/MikeNeilson/housedb/LICENSE.md
 */

package net.hobbyscience.database.exceptions;

public class BadMethodData extends RuntimeException {

    /**
     *
     */
    private static final long serialVersionUID = 1L;
    
    public BadMethodData(String msg){
        super(msg);
    }

    public BadMethodData(String msg, Throwable ex){
        super(msg, ex);
    }

}
