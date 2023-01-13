"""
Initialize CWMS locations
"""

from cwmsdata import pool

def store_location2(**kwargs):
    with pool.acquire() as connection:
        with connection.cursor() as crsr:
            crsr.callproc(
                "cwms_loc.store_location2",
                keywordParameters=kwargs,
            )
            return True

# def delete_location_cascade(**kwargs):
#     with pool.acquire() as connection:
#         with connection.cursor() as crsr:
#             crsr.callproc(
#                 "cwms_loc.delete_location_cascade",
#                 keywordParameters=kwargs,
#             )









            
# def locations_by_huc(huc="05130202"):
#     """
#     parse usgs rdb file returning each  line as an object

#     Yields
#     ------
#     dictionary object
#         USGS rdb file selection fields and values in key=value pairs
#     """
#     url = f"https://waterservices.usgs.gov/nwis/site/?format=rdb&huc={huc}&parameterCd=00060,00065&siteStatus=all"

#     resp = requests.get(url=url)

#     rdb_file = [line for line in resp.text.split("\n") if not line.startswith("#")]

#     # line one is the parameter names
#     parameter_names = rdb_file[0].rstrip().split("\t")

#     reader = csv.DictReader(
#         rdb_file[2:],
#         fieldnames=parameter_names,
#         delimiter="\t",
#     )

#     for r in reader:
#         yield r


# def store_location2(**kwargs):
#     with pool.acquire() as connection:
#         with connection.cursor() as crsr:
#             office = crsr.callfunc("cwms_util.user_office_id", cx_Oracle.LONG_STRING)
#             for l in locations_by_huc():
#                 crsr.callproc(
#                     "cwms_loc.store_location2",
#                     keywordParameters={
#                         "p_location_id": l["site_no"],
#                         "p_location_type": "SITE",
#                         "p_elevation": None
#                         if l["alt_va"].strip() == ""
#                         else float(l["alt_va"].strip()),
#                         "p_elev_unit_id": "ft",
#                         "p_vertical_datum": l["alt_datum_cd"],
#                         "p_latitude": float(l["dec_lat_va"]),
#                         "p_longitude": float(l["dec_long_va"]),
#                         "p_horizontal_datum": l["dec_coord_datum_cd"],
#                         "p_public_name": l["station_nm"],
#                         "p_long_name": l["station_nm"],
#                         "p_description": l["station_nm"],
#                         "p_time_zone_id": "US/Central",
#                         "p_county_name": None,
#                         "p_state_initial": "TN",
#                         "p_active": "T",
#                         "p_location_kind_id": "SITE",
#                         "p_map_label": "Map: Test",
#                         "p_published_latitude": float(l["dec_lat_va"]),
#                         "p_published_longitude": float(l["dec_long_va"]),
#                         "p_bounding_office_id": None,
#                         "p_nation_id": "UNITED STATES",
#                         "p_nearest_city": "Nashville",
#                         "p_ignorenulls": "T",
#                         "p_db_office_id": office,
#                     },
#                 )
