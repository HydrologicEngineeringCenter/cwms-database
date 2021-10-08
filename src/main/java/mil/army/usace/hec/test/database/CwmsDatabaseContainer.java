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
/**
 * An container manager to manage creation of CWMSDatabases for automated tests
 */
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

    /**
     * DockerImageName corresponding to the oracle version you want to use.
     * The following is currently tested:
     * oracle/database-19.3.0-ee
     * @param oracleImageName
     */
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
    /**
     * See CwmsDatabaseContainer(DockerImageName oracleImageName)
     * The constant ORACLE_19C is the current valid image
     * @param oracleVersion
     */
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

    /**
     * Retrieve a regular "CWMS User" name for the system
     */
	@Override
	public String getUsername() {
		return officeEroc+"hectest";
	}

    /**
     * The password shared by all accounts
     */
	@Override
	public String getPassword() {

		return password;
	}

	@Override
	protected String getTestQueryString() {
		return "select 1 from dual";
	}


    /**
     * The 3-4 letter office code you want this database to be for.
     * @param officeId
     * @return
     */
    public SELF withOfficeId(String officeId){
        this.officeId = officeId;
        return self();
    }

    /**
     * The two character (letter,digit) office identifier corresponding to the office ID you've choosen.
     * @param officeEroc
     * @return
     */
    public SELF withOfficeEroc(String officeEroc){
        this.officeEroc = officeEroc;
        return self();
    }

    /**
     * What Oracle SYS password to you. NOTE: not requried, a default is created for this instance
     * @param sysPassword
     * @return
     */
    public SELF withSysPassword(String sysPassword){
        this.sysPassword = sysPassword;
        return self();
    }


    /**
     * Name of the docker volume to user for this run, it can be whatever you want locally but should be based
     * on branch name on the build server
     * @param volumeName
     * @return
     */
    public SELF withVolumeName(String volumeName){
        this.volumeName = volumeName;
        return self();
    }

    /**
     * What version of the cwms database you desire for this test. It should only be the version number
     * e.g. 18-SNAPSHOT, or 18.1.9, etc
     * @param schemaVersion
     * @return
     */
    public SELF withSchemaVersion(String schemaVersion){
        this.schemaVersion = schemaVersion;
        return self();
    }

    /**
     * Get the user name for a user with CWMS_DBA privileges
     * @return
     */
    public String getDbaUser() {
        return officeEroc+"hectest_db";
    }

    /**
     * Get the username for a user with CWMS PD User privileges.
     * @return
     */
    public String getPdUser() {
        return officeEroc+"hectest_pu";
    }


    /**
     * get the username for a user with Read Only privileges
     * @return
     */
    public String getReadOnly() {
        return officeEroc+"hectest_ro";
    }

    /**
     * Execute a block of sql, it can be any valid sql but assumes there is no returned contents to the user
     * Default to executing with the user from getUsername();
     * @param theSQL
     * @throws SQLException
     */
    public void executeSQL( String theSQL ) throws SQLException {
        this.executeSQL(theSQL, getUsername() );
    }

    /**
     * As executeSQL without a user, but instead use the specified username.
     * @param theSQL
     * @param user
     * @throws SQLException
     */
    public void executeSQL( String theSQL, String user) throws SQLException {
        connection( (c) -> {

            try( Statement stmt = c.createStatement(); ){
                stmt.execute(theSQL);
            } catch ( SQLException e ){
                throw new RuntimeException(e);
            }


        }, user );
    }

    /**
     * Create connection with the specified user
     * @param user
     * @return
     * @throws SQLException
     * @throws NoDriverFoundException
     */
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

    /**
     * Get an open connection from the system and perform arbitrary JDBC commands."
     * @param function
     * @throws SQLException
     */
    public void connection ( Consumer<java.sql.Connection> function ) throws SQLException {
        this.connection(function, getUsername() );
    }

    /**
     * As connection without a user, but uses the specified username instead of the default
     * @param function
     * @param user
     * @throws SQLException
     */
    public void connection( Consumer<java.sql.Connection> function, String user ) throws SQLException{
        try( Connection conn = getConnection(user);){
            function.accept(conn);
        }

    }
}
