"""
CWMS Oracle package 'cwms_ts'
"""

import cx_Oracle

from cwmsdata import pool


def store_ts(p_cwms_ts_id, p_units, p_times, p_values, p_qualities, p_office_id=None):
    """


    Parameters
    ----------
    P_Cwms_Ts_Id
        The time series identifier

    P_Units
        The unit of the data values

    P_Times
        The UTC times of the data values

    P_Values
        The data values

    P_Qualities
        The data quality codes for the data values

    P_Store_Rule
        The store rule to use

    P_Override_Prot
        A flag ('T' or 'F') specifying whether to override the protection flag on any existing data value

    P_Version_Date
        The version date of the data

    P_Office_Id
        The office owning the time series. If not specified or NULL, the session user's default office is used

    P_Create_As_Lrts
        A flag ('T' or 'F') specifying whether to create the time series as a local-regular time series if it doesn't already exit. This applies only to non-existing time series with intervals that start with '~'. Otherwise the parameter is ignored.


    Returns
    -------
    bool
        true if successful
    """
    stmt = """
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

    with pool.acquire() as connection:
        with connection.cursor() as crsr:
            args = [
                p_cwms_ts_id,
                p_units,
                crsr.arrayvar(cx_Oracle.NUMBER, p_times),
                crsr.arrayvar(cx_Oracle.NATIVE_FLOAT, p_values),
                crsr.arrayvar(cx_Oracle.NUMBER, p_qualities),
                p_office_id,
            ]

            crsr.execute(stmt, args)

            return True
