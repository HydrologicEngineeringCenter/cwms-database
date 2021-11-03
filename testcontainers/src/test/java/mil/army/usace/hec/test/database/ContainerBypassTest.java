package mil.army.usace.hec.test.database;

import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.*;
import org.junit.jupiter.api.extension.ExtendWith;
import org.testcontainers.junit.jupiter.Container;

public class ContainerBypassTest {




    @BeforeAll
    private static void setup() {

    }

    @Test
    public void test_bypass_values_provided() throws Exception {
        final String url = "url.bypassed";
        final String cwmsPassword = "password.bypassed";

        final String officeEroc = "q0";
        System.setProperty(CwmsDatabaseContainer.BYPASS_URL, url);
        System.setProperty(CwmsDatabaseContainer.BYPASS_CWMS_PASSWORD,cwmsPassword);
        System.setProperty(CwmsDatabaseContainer.BYPASS_CWMS_OFFICE_EROC,officeEroc);

        CwmsDatabaseContainer database = new CwmsDatabaseContainer(CwmsDatabaseContainer.ORACLE_19C)
                                                            .withSchemaVersion("doesn't matter here")
                                                            .withVolumeName("no volume");

        database.start();

        assertTrue( database.getJdbcUrl().equals(url), "By URL wasn't returned");
        assertTrue( database.getPassword().equals(cwmsPassword), "Bypassed password wasn't used");
        assertTrue( database.getPdUser().equals(officeEroc.toLowerCase()+"hectest_pu"), "bypassed office EROC not used");


    }
}
