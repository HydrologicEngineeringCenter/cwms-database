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
import org.testcontainers.containers.output.OutputFrame;
import org.testcontainers.containers.JdbcDatabaseContainer;
import org.testcontainers.utility.DockerImageName;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testcontainers.containers.ContainerLaunchException;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.startupcheck.OneShotStartupCheckStrategy;
import org.testcontainers.containers.wait.strategy.LogMessageWaitStrategy;
import org.testcontainers.containers.wait.strategy.Wait;
/**
 * An container manager to manage creation of CWMSDatabases for automated tests
 */
public class CwmsDatabaseContainer<SELF extends CwmsDatabaseContainer<SELF>> extends JdbcDatabaseContainer<SELF> {
    public static final Logger log = LoggerFactory.getLogger(CwmsDatabaseContainer.class);
    public static final String ORACLE_19C= "oracle/database:19.3.0-ee";
    public static final String ORACLE_18XE = "oracle/database:18.4.0-xe";

    public static final String BYPASS_URL = "testcontainer.cwms.bypass.url";
    public static final String BYPASS_SYS_PASSWORD = "testcontainer.cwms.bypass.sys.pass";
    public static final String BYPASS_CWMS_PASSWORD = "testcontainer.cwms.bypass.cwms.pass";
    public static final String BYPASS_CWMS_OFFICE_ID = "testcontainer.cwms.bypass.office.id";
    public static final String BYPASS_CWMS_OFFICE_EROC="testcontainer.cwms.bypass.office.eroc";

    private static final String NETWORK_ALIAS = "cwmsdb";

    // CWMS Portion
    private String password = System.getProperty(BYPASS_CWMS_PASSWORD,"cwmspassword");
    private String buildUserPassword = "builduserpassword";
    private String officeId = System.getProperty(BYPASS_CWMS_OFFICE_ID,"SPK");
    private String officeEroc = System.getProperty(BYPASS_CWMS_OFFICE_EROC,"l2");
    private String cwmsImageName = "cwms_schema_installer";
    private String schemaVersion = "";
    private Driver driverInstance = null;

    //Oracle Portion

    private String sysPassword = "SmallPass0wrd";
    private String volumeName = "cwms_test_db_volume";
    private String pdbName = "CWMS";


    private boolean bypass = System.getProperty(BYPASS_URL) != null;

    GenericContainer<?> cwmsInstaller = null;
    private Consumer<OutputFrame> logConsumer = null;

    /**
     * DockerImageName corresponding to the oracle version you want to use.
     * The following is currently tested:
     * oracle/database-19.3.0-ee
     * @param oracleImageName
     */
    public CwmsDatabaseContainer(DockerImageName oracleImageName) {
		super(oracleImageName);

        if( oracleImageName.asCanonicalNameString().endsWith("-xe")){
            log.debug("Set pluggable database name to XEPDB1");
            pdbName="XEPDB1";
            volumeName = volumeName + "_xe";
        }

        this.waitStrategy = new LogMessageWaitStrategy()
            .withRegEx("^DATABASE IS READY TO USE.*\\n")
            .withTimes(1)
            .withStartupTimeout(Duration.ofMinutes(50)) // it's oracle, it just takes that long, sometimes
            ;
        this.withStartupTimeoutSeconds((int)Duration.ofMinutes(50).getSeconds());
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
        log.debug("Configuring Database and Schema container");

        addExposedPorts(1521);
        setNetwork(Network.newNetwork());
        withNetworkAliases(NETWORK_ALIAS);

        addEnv("enterprise","1");
        addEnv("ORACLE_PDB",pdbName);
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
        cwmsInstaller.addEnv("DB_NAME","/"+pdbName);
        cwmsInstaller.addEnv("SYS_PASSWORD",sysPassword);
        cwmsInstaller.withStartupCheckStrategy(
            new OneShotStartupCheckStrategy().withTimeout(Duration.ofMinutes(15))
        );
        cwmsInstaller.dependsOn(this);
        cwmsInstaller.withReuse(true);
        //setNetwork(oracle.getNetwork());
        if( logConsumer != null ){
            cwmsInstaller.withLogConsumer(this.logConsumer);
        }
        log.debug("Configuration Finished");
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
        if( bypass ) return;

        super.containerIsStarted(containerInfo);

        try{
            executeSQL("alter system set JAVA_JIT_ENABLED=FALSE", "sys");
            log.debug("JAVA_JIT disabled");
        } catch( SQLException err ){
            throw new RuntimeException("Error getting database into correct state",err);
        }

        cwmsInstaller.setNetwork(getNetwork());
        log.info("Installing schema");
        cwmsInstaller.start();
    }

