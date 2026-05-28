# Purpose of `src/xml` Directory

The files in this directory are used in `ant xml-schemas` and also `ant bundle` to generate XML schema definitions and associated diagrams.

The `hec-datatypes-template.xsd` and `hec-datatypes_xml_schema.ctl` files are used to generate the `hec-datatypes.xsd` file, which is referenced by the other .xsd files. The `make_diagram.py` jython script uses `makefile`, `xsdvi.jar` and `xercesImpl.jar` to create SVG diagrams of the .xsd files.

These files are in the database build repository due to dependence on the database structure. The .xsd and .svg files should be moved to a location accessible as https://www.hec.usace.army.mil/xmlSchema/CWMS/