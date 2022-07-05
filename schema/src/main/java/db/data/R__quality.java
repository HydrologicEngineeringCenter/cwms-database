package db.data;

import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import com.fasterxml.jackson.annotation.JsonBackReference;
import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonIdentityInfo;
import com.fasterxml.jackson.annotation.JsonManagedReference;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.ObjectIdGenerators;
import com.fasterxml.jackson.core.JsonFactory;
import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.JsonDeserializer;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import com.fasterxml.jackson.databind.module.SimpleModule;
import com.fasterxml.jackson.databind.node.TreeTraversingParser;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import java.util.zip.CRC32;

public class R__quality extends BaseJavaMigration {
    private static final Logger log = Logger.getLogger(R__quality.class.getName());

    private Long checksum = 3L;

    private Quality screenedData;
    private Quality validityData;
    private Quality valueRangeData;
    private Quality differentData;
    private Quality replacementCauseData;
    private Quality replacementMethodData;
    private Quality testFailedData;
    private Quality protectionData;

    public void init() throws Exception {
        
        log.info("Loading Quality Data");
        CRC32 crc = new CRC32();
        
        checksum = 6L;//crc.getValue();
    }

    public InputStream getData(String fileName) throws Exception {
        return this.getClass().getClassLoader().getResourceAsStream(fileName);
    }
    
    public R__quality() throws Exception {
        this.init();
    }

    @Override
    public void migrate(Context context) throws Exception {
        log.info("hello");
        
        this.load_data();

        try( PreparedStatement qualityInsert = context.getConnection().prepareStatement(
              "insert into cwms_data_quality"
            + "(QUALITY_CODE,SCREENED_ID,VALIDITY_ID,RANGE_ID,CHANGED_ID,REPL_CAUSE_ID,REPL_METHOD_ID,TEST_FAILED_ID,PROTECTION_ID)"
            + " values(?   ,?           ,?          ,?       ,?         ,?            ,?             ,?             ,?)");
        //             1    2            3           4        5          6             7              8              9
        ) {
            qualityInsert.setLong(1, 0); // always unscreened
            qualityInsert.setString(2,screenedData.getValues().get(0).getName());
            qualityInsert.setString(3,validityData.getValues().get(0).getName());
            qualityInsert.setString(4,valueRangeData.getValues().get(0).getName());
            qualityInsert.setString(5,differentData.getValues().get(0).getName());
            qualityInsert.setString(6,replacementCauseData.getValues().get(0).getName());
            qualityInsert.setString(7,replacementMethodData.getValues().get(0).getName());
            qualityInsert.setString(8,testFailedData.getValues().get(0).getName());
            qualityInsert.setString(9,protectionData.getValues().get(0).getName());
            qualityInsert.addBatch();
            
            for( QualityBitDescription validity: validityData.getValues()){
                for( QualityBitDescription range: valueRangeData.getValues()){
                    for( QualityBitDescription different: differentData.getValues() ) {
                        for( QualityBitDescription replacementCause: replacementCauseData.getValues()) {
                            for( QualityBitDescription replacementMethod: replacementMethodData.getValues() ) {
                                for( QualityBitDescription testFailed: testFailedData.getValues() ) {
                                    for( QualityBitDescription protection: protectionData.getValues() ) {
                                        long qualityCode = 0L 
                                                    | (screenedData.getValues().get(1).getValue() << screenedData.getShift())
                                                    | (validity.getValue() << validityData.getShift() )
                                                    | (range.getValue() << valueRangeData.getShift() )
                                                    | (different.getValue() << differentData.getShift() )
                                                    | (replacementCause.getValue() << replacementCauseData.getShift() )
                                                    | (replacementMethod.getValue() << replacementMethodData.getShift() )
                                                    | (testFailed.getValue() << testFailedData.getShift() )
                                                    | (protection.getValue() << protectionData.getShift() );

                                        qualityInsert.setLong(1, qualityCode);
                                        qualityInsert.setString(2,screenedData.getValues().get(1).getName()); // always screened
                                        qualityInsert.setString(3,validity.getName());
                                        qualityInsert.setString(4,range.getName());
                                        qualityInsert.setString(5,different.getName());
                                        qualityInsert.setString(6,replacementCause.getName());
                                        qualityInsert.setString(7,replacementMethod.getName());
                                        qualityInsert.setString(8,testFailed.getName());
                                        qualityInsert.setString(9,protection.getName());
                                        qualityInsert.addBatch();
                                    }
                                }
                            }

                        }
                    }
                }                
            }
            qualityInsert.executeBatch();

        }


    }

    
    
