# CWMS Database

This repository contains the information necessary to both create a CWMS database from scratch and upgrade an existing database.

## Contributing

clone the repository with 

    git clone https://bitbucket.hecdev.net/scm/cwms/cwms_database.git

Use a token, created through the bitbucket account management interface, instead of your password. Certain operations will fail if your username/password combination is used.

Once you've decided on what you'll be working on create a branch (or checkout an existing branch if helping someone.)

    git checkout -b <branch name>

You one of the following prefixes for your branch

- feature
- bugfix
- hotfix

Other branch names are completely valid, but they won't automatically build without a pull request being created.

All contributions will be made through a Pull Request. If you have write access to the repository simply push your branch with the following:

    git push origin <branch name>

and then go to the bitbucket site and create the PR. 

Please do this as early as possible in your development cycle. This will help prevent duplication of work and open up a consistent communication channel. It is expected that ones initial submission will not meet all of the requirements and guidance will be provided.

For you code to be accepted it must successfully install into Oracle and be approved by one of the people at the bottom of this readme in the Reviewers section.

In the future we will enforce coding style standards and test coverage. 

If you do not have write access you may be able to fork it in bitbucket and submit a PR from the fork. If that doesn't work contact one of the Reviewers for access.


## build and testing

### Standing up an Oracle database

#### OS Install

Beyond the scope of this document.

#### Docker

The following assumes you have installed docker. Link to docker installation instructions: https://docs.docker.com/engine/install/
If you have DevNet credentials you can get a pregenerated Oracle Database image in the following way:

```
docker login https://registry.hecdev.net
# enter user name and password as prompted
docker pull registry.hecdev.net/oracle/database:19.3.0-ee
# also available are:
docker pull registry.hecdev.net/oracle/database:19.17.0-ee
docker pull registry.hecdev.net/oracle/database:18.4.0-xe
```

The readme will provide some simple instructions, for additional container configuration options see: https://github.com/oracle/docker-images/tree/main/OracleDatabase/SingleInstance

For continuous development the following setup is recommended. It uses the pluggable database mechanism. This allows the creation of additional databases within this one instance. This is 
useful for having say, a fairly stable version of the schema for application development and a separate database for database feature development.

NOTE: If building manually from the github link images you may need additional parameters.

```
docker volume create cwmsdb_volume
docker network create cwmsdb_net
docker run -d --name cwmsdb -e ORACLE_PDB=CWMSDEV -e ORACLE_PWD="simplePassword0#" -p 1521:1521 -p 5500:5500 -p 2484:2484 \
-v cwms_db_volume:/opt/oracle/oradata --network cwmsdb_net \
registry.hecdev.net/oracle/database:19.17.0-ee

docker logs -f cwmsdb
# Now wait roughly 35-40 minutes for "Database ready to appear"
# Use `Ctrl-C` to disable the log display
# If you're machine is restarted do the following to bring it back up
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

`docker pull registy.hecdev.net/cwms/schema_installer:<version>`

where `<version>` can be:

- latest-dev
- 21.1.1
- latest
- etc 

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
            registry.hecdev.net/cwms/schema_installer:<version>
```

NOTE the dockerimage is not generally friendly for diagnosing thing as it's intended
for use after the build scripts have been verified. The buildCWMS_DB.log and other logging .txt
files will be printed to the schema installers stdout.


### Build for dev

It is recommend that you open the schema directory as the root directory in any IDE you should.

Copy the teamcity_overrides.xml to build/localoverrides.xml (or preferably to a directory outside the build tree) and alter the settings internally to match the test database you have either setup or had provided.

It is assumed that apex (20.1 at time of writing) has previously been installed in the database; failure to meet this condition will cause the build to fail. Additionally, the Oracle Instant client with the SQL*Plus and Tools packages is required to be set in the PATH variable. 

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

- We're not going to bump the version on everything change we'll leave the pom.xml at MAJOR-SNAPSHOT (I think we'll go ahead and push to nexus)
- We'll keep a running update script: update_18.1.8_to_99_99_99.sql (if you make a change the correct alteration commands should go in there.)
- When we do a release it will be a PR to a release branch (e.g. v18 or v18.1 or something, still working exactly what out.)
- We do appreciate developers creating their own update scripts for changes but also understand how difficult that is.

#### Versioning

There is a pom.xml file in the root directory that contains the current version. The version follows the following format:

    XX.YY.ZZ[-SNAPSHOT] 

XX-Year/major
YY-minor
ZZ[-SNAPSHOT] - patch

if you need the version anywhere in the build.xml file, use `${pom.version}` to extract.

SNAPSHOT will be appended to major versions while changes are merged in to master.

If minor is increased,reset the patch number to 0.

Year/major is for major changes, which due to the nature of how we change the database over time, often just ends up being a year

minor - new features that don't break anything

patch - bug fixes to existing code

## Docker Compose

There is a docker compose file to assist with certain developement. See the docker-compose.README.md file for additional details.

## Reviewers

Eric Novotny
Mike Neilson
Mike Perryman

## Confluence Documentation
There is a confluence page that contains more information about the database API. 
It is located at [CWMS Database Documentation](https://www.hec.usace.army.mil/confluence/display/CWMS/CWMS+Database+Documentation)
