import com.github.dockerjava.api.DockerClient
import com.github.dockerjava.api.exception.NotModifiedException
import com.github.dockerjava.api.model.Container
import com.github.dockerjava.api.model.ExposedPort
import com.github.dockerjava.core.DockerClientConfig
import com.github.dockerjava.core.DockerClientImpl
import com.github.dockerjava.core.DefaultDockerClientConfig
import com.github.dockerjava.httpclient5.ApacheDockerHttpClient
import java.time.Duration

public class DockerUtil {
    public static DockerClient getClient() {
        def config = DefaultDockerClientConfig.createDefaultConfigBuilder().build();
        def httpClient = new ApacheDockerHttpClient.Builder()
                        .dockerHost(config.getDockerHost())
                        .sslConfig(config.getSSLConfig())
                        .maxConnections(100)
                        .connectionTimeout(Duration.ofSeconds(30))
                        .responseTimeout(Duration.ofSeconds(45))
                        .build();
        def dockerClient = DockerClientImpl.getInstance(config,httpClient)
    }
   

    public static Optional<Container> findContainer(String name) {
        def containers = getClient().listContainersCmd()
                                    .withShowAll(true)
                                    .withNameFilter([name])
                                    .exec()
                       + getClient().listContainersCmd()
                                    .withShowAll(true)
                                    .withIdFilter([name])
                                    .exec()
        
        if (containers.size() == 0) {
            return Optional.empty()
        } else {
            return Optional.of(containers.get(0))
        }
    }    

    public static boolean startContainer(Container container) {
        try {
            getClient().startContainerCmd(container.getId()).exec()
            return true
        } catch(NotModifiedException ex) {
            return true
        }
    }

    public static boolean stopContainer(Container container) {
        try {
            getClient().stopContainerCmd(container.getId()).exec()
            return true
        } catch(NotModifiedException ex) {
            return true
        }
    }

    public static String getPortFor(Container container, int port) {
        def exposedPort = new ExposedPort(1521)
        def inspect = getClient().inspectContainerCmd(container.getId()).exec()
        def bindings = inspect.networkSettings.ports.bindings
        def ports = bindings.get(exposedPort)        
        return ports.hostPortSpec[0]

    }
}