import jetbrains.buildServer.configs.kotlin.v2019_2.*
import jetbrains.buildServer.configs.kotlin.v2019_2.buildFeatures.commitStatusPublisher
import jetbrains.buildServer.configs.kotlin.v2019_2.buildSteps.ant
import jetbrains.buildServer.configs.kotlin.v2019_2.buildSteps.script
import jetbrains.buildServer.configs.kotlin.v2019_2.buildSteps.exec
import jetbrains.buildServer.configs.kotlin.v2019_2.failureConditions.BuildFailureOnMetric
import jetbrains.buildServer.configs.kotlin.v2019_2.failureConditions.failOnMetricChange
import jetbrains.buildServer.configs.kotlin.v2019_2.triggers.vcs
import jetbrains.buildServer.configs.kotlin.v2019_2.triggers.finishBuildTrigger
import java.io.BufferedReader;
import java.io.File;

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

version = "2020.2"

project {

	params {
        param("teamcity.ui.settings.readOnly", "true")
    }
    sequential {
        buildType(Build)
        buildType(Deploy)
    }.buildTypes().forEach { buildType(it) }
    
}

object Helpers {
    fun readScript( path: String ): String {
        val bufferedReader: BufferedReader = File(path).bufferedReader()
        return bufferedReader.use { it.readText() }.trimIndent()
    }
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
        build/coverage.zip => /
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
            scriptContent = Helpers.readScript("scripts/setup_parameters.sh");
        }
        script {
            name = "Destroy Database In case of prevous failure"
            executionMode = BuildStep.ExecutionMode.ALWAYS
            scriptContent = Helpers.readScript("scripts/destroy_database.sh");            
        }
        script {
            name = "Create PDB"
            scriptContent = Helpers.readScript("scripts/create_database.sh")            
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
        }
        ant {
            name = "Install CWMS Database"
            mode = antFile {
            }
            targets = "clean,build"
            antArguments = "-Dbuilduser.overrides=output/overrides.xml"            
        }
        ant {
            targets = "test"
            antArguments = "-Dbuilduser.overrides=output/overrides.xml"            
        }
        script {
            name = "Destroy Database Since we are done"
            executionMode = BuildStep.ExecutionMode.ALWAYS
            scriptContent = Helpers.readScript("scripts/destroy_database.sh");            
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
        feature {
            type = "xml-report-plugin"
            param("xmlReportParsing.reportType", "junit")
            param("xmlReportParsing.reportDirs", "+:build/tests-*.xml")
        }
    }

    requirements {
        contains("docker.server.osType", "linux")
    }
})


object Deploy : BuildType({
    name = "Deploy to Nexus"

    artifactRules = """

    """.trimIndent()

    vcs {
        root(DslContext.settingsRoot)
    }

    params {        
        password("env.SYS_PASSWORD", "credentialsJSON:e335ba71-db80-4491-8ea3-a9ca51bfa6d7")
    }

    steps {
        exec {
            path = "echo"
            arguments = """"##teamcity[setParameter name='env.IS_DEPLOY' value='1']"""
        }
        script {
            name = "Generate Overrides file and Parameters"
            scriptContent = Helpers.readScript("scripts/setup_parameters.sh");
        }        
        script {
            name = "Create PDB"
            scriptContent = Helpers.readScript("scripts/create_database.sh")            
        }
        ant {
            name = "Install CWMS Database"
            mode = antFile {
            }
            targets = "clean,build"
            antArguments = "-Dbuilduser.overrides=output/overrides.xml"            
        }
        ant {
            name = "Build Bundle"
            mode = antFile {}
            targets = "deploy"
            antArguments = "-Dbuilduser.overrides=output/overrides.xml"            
        }
        script {
            name = "Destroy Database Since we are done"
            executionMode = BuildStep.ExecutionMode.ALWAYS
            scriptContent = Helpers.readScript("scripts/destroy_database.sh");            
        }        
    }

    triggers {
        finishBuildTrigger {
            buildType = "${Build.id}"
            successfulOnly = true
            branchFilter = """
                +:refs/heads/master
                +:refs/heads/release/*
                +:refs/tags/*
            """.trimIndent()

        }

    } 

    requirements {
        contains("docker.server.osType", "linux")
    }
    

})
