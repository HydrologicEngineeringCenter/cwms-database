/* Formatted on 2007/11/13 15:21 (Formatter Plus v4.8.8) */
/* CWMS Version 2.0 --
This script should be run by the cwms schema owner.
*/
SET serveroutput on
----------------------------------------------------
-- drop tables, mviews & mview logs if they exist --
----------------------------------------------------
DECLARE
   TYPE id_array_t IS TABLE OF VARCHAR2 (32);
   view_names   id_array_t
      := id_array_t ('av_active_flag',
                     'av_loc',          -- av_loc is created in at_schema_2...
                     'av_cwms_ts_id',
                     'av_loc_alias',
                     'av_loc_cat_grp',
                     'av_loc_level',
                     'av_parameter',
                     'av_screened_ts_ids',
                     'av_screening_assignments',
                     'av_screening_criteria',
                     'av_screening_dur_mag',
                     'av_screening_id',
                     'av_shef_decode_spec',
                     'av_shef_pe_codes',
                     'av_unit',
                     'av_storage_unit',
                     'av_log_message',     -- located in at_schema_2
                     'av_dataexchange_job'
                    );
BEGIN
   FOR i IN view_names.FIRST .. view_names.LAST
   LOOP
      BEGIN
         EXECUTE IMMEDIATE 'drop view' || view_names (i);
         DBMS_OUTPUT.put_line ('Dropped view ' || view_names (i));
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END LOOP;
END;
/
---------------------------------------------------------
CREATE OR REPLACE FORCE VIEW av_shef_pe_codes
(
    shef_pe_code,
    base_parameter_id,
    sub_parameter_id,
    parameter_type_id,
    abstract_param_id,
    unit_id_en,
    unit_id_si,
    shef_duration_numeric,
    shef_tse_code,
    description,
    db_office_id,
    abstract_param_code,
    unit_code_en,
    unit_code_si
)
AS
    SELECT    a.shef_pe_code,
                CASE
                    WHEN a.parameter_code = 0 THEN NULL
                    ELSE c.base_parameter_id
                END
                    base_parameter_id,
                CASE
                    WHEN a.parameter_code = 0 THEN NULL
                    ELSE b.sub_parameter_id
                END
                    sub_parameter_id,
                CASE
                    WHEN d.parameter_type_code = 0 THEN NULL
                    ELSE parameter_type_id
                END
                    parameter_type_id, i.abstract_param_id, e.unit_id unit_id_en,
                f.unit_id unit_id_si, g.shef_duration_numeric, a.shef_tse_code,
                a.description, 'CWMS' db_office_id, i.abstract_param_code,
                e.unit_code unit_code_en, f.unit_code unit_code_si
      FROM    cwms_shef_pe_codes a,
                at_parameter b,
                cwms_base_parameter c,
                cwms_parameter_type d,
                cwms_unit e,
                cwms_unit f,
                cwms_shef_duration g,
                cwms_abstract_parameter i
     WHERE         a.parameter_code = b.parameter_code
                AND b.base_parameter_code = c.base_parameter_code
                AND a.parameter_type_code = d.parameter_type_code
                AND a.unit_code_en = e.unit_code(+)
                AND e.abstract_param_code = i.abstract_param_code
                AND a.unit_code_si = f.unit_code(+)
                AND a.shef_duration_code = g.shef_duration_code(+)
    UNION
    SELECT    a.shef_pe_code,
                CASE
                    WHEN a.parameter_code = 0 THEN NULL
                    ELSE c.base_parameter_id
                END
                    base_parameter_id,
                CASE
                    WHEN a.parameter_code = 0 THEN NULL
                    ELSE b.sub_parameter_id
                END
                    sub_parameter_id,
                CASE
                    WHEN d.parameter_type_code = 0 THEN NULL
                    ELSE parameter_type_id
                END
                    parameter_type_id, i.abstract_param_id, e.unit_id unit_id_en,
                f.unit_id unit_id_si, g.shef_duration_numeric, a.shef_tse_code,
                a.description, h.office_id db_office_id, i.abstract_param_code,
                e.unit_code unit_code_en, f.unit_code unit_code_si
      FROM    at_shef_pe_codes a,
                at_parameter b,
                cwms_base_parameter c,
                cwms_parameter_type d,
                cwms_unit e,
                cwms_unit f,
                cwms_shef_duration g,
                cwms_office h,
                cwms_abstract_parameter i
     WHERE         a.parameter_code = b.parameter_code
                AND b.base_parameter_code = c.base_parameter_code
                AND a.parameter_type_code = d.parameter_type_code
                AND a.unit_code_en = e.unit_code(+)
                AND e.abstract_param_code = i.abstract_param_code
                AND a.unit_code_si = f.unit_code(+)
                AND a.shef_duration_code = g.shef_duration_code(+)
                AND a.db_office_code = h.office_code
    ORDER BY   shef_pe_code
/
--------------------------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW av_shef_decode_spec
(
    ts_code,
    cwms_ts_id,
    data_stream_id,
    db_office_id,
    loc_group_id,
    loc_category_id,
    loc_alias_id,
    shef_loc_id,
    shef_pe_code,
    shef_tse_code,
    shef_duration_code,
    shef_duration_numeric,
    shef_time_zone_id,
    dl_time,
    unit_id,
    unit_system,
    interval_utc_offset,
    interval_forward,
    interval_backward,
    active_flag,
    shef_spec,
    location_id,
    parameter_id,
    parameter_type_id,
    interval_id,
    duration_id,
    version_id
)
AS
    SELECT    a.ts_code, b.cwms_ts_id, c.data_stream_id, b.db_office_id,
                e.loc_group_id, f.loc_category_id,
                CASE
                    WHEN d.loc_alias_id IS NULL THEN b.location_id
                    ELSE d.loc_alias_id
                END
                    loc_alias_id, a.shef_loc_id, a.shef_pe_code, a.shef_tse_code,
                a.shef_duration_code, a.shef_duration_numeric,
                g.shef_time_zone_id, a.dl_time, i.unit_id, i.unit_system,
                CASE
                    WHEN h.interval_utc_offset = -2147483648 THEN NULL
                    WHEN h.interval_utc_offset = 2147483647 THEN NULL
                    ELSE TO_CHAR (h.interval_utc_offset, '9999999999')
                END
                    interval_utc_offset, h.interval_forward, h.interval_backward,
                h.active_flag,
                    loc_alias_id
                || '.'
                || shef_pe_code
                || '.'
                || shef_tse_code
                || '.'
                || shef_duration_numeric
                    shef_spec, b.location_id, b.parameter_id, b.parameter_type_id,
                b.interval_id, b.duration_id, b.version_id
      FROM    at_shef_decode a,
                mv_cwms_ts_id b,
                at_data_stream_id c,
                at_loc_group_assignment d,
                at_loc_group e,
                at_loc_category f,
                cwms_shef_time_zone g,
                at_cwms_ts_spec h,
                cwms_unit i
     WHERE         a.ts_code = b.ts_code
                AND a.data_stream_code = c.data_stream_code
                AND a.loc_group_code = d.loc_group_code
                AND a.location_code = d.location_code
                AND d.loc_group_code = e.loc_group_code
                AND e.loc_category_code = f.loc_category_code
                AND a.shef_time_zone_code = g.shef_time_zone_code
                AND a.ts_code = h.ts_code
                AND a.shef_unit_code = i.unit_code
/
begin
	execute immediate 'DROP PUBLIC SYNONYM CWMS_V_SHEF_DECODE_SPEC';
exception
	when others then null;
end;		
/
CREATE PUBLIC SYNONYM CWMS_V_SHEF_DECODE_SPEC FOR AV_SHEF_DECODE_SPEC
/
GRANT SELECT ON AV_SHEF_DECODE_SPEC TO CWMS_USER
/
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW av_active_flag (data_stream_id,
                                       shef_spec,
                                       db_office_code,
                                       db_office_id,
                                       ts_code,
                                       cwms_ts_id,
                                       loc_active_flag,
                                       ts_active_flag,
                                       ds_active_flag,
                                       net_active_flag
                                      )
AS
   SELECT c.data_stream_id,
          UPPER (   b.shef_loc_id
                 || SUBSTR ('.', 1, LENGTH (b.shef_loc_id))
                 || b.shef_pe_code
                 || SUBSTR ('.', 1, LENGTH (b.shef_loc_id))
                 || b.shef_tse_code
                 || SUBSTR ('.', 1, LENGTH (b.shef_loc_id))
                 || b.shef_duration_numeric
                ) shef_spec,
          a.db_office_code, a.db_office_id, a.ts_code, a.cwms_ts_id,
          a.loc_active_flag, a.ts_active_flag,
          CASE
             WHEN c.active_flag IS NULL
                THEN 'N/A'
             ELSE c.active_flag
          END ds_active_flag,
          CASE
             WHEN c.active_flag IS NULL
                THEN a.net_ts_active_flag
             WHEN a.net_ts_active_flag = 'T'
             AND c.active_flag = 'T'
                THEN 'T'
             ELSE 'F'
          END net_active_flag
     FROM mv_cwms_ts_id a, at_shef_decode b, at_data_stream_id c
    WHERE a.ts_code = b.ts_code(+) AND b.data_stream_code = c.data_stream_code(+)
