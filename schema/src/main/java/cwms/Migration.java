package cwms;

import java.io.FileInputStream;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;
import org.flywaydb.core.Flyway;
import org.kohsuke.args4j.Argument;
import org.kohsuke.args4j.CmdLineException;
import org.kohsuke.args4j.CmdLineParser;
import org.kohsuke.args4j.Option;

public class Migration {

    Properties props = new Properties();
    @Argument
    private List<String> argFiles = new ArrayList<>();

    @Option(name = "-c", usage="which flyway command to run")
    private String command = null;

    @Option(name = "-D", metaVar = "<property>=<value>", usage = "use value for given property")
	private void setProperty(final String property) throws CmdLineException
	{
        var index = property.indexOf("=");
		String[] arr = List.of(property.substring(0,index),property.substring(index+1)).toArray(new String[0]);
		setProperty(arr);
	}

	public void setProperty(String[] arr) throws CmdLineException
	{
		if (arr.length != 2) {
			throw new CmdLineException("Properties must be specified in the form:" +
				"<property>=<value>");
		}
		props.setProperty(arr[0], arr[1]);
	}


    public static void main(String[] args) throws Exception {
        if(!new Migration().run(args)) {
            System.exit(1);
        }
    }

    public boolean run(String[] args) throws Exception {
        CmdLineParser parser = new CmdLineParser(this);
        // if you have a wider console, you could increase the value;
        // here 80 is also the default
        parser.setUsageWidth(80);

        try {
            parser.parseArgument(args);
            // after parsing arguments, you should check
            // if enough arguments are given.
        } catch(CmdLineException ex) {
            System.err.println(ex.getMessage());
            System.err.println("java SampleMain [options...] arguments...");

            parser.printUsage(System.err);
            System.err.println();

            return false;
        }

        if (!argFiles.isEmpty()) {
            for (var argFile: argFiles) {
                try (InputStream is = new FileInputStream(argFile)) {
                    props.load(is);
                }
            }
        }

        System.getProperties().forEach((k,value) -> {
            if (k instanceof String key) {
                if (key.startsWith("flyway.")) {
                    props.put(key,value);
                } else if (key.startsWith("database.")) {
                    props.put(key.replace("database.","flyway."), value);
                }
            }
        });
        if (command.equalsIgnoreCase("migrate")) {
            System.out.println("Running Schema Migration");
            migrate(props);
        } else if (command.equalsIgnoreCase("clean")) {
            System.out.println("Cleaning schema.");
            clean(props);
        } else {
            System.err.println("Command '" + command + "' is not available.");
            return false;
        }

        return true;
    }


    private void migrate(Properties props) {
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

    private void clean(Properties props) {
        Flyway schema = Flyway.configure()
                        .configuration(props)
                        .schemas("CWMS_20", "CWMS_DBA")
                        .baselineOnMigrate(true)
                        .baselineVersion("0")
                        .locations("db/schema")
                        .tablespace("CWMS_20DATA")
                        .mixed(true)
                        .load();
        schema.clean();
    }
}
