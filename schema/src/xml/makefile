$(zipfile) : index.html \
	dataexchangeconfiguration.xsd \
	dataexchangeconfiguration.svg \
	dataexchangeconfiguration_v2.xsd \
	dataexchangeconfiguration_v2.svg \
	hec-datatypes.xsd \
	hec-datatypes.svg \
	location-levels.xsd \
	location-levels.svg \
	Ratings.xsd \
	Ratings.svg
	zip $@ $?

%.svg : %.xsd
	python2 make_diagram.py $<

clean :
	rm -fv $(zipfile) *.svg hec-datatypes.xsd *.log *.out

