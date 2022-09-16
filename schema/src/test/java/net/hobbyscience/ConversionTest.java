package net.hobbyscience;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.TestInstance;
import org.junit.jupiter.api.TestInstance.Lifecycle;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvFileSource;

import jmc.cas.Mode;
import net.hobbyscience.database.methods.Function;

@TestInstance(Lifecycle.PER_CLASS)
public class ConversionTest {

    @BeforeAll
    public static void setup() {
        Mode.DEBUG = true;
    }

    @ParameterizedTest(name="{0}")
    @CsvFileSource(delimiter = ':',
                   numLinesToSkip = 0,
                   resources = {"/net/hobbyscience/inversetests.txt"}
    )
    public void test_inverse(String name, String infix, String postfixInverse) {
        var conversion = new Function(infix);
        var inverse = conversion.getInversion();
        assertEquals(postfixInverse.trim(),inverse.render().trim(),() -> String.format("Inversion for %s did not work correctly",name));
    }

}
