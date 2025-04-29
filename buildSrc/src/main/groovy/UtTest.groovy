import org.gradle.api.tasks.*
import org.gradle.api.DefaultTask
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.provider.Property
import org.gradle.api.provider.ListProperty
import org.gradle.process.ExecOperations
import javax.inject.Inject
import java.util.stream.Collectors

public abstract class UtTest extends DefaultTask {


    @Input
    public abstract Property<String> getUser();

    @Input
    public abstract ListProperty<String> getTests();

    @OutputDirectory
    public abstract DirectoryProperty getCoverageDir();

    private ExecOperations exec;

    @Inject
    UtTest(ExecOperations exec) {
        this.exec = exec
        group = "Testing"
        description = "Run a UtPLSQL test suite"
        coverageDir.convention(project.layout.buildDir.dir("coverage"))
    }

    @TaskAction
    public void test() {
        def database = project.extensions.getByName("database")
        def dbUrl = database.url.get()
        def cwms_eroc = database.cwmsOfficeEroc.get()
        def pd_password = database.cwmsPassword.get()
        def cwms_schema_name = database.schemaName.get()
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