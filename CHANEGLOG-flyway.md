# General

All code is executed as part of a simple JDBC:thin driver call.
as such you can't use defines, set output, show errors, etc.


## defines 

defines are replaced with flyway placeholders:

| ant/sqlplus | flyway |
|-------------|--------|
|&cwms_schema | ${CWMS_SCHEMA} |
|&office_id    | ${CWMS_OFFICE_ID}|
|&eroc  | ${CWMS_OFFICE_EROC} |


## Conditional sql

Placeholders are expanded BEFORE the sql is sent to the database. You can use placeholder variables and anonymous procedures to handle conditional operations.

## Schema User

New versions of Oracle support a SCHEMA USER/OWNER that doesn't have a password. This is currently done for the CWMS_20 and CWMS_DBA schema. If you need to revert to default behavior override the CWMS_SCHEMA_AUTH or CWMS_DBA_AUTH placeholder variables with the appropriate `identified by <...>` syntax.

# The schema migrate is split into 2 parts.

1. The baseline schema run as the "BUILD USER"
2. The data run as CWMS_20. 

The build system will use the user names and passwords you give it and grant itself proxy access to CWMS_20 to create things like the spatial indexes. 

This is due to a limitation of no being in sqlplus, we can't change to a different user.

# test users creation

Mechanism is still in play, pass

`-Pflyway.placeholders.CWMS_TEST_USERS=create`

as part of the flyway command line


# Session Contexts

Session contexts were moved to a single afterMigrate Script

# After Migrate

For anything that needs to be rebuilt or done after other things put the code in afterMigrate__&lt;name&gt;.sql scripts. Code *MUST* be repeatable as these are always run.

# Data

## Generated

Flyway supports migrations in the form of Java code. The generated data, like all the QUALITY rows, are being moved thereto.

In the case of quality there's a bunch of .json file that the migration loads. However any method of storage and processing is acceptable. It should just make sense for the data at hand. Ex. the Quality was migrated to JSON as it was in python dictionaries.

Generated data should generally be repeatable migrations. This makes it easier for people to add new elements.


## Load

To prepare for a future where we move away from oracle the data loads are getting moved to CSV files with a custom executor. THe current format (at time of commit of this file) is not final.

The final format will be as follows

&lt;data set name&gt;.load
&lt;data set name&gt;.csv

.load will contain the appropriate insert or merge commands and evaluation of the CSV.

At present we're doing some regex magic for validation. Other ideas could be a proper CSV handling library. I'm open to ideas.

# Tests
The tests are still using sqlplus/sqlloader. This is partly to save time and partly because test will only be run on a dev machine and it's reasonable to expect all those tools.

However this is subject to change.


# Running the build

Example commandline; this assume as database has been made that has an appropriate CWMS_EXTRA (build user) already setup.

This will run the `flywayMigrate` task which does the intial load followed by the `dataMigrate` task which builds and loads the data then loads the test data and runs the tests.

NOTE: DO NOT RUN THE TESTS ON A PRODUCTION DATABASE, they are very destructive.

`./gradlew --no-daemon -Pflyway.url=jdbc:oracle:thin:@//localhost:1521/FEATURES -Pcwms.user=CWMS_EXTRA -Pflyway.password=extrauser -Pdb.sys_password=vmwaresys -Pflyway.placeholders.CWMS_TEST_USERS=create  test --info`

all of the -P settings can be set in a local gradle.properties or the user $HOME/.gradle/gradle.properties
