# CWMS Database

This repository contains the information necessary to both create a CWMS database from scratching as well as upgrade existing database.

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

All contributions will be made through a Pull Request. If you have write access to the repistory simply push your branch with the following:

    git push origin <branch name>

And then go to the bitbucket site and create the PR. 

Please do this as early as possible in your development cycle. This will help prevent duplication of work and open up a consistent communication channel. It is expected that ones initial submission will not meet all of the requirements and guidance will be provided.

For you code to be accepted it must successfully install into oracle and be approved by one of the people at the bottom of this readme in the the Reviewers section.

In the future we will enforce coding style standards and test coverage. 

If you do not have write access you may be able to fork it in bitbucket and submit a PR from the fork. If that doesn't work contact one of the Reviewers for access.


## build and testing

### build

copy the wcdba_overrides.xml or teamcity_overrides.xml to build/localoverrides.xml and alter the settings internally to match the test database you have either setup or had provided.

to build the database run the following:

   ant -Dbuilduser.overrides=build/local_overrides.xml clean build

*clean* will remove any existing schemas with the CWMS_20 name.

*build* will initialize the database.


### test

You must have utplsql from github.com/utPLSQL/utPLSQL-cli on your path. 
If you get the error that the oci version doesn't match while trying to run the tests remove all of the oracle jar from the utPLSQL-cli installation path *lib* directory and copy the ojdbc8.jar from your instantclient folder. (This issue has previously been reported to the utPLSQL team and should eventually be fixed.)

to run the tests 

   ant -Dbuilduser.overrides=build/local_overrides.xml test

The test framework will be installed and the tests will be run. The following files will be created:

- build/tests.log Information about how the test framework installation ran
- build/tests.xml Junit xml format for various reporting tools
- build/coverage.html Code coverage in a pretty HTML format.
- build/coverage.xml Code coverage in a format that TeamCity and others can pick up. the Cobertura format.


## Reviewers

Mike Neilson
Mike Perryman
Prasad Vemulapati

