package cwms.database.testing.support;

import org.gradle.api.GradleException;
import org.gradle.api.provider.Property;
import org.gradle.api.services.BuildService;
import org.gradle.api.services.BuildServiceParameters;

public abstract class DatabaseService implements BuildService<DatabaseService.Params>, AutoCloseable
{
    interface Params extends BuildServiceParameters
    {
        Property<String> getUrl();
        Property<String> getJdbcUrl();
        Property<String> getSysPassword();
        Property<String> getBuildUserName();
        Property<String> getBuildUserPassword();
        Property<String> getEroc();
        Property<String> getOfficeId();
        Property<String> getSchema();
        Property<Boolean> getCreateTestAccounts();
        Property<String> getTestAccountPassword();
        Property<Boolean> getCreateTestDatabase();
        Property<String> getDatabaseImage();
        Property<String> getContainerName();
    }

    private final boolean createDatabase;
    private boolean databaseRunning = false;
    
    public DatabaseService()
    {
        var parameters = getParameters();
        createDatabase = parameters.getCreateTestDatabase().get();
        if (!createDatabase) {
            // If the user has passed in specific database information it's on them to 
            // make sure it's running.
            databaseRunning = true;
        }
    }

    private synchronized void checkDatabase() {
        if (databaseRunning) {
            return;
        } else if (createDatabase) {
            System.out.println("Starting Database");
            databaseRunning = startDatabase();
            if (databaseRunning) {
                return;
            }
        }
        throw new GradleException("Database is not running.");
    }

    public String getJdbcUrl()
    {
        checkDatabase();
        return getParameters().getJdbcUrl().get();
    }

    public String getUrl() {
        checkDatabase();
        return getParameters().getUrl().get();
    }

    public String getBuildUser() {
        checkDatabase();
        return getParameters().getBuildUserName().get();
    }

    public String getBuildUserPassword() {
        checkDatabase();
        return getParameters().getBuildUserPassword().get();
    }

    public String getSysPassword() {
        checkDatabase();
        return getParameters().getSysPassword().get();
    }

    public String getTestAccountPassword() {
        checkDatabase();
        return getParameters().getTestAccountPassword().get();
    }

    public String getSchemaName() {
        checkDatabase();
        return getParameters().getSchema().get();
    }

    public String getCwmsUser() {
        checkDatabase();
        var buildUser = getParameters().getBuildUserName().get();
        var schema = getParameters().getSchema().get();
        return String.format("%s[%s]", buildUser, schema);
    }

    public String getEroc() {
        checkDatabase();
        return getParameters().getEroc().get();
    }

    public String getOfficeId() {
        checkDatabase();
        return getParameters().getOfficeId().get();
    }


    @Override
    public void close()
    {
        /* currently do nothing. */
    }


    private boolean startDatabase() {
        // Don't call the other class methods in here
        // They call call checkDatabase which might loop back here.
        var database = new DockerDatabase(getParameters());
        return database.start();
    }
}