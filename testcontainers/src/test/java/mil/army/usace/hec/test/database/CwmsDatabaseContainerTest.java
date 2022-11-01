package mil.army.usace.hec.test.database;


import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testcontainers.containers.output.OutputFrame;
import org.testcontainers.junit.jupiter.Container;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class CwmsDatabaseContainerTest {
    public static final Logger log = LoggerFactory.getLogger(CwmsDatabaseContainerTest.class);

    public final static String branch = System.getProperty("teamcity.build.branch");
    public final static String imageVersion = System.getProperty("cwms.image") != null ? System.getProperty("cwms.image") : "18-SNAPSHOT";
    public final static String volumeName = branch != null ? teamcityVolumeName(branch) : "cwms_container_test_db";
    private static final String DatabaseImage = System.getProperty("database.image", CwmsDatabaseContainer.ORACLE_19C);

    private static String teamcityVolumeName(String branch){
        String generatedVolumeName = "cwmsdb_"+TeamCityUtilities.cleanupBranchName(branch)+"_"+System.getProperty("teamcity.build.agent")+"_volume";
        log.debug("Using volume name {}",generatedVolumeName);
        return generatedVolumeName;
    }

    @Container
    private static MyCwmsDatabaseContainer database = new MyCwmsDatabaseContainer()
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

    @Test
    public void test_connection_function() throws Exception {
        String pdUser = database.getPdUser();
        String userName = database.connection(this::getServiceAccountUsername, pdUser);
        assertNotNull(userName, "Service account username should be returned");
        assertFalse(userName.isEmpty(), "Service account username should be returned");
    }


    private String getServiceAccountUsername(Connection conn)
    {
        String procedure = "begin cwms_20.cwms_sec.get_service_credentials(?,?,?); end;";
        try (CallableStatement callStmt = conn.prepareCall(procedure)) {
            callStmt.registerOutParameter(1, Types.VARCHAR);
            callStmt.registerOutParameter(2, Types.VARCHAR);
            callStmt.registerOutParameter(3, Types.VARCHAR);
            callStmt.execute();
            return callStmt.getString(1);
        } catch(SQLException e) {
            throw new RuntimeException(e);
        }
    }

    private static class MyCwmsDatabaseContainer extends CwmsDatabaseContainer<MyCwmsDatabaseContainer>
    {
        private MyCwmsDatabaseContainer()
        {
            super(DatabaseImage);
        }
    }
}
