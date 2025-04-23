import com.github.dockerjava.api.DockerClient
import com.github.dockerjava.core.DockerClientConfig
import com.github.dockerjava.core.DockerClientImpl
import com.github.dockerjava.core.DefaultDockerClientConfig
import com.github.dockerjava.httpclient5.ApacheDockerHttpClient
import org.gradle.api.tasks.*
import org.gradle.api.DefaultTask
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.provider.Property
import java.time.Duration

public abstract class StopDatabaseTask extends DefaultTask {
    @Input
    @Optional
    public abstract Property<String> getUrl();

    @TaskAction
    void stop() {
        final var extension = project.extensions.getByType(DatabaseExtension)
        if (!url.isPresent()) {
            def name = extension.name.get()
            def container = DockerUtil.findContainer(name)
            if (container.isPresent()) {
                DockerUtil.stopContainer(container.get())
            }
        }
    }
}