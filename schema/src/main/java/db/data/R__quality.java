package db.data;

import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;
import java.util.zip.CRC32;

public class R__quality extends BaseJavaMigration {
    private static final Logger log = Logger.getLogger(R__quality.class.getName());

    public int checksum = 3;

    public Quality screened;
    public Quality validity;

    public void init() throws Exception {
        
        log.info("Loading Quality Data");
        CRC32 crc = new CRC32();
        
        ObjectMapper mapper = new ObjectMapper();

        screened = mapper.readValue(this.getClass().getClassLoader().getResourceAsStream("db/custom/quality/screened.json"),Quality.class);
        log.info("Shift is: " + screened.getShift());
        
        validity = mapper.readValue(this.getClass().getClassLoader().getResourceAsStream("db/custom/quality/validity.json"),Quality.class);
        log.info("Shift is: " + validity.getShift());
    }
    
    public R__quality() throws Exception {
        this.init();
    }

    @Override
    public void migrate(Context context) throws Exception {
        log.info("hello");
        

    }

    @Override
    public String getDescription(){
        return "Filling the quality description table.";
    }

    /* 
    @Override
    public Integer getChecksum(){
        return Integer.valueOf(checksum);
    }*/

    public static class QualityBitDescription {
        private int value;
        private String name;
        private String description;

        
        public QualityBitDescription(@JsonProperty List<String> values){
            this.value = Integer.parseInt((values.get(0)));
            this.name= values.get(1);
            this.description = values.get(2);
        }
        @JsonCreator(mode=JsonCreator.Mode.PROPERTIES)
        public QualityBitDescription(@JsonProperty(value="value",index=0) int value, 
                                     @JsonProperty(value="name",index=1) String name,
                                     @JsonProperty(value="description",index=2) String description) {
            this.value = value;
            this.name = name;
            this.description = description;
        }

        int getValue() { return value; }
        String getName() { return name; }
        String description() { return description; }

    }

    public static class Quality {
        private int shift;
        @JsonFormat(shape=JsonFormat.Shape.ARRAY)        
        private List<QualityBitDescription> values = null;

        @JsonCreator(mode = JsonCreator.Mode.PROPERTIES)
        public Quality(@JsonProperty("shift") int shift, @JsonProperty("values") List<QualityBitDescription> values) {
            this.shift = shift;
            this.values = values;
        }

        int getShift() { return shift; }
        List<QualityBitDescription> getValues() { return values; }
    }
}
