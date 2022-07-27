package db.data;

import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import com.fasterxml.jackson.annotation.JsonFormat.Features;
import com.fasterxml.jackson.core.JsonParser.Feature;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import cwms.units.ConversionGraph;
import cwms.units.Unit;
import net.hobbyscience.database.Conversion;
import net.hobbyscience.database.methods.Linear;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.function.Function;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

public class R__units_and_parameters extends BaseJavaMigration  implements CwmsMigration {
    private static final Logger log = Logger.getLogger(R__units_and_parameters.class.getName());

    private ArrayList<String> abstractParameters = new ArrayList<>();
    private Map<String,Unit> unitDefinitions = null;
    private HashSet<Conversion> conversions = new HashSet<>();

    public R__units_and_parameters() throws Exception {
        this.loadData();
    }

    @Override
    public void migrate(Context context) throws Exception {
        log.info("Inserting/Updating units");
        log.log( Level.FINEST, "Parameters: \n{0}", 
                 abstractParameters
                    .stream()
                    .collect( Collectors.joining("\n")));
        log.log( Level.FINEST, "units: \n{0}", 
                 unitDefinitions.values()
                 .stream()
                 .map( unit -> unit.toString() )
                 .collect(Collectors.joining("\n")));
        log.log( Level.FINEST, "Listed Conversions\n{0}", 
                 conversions
                 .stream()
                 .map( conv -> conv.toString() )
                 .collect(Collectors.joining("\n")));

        ConversionGraph convGraph = new ConversionGraph(conversions);

        var expandedConversions = convGraph.generateConversions();
        log.info(() -> String.format("We have %s total conversions",expandedConversions.size()));
        log.log(Level.INFO, "Expanded Conversions:\n{0}", 
                expandedConversions
                    .stream()
                    .map(conv -> conv.toString())
                    .collect(Collectors.joining("\n")));
        /* now we would insert or update the conversions */
    }

    private void loadData() throws Exception {
        ObjectMapper mapper = new ObjectMapper();        
        mapper.enable(Feature.ALLOW_COMMENTS);

        abstractParameters = mapper.readValue(
            getData("db/custom/units_and_parameters/abstract_parameters.json"),
            new TypeReference<ArrayList<String>>(){});

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

        JsonNode tmpConversions = mapper.readTree(
            getData("db/custom/units_and_parameters/conversions.json"));

        tmpConversions.forEach( (conversion) -> {                        
            //Conversion c = new Conversion(from, to, method)
            Unit from = unitDefinitions.get(conversion.get(0).asText());
            Unit to = unitDefinitions.get(conversion.get(0).asText());
            if( from !=null && to != null ) {
                Conversion c = new Conversion(from,to, new Linear(1.0, 0.0));
                conversions.add(c);
            }
            
        });


    }

    @Override
    public Integer getChecksum() {
        return Integer.valueOf(13);
    }


    
}
