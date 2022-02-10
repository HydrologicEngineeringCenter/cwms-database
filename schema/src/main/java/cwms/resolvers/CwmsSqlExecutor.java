package cwms.resolvers;

import java.sql.SQLException;

import org.flywaydb.core.api.executor.Context;
import org.flywaydb.core.api.executor.MigrationExecutor;

public class CwmsSqlExecutor implements MigrationExecutor {



    @Override
    public void execute(Context context) throws SQLException {


    }

    @Override
    public boolean canExecuteInTransaction() {

        return true;
    }

    @Override
    public boolean shouldExecute() {

        return true;
    }

}
