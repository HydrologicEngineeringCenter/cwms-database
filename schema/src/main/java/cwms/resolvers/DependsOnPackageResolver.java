package cwms.resolvers;

import java.io.File;
import java.io.IOException;
import java.io.Reader;
import java.net.URISyntaxException;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.function.Consumer;
import java.util.logging.Logger;
import java.util.regex.Pattern;

import org.flywaydb.core.api.Location;
import org.flywaydb.core.api.MigrationType;
import org.flywaydb.core.api.ResourceProvider;
import org.flywaydb.core.api.configuration.Configuration;
import org.flywaydb.core.api.executor.MigrationExecutor;
import org.flywaydb.core.api.resolver.Context;
import org.flywaydb.core.api.resolver.MigrationResolver;
import org.flywaydb.core.api.resolver.ResolvedMigration;
import org.flywaydb.core.api.resource.LoadableResource;
import org.flywaydb.core.internal.parser.ParsingContext;
import org.flywaydb.core.internal.resolver.ResolvedMigrationImpl;
import org.flywaydb.core.internal.resource.ResourceName;
import org.flywaydb.core.internal.resource.ResourceNameParser;
import org.flywaydb.core.internal.sqlscript.SqlScriptExecutorFactory;
import org.flywaydb.core.internal.sqlscript.SqlScriptFactory;

public class DependsOnPackageResolver implements MigrationResolver {
    public static final Logger log = Logger.getLogger(DependsOnPackageResolver.class.getName());

    private ResourceProvider resourceProvider;

    private Configuration configuration;


    public DependsOnPackageResolver(){
    }

    @Override
    public Collection<ResolvedMigration> resolveMigrations(Context context) {
        log.info("*************helllo, scaning for CWMS Custom Migrations.*****");
        this.configuration = context.getConfiguration();


        List<ResolvedMigration> migrations = new ArrayList<>();
        String suffix = "sqld";


        addMigrations(migrations,context.getConfiguration().getSqlMigrationPrefix(),suffix,context);


        return migrations;
    }

    private void addMigrations(List<ResolvedMigration> migrations, String prefix, String suffix, Context context){
        ResourceNameParser nameParser = new ResourceNameParser(context.getConfiguration());
        System.out.println("finding CWMS Custom migrations");


        for(LoadableResource resource: getResources(prefix, suffix) ){
            String filename = resource.getFilename();
            System.out.println("*********" + filename +"**************");
            ResourceName name = nameParser.parse(filename);
            if(!name.isValid() || !prefix.equals(name.getPrefix())) {
                continue;
            }
            System.out.println(name);
            /*
            migrations.add(new ResolvedMigrationImpl(name.getVersion(),
                                                     name.getDescription(),
                                                     resource.getRelativePath(),
                                                     0, //checksum
                                                     0, //equivalentChecksum,
                                                     MigrationType.CUSTOM,
                                                     resource.getAbsolutePath(),
                                                     new MigrationExecutor() {

                                                        @Override
                                                        public void execute(
                                                                org.flywaydb.core.api.executor.Context context)
                                                                throws SQLException {
                                                            // TODO Auto-generated method stub

                                                        }

                                                        @Override
                                                        public boolean canExecuteInTransaction() {
                                                            // TODO Auto-generated method stub
                                                            return true;
                                                        }

                                                        @Override
                                                        public boolean shouldExecute() {
                                                            // TODO Auto-generated method stub
                                                            return true;
                                                        }

                                                     }));*/
        }

    }


    private List<LoadableResource> getResources(final String prefix, final String suffix){
        List<LoadableResource> resources = new ArrayList<>();



        for( Location location: configuration.getLocations() ) {
            System.out.println("Searching in " + location.getPath()+ "|||" + location.getDescriptor());
            try {
                URL dir = getClass().getClassLoader().getResource(location.getPath());
                Path path = Path.of(dir.toURI());
                walk(path, (f) -> {
                    String name = f.getName();
                    if( name.startsWith(prefix) && name.endsWith(suffix) ){
                        System.out.println(f.getAbsolutePath() + " -> " + f.getName());

                        resources.add( new LoadableResource() {

                            @Override
                            public String getAbsolutePath() {
                                return f.getAbsolutePath();
                            }

                            @Override
                            public String getAbsolutePathOnDisk() {
                                return f.getAbsolutePath();
                            }

                            @Override
                            public String getFilename() {

                                return f.getName();
                            }

                            @Override
                            public String getRelativePath() {
                                return f.getPath();
                            }

                            @Override
                            public Reader read() {
                                // TODO Auto-generated method stub
                                return null;
                            }

                        });
                    }


                });
            } catch (URISyntaxException e) {

                e.printStackTrace();
            }

        }

        return resources;
    }

    private void walk( Path path, Consumer<File> function ) {
        try {
            Files.newDirectoryStream(path).forEach((p) -> {
                if(p.toFile().isDirectory()) {
                    walk(p,function);
                } else {
                    function.accept(p.toFile());
                }


            });
        } catch (IOException e) {

            e.printStackTrace();
        }
    }

}
