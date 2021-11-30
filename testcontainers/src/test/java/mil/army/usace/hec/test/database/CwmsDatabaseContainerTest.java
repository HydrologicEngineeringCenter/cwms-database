package mil.army.usace.hec.test.database;


import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.JDBCType;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.SQLType;

import org.junit.jupiter.api.*;
import org.junit.jupiter.api.extension.ExtendWith;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testcontainers.containers.output.OutputFrame;
import org.testcontainers.containers.output.ToStringConsumer;
import org.testcontainers.containers.output.OutputFrame.OutputType;
import org.testcontainers.junit.jupiter.Container;

public class CwmsDatabaseContainerTest {
    public static final Logger log = LoggerFactory.getLogger(CwmsDatabaseContainerTest.class);

    public final static String branch = System.getProperty("teamcity.build.branch");
    public final static String imageVersion = System.getProperty("cwms.image") != null ? System.getProperty("cwms.image") : "18-SNAPSHOT";
    public final static String volumeName = branch != null ? teamcityVolumeName(branch) : "cwms_container_test_db";


    private static String teamcityVolumeName(String branch){
        String generatedVolumeName = "cwmsdb_"+TeamCityUtilities.cleanupBranchName(branch)+"_"+System.getProperty("teamcity.build.agent")+"_volume";
        log.debug("Using volume name {}",generatedVolumeName);
        return generatedVolumeName;
    }

    @Container
    private static CwmsDatabaseContainer database = new CwmsDatabaseContainer(CwmsDatabaseContainer.ORACLE_19C)
                                                        .withSchemaVersion(imageVersion)
                                                        .withVolumeName(volumeName)
                                                        .withLogConsumer((line) -> {
                                                            System.out.println(((OutputFrame)line).getUtf8String());
                                                        });

    @BeforeAll
    private static void setup() {
        log.debug("Starting Test Database");
        database.start();
        log.debug("Test Database Started");
    }

    @Test
    public void canExcuteSQL() throws Exception {
        assertDoesNotThrow(() -> {
            database.executeSQL("select 1 from dual");
            database.executeSQL("select 1 from dual", database.getReadOnlyUser());
        });

    }

    @Test
    @SuppressWarnings("unchecked")
    public void test_can_run_pd_user_commands() throws Exception {
        assertDoesNotThrow( () -> {
            String pdUser = database.getPdUser();
            String normalUser = database.getUsername();
            database.connection( (c) -> {
                Connection conn = (Connection)c;
                try( CallableStatement addUser =conn.prepareCall("call cwms_sec.add_user_to_group(?,?)"); ){
                    addUser.setString(1,normalUser);
                    addUser.setString(2,"CWMS DBA Users");
                    addUser.execute();
                } catch( SQLException err ){
                    throw new RuntimeException(err);
                }
            }, pdUser);
        });
    }


    @Test
    @SuppressWarnings("unchecked")
    public void test_can_run_as_cwms_20() throws Exception {
        assertDoesNotThrow(() -> {
            database.connection( c -> {

                Connection conn = (Connection)c;
                try( PreparedStatement stmt = conn.prepareStatement("select * from cwms_office");
                     ResultSet rs = stmt.executeQuery();
                ){

                    assertTrue(rs.next(), "operating as cwms_20 does not appear to have worked.");

                } catch( SQLException err ){
                    throw new RuntimeException(err);
                }
            },"cwms_20");
        });

    }
}
