# CWMS Database

This repository contains the information necessary to both create a CWMS database from scratch and upgrade an existing database.

NOTE: We have only recently decided to move the project to github, and we have made some process improvements to the build. Some of the following information 
may be out of date. Please ask questions at https://github.com/HydrologicEngineeringCenter/cwms-database/discussions for any clarification required.

## Contributing

clone the repository with 

    git clone https://github.com/HydrologicEngineeringCenter/cwms-database.git

Use a token, created through the bitbucket account management interface, instead of your password. Certain operations will fail if your username/password combination is used.

Once you've decided on what you'll be working on create a branch (or checkout an existing branch if helping someone.)

    git checkout -b <branch name>

Please use one of the following prefixes for your branch

- feature/
- bugfix/
- hotfix/


and then go to the bitbucket site and create the PR. 

Please do this as early as possible in your development cycle. This will help prevent duplication of work and open up a consistent communication channel. It is expected that ones initial submission will not meet all of the requirements and guidance will be provided.

For you code to be accepted it must successfully install into Oracle and be approved by one of the people at the bottom of this readme in the Reviewers section.

In the future we will enforce coding style standards and test coverage. 

If you do not have write access please fork the respository and submit your pull-request from your fork.


## build and testing

### Standing up an Oracle database

NOTE: The CWMS Database and it's testing now support the https://hub.docker.com/r/gvenzl/oracle-free images, including faststart variants. `-slim` variants are not supported.
You may also manually create an overrides.xml file that points to an existing database; see further down for information.

#### OS Install

Beyond the scope of this document.

#### Docker

The following assumes you have installed docker. Link to docker installation instructions: https://docs.docker.com/engine/install/

The readme will provide some simple instructions, for additional container configuration options see: https://github.com/oracle/docker-images/tree/main/OracleDatabase/SingleInstance

For continuous development the following setup is recommended. It uses the pluggable database mechanism. This allows the creation of additional databases within this one instance. This is 
useful for having say, a fairly stable version of the schema for application development and a separate database for database feature development.

NOTE: If building manually from the github link images you may need additional parameters.

```
docker volume create cwmsdb_volume
docker network create cwmsdb_net
docker run -d --name cwmsdb -e ORACLE_PASSWORD="simplePassword0#" -p 1521:1521 \
              --network cwmsdb_net \
              -v cwmsdb_volume:/opt/oracle/oradata gvenzl/oracle-free \
              gvenzl/oracle-free:23.6-full
# Alternatively you can use the -faststart if you do not need to keep the schema or any data between restarts.
docker logs -f cwmsdb
# If your machine is restarted and you have not set the container to autostart do the following to bring it back up
docker start cwmsdb # this will be fairly quick
# to restart
docker restart cwmsdb
```

We've found that sqlplus and other tools don't play super nice with oracle in docker at times. create a `$HOME/.sqlnet.ora` file
that includes the following:

```
DISABLE_OOB=ON
```

For JDBC connections use the following extra parameter:
```
jdbc:oracle:thin:.../CWMSDB?oracle.net.disableOob=true
```

You should not be able to use the schema installer image below, or create an overrides file (see build for dev below) to
use the ant targets directly.

### Docker installer for use

If you are not doing development and only want to install an instance of the CWMS schema into a database for use:

`docker pull registy-public.hecdev.net/cwms/schema_installer:<version>`

where `<version>` can be:

- latest-dev
- 21.1.1
- latest
- Current latest schema: 24.12.04

latest-dev is the newest code, latest will be the main version deployed

If you have the source you can use `ant docker.install` to get a default setup that will also start the database for you.

Otherwise

```bash
docker run  -e DB_HOST_PORT=<database hostname/ip>:<port> \
            -e DB_NAME=<database SID or Service Name \
            -e SYS_PASSWORD=<sys password on your Oracle database> \
            -e CWMS_PASSWORD=<desired CWMS_20 password or leave off to generate> \
            -e BUILDUSER_PASSWORD=<desired build user password or leave off to generate> \
            -e OFFICE_ID=<office ID, letters, all caps. default is HEC> \
            -e OFFICE_EROC=<2 letter eroc, lower case, default is q0> \
            registry-public.hecdev.net/cwms/schema_installer:<version>
```

NOTE the docker image is not generally friendly for diagnosing thing as it's intended
for use after the build scripts have been verified. The buildCWMS_DB.log and other logging .txt
files will be printed to the schema installers stdout.


### Build for dev

It is recommend that you open the schema directory as the root directory in any IDE you use.

Copy the teamcity_overrides.xml to build/localoverrides.xml (or preferably to a directory outside the build tree) and alter the settings internally to match the test database you have either setup or had provided.

To build the database run the following:

    ant -Dbuilduser.overrides=build/local_overrides.xml clean build

*clean* will remove any existing schemas with the CWMS_20 name.

*build* will initialize the database.


### Tests

You must have utplsql from github.com/utPLSQL/utPLSQL-cli on your path. 
If you get the error that the oci version doesn't match while trying to run the tests remove all of the oracle jar from the utPLSQL-cli installation path *lib* directory and copy the ojdbc8.jar from your instantclient folder. (This issue has previously been reported to the utPLSQL team and should eventually be fixed.)

to run the tests 

   ant -Dbuilduser.overrides=build/local_overrides.xml test
   # or likely more often
   ant -Dbuilduser.overrides=build/local_overrides.xml clean build test

The test framework will be installed, and the tests will be run. The following files will be created:

- build/tests.log Information about how the test framework installation ran
- build/tests.xml Junit xml format for various reporting tools
- build/coverage.html Code coverage in a pretty HTML format.
- build/coverage.xml Code coverage in a format that TeamCity and others can pick up. It is the Cobertura format.

The tests themselves are simply PL/SQL procedures and the utPLSQL library provides facitilies for assertions and reporting.
There are multiple test targets called by the root `test` target in ant. Each target has a unique set of tests and a specific username to set permissions correctly.

The full suite of tests usually takes about 5-7 minutes to run.

When creating a new tests, if the test makes sense to add to an existing file, do so, that is easier. If you need to create a new test suite, consider the usage
of the code under test and add it to the target with appropriate credentials.

NOTE: Due to the complexity of the system, we don't currently have a good way to tell the ant targets exactly which tests to run. You may edit the build.xml to comment out the tests
you don't want while doing your initial work. Try to revert the changes before PR submission (unless draft) though we *usually* catch them during review.

NOTE2: If enough people complain about this I'll take the time to you know, actually see if we can fix that situation.

### Modifying the build

For simple modifications provide a pull request with the build code modified as normal.


### Update scripts and Releases

- We're not going to bump the version on everything change we'll leave the pom.xml at MAJOR-SNAPSHOT
- We do appreciate developers creating their own update scripts for changes but also understand how difficult that is.

#### Versioning

There is a pom.xml file in the root directory that contains the current version. The version follows the following format:

    XX.YY.ZZ[-SNAPSHOT] 

XX-Year
YY-Month
ZZ[-SNAPSHOT] - Day

if you need the version anywhere in the build.xml file, use `${pom.version}` to extract.

SNAPSHOT will be appended to major versions while changes are merged in to main.

## Docker Compose

There is a docker compose file to assist with certain developement. See the docker-compose.README.md file for additional details.

## Reviewers

Eric Novotny
Mike Neilson
Mike Perryman

## Confluence Documentation

Some documentation is currently hosted on an internal wiki, we will move it to the github wiki on a time permitting basis. Please
ask questions on the discussion if you have them. We will use such questions to prioritize moving documentation.
