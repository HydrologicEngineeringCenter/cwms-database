package cwms.database.testing.support;

import org.gradle.api.Plugin;
import org.gradle.api.Project;
import org.gradle.api.provider.Provider;

public class DatabaseServicePlugin implements Plugin<Project>
{
    public void apply(Project project)
    {
        // Register the service
        project.gradle.sharedServices.registerIfAbsent("database", DatabaseService.class, spec -> {
            // Provide some parameters

            // Check for configured parameters and decided if the database exists or needs to be started.
            final var url = project.findProperty("database.url");
            final var database = spec.getParameters();
            if (url != null) {
                database.createTestDatabase.set(false);
                database.url.set((String)url);
                database.jdbcUrl.set(project.findProperty("database.jdbcUrl")?: "jdbc:oracle:thin:@${url}?oracle.net.disableOob=true")
                database.sysPassword.set(project.getProperty("database.sysPassword"))
                database.buildUserName.set(project.getProperty("database.buildUser"))
                database.buildUserPassword.set(project.getProperty("database.buildUserPassword"))
                database.testAccountPassword.set(project.getProperty("database.testAccountPassword"))
                database.eroc.set(project.getProperty("database.eroc"))
                database.officeId.set(project.getProperty("database.officeId"))
                database.createTestAccounts.set(true)
            } else {
                database.createTestDatabase.set(true)
                database.databaseImage.set(project.findProperty("database.image")?: "gvenzl/oracle-free:23.5-full-faststart")
                database.containerName.set(project.findProperty("database.containerName")?: "cwms-test-database")
                database.createTestAccounts.set(true)
                database.sysPassword.set(project.findProperty("database.sysPassword")?: "Bad-SysPassw0rd")
                database.buildUserName.set(project.findProperty("database.buildUser")?: "builduser")
                database.buildUserPassword.set(project.findProperty("database.buildUserPassword")?: "Bu1ld-User_Pass")
                database.testAccountPassword.set(project.findProperty("database.testAccountPassword")?: "Cwms-UserP0sswUrt")
                database.eroc.set(project.findProperty("database.eroc")?: "l2")
                database.officeId.set(project.findProperty("database.officeId")?: "SPK")
                database.createTestAccounts.set(true)
                database.url.value("")
            }
            database.schema.set("CWMS_20")
        })

        def checkTestSetup = project.tasks.register("CheckTestSetup", CheckTestSetupTask) {}
        def installTestFramework = project.tasks.register("installTestFramework", InstallTestFrameworkTask) {
            dependsOn checkTestSetup
        }
        def installTests = project.tasks.register("installTests", InstallTestsTask) {
            dependsOn installTestFramework
        }
        def cleanTestData = project.tasks.register("cleanTestData", cwms.database.testing.support.UtTest) {
            dependsOn installTests
            tests = ["test_clean_all"]
            outputs.upToDateWhen { false } // we always run this task
            user = "cwmspd"
        }
        def loadTestData = project.tasks.register("loadTestData", LoadTestDataTask) {
            dependsOn installTests
            dependsOn cleanTestData
        }

        def testDb = project.tasks.register("testDb") {
            dependsOn installTests

            dependsOn cleanTestData
            dependsOn loadTestData
        }

        def test = project.tasks.register("test") {
            dependsOn testDb
}

    }
}