/
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW av_loc_alias (category_id,
                                     GROUP_ID,
                                     location_code,
                                     db_office_id,
                                     base_location_id,
                                     sub_location_id,
                                     location_id,
                                     alias_id
                                    )
AS
   SELECT atlc.loc_category_id, atlg.loc_group_id, atlga.location_code,
          co.office_id db_office_id, abl.base_location_id,
          atpl.sub_location_id,
             abl.base_location_id
          || SUBSTR ('-', 1, LENGTH (atpl.sub_location_id))
          || atpl.sub_location_id location_id,
          atlga.loc_alias_id
     FROM at_physical_location atpl,
          at_base_location abl,
          at_loc_group_assignment atlga,
          at_loc_group atlg,
          at_loc_category atlc,
          cwms_office co
    WHERE atlga.location_code = atpl.location_code
      AND atpl.base_location_code = abl.base_location_code
      AND atlga.loc_group_code = atlg.loc_group_code
      AND atlg.loc_category_code = atlc.loc_category_code
      AND abl.db_office_code = co.office_code
/
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW av_loc_grp_assgn (category_id,
                                         group_id,
                                         location_code,
                                         db_office_id,
                                         base_location_id,
                                         sub_location_id,
                                         location_id,
                                         alias_id,
                                         attribute
                                        )
AS
   SELECT atlc.loc_category_id, atlg.loc_group_id, atlga.location_code,
          co.office_id db_office_id, abl.base_location_id,
          atpl.sub_location_id,
             abl.base_location_id
          || SUBSTR ('-', 1, LENGTH (atpl.sub_location_id))
          || atpl.sub_location_id location_id,
          atlga.loc_alias_id,
          atlga.loc_attribute
     FROM at_physical_location atpl,
          at_base_location abl,
          at_loc_group_assignment atlga,
          at_loc_group atlg,
          at_loc_category atlc,
          cwms_office co
    WHERE atlga.location_code = atpl.location_code
      AND atpl.base_location_code = abl.base_location_code
      AND atlga.loc_group_code = atlg.loc_group_code
      AND atlg.loc_category_code = atlc.loc_category_code
      AND abl.db_office_code = co.office_code
/
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW av_loc_cat_grp (cat_db_office_id,
                                       loc_category_id,
                                       loc_category_desc,
                                       grp_db_office_id,
                                       loc_group_id,
                                       loc_group_desc
                                      )
AS
   SELECT co.office_id cat_db_office_id, loc_category_id, loc_category_desc,
          coo.office_id grp_db_office_id, loc_group_id, loc_group_desc
     FROM cwms_office co,
          cwms_office coo,
          at_loc_category atlc,
          at_loc_group atlg
    WHERE atlc.db_office_code = co.office_code
      AND atlg.db_office_code = coo.office_code(+)
      AND atlc.loc_category_code = atlg.loc_category_code(+)
/
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW av_parameter (db_office_id,
                                     db_office_code,
                                     parameter_code,
                                     base_parameter_code,
                                     base_parameter_id,
                                     sub_parameter_id,
                                     parameter_id
                                    )
AS
   SELECT a.office_id db_office_id, b.db_office_code, b.parameter_code,
          c.base_parameter_code, c.base_parameter_id, b.sub_parameter_id,
             c.base_parameter_id
          || SUBSTR ('-', 1, LENGTH (b.sub_parameter_id))
          || b.sub_parameter_id parameter_id
     FROM cwms_office a, at_parameter b, cwms_base_parameter c
    WHERE b.db_office_code = a.db_host_office_code
      AND b.base_parameter_code = c.base_parameter_code
/
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW av_screened_ts_ids (screening_code,
                                           ts_code,
                                           base_location_code,
                                           location_code,
                                           db_office_id,
                                           screening_id,
                                           active_flag,
                                           resultant_ts_code,
                                           screening_id_desc,
                                           cwms_ts_id,
                                           base_location_id,
                                           sub_location_id,
                                           location_id,
                                           base_parameter_id,
                                           sub_parameter_id,
                                           parameter_id,
                                           parameter_type_id,
                                           duration_id
                                          )
AS
   SELECT atsi.screening_code, ats.ts_code, mcti.base_location_code,
          mcti.location_code, mcti.db_office_id, atsi.screening_id,
          ats.active_flag, ats.resultant_ts_code, atsi.screening_id_desc,
          mcti.cwms_ts_id, mcti.base_location_id, mcti.sub_location_id,
          mcti.location_id, mcti.base_parameter_id, mcti.sub_parameter_id,
          mcti.parameter_id, mcti.parameter_type_id, mcti.duration_id
     FROM mv_cwms_ts_id mcti, at_screening_id atsi, at_screening ats
    WHERE ats.screening_code = atsi.screening_code
      AND ats.ts_code = mcti.ts_code
/
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW av_screening_assignments (screening_code,
                                                 ts_code,
                                                 base_location_code,
                                                 location_code,
                                                 db_office_id,
                                                 screening_id,
                                                 active_flag,
                                                 resultant_ts_code,
                                                 screening_id_desc,
                                                 cwms_ts_id,
                                                 base_location_id,
                                                 sub_location_id,
                                                 location_id,
                                                 base_parameter_id,
                                                 sub_parameter_id,
                                                 parameter_id,
                                                 parameter_type_id,
                                                 duration_id
                                                )
AS
   SELECT atsi.screening_code, ats.ts_code, mcti.base_location_code,
          mcti.location_code, mcti.db_office_id, atsi.screening_id,
          ats.active_flag, ats.resultant_ts_code, atsi.screening_id_desc,
          mcti.cwms_ts_id, mcti.base_location_id, mcti.sub_location_id,
          mcti.location_id, mcti.base_parameter_id, mcti.sub_parameter_id,
          mcti.parameter_id, mcti.parameter_type_id, mcti.duration_id
     FROM mv_cwms_ts_id mcti, at_screening_id atsi, at_screening ats
    WHERE ats.screening_code = atsi.screening_code
      AND ats.ts_code = mcti.ts_code
/
--------------------------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW av_screening_criteria (screening_code,
                                                            db_office_id,
                                                            screening_id,
                                                            screening_id_desc,
                                                            base_parameter_id,
                                                            sub_parameter_id,
                                                            parameter_id,
                                                            parameter_type_id,
                                                            duration_id,
                                                            season_start_day,
                                                            season_start_month,
                                                            unit_system,
                                                            unit_id,
                                                            range_reject_lo,
                                                            range_reject_hi,
                                                            range_question_lo,
                                                            range_question_hi,
                                                            rate_change_reject_rise,
                                                            rate_change_reject_fall,
                                                            rate_change_quest_rise,
                                                            rate_change_quest_fall,
                                                            rate_change_disp_interval,
                                                            const_reject_duration,
                                                            const_reject_min,
                                                            const_reject_tolerance,
                                                            const_reject_n_miss,
                                                            const_quest_duration,
                                                            const_quest_min,
                                                            const_quest_tolerance,
                                                            const_quest_n_miss,
                                                            estimate_expression,
                                                            range_active_flag,
                                                            rate_change_active_flag,
                                                            const_active_flag,
                                                            dur_mag_active_flag,
                                                            rate_change_disp_interval_id
                                                           )
