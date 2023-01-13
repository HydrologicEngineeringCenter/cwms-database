"""_summary_
"""

import cx_Oracle

from cwmsdata import pool

def user_office_id():
    office = None
    with pool.acquire() as connection:
        with connection.cursor() as crsr:
            office = crsr.callfunc("cwms_util.user_office_id", cx_Oracle.STRING)

    return office
