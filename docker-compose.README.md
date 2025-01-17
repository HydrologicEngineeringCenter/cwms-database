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

## Docker Compose Services
----
### Database

Oracle container using image `gvenzl/oracle-free:23.6-ull`.  Two of the three environment variables can be modified but are already set to support local development.  Changing variable values does require updating environment variables in the other services.

### Schema

CWMS Schema Installer is this repository building from context `./schema`.  Environment variables are set for local development.  Modifying any of these values will require updating other services environment variable values.


### CWMS-Data-API

For an example with Data-API see the project at [USACE/cwms-data-api](https://github.com/USACE/cwms-data-api)

----