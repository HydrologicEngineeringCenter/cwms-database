package db.data;

import java.sql.Connection;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.logging.Logger;
import java.util.zip.CRC32;

import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

public class R__0003_base_parameters extends BaseJavaMigration implements CwmsMigration {
    private static final Logger log = Logger.getLogger(R__0003_base_parameters.class.getName());
    public static final String baseParametersSqlFile = "db/custom/parameters/base_parameters.sql";
    public static final String baseParametersJsonFile = "db/custom/parameters/base_parameters.json";
    public static final String subParametersJsonFile = "db/custom/parameters/initial_sub-parameters.json";
    public static final String subParametersSqlFile = "db/custom/parameters/initial_sub-parameters.sql";
    public static final String defaultBaseDisplayUnitsSqlFile = "db/custom/parameters/base_display-units.sql";

    private CRC32 crc = new CRC32();
    private ArrayList<BaseParameter> parameters = null;
    private ArrayList<SubParameter> subParameters = null;
    private String baseParametersMergeSql = null;
    //private String baseParameterDefaultSql = null;
    private String subParametersMergeSql = null;
    private String defaultBaseDisplayUnitsSql = null;

    public R__0003_base_parameters() throws Exception {        
        log.info("Loading Base Parameters");
        loadData();
    }

    @Override
    public void migrate(Context context) throws Exception {

        

        log.info("Merging Base Parameters");
        Connection conn = context.getConnection();
        try (var mergeBaseParameters = conn.prepareStatement(expandPlaceHolders(baseParametersMergeSql,context));
             var mergeSubParameters = conn.prepareStatement(expandPlaceHolders(subParametersMergeSql,context));
             var defaultBaseDisplayUnits = conn.prepareStatement(expandPlaceHolders(defaultBaseDisplayUnitsSql,context));) {
            for(var param: parameters) {
                log.fine("Saving" + param.toString());
                mergeBaseParameters.clearParameters();
                mergeBaseParameters.setLong(1,param.getCode());
                mergeBaseParameters.setString(2,param.getAbstractParameter());
                mergeBaseParameters.setString(3,param.getId());
                mergeBaseParameters.setString(4,param.getLongName());
                mergeBaseParameters.setString(5,param.getStoreUnits());
                mergeBaseParameters.setString(6,param.getDisplaySI());
                mergeBaseParameters.setString(7,param.getDisplayEN());
                mergeBaseParameters.setString(8,param.getDescription());
                mergeBaseParameters.addBatch();                
            }
            mergeBaseParameters.executeBatch();
            log.info("merging sub parameters");
            for(var subParam: subParameters) {
                mergeSubParameters.clearParameters();
                mergeSubParameters.setLong(1,subParam.getCode());
                mergeSubParameters.setString(2,subParam.getBaseParameterId());
                mergeSubParameters.setString(3,subParam.getSubParameterId());
                mergeSubParameters.setString(4,subParam.getSubParameterDescription());
                mergeSubParameters.addBatch();
            }
            mergeSubParameters.executeBatch();

            defaultBaseDisplayUnits.execute();
        }
    }

    private void loadData() throws Exception {
        ObjectMapper mapper = getDefaultMapper();
        parameters = mapper.readValue(getData(baseParametersJsonFile),
                                      new TypeReference<ArrayList<BaseParameter>>(){});
        for( var p: parameters) {
            crc.update(p.toString().getBytes());
        }

        subParameters = mapper.readValue(getData(subParametersJsonFile),
                                        new TypeReference<ArrayList<SubParameter>>() {});
        for( var sp: subParameters){
            crc.update(sp.toString().getBytes());
        }
        baseParametersMergeSql = new String(getData(baseParametersSqlFile).readAllBytes());
        subParametersMergeSql = new String(getData(subParametersSqlFile).readAllBytes());
        defaultBaseDisplayUnitsSql = new String(getData(defaultBaseDisplayUnitsSqlFile).readAllBytes());
    }

    @Override
    public Integer getChecksum() {
        return Long.valueOf(crc.getValue()).intValue();
    }

    @JsonFormat(shape=JsonFormat.Shape.ARRAY)
    public static class BaseParameter {
        private Long code;
        private String id;
        private String abstractParameter;
        private String longName;
        private String storeUnits;
        private String displaySI;
        private String displayEN;
        private String description;
//                                                                                     db        -----    Default  ------
//                                                                                    store      ------Display Units-----
//   CODE   ABSTRACT PARAMETER                  ID             NAME                  UNIT ID      SI       Non-SI         DESCRIPTION