AS
   SELECT atsi.screening_code, co.office_id db_office_id, atsi.screening_id,
          atsi.screening_id_desc, cbp.base_parameter_id, atp.sub_parameter_id,
             cbp.base_parameter_id
          || SUBSTR ('-', 1, LENGTH (atp.sub_parameter_id))
          || atp.sub_parameter_id parameter_id,
          cpt.parameter_type_id, cd.duration_id,
          MOD (avsc.season_start_date, 30) season_start_day,
              (avsc.season_start_date - MOD (avsc.season_start_date, 30)
              )
            / 30
          + 1 season_start_month,
          adu.unit_system, cuc.to_unit_id unit_id,
          avsc.range_reject_lo * cuc.factor + cuc.offset range_reject_lo,
          avsc.range_reject_hi * cuc.factor + cuc.offset range_reject_hi,
          avsc.range_question_lo * cuc.factor + cuc.offset range_question_lo,
          avsc.range_question_hi * cuc.factor + cuc.offset range_question_hi,
            avsc.rate_change_reject_rise * cuc.factor
          + cuc.offset rate_change_reject_rise,
            avsc.rate_change_reject_fall * cuc.factor
          + cuc.offset rate_change_reject_fall,
            avsc.rate_change_quest_rise * cuc.factor
          + cuc.offset rate_change_quest_rise,
            avsc.rate_change_quest_fall * cuc.factor
          + cuc.offset rate_change_quest_fall,
          CASE
             WHEN asctl.rate_change_disp_interval_code IS NULL
                THEN 'Unknown'
             ELSE (SELECT interval_id
                     FROM cwms_interval
                    WHERE interval_code =
                             asctl.rate_change_disp_interval_code)
          END rate_change_disp_interval,
          CASE
             WHEN avsc.const_reject_duration_code IS NULL
                THEN 'Unknown'
             ELSE (SELECT duration_id
                     FROM cwms_duration
                    WHERE duration_code =
                             avsc.const_reject_duration_code)
          END const_reject_duration,
          avsc.const_reject_min * cuc.factor + cuc.offset const_reject_min,
            avsc.const_reject_tolerance * cuc.factor
          + cuc.offset const_reject_tolerance,
          avsc.const_reject_n_miss,
          CASE
             WHEN avsc.const_quest_duration_code IS NULL
                THEN 'Unknown'
             ELSE (SELECT duration_id
                     FROM cwms_duration
                    WHERE duration_code =
                             avsc.const_quest_duration_code)
          END const_quest_duration,
          avsc.const_quest_min * cuc.factor + cuc.offset const_quest_min,
            avsc.const_quest_tolerance * cuc.factor
          + cuc.offset const_quest_tolerance,
          avsc.const_quest_n_miss, avsc.estimate_expression,
          asctl.range_active_flag, asctl.rate_change_active_flag,
          asctl.const_active_flag, asctl.dur_mag_active_flag,
          ci.interval_id rate_change_disp_interval_id
     FROM at_screening_id atsi,
          cwms_office co,
          at_parameter atp,
          cwms_base_parameter cbp,
          cwms_parameter_type cpt,
          cwms_duration cd,
          cwms_interval ci,
          at_display_units adu,
          cwms_unit_conversion cuc,
          at_screening_criteria avsc,
          at_screening_control asctl
    WHERE co.office_code = atsi.db_office_code
      AND cbp.base_parameter_code = atsi.base_parameter_code
      AND atp.parameter_code = atsi.parameter_code
      AND atsi.parameter_type_code = cpt.parameter_type_code(+)
      AND atsi.duration_code = cd.duration_code(+)
      AND atsi.screening_code = avsc.screening_code(+)
      AND atsi.db_office_code = adu.db_office_code
      AND cbp.unit_code = cuc.from_unit_code
      AND adu.display_unit_code = cuc.to_unit_code
      AND atsi.parameter_code = adu.parameter_code
      AND avsc.screening_code = asctl.screening_code(+)
      AND asctl.rate_change_disp_interval_code = ci.interval_code(+)
/
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW av_screening_dur_mag (screening_code,
                                             db_office_id,
                                             screening_id,
                                             screening_id_desc,
                                             base_parameter_id,
                                             sub_parameter_id,
                                             parameter_id,
                                             parameter_type_id,
                                             duration_id,
                                             season_start_day,
                                             season_start_month,
                                             unit_system,
                                             unit_id,
                                             dur_mag_duration_id,
                                             reject_lo,
                                             reject_hi,
                                             question_lo,
                                             question_hi
                                            )
AS
   SELECT atsdm.screening_code, co.office_id db_office_id, atsi.screening_id,
          atsi.screening_id_desc, cbp.base_parameter_id, atp.sub_parameter_id,
             cbp.base_parameter_id
          || SUBSTR ('-', 1, LENGTH (atp.sub_parameter_id))
          || atp.sub_parameter_id parameter_id,
          cpt.parameter_type_id, cd.duration_id,
          MOD (atsdm.season_start_date, 30) season_start_day,
              (atsdm.season_start_date - MOD (atsdm.season_start_date, 30)
              )
            / 30
          + 1 season_start_month,
          adu.unit_system, cuc.to_unit_id unit_id,
          cd2.duration_id dur_mag_duration_id,
          atsdm.reject_lo * cuc.factor + cuc.offset reject_lo,
          atsdm.reject_hi * cuc.factor + cuc.offset reject_hi,
          atsdm.question_lo * cuc.factor + cuc.offset question_lo,
          atsdm.question_hi * cuc.factor + cuc.offset question_hi
     FROM at_screening_id atsi,
          cwms_office co,
          at_parameter atp,
          cwms_base_parameter cbp,
          cwms_parameter_type cpt,
          cwms_duration cd,
          cwms_duration cd2,
          at_display_units adu,
          cwms_unit_conversion cuc,
          at_screening_dur_mag atsdm
    WHERE co.office_code = atsi.db_office_code
      AND cbp.base_parameter_code = atsi.base_parameter_code
      AND atp.parameter_code = atsi.parameter_code
      AND atsi.parameter_type_code = cpt.parameter_type_code(+)
      AND atsi.duration_code = cd.duration_code(+)
      AND atsdm.duration_code = cd2.duration_code
      AND atsi.screening_code = atsdm.screening_code
      AND atsi.db_office_code = adu.db_office_code
      AND cbp.unit_code = cuc.from_unit_code
      AND adu.display_unit_code = cuc.to_unit_code
      AND atsi.parameter_code = adu.parameter_code
/
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW av_screening_id (screening_code,
                                        db_office_id,
                                        screening_id,
                                        screening_id_desc,
                                        base_parameter_id,
                                        sub_parameter_id,
                                        parameter_id,
                                        parameter_type_id,
                                        duration_id
                                       )
AS
   SELECT atsi.screening_code, co.office_id db_office_id, atsi.screening_id,
          atsi.screening_id_desc, cbp.base_parameter_id, atp.sub_parameter_id,
             cbp.base_parameter_id
          || SUBSTR ('-', 1, LENGTH (atp.sub_parameter_id))
          || atp.sub_parameter_id parameter_id,
          cpt.parameter_type_id, cd.duration_id
     FROM at_screening_id atsi,
          cwms_office co,
          at_parameter atp,
          cwms_base_parameter cbp,
          cwms_parameter_type cpt,
          cwms_duration cd
    WHERE co.office_code = atsi.db_office_code
      AND cbp.base_parameter_code = atsi.base_parameter_code
      AND atp.parameter_code = atsi.parameter_code
      AND atsi.parameter_type_code = cpt.parameter_type_code(+)
      AND atsi.duration_code = cd.duration_code(+)
/
--------------------------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW av_cwms_ts_id (db_office_id,
                                                    cwms_ts_id,
                                                    unit_id,
                                                    abstract_param_id,
                                                    base_location_id,
                                                    sub_location_id,
                                                    location_id,
                                                    base_parameter_id,
                                                    sub_parameter_id,
                                                    parameter_id,
                                                    parameter_type_id,
                                                    interval_id,
                                                    duration_id,
                                                    version_id,
                                                    INTERVAL,
                                                    interval_utc_offset,
                                                    loc_active_flag,
                                                    ts_active_flag,
                                                    net_ts_active_flag,
                                                    version_flag,
                                                    ts_code,
                                                    db_office_code,
                                                    base_location_code,
                                                    location_code,
                                                    parameter_code
                                                   )
AS
   SELECT db_office_id, cwms_ts_id, unit_id, abstract_param_id,
          base_location_id, sub_location_id, location_id, base_parameter_id,
          sub_parameter_id, parameter_id, parameter_type_id, interval_id,
          duration_id, version_id, INTERVAL, interval_utc_offset,
          loc_active_flag, ts_active_flag, net_ts_active_flag, version_flag,
          ts_code, db_office_code, base_location_code, location_code,
          parameter_code
     FROM mv_cwms_ts_id
