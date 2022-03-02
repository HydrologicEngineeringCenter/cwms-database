package cwms.resolvers;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.net.URL;
import java.sql.Clob;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.logging.Logger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.flywaydb.core.api.FlywayException;
import org.flywaydb.core.api.executor.Context;
import org.flywaydb.core.api.executor.MigrationExecutor;
import org.flywaydb.core.api.resource.LoadableResource;

public class CwmsDataLoadExecutor implements MigrationExecutor {
    private static final Logger logger = Logger.getLogger(CwmsDataLoadExecutor.class.getName());
    private DataResource resource;
    private String query;

    private class Group {
        public Group( String item, String pattern, String type, String endSequence){
            this.continues=continues;
            this.item = item;
            this.pattern = Pattern.compile(pattern);
            this.type = type;

            this.continues = !endSequence.isEmpty();

        }
        public String item;
        public String type;
        public Pattern pattern;
        public boolean continues;
        public String endSequence;
    }

    private ArrayList<Group> groups = new ArrayList<Group>();

    public CwmsDataLoadExecutor(DataResource resource) {
        this.resource = resource;
    }

    @Override
    public void execute(Context context) throws SQLException {
        logger.info("Loading " + resource.getFilename());
        try {

            BufferedReader reader = new BufferedReader(resource.read());
            String line;
            while( (line = reader.readLine()) != null ){
                if (line.startsWith("#")){
                    continue;
                } else if( line.startsWith("!query")) {
                    logger.info("Loading Query");
                    query = loadQuery(reader);
                    logger.info(() -> String.format("Loading Data with: %s",query));
                } else if( line.startsWith("!description") ) {
                    logger.info("Loading descriptions.");
                    loadDescription(reader);
                } else if( line.startsWith("!data")){
                    logger.info("Processing Data Elemements");
                    processData(reader,context.getConnection());
                }


            }
        } catch( IOException e ){
            throw new FlywayException("Data load processing failure",e);
        }




    }

    private void processData(BufferedReader reader,Connection connection) throws IOException, SQLException {

        PreparedStatement stmt = connection.prepareStatement(query);


        String line;
        while( (line = reader.readLine()) != null) {
            stmt.clearParameters();
            //logger.info(line);
            String remainder = line;
            int idx = 1;
            for( Group grp: groups ){
                logger.info("searching for " + grp.item);
                Matcher matches = grp.pattern.matcher(remainder);
                if( matches.matches() ){
                    logger.info("Found matches for " + remainder);
                    String current = matches.group(1);
                    remainder = matches.group(2);
                    logger.info("Found " + current + " For " + grp.item);
                    StringBuilder data = new StringBuilder();
                    data.append(current);
                    if( grp.continues && !current.endsWith(grp.endSequence)) {
                        do {
                            line = reader.readLine().trim();
                            data.append(line.substring(1));
                        } while( !line.endsWith(grp.endSequence));
                    }
                    setJdbcParameter(connection,stmt,grp,idx,data.toString());
                    idx++;
                }
            }
            logger.info( idx + " elements set");
            logger.info(stmt.toString());
            stmt.addBatch();
        }
        stmt.execute();
    }

    private void setJdbcParameter(Connection conn, PreparedStatement stmt, Group grp, int idx, String string) throws SQLException {
        if( "string".equalsIgnoreCase(grp.type)){
            stmt.setString(idx,string);
        } else if( "number".equalsIgnoreCase(grp.type)) {
            stmt.setDouble(idx, Double.parseDouble(string));
        } else if( "clob".equalsIgnoreCase(grp.type)) {
            Clob c = conn.createClob();
            c.setString(0,string);
            stmt.setClob(idx,c);
        } else {
            throw new FlywayException("unknown type " + grp.type + ". Maybe typo, may need new code implemented");
        }
    }

    private void loadDescription(BufferedReader reader) throws IOException {
        String line;

        while( !(line = reader.readLine()).startsWith("!enddescription")) {
            String parts[] = line.split("\\s+");
            logger.info( "Loading " + line + " Split to " + parts.length + " elements.");
            groups.add( new Group(parts[0],
                                  parts[1],
                                  parts[2],
                                  parts.length == 4 ? parts[3] : ""
            ));
        }
        logger.info("Descriptions loaded.");
    }

    private String loadQuery(BufferedReader reader) throws IOException{
        String line;
        StringBuilder query = new StringBuilder();
        while( !(line = reader.readLine()).startsWith("!endquery")) {
            query.append(line).append(System.lineSeparator());
        }
        return query.toString();
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
