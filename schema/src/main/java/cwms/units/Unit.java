package cwms.units;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

import cwms.CwmsMigrationError;

public class Unit {
    private String abstractParameter;
    private String abbreviation;        
    private String system;
    private String name;
    private String description;

    public String getAbstractParameter() { return abstractParameter; }
    public String getAbbreviation() { return abbreviation; }
    public String getSystem() { return system; }
    public String getName() { return name; }
    public String getDescription() { return description; }
    
    @JsonCreator(mode=JsonCreator.Mode.PROPERTIES)
    public Unit(@JsonProperty(value="abstract-parameter",required = true) String abstractParameter, 
                          @JsonProperty(value="abbr", required = true) String abbreviation,
                          @JsonProperty(value="system", required = true) String system,
                          @JsonProperty(value="name", required = true) String name,
                          @JsonProperty(value="description", required = true) String description                                     
                    ) throws CwmsMigrationError {
        this.abstractParameter = abstractParameter;
        this.abbreviation = abbreviation;
        
        this.name = name;
        this.description = description;
        
        if( ! /* not */
            (system.equalsIgnoreCase("EN") 
            || 
            system.equalsIgnoreCase("SI") 
            || 
            system.equalsIgnoreCase("NULL"))) {
                throw new CwmsMigrationError(String.format("Invalid Unit System (%s) set for unit %s/%s",system,abstractParameter,abbreviation));
        }
        this.system = system.toUpperCase();
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append(name)
          .append("{param=").append(abstractParameter).append(",")
          .append("unit=").append(abbreviation).append(",")
          .append("system=").append(system).append(",")
          .append("description=").append(description).append("}");
        return sb.toString();
    }
}