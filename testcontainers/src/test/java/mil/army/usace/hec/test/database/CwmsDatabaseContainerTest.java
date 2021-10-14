package mil.army.usace.hec.test.database;

import org.junit.jupiter.api.*;
import org.junit.jupiter.api.extension.ExtendWith;
import org.testcontainers.junit.jupiter.Container;

public class CwmsDatabaseContainerTest {

    public final static String branch = System.getProperty("teamcity.build.branch");
    public final static String imageVersion = System.getProperty("cwms.image") != null ? System.getProperty("cwms.image") : "18-SNAPSHOT";
    public final static String volumeName = branch != null ? TeamCityUtilities.cleanupBranchName(branch) : "cwms_container_test_db";

    @Container
    private static CwmsDatabaseContainer database = new CwmsDatabaseContainer(CwmsDatabaseContainer.ORACLE_19C)
                                                        .withSchemaVersion(imageVersion)
                                                        .withVolumeName(volumeName);

    @BeforeAll
    private static void setup() {
        database.start();
    }

    @Test
    public void canExcuteSQL() throws Exception {
        database.executeSQL("select 1 from dual");
        database.executeSQL("select 1 from dual", database.getReadOnlyUser());
    }

}
