$(zipfile) : index.html \
	dataexchangeconfiguration.xsd \
	dataexchangeconfiguration.svg \
	hec-datatypes.xsd \
	hec-datatypes.svg \
	location-levels.xsd \
	location-levels.svg \
	Ratings.xsd \
	Ratings.svg
	zip $@ $?

%.svg : %.xsd
	python make_diagram.py $<

clean :
	rm $(zipfile) *.svg hec-datatypes.xsd *.log *.out