/
--------------------------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW zav_cwms_ts_id
(
    db_office_code,
    base_location_code,
    location_code,
    loc_active_flag,
    parameter_code,
    ts_code,
    ts_active_flag,
    net_ts_active_flag,
    db_office_id,
    cwms_ts_id,
    unit_id,
    abstract_param_id,
    base_location_id,
    sub_location_id,
    location_id,
    base_parameter_id,
    sub_parameter_id,
    parameter_id,
    parameter_type_id,
    interval_id,
    duration_id,
    version_id,
    interval,
    interval_utc_offset,
    version_flag
)
AS
    SELECT    abl.db_office_code, abl.base_location_code, s.location_code,
                l.active_flag loc_active_flag, ap.parameter_code, s.ts_code,
                s.active_flag ts_active_flag,
                CASE
                    WHEN l.active_flag = 'T' AND s.active_flag = 'T' THEN 'T'
                    ELSE 'F'
                END
                    net_ts_active_flag, o.office_id db_office_id,
                    abl.base_location_id
                || SUBSTR ('-', 1, LENGTH (l.sub_location_id))
                || l.sub_location_id
                || '.'
                || base_parameter_id
                || SUBSTR ('-', 1, LENGTH (ap.sub_parameter_id))
                || ap.sub_parameter_id
                || '.'
                || parameter_type_id
                || '.'
                || interval_id
                || '.'
                || duration_id
                || '.'
                || version
                    cwms_ts_id, u.unit_id, cap.abstract_param_id,
                abl.base_location_id, l.sub_location_id,
                    abl.base_location_id
                || SUBSTR ('-', 1, LENGTH (l.sub_location_id))
                || l.sub_location_id
                    location_id, base_parameter_id, ap.sub_parameter_id,
                    base_parameter_id
                || SUBSTR ('-', 1, LENGTH (ap.sub_parameter_id))
                || ap.sub_parameter_id
                    parameter_id, parameter_type_id, interval_id, duration_id,
                version version_id, i.interval, s.interval_utc_offset,
                s.version_flag
      FROM    cwms_office o,
                at_base_location abl,
                at_physical_location l,
                at_cwms_ts_spec s,
                at_parameter ap,
                cwms_base_parameter p,
                cwms_parameter_type t,
                cwms_interval i,
                cwms_duration d,
                cwms_unit u,
                cwms_abstract_parameter cap
     WHERE         abl.db_office_code = o.office_code
                AND l.location_code = s.location_code
                AND ap.base_parameter_code = p.base_parameter_code
                AND s.parameter_code = ap.parameter_code
                AND s.parameter_type_code = t.parameter_type_code
                AND s.interval_code = i.interval_code
                AND s.duration_code = d.duration_code
                AND u.unit_code = p.unit_code
                AND u.abstract_param_code = cap.abstract_param_code
                AND l.base_location_code = abl.base_location_code
                AND s.delete_date IS NULL
/
--------------------------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW av_unit
(
    unit_system,
    unit_id,
    abstract_param_id,
    long_name,
    description,
    db_office_id,
    unit_code,
    abstract_param_code,
    db_office_code
)
AS
    SELECT    a.unit_system, a.unit_id, b.abstract_param_id, a.long_name,
                a.description, 'CWMS' db_office_id, a.unit_code,
                a.abstract_param_code, 53 db_office_code
      FROM    cwms_unit a, cwms_abstract_parameter b
     WHERE    b.abstract_param_code = a.abstract_param_code
    UNION
    SELECT    b.unit_system, a.alias_id unit_id, c.abstract_param_id,
                b.long_name, b.description, d.office_id db_office_id, a.unit_code,
                b.abstract_param_code, a.db_office_code
      FROM    at_unit_alias a,
                cwms_unit b,
                cwms_abstract_parameter c,
                cwms_office d
     WHERE         b.unit_code = a.unit_code
                AND b.abstract_param_code = c.abstract_param_code
                AND a.db_office_code = d.office_code
/
--------------------------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW av_storage_unit
(
    base_parameter_id,
    sub_parameter_id,
    unit_id
)
AS
   select base_parameter_id,
          sub_parameter_id,
          unit_id
     from at_parameter ap,
          cwms_base_parameter bp,
          cwms_unit u
    where ap.base_parameter_code = bp.base_parameter_code
      and bp.unit_code = u.unit_code
/
--------------------------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW AV_DATAEXCHANGE_JOB
(
   JOB_ID,
   REQUESTED_FROM,
   SET_ID,
   DIRECTION,
   REQUEST_TIME,
   START_TIME,
   END_TIME,
   START_DELAY,
   EXECUTION_TIME,
   TOTAL_TIME,
   PROCESSED_BY,
   RESULTS
)
AS
   WITH request$
           AS (SELECT p1.msg_id,
                      p1.prop_text AS job_id,
                      p3.prop_text AS set_id,
                      p4.prop_text AS to_dss,
                      m.log_timestamp_utc,
                      o.office_id,
                      m.HOST
                 FROM at_log_message m,
                      cwms_office o,
                      at_log_message_properties p1,
                      at_log_message_properties p2,
                      at_log_message_properties p3,
                      at_log_message_properties p4,
                      cwms_log_message_types t
                WHERE     p1.prop_name = 'job_id'
                      AND p2.prop_name = 'subtype'
                      AND p3.prop_name = 'set_id'
                      AND p4.prop_name = 'to_dss'
                      AND p2.prop_text = 'BatchExchange'
                      AND p2.msg_id = p1.msg_id
                      AND p3.msg_id = p1.msg_id
                      AND p4.msg_id = p1.msg_id
                      AND t.message_type_id = 'RequestAction'
                      AND m.msg_type = t.message_type_code
                      AND m.msg_id = p1.msg_id
                      AND o.office_code = m.office_code),
        start$
           AS (SELECT p1.msg_id, p1.prop_text AS job_id, m.log_timestamp_utc
                 FROM at_log_message m,
                      cwms_office o,
                      at_log_message_properties p1,
                      at_log_message_properties p2,
                      cwms_log_message_types t
                WHERE     p1.prop_name = 'job_id'
                      AND p2.prop_name = 'subtype'
                      AND p2.prop_text = 'BatchStarting'
                      AND p2.msg_id = p1.msg_id
                      AND t.message_type_id = 'Status'
                      AND m.msg_type = t.message_type_code
                      AND m.msg_id = p1.msg_id
                      AND o.office_code = m.office_code),
        complete$
           AS (SELECT p1.msg_id,
                      p1.prop_text AS job_id,
                      m.log_timestamp_utc,
                      m.instance,
                      m.msg_text
                 FROM at_log_message m,
                      cwms_office o,
                      at_log_message_properties p1,
                      at_log_message_properties p2,
                      cwms_log_message_types t
                WHERE     p1.prop_name = 'job_id'
                      AND p2.prop_name = 'subtype'
                      AND p2.prop_text = 'BatchCompleted'
                      AND p2.msg_id = p1.msg_id
                      AND t.message_type_id = 'Status'
                      AND m.msg_type = t.message_type_code
                      AND m.msg_id = p1.msg_id
                      AND o.office_code = m.office_code)
     SELECT request$.job_id,
            request$.host AS requested_from,
            request$.office_id || '/' || request$.set_id AS set_id,
            CASE request$.to_dss
               WHEN 'true'  THEN 'extract'
               WHEN 'false' THEN 'post'
            END
               AS direction,
            request$.log_timestamp_utc AS request_time,
            start$.log_timestamp_utc AS start_time,
            complete$.log_timestamp_utc AS end_time,
            start$.log_timestamp_utc - request$.log_timestamp_utc
               AS start_delay,
            complete$.log_timestamp_utc - start$.log_timestamp_utc
               AS execution_time,
            complete$.log_timestamp_utc - request$.log_timestamp_utc
               AS total_time,
            complete$.instance AS processed_by,
            complete$.msg_text AS results
       FROM request$
            LEFT OUTER JOIN start$
               ON start$.job_id = request$.job_id
            LEFT OUTER JOIN complete$
               ON complete$.job_id = request$.job_id
   ORDER BY request$.log_timestamp_utc DESC;
/
show errors;

