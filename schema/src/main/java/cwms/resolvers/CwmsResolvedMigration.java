package cwms.resolvers;

import org.flywaydb.core.api.MigrationVersion;
import org.flywaydb.core.api.executor.MigrationExecutor;
import org.flywaydb.core.api.resolver.ResolvedMigration;
import org.flywaydb.core.extensibility.MigrationType;

public class CwmsResolvedMigration implements ResolvedMigration{

    Integer checksum;
    Integer checkSumAfterSubsitution;
    String description;
    String script;
    String location;
    MigrationVersion version;
    MigrationType type;
    MigrationExecutor executor;

    public CwmsResolvedMigration(MigrationVersion version, String description, String script, Integer checksum,
                                 Integer equivalentChecksum, MigrationType type, String physicalLocation,
                                 MigrationExecutor executor) {
        this.version = version;
        this.description = description;
        this.script = script;        
        this.checksum = checksum;
        this.checkSumAfterSubsitution = equivalentChecksum;
        this.type = type;
        this.location = physicalLocation;
        this.executor = executor;
    }

    @Override
    public boolean checksumMatches(Integer checksum) {
        return checksum.equals(checkSumAfterSubsitution);
    }

    @Override
    public boolean checksumMatchesWithoutBeingIdentical(Integer checksum) {
        return this.checksum.equals(checksum);
    }

    @Override
    public MigrationVersion getVersion() {
        return version;
    }

    @Override
    public String getDescription() {
        return description;
    }

    @Override
    public String getScript() {
        return script;
    }

    @Override
    public Integer getChecksum() {
        return checksum;
    }

    @Override
    public MigrationType getType() {
        return type;
    }

    @Override
    public String getPhysicalLocation() {
        return location;
    }

    @Override
    public MigrationExecutor getExecutor() {
        return executor;
    }
    
}
