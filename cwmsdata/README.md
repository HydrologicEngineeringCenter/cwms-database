# CWMS Data Acquisition

Python package to initiate data acquisition from the USGS Water Services.  Currently, command-line functions are available (usgs-sites and usgs-ts) to store sites and their timeseries.

# Dependencies

Access to Oracle in Python uses `cx_Oracle`, which requires Oracle Instant Client installed on the system.  See [Oracle Instant Client Downloads](https://www.oracle.com/database/technologies/instant-client/downloads.html)

Python dependencies are listed in the `setup.cfg` file.

# Installation

Local installation for this Python package can be done with `pip`.  Change directory to `cwmsdata` making sure to be at the same level as `setup.cfg`

execute at the terminal:

```
> pip install .
```

# Command-line Tools

## **usgs-sites**

argument | description | example | default
--- | --- | --- | ---
--format | Return format from the request | --format rdb | rdb
--huc | Space delimited list of Hydrologic Unit Code to filter locations | --huc 05130104 05130108 | None
--location | Space delimited list of locations | --location 03605078 03485500| None
--parameter_code | List of parameters codes | --parameter_code 00065 00060 | None
--service | USGS Water Service | --service site | site

----

## **usgs-ts**

argument | description | example | default
--- | --- | --- | ---
--format | Return format from the request | --format rdb | rdb
--huc | Space delimited list of Hydrologic Unit Code to filter locations | --huc 05130104 05130108 | None
--location | Space delimited list of locations | --location 03605078 03485500| None
--parameter_code | List of parameters codes | --parameter_code 00065 00060 | None
--service | USGS Water Service | --service site | site
--period | From now to period in the past | --period P1D | P1D

****The period argument uses only a positive [ISO-8601 format](http://en.wikipedia.org/wiki/ISO-8601#Durations) returning data from now to a time in the past.***