CREATE OR REPLACE FORCE VIEW av_location_level
AS
   select office_id,
          location_id
          || '.' || parameter_id
          || '.' || parameter_type_id
          || '.' || duration_id
          || '.' || specified_level_id                            as location_level_id,
          attribute_parameter_id
          || substr('.', 1, length(attribute_parameter_type_id)) 
          || attribute_parameter_type_id
          || substr('.', 1, length(attribute_duration_id)) 
          || attribute_duration_id                                as attribute_id,
          level_date,
          unit_system,
          attribute_unit,
          level_unit,
          attribute_value,
          constant_level,
          interval_origin,
          substr(calendar_interval_, 2)                           as calendar_interval,
          time_interval,
          interpolate,
          substr(calendar_offset_, 2)                             as calendar_offset,
          substr(time_offset_, 2)                                 as time_offset,
          seasonal_level,
          level_comment,
          attribute_comment
     from ((select c_o.office_id                                          as office_id,
                   a_bl.base_location_id
                   || substr('-', 1, length(a_pl.sub_location_id))
                   || a_pl.sub_location_id                                as location_id,
                   c_bp1.base_parameter_id
                   || substr('-', 1, length(a_p1.sub_parameter_id))
                   || a_p1.sub_parameter_id                               as parameter_id,
                   c_pt1.parameter_type_id                                as parameter_type_id,
                   c_d1.duration_id                                       as duration_id,
                   a_sl.specified_level_id                                as specified_level_id,
                   null                                                   as attribute_parameter_id,
                   null                                                   as attribute_parameter_type_id,
                   null                                                   as attribute_duration_id,
                   a_ll.location_level_date                               as level_date,
                   us.unit_system                                         as unit_system,
                   c_uc1.to_unit_id                                       as level_unit,
                   null                                                   as attribute_unit,
                   a_ll.attribute_value                                   as attribute_value,
                   a_ll.location_level_value*c_uc1.factor+c_uc1.offset    as constant_level,
                   a_ll.interval_origin                                   as interval_origin,
                   a_ll.calendar_interval                                 as calendar_interval_,
                   a_ll.time_interval                                     as time_interval,
                   a_ll.interpolate                                       as interpolate,
                   null                                                   as calendar_offset_,
                   null                                                   as time_offset_,
                   null                                                   as seasonal_level,
                   a_ll.location_level_comment                            as level_comment,
                   a_ll.attribute_comment                                 as attribute_comment
              from at_location_level          a_ll,
                   at_specified_level         a_sl,
                   at_physical_location       a_pl,
                   at_base_location           a_bl,
                   at_parameter               a_p1,
                   cwms_duration              c_d1,
                   cwms_base_parameter        c_bp1,
                   cwms_parameter_type        c_pt1,
                   cwms_unit_conversion       c_uc1,
                   cwms_office                c_o,
                   (select 'EN' as unit_system from dual union select 'SI' as unit_system from dual) us
             where a_pl.location_code            = a_ll.location_code
               and a_bl.base_location_code       = a_pl.base_location_code
               and c_o.office_code               = a_bl.db_office_code
               and a_p1.parameter_code           = a_ll.parameter_code
               and c_bp1.base_parameter_code     = a_p1.base_parameter_code
               and c_pt1.parameter_type_code     = a_ll.parameter_type_code
               and c_d1.duration_code            = a_ll.duration_code
               and a_sl.specified_level_code     = a_ll.specified_level_code
               and c_uc1.from_unit_code          = c_bp1.unit_code
               and c_uc1.to_unit_code = decode(
                  us.unit_system, 
                  'EN', c_bp1.display_unit_code_en, 
                  'SI', c_bp1.display_unit_code_si)  
               and a_ll.attribute_parameter_code is null
               and a_ll.location_level_value     is not null) 
           union
           (select c_o.office_id                                          as office_id,
                   a_bl.base_location_id
                   || substr('-', 1, length(a_pl.sub_location_id))
                   || a_pl.sub_location_id                                as location_id,
                   c_bp1.base_parameter_id
                   || substr('-', 1, length(a_p1.sub_parameter_id))
                   || a_p1.sub_parameter_id                               as parameter_id,
                   c_pt1.parameter_type_id                                as parameter_type_id,
                   c_d1.duration_id                                       as duration_id,
                   a_sl.specified_level_id                                as specified_level_id,
                   null                                                   as attribute_parameter_id,
                   null                                                   as attribute_parameter_type_id,
                   null                                                   as attribute_duration_id,
                   a_ll.location_level_date                               as level_date,
                   us.unit_system                                         as unit_system,
                   c_uc1.to_unit_id                                       as level_unit,
                   null                                                   as attribute_unit,
                   a_ll.attribute_value                                   as attribute_value,
                   null                                                   as constant_level,
                   a_ll.interval_origin                                   as interval_origin,
                   a_ll.calendar_interval                                 as calendar_interval_,
                   a_ll.time_interval                                     as time_interval,
                   a_ll.interpolate                                       as interpolate,
                   a_sll.calendar_offset                                  as calendar_offset_,
                   a_sll.time_offset                                      as time_offset_,
                   a_sll.value*c_uc1.factor+c_uc1.offset                  as seasonal_level,
                   a_ll.location_level_comment                            as level_comment,
                   a_ll.attribute_comment                                 as attribute_comment
              from at_location_level          a_ll,
                   at_seasonal_location_level a_sll,
                   at_specified_level         a_sl,
                   at_physical_location       a_pl,
                   at_base_location           a_bl,
                   at_parameter               a_p1,
                   cwms_duration              c_d1,
                   cwms_base_parameter        c_bp1,
                   cwms_parameter_type        c_pt1,
                   cwms_unit_conversion       c_uc1,
                   cwms_office                c_o,
                   (select 'EN' as unit_system from dual union select 'SI' as unit_system from dual) us
             where a_pl.location_code            = a_ll.location_code
               and a_bl.base_location_code       = a_pl.base_location_code
               and c_o.office_code               = a_bl.db_office_code
               and a_p1.parameter_code           = a_ll.parameter_code
               and c_bp1.base_parameter_code     = a_p1.base_parameter_code
               and c_pt1.parameter_type_code     = a_ll.parameter_type_code
               and c_d1.duration_code            = a_ll.duration_code
               and a_sl.specified_level_code     = a_ll.specified_level_code
               and c_uc1.from_unit_code          = c_bp1.unit_code
               and c_uc1.to_unit_code = decode(
                  us.unit_system, 
                  'EN', c_bp1.display_unit_code_en, 
                  'SI', c_bp1.display_unit_code_si)  
               and a_ll.attribute_parameter_code is null
               and a_ll.location_level_value     is null
               and a_sll.location_level_code     = a_ll.location_level_code)
           union
           (select c_o.office_id                                          as office_id,
                   a_bl.base_location_id
                   || substr('-', 1, length(a_pl.sub_location_id))
                   || a_pl.sub_location_id                                as location_id,
                   c_bp1.base_parameter_id
                   || substr('-', 1, length(a_p1.sub_parameter_id))
                   || a_p1.sub_parameter_id                               as parameter_id,
                   c_pt1.parameter_type_id                                as parameter_type_id,
                   c_d1.duration_id                                       as duration_id,
                   a_sl.specified_level_id                                as specified_level_id,
                   c_bp2.base_parameter_id
                   || substr('-', 1, length(a_p2.sub_parameter_id))
                   || a_p2.sub_parameter_id                               as attribute_parameter_id,
                   c_pt2.parameter_type_id                                as attribute_parameter_type_id,
                   c_d2.duration_id                                       as attribute_duration_id,
                   a_ll.location_level_date                               as level_date,
                   us.unit_system                                         as unit_system,
                   c_uc1.to_unit_id                                       as level_unit,
                   c_uc2.to_unit_id                                       as attribute_unit,
                   a_ll.attribute_value*c_uc2.factor+c_uc2.offset         as attribute_value,
                   a_ll.location_level_value*c_uc1.factor+c_uc1.offset    as constant_level,
                   a_ll.interval_origin                                   as interval_origin,
                   a_ll.calendar_interval                                 as calendar_interval_,
                   a_ll.time_interval                                     as time_interval,
                   a_ll.interpolate                                       as interpolate,
                   null                                                   as calendar_offset_,
                   null                                                   as time_offset_,
                   null                                                   as seasonal_level,
                   a_ll.location_level_comment                            as level_comment,
                   a_ll.attribute_comment                                 as attribute_comment
              from at_location_level          a_ll,
                   at_specified_level         a_sl,
                   at_physical_location       a_pl,
                   at_base_location           a_bl,
                   at_parameter               a_p1,
                   at_parameter               a_p2,
                   cwms_duration              c_d1,
                   cwms_base_parameter        c_bp1,
                   cwms_parameter_type        c_pt1,
                   cwms_unit_conversion       c_uc1,
                   cwms_duration              c_d2,
                   cwms_base_parameter        c_bp2,
                   cwms_parameter_type        c_pt2,
                   cwms_unit_conversion       c_uc2,
                   cwms_office                c_o,
                   (select 'EN' as unit_system from dual union select 'SI' as unit_system from dual) us
             where a_pl.location_code            = a_ll.location_code
               and a_bl.base_location_code       = a_pl.base_location_code
               and c_o.office_code               = a_bl.db_office_code
               and a_p1.parameter_code           = a_ll.parameter_code
               and c_bp1.base_parameter_code     = a_p1.base_parameter_code
               and c_pt1.parameter_type_code     = a_ll.parameter_type_code
               and c_d1.duration_code            = a_ll.duration_code
               and a_sl.specified_level_code     = a_ll.specified_level_code
               and c_uc1.from_unit_code          = c_bp1.unit_code
               and c_uc1.to_unit_code = decode(
                  us.unit_system, 
                  'EN', c_bp1.display_unit_code_en, 
                  'SI', c_bp1.display_unit_code_si)  
               and a_ll.attribute_parameter_code is not null
               and a_p2.parameter_code           = a_ll.attribute_parameter_code
               and c_bp2.base_parameter_code     = a_p2.base_parameter_code
               and c_pt2.parameter_type_code     = a_ll.attribute_parameter_type_code
               and c_d2.duration_code            = a_ll.attribute_duration_code
               and c_uc2.from_unit_code          = c_bp2.unit_code
               and c_uc2.to_unit_code = decode(
                  us.unit_system, 
                  'EN', c_bp2.display_unit_code_en, 
                  'SI', c_bp2.display_unit_code_si)  
               and a_ll.location_level_value     is not null) 
           union
           (select c_o.office_id                                          as office_id,
                   a_bl.base_location_id
                   || substr('-', 1, length(a_pl.sub_location_id))
                   || a_pl.sub_location_id                                as location_id,
                   c_bp1.base_parameter_id
                   || substr('-', 1, length(a_p1.sub_parameter_id))
                   || a_p1.sub_parameter_id                               as parameter_id,
                   c_pt1.parameter_type_id                                as parameter_type_id,
                   c_d1.duration_id                                       as duration_id,
                   a_sl.specified_level_id                                as specified_level_id,
                   c_bp2.base_parameter_id
                   || substr('-', 1, length(a_p2.sub_parameter_id))
                   || a_p2.sub_parameter_id                               as attribute_parameter_id,
                   c_pt2.parameter_type_id                                as attribute_parameter_type_id,
                   c_d2.duration_id                                       as attribute_duration_id,
                   a_ll.location_level_date                               as level_date,
                   us.unit_system                                         as unit_system,
                   c_uc1.to_unit_id                                       as level_unit,
                   c_uc2.to_unit_id                                       as attribute_unit,
                   a_ll.attribute_value*c_uc2.factor+c_uc2.offset         as attribute_value,
                   null                                                   as constant_level,
                   a_ll.interval_origin                                   as interval_origin,
                   a_ll.calendar_interval                                 as calendar_interval_,
                   a_ll.time_interval                                     as time_interval,
                   a_ll.interpolate                                       as interpolate,
                   a_sll.calendar_offset                                  as calendar_offset_,
                   a_sll.time_offset                                      as time_offset_,
                   a_sll.value*c_uc1.factor+c_uc1.offset                  as seasonal_level,
                   a_ll.location_level_comment                            as level_comment,
                   a_ll.attribute_comment                                 as attribute_comment
              from at_location_level          a_ll,
                   at_seasonal_location_level a_sll,
                   at_specified_level         a_sl,
                   at_physical_location       a_pl,
                   at_base_location           a_bl,
                   at_parameter               a_p1,
                   at_parameter               a_p2,
                   cwms_duration              c_d1,
                   cwms_base_parameter        c_bp1,
                   cwms_parameter_type        c_pt1,
                   cwms_unit_conversion       c_uc1,
                   cwms_duration              c_d2,
                   cwms_base_parameter        c_bp2,
                   cwms_parameter_type        c_pt2,
                   cwms_unit_conversion       c_uc2,
                   cwms_office                c_o,
                   (select 'EN' as unit_system from dual union select 'SI' as unit_system from dual) us
             where a_pl.location_code            = a_ll.location_code
               and a_bl.base_location_code       = a_pl.base_location_code
               and c_o.office_code               = a_bl.db_office_code
               and a_p1.parameter_code           = a_ll.parameter_code
               and c_bp1.base_parameter_code     = a_p1.base_parameter_code
               and c_pt1.parameter_type_code     = a_ll.parameter_type_code
               and c_d1.duration_code            = a_ll.duration_code
               and a_sl.specified_level_code     = a_ll.specified_level_code
               and c_uc1.from_unit_code          = c_bp1.unit_code
               and c_uc1.to_unit_code = decode(
                  us.unit_system, 
                  'EN', c_bp1.display_unit_code_en, 
                  'SI', c_bp1.display_unit_code_si)  
               and a_ll.attribute_parameter_code is not null
               and a_p2.parameter_code           = a_ll.attribute_parameter_code
               and c_bp2.base_parameter_code     = a_p2.base_parameter_code
               and c_pt2.parameter_type_code     = a_ll.attribute_parameter_type_code
               and c_d2.duration_code            = a_ll.attribute_duration_code
               and c_uc2.from_unit_code          = c_bp2.unit_code
               and c_uc2.to_unit_code = decode(
                  us.unit_system, 
                  'EN', c_bp1.display_unit_code_en, 
                  'SI', c_bp1.display_unit_code_si)  
               and a_ll.location_level_value     is null
               and a_sll.location_level_code     = a_ll.location_level_code))
  order by office_id,
           location_level_id,
           attribute_id,
           level_date,
           unit_system,
           attribute_value,
           interval_origin + calendar_offset_ + time_offset_;
