/*
 * Copyright 2022 Michael Neilson
 * Licensed Under MIT License. https://github.com/MikeNeilson/housedb/LICENSE.md
 */

package db.migration;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import cwms.units.ConversionGraph;
import cwms.units.Unit;
import db.data.R__0002_units_and_parameters;
import net.hobbyscience.SimpleInfixCalculator;
import net.hobbyscience.database.Conversion;

import static org.junit.jupiter.api.Assertions.*;

import java.util.HashSet;
import java.util.logging.Logger;


public class UnitConversionTest {
    private static final Logger log = Logger.getLogger(UnitConversionTest.class.getName());

    private static HashSet<Conversion> conversions;

    @BeforeAll
    public static void setup() throws Exception {
        R__0002_units_and_parameters migration = new R__0002_units_and_parameters();        

        ConversionGraph graph = new ConversionGraph(migration.getConversions());
        conversions = graph.generateConversions();
        log.info( () -> { 
            StringBuilder sb = new StringBuilder();
            conversions.forEach(c-> sb.append(c.toString()).append(System.lineSeparator()));
            return sb.toString();
        });
        
        assertTrue(conversions.size() > 0);
    }    

    @Test
    public void test_degC_degF_and_back() throws Exception {
        double degC_val = 20.0;
        double degF_val = 68.0;        

        var degC_unit = new Unit("Temperature","C","SI","Centigrade","Celsius Degree");
        var degF_unit = new Unit("Temperature","F","EN","Fahrenheit","Fahrenheit Degree");        

        Conversion degC_to_F = conversions.stream().filter( c -> c.getFrom().equals(degC_unit) && c.getTo().equals(degF_unit) ).findFirst().get();
        Conversion degF_to_C = conversions.stream().filter( c -> c.getFrom().equals(degF_unit) && c.getTo().equals(degC_unit) ).findFirst().get();        

        var infixCtoF = degC_to_F.getMethod().getPostfix();
        var infixFtoC = degF_to_C.getMethod().getPostfix();
        
        double ret = SimpleInfixCalculator.calculate(infixCtoF, degC_val);
        assertEquals(degF_val,ret, 0.0001);

        ret = SimpleInfixCalculator.calculate(infixFtoC, degF_val);
        assertEquals(degC_val,ret, 0.0001);

        

    }

    @Test
    public void test_degF_degK_and_back() throws Exception {
        double degF_val = 68.0;
        double degK_val = 293.15;
        var degF_unit = new Unit("Temperature","F","EN","Fahrenheit","Fahrenheit Degree");
        var degK_unit = new Unit("Temperature", "K", "SI", "Kelvins", "Temperature in Kelvins");

        Conversion degK_to_F = conversions.stream().filter( c -> c.getFrom().equals(degK_unit) && c.getTo().equals(degF_unit) ).findFirst().get();
        Conversion degF_to_K = conversions.stream().filter( c -> c.getFrom().equals(degF_unit) && c.getTo().equals(degK_unit) ).findFirst().get();

        var infixFtoK = degF_to_K.getMethod().getPostfix();
        var infixKtoF = degK_to_F.getMethod().getPostfix();

        double ret = SimpleInfixCalculator.calculate(infixFtoK, degF_val);
        assertEquals(degK_val,ret, 0.0001);

        ret = SimpleInfixCalculator.calculate(infixKtoF, degK_val);
        assertEquals(degF_val, ret, 0.0001);

    }

    
}