	@Override
	public String getDriverClassName() {
        return "oracle.jdbc.OracleDriver";
	}

    @Override
    public void start(){
        if( bypass ) return;
        log.debug("Starting Database");
        super.start();
        log.debug("Database Started and Schema {}:{} installed",cwmsImageName,schemaVersion);

    }

    /**
     *
     * @return the appropriate JDBC url for this container
     */
	@Override
	public String getJdbcUrl() {
        if( !bypass) {
            return String.format("jdbc:oracle:thin:@%s:%d/%s?oracle.net.disableOob=true", getHost(),getMappedPort(1521),pdbName);
        } else {
            return System.getProperty(BYPASS_URL);
        }

	}

    /**
     * Retrieve a regular "CWMS User" name for the system
     */
	@Override
	public String getUsername() {
		return officeEroc+"hectest";
	}

    public String getOfficeId() {
		return officeId;
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
     * @return This Container
     */
    public SELF withOfficeId(String officeId){
        this.officeId = System.getProperty(BYPASS_CWMS_OFFICE_ID,officeId);
        return self();
    }

    /**
     * The two character (letter,digit) office identifier corresponding to the office ID you've choosen.
     * @param officeEroc
     * @return This Container
     */
    public SELF withOfficeEroc(String officeEroc){
        this.officeEroc = System.getProperty(BYPASS_CWMS_OFFICE_EROC,officeEroc);
        return self();
    }

    /**
     * What Oracle SYS password to use. NOTE: not required, a default is created for this instance
     * @param sysPassword
     * @return This Container
     */
    public SELF withSysPassword(String sysPassword){
        this.sysPassword = System.getProperty(BYPASS_SYS_PASSWORD, sysPassword);
        return self();
    }


    /**
     * Name of the docker volume to user for this run, it can be whatever you want locally but should be based
     * on branch name on the build server
     * @param volumeName
     * @return This Container
     */
    public SELF withVolumeName(String volumeName){
        this.volumeName = volumeName;
        return self();
    }

    /**
     * What version of the cwms database you desire for this test. It should only be the version number
     * e.g. 18-SNAPSHOT, or 18.1.9, etc
     * @param schemaVersion
     * @return This Container
     */
    public SELF withSchemaVersion(String schemaVersion){
        this.schemaVersion = schemaVersion;
        return self();
    }

    /**
     *
     * @return the user name for a user with CWMS_DBA privileges
     */
    public String getDbaUser() {
        return officeEroc+"hectest_db";
    }

    /**
     *
     * @return the username for a user with CWMS PD User privileges.
     */
    public String getPdUser() {
        return officeEroc+"hectest_pu";
    }


    /**
     *
     * @return the username for a user with Read Only privileges
     */
    public String getReadOnlyUser() {
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
     *
     * @param user
     * @return connection opened with the specified user
     * @throws SQLException
     * @throws NoDriverFoundException
     */
    private Connection getConnection(String user) throws SQLException, NoDriverFoundException {
        if( driverInstance == null ){
            try{
                driverInstance = (Driver)Class.forName(this.getDriverClassName()).newInstance();
                log.debug("Oracle Driver Loaded");
            } catch( InstantiationException | IllegalAccessException | ClassNotFoundException e){
                throw new NoDriverFoundException("Could not get driver", e);
            }
        }


        Properties info = new Properties();
        info.put("user", user.equals("sys") ? user +" as sysdba": user);
        info.put("password", user.equals("sys") ? this.sysPassword : this.getPassword());
        log.debug("Creating database connection");
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

    @Override
    public SELF withLogConsumer( Consumer<OutputFrame> logConsumer ){
        super.withLogConsumer(logConsumer);
        this.logConsumer = logConsumer;
        return self();
    }


}
