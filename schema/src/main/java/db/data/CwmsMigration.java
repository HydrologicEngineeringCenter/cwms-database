package db.data;

import java.io.InputStream;

import com.fasterxml.jackson.core.JsonParser.Feature;
import com.fasterxml.jackson.databind.ObjectMapper;

public interface CwmsMigration {
    static final ObjectMapper defaultMapper = new ObjectMapper().enable(Feature.ALLOW_COMMENTS);

    default public ObjectMapper getDefaultMapper() {
        return defaultMapper;
    }

    default public InputStream getData(String resourceName) {
        return this.getClass().getClassLoader().getResourceAsStream(resourceName);
    }
}