/
show errors;

CREATE OR REPLACE FORCE VIEW av_location_level_indicator
AS
   with 
      llic as (
      select level_indicator_code,
             level_indicator_value as value,
             description as name,
             expression
             ||' '||comparison_operator_1
             ||' '||round(cast(comparison_value_1 as number), 10)
             ||substr(' ', 1, length(connector))
             ||connector
             ||substr(' ', 1, length(comparison_operator_2))
             ||comparison_operator_2
             ||substr(' ', 1, length(comparison_value_2))
             ||round(cast(comparison_value_2 as number), 10) as expression,
             comparison_unit,
             rate_expression
             ||substr(' ', 1, length(rate_comparison_operator_1))
             ||rate_comparison_operator_1
             ||substr(' ', 1, length(rate_comparison_value_1))
             ||round(cast(rate_comparison_value_1 as number), 10)
             ||substr(' ', 1, length(rate_connector))
             ||rate_connector
             ||substr(' ', 1, length(rate_comparison_operator_2))
             ||rate_comparison_operator_2
             ||substr(' ', 1, length(rate_comparison_value_2))
             ||round(cast(rate_comparison_value_2 as number), 10) as rate_expression,
             rate_comparison_unit,
             rate_interval
        from at_loc_lvl_indicator_cond),       
      unit as (
      select unit_code,
             unit_id
        from cwms_unit),
      rate_unit as (
      select unit_code as rate_unit_code,
             unit_id as rate_unit_id
        from cwms_unit),
      lli as (
      select *
        from at_loc_lvl_indicator),
      loc as (
      select location_code,
             base_location_code,
             sub_location_id
        from at_physical_location),
      base_loc as (
      select base_location_code,
             base_location_id,
             db_office_code
        from at_base_location),
      ofc as (
      select office_code,
             office_id
        from cwms_office),
      param as (
      select parameter_code,
             base_parameter_code,
             sub_parameter_id
        from at_parameter),
      base_param as (
      select base_parameter_code,
             base_parameter_id
        from cwms_base_parameter),
      param_type as (
      select parameter_type_code,
             parameter_type_id
        from cwms_parameter_type),
      dur as (
      select duration_code,
             duration_id
        from cwms_duration),                                              
      spec_level as (select * from at_specified_level),
      attr_param as (      
      select parameter_code,
             base_parameter_code,
             sub_parameter_id
        from at_parameter),
      attr_base_param as (
      select base_parameter_code,
             base_parameter_id,
             unit_code
        from cwms_base_parameter),
      attr_param_type as (
      select parameter_type_code,
             parameter_type_id
        from cwms_parameter_type),
      attr_dur as (
      select duration_code,
             duration_id
        from cwms_duration),
      disp as (select * from at_display_units),
      conv as (select * from cwms_unit_conversion),                                                   
      ref_spec_level as (select * from at_specified_level)
   select office_id,
          base_location_id
          || substr('-', 1, length(sub_location_id))
          || sub_location_id
          ||'.' || base_param.base_parameter_id
          || substr('-', 1, length(param.sub_parameter_id))
          || param.sub_parameter_id
          || '.' || param_type.parameter_type_id
          || '.' || dur.duration_id
          || '.' || spec_level.specified_level_id
          || '.' || level_indicator_id as level_indicator_id,
          ref_spec_level.specified_level_id as reference_level_id,
          attr_base_param.base_parameter_id
          || substr('-', 1, length(attr_param.sub_parameter_id))
          || attr_param.sub_parameter_id
          || substr('.', 1, length(attr_param_type.parameter_type_id))
          || attr_param_type.parameter_type_id
          || substr('.', 1, length(attr_dur.duration_id))
          || attr_dur.duration_id as attribute_id,
          unit_system,
          round(attr_value * factor + offset, 10 - log(10, attr_value * factor + offset)) as attribute_value,
          round(ref_attr_value * factor + offset, 10 - log(10, ref_attr_value * factor + offset)) as reference_attribute_value,
          to_unit_id as attribute_units,
          name,
          value,
          expression
          ||substr(' ', 1, length(unit_id))
          ||unit_id as expression,
          rate_expression
          ||substr(' ', 1, length(rate_unit_id))
          ||rate_unit_id
          ||substr(' per ', 1, length(rate_interval))
          ||substr(rate_interval, 2) as rate_expression,
          substr(minimum_duration, 2) as minimum_duration,
          substr(maximum_age, 2) as maximum_age
     from llic
          join lli on lli.level_indicator_code = llic.level_indicator_code
          join loc on loc.location_code = lli.location_code
          join base_loc on base_loc.base_location_code = loc.base_location_code
          join ofc on ofc.office_code = base_loc.db_office_code
          join param on param.parameter_code = lli.parameter_code
          join base_param on base_param.base_parameter_code = param.base_parameter_code
          join param_type on param_type.parameter_type_code = lli.parameter_type_code
          join dur on dur.duration_code = lli.duration_code
          join spec_level on spec_level.specified_level_code = lli.specified_level_code 
          left outer join attr_param on attr_param.parameter_code = lli.attr_parameter_code
          left outer join attr_base_param on attr_base_param.base_parameter_code = attr_param.base_parameter_code
          left outer join attr_param_type on attr_param_type.parameter_type_code = lli.attr_parameter_type_code
          left outer join attr_dur on attr_dur.duration_code = lli.attr_duration_code
          left outer join disp on disp.parameter_code = attr_base_param.base_parameter_code and disp.db_office_code = ofc.office_code
          left outer join conv on conv.from_unit_code = attr_base_param.unit_code and conv.to_unit_code = disp.display_unit_code
          left outer join ref_spec_level on ref_spec_level.specified_level_code = lli.ref_specified_level_code
          left outer join unit on unit.unit_code = llic.comparison_unit 
          left outer join rate_unit on rate_unit.rate_unit_code = llic.rate_comparison_unit     
 order by office_id,
          level_indicator_id,
          reference_level_id,
          attribute_id,
          unit_system,
          attribute_value,
          value;
