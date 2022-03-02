package cwms.resolvers;

import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.io.Reader;

import org.flywaydb.core.api.FlywayException;
import org.flywaydb.core.api.resource.LoadableResource;

public class DataResource extends LoadableResource {

    private File file;

    DataResource( File file ){
        this.file = file;
    }

    public long size() {
        return file.length();
    }

    @Override
    public String getAbsolutePath() {
        return file.getAbsolutePath();
    }

    @Override
    public String getAbsolutePathOnDisk() {
        return file.getAbsolutePath();
    }

    @Override
    public String getFilename() {

        return file.getName();
    }

    @Override
    public String getRelativePath() {
        return file.getPath();
    }

    @Override
    public Reader read() {
        try{
            return new FileReader(file);
        } catch( IOException e ){
            throw new FlywayException("Failed to load resource",e);
        }
    }
}
