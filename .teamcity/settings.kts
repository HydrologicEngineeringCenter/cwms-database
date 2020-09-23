import jetbrains.buildServer.configs.kotlin.v2019_2.*
import jetbrains.buildServer.configs.kotlin.v2019_2.buildFeatures.commitStatusPublisher
import jetbrains.buildServer.configs.kotlin.v2019_2.buildSteps.ant
import jetbrains.buildServer.configs.kotlin.v2019_2.buildSteps.script
import jetbrains.buildServer.configs.kotlin.v2019_2.failureConditions.BuildFailureOnMetric
import jetbrains.buildServer.configs.kotlin.v2019_2.failureConditions.failOnMetricChange
import jetbrains.buildServer.configs.kotlin.v2019_2.triggers.vcs

/*
The settings script is an entry point for defining a TeamCity
project hierarchy. The script should contain a single call to the
project() function with a Project instance or an init function as
an argument.

VcsRoots, BuildTypes, Templates, and subprojects can be
registered inside the project using the vcsRoot(), buildType(),
template(), and subProject() methods respectively.

To debug settings scripts in command-line, run the

    mvnDebug org.jetbrains.teamcity:teamcity-configs-maven-plugin:generate

command and attach your debugger to the port 8000.

To debug in IntelliJ Idea, open the 'Maven Projects' tool window (View
-> Tool Windows -> Maven Projects), find the generate task node
(Plugins -> teamcity-configs -> teamcity-configs:generate), the
'Debug' option is available in the context menu for the task.
*/

version = "2020.1"

project {
	params {
        param("teamcity.ui.settings.readOnly", "true")
    }
    buildType(Build)
}

