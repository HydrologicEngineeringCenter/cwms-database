package db.data;

import org.apache.commons.io.IOUtils;
import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import com.fasterxml.jackson.databind.node.TreeTraversingParser;

import io.herrmann.generator.Generator;

import java.io.InputStream;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import java.util.zip.CRC32;

public class R__0001_quality extends BaseJavaMigration implements CwmsMigration {
    private static final Logger log = Logger.getLogger(R__0001_quality.class.getName());

    private Long checksum = 3L;
    private String query = null;

    private Quality screenedData;
    private Quality validityData;
    private Quality valueRangeData;
    private Quality differentData;
    private Quality replacementCauseData;
    private Quality replacementMethodData;
    private Quality testFailedData;
    private Quality protectionData;

    public void init() {

        log.info("Loading Quality Data");
        CRC32 crc = new CRC32();

        checksum = crc.getValue();
        try {
            query = readQuery("db/custom/quality/cwms_data_quality.sql");
        } catch (Exception ex) {
            throw new RuntimeException("Unable to load quality data sql",ex);
        }

    }

    private String readQuery(String filename) throws Exception {
        InputStream is = getData(filename);

        return new String( IOUtils.toByteArray(is) );
    }

    public R__0001_quality() throws Exception {
        this.init();
    }

    @Override
    public void migrate(Context context) throws Exception {
        log.info("Merging Quality Information");

        var rows = this.load_data();
        log.info("Quality Data loaded.");
        final long start = System.currentTimeMillis();
        try(
            PreparedStatement qualityInsert = context.getConnection()
                                                     .prepareStatement(expandPlaceHolders(query,context));
        ) {
            AtomicInteger count = new AtomicInteger(1);
            int batchSize = 500;
            rows.forEach(row -> {
                try {
                    qualityInsert.setLong(1, row.qualityCode);
                    qualityInsert.setString(2, row.screening);
                    qualityInsert.setString(3, row.validity);
                    qualityInsert.setString(4, row.range);
                    qualityInsert.setString(5, row.different);
                    qualityInsert.setString(6, row.replacementCause);
                    qualityInsert.setString(7, row.replacementMethod);
                    qualityInsert.setString(8, row.testFailed);
                    qualityInsert.setString(9, row.protection);

                    qualityInsert.addBatch();
                    if( count.incrementAndGet() % batchSize == 0 ){
                        qualityInsert.executeBatch();
                    }
                } catch (SQLException ex) {
                    throw new RuntimeException("unable to add element to batch or execute batch.", ex);
                }
                
            });
            qualityInsert.executeBatch();
        }
        final long end = System.currentTimeMillis();
        log.info(() -> String.format("Quality data loading took %d milliseconds", (end-start)));


    }



