import org.gradle.api.provider.Property

interface DatabaseExtension {
    Property<String> getUrl();
    Property<String> getJdbcUrl();
    Property<String> getImage();
    Property<String> getName();
    Property<String> getBuildUser();
    Property<String> getBuildUserPassword();
    Property<String> getCwmsOfficeId();
    Property<String> getCwmsOfficeEroc();
    Property<String> getCwmsPassword();
    Property<String> getCreateUsers();
    Property<String> getCwmsUser();
    Property<String> getSchemaName();
}
