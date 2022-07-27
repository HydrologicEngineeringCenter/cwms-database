/*
 * Copyright 2022 Michael Neilson
 * Licensed Under MIT License. https://github.com/MikeNeilson/housedb/LICENSE.md
 */

package net.hobbyscience.database;

import java.util.Objects;

import cwms.units.Unit;

public class Conversion {
    private Unit from;
    private Unit to;
    private ConversionMethod method;    

    public Conversion(Unit from, Unit to, ConversionMethod method){
        this.from = from;
        this.to = to;
        this.method = method;
    }

    public Unit getFrom() {
        return this.from;
    }

    public Unit getTo() {
        return this.to;
    }

    public ConversionMethod getMethod() {
        return this.method;
    }

    public Conversion getInverse(){
        return new Conversion(to,from, method.getInversion());
    }
    
    @Override
    public boolean equals(Object other ){
        if( !(other instanceof Conversion ) ) return false;
        Conversion o = (Conversion)other;
        if( this.from != o.from ) return false;
        if( this.to != o.to ) return false;
        return this.method.equals(o.method);
    }

    @Override
    public int hashCode() {
        return Objects.hash(from, to, method);
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append("( ")
          .append(from.getAbbreviation() )
          .append(" -> ")
          .append(to.getAbbreviation())
          .append(" with ")
          .append(method.render());
        return sb.toString();
    }
}
