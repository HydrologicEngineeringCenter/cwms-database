/*
 * Copyright (c) 2021
 * United States Army Corps of Engineers - Hydrologic Engineering Center (USACE/HEC)
 * All Rights Reserved.  USACE PROPRIETARY/CONFIDENTIAL.
 * Source may not be released without written approval from HEC
 */

package usace.cwms.db.jooq.generator;

/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */


import java.util.logging.Level;
import java.util.logging.Logger;

import org.jooq.codegen.DefaultGeneratorStrategy;
import org.jooq.meta.Definition;
import org.jooq.meta.oracle.OraclePackageDefinition;

/**
 * @author psmorris
 */
public class CwmsDefaultGeneratorStrategy extends DefaultGeneratorStrategy
{
	private static final Logger LOGGER = Logger.getLogger(CwmsDefaultGeneratorStrategy.class.getName());

	@Override
	public String getJavaIdentifier(Definition definition)
	{
		return definition.getOutputName();
	}

	@Override
	public String getJavaSetterName(Definition definition, Mode mode)
	{
		return "set" + definition.getOutputName();
	}

	@Override
	public String getJavaGetterName(Definition definition, Mode mode)
	{
		return "get" + definition.getOutputName();
	}

	@Override
	public String getJavaMethodName(Definition definition, Mode mode)
	{
		return "call_" + definition.getOutputName();
	}

	@Override
	public String getJavaClassName(Definition definition, Mode mode)
	{
		String retval = definition.getOutputName();
		if(definition instanceof OraclePackageDefinition)
		{
			retval = definition.getOutputName() + "_PACKAGE";
		}
		else if(mode == Mode.POJO)
		{
			retval = definition.getOutputName() + "_POJO";
		}
		else if(mode == Mode.INTERFACE)
		{
			retval = definition.getOutputName() + "_INTERFACE";
		}
		else if(mode == Mode.DAO)
		{
			retval = definition.getOutputName() + "_DAO";
		}
		return retval;
	}

	@Override
	public String getJavaMemberName(Definition definition, Mode mode)
	{
		return definition.getOutputName();
	}


	/**
	 * Override this method to define the suffix to apply to routines when they are overloaded.
	 * <p>
	 * Use this to resolve compile-time conflicts in generated source code, in case you make heavy use of procedure
	 * overloading
	 *
	 * @param definition
	 * @param mode
	 * @param overloadIndex
	 * @return
	 */
	@Override
	public String getOverloadSuffix(Definition definition, Mode mode, String overloadIndex)
	{
		String overloadSuffix = "";
		if(overloadIndex != null)
		{
			try
			{
				int integer = Integer.parseInt(overloadIndex);
				if(integer > 1)
				{
					overloadSuffix = "__" + integer;
				}
			}
			catch(NumberFormatException ex)
			{
				LOGGER.log(Level.SEVERE, ex, () -> "Unable to parse overloadIndex: " + overloadIndex);
			}
		}
		return overloadSuffix;
	}
}
