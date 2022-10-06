package db.data;

import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import com.fasterxml.jackson.core.JsonParser.Feature;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import cwms.CwmsMigrationError;
import cwms.CwmsMigrationSqlError;
import cwms.units.ConversionGraph;
import cwms.units.Unit;
import net.hobbyscience.database.Conversion;
import net.hobbyscience.database.ConversionMethod;
import net.hobbyscience.database.methods.*;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.function.Function;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.zip.CRC32;

public class R__0002_units_and_parameters extends BaseJavaMigration  implements CwmsMigration {
    private static final Logger log = Logger.getLogger(R__0002_units_and_parameters.class.getName());

    private ArrayList<String> abstractParameters = new ArrayList<>();
    private Map<String,Unit> unitDefinitions = null;
    private HashSet<Conversion> conversions = new HashSet<>();
    private Map<String,String> constants = null;
    private String sqlConversions = null;
    private String sqlAbstract = null;
    private String sqlUnits = null;

    private final Pattern yEqualsMx = Pattern.compile("^i -?[0-9]+(\\.[0-9]+)? \\*$");
    private final Pattern yEqualsMxPlusB = Pattern.compile("^i -?[0-9]+(\\.[0-9]+)? \\* ?[0-9]+(\\.[0-9]+)? [-+]$");
    private final Pattern yEqualsXPlusB = Pattern.compile("^i -?[0-9]+(\\.[0-9]+)? [-+]$");

    private CRC32 crc = new CRC32();

    public R__0002_units_and_parameters() throws Exception {
        log.info("Loading Unit definitions and Abstract Parameters");
        this.loadData();
        System.out.println(crc.getValue());
    }

    @Override
    public void migrate(Context context) throws Exception {

        log.log( Level.FINEST, "Parameters: \n{0}",
                 abstractParameters
                    .stream()
                    .collect( Collectors.joining("\n")));
        log.log( Level.FINEST, "units: \n{0}",
                 unitDefinitions.values()
                 .stream()
                 .map( unit -> unit.toString() )
                 .collect(Collectors.joining("\n")));
        log.log( Level.INFO, "Listed Conversions\n{0}",
                 conversions
                 .stream()
                 .map( conv -> conv.toString() )
                 .collect(Collectors.joining("\n")));

        ConversionGraph convGraph = new ConversionGraph(conversions);

        var expandedConversions = convGraph.generateConversions();
        log.info(() -> String.format("We have %s total conversions",expandedConversions.size()));
        log.log(Level.FINEST, "Expanded Conversions:\n{0}",
                expandedConversions
                    .stream()
                    .map(conv -> conv.toString())
                    .collect(Collectors.joining("\n")));

        Connection conn = context.getConnection();
        /* now we would insert or update the conversions */
        try (var mergeAbstractParams = conn.prepareStatement(sqlAbstract);
             var mergeConversions = conn.prepareStatement(sqlConversions);
             var mergeUnits = conn.prepareStatement(sqlUnits);
             var deleteAbstractParams = conn.prepareStatement("delete from cwms_abstract_parameter where abstract_parameter_id = ?");
             var existingParametersRS = conn.createStatement().executeQuery("select abstract_param_id from cwms_abstract_parameter");
              ) {
            log.info("Querying for existing abstract parameters");
            var existingParameters = new ArrayList<String>();
            while( existingParametersRS.next() ) {
                existingParameters.add(existingParametersRS.getString(1));
            }


            log.info("inserting new abstract parameters");
            for(String param: abstractParameters) {
                mergeAbstractParams.setString(1,param);
                mergeAbstractParams.addBatch();
            };
            mergeAbstractParams.executeBatch();

            var toRemove = existingParameters.stream()
                                             .filter((s)-> !abstractParameters.contains(s))
                                             .collect(Collectors.toList());
            log.info("Flushing old Abstract Parameters");
            for( String param: toRemove) {
                log.info("\t" + param);
                deleteAbstractParams.setString(1,param);
                deleteAbstractParams.addBatch();
            }
            deleteAbstractParams.executeBatch();


            log.info("Merging Unit definitions");
            for(Unit unit: unitDefinitions.values()) {
                    mergeUnits.clearParameters();
                    log.fine("Storing " + unit.toString());
                    mergeUnits.setString(1,unit.getAbbreviation());
                    mergeUnits.setString(2,unit.getAbstractParameter());
                    if( "null".equalsIgnoreCase(unit.getSystem())) {
                        mergeUnits.setString(3,null);
                    } else {
                        mergeUnits.setString(3,unit.getSystem());
                    }
                    mergeUnits.setString(4,unit.getName());
                    mergeUnits.setString(5,unit.getDescription());
                    mergeUnits.addBatch();
            }
            mergeUnits.executeBatch();


            log.info("Merging conversions");
            for(Conversion conv: expandedConversions) {
                mergeConversions.clearParameters();
                mergeConversions.setString(1,conv.getFrom().getAbbreviation());
                mergeConversions.setString(2,conv.getTo().getAbbreviation());
                mergeConversions.setString(3,conv.getFrom().getAbstractParameter());
                String postfix = conv.getMethod().getPostfix();
                if( yEqualsMx.matcher(postfix).matches()) {
                    String value = postfix.split("\\s+")[1];
                    mergeConversions.setDouble(4,Double.parseDouble(value));
                    mergeConversions.setDouble(5,0.0);
                    mergeConversions.setString(6,null);
                } else if (yEqualsXPlusB.matcher(postfix).matches()) {
                    String value = postfix.split("\\s+")[1];
                    mergeConversions.setDouble(4,0.0);
                    mergeConversions.setDouble(5,Double.parseDouble(value));
                    mergeConversions.setString(6,null);

                } else if (yEqualsMxPlusB.matcher(postfix).matches()) {
                    mergeConversions.setString(6,null);
                    // i m * b +
                    String values[] = postfix.split("\\s+");
                    mergeConversions.setDouble(4,Double.parseDouble(values[1]));
                    mergeConversions.setDouble(5,Double.parseDouble(values[3]));
                    mergeConversions.setString(6,null);
                } else {
                    mergeConversions.setNull(4, Types.DOUBLE);
                    mergeConversions.setNull(5, Types.DOUBLE);
                    mergeConversions.setString(6,postfix.replace("i","ARG0"));
                }
                mergeConversions.addBatch();
            }
            mergeConversions.executeBatch();

        } catch (SQLException ex) {
            throw new CwmsMigrationSqlError("failed to merge unit data", ex);
        }

    }

