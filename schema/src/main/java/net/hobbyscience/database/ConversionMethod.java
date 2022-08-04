/*
 * Copyright 2022 Michael Neilson
 * Licensed Under MIT License. https://github.com/MikeNeilson/housedb/LICENSE.md
 */

package net.hobbyscience.database;

import net.hobbyscience.database.exceptions.BadMathExpression;

public interface ConversionMethod { 
    public String getAlgebra();
    public String getPostfix() throws BadMathExpression;
    public ConversionMethod getInversion() throws BadMathExpression;
    public String render();
}
