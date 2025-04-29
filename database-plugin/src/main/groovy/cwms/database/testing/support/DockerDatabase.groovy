package cwms.database.testing.support
import com.github.dockerjava.api.DockerClient
import com.github.dockerjava.core.command.ExecStartResultCallback
import com.github.dockerjava.api.exception.NotModifiedException
import com.github.dockerjava.api.model.Container
import com.github.dockerjava.api.model.ExposedPort
import com.github.dockerjava.api.model.PortBinding
import com.github.dockerjava.api.model.HealthCheck
import com.github.dockerjava.api.model.HostConfig
import com.github.dockerjava.core.DockerClientConfig
import com.github.dockerjava.core.DockerClientImpl
import com.github.dockerjava.core.DefaultDockerClientConfig
import com.github.dockerjava.httpclient5.ApacheDockerHttpClient
import java.time.Duration
import java.util.concurrent.TimeUnit


public final class DockerDatabase {
    Container container;
    DatabaseService.Params params;
    DockerClient dockerClient = DockerUtil.getClient();

    public DockerDatabase(DatabaseService.Params params) {
        this.params = params;
    }

    public boolean start() {
        def name = params.getContainerName().get()
        this.container = DockerUtil.findContainer(name)
                                   .orElseGet(() -> createContainer())
        startContainer()
        return isRunning()
    }


    public boolean isRunning() {
        return DockerUtil.isHealthy(container)
    }


    private Container createContainer() {
        def image = params.databaseImage.get()
        dockerClient.pullImageCmd(image)
                    .start()
                    .awaitCompletion()
        
        def name = params.containerName.get()

        def createContainer =
            dockerClient.createContainerCmd(image)
                        .withEnv("ORACLE_PASSWORD=${params.sysPassword.get()}")
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
        return DockerUtil.findContainer(containerResponse.getId()).get()
    }

    private void startContainer() {
        DockerUtil.startContainer(container)
        DockerUtil.waitForHealthy(container)
        def port = DockerUtil.getPortFor(container,1521)

        params.url.set("localhost:${port}/FREEPDB1")
        def buildUserResult = DockerUtil.execInContainer(container,
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
sqlplus sys/${params.sysPassword.get()}@localhost:1521/FREEPDB1 as sysdba @/tmp/builduser.sql builduser ${params.buildUserPassword.get()}
            """ )
            println("***********" + buildUserResult)
            
            /*props.jdbcUrl = "jdbc:oracle:thin:@localhost:${port}/FREEPDB1?oracle.net.disableOob=true"
            props.url = "localhost:${port}/FREEPDB1"
            props.user = username.get()
            props.password = password.get()
            placeholders.PD_PASSWORD = extension.cwmsPassword.get()
            placeholders.TEST_PASSWORD = extension.cwmsPassword.get()
            placeholders.CWMS_OFFICE_ID = extension.cwmsOfficeId.get()
            placeholders.CWMS_OFFICE_EROC = extension.cwmsOfficeEroc.get()*/
    }
}