/                  
show errors;

CREATE OR REPLACE FORCE VIEW av_location_level_indicator_2
AS
	with
	      llic1 as (
	      select level_indicator_code,
	             description as name,
	             expression,
	             comparison_operator_1 as op_1,
	             round(cast(comparison_value_1 as number), 10) as val_1,
	             connector,
	             comparison_operator_2 as op_2,
	             round(cast(comparison_value_2 as number), 10) as val_2,
	             comparison_unit,
	             rate_expression,
	             rate_comparison_operator_1 as rate_op_1,
	             round(cast(rate_comparison_value_1 as number), 10) as rate_val_1,
	             rate_connector,
	             rate_comparison_operator_2 as rate_op_2,
	             round(cast(rate_comparison_value_2 as number), 10) as rate_val_2,
	             rate_comparison_unit,
	             rate_interval
	        from at_loc_lvl_indicator_cond
		   where level_indicator_value = 1),
	      llic2 as (
	      select level_indicator_code,
                description as name,
                expression,
                comparison_operator_1 as op_1,
                round(cast(comparison_value_1 as number), 10) as val_1,
                connector,
                comparison_operator_2 as op_2,
                round(cast(comparison_value_2 as number), 10) as val_2,
                comparison_unit,
                rate_expression,
                rate_comparison_operator_1 as rate_op_1,
                round(cast(rate_comparison_value_1 as number), 10) as rate_val_1,
                rate_connector,
                rate_comparison_operator_2 as rate_op_2,
                round(cast(rate_comparison_value_2 as number), 10) as rate_val_2,
                rate_comparison_unit,
                rate_interval
	        from at_loc_lvl_indicator_cond
		   where level_indicator_value = 2),
	      llic3 as (
	      select level_indicator_code,
                description as name,
                expression,
                comparison_operator_1 as op_1,
                round(cast(comparison_value_1 as number), 10) as val_1,
                connector,
                comparison_operator_2 as op_2,
                round(cast(comparison_value_2 as number), 10) as val_2,
                comparison_unit,
                rate_expression,
                rate_comparison_operator_1 as rate_op_1,
                round(cast(rate_comparison_value_1 as number), 10) as rate_val_1,
                rate_connector,
                rate_comparison_operator_2 as rate_op_2,
                round(cast(rate_comparison_value_2 as number), 10) as rate_val_2,
                rate_comparison_unit,
                rate_interval
	        from at_loc_lvl_indicator_cond
		   where level_indicator_value = 3),
	      llic4 as (
	      select level_indicator_code,
                description as name,
                expression,
                comparison_operator_1 as op_1,
                round(cast(comparison_value_1 as number), 10) as val_1,
                connector,
                comparison_operator_2 as op_2,
                round(cast(comparison_value_2 as number), 10) as val_2,
                comparison_unit,
                rate_expression,
                rate_comparison_operator_1 as rate_op_1,
                round(cast(rate_comparison_value_1 as number), 10) as rate_val_1,
                rate_connector,
                rate_comparison_operator_2 as rate_op_2,
                round(cast(rate_comparison_value_2 as number), 10) as rate_val_2,
                rate_comparison_unit,
                rate_interval
	        from at_loc_lvl_indicator_cond
		   where level_indicator_value = 4),
	      llic5 as (
	      select level_indicator_code,
                description as name,
                expression,
                comparison_operator_1 as op_1,
                round(cast(comparison_value_1 as number), 10) as val_1,
                connector,
                comparison_operator_2 as op_2,
                round(cast(comparison_value_2 as number), 10) as val_2,
                comparison_unit,
                rate_expression,
                rate_comparison_operator_1 as rate_op_1,
                round(cast(rate_comparison_value_1 as number), 10) as rate_val_1,
                rate_connector,
                rate_comparison_operator_2 as rate_op_2,
                round(cast(rate_comparison_value_2 as number), 10) as rate_val_2,
                rate_comparison_unit,
                rate_interval
	        from at_loc_lvl_indicator_cond
		   where level_indicator_value = 5),
	      unit as (
	      select unit_code,
	             unit_id
	        from cwms_unit),
	      rate_unit as (
	      select unit_code as rate_unit_code,
	             unit_id as rate_unit_id
	        from cwms_unit),
	      lli as (
	      select *
	        from at_loc_lvl_indicator),
	      loc as (
	      select location_code,
	             base_location_code,
	             sub_location_id
	        from at_physical_location),
	      base_loc as (
	      select base_location_code,
	             base_location_id,
	             db_office_code
	        from at_base_location),
	      ofc as (
	      select office_code,
	             office_id
	        from cwms_office),
	      param as (
	      select parameter_code,
	             base_parameter_code,
	             sub_parameter_id
	        from at_parameter),
	      base_param as (
	      select base_parameter_code,
	             base_parameter_id
	        from cwms_base_parameter),
	      param_type as (
	      select parameter_type_code,
	             parameter_type_id
	        from cwms_parameter_type),
	      dur as (
	      select duration_code,
	             duration_id
	        from cwms_duration),
	      spec_level as (select * from at_specified_level),
	      attr_param as (
	      select parameter_code,
	             base_parameter_code,
	             sub_parameter_id
	        from at_parameter),
	      attr_base_param as (
	      select base_parameter_code,
	             base_parameter_id,
	             unit_code
	        from cwms_base_parameter),
	      attr_param_type as (
	      select parameter_type_code,
	             parameter_type_id
	        from cwms_parameter_type),
	      attr_dur as (
	      select duration_code,
	             duration_id
	        from cwms_duration),
	      disp as (select * from at_display_units),
	      conv as (select * from cwms_unit_conversion),
	      ref_spec_level as (select * from at_specified_level)
	   select office_id,
	          base_location_id
	          || substr('-', 1, length(sub_location_id))
	          || sub_location_id
	          ||'.' || base_param.base_parameter_id
	          || substr('-', 1, length(param.sub_parameter_id))
	          || param.sub_parameter_id
	          || '.' || param_type.parameter_type_id
	          || '.' || dur.duration_id
	          || '.' || spec_level.specified_level_id
	          || '.' || level_indicator_id as level_indicator_id,
	          ref_spec_level.specified_level_id as reference_level_id,
	          attr_base_param.base_parameter_id
	          || substr('-', 1, length(attr_param.sub_parameter_id))
	          || attr_param.sub_parameter_id
	          || substr('.', 1, length(attr_param_type.parameter_type_id))
	          || attr_param_type.parameter_type_id
	          || substr('.', 1, length(attr_dur.duration_id))
	          || attr_dur.duration_id as attribute_id,
	          unit_system,
	          round(attr_value * factor + offset, 10 - log(10, attr_value * factor + offset)) as attribute_value,
	          round(ref_attr_value * factor + offset, 10 - log(10, ref_attr_value * factor + offset)) as reference_attribute_value,
	          to_unit_id as attribute_units,
	          substr(minimum_duration, 2) as minimum_duration,
	          substr(maximum_age, 2) as maximum_age,
             unit_id,
             rate_unit_id,
	          llic1.name as cond_1_name,
	          llic1.expression as cond_1_expr,
             llic1.op_1 as cond_1_op_1,
             llic1.val_1 as cond_1_val_1,
             llic1.connector as cond_1_connector,
             llic1.op_2 as cond_1_op_2,
             llic1.val_2 as cond_1_val_2,
             llic1.rate_expression as cond_1_rate_expr,
             llic1.rate_op_1 as cond_1_rate_op_1,
             llic1.rate_val_1 as cond_1_rate_val_1,
             llic1.rate_connector as cond_1_rate_connector,
             llic1.rate_op_2 as cond_1_rate_op_2,
             llic1.rate_val_2 as cond_1_rate_val_2,
             llic1.rate_interval as cond_1_rate_interval,
             llic2.name as cond_2_name,
             llic2.expression as cond_2_expr,
             llic2.op_1 as cond_2_op_1,
             llic2.val_1 as cond_2_val_1,
             llic2.connector as cond_2_connector,
             llic2.op_2 as cond_2_op_2,
             llic2.val_2 as cond_2_val_2,
             llic2.rate_expression as cond_2_rate_expr,
             llic2.rate_op_1 as cond_2_rate_op_1,
             llic2.rate_val_1 as cond_2_rate_val_1,
             llic2.rate_connector as cond_2_rate_connector,
             llic2.rate_op_2 as cond_2_rate_op_2,
             llic2.rate_val_2 as cond_2_rate_val_2,
             llic2.rate_interval as cond_2_rate_interval,
             llic3.name as cond_3_name,
             llic3.expression as cond_3_expr,
             llic3.op_1 as cond_3_op_1,
             llic3.val_1 as cond_3_val_1,
             llic3.connector as cond_3_connector,
             llic3.op_2 as cond_3_op_2,
             llic3.val_2 as cond_3_val_2,
             llic3.rate_expression as cond_3_rate_expr,
             llic3.rate_op_1 as cond_3_rate_op_1,
             llic3.rate_val_1 as cond_3_rate_val_1,
             llic3.rate_connector as cond_3_rate_connector,
             llic3.rate_op_2 as cond_3_rate_op_2,
             llic3.rate_val_2 as cond_3_rate_val_2,
             llic3.rate_interval as cond_3_rate_interval,
             llic4.name as cond_4_name,
             llic4.expression as cond_4_expr,
             llic4.op_1 as cond_4_op_1,
             llic4.val_1 as cond_4_val_1,
             llic4.connector as cond_4_connector,
             llic4.op_2 as cond_4_op_2,
             llic4.val_2 as cond_4_val_2,
             llic4.rate_expression as cond_4_rate_expr,
             llic4.rate_op_1 as cond_4_rate_op_1,
             llic4.rate_val_1 as cond_4_rate_val_1,
             llic4.rate_connector as cond_4_rate_connector,
             llic4.rate_op_2 as cond_4_rate_op_2,
             llic4.rate_val_2 as cond_4_rate_val_2,
             llic4.rate_interval as cond_4_rate_interval,
             llic5.name as cond_5_name,
             llic5.expression as cond_5_expr,
             llic5.op_1 as cond_5_op_1,
             llic5.val_1 as cond_5_val_1,
             llic5.connector as cond_5_connector,
             llic5.op_2 as cond_5_op_2,
             llic5.val_2 as cond_5_val_2,
             llic5.rate_expression as cond_5_rate_expr,
             llic5.rate_op_1 as cond_5_rate_op_1,
             llic5.rate_val_1 as cond_5_rate_val_1,
             llic5.rate_connector as cond_5_rate_connector,
             llic5.rate_op_2 as cond_5_rate_op_2,
             llic5.rate_val_2 as cond_5_rate_val_2,
             llic5.rate_interval as cond_5_rate_interval
	     from llic1
	          join llic2 on llic2.level_indicator_code = llic1.level_indicator_code
	          join llic3 on llic3.level_indicator_code = llic1.level_indicator_code
	          join llic4 on llic4.level_indicator_code = llic1.level_indicator_code
	          join llic5 on llic5.level_indicator_code = llic1.level_indicator_code
	          join lli on lli.level_indicator_code = llic1.level_indicator_code
	          join loc on loc.location_code = lli.location_code
	          join base_loc on base_loc.base_location_code = loc.base_location_code
	          join ofc on ofc.office_code = base_loc.db_office_code
	          join param on param.parameter_code = lli.parameter_code
	          join base_param on base_param.base_parameter_code = param.base_parameter_code
	          join param_type on param_type.parameter_type_code = lli.parameter_type_code
	          join dur on dur.duration_code = lli.duration_code
	          join spec_level on spec_level.specified_level_code = lli.specified_level_code
	          left outer join attr_param on attr_param.parameter_code = lli.attr_parameter_code
	          left outer join attr_base_param on attr_base_param.base_parameter_code = attr_param.base_parameter_code
	          left outer join attr_param_type on attr_param_type.parameter_type_code = lli.attr_parameter_type_code
	          left outer join attr_dur on attr_dur.duration_code = lli.attr_duration_code
	          left outer join disp on disp.parameter_code = attr_base_param.base_parameter_code and disp.db_office_code = ofc.office_code
	          left outer join conv on conv.from_unit_code = attr_base_param.unit_code and conv.to_unit_code = disp.display_unit_code
	          left outer join ref_spec_level on ref_spec_level.specified_level_code = lli.ref_specified_level_code
	          left outer join unit on unit.unit_code = llic1.comparison_unit
	          left outer join rate_unit on rate_unit.rate_unit_code = llic1.rate_comparison_unit
	 order by office_id,
	          level_indicator_id,
	          reference_level_id,
	          attribute_id,
	          unit_system,
	          attribute_value;
