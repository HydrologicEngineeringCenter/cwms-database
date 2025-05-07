package cwms.database.testing.support

import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.provider.Property
import org.gradle.api.provider.ListProperty
import org.gradle.api.services.ServiceReference
import org.gradle.api.tasks.*
import org.gradle.process.ExecOperations
import javax.inject.Inject
import java.util.stream.Collectors


public abstract class DatabaseTask extends DefaultTask {
    @ServiceReference("database")
    protected abstract Property<DatabaseService> getDatabaseService();

    @Inject
    protected abstract ExecOperations getExec();

}

public abstract class UtTest extends DatabaseTask {
    @Input
    public abstract Property<String> getUser();

    @Input
    public abstract ListProperty<String> getTests();

    @OutputDirectory
    public abstract DirectoryProperty getCoverageDir();

    public UtTest() {
        group = "Testing"
        description = "Run a UtPLSQL test suite"
        coverageDir.convention(project.layout.buildDir.dir("coverage"))
    }

    @TaskAction
    public void test() {

        def database = databaseService.get()
        def dbUrl = database.url
        def cwms_eroc = database.eroc
        def pd_password = database.testAccountPassword
        def cwms_schema_name = database.schemaName
        def tests = tests.get()
                         .stream()
                         .map(t -> "${cwms_schema_name}.${t}")
                         .collect(Collectors.joining(","))
        exec.exec( {
            executable "utplsql"
            args "run"
            args "-p=${tests}"
            args "-f=UT_COVERAGE_HTML_REPORTER"
                args "-o=${coverageDir.get()}/index_${name}.html"
            args "-f=UT_COVERAGE_COBERTURA_REPORTER"
                args "-o=${coverageDir.get()}/coverage_${name}.xml"
            args "-f=UT_JUNIT_REPORTER"
                args "-o=${project.layout.buildDir.get()}/TEST-${name}.xml"
            args "-f=UT_DOCUMENTATION_REPORTER"
            args "-d" // diagnostic info
            args "-D" // dbms_output
            args "-s" // terminal output even with o set
            args "-c" // color
            args "${cwms_eroc}${user.get()}/\"${pd_password}\"@${dbUrl}"
        }).rethrowFailure()
    }
}


public abstract class CheckTestSetupTask extends DatabaseTask {

    @TaskAction
    public void check() {
        def database = databaseService.get()
        def dbUrl = database.url
        def result = exec.exec( {
            executable "sqlplus"
            args "-h"
            ignoreExitValue = true
            standardOutput = new ByteArrayOutputStream()
            errorOutput = new ByteArrayOutputStream()
        })

        if (result.exitValue !=0 ) {
            throw new GradleException("sqlplus must be available for test framework to execute")
        }

        result = exec.exec({
            executable "utplsql"
            args "-h"
            ignoreExitValue = true
            standardOutput = new ByteArrayOutputStream()
            errorOutput = new ByteArrayOutputStream()
        })

        if (result.exitValue != 0) {
            throw new GradleException("utplsql-cli must be installed and in PATH for tests to run")
        }

        if (database.sysPassword == null) {
            throw new GradleException("Tests can only be run if db.sys_password is set.")
        }

        if (dbUrl == null) {
            throw new GradleException("Test framework assumes you are allow running flyway Migrate tasks, please set flyway.url")
        }
    }
}


public abstract class InstallTestFrameworkTask extends DatabaseTask {

    @TaskAction
    public void installFramework() {
        def database = databaseService.get()
        exec.exec({
            executable "sqlplus"
            args "sys/\"${database.sysPassword}\"@${database.url} as sysdba"
            args "@install_headless_with_trigger.sql"

            ignoreExitValue true
            workingDir project.layout.buildDir.dir("deps/utPLSQL/source")
        })

        exec.exec({
            executable "sqlplus"
            args "sys/\"${database.sysPassword}\"@${database.url} as sysdba"
            standardInput = new ByteArrayInputStream("GRANT INHERIT PRIVILEGES ON USER sys TO ut3;".getBytes())
        })
    }
}

public abstract class InstallTestsTask extends DatabaseTask {
    @TaskAction
    public void installTests() {
        def database = databaseService.get()
        exec.exec({
            workingDir project.layout.projectDirectory.dir("src/test/utplsql")
            executable "sqlplus"
            args "${database.cwmsUser}/\"${database.buildUserPassword}\"@${database.url}"
            args "@tests.sql"
            args database.officeId
            args database.schemaName
            args database.eroc + "hectest_up"
            args database.eroc
        }).assertNormalExitValue()

        exec.exec({
            executable "sqlplus"
            workingDir project.layout.projectDirectory.dir("src/test/utplsql")
            args "sys/\"${database.sysPassword}\"@${database.url} as sysdba"
            args "@test_grants.sql"
            args "${database.eroc}cwmspd"
            args "${database.eroc}hectest_ro"
            args "${database.eroc}hectest_db"
            args "${database.eroc}hectest_pu"
            args "${database.eroc}hectest_up"
            args "${database.schemaName}"
            args "${database.eroc}hectest"
            args "${database.eroc}webtest"
            args "${database.eroc}hectest_multioffice"
        }).assertNormalExitValue()
    }
}


public abstract class LoadTestDataTask extends DatabaseTask {
    @TaskAction
    public void loadTestData() {
        def database = databaseService.get()
        exec.exec({
            workingDir project.layout.projectDirectory.dir("src/test/data/ratings")
            executable "sqlldr"
            args "${database.cwmsUser}/\"${database.buildUserPassword}\"@${database.url}"
            args "control=xsl_test_clobs.ctl"
        }).assertNormalExitValue()
    }
}