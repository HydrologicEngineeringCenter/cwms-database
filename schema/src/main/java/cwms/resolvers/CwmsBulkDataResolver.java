package cwms.resolvers;

import java.io.File;
import java.io.FileReader;
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
import java.util.Random;
import java.util.function.Consumer;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.regex.Pattern;

import org.flywaydb.core.api.FlywayException;
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
import org.flywaydb.core.internal.resolver.ChecksumCalculator;
import org.flywaydb.core.internal.resolver.ResolvedMigrationImpl;
import org.flywaydb.core.internal.resource.ResourceName;
import org.flywaydb.core.internal.resource.ResourceNameParser;
import org.flywaydb.core.internal.sqlscript.SqlScriptExecutorFactory;
import org.flywaydb.core.internal.sqlscript.SqlScriptFactory;

public class CwmsBulkDataResolver implements MigrationResolver {
    public static final Logger log = Logger.getLogger(CwmsBulkDataResolver.class.getName());

    private ResourceProvider resourceProvider;

    private Configuration configuration;


    public CwmsBulkDataResolver(){
    }

    @Override
    public Collection<ResolvedMigration> resolveMigrations(Context context) {
        log.info("*************hello, scanning for CWMS Custom Migrations.*****");
        this.configuration = context.getConfiguration();


        List<ResolvedMigration> migrations = new ArrayList<>();
        String suffix = "csv";


        addMigrations(migrations,context.getConfiguration().getRepeatableSqlMigrationPrefix(),suffix,context);


        return migrations;
    }

    private void addMigrations(List<ResolvedMigration> migrations, String prefix, String suffix, Context context){
        ResourceNameParser nameParser = new ResourceNameParser(context.getConfiguration());
        log.info("finding CWMS Custom migrations");


        for(DataResource resource: getResources(prefix, suffix) ){
            String filename = resource.getFilename();
            log.fine(()->"*********" + filename +"**************");
            ResourceName name = nameParser.parse(filename);
            if(!name.isValid() || !prefix.equals(name.getPrefix())) {
                continue;
            }
            Integer checkSum = ChecksumCalculator.calculate(resource);
            Integer equiv = ChecksumCalculator.calculate(resource);
            migrations.add(new ResolvedMigrationImpl(name.getVersion(),
                                                     name.getDescription(),
                                                     resource.getRelativePath(),
                                                     checkSum, //checksum
                                                     equiv, //equivalentChecksum,
                                                     MigrationType.CUSTOM,
                                                     resource.getAbsolutePath(),
                                                     new CwmsDataLoadExecutor(resource)));
        }

    }


    private List<DataResource> getResources(final String prefix, final String suffix){
        List<DataResource> resources = new ArrayList<>();



        for( Location location: configuration.getLocations() ) {
            log.info("Searching in " + location.getPath()+ "|||" + location.getDescriptor());
            try {
                URL dir = getClass().getClassLoader().getResource(location.getPath()+"/csv");
                Path path = Path.of(dir.toURI());
                walk(path, (f) -> {
                    String name = f.getName();
                    if( name.startsWith(prefix) && name.endsWith(suffix) ){
                        log.fine( () -> f.getAbsolutePath() + " -> " + f.getName());

                        resources.add( new DataResource(f));
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
            log.log(Level.SEVERE,"Error walking path",e);        
        }
    }

}
