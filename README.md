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

# Docker Compose

The Compose file `docker-compose.yml` is a [YAML](https://yaml.org/) file defining services, networks and volumes for `cwms_database` application.  Included services are `database`, `schema`, `cwms-data` and `radar`.  Each of these services are listed in detail below.

### Docker Network and Volume

The Compose file defines the network and volume as external.  Therefore, these will need to be created before starting services.

Terminal:

- docker network create ***network-name-in-compose***
- docker volume create ***volume-name-in-compose***

### Docker Compose UP

Some defined services are dependent on others.  This does require a startup sequence with Compose and not starting everything at the same time.  The `database` service must be started first and ready before initializing the schema.  After the database is ready and the schema install has completed, `cwms-data` service can start.  The schema install and cwms-data services do not have to stay `alive` and will stop after their completion.  The `radar` service can start without dependencies but typically started last.


Terminal:

- docker compose up [--build] database
- docker compose up [--build] schema
- docker compose up [--build] cwms-data
- docker compose up [--build] radar

## Docker Compose Services
----
### Database

Oracle container using image `registry.hecdev.net/oracle/database:19.3.0-ee`.  Two of the three environment variables can be modified but are already set to support local development.  Changing variable values does require updating environement variables in the other services.

### Schema

CWMS Schema Installer is this repository building from context `./schema`.  Environment variables are set for local development.  Modifying any of these values will require updating other services environment variable values.

### CWMS Data

CWMS Data service is a container running Ubuntu and local Python package `cwmsdata` to initialize the CWMS database with locations (`usgs-sites`) and time series (`usgs-ts`).  Both `usgs-sites` and `usgs-ts` are command-line tools that take similar arguments to filter sites by [HUC](http://water.usgs.gov/GIS/huc_name.html), list of locations ([NWIS Mapper](http://maps.waterdata.usgs.gov/mapper/)) and/or [parameter codes](http://help.waterdata.usgs.gov/codes-and-parameters/parameters).

An entry point shell script (`entrypoint.sh`) can be used to execute `cwmsdata` command-line tools `usgs-sites` or `usgs-ts`.  The following is the usage for `entrypopint.sh`

    a) # Keep the container alive
    c) # Switches for commands
    s) # Run usgs-sites
    t) # Run usgs-ts
    h) # Print usage message

Example `CMD` entry for `entrypoint.sh` that loads sites and time series data in Hydrologic Unit Code (HUC) area `05130105` for parameters `00060` and `00065`.

```
CMD [ "-st", "-c", "--huc 05130105 --parameter_code 00060 00065" ]
```


### Radar

The Compose file references [USACE/cwms-radar-api](https://github.com/USACE/cwms-radar-api) locally with a relative path.  Modify the `radar:build:context` path according to local setup.

----

### build for dev

copy the wcdba_overrides.xml or teamcity_overrides.xml to build/localoverrides.xml and alter the settings internally to match the test database you have either setup or had provided.

It is assumed that apex (20.1 at time of writing) has previously been installed in the database; failure to meet this condition will cause the build to fail. Additionally, the Oracle Instant client with the SQL*Plus and Tools packages is required to be set in the PATH variable. 

to build the database run the following:

    ant -Dbuilduser.overrides=build/local_overrides.xml clean build

*clean* will remove any existing schemas with the CWMS_20 name.

*build* will initialize the database.


### test

You must have utplsql from github.com/utPLSQL/utPLSQL-cli on your path. 
If you get the error that the oci version doesn't match while trying to run the tests remove all of the oracle jar from the utPLSQL-cli installation path *lib* directory and copy the ojdbc8.jar from your instantclient folder. (This issue has previously been reported to the utPLSQL team and should eventually be fixed.)

to run the tests 

   ant -Dbuilduser.overrides=build/local_overrides.xml test

The test framework will be installed, and the tests will be run. The following files will be created:

- build/tests.log Information about how the test framework installation ran
- build/tests.xml Junit xml format for various reporting tools
- build/coverage.html Code coverage in a pretty HTML format.
- build/coverage.xml Code coverage in a format that TeamCity and others can pick up. It is the Cobertura format.

### Modifying the build

For simple modifications provide a pull request with the build code modified as normal.

If you want to create a new build configuration you will first need to submit a pull request with the code with the build steps commented out but otherwise generating the new configuration. 
Once everyone agrees on this new step we will merge it into master, which will cause teamcity to generate and link the new configuration, and you will need to continue further on a new branch so that TeamCity can actually run the steps. This is a current limitation of TeamCity. 


### Update scripts and Releases

-  We're not going to bump the version on everything change we'll leave the pom.xml at MAJOR-SNAPSHOT (I think we'll go ahead and push to nexus)
- We'll keep a running update script: update_18.1.8_to_99_99_99.sql (if you make a change the correct alteration commands should go in there.)
- When we do a release it will be a PR to a release branch (e.g. v18 or v18.1 or something, still working exactly what out.)

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

## Reviewers

Mike Neilson
Mike Perryman
Prasad Vemulapati

## Confluence Documentation
There is a confluence page that contains more information about the database API. 
It is located at [CWMS Database Documentation](https://www.hec.usace.army.mil/confluence/display/CWMS/CWMS+Database+Documentation)