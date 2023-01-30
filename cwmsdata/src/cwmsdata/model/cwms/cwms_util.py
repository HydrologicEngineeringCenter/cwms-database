"""
CWMS Oracle package 'cwms_util'
"""

import cx_Oracle

from cwmsdata import pool


def user_office_id():
    """
    Determine the user's office id

    Returns
    -------
    str
        Returns the primary office id of user calling the function
    """
    office = None
    with pool.acquire() as connection:
        with connection.cursor() as crsr:
            office = crsr.callfunc("cwms_util.user_office_id", cx_Oracle.STRING)

    return office