        @JsonCreator(mode=JsonCreator.Mode.PROPERTIES)
        public BaseParameter(@JsonProperty(value="code",index=0) Long code,
                            @JsonProperty(value="abstract-param",index=1) String abstractParameter,
                            @JsonProperty(value="id",index=2) String id,
                            @JsonProperty(value="long-name",index=3) String longName,
                            @JsonProperty(value="store-units",index=4) String storeUnits,
                            @JsonProperty(value="display-si",index=5) String displaySI,
                            @JsonProperty(value="display-en",index=6) String displayEN,
                            @JsonProperty(value="description",index=7) String description) {
            this.code = code;
            this.abstractParameter = abstractParameter;
            this.id = id;
            this.longName = longName;
            this.storeUnits = storeUnits;
            this.displaySI = displaySI;
            this.displayEN = displayEN;
            this.description = description;
        }


        public Long getCode() { return code; }
        public String getId() { return id; }
        public String getLongName() { return longName; }
        public String getStoreUnits() { return storeUnits; }
        public String getDisplaySI() { return displaySI; }
        public String getDisplayEN() { return displayEN; }
        public String getDescription() { return description; }
        public String getAbstractParameter() { return abstractParameter; }

        @Override
        public String toString() {
            StringBuilder builder = new StringBuilder();
            builder.append("base_parameter{")
                   .append("code=").append(code).append(",")
                   .append("id=").append(id).append(",")
                   .append("abstract-parameter=").append(abstractParameter).append(",")
                   .append("long-name=").append(longName).append(",")
                   .append("store-unit=").append(storeUnits).append(",")
                   .append("display-si=").append(displaySI).append(",")
                   .append("display-en=").append(displayEN).append(",")
                   .append("description=").append(description)                   
                   .append("}");


                
            return builder.toString();
        }

    }

    @JsonFormat(shape=JsonFormat.Shape.ARRAY)
    public static class SubParameter {
          //           --  DEFAULT Sub_Parameters -------------------------------    -- Display Units --
    //    Param  Base        Sub
    //    Code   Param       Param          Sub-Parameter Descripiton           SI         Non-SI
    //    ----- ----------- -------------- ---------------------------------- ---------- ---------
    //[ 301,  "%",        "ofArea-Snow", "Percent of Area Covered by Snow", "%",       "%"],
        private Long code;
        private String baseParameterId;
        private String subParameterId;
        private String subParameterDescription;
        private String displaySI;
        private String displayEN;

        public Long getCode() { return code; }
        public String getBaseParameterId() { return baseParameterId; }
        public String getSubParameterId() { return subParameterId; }        
        public String getDisplaySI() { return displaySI; }
        public String getDisplayEN() { return displayEN; }
        public String getSubParameterDescription() { return subParameterDescription; }

        @JsonCreator(mode=JsonCreator.Mode.PROPERTIES)
        public SubParameter(@JsonProperty(value="code",index=0) Long code,
                            @JsonProperty(value="base-parameter-id",index=1) String baseParameterId,
                            @JsonProperty(value="sub-parameter-id",index=2) String subParameterId,
                            @JsonProperty(value="sub=parameter-description",index=3) String subParameterDescription,                            
                            @JsonProperty(value="display-si",index=4) String displaySI,
                            @JsonProperty(value="display-en",index=5) String displayEN
                            ) {
            this.code = code;
            this.baseParameterId = baseParameterId;
            this.subParameterDescription = subParameterDescription;
            this.subParameterId = subParameterId;
            this.displaySI = displaySI;
            this.displayEN = displayEN;
            
        }


        @Override
        public String toString() {
            StringBuilder builder = new StringBuilder();
            builder.append("sub_parameter{")
                   .append("code=").append(code).append(",")
                   .append("base-parameter-id=").append(baseParameterId).append(",")
                   .append("sub-parameter-id=").append(subParameterId).append(",")
                   .append("sub-parameter-description=").append(subParameterDescription).append(",")
                   
                   .append("display-si=").append(displaySI).append(",")
                   .append("display-en=").append(displayEN).append(",")
                   .append("description=").append(subParameterDescription)                   
                   .append("}");


                
            return builder.toString();
        }

    }
    
}
