"""

"""

import json
import sqlite3
from datetime import datetime, timedelta
from pathlib import Path
from textwrap import dedent

import requests

cur_file = Path(__file__)
cur_path = cur_file.parent

# cx_cwms/src/data/cx_cwms.db
sqldb = cur_path / "cx_cwms.db"
usgs_locations_output = cur_path / "usgs_locations.json"


def usgs_cwms_codes(usgs_parameter, sqldb):
    stmt = f"""
        SELECT cwms_parameter, cwms_type, cwms_unit
        FROM cwms as c
        WHERE c.usgs_code_id = (SELECT id FROM usgs_code AS uc WHERE uc.code = '{usgs_parameter}')
    """
    with sqlite3.connect(sqldb) as conn:
        cur = conn.cursor()
        res = cur.execute(dedent(stmt))
        rows = res.fetchall()

    return rows


def data_interval(data_list):
    min_interval = timedelta(hours=87600)
    for i in range(1, len(data_list)):
        dt1 = datetime.fromisoformat(data_list[i - 1]["dateTime"])
        dt2 = datetime.fromisoformat(data_list[i]["dateTime"])

        td = dt2 - dt1
        if dt2 < dt1:
            td = dt1 - dt2

        min_interval = td if td < min_interval else min_interval

        return min_interval

def main():
    url = "https://waterservices.usgs.gov/nwis/iv/?format=json&sites=03431300,03431500,03431599&period=P6D&parameterCd=00060,00065&siteStatus=all"

    resp = requests.get(url=url)

    resp_json = resp.json()

    return_list = []
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
            with sqlite3.connect(sqldb) as conn:
                crsr = conn.cursor()
                crsr.execute(
                    """
                    SELECT interval_id
                    FROM cwms_interval AS ci
                    WHERE ci.interval_sec = :interval
                    """,
                    {"interval": interval_td.seconds},
                )
                interval = crsr.fetchone()[0]

            parameter, ptype, unit = usgs_cwms_codes(varible_code, sqldb)[0]

            duration = 0
            if ptype != "Inst":
                duration = interval

            return_list.append(
                {
                    "base_location": base_location,
                    "parameter": parameter,
                    "parameter_type": ptype,
                    "interval": interval,
                    "duration": duration,
                    "version": network,
                    "unit": unit,
                    "variable_code": varible_code,
                    "nodata_value": nodata_value,
                    "values": values,
                }
            )

    with usgs_locations_output.open("w", encoding="utf-8") as fp:
        fp.writelines(json.dumps(return_list, indent=4))


if __name__ == "__main__":
    main()
