import org.gradle.api.provider.Property

interface DatabaseExtension {
    Property<String> getImage();
    Property<String> getName();
    Property<String> getBuildUser();
    Property<String> getBuildUserPassword();
    Property<String> getCwmsOfficeId();
    Property<String> getCwmsOfficeEroc();
    Property<String> getCwmsPassword();
    Property<String> getCreateUsers();
}
