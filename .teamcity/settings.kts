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
        build/resources => resources.zip
        build/resources.jar =>
        build/docs.zip =>
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
            name = "Setup Path variables"
            scriptContent = Helpers.readScript("scripts/setup_parameters.sh")

        }
        ant {
            name = "Prep Oracle"
            targets = "docker.prepdb"
            antArguments = "-Dteamcity.branch=%teamcity.build.branch%"
        }
        ant {
            name = "Install CWMS Database"
            targets = "clean,build"
            mode = antFile {
            }
            antArguments = "-Dbuilduser.overrides=build/overrides.external.xml"
        }
        ant {
            name = "Run Tests"
            targets = "test"
            antArguments = "-Dbuilduser.overrides=build/overrides.external.xml"
        }
        ant {
            name = "Run Generate Test Bundle (will include generated artifacts)"
            targets = "bundle"
            antArguments = "-Dbuilduser.overrides=build/overrides.external.xml"
        }
        ant {
            name = "Stop database"
            targets = "docker.stopdb"
            executionMode = BuildStep.ExecutionMode.ALWAYS
            antArguments = "-Dteamcity.branch=%teamcity.build.branch%"
        }
    }

    triggers {
        vcs {
        }
    }

    failureConditions {
        executionTimeoutMin = 45
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
            param("xmlReportParsing.reportDirs", "build/tests*.xml")
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
            name = "Cleanup Generated Files"
            targets = "clean-output-files"
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
                +:<default>
                +:release/*
            """.trimIndent()

        }

    }

    requirements {
        contains("docker.server.osType", "linux")
    }


})
