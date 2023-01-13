"""

"""

from datetime import datetime
import json
import os
from pathlib import Path
import cx_Oracle

cur_file = Path(__file__)
cur_path = cur_file.parent

usgs_locations_output = cur_path / "usgs_locations.json"



store_ts_sql = """
begin     
    cwms_ts.store_ts(
       p_cwms_ts_id    => :tsid,
       p_units         => :units,
       p_times         => :times,
       p_values        => :vals,
       p_qualities     => :quals,
       p_store_rule    => cwms_util.replace_all,
       p_override_prot => 'F',
       p_version_date  => cwms_util.non_versioned,
       p_office_id     => :office);
end;"""

# read the json file with the data
with usgs_locations_output.open("r") as fp:
    data = json.loads(fp.read())


with cx_Oracle.Connection(
    user=os.environ.get("CWMS_USER"),
    password=os.environ.get("CWMS_PASSWORD"),
    dsn=os.environ.get("DB_HOST_PORT") + os.environ.get("DB_NAME"),
) as connection:
    crsr = connection.cursor()
    office = crsr.callfunc("cwms_util.user_office_id", cx_Oracle.STRING)

    for dataset in data:
        location = dataset["base_location"]
        parameter = dataset["parameter"]
        ptype = dataset["parameter_type"]
        interval = dataset["interval"]
        duration = dataset["duration"]
        version = dataset["version"]
        tsid = f"{location}.{parameter}.{ptype}.{interval}.{duration}.{version}"

        _values = [float(v["value"]) for v in dataset["values"]]
        _times = [
            int(datetime.fromisoformat(dt["dateTime"]).timestamp() * 1000)
            for dt in dataset["values"]
        ]

        args = [
            tsid,
            dataset["unit"],
            crsr.arrayvar(cx_Oracle.NUMBER, _times),
            crsr.arrayvar(cx_Oracle.NATIVE_FLOAT, _values),
            crsr.arrayvar(cx_Oracle.NUMBER, [0] * len(_values)),
            office,
        ]

        try:
            crsr.execute(store_ts_sql, args)
        except cx_Oracle.DatabaseError as err:
            print(err)
            continue
        