import org.gradle.api.provider.Property

interface DatabaseExtension {
    Property<String> getImage();
    Property<String> getBuildUser();
    Property<String> getBuildUserPassword();
}
