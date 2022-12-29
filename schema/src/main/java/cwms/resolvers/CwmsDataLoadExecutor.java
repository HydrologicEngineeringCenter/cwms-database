package cwms.resolvers;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.net.URL;
import java.sql.Clob;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.SQLType;
import java.sql.Types;
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
    private ArrayList<String> disabledIndexes = new ArrayList<>();
    private int batchSize = 1000;

    private class Group {
        public Group( String item, String pattern, String type, String endSequence){
            this.item = item;
            this.pattern = Pattern.compile(pattern);
            this.type = type;
            this.endSequence = endSequence;
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
                    logger.fine("Loading Query");
                    query = loadQuery(reader);
                    logger.finest(() -> String.format("Loading Data with: %s",query));
                } else if( line.startsWith("!description") ) {
                    logger.fine("Loading descriptions.");
                    loadDescription(reader);
                } else if( line.startsWith("!data")) {
                    logger.fine("Processing Data Elemements");
                    int entries = processData(reader,context.getConnection());
                    logger.finest("Total Entries loaded for (" + resource.getFilename() + ") is " + entries);
                } else if( line.startsWith("!disableindex")) {
                    disableIndex(line.split("\\s+")[1],context.getConnection());
                } else if( line.startsWith("!config")) {
                    processConfig(reader);
                } else if( line.startsWith("!")){
                    // do nothing, comment
                }
            }
            PreparedStatement enableIndex = context.getConnection().prepareStatement("alter index ? rebuild online");
            for(String index: disabledIndexes){
                enableIndex.setString(1,index);
                enableIndex.execute();
            }
        } catch (SQLException ex) {
            SQLException cur = ex;
            logger.info(ex.getLocalizedMessage());
            while ((cur = cur.getNextException()) != null) {
                logger.info(cur.getLocalizedMessage());
            }
            throw ex;
        } catch (IOException e ) {
            throw new FlywayException("Data load processing failure",e);
        }




    }

    private void processConfig(BufferedReader reader) throws IOException {
        String line;

        while( !(line = reader.readLine()).startsWith("!endconfig")) {
            String parts[] = line.split("\\s+");
            logger.finest( "Loading " + line + " Split to " + parts.length + " elements.");
            if ("batchsize".equalsIgnoreCase(parts[0])) {
                this.batchSize = Integer.parseInt(parts[1]);
            } else {
                logger.warning("Unknown config paramter " + parts[0] + ", ignored.");
            }
        }
    }

    private void disableIndex(String indexName, Connection connection) throws SQLException {
        logger.fine("Disabling index: " + indexName);
        connection.createStatement().execute("alter session set skip_unusable_indexes = true");
        String query = "alter index " +indexName + " unusable";
        logger.fine("Running " + query);
        connection.createStatement().execute(query);
        logger.fine("Disabled");
    }

    private int processData(BufferedReader reader,Connection connection) throws IOException, SQLException {

        PreparedStatement stmt = connection.prepareStatement(query);
        boolean defaultAutoCommit = connection.getAutoCommit();
        connection.setAutoCommit(false);
        String line;
        int totalEntries = 0;
        while ((line = reader.readLine()) != null) {
            stmt.clearParameters();
            logger.info(line);
            String remainder = line;
            int idx = 0;
            if( line.trim().isEmpty()){
                continue;
            }
            for( Group grp: groups ){
                logger.fine("searching for " + grp.item);
                Matcher matches = grp.pattern.matcher(remainder.trim());
                if (matches.matches() ){
                    idx++;
                    logger.fine("Found matches in " + remainder);

                    /**
                     * Most of this silly logic is caused by the weird grouping required
                     * to handle ,/ in the middle of a line. If one can fix that regex
                     * we can simplify
                     */
                    String current = matches.group("current") != null ? matches.group("current") : matches.group("all");
                    logger.fine(" using '" + current +"'");
                    if (matches.groupCount() > 1 && matches.group("remains") != null) {
                        remainder = matches.group("remains");
                    } else {
                        remainder = "";
                    }

                    //logger.info("Found " + current + " For " + grp.item + "(" + idx +")");
                    StringBuilder data = new StringBuilder();
                    data.append(current);
                    if (grp.continues && remainder.isEmpty() && !line.endsWith(grp.endSequence)) {
                        int seqIdx = -1;
                        do {
                            line = reader.readLine().trim();
                            seqIdx = line.indexOf(grp.endSequence);
                            logger.fine("Found extra line " + line);
                            String tmp = line;
                            if( seqIdx > 0 ) {
                                tmp = tmp.substring(0,seqIdx);
                            } 
                            data.append(tmp.replace("#","").replace(grp.endSequence,""));
                        } while( seqIdx < 0);

                        if( !line.endsWith(grp.endSequence )) {
                            seqIdx = line.indexOf(grp.endSequence);
                            remainder = line.substring(seqIdx+grp.endSequence.length());
                            logger.finest("remaining" + remainder);
                        }
                    }
                    logger.finest( "Setting " + idx);                    
                    setJdbcParameter(connection,stmt,grp,idx,data.toString());
                }
            }
            logger.fine( idx + " elements set");            
            stmt.addBatch();
            totalEntries++;
            if( totalEntries % batchSize == 0 ){
                stmt.executeBatch();
                logger.info( "Have now saved: " + totalEntries + " records total for this set.");
            }
        }
        stmt.executeBatch();
        connection.commit();
        connection.setAutoCommit(defaultAutoCommit);
        return totalEntries;
    }

    private void setJdbcParameter(Connection conn, PreparedStatement stmt, Group grp, int idx, String string) throws SQLException {
        logger.fine(() -> new StringBuilder()
            .append("JDBC Parms -> ")
            .append("Index: ").append(idx)
            .append(", Group: ").append(grp.item)
            .append(", Type: ").append(grp.type)
            .append(", Value: ").append(string)
            .toString()
        );
        if( "string".equalsIgnoreCase(grp.type)){
            if( "null".equalsIgnoreCase(string)){
                stmt.setNull(idx,Types.VARCHAR);
            } else {
                stmt.setString(idx,string.replace("\"",""));
            }            
        } else if( "int".equalsIgnoreCase(grp.type)) {
            if( !string.isEmpty() && !string.equalsIgnoreCase("NULL")) {
                stmt.setInt(idx, Integer.parseInt(string));
            } else {
                stmt.setNull(idx,Types.NUMERIC);
            }
        } else if( "double".equalsIgnoreCase(grp.type) ) {
            if( !string.isEmpty() && !string.equalsIgnoreCase("NULL") ){
                stmt.setDouble(idx, Double.parseDouble(string));
            } else {
                stmt.setNull(idx, Types.DOUBLE);
            }

        } else if( "clob".equalsIgnoreCase(grp.type)) {
            Clob c = conn.createClob();
            logger.finest(() -> "Num elements: " + string.split(",").length );
            if( string.endsWith(",")) {                                
                c.setString(1,string.substring(0,string.length()-1));
            } else {
                c.setString(1,string);
            }
            stmt.setClob(idx,c);
        } else {
            throw new FlywayException("unknown type '" + grp.type + "''. Maybe typo, may need new code implemented");
        }
    }

    private void loadDescription(BufferedReader reader) throws IOException {
        String line;

        while( !(line = reader.readLine()).startsWith("!enddescription")) {
            String parts[] = line.split("\\s+");
            logger.finest( "Loading " + line + " Split to " + parts.length + " elements.");
            groups.add( new Group(parts[0],
                                  parts[1],
                                  parts[2],
                                  parts.length == 4 ? parts[3] : ""
            ));
        }
        logger.fine("Descriptions loaded.");
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
