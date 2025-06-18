create or replace and compile java source named "random_uuid" as
public class RandomUUID {
    public static String create() {
        return java.util.UUID.randomUUID().toString();
    }
}
/
create or replace function random_uuid
return varchar2
as language java
name 'RandomUUID.create() return java.lang.String';
/