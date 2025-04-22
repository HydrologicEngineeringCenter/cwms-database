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
        if (!url.isPresent()) {
            System.out.println("Starting new database");
            def config = DefaultDockerClientConfig.createDefaultConfigBuilder().build();
            def httpClient = new ApacheDockerHttpClient.Builder()
                            .dockerHost(config.getDockerHost())
                            .sslConfig(config.getSSLConfig())
                            .maxConnections(100)
                            .connectionTimeout(Duration.ofSeconds(30))
                            .responseTimeout(Duration.ofSeconds(45))
                            .build();
            def image = extension.image.get()
            def dockerClient = DockerClientImpl.getInstance(config,httpClient)
            dockerClient.pullImageCmd(image)
                        .withRegistry(config.registryUrl)
                        .start()
                        .awaitCompletion()
            def createContainer = dockerClient.createContainerCmd(image).withEnv("ORACLE_PASSWORD", "BadSysPassword")
            def response = createContainer.exec()
            
            props.url = "a test"
            props.username = "user"
            props.password = "pass"
        } else {
            System.out.println("Using existing database.");
            props["url"] = url.get()
            props["password"] = password.get()
            props["username"] = username.get()
        }

        url.finalizeValue()
        username.finalizeValue()
        password.finalizeValue()
        outputFile.finalizeValue();

        def out = outputFile.get().asFile
        out.delete()
        out << "[flyway]\n";
        props.each { entry ->
            out << "${entry.key}=${entry.value}\n"
        }
        out << "[flyway.placeholders]\n"
        out << "testaccounts=true\n";
        
    }
}