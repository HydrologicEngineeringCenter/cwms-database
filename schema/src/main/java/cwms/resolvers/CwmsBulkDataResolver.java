package cwms.resolvers;

import java.io.File;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import java.util.logging.Logger;

import org.flywaydb.core.api.CoreMigrationType;
import org.flywaydb.core.api.resolver.MigrationResolver;
import org.flywaydb.core.api.resolver.ResolvedMigration;
import org.flywaydb.core.api.resource.LoadableResource;
import org.flywaydb.core.internal.resolver.ChecksumCalculator;

public class CwmsBulkDataResolver implements MigrationResolver {
    public static final Logger log = Logger.getLogger(CwmsBulkDataResolver.class.getName());

    public CwmsBulkDataResolver() {
    }

    @Override
    public Collection<ResolvedMigration> resolveMigrations(MigrationResolver.Context context) {
        log.info("*************hello, scanning for CWMS Custom Migrations.*****");

        List<ResolvedMigration> migrations = new ArrayList<>();
        String suffix = "csv";


        addMigrations(migrations,context.configuration.getRepeatableSqlMigrationPrefix(),suffix,context);


        return migrations;
    }

    private void addMigrations(List<ResolvedMigration> migrations, String prefix, String suffix, MigrationResolver.Context context) {
        final String fullPrefix = prefix+"__";
        log.info("Finding CWMS Custom migrations with prefix " + prefix);
        for (LoadableResource lr:  context.resourceProvider.getResources(prefix, new String[]{suffix})) {        
            String filename = lr.getFilename();
            log.info(filename + ":" + lr.getAbsolutePathOnDisk());
            if (!filename.startsWith(fullPrefix)) {
                log.info("\tSkipped");
                continue;
            }
            Integer checkSum = ChecksumCalculator.calculate(lr);
            Integer equiv = ChecksumCalculator.calculate(lr);
            DataResource dr = new DataResource(new File(lr.getAbsolutePathOnDisk()));
            migrations.add(new CwmsResolvedMigration(null,
                                                     lr.getFilename(),
                                                     lr.getRelativePath(),
                                                     checkSum, //checksum
                                                     equiv, //equivalentChecksum,
                                                     CoreMigrationType.CUSTOM,
                                                     lr.getAbsolutePathOnDisk(),
                                                     new CwmsDataLoadExecutor(dr)));
        }

    }
}
