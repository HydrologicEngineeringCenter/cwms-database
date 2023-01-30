"""
Initialize CWMS locations
"""

from cwmsdata import pool


def store_location2(**kwargs):
    """_summary_

    Parameters
    ----------
    p_location_id
        The location identifier

    p_location_type
        A user-defined type for the location

    p_elevation
        The elevation of the location

    p_elev_unit_id
        The elevation unit

    p_vertical_datum
        The datum of the elevation

    p_latitude
        The actual latitude of the location

    p_longitude
        The actual longitude of the location

    p_horizontal_datum
        The datum for the latitude and longitude

    p_public_name
        The public name for the location

    p_long_name
        The long name for the location

    p_description
        A description of the location

    p_time_zone_id
        The time zone name for the location

    p_county_name
        The name of the county that the location is in

    p_state_initial
        The two letter abbreviation of the state that the location is in

    p_active
        A flag ('T' or 'F') that specifies whether the location is marked as active

    p_location_kind_id
        THIS PARAMETER IS IGNORED. A site created with this procedure will have a location kind of SITE.

    p_map_label
        A label to be used on maps for location

    p_published_latitude
        The published latitude for the location

    p_published_longitude
        The published longitude for the location

    p_bounding_office_id
        The office whose boundary encompasses the location

    p_nation_id
        The nation that the location is in

    p_nearest_city
        The name of the city nearest to the location

    p_ignorenulls
        A flag ('T' or 'F') that specifies whether to ignore NULL parameters. If 'F', existing data will be updated with NULL parameter values.

    p_db_office_id
        The office that owns the location. If not specified or NULL, the session user's default office will be used


    Returns
    -------
    bool
        true if successful
    """
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
