package org.opendcs.support;

import org.gradle.api.provider.Property;
import org.gradle.api.services.BuildService;
import org.gradle.api.services.BuildServiceParameters;

abstract class DatabaseService implements BuildService<DatabaseService.Params>, AutoCloseable
{
    interface Params extends BuildServiceParameters
    {
        Property<String> getJdbcUrl();
        Property<String> getSysPassword();
        Property<String> getBuildUserName();
        Property<String> getBuildUserPassword();
        Property<String> getEroc();
        Property<String> getOfficeId();
        Property<String> getSchema();
        Property<String> getCreateTestAccounts();
        Property<String> getTestAccountPassword();
        Property<Boolean> getCreateTestDatabase();
    }

    private final boolean createDatabase;
    private final String jdbcUrl;
    private boolean databaseRunning = false;

    public DatabaseService()
    {
        var parameters = getParameters();
        createDatabase = parameters.getCreateTestDatabase().get();
        jdbcUrl = parameters.getJdbcUrl().get();
    }

    public String getJdbcUrl()
    {
        if (!databaseRunning)
        {
            databaseRunning = true;
        }
        return jdbcUrl;
    }

    @Override
    public void close()
    {
        /* currently do nothing. */
    }
}
