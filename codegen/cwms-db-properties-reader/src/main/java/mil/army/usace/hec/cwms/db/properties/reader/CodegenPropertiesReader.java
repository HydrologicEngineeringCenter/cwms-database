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
package mil.army.usace.hec.cwms.db.properties.reader;

import java.io.FileInputStream;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathFactory;

import org.apache.maven.plugin.AbstractMojo;
import org.apache.maven.plugin.MojoExecutionException;
import org.apache.maven.plugins.annotations.Mojo;
import org.apache.maven.plugins.annotations.Parameter;
import org.apache.maven.project.MavenProject;
import org.w3c.dom.Document;

/**
 * @author adam
 */
@Mojo(name = "codegen-properties-reader")
public class CodegenPropertiesReader extends AbstractMojo
{
	private static final Logger LOGGER = Logger.getLogger(CodegenPropertiesReader.class.getName());

	@Parameter(property = "builduser.overrides", required = true)
	private String _buildUserOverrides;
	@Parameter(defaultValue = "${project}", required = true)
	private MavenProject _project;

	private String _officeCode;
	private String _testUserPassword;
	private String _codegenUrl;

	@Override
	public void execute() throws MojoExecutionException
	{
		readBuildUserOverrides();
		writeProperties();
	}

	private void readBuildUserOverrides() throws MojoExecutionException
	{
		LOGGER.log(Level.CONFIG, () -> "Reading properties from file: " + _buildUserOverrides);
		try(FileInputStream fileIS = new FileInputStream(_buildUserOverrides))
		{
			DocumentBuilderFactory builderFactory = DocumentBuilderFactory.newInstance();
			DocumentBuilder builder = builderFactory.newDocumentBuilder();
			Document xmlDocument = builder.parse(fileIS);
			XPath xPath = XPathFactory.newInstance().newXPath();
			String instantXpath = "/*/property[@name='oracle.cwms.instance']/@value";
			String instance = (String) xPath.compile(instantXpath).evaluate(xmlDocument, XPathConstants.STRING);
			_codegenUrl = "jdbc:oracle:thin:@" + instance;

			String parametersXpath = "/*/property[@name='oracle.connection.parameters']/@value";
			String parameters = (String) xPath.compile(parametersXpath).evaluate(xmlDocument, XPathConstants.STRING);
			if( parameters != null && !parameters.isEmpty()){
				_codegenUrl = _codegenUrl + "?" + parameters;
			}
			String testUserPasswordXpath = "/*/property[@name='oracle.hectest.password']/@value";
			_testUserPassword = (String) xPath.compile(testUserPasswordXpath).evaluate(xmlDocument, XPathConstants.STRING);
			String officeCodeXPath = "/*/property[@name='office.primary.code']/@value";
			_officeCode = (String) xPath.compile(officeCodeXPath).evaluate(xmlDocument, XPathConstants.STRING);
		}
		catch(Exception e)
		{
			throw new MojoExecutionException("Unable to read values from: " + _buildUserOverrides, e);
		}

	}

	private void writeProperties()
	{
		writeOfficeCode();
		writeCodegenUrl();
		writeTestUserPassword();
	}

	private void writeCodegenUrl()
	{
		String propertyKey = "oracle.codegen.url";
		String propertyString = _codegenUrl;
		LOGGER.log(Level.CONFIG, () -> "Writing codegen url to property: " + propertyKey + " as " + propertyString);
		writeProperty(propertyKey, propertyString);
	}

	private void writeOfficeCode()
	{
		String propertyKey = "office.primary.code";
		String propertyString = _officeCode;
		LOGGER.log(Level.CONFIG, () -> "Writing codegen office code to property: " + propertyKey + " as " + propertyString);
		writeProperty(propertyKey, propertyString);
	}

	private void writeTestUserPassword()
	{
		String propertyKey = "oracle.hectest.password";
		String propertyString = _testUserPassword;
		LOGGER.log(Level.CONFIG, () -> "Writing codegen password to property: " + propertyKey);
		writeProperty(propertyKey, propertyString);
	}

	private void writeProperty(String propertyKey, String propertyString)
	{
		_project.getProperties().setProperty(propertyKey, propertyString);
	}

}
