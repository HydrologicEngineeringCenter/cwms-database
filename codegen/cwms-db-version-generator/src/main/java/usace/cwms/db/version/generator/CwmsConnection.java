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
import java.sql.DriverManager;
import java.sql.SQLException;

import oracle.jdbc.driver.OracleDriver;
import org.apache.maven.plugins.annotations.Mojo;
import org.apache.maven.plugins.annotations.Parameter;

/**
 *
 * @author adam
 */
@Mojo(name="cwmsconnection")
public class CwmsConnection 
{
    @Parameter
    private String driver;
    
    @Parameter
    private String url;
    @Parameter
    private String user;
    @Parameter
    private String password;
    
    public Connection buildConnection() throws SQLException, ClassNotFoundException, InstantiationException, IllegalAccessException
    {
        DriverManager.registerDriver(new OracleDriver());
        Class.forName(driver).newInstance();
        return DriverManager.getConnection(url, user, password);
    }
}
