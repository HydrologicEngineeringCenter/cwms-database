# Docker Compose

The Compose file `docker-compose.yml` is a [YAML](https://yaml.org/) file defining services, networks and volumes for `cwms_database` application.  Included services are `database`, `schema`, `cwms-data` and `radar`.  Each of these services are listed in detail below.

### Docker Network and Volume

The Compose file defines the network and volume as external.  Therefore, these will need to be created before starting services.

Terminal:

- docker network create ***network-name-in-compose***
- docker volume create ***volume-name-in-compose***

### Docker Compose UP

Some defined services are dependent on others.  This does require a startup sequence with Compose and not starting everything at the same time.  The `database` service must be started first and ready before initializing the schema.  After the database is ready and the schema install has completed, `cwms-data` service can start.  The schema install and cwms-data services do not have to stay `alive` and will stop after their completion.  The `radar` service can start without dependencies but typically started last.


Terminal:

- docker compose up [--build] database
- docker compose up [--build] schema
- docker compose up [--build] cwms-data
- docker compose up [--build] radar

## Docker Compose Services
----
### Database

Oracle container using image `registry.hecdev.net/oracle/database:19.3.0-ee`.  Two of the three environment variables can be modified but are already set to support local development.  Changing variable values does require updating environement variables in the other services.

### Schema

CWMS Schema Installer is this repository building from context `./schema`.  Environment variables are set for local development.  Modifying any of these values will require updating other services environment variable values.

### CWMS Data

CWMS Data service is a container running Ubuntu and local Python package `cwmsdata` to initialize the CWMS database with locations (`usgs-sites`) and time series (`usgs-ts`).  Both `usgs-sites` and `usgs-ts` are command-line tools that take similar arguments to filter sites by [HUC](http://water.usgs.gov/GIS/huc_name.html), list of locations ([NWIS Mapper](http://maps.waterdata.usgs.gov/mapper/)) and/or [parameter codes](http://help.waterdata.usgs.gov/codes-and-parameters/parameters).

An entry point shell script (`entrypoint.sh`) can be used to execute `cwmsdata` command-line tools `usgs-sites` or `usgs-ts`.  The following is the usage for `entrypopint.sh`

    a) # Keep the container alive
    c) # Switches for commands
    s) # Run usgs-sites
    t) # Run usgs-ts
    h) # Print usage message

Example `CMD` entry for `entrypoint.sh` that loads sites and time series data in Hydrologic Unit Code (HUC) area `05130105` for parameters `00060` and `00065`.

```
CMD [ "-st", "-c", "--huc 05130105 --parameter_code 00060 00065" ]
```


### CWMS-Data-API

The Compose file references [USACE/cwms-data-api](https://github.com/USACE/cwms-data-api) locally with a relative path.  Modify the `radar:build:context` path according to local setup.

----