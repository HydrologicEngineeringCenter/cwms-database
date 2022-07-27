package db.data;

import java.io.InputStream;

public interface CwmsMigration {
    default public InputStream getData(String resourceName) {
        return this.getClass().getClassLoader().getResourceAsStream(resourceName);
    }
}
