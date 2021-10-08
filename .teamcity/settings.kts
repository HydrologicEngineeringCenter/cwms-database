import jetbrains.buildServer.configs.kotlin.v2019_2.*
import jetbrains.buildServer.configs.kotlin.v2019_2.buildFeatures.commitStatusPublisher
import jetbrains.buildServer.configs.kotlin.v2019_2.buildSteps.maven
import jetbrains.buildServer.configs.kotlin.v2019_2.buildSteps.script
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

version = "2021.1"


project {

    params {
        param("teamcity.ui.settings.readOnly", "true")
    }

    sequential {
        buildType(Build)
        buildType(Deploy)


    }.buildTypes().forEach { buildType(it) }

}


object Build : BuildType({
    name = "Build Libraries"
    // artifacts rules place your generated output in a place it can be downloaded or sent to another Build configuration
    artifactRules = """
        **/target/*.jar =>
    """.trimIndent()


    params {

    }

    vcs {
        root(DslContext.settingsRoot)
    }

    steps {
        maven {
            name = "Compile"
            goals = "compile -U"
            userSettingsSelection = "sc_settings.xml"
            pomLocation = "pom.xml"
            mavenVersion = bundled_3_6()
        }
        maven {
            name = "Tests"
            goals = "verify"
            userSettingsSelection = "sc_settings.xml"
            pomLocation = "pom.xml"
            mavenVersion = bundled_3_6()
        }
        script {
            name = "read in coverage"
            scriptContent = """
                echo "##teamcity[jacocoReport ./target/jacoco.exec']"
            """.trimIndent()
        }
        maven {
            name = "Analysis"
            goals = "sonar:sonar"
            userSettingsSelection = "sc_settings.xml"
            pomLocation = "pom.xml"
            runnerArgs = "-Dsonar.login=%system.SONAR_TOKEN% -Dsonar.host.url=%system.SONAR_URL%"
            mavenVersion = bundled_3_6()
        }
    }

    triggers {
        vcs {
        }
    }

    failureConditions {
        executionTimeoutMin = 5
    }

    features {
        commitStatusPublisher {
            publisher = bitbucketServer {
                url = "https://bitbucket.hecdev.net"
                userName = "builduser"
                password = "credentialsJSON:a8e6f8db-975b-4af8-844f-e203b50e37f2"
            }
        }
        feature {
            type = "halfbaked-sonarqube-report-plugin"
        }
    }

    requirements {
        exists("docker.version")
    }
})


object Deploy : BuildType({
    name = "Deploy to Nexus"

    artifactRules = """

    """.trimIndent()

    vcs {
        root(DslContext.settingsRoot)
    }

    steps {
        maven {
            name = "Publish"
            goals = "deploy"
            pomLocation = "pom.xml"
            mavenVersion = bundled_3_6()
            userSettingsSelection = "sc_settings.xml"
        }
    }

    // for this example deployed releases will always from from master
    // you could choose any other valid branch filter.
    triggers {
        finishBuildTrigger {
            buildType = "${Build.id}"
            successfulOnly = true
            branchFilter = """
                +:<default>
            """.trimIndent()

        }
    }

    requirements {
        exists("docker.version")
    }


})
