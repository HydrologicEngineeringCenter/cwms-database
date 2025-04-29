package cwms.database.testing.support;

import org.gradle.api.DefaultTask;
import org.gradle.api.file.RegularFileProperty;
import org.gradle.api.provider.Property;
import org.gradle.api.services.ServiceReference;
import org.gradle.api.tasks.OutputFile;
import org.gradle.api.tasks.TaskAction;

public abstract class DatabaseStartTask extends DefaultTask
{
    @ServiceReference("database")
    abstract Property<DatabaseService> getDatabaseService();

    @TaskAction
    public void startDatabase()
    {
        var databaseService = getDatabaseService().get();
        System.out.println("Starting database at " + databaseService.getJdbcUrl());
    }
}