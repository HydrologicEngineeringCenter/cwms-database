import glob, os, re, subprocess, sys

def make_diagram(filename) :
	with open(filename, "r") as f : content = f.read()
	m = re.search(r'targetNamespace\s*=\s*"(.+?)"', content)
        if m and m.group(1) :
            schema_name = m.group(1).split("/")[-1].strip()
        else :
            schema_name = os.path.splitext(os.path.split(filename)[1])[0]
        print("Schema name is %s" % schema_name)
	cmd = "java -jar xsdvi.jar %s >%s.out 2>&1" % (filename, filename)
	print(cmd)
	rc = subprocess.call(cmd, shell=True)
	with open("xsdvi.log", "r") as f : logdata = f.read()
	with open("%s.log" % filename, "w") as f : f.write(logdata)
	os.unlink("xsdvi.log")
	svgfile = filename.replace(".xsd", ".svg")
	with open(svgfile, "r") as f : content = f.read()
	with open(svgfile, "w") as f : f.write(content.replace("<title>XsdVi</title>", "<title>%s xml schema</title>" % schema_name))


if len(sys.argv) == 1 :
	print("\n%s xml_schema_filename(s)\n" % sys.argv[0])

for pathnames in sys.argv[1:] :
	for pathname in glob.glob(pathnames) :
		filename = os.path.split(pathname)[1]
		if os.path.splitext(filename)[1] != ".xsd" :
			print("Skipping file %s - not a schema file" % pathname)
			continue
		if filename == "hec-datatypes.xsd" :
			#---------------------------------#
			# un-comment elements for diagram #
			#---------------------------------#
			with open(pathname, "r") as f : old_content = f.read()
			new_content = re.sub(r"<!-- (xs:element .+?) -->", r"<\1/>", old_content)
			# print(new_content)
			with open(pathname, "w") as f : f.write(new_content)
		make_diagram(pathname)
		if filename == "hec-datatypes.xsd" :
			#-------------------------------------------------------------------#
			# restore element comments to keep other diagrams from showing them #
			#-------------------------------------------------------------------#
			with open(pathname, "w") as f : f.write(old_content)

