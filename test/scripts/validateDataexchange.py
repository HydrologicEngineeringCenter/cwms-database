import os, re, sys
import java, javax, org

errorCount        = 0
warningCount      = 0
totalErrorCount   = 0
totalWarningCount = 0
instanceCount     = 0

iso_time_pattern = re.compile("-?\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2}([.]\d+)?)?([-+]\d{2}:\d{2}|Z)?")

#-------------------------------------------------------------------------------------------#
# this XPath operation strips all '.' and '/' characters and white space from the node text #
#-------------------------------------------------------------------------------------------#
_strip = "normalize-space(translate(text(), '/. ', ''))" 
#---------------------------------------------------------------------------------------------#
# this XPath operation selects all ts-mapping nodes that have "stripped" text ending with "%" #
#---------------------------------------------------------------------------------------------#
_filter = "ts-mapping-set/ts-mapping/*[contains(substring(%s, string-length(%s)), '%%')]/.." % (_strip, _strip)
print 'Forecast mapping filter = "%s"' % _filter

class errorHandler(org.xml.sax.ErrorHandler) :

	def warning(self, e) :
		global warningCount
		if errorCount == 0 and warningCount == 0 :
			print
		warningCount += 1
		print "\tWARNING : %s" % e.getMessage()

	def error(self, e) :
		global errorCount
		errorCount += 1
		print "\tERROR : %s" % e.getMessage()

	def fatalError(self, e) :
		print "\tFATAL ERROR : %s" % e.getMessage()
		raise e

def usage() :

	progName = os.path.basename(sys.argv[0])
	
	print """
	Program %s : performs schema validation of XML instances.

	Usage : %s xmlspec [xmlspec [...]]

	Where : xmlspec is a file name (or mask) or URL.
	"""  % (progName, progName)

