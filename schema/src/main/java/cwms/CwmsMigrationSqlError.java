package cwms;

import java.sql.SQLException;

public class CwmsMigrationSqlError extends SQLException {

    public CwmsMigrationSqlError(String msg) {
        super(msg);
    }

    public CwmsMigrationSqlError(String msg, SQLException ex) {
        super(msg,ex);
    }

    @Override
    public String getMessage() {
        StringBuilder builder = new StringBuilder();
        builder.append(super.getMessage());
        SQLException ex = (SQLException)this.getCause();
        while( (ex!=null)){
            builder.append(ex.getMessage());
            builder.append(System.lineSeparator());
            builder.append("Because: ");
            ex = ex.getNextException();
        }

        return builder.toString();
    }

    @Override
    public String getLocalizedMessage() {
        StringBuilder builder = new StringBuilder();
        builder.append(super.getMessage());
        SQLException ex = (SQLException)this.getCause();
        while( (ex!=null)){
            builder.append(ex.getLocalizedMessage());
            ex = ex.getNextException();
        }

        return builder.toString();
    }
}
