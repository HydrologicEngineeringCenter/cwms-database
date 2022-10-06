package db.data;

import java.io.IOException;
import java.io.InputStream;
import java.io.StringReader;
import java.util.Map;

import org.apache.commons.io.IOUtils;
import org.flywaydb.core.api.migration.Context;
import org.flywaydb.core.internal.parser.PlaceholderReplacingReader;

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

    default public String expandPlaceHolders(String input, Context context) throws IOException {
        
        PlaceholderReplacingReader reader = 
            new PlaceholderReplacingReader(
                    context.getConfiguration().getPlaceholderPrefix(),
                    context.getConfiguration().getPlaceholderSuffix(),
                    context.getConfiguration().getPlaceholders(),
                    new StringReader(input)
                );
        return IOUtils.toString(reader);
    }
}
