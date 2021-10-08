package mil.army.usace.hec.test.database;


import java.time.Duration;
import java.util.function.Function;
import java.util.function.Consumer;
import java.sql.Driver;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Properties;


import com.github.dockerjava.api.model.Bind;
import com.github.dockerjava.api.command.InspectContainerResponse;


import org.testcontainers.containers.Network;


import org.testcontainers.containers.JdbcDatabaseContainer;
import org.testcontainers.utility.DockerImageName;


import org.testcontainers.containers.ContainerLaunchException;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.startupcheck.OneShotStartupCheckStrategy;
import org.testcontainers.containers.wait.strategy.LogMessageWaitStrategy;
import org.testcontainers.containers.wait.strategy.Wait;

public class CwmsDatabaseContainer<SELF extends CwmsDatabaseContainer<SELF>> extends JdbcDatabaseContainer<SELF> {
    public static final String ORACLE_19C= "oracle/database:19.3.0-ee";
    private static final String PDBNAME = "CWMS";
    private static final String NETWORK_ALIAS = "cwmsdb";

    // CWMS Portion
    private String password = "cwmspassword";
    private String buildUserPassword = "builduserpassword";
    private String officeId = "SPK";
    private String officeEroc = "l2";
    private String cwmsImageName = "cwms_schema_installer";
    private String schemaVersion = "";
    private Driver driverInstance = null;

    //Oracle Portion

    private String sysPassword = "SmallPass0wrd";
    private String volumeName = "cwms_test_db_volume";

    GenericContainer<?> cwmsInstaller = null;

    public CwmsDatabaseContainer(DockerImageName oracleImageName) {
		super(oracleImageName);



        this.waitStrategy = new LogMessageWaitStrategy()
            .withRegEx("^DATABASE IS READY TO USE.*\\n")
            .withTimes(1)
            .withStartupTimeout(Duration.ofMinutes(30)) // it's oracle, it just takes that long
            ;
        this.withStartupTimeoutSeconds((int)Duration.ofMinutes(30).getSeconds());
        this.withReuse(true);
    }

	public CwmsDatabaseContainer(final String oracleVersion) {
        this(DockerImageName.parse(oracleVersion));
    }

    @Override
    protected void configure(){


        addExposedPorts(1521);
        setNetwork(Network.newNetwork());
        withNetworkAliases(NETWORK_ALIAS);

        addEnv("enterprise","1");
        addEnv("ORACLE_PDB",PDBNAME);
        addEnv("ORACLE_PWD",sysPassword);

        this.withCreateContainerCmdModifier(
                cmd -> cmd.getHostConfig().withBinds(Bind.parse(volumeName+":/opt/oracle/oradata"))
                );

        String imageName = schemaVersion.isEmpty() ? cwmsImageName: cwmsImageName+":"+schemaVersion;

        cwmsInstaller = new GenericContainer<>(DockerImageName.parse(imageName));

        cwmsInstaller.addEnv("OFFICE_ID",officeId);
        cwmsInstaller.addEnv("OFFICE_EROC",officeEroc);
        cwmsInstaller.addEnv("BUILDUSER_PASSWORD",buildUserPassword);
        cwmsInstaller.addEnv("CWMS_PASSWORD",password);
        cwmsInstaller.addEnv("DB_HOST_PORT",""+NETWORK_ALIAS+":1521");
        cwmsInstaller.addEnv("DB_NAME","/"+PDBNAME);
        cwmsInstaller.addEnv("SYS_PASSWORD",sysPassword);
        cwmsInstaller.withStartupCheckStrategy(
            new OneShotStartupCheckStrategy().withTimeout(Duration.ofMinutes(15))
        );
        cwmsInstaller.dependsOn(this);
        cwmsInstaller.withReuse(true);
        //setNetwork(oracle.getNetwork());
    }

    /*
	@Override
	public void close() throws Exception {

	}*/

    @Override
    protected void waitUntilContainerStarted() {
        getWaitStrategy().waitUntilReady(this);
    }

    @Override
    protected void containerIsStarted(InspectContainerResponse containerInfo) {
        super.containerIsStarted(containerInfo);
        System.out.println("Installing schema");
        cwmsInstaller.setNetwork(getNetwork());
        cwmsInstaller.start();
    }

	@Override
	public String getDriverClassName() {
		return "oracle.jdbc.driver.OracleDriver";
	}


	@Override
	public String getJdbcUrl() {
		return String.format("jdbc:oracle:thin:@%s:%d/%s", getHost(),getMappedPort(1521),PDBNAME);
	}

	@Override
	public String getUsername() {
		return officeEroc+"hectest";
	}

	@Override
	public String getPassword() {

		return password;
	}

	@Override
	protected String getTestQueryString() {
		return "select 1 from dual";
	}


    public SELF withOfficeId(String officeId){
        this.officeId = officeId;
        return self();
    }

    public SELF withOfficeEroc(String officeEroc){
        this.officeEroc = officeEroc;
        return self();
    }


    public SELF withSysPassword(String sysPassword){
        this.sysPassword = sysPassword;
        return self();
    }

    public SELF withVolumeName(String volumeName){
        this.volumeName = volumeName;
        return self();
    }

    public SELF withSchemaVersion(String schemaVersion){
        this.schemaVersion = schemaVersion;
        return self();
    }


    public String getDbaUser() {
        return officeEroc+"hectest_db";
    }

    public String getPdUser() {
        return officeEroc+"hectest_pu";
    }

    public String getReadOnly() {
        return officeEroc+"hectest_ro";
    }

    public void executeSQL( String theSQL ) throws SQLException {
        this.executeSQL(theSQL, getUsername() );
    }

    public void executeSQL( String theSQL, String user) throws SQLException {
        connection( (c) -> {

            try( Statement stmt = c.createStatement(); ){
                stmt.execute(theSQL);
            } catch ( SQLException e ){
                throw new RuntimeException(e);
            }


        }, user );
    }


    private Connection getConnection(String user) throws SQLException, NoDriverFoundException {
        if( driverInstance == null ){
            try{
                driverInstance = (Driver)Class.forName(this.getDriverClassName()).newInstance();
            } catch( InstantiationException | IllegalAccessException | ClassNotFoundException e){
                throw new NoDriverFoundException("Could not get driver", e);
            }
        }

        Properties info = new Properties();
        info.put("user", user);
        info.put("password", this.getPassword());

        return driverInstance.connect(getJdbcUrl(),info);

    }

    public void connection ( Consumer<java.sql.Connection> function ) throws SQLException {
        this.connection(function, getUsername() );
    }

    public void connection( Consumer<java.sql.Connection> function, String user ) throws SQLException{
        try( Connection conn = getConnection(user);){
            function.accept(conn);
        }

    }
}
