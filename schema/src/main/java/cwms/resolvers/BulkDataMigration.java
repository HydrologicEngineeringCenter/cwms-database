package cwms.resolvers;

import org.flywaydb.core.extensibility.MigrationType;

public class BulkDataMigration implements MigrationType {

    public static final BulkDataMigration BULK_DATA = new BulkDataMigration();

    @Override
    public boolean isUndo() {
        return false;
    }

    @Override
    public String name() {
        return "CwmsBulkData";
    }

    @Override
    public boolean isSynthetic() {
        return true;
    }

    @Override
    public boolean isBaseline() {
        return false;
    }
    
}
