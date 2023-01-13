"""
Connection to the database using environment variables
"""

import os
from pathlib import Path

import cx_Oracle

from cwmsdata.cwms_log.cwms_logger import logger

cx_Oracle.init_oracle_client()

parent_dir = Path(__file__).parent

def start_pool():
    """
    Create a SessionPool

    Returns
    -------
    cx_Oracle.SessionPool
        SessionPool provide for acquire()
    """
    pool_min = 4
    pool_max = 4
    pool_inc = 0

    try:
        pool = cx_Oracle.SessionPool(
                user=os.environ.get("CWMS_USER"),
                password=os.environ.get("CWMS_PASSWORD"),
                dsn=os.environ.get("DB_HOST_PORT") + os.environ.get("DB_NAME"),
                min=pool_min,
                max=pool_max,
                increment=pool_inc,
            )
        return pool
    except TypeError as err:
        logger.warning(err)
