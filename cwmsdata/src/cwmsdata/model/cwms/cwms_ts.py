"""_summary_
"""

import cx_Oracle

from cwmsdata import pool


def store_ts(p_cwms_ts_id, p_units, p_times, p_values, p_qualities, p_office_id=None):

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
