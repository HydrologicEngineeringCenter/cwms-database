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

It it assumed that apex (20.1 at time of writing) has previusly been installed in the database; failure to meet this condition will cause the build to ail.

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
- build/coverage.xml Code coverage in a format that TeamCity and others can pick up. It is the Cobertura format.

### Modifying the build

For simple modifications provide a pull request with the build code modified as normal.

If you want to create a new build configuration you will first need to submit a pull request with the code with the build steps commented out but otherwise generating the new configuration. 
Once everyone agrees on this new step we will merge it into master, which will cause teamcity to generate and link the new configuration, and you will need to continue further on a new branch so that TeamCity can actually run the steps. This is a current limitation of TeamCity. 


### Update scripts and Releases

There will be a running update script in master that will be update_<last release>_current. If you make any changes include those updates within this script.

1. This will help simplify the release process for whoever decides the release.
1. It will put the part of the burden of verifying a feature made it to user on the original developer.
1. We intend to setup in testing automated updates.
  a. This will involve running all tests again so it will wait for some of the build server expansion; but keep it in mind.

When a release is determined to be made we'll decide on the number we'll create a long running release branch and update the relevant portions of the scripts to match. At that point the only code changes that should be made to that branch are "hot fixes." The working named update script should be immediately merged into master leaving the branch active (bit bucket is set to prevent all release/ branches from being delete so if you forget to uncheck the delete branch button the interface will stop you.)

#### Versioning

There is a pom.xml file in the root directory that contains the currentversion. The version follows the following format:

    XX.YY.ZZ[-SNAPSHOT] 

XX-Year/major
YY-minor
ZZ[-SNAPSHOT] - patch

if you need the version anywhere in thebuild.xml fileuse `${pom.version}` to extract.

SNAPSHOT will be appened to major versions while changes are merged in to master.

If minor is increased,reset the patch numberto 0.

Year/major is for major changes,which due to the nature of how we change the database over time often just ends up being a year

minor - new features that don't break anything

patch - bug fixes to existing code

## Reviewers

Mike Neilson
Mike Perryman
Prasad Vemulapati

