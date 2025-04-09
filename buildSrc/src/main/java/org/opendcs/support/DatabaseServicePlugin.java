package org.opendcs.support;

import org.gradle.api.Plugin;
import org.gradle.api.Project;
import org.gradle.api.provider.Provider;

public class DatabaseServicePlugin implements Plugin<Project>
{
    public void apply(Project project)
    {
        // Register the service
        project.getGradle().getSharedServices().registerIfAbsent("database", DatabaseService.class, spec -> {
            // Provide some parameters
            spec.getParameters().getCreateTestDatabase().set(true);
            spec.getParameters().getJdbcUrl().set("jdbc:oracle:thin:@localhost:1521/test");
        });

        project.getTasks().register("databaseStart", DatabaseStartTask.class, task ->
        {
            task.setGroup("Database");
        });
    }
}
