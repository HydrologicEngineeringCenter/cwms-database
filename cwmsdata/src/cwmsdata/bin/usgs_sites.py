#!/usr/bin/env python3
"""
Store/Update USGS sites to the CWMS Oracle database
"""

import argparse
import csv
import sys

import requests

from cwmsdata.cwms_log.cwms_logger import logger
from cwmsdata.model.cwms import cwms_loc, cwms_util
from cwmsdata.model.usgs import output_format, services, usgs_services_url


def usgs_sites():
    """
    USGS sites method
    """
    max_log_level = 50
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-v",
        action="count",
        dest="level",
        help="-v (40), -vv (30), -vvv (20), or -vvv (10) (default: (50)",
    )
    parser.add_argument(
        "--format",
        action="store",
        choices=output_format.keys(),
        default="rdb",
    )
    parser.add_argument(
        "--huc",
        action="extend",
        nargs="+",
        type=str,
    )
    parser.add_argument(
        "--location",
        action="extend",
        nargs="+",
        type=str,
    )
    parser.add_argument(
        "--parameter_code",
        nargs="+",
        action="extend",
    )
    parser.add_argument(
        "--service",
        action="store",
        type=str,
        choices=services.keys(),
        default="site",
    )

    args = parser.parse_known_args()

    log_level = 0
    if 0 > args.level < max_log_level:
        log_level = max_log_level - args.level * 10
    elif args.level > max_log_level:
        log_level = 10

    logger.setLevel(log_level)

    query = {}
    if args.huc:
        query["huc"] = ",".join(args.huc)
    if args.location:
        query["sites"] = ",".join(args.location)
    if args.parameter_code:
        query["parameterCd"] = ",".join(args.parameter_code)
    if args.format:
        query["format"] = args.format

    logger.debug(f"{query=}")

    url = usgs_services_url(service=args.service, query=query)
    logger.debug(url)

    resp = requests.get(url=url)

    if stat_code := resp.status_code != 200:
        logger.critical(f"Response status code {stat_code}")
        sys.exit(1)

    rdb_file = [line for line in resp.text.split("\n") if not line.startswith("#")]

    # line one is the parameter names
    parameter_names = rdb_file[0].rstrip().split("\t")
    # parameter_lengths = rdb_file[1].rstrip().replace("s", "").split("\t")

    reader = csv.DictReader(
        rdb_file[2:],
        fieldnames=parameter_names,
        delimiter="\t",
    )

    office = cwms_util.user_office_id()

    for r in reader:
        site = r["site_no"]
        alt_va = None if r["alt_va"].strip() == "" else float(r["alt_va"].strip())
        dec_lat_va = 0 if r["dec_lat_va"] == "" else float(r["dec_lat_va"])
        dec_long_va = 0 if r["dec_long_va"] == "" else float(r["dec_long_va"])
        keywordParameters = {
            "p_location_id": site,
            "p_location_type": "SITE",
            "p_elevation": alt_va,
            "p_elev_unit_id": "ft",
            "p_vertical_datum": r["alt_datum_cd"],
            "p_latitude": dec_lat_va,
            "p_longitude": dec_long_va,
            "p_horizontal_datum": r["dec_coord_datum_cd"],
            "p_public_name": r["station_nm"],
            "p_long_name": r["station_nm"],
            "p_description": r["station_nm"],
            "p_time_zone_id": None,
            "p_county_name": None,
            "p_state_initial": None,
            "p_active": "T",
            "p_map_label": None,
            "p_published_latitude": dec_lat_va,
            "p_published_longitude": dec_long_va,
            "p_bounding_office_id": None,
            "p_nation_id": None,
            "p_nearest_city": None,
            "p_ignorenulls": "T",
            "p_db_office_id": office,
        }
        if cwms_loc.store_location2(**keywordParameters):
            logger.info(f"Site saved/updated: {site}")
        else:
            logger.warning(f"Site not saved/updated: {keywordParameters}")

    sys.exit(0)