    private void loadData() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        mapper.enable(Feature.ALLOW_COMMENTS);

        abstractParameters = mapper.readValue(
            getData("db/custom/units_and_parameters/abstract_parameters.json"),
            new TypeReference<ArrayList<String>>(){});
        abstractParameters.forEach(ap -> {
            crc.update(ap.getBytes());
        });

        unitDefinitions = mapper.readValue(
            getData("db/custom/units_and_parameters/unit_definitions.json"),
            new TypeReference<ArrayList<Unit>>(){})
            .stream()
            .collect(
                Collectors.toMap(
                    Unit::getAbbreviation,
                    Function.identity(),
                    (o1,o2) -> o1,
                    HashMap::new
            ));
        unitDefinitions.forEach( (k,v) -> {
            crc.update(v.toString().getBytes());
        });


        constants = mapper.readValue(
            getData("db/custom/units_and_parameters/conversion_constants.json"),
            new TypeReference<HashMap<String,String>>(){});
        constants.forEach( (k,v) -> {
            String tmp = String.format("%s:%s",k,v);
            crc.update(tmp.getBytes());
        });

        JsonNode tmpConversions = mapper.readTree(
            getData("db/custom/units_and_parameters/conversions.json"));

        tmpConversions.forEach( (conversion) -> {
            //Conversion c = new Conversion(from, to, method)
            Unit from = unitDefinitions.get(conversion.get(0).asText());
            Unit to = unitDefinitions.get(conversion.get(1).asText());
            if( from !=null && to != null ) {
                String parts[] = conversion.get(2).asText().split(":");
                String type = parts[0];
                String function = parts[1].trim();
                ConversionMethod method = null;
                if( "linear".equalsIgnoreCase(type)){
                   method = new Linear(substituteVariables(function));
                } else if( "function".equalsIgnoreCase(type)){
                   method = new net.hobbyscience.database.methods.Function(substituteVariables(function));
                } else {
                    throw new CwmsMigrationError("Invalid conversion method: " + type);
                }

                Conversion c = new Conversion(from,to, method);
                crc.update(c.toString().getBytes());
                conversions.add(c);
            }

        });

        sqlAbstract = new String(getData("db/custom/units_and_parameters/abstract_parameters.sql").readAllBytes());
        sqlConversions = new String(getData("db/custom/units_and_parameters/conversions.sql").readAllBytes());
        sqlUnits = new String(getData("db/custom/units_and_parameters/units.sql").readAllBytes());

    }

    @Override
    public Integer getChecksum() {
        return (int)crc.getValue(); //Integer.valueOf(18);
    }


    private String substituteVariables(String conversion) {
        String tmp = conversion;
        for( String constant: constants.keySet() ){
            tmp = tmp.replace(constant,constants.get(constant));
        }
        return tmp;
    }

    public HashSet<Conversion> getConversions() {
        return conversions;
    }
}
