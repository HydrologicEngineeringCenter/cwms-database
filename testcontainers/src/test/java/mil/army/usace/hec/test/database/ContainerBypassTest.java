package mil.army.usace.hec.test.database;

import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.*;

public class ContainerBypassTest {
    final static String url = "url.bypassed";
    final static String cwmsPassword = "password.bypassed";
    final static String sysPassword = "not the default sys password";

    final static String officeEroc = "q0";



    @BeforeAll
    private static void setup() {

        System.setProperty(CwmsDatabaseContainer.BYPASS_URL, url);
        System.setProperty(CwmsDatabaseContainer.BYPASS_CWMS_PASSWORD,cwmsPassword);
        System.setProperty(CwmsDatabaseContainer.BYPASS_SYS_PASSWORD,sysPassword);
        System.setProperty(CwmsDatabaseContainer.BYPASS_CWMS_OFFICE_EROC,officeEroc);
    }

    @AfterAll
    private static void tearDown() {
        System.clearProperty(CwmsDatabaseContainer.BYPASS_URL);
        System.clearProperty(CwmsDatabaseContainer.BYPASS_CWMS_PASSWORD);
        System.clearProperty(CwmsDatabaseContainer.BYPASS_CWMS_OFFICE_EROC);
        System.clearProperty(CwmsDatabaseContainer.BYPASS_SYS_PASSWORD);
    }

    @Test
    public void test_bypass_values_provided() throws Exception {



        CwmsDatabaseContainer database = new CwmsDatabaseContainer(CwmsDatabaseContainer.ORACLE_19C)
                                                            .withSchemaVersion("doesn't matter here")
                                                            .withVolumeName("no volume");

        database.start();

        assertTrue( database.getJdbcUrl().equals(url), "By URL wasn't returned");
        assertTrue( database.getPassword().equals(cwmsPassword), "Bypassed password wasn't used");
        assertTrue( database.getPdUser().equals(officeEroc.toLowerCase()+"hectest_pu"), "bypassed office EROC not used");
        
        assertTrue( database.getSysPassword().equals(sysPassword), "bypass sys password was not set correctly.");
        
        
    }
}
