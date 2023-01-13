#!/usr/bin/env python3
"""
Command-line tool to load usgs site data
"""

import argparse
import sqlite3
import sys
from datetime import datetime, timedelta
from textwrap import dedent

import pkg_resources
import requests

from cwmsdata.cwms_log.cwms_logger import logger
from cwmsdata.model.cwms import cwms_ts, cwms_util
from cwmsdata.model.usgs import output_format, services, usgs_services_url


def cx_cwms(stmt):
    """
    Connect to package sqlite database and execute provided sql statement

    Parameters
    ----------
    stmt : str
        sql statement

    Returns
    -------
    list
        rows from fetchall()
    """
    sqldb = pkg_resources.resource_filename("cwmsdata.data", "cx_cwms.db")
    with sqlite3.connect(str(sqldb)) as conn:
        cur = conn.cursor()
        res = cur.execute(dedent(stmt))
        rows = res.fetchall()

        return rows

def data_interval(data_list):
    """
    Determine the minimum interval from a list of times

    Parameters
    ----------
    data_list : list[dict]
        list of objects with attribute 'dateTime'

    Returns
    -------
    datetime.timedelta
        minimum interval within the data
    """
    min_interval = timedelta(hours=87600)
    for i in range(1, len(data_list)):
        dt1 = datetime.fromisoformat(data_list[i - 1]["dateTime"])
        dt2 = datetime.fromisoformat(data_list[i]["dateTime"])

        td = dt2 - dt1
        if dt2 < dt1:
            td = dt1 - dt2

        min_interval = td if td < min_interval else min_interval

        return min_interval


def usgs_sites_ts():
    """
    Command-line method
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("--format", action="store", choices=output_format.keys(), default="json")
    parser.add_argument("--huc", action="extend", nargs="+", type=str)
    parser.add_argument("--location", action="extend", nargs="+", type=str)
    parser.add_argument("--parameter_code", nargs="+", action="extend")
    parser.add_argument("--service", action="store", type=str, choices=services.keys(), default="instantaneous")
    parser.add_argument("--period", action="store", type=str, default="P1D")

    args = parser.parse_args()

    query = {}
    if args.huc:
        query["huc"] = ",".join(args.huc)
    if args.location:
        query["sites"] = ",".join(args.location)
    if args.parameter_code:
        query["parameterCd"] =  ",".join(args.parameter_code)
    if args.format:
        query["format"] = args.format
    if args.period:
        query["period"] = args.period

    logger.debug(f"{query=}")
    
    url = usgs_services_url(service=args.service, query=query)
    logger.debug(url)


    resp = requests.get(url=url)
    if resp.status_code != 200:
        logger.critical(f"Response status code {resp.status_code} {resp.reason}")
        sys.exit(1)

    office = cwms_util.user_office_id()
    resp_json = resp.json()

    for ts in resp_json["value"]["timeSeries"]:
        # Source Info
        base_location = ts["sourceInfo"]["siteCode"][0]["value"]
        network = ts["sourceInfo"]["siteCode"][0]["network"]
        # Variable
        varible_code = ts["variable"]["variableCode"][0]["value"]
        nodata_value = ts["variable"]["noDataValue"]
        # Values
        values = ts["values"][0]["value"]


        if len(values) > 0:
            interval_td = data_interval(values)
            try:
                interval = cx_cwms(dedent(
                    f"""
                        SELECT interval_id
                        FROM cwms_interval AS ci
                        WHERE ci.interval_sec = {interval_td.seconds}
                    """))[0][0]


                parameter, ptype, unit = cx_cwms(dedent(
                    f"""
                        SELECT cwms_parameter, cwms_type, cwms_unit
                        FROM cwms as c
                        WHERE c.usgs_code_id = (SELECT id FROM usgs_code AS uc WHERE uc.code = '{varible_code}')
                    """))[0]

                duration = 0
                if ptype != "Inst":
                    duration = interval


                tsid = f"{base_location}.{parameter}.{ptype}.{interval}.{duration}.{network}"
                
                _values = [float(v.get("value")) for v in values]
                _times = [
                    int(datetime.fromisoformat(v.get("dateTime")).timestamp() * 1000)
                    for v in values
                ]
                _qualities = [0] * len(_values)

                if cwms_ts.store_ts(
                    p_cwms_ts_id=tsid,
                    p_units=unit,
                    p_times=_times,
                    p_values=_values,
                    p_qualities=_qualities,
                    p_office_id=office,
                    ):
                    logger.info(f"Stored TS: {tsid}")
                else:
                    logger.warning(f"Did not store TS: {tsid}")

            except IndexError as err:
                logger.warning(err)
                continue
