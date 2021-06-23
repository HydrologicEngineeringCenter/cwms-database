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

### build

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

