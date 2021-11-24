import jetbrains.buildServer.configs.kotlin.v2019_2.*
import jetbrains.buildServer.configs.kotlin.v2019_2.buildFeatures.commitStatusPublisher
import jetbrains.buildServer.configs.kotlin.v2019_2.buildSteps.ant
import jetbrains.buildServer.configs.kotlin.v2019_2.buildSteps.script
import jetbrains.buildServer.configs.kotlin.v2019_2.buildSteps.gradle
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
        buildType(TestContainer)
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
        build/buildCWMS_DB.log => buildinfo/
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
            workingDir = "./schema"
            mode = antFile {
                path = "schema/build.xml"
            }
            targets = "docker.prepdb"
            antArguments = "-Dteamcity.branch=%teamcity.build.branch%_%teamcity.agent.name%"
        }
        ant {
            name = "Install CWMS Database"
            workingDir = "./schema"
            mode = antFile {
                path = "schema/build.xml"
            }
            targets = "docker.install"
            antArguments = "-Dteamcity.branch=%teamcity.build.branch%_%teamcity.agent.name%"
        }
        ant {
            name = "Run Tests"
            workingDir = "./schema"
            mode = antFile {
                path = "schema/build.xml"
            }
            targets = "test"
            antArguments = "-Dbuilduser.overrides=build/overrides.external.xml"
        }
        ant {
            workingDir = "./schema"
            mode = antFile {
                path = "schema/build.xml"
            }
            name = "Generate Bundle (will include generated artifacts)"
            targets = "bundle"
            antArguments = "-Dbuilduser.overrides=build/overrides.external.xml"
        }

        ant {
            name = "Cleanup Generated Files"
            workingDir = "./schema"
            mode = antFile {
                path = "schema/build.xml"
            }
            targets = "clean-output-files"
            antArguments = "-Dbuilduser.overrides=build/overrides.external.xml"
            conditions {
                matches("teamcity.build.branch", "(master|release/.*)")
            }
        }
        ant {
            name = "Push to Nexus"
            workingDir = "./schema"
            mode = antFile {
                path = "schema/build.xml"
            }
            targets = "deploy"
            antArguments = "-Dbuilduser.overrides=build/overrides.external.xml"
            conditions {
                matches("teamcity.build.branch", "(master|release/.*)")
            }
        }
        ant {
            name = "Stop database"
            workingDir = "./schema"
            mode = antFile {
                path = "schema/build.xml"
            }
            targets = "docker.stopdb"
            executionMode = BuildStep.ExecutionMode.ALWAYS
            antArguments = "-Dteamcity.branch=%teamcity.build.branch%_%teamcity.agent.name%"
        }
    }

    triggers {
        vcs {
        }
    }

    failureConditions {

        // Shouldn't ever take this long, but sometimes it happens with the creation
        // Of the oracle databases
        executionTimeoutMin = 180
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
            param("xmlReportParsing.reportDirs", "schema/build/tests*.xml")
        }
    }

    requirements {
        contains("docker.server.osType", "linux")
    }
})


object TestContainer : BuildType({
    name = "Build TestContainers"

    artifactRules = """
        build/libs/ =>
    """.trimIndent()

    params {

    }

    vcs {
        root(DslContext.settingsRoot)
    }

    steps {
        gradle {
            name = "Build"
            workingDir="testcontainers"
            tasks = "build"
            jdkHome ="%env.JDK_1_8_x64%"
        }
        gradle {
            name = "SonarQube Analysis"
            workingDir = "./testcontainers"

            tasks = ":sonarqube"
            gradleParams = "-Dsonar.login=%system.SONAR_TOKEN% -Dsonar.host.url=https://sonarqube.hecdev.net"
        }
        gradle {
            name = "Push to Nexus"
            workingDir = "./testcontainers"

            tasks = "publish"
            gradleParams = "-DmavenUser=%env.NEXUS_USER% -DmavenPassword=%env.NEXUS_PASSWORD%"
            jdkHome ="%env.JDK_1_8_x64%"
            conditions {
                matches("teamcity.build.branch", "(master|release/.*)")
            }
        }
    }

    triggers {
        vcs {
        }
    }

    failureConditions {
        executionTimeoutMin = 180
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