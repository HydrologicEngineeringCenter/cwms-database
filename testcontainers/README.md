# TestContainers for CWMS Database

## Purpose

This library allows you to, with relative easy, get a test database stood up that can be used for any Integration Test or other purpose requiring a live cwms database.

## Requirements

### Oracle
The following must be manually setup at this time:

the oracle database docker image, see https://github.com/oracle/docker-images/tree/main/OracleDatabase/SingleInstance
The tag name used should be `oracle/database:19.3.0-ee`

You can also use an 18 Expression Edition but you MUST specify that image name when creating the container instance.

For example in your test class
```java
    @Container
    private static CwmsDatabaseContainer cwmsDatabase = new CwmsDatabaseContainer(CwmsDatabaseContainer.ORACLE_19C)
                                                                .withSchemaVersion("18-SNAPSHOT")
                                                                .withVolumeName("cwms_aaa_db");
```

#### Notes

If the variable is static is setup once for all tests in the suite, if it is not static it is reset after each test and you will need to call cwmsDatabase.start() at the beginning of each test. A full example will be available at the end of the readme.

### Cwms Database installer

You must also have a Cwms Database installer image. At this time we do not have a proper registry, you may download the appropriate images from the HEC Nexus cwms-internal/cwms-database-schema/<version>/cwms-data-schema-<version>-docker.tar and run the following command

```bash
docker image load <downloaded file name>
```

The image SHOULD have the correct name.

## To setup a test database manually (e.g. not controlled by the testcontainers system for exploratory testing and such)

*NOTE* you must add "DIABLE_OOB=ON" to your ~/.sqlnet.ora file to connect to the docker image from the host.

`$CONTAINERNAME` is functionally the hostname within the `$NETWORK_NAME` docker network. It's also the short name you'll use to interact with docker. e.g. `docker start $CONTAINERNAME` or `docker stop $CONTAINERNAME`

```bash
docker network create $NETWORK_NAME
docker volume create $VOLUME_NAME
docker run -d --network $NETWORK_NAME --name $CONTAINERNAME \
            -e ORACLE_PDB=$DBNAME -e ORACLE_PWD=$SYS_PASSWORD \
            -p $PORT:1521 \
            -v $VOLUME_NAME:/opt/oracle/oradata \
            -e enterprise oracle/database:19.3.0-ee
# about 25 minutes later you will have a functional oracle database you control
# because you used the -d parameter above, your database will be running in the background. Otherwise you'll need to open a new shell or Ctrl-C and run the docker start $CONTAINERNAME command
#
#NOTE on port here, the $PORT above is the external to docker port, e.g. what sqldeveloper will connect to. Internally on the $NETWORK_NAME
# network oracle is listening on port 1521, the install image runs on the network.
#
# replace <version> with your actual version of CWMS Database Schema desired
# additional environment variables are OFFICE_ID and OFFICE_EROC. The default is HQ and Q0 respectively.
docker run --network $NETWORK_NAME -e DB_HOST_PORT="$CONTAINERNAME:1521" \
           -e DB_NAME="/$DBNAME" -e SYS_PASSWORD=$SYS_PASSWORD cwms_db_install:<version>
# Once this finishes it will dump the buildCWMS_DB.log file to the screen and return; if no errors are reported your test database is ready
# with the normal test users setup.
```

## Example

See https://testcontainers.org for information on the basic dependencies required.
Also see https://bitbucket.hecdev.net/projects/CWMS/repos/cwms_aaa/browse/IntegrationTests and this project for functioning examples in gradle.

This example shows using the teamcity branch name, if available, to determine the volume name. This will allow builds
after the first to reuse the instance of oracle and reduce the time from 40 minutes to 10 minutes (the time to reload the cwms schema.)
It also allows something to overwrite which version of the database installer is getting used.

If you need to test with multiple CWMS versions, Junit 5's parameterized tests mechanism SHOULD be used instead. However, such an exercise is beyond scope and left to the reader.

```java
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
        database.executeSQL("select 1 from dual"); // runs as the pd user by default
        database.executeSQL("select 1 from dual", database.getReadOnlyUser());
    }

    @Test
    public void getUrl() throws Exception {
        String url = cwmsDatabase.getJdbcUrl();
        // do something that requires the URL.
        // NOTE: this url WILL have disableOob turned on for you, if you do not use it AS IS, the problems are yours to solve.
    }

}
```