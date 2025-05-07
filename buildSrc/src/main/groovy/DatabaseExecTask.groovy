import org.gradle.api.tasks.*
import org.gradle.api.DefaultTask
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.provider.Property

public abstract class DatabaseExecTask extends Exec {
    @Input
    public abstract Property<String> getUrl();

    @Input
    public abstract Property<String> getUser();

    @Input
    public abstract Property<String> getPassword();

    @Input
    @Optional
    public abstract Property<String> getSysPassword();

}