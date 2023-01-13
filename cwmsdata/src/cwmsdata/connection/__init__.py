"""
Connection to the database using environment variables
"""

import os
import sqlite3
from importlib.resources import path
from textwrap import dedent

import cx_Oracle

from cwmsdata.cwms_log.cwms_logger import logger

cx_Oracle.init_oracle_client()


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
    data_resources = path("cwmsdata.data", "cx_cwms.db")
    with data_resources as res:
        with sqlite3.connect(res.as_posix()) as conn:
            cur = conn.cursor()
            res = cur.execute(dedent(stmt))
            rows = res.fetchall()

            return rows
