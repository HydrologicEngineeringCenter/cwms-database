/*
 * Copyright 2022 Michael Neilson
 * Licensed Under MIT License. https://github.com/MikeNeilson/housedb/LICENSE.md
 */

package net.hobbyscience.database;

public interface ConversionMethod { 
    public String getAlgebra();
    public String getPostfix();
    public ConversionMethod getInversion();
    public String render();
}
