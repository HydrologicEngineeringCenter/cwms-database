package cwms;

public class CwmsMigrationError extends RuntimeException {
    public CwmsMigrationError(String msg) {
        super(msg);
    }

    public CwmsMigrationError(String msg, Throwable err) {
        super(msg,err);
    }
}
