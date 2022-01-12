/*
 * Copyright (c) 2018
 * United States Army Corps of Engineers - Hydrologic Engineering Center (USACE/HEC)
 * All Rights Reserved.  USACE PROPRIETARY/CONFIDENTIAL.
 * Source may not be released without written approval from HEC
 */

/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package usace.cwms.db.version.generator;

import java.sql.Connection;
import java.sql.Date;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.time.LocalDate;
import java.util.logging.Logger;

import org.apache.maven.plugin.AbstractMojo;
import org.apache.maven.plugins.annotations.Mojo;
import org.apache.maven.plugins.annotations.Parameter;
import org.apache.maven.project.MavenProject;
import org.jooq.Field;
import org.jooq.Record;
import org.jooq.Record5;
import org.jooq.Result;
import org.jooq.Table;
import org.jooq.util.oracle.OracleDSL;

/**
 *
 * @author adam
 */
@Mojo(name ="schemaPropertyGenerator")
public class CwmsDbPropertiesGenerator extends AbstractMojo
{
	private static final Logger LOGGER = Logger.getLogger(CwmsDbPropertiesGenerator.class.getName());
	private final DateFormat _dateFormatter = new SimpleDateFormat("yyyy-MM-dd");
	@Parameter(property = "schemaPropertyGenerator.jdbc")
    CwmsConnection jdbc;

	@Parameter(defaultValue="${project}", required=true)
    protected MavenProject project;
    private String _dbApplication;
    private String _dbApplyDate;
    private String _dbVerDate;
    private String _dbVersion;
    
    @Override
    public void execute()
    {
        
        try (Connection conn = jdbc.buildConnection())
        {
            retrieveDbVersionInfo(conn);
            writeDbVersionInfo();
        }
        catch (SQLException ex)
        {
            getLog().error("Unable to retrieve CWMS Schema");
            getLog().error(ex);
        } 
    }
    
    private void retrieveDbVersionInfo(Connection conn)
	{
        Field<String> application = OracleDSL.field("APPLICATION", org.jooq.impl.SQLDataType.VARCHAR.length(32).nullable(false));
        Field<String> version = OracleDSL.field("VERSION", org.jooq.impl.SQLDataType.VARCHAR.length(122));
        Field<Timestamp> versionDate = OracleDSL.field("VERSION_DATE", org.jooq.impl.SQLDataType.TIMESTAMP);
        Field<Timestamp> applyDate = OracleDSL.field("APPLY_DATE", org.jooq.impl.SQLDataType.TIMESTAMP);
        Field<String> description = OracleDSL.field("DESCRIPTION",  org.jooq.impl.SQLDataType.CLOB);
        final Table<Record> avDbChangeLog = OracleDSL.table("CWMS_20.AV_DB_CHANGE_LOG");
        Result<Record5<String, String, Timestamp, Timestamp, String>> fetch = OracleDSL.using(conn)
                .select(application,
                        version,
                        versionDate,
                        applyDate,
                        description)
                .from(avDbChangeLog)
                .fetch()
                .sortDesc(versionDate);
        
        Record record = fetch.get(0);
        _dbApplication = record.get(application);
        _dbVersion = record.get(version);
        Timestamp versionDateTimstamp = record.get(versionDate);
        _dbVerDate = _dateFormatter.format(versionDateTimstamp);
        Timestamp applyDateTimestamp = record.get(applyDate);
        _dbApplyDate = _dateFormatter.format(applyDateTimestamp);
    }

    private void writeDbVersionInfo()
    {
        writeDbApplication();
        writeDbVersion();
        writeDbVersionDate();
        writeDbApplyDate();
        writeGenerationDate();
    }
    
    private void writeDbVersion()
    {
        String propertyKey = "cwms-database-version";
        String propertyString = _dbVersion;
        writeProperty(propertyKey, propertyString);
    }

    private void writeDbApplication()
    {
        String propertyKey = "cwms-database-version-application";
        String propertyString = _dbApplication;
        writeProperty(propertyKey, propertyString);
    }

    private void writeDbApplyDate()
    {
        String propertyKey = "cwms-database-version-applydate";
        String propertyString = _dbApplyDate;
        writeProperty(propertyKey, propertyString);
    }

    private void writeDbVersionDate()
    {
        String propertyKey = "cwms-database-version-date";
        String propertyString = _dbVerDate;
        writeProperty(propertyKey, propertyString);
    }

    private void writeProperty(String propertyKey, String propertyString) 
    {
        project.getProperties().setProperty(propertyKey, propertyString);
    }

    private void writeGenerationDate() 
    {
        String propertyKey = "code-generation-date";
        String propertyString = _dateFormatter.format(Date.valueOf(LocalDate.now()));
        writeProperty(propertyKey, propertyString);
    }

}