def validateXML(xmlSpec) :
	
	global errorCount, warningCount, totalErrorCount, totalWarningCount, instanceCount
	
	errorCount   = 0
	warningCount = 0
	if os.path.isfile(xmlSpec) :
		print "\nValidating file %s" % xmlSpec
		xmlSpec = "file:///%s" % os.path.abspath(xmlSpec).replace("\\", "/")
	else :
		print "\nValidating URL %s" % xmlSpec
		
	instanceSource = javax.xml.transform.stream.StreamSource(xmlSpec)

	instanceCount += 1

	#---------------------------------#
	# Grammar-based schema validation #
	#---------------------------------#
	print "Validating grammar."
	schemaFactory = javax.xml.validation.SchemaFactory.newInstance(javax.xml.XMLConstants.W3C_XML_SCHEMA_NS_URI)
	schema = schemaFactory.newSchema()
	errorHandlerInst = errorHandler()
	validator = schema.newValidator()
	validator.setErrorHandler(errorHandlerInst)
	try    : validator.validate(instanceSource)
	except : pass

	#-----------------------#
	# Rule-based validation #
	#-----------------------#
	print "Validating rules."
	NODE    = javax.xml.xpath.XPathConstants.NODE
	NODESET = javax.xml.xpath.XPathConstants.NODESET
	STRING  = javax.xml.xpath.XPathConstants.STRING
	NUMBER  = javax.xml.xpath.XPathConstants.NUMBER
	BOOLEAN = javax.xml.xpath.XPathConstants.BOOLEAN

	inputSource = org.xml.sax.InputSource(xmlSpec)
	xpath = javax.xml.xpath.XPathFactory.newInstance().newXPath()


	datastore_types = {}
	realtime_to_oracle = []
	realtime_to_dss = []

	realtime_imports = {}
	realtime_exports = {}
	
	is_cwms = xpath.evaluate("starts-with(local-name(/*[1]), 'cwms-')", inputSource, BOOLEAN)
	
	#-----------------------------------#
	# collect the datastore types by id #
	#-----------------------------------#
	datastores = xpath.evaluate("/*/datastore", inputSource, NODESET)
	for i in range(datastores.getLength()) :
		ds = datastores.item(i)
		ds_type = xpath.evaluate("local-name(*[1])", ds, STRING)
		ds_name = xpath.evaluate("*[1]/@id", ds, STRING)
		datastore_types[ds_name] = ds_type
		
	#----------------------------#
	# for each data exchange set #
	#----------------------------#
	xchg_sets = xpath.evaluate("/*/dataexchange-set", inputSource, NODESET)
	for i in range(xchg_sets.getLength()) :
		xchg_set = xchg_sets.item(i)
		xchg_set_id = xpath.evaluate("@id", xchg_set, STRING)
		realtime_sourceid = xpath.evaluate("@realtime-source-id", xchg_set, STRING)

		mapping_count = xpath.evaluate("count(ts-mapping-set/*)", xchg_set, NUMBER)
		print "\t%s (%d mappings)" % (xchg_set_id, mapping_count)
		
		if is_cwms :
			#-------------------------------------------------------------------------------#
			# verify that there is one DSS and one Oracle data store for CWMS exchange sets #
			#-------------------------------------------------------------------------------#
			set_datastore_types = []
			for j in (1,2) :
				datastore = xpath.evaluate("datastore-ref[%d]/@id" % j, xchg_set, STRING)
				set_datastore_types.append(datastore_types[datastore])

			if not ("dssfilemanager" in set_datastore_types and "oracle" in set_datastore_types) :
				errorHandlerInst.error(org.xml.sax.SAXParseException(
					'dataexchange-set "%s" must use one oracle datastore and one dssfilemanager datastore.' % \
					xchg_set_id, None))

		#---------------------------------------------------------------------#					
		# verify that forecast mappings have matching parameterized versions  #
		# and parameterized forecast time windows                             #
		#                                                                     #
		# the XPath gets a little hairy (c'mon XPath 2.0!), but operates much #
		# faster than iterating through every node in the script code...      #
		#---------------------------------------------------------------------#
		mappings = xpath.evaluate(_filter, xchg_set, NODESET)
		for j in range(mappings.getLength()) :
			mapping = mappings.item(j)
			if xpath.evaluate("name(*[1])", mapping, STRING) == 'dss-timeseries' :
				version1 = xpath.evaluate("*[1]", mapping, STRING).strip().split("/")[6].strip()
			else :
				version1 = xpath.evaluate("*[1]", mapping, STRING).strip().split(".")[5].strip()
			if xpath.evaluate("name(*[2])", mapping, STRING) == 'dss-timeseries' :
				version2 = xpath.evaluate("*[2]", mapping, STRING).strip().split("/")[6].strip()
			else :
				version2 = xpath.evaluate("*[2]", mapping, STRING).strip().split(".")[5].strip()
			if version1 == "%" * len(version1) or version2 == "%" * len(version2) :
				if version1 != version2 :
					errorHandlerInst.error(org.xml.sax.SAXParseException(
						'dataexchange-set "%s" has forecast mapping with mis-mathced version place-holders' % \
						xchg_set_id, None))
						
			tw_node = xpath.evaluate("../../timewindow", mapping, NODE)
			if not tw_node :
				errorHandlerInst.error(org.xml.sax.SAXParseException(
					'dataexchange-set "%s" has forecast mapping without a forecast time window.' % \
					xchg_set_id, None))
			starttime = xpath.evaluate("normalize-space(starttime)", tw_node, STRING)
			endtime = xpath.evaluate("normalize-space(endtime)", tw_node, STRING)
			if iso_time_pattern.match(starttime) :
				errorHandlerInst.error(org.xml.sax.SAXParseException(
					'dataexchange-set "%s" has forecast time window with explicit start time.' % \
					xchg_set_id, None))
			if iso_time_pattern.match(endtime) :
				errorHandlerInst.error(org.xml.sax.SAXParseException(
					'dataexchange-set "%s" has forecast time window with explicit end time.' % \
					xchg_set_id, None))
			
				
		#-------------------------------------------------------------------------------------------#
		# verify that no time series is used for realtime import and export from the same datastore #
		#-------------------------------------------------------------------------------------------#
		if realtime_sourceid :
			export_ds = realtime_sourceid
			datastore = xpath.evaluate("datastore-ref[1]/@id", xchg_set, STRING)
			if datastore == export_ds :
				import_ds = xpath.evaluate("datastore-ref[2]/@id", xchg_set, STRING)
			else :
				import_ds = datastore
			if not realtime_exports.has_key(export_ds) : realtime_exports[export_ds] = []
			if not realtime_imports.has_key(import_ds) : realtime_imports[import_ds] = []
			export_tsids = xpath.evaluate("ts-mapping-set/ts-mapping/*[@datastore-id='%s']" % export_ds, xchg_set, NODESET)
			for j in range(export_tsids.getLength()) :
				tsid = xpath.evaluate(".", export_tsids.item(j), STRING).strip()
				if tsid not in realtime_exports[export_ds] : realtime_exports[export_ds].append(tsid)
				if realtime_imports.has_key(export_ds) and tsid in realtime_imports[export_ds] :
					msg = 'Time series "%s" is specified as real time import and export for %s datastore "%s"' % \
						(tsid, datastore_types[export_ds], export_ds)
					errorHandlerInst.error(org.xml.sax.SAXParseException(msg, None))
			import_tsids = xpath.evaluate("ts-mapping-set/ts-mapping/*[@datastore-id='%s']" % import_ds, xchg_set, NODESET)
			for j in range(import_tsids.getLength()) :
				tsid = xpath.evaluate(".", import_tsids.item(j), STRING).strip()
				if tsid not in realtime_imports[import_ds] : realtime_imports[import_ds].append(tsid)
				if realtime_exports.has_key(import_ds) and tsid in realtime_exports[import_ds] :
					msg = 'Time series "%s" is specified as real time import and export for %s datastore "%s"' % \
						(tsid, datastore_types[import_ds], import_ds)
					errorHandlerInst.error(org.xml.sax.SAXParseException(msg, None))

	print "\n\t%d error(s), %d warning(s)" % (errorCount, warningCount)
	totalErrorCount   += errorCount
	totalWarningCount += warningCount

if len(sys.argv) == 1 or "-help".startswith(sys.argv[1].lower()) : 
	usage()
	sys.exit(-1)

for arg in sys.argv[1:] : validateXML(arg)

print "\n%d instance(s), %d error(s), %d warning(s)\n" % (instanceCount, totalErrorCount, totalWarningCount)

sys.exit(totalErrorCount + totalWarningCount)
	