/                  
show errors;

create or replace force view av_dataexchange_job as
   with 
   request$ as (
      select p1.msg_id,
             p1.prop_text as job_id,
             p3.prop_text as set_id,
             p4.prop_text as to_dss,
             m.log_timestamp_utc,
             o.office_id,
             m.host
        from at_log_message m,
              cwms_office o,
              at_log_message_properties p1,
              at_log_message_properties p2,
              at_log_message_properties p3,
              at_log_message_properties p4,
              cwms_log_message_types t
       where p1.prop_name = 'job_id'
         and p2.prop_name = 'subtype'
         and p3.prop_name = 'set_id'
         and p4.prop_name = 'to_dss'
         and p2.prop_text = 'BatchExchange'
         and p2.msg_id = p1.msg_id
         and p3.msg_id = p1.msg_id
         and p4.msg_id = p1.msg_id
         and t.message_type_id = 'RequestAction'
         and m.msg_type = t.message_type_code
         and m.msg_id = p1.msg_id
         and o.office_code = m.office_code),
   start$ as (
      select p1.msg_id,
             p1.prop_text as job_id,
             m.log_timestamp_utc
        from at_log_message m,
              cwms_office o,
              at_log_message_properties p1,
              at_log_message_properties p2,
              cwms_log_message_types t
       where p1.prop_name = 'job_id'
         and p2.prop_name = 'subtype'
         and p2.prop_text = 'BatchStarting'
         and p2.msg_id = p1.msg_id
         and t.message_type_id = 'Status'
         and m.msg_type = t.message_type_code
         and m.msg_id = p1.msg_id
         and o.office_code = m.office_code),
   complete$ as (
      select p1.msg_id,
             p1.prop_text as job_id,
             m.log_timestamp_utc,
             m.instance,
             m.msg_text
        from at_log_message m,
              cwms_office o,
              at_log_message_properties p1,
              at_log_message_properties p2,
              cwms_log_message_types t
       where p1.prop_name = 'job_id'
         and p2.prop_name = 'subtype'
         and p2.prop_text = 'BatchCompleted'
         and p2.msg_id = p1.msg_id
         and t.message_type_id = 'Status'
         and m.msg_type = t.message_type_code
         and m.msg_id = p1.msg_id
         and o.office_code = m.office_code)
   select request$.job_id,
          request$.host as requested_from,
          request$.office_id || '/' || request$.set_id as set_id,
          case request$.to_dss
            when 'true'  then 'extract'
            when 'false' then 'post'
          end as direction,
          request$.log_timestamp_utc as request_time,
          start$.log_timestamp_utc as start_time,
          complete$.log_timestamp_utc as end_time,
          start$.log_timestamp_utc - request$.log_timestamp_utc as start_delay,
          complete$.log_timestamp_utc - start$.log_timestamp_utc as execution_time,
          complete$.log_timestamp_utc - request$.log_timestamp_utc as total_time,
          complete$.instance as processed_by,
          complete$.msg_text as results
     from request$
          left outer join start$ on start$.job_id = request$.job_id
          left outer join complete$ on complete$.job_id = request$.job_id           
 order by request$.log_timestamp_utc desc;
/
show errors;