    private Stream<QualityRow> load_data() throws Exception {
        ObjectMapper mapper = new ObjectMapper();

        JsonNode tmp = mapper.readTree(getData("db/custom/quality/screened.json"));

        screenedData = mapper.readValue(new TreeTraversingParser(tmp,mapper), Quality.class);

        validityData = mapper.readValue(getData("db/custom/quality/validity.json"),Quality.class);

        valueRangeData = mapper.readValue(getData("db/custom/quality/value_range.json"),Quality.class);
        differentData = mapper.readValue(getData("db/custom/quality/different.json"),Quality.class);
        replacementCauseData = mapper.readValue(getData("db/custom/quality/replacement_cause.json"),Quality.class);
        replacementMethodData = mapper.readValue(getData("db/custom/quality/replacement_method.json"),Quality.class);
        testFailedData = mapper.readValue(getData("db/custom/quality/test_failed.json"),Quality.class);
        protectionData = mapper.readValue(getData("db/custom/quality/protection.json"),Quality.class);

        fillTestFailedData(testFailedData);
        log.log( Level.FINEST, "Parameters: \n{0}",
                 testFailedData.getValues()
                    .stream().map(QualityBitDescription::toString)
                    .collect( Collectors.joining("\n")));
        final String screenedName = screenedData.getValues().get(1).getName();// always screened
        List<QualityRow> rows = new ArrayList<>();

        // always unscreened
        rows.add(
            new QualityRow(0,
            screenedData.getValues().get(0).getName(),
            validityData.getValues().get(0).getName(),
            valueRangeData.getValues().get(0).getName(),
            differentData.getValues().get(0).getName(),
            replacementCauseData.getValues().get(0).getName(),
            replacementMethodData.getValues().get(0).getName(),
            testFailedData.getValues().get(0).getName(),
            protectionData.getValues().get(0).getName()
            ));

        for( QualityBitDescription validity: validityData.getValues()){
            for( QualityBitDescription range: valueRangeData.getValues()){
                for( QualityBitDescription different: differentData.getValues() ) {
                    for( QualityBitDescription replacementCause: replacementCauseData.getValues()) {
                        if( (different.getValue() > 0) != (replacementCause.getValue() > 0) ) {
                            continue;
                        }
                        for( QualityBitDescription replacementMethod: replacementMethodData.getValues() ) {
                            if( (different.getValue() > 0) != (replacementMethod.getValue() > 0)) {
                                continue;
                            }
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
                                    rows.add(
                                        new QualityRow(qualityCode,
                                                       screenedName,
                                                       validity.getName(),
                                                       range.getName(),
                                                       different.getName(),
                                                       replacementCause.getName(),
                                                       replacementMethod.getName(),
                                                       testFailed.getName(),
                                                        protection.getName()));
                                }
                            }
                        }
                    }
                }
            }
        }
        return rows.stream();
    }

    private void fillTestFailedData(Quality failedData) {
        List<QualityBitDescription> values = failedData.getValues().subList(1, failedData.getValues().size());

        List<List<QualityBitDescription>> combinations = new ArrayList<>();
        for( int i = 0; i < values.size(); i++) {

            for( List<QualityBitDescription> combinationsForElement: new UniqueComboGenerator(values,i+1)) {
                combinations.add(combinationsForElement);
            }
        }
        ArrayList<QualityBitDescription> testFails = new ArrayList<>(testFailedData.getValues().subList(0, 1));
        for(List<QualityBitDescription> combos: combinations){
            if( combos.size() == 1) {
                testFails.add(combos.get(0));
            } else if ( combos.size() > 1 ) {
                QualityBitDescription newQual =
                    combos.stream()
                          .reduce(
                            new QualityBitDescription(0L,"",""),
                            (total, element) -> {
                                total.value += element.value;
                                if( total.name.isEmpty()) {
                                    total.name += element.name;
                                } else {
                                    total.name += "+" + element.name;
                                }


                                return total;
                            }
                            );
                newQual.description = String.format("The value failed %d tests", combos.size());
                testFails.add(newQual);

            } else {
                // do nothing
            }
        }
        testFailedData.getValues().clear();
        testFailedData.getValues().addAll(testFails);
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

        public String toString() {
            StringBuilder sb = new StringBuilder();
            sb.append(value).append(",")
              .append(name).append(",")
              .append(description);
            return sb.toString();
        }

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

    private class UniqueComboGenerator extends Generator<List<QualityBitDescription>> {

        private List<QualityBitDescription> items;
        private int n;

        public UniqueComboGenerator(List<QualityBitDescription> items, int n) {
            this.items = items;
            this.n = n;
        }

        @Override
        protected void run() throws InterruptedException {
            if( this.n == 0 ) {
                yield_element(List.of());
            } else {
                for( int i = 0; i < this.items.size(); i++ ) {
                    for( List<QualityBitDescription> combos: new UniqueComboGenerator(this.items.subList(i+1, this.items.size()), this.n-1) ) {
                        ArrayList<QualityBitDescription> tmp = new ArrayList<>(Arrays.asList(this.items.get(i)));
                        tmp.addAll(combos);
                        yield_element(tmp);
                    }
                }
            }

        }

    }

    private static class QualityRow {
        public final long qualityCode;
        public final String screening;
        public final String validity;
        public final String range;
        public final String different;
        public final String replacementCause;
        public final String replacementMethod;
        public final String testFailed;
        public final String protection;

        public QualityRow(long qualityCode, String screening, String validity, String range,
                          String different, String replacementCause, String replacementMethod,
                          String testFailed, String protection) {
            this.qualityCode = qualityCode;
            this.screening = screening;
            this.validity = validity;
            this.range = range;
            this.different = different;
            this.replacementCause = replacementCause;
            this.replacementMethod = replacementMethod;
            this.testFailed = testFailed;
            this.protection = protection;
        }
        
    }
}