    private void load_data() throws Exception {
        ObjectMapper mapper = new ObjectMapper();        

        JsonNode tmp = mapper.readTree(getData("db/custom/quality/screened.json"));

        screenedData = mapper.readValue(new TreeTraversingParser(tmp,mapper), Quality.class);
        log.info("Shift is: " + screenedData.getShift());
        
        validityData = mapper.readValue(getData("db/custom/quality/validity.json"),Quality.class);
        log.info("Shift is: " + validityData.getShift());

        valueRangeData = mapper.readValue(getData("db/custom/quality/value_range.json"),Quality.class);
        differentData = mapper.readValue(getData("db/custom/quality/different.json"),Quality.class);
        replacementCauseData = mapper.readValue(getData("db/custom/quality/replacement_cause.json"),Quality.class);
        replacementMethodData = mapper.readValue(getData("db/custom/quality/replacement_method.json"),Quality.class);
        testFailedData = mapper.readValue(getData("db/custom/quality/test_failed.json"),Quality.class);
        protectionData = mapper.readValue(getData("db/custom/quality/protection.json"),Quality.class);

        fillTestFailedData(testFailedData);
    }

    private void fillTestFailedData(Quality failedData) {
        List<QualityBitDescription> values = failedData.getValues().subList(1, failedData.getValues().size());

        List<List<QualityBitDescription>> combinations = new ArrayList<>();
        for( int i = 0; i < values.size(); i++) {
            for( List<QualityBitDescription> combinationsForElement: uniqueCombinations(values,i+1)) {
                combinations.add(combinationsForElement);
            }
        }

        for(List<QualityBitDescription> combos: combinations){
            if( combos.size() == 1) {
                failedData.getValues().add(combos.get(0)); 
            } else if ( combos.size() > 1 ) {
                QualityBitDescription newQual = 
                    combos.stream()
                          .reduce( 
                            new QualityBitDescription(0L,"",""), 
                            (total, element) -> { 
                                total.value += element.value;
                                total.name += "+" + element.name;
                                
                                return total;
                            }
                            );
                newQual.description = String.format("The value failed %d tests", combos.size());
                failedData.getValues().add(newQual);

            } else {
                // do nothing
            }
            
        }
    }

    

    private List<List<QualityBitDescription>> uniqueCombinations(List<QualityBitDescription> values, int i) {        
        return  values.stream()
                      .flatMap( curVal -> values.subList(i,values.size())
                                             .stream()
                                             .map( subVal -> new ArrayList<>(Arrays.asList(curVal,subVal))))
                       .collect(Collectors.toList());   
    }

    @Override
    public String getDescription() {
        return "Filling or updating the quality description table.";
    }

     
    @Override
    public Integer getChecksum() {
        return checksum.intValue();
    }

    public static class QualityBitDescription {
        private long value;
        private String name;
        private String description;        
        
        public QualityBitDescription(@JsonProperty List<String> values){
            this.value = Integer.parseInt((values.get(0)));
            this.name= values.get(1);
            this.description = values.get(2);
        }

        @JsonCreator(mode=JsonCreator.Mode.PROPERTIES)
        public QualityBitDescription(@JsonProperty(value="value",index=0) long value, 
                                     @JsonProperty(value="name",index=1) String name,
                                     @JsonProperty(value="description",index=2) String description                                     
                        ) {
            this.value = value;
            this.name = name;
            this.description = description;            
        }

        long getValue() { return value; }
        String getName() { return name; }
        String description() { return description; }


        
    }

    public static class Quality {
        private long shift;
        @JsonFormat(shape=JsonFormat.Shape.ARRAY)                
        private List<QualityBitDescription> values = null;

        @JsonCreator(mode = JsonCreator.Mode.PROPERTIES)
        public Quality(@JsonProperty("shift") int shift, @JsonProperty("values") List<QualityBitDescription> values) {
            this.shift = shift;
            this.values = values;
        }

        public long getShift() { return shift; }        
        public List<QualityBitDescription> getValues() { return values; }
    }
}
