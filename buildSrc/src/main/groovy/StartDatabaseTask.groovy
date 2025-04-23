import com.github.dockerjava.api.DockerClient
import com.github.dockerjava.api.model.ExposedPort
import com.github.dockerjava.api.model.PortBinding
import com.github.dockerjava.api.model.HostConfig
import com.github.dockerjava.core.DockerClientConfig
import com.github.dockerjava.core.DockerClientImpl
import com.github.dockerjava.core.DefaultDockerClientConfig
import com.github.dockerjava.httpclient5.ApacheDockerHttpClient
import org.gradle.api.tasks.*
import org.gradle.api.DefaultTask
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.provider.Property
import java.time.Duration

public abstract class StartDatabaseTask extends DefaultTask {
    @Input
    @Optional
    public abstract Property<String> getUrl();

    @Input
    @Optional
    abstract Property<String> getUsername();

    @Input
    @Optional
    abstract Property<String> getPassword();

    @OutputFile
    abstract RegularFileProperty getOutputFile();

    @TaskAction
    void startOrValidateDatabase() {
        final var extension = project.extensions.getByType(DatabaseExtension)
        def props = [:]
        def placeholders = [:]
        placeholders.CWMS_TEST_USERS = "create"

        if (!url.isPresent()) {
            System.out.println("Starting new database");
            def image = extension.image.get()
            def name = extension.name.get()
            def container = DockerUtil.findContainer(name)
            def dockerClient = DockerUtil.getClient()

            if (!container.isPresent()) {
                dockerClient.pullImageCmd(image)
                            .start()
                            .awaitCompletion()

                def createContainer = dockerClient.createContainerCmd(image)
                                                .withEnv("ORACLE_PASSWORD=${password.get()}")
                                                .withName(name)
                                                .withExposedPorts(new ExposedPort(1521))
                                                .withHostConfig(
                                                    HostConfig.newHostConfig()
                                                              .withPortBindings(PortBinding.parse("1521"))
                                                )

                def containerResponse = createContainer.exec()
                container = DockerUtil.findContainer(containerResponse.getId())
            }
            DockerUtil.startContainer(container.get())
            def port = DockerUtil.getPortFor(container.get(),1521)

            props.url = "jdbc:oracle:thin:@localhost:${port}/FREEPDB1"
            props.user = username.get()
            props.password = password.get()
            placeholders.PD_PASSWORD = extension.cwmsPassword.get()
            placeholders.TEST_PASSWORD = extension.cwmsPassword.get()
            placeholders.CWMS_OFFICE_ID = extension.cwmsOfficeId.get()
            placeholders.CWMS_OFFICE_EROC = extension.cwmsOfficeEroc.get()
        } else {
            System.out.println("Using existing database.");
            props.url = url.get()
            props.password = password.get()
            props.user = username.get()
        }

        url.finalizeValue()
        username.finalizeValue()
        password.finalizeValue()
        outputFile.finalizeValue();

        def out = outputFile.get().asFile
        out.delete()
        props.each { entry ->
            out << "flyway.${entry.key}=${entry.value}\n"
        }
        placeholders.each { entry ->
            out << "flyway.placeholders.${entry.key}=${entry.value}\n";
        }
    }
}