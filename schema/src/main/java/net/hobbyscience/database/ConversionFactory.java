package net.hobbyscience.database;

import cwms.units.Unit;
import net.hobbyscience.database.methods.Linear;

public class ConversionFactory {
    public static Conversion from(Unit from, Unit to, String conversionString){
        String parts[] = conversionString.split(":");
        String type = parts[0];
        String function = parts[1].trim();
        ConversionMethod method = null;
        if( "linear".equalsIgnoreCase(type)){
            method = new Linear(function);
        }
        return method != null ? new Conversion(from,to, method) : null;
        
    }
}
