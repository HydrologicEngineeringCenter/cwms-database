import com.github.dockerjava.api.DockerClient
import com.github.dockerjava.api.model.ExposedPort
import com.github.dockerjava.api.model.PortBinding
import com.github.dockerjava.api.model.HealthCheck
import com.github.dockerjava.api.model.HostConfig
import com.github.dockerjava.core.DockerClientConfig
import com.github.dockerjava.core.DockerClientImpl
import com.github.dockerjava.core.DefaultDockerClientConfig
import com.github.dockerjava.httpclient5.ApacheDockerHttpClient
import org.gradle.api.tasks.*
import org.gradle.api.DefaultTask
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.provider.Property
import java.time.Duration
import java.util.concurrent.TimeUnit

public abstract class StartDatabaseTask extends DefaultTask {
    @Input
    @Optional
    public abstract Property<String> getUrl();

    @Input
    @Optional
    abstract Property<String> getUsername();

    @Input
    @Optional
    abstract Property<String> getPassword();

    @OutputFile
    abstract RegularFileProperty getOutputFile();

    @TaskAction
    void startOrValidateDatabase() {
        final var extension = project.extensions.getByType(DatabaseExtension)
        def props = [:]
        def placeholders = [:]
        placeholders.CWMS_TEST_USERS = "create"

        if (!url.isPresent()) {
            System.out.println("Starting new database");
            def image = extension.image.get()
            def name = extension.name.get()
            def container = DockerUtil.findContainer(name)
            def dockerClient = DockerUtil.getClient()
            // TODO: deal with the situation of the oracle free vs enterprise and
            // maintaining a volume for non-fast-start images.
            if (!container.isPresent()) {
                dockerClient.pullImageCmd(image)
                            .start()
                            .awaitCompletion()

                def createContainer = dockerClient.createContainerCmd(image)
                                                .withEnv("ORACLE_PASSWORD=${password.get()}")
                                                .withName(name)
                                                .withExposedPorts(new ExposedPort(1521))
                                                .withHostConfig(
                                                    HostConfig.newHostConfig()
                                                              .withPortBindings(PortBinding.parse("1521"))
                                                              .withCpuPeriod(20000)
                                                              .withCpuQuota(25000)
                                                              .withMemory(4L*1024*1024*1024)
                                                )
                                                .withHealthcheck(new HealthCheck()
                                                    .withTest(["CMD","/opt/oracle/healthcheck.sh", "FREEPDB1"])
                                                    .withInterval(TimeUnit.SECONDS.toNanos(5))
                                                    .withTimeout(TimeUnit.SECONDS.toNanos(5))
                                                    .withStartPeriod(TimeUnit.MINUTES.toNanos(40))
                                                    .withRetries(50)
                                                )
                def containerResponse = createContainer.exec()
                container = DockerUtil.findContainer(containerResponse.getId())
            }
            DockerUtil.startContainer(container.get())
            DockerUtil.waitForHealthy(container.get())
            def port = DockerUtil.getPortFor(container.get(),1521)
            def buildUserResult = DockerUtil.execInContainer(container.get(),
                "/bin/bash", "-xc", """
cat > /tmp/builduser.sql <<EOF
define builduser=&1
drop user &builduser;
create user &builduser identified by "&2";

grant dba to &builduser;

grant select on dba_scheduler_jobs to &builduser with grant option;
grant select on dba_scheduler_job_log to &builduser with grant option;
grant select on dba_scheduler_job_run_details to &builduser with grant option;

grant execute on dbms_crypto to &builduser with grant option;
grant execute on dbms_aq to &builduser with grant option;
grant execute on dbms_aq_bqview to &builduser with grant option;
grant execute on dbms_aqadm to &builduser with grant option;
grant execute on dbms_lock to &builduser with grant option;
grant execute on dbms_rls to &builduser with grant option;
grant execute on dbms_lob to &builduser with grant option;
grant execute on dbms_random to &builduser with grant option;
grant execute on utl_smtp to &builduser with grant option;
grant execute on utl_http to &builduser with grant option;
grant execute on utl_recomp to &builduser with grant option;
grant select on sys.v_\\\$latch to &builduser with grant option;
grant select on sys.v_\\\$mystat to &builduser with grant option;
grant select on sys.v_\\\$statname to &builduser with grant option;
grant select on sys.v_\\\$timer to &builduser with grant option;
grant select on SYS.AQ\\\$_UNFLUSHED_DEQUEUES to &builduser with grant option;
grant ctxapp to &builduser with admin option;
grant execute on ctxsys.ctx_ddl to &builduser with grant option;
grant execute on ctxsys.ctx_doc to &builduser with grant option;

grant execute any procedure to &builduser;

-- create table spaces
CREATE TABLESPACE "CWMS_20AT_DATA" DATAFILE 'at_data.dat' size 20M autoextend on next 10M maxsize UNLIMITED;
CREATE TABLESPACE "CWMS_20DATA"    DATAFILE 'data.dat'    size 20M autoextend on next 10M maxsize UNLIMITED;
CREATE TABLESPACE "CWMS_20_TSV"    DATAFILE 'tsv.dat'     size 20M autoextend on next 10M maxsize UNLIMITED;
CREATE TABLESPACE "CWMS_AQ"        DATAFILE 'aq.dat'      size 20M autoextend on next 10M maxsize UNLIMITED;
CREATE TABLESPACE "CWMS_AQ_EX"     DATAFILE 'aq_ex.dat'   size 20M autoextend on next 10M maxsize UNLIMITED;

EOF
sqlplus sys/${password.get()}@localhost:1521/FREEPDB1 as sysdba @/tmp/builduser.sql builduser ${password.get()}
            """ )
            println("***********" + buildUserResult)

            props.jdbcUrl = "jdbc:oracle:thin:@localhost:${port}/FREEPDB1?oracle.net.disableOob=true"
            props.url = "localhost:${port}/FREEPDB1"
            props.user = username.get()
            props.password = password.get()
            placeholders.PD_PASSWORD = extension.cwmsPassword.get()
            placeholders.TEST_PASSWORD = extension.cwmsPassword.get()
            placeholders.CWMS_OFFICE_ID = extension.cwmsOfficeId.get()
            placeholders.CWMS_OFFICE_EROC = extension.cwmsOfficeEroc.get()
        } else {
            System.out.println("Using existing database.");
            props.url = url.get()
            props.password = password.get()
            props.user = username.get()
        }
        extension.url.set(props.url)
        extension.jdbcUrl.set(props.jdbcUrl)
        extension.url.finalizeValue()
        extension.jdbcUrl.finalizeValue()

        username.finalizeValue()
        password.finalizeValue()
        outputFile.finalizeValue();

        def out = outputFile.get().asFile
        out.delete()
        props.each { entry ->
            out << "flyway.${entry.key}=${entry.value}\n"
        }
        placeholders.each { entry ->
            out << "flyway.placeholders.${entry.key}=${entry.value}\n";
        }
        // Can't put set flyway.user here, configFile is loaded *after* the task set values
        // and thus breaks the builduser[CWMS_20] user on the data migration task.
        out << "flyway.placeholders.BUILD_USER=${props.user}"
    }
}