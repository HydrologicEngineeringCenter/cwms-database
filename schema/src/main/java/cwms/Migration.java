package cwms;

import java.io.FileInputStream;
import java.io.InputStream;
import java.util.Properties;
import org.flywaydb.core.Flyway;


public class Migration {
    public static void main(String[] args) throws Exception {
        Properties props = new Properties();
        try (InputStream is = new FileInputStream(args[0]))
        {
            props.load(is);
            Flyway schema = Flyway.configure()
                            .configuration(props)
                            .schemas("CWMS_20", "CWMS_DBA")
                            .baselineOnMigrate(true)
                            .baselineVersion("0")
                            .locations("db/schema")
                            .tablespace("CWMS_20DATA")
                            .mixed(true)
                            .load();
            schema.migrate();
            props.setProperty("flyway.user", props.getProperty("flyway.user")+"[CWMS_20]");
            Flyway data = Flyway.configure()
                                .configuration(props)
                                .locations("db/data")
                                .mixed(true)
                                .resolvers(new cwms.resolvers.CwmsBulkDataResolver())
                                .table("flyway_data_history")
                                .baselineOnMigrate(true)
                                .schemas("CWMS_20")
                                .load();
            data.migrate();
        }
    }

}