object Build : BuildType({
    name = "Build (create in oracle)"

    artifactRules = """
        output/database.info => database/
        output/users.txt => database/
        output/build-sql-script-output.txt => buildinfo/
        output/build-sql-script-error.txt => buildinfo/
        output/overrides.xml => buildinfo/
        src/buildCWMS_DB.log => buildinfo/
    """.trimIndent()

    params {
        param("env.OFFICE_CODE", "e1")
        param("env.HOST_AND_PORT", "cwms-docker1.hecdev.net:1521")
        param("env.ContainerDB", "ROOTDB")
        param("env.OFFICE_ID", "NAB")
        password("env.SYS_PASSWORD", "credentialsJSON:e335ba71-db80-4491-8ea3-a9ca51bfa6d7")
    }

    vcs {
        root(DslContext.settingsRoot)
    }

    steps {
        script {
            name = "Generate Overrides file and Parameters"
            scriptContent = """
                if [ -d output ]; then
                	rm -rf output
                fi
                mkdir output
                export PW=`tr -cd '[:alnum:]' < /dev/urandom | fold -w25 | head -n1`
                
                export CWMS_PDB=`echo %teamcity.build.branch% | sed -e "s@/refs/heads/@@g" | sed "s@/@_@g" | sed "s@\.@_@g"`
                if [[ ${'$'}CWMS_PDB =~ ^[0-9]+${'$'} ]]; then
                	echo "prefixing pull request number with text."
                    export CWMS_PDB="PULLREQUEST_${'$'}{CWMS_PDB}"
                elif [[ ${'$}CWMS_PDB =~ ^[0-9] ]]; then
                    # while not a pull request, it still needs an alpha prefix.
                    echo "prefixing with letter"
                    export CWMS_PDB="z_${'$'}{CWMS_PDB}"
                fi
                cat <<EOF
                ##teamcity[setParameter name='env.CWMS_PDB' value='${'$'}CWMS_PDB']
                
                EOF
                
                echo "=${'$'}CWMS_PDB="
                
                sed -e "s/SYS_PASSWORD/${'$'}SYS_PASSWORD/g" \
                    -e "s/PASSWORD/${'$'}PW/g" \
                    -e "s/HOST_AND_PORT/${'$'}HOST_AND_PORT/g" \
                    -e "s/SERVICE_NAME/${'$'}CWMS_PDB/g" \
                    -e "s/OFFICE_ID/${'$'}OFFICE_ID/g" \
                    -e "s/OFFICE_CODE/${'$'}OFFICE_CODE/g" \
                    -e "s/TEST_ACCOUNT_FLAG/-testaccount/g" teamcity_overrides.xml > output/overrides.xml
                cat <<EOF
                ##teamcity[setParameter name='env.CWMS_PASSWORD' value='${'$'}PW']
                
                EOF
                
                echo "${'$'}CWMS_PDB" > output/database.info
                echo "${'$'}PW" >> output/database.info
                exit 0
            """.trimIndent()
        }
        script {
            name = "Destroy Database"
            executionMode = BuildStep.ExecutionMode.ALWAYS
            scriptContent = """
                sqlplus sys/${'$'}SYS_PASSWORD@${'$'}HOST_AND_PORT/${'$'}ContainerDB as SYSDBA <<EOF
                	ALTER PLUGGABLE DATABASE ${'$'}CWMS_PDB CLOSE;
                	DROP PLUGGABLE DATABASE ${'$'}CWMS_PDB INCLUDING DATAFILES;      
                EOF
            """.trimIndent()
            dockerImage = "cwms_db_dev:latest"
        }
        script {
            name = "Create PDB"
            scriptContent = """
                sqlplus sys/${'$'}SYS_PASSWORD@${'$'}HOST_AND_PORT/${'$'}ContainerDB as SYSDBA <<EOF | grep "ORA-65012: Pluggable database REFS_HEADS_MASTER already exists"
                alter session set PDB_FILE_NAME_CONVERT='/opt/oracle/oradata/ROOTDB/CWMSBASE/','/opt/oracle/oradata/ROOTDB/${'$'}{CWMS_PDB}/';
                CREATE PLUGGABLE DATABASE ${'$'}CWMS_PDB from CWMSBASE;
                ALTER PLUGGABLE DATABASE ${'$'}CWMS_PDB OPEN READ WRITE;
                EOF
                if [ ${'$'}? -eq 0 ]; then
                	echo "Database wasn't correctly destroyed" 1>&2
                    exit 1
                fi
            """.trimIndent()
            dockerImage = "cwms_db_dev:latest"
        }
        script {
            name = "Create Tablespaces"
            enabled = false
            scriptContent = """
                sqlplus sys/${'$'}SYS_PASSWORD@${'$'}HOST_AND_PORT/${'$'}CWMS_PDB as SYSDBA <<EOF
                define data_file_prefix=/opt/oracle/oradata/${'$'}CWMS_PDB
                CREATE TABLESPACE USERS DATAFILE '&data_file_prefix.users.dbf' SIZE 8M autoextend on next 2M;
                CREATE TABLESPACE "CWMS_20AT_DATA" DATAFILE '&data_file_prefix.cmws_at_data.tblspc' SIZE  2m AUTOEXTEND ON NEXT 20m;
                CREATE TABLESPACE "CWMS_20DATA" DATAFILE '&data_file_prefix.cwms_data.tblspc' SIZE 2m AUTOEXTEND ON NEXT 20m;
                CREATE TABLESPACE "CWMS_20_TSV" DATAFILE '&data_file_prefix.cwms_tsv.tblspc' SIZE 2m AUTOEXTEND ON NEXT 20m;
                CREATE TABLESPACE "CWMS_AQ" DATAFILE '&data_file_prefix.cwms_aq.tblspc' SIZE 2m AUTOEXTEND ON NEXT 20m;
                CREATE TABLESPACE "CWMS_AQ_EX" DATAFILE '&data_file_prefix.cwms_aq_ex.tblspc' SIZE 2m AUTOEXTEND ON NEXT 20m;
                EOF
            """.trimIndent()
            dockerImage = "cwms_db_dev:latest"
        }
        ant {
            name = "Install CWMS Database"
            mode = antFile {
            }
            targets = "clean,build"
            antArguments = "-Dbuilduser.overrides=output/overrides.xml"
            dockerImage = "cwms_db_dev:latest"
        }
        script {
            name = "Create Basic Users"
            scriptContent = """
                sqlplus cwms_20/${'$'}CWMS_PASSWORD@${'$'}HOST_AND_PORT/${'$'}CWMS_PDB << EOF
                  --execute cwms_sec.create_cwmsdbi_db_user( 'q0cwpa64', '${'$'}CWMS_PASSWORD', '${'$'}OFFICE_ID');
                  execute cwms_sec.create_user('basic_user','${'$'}CWMS_PASSWORD', char_32_array_type('CWMS Users'), '${'$'}OFFICE_ID');
                  execute cwms_sec.update_edipi('basic_user',1000000000);
                  
                  execute cwms_sec.create_user('user_admin','${'$'}CWMS_PASSWORD', char_32_array_type('CWMS Users', 'CWMS User Admins'), '${'$'}OFFICE_ID');
                  execute cwms_sec.update_edipi('user_admin',2000000000);
                  
                  execute cwms_sec.create_user('pd_user','${'$'}CWMS_PASSWORD', char_32_array_type('CWMS Users', 'CWMS PD Users','CWMS User Admins'), '${'$'}OFFICE_ID');
                  execute cwms_sec.update_edipi('pd_user',3000000000);
                EOF
                
                if [ ${'$'}? -ne 0 ]; then
                  echo "Failed to create CWMS Users."
                  exit 1
                fi
                
                echo "BASIC_USER:1000000000:All Users,CWMS Users" > output/users.txt
                echo "USER_ADMIN:2000000000:All Users,CWMS Users,CWMS User Admins" >> output/users.txt
                echo "PD_USER:3000000000:All Users,CWMS Users,CWMS PD Users,CWMS User Admins" >> output/users.txt
            """.trimIndent()
            dockerImage = "cwms_db_dev:latest"
        }
    }

    triggers {
        vcs {
        }
    }

    failureConditions {
        executionTimeoutMin = 15
        failOnMetricChange {
            metric = BuildFailureOnMetric.MetricType.ARTIFACT_SIZE
            units = BuildFailureOnMetric.MetricUnit.DEFAULT_UNIT
            comparison = BuildFailureOnMetric.MetricComparison.MORE
            compareTo = value()
            stopBuildOnFailure = true
            param("metricThreshold", "20MB")
        }
    }

    features {
        commitStatusPublisher {
            publisher = bitbucketServer {
                url = "https://bitbucket.hecdev.net"
                userName = "builduser"
                password = "credentialsJSON:0c6a7d80-71bc-4c22-931e-1f6999bcc0f1"
            }
        }
    }

    requirements {
        contains("docker.server.osType", "linux")
    }
})
