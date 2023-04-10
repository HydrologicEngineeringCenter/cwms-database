/*
 * Copyright 2022 Michael Neilson
 * Licensed Under MIT License. https://github.com/MikeNeilson/housedb/LICENSE.md
 */

package db.migration;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvFileSource;

import cwms.units.ConversionGraph;
import cwms.units.Unit;
import db.data.R__0002_units_and_parameters;
import org.opendcs.jas.core.Mode;
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
        Mode.DEBUG = true;
        Mode.FRACTION = true;
        R__0002_units_and_parameters migration = new R__0002_units_and_parameters();        

        ConversionGraph graph = new ConversionGraph(migration.getConversions());
        conversions = graph.generateConversions();
        log.finest( () -> { 
            StringBuilder sb = new StringBuilder();
            conversions.forEach(c-> sb.append(c.toString()).append(System.lineSeparator()));
            return sb.toString();
        });
        
        assertTrue(conversions.size() > 0);
    }    

    @ParameterizedTest /*(name="[{index}] {arguments}")*/
    @CsvFileSource(resources = "/units/conversions_to_test.csv",useHeadersInDisplayName = true)
    public void test_units(String from, String to, double in, double expected, double delta) {
        var fromUnit = getUnit(from);
        var toUnit = getUnit(to);
        var conversion = getConversion(fromUnit,toUnit);
        var inverseConversion = getConversion(toUnit, fromUnit);
        var infix = conversion.getMethod().getPostfix();
        var inverseInfix = inverseConversion.getMethod().getPostfix();

        log.finest(()->"Forward conversion " + conversion.toString());
        double forward = SimpleInfixCalculator.calculate(infix, in);
        assertEquals(expected,forward, delta, () -> "Unable to perform forward conversion using " + conversion.toString());

        log.finest(()->"Inverse conversion " + inverseConversion.toString());
        double inverse = SimpleInfixCalculator.calculate(inverseInfix, expected);
        assertEquals(in,inverse, delta, () -> "Unable to perform inverse conversion using " + inverseConversion.toString());
    }

    private Conversion getConversion(Unit from, Unit to) {
        return conversions.stream()
                          .filter( c -> c.getFrom().equals(from) 
                                     && c.getTo().equals(to))
                          .findFirst().get();
    }

    private Unit getUnit(String unit) {
        return conversions.stream()
                          .filter( c -> c.getFrom().getAbbreviation().equals(unit))
                          .findFirst()
                          .get().getFrom();
    }
}
