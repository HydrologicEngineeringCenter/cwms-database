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
                     'av_loc_alias',
                     'av_loc_cat_grp',
                     'av_parameter',
                     'av_screened_ts_ids',
                     'av_screening_assignments',
                     'av_screening_criteria',
                     'av_screening_dur_mag',
                     'av_screening_id',
                     'av_shef_decode_spec'
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

GRANT SELECT ON av_screening_criteria TO cwms_dev
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
CREATE OR REPLACE VIEW av_shef_decode_spec (ts_code,
                                            cwms_ts_id,
                                            data_stream_id,
                                            db_office_id,
                                            loc_group_id,
                                            loc_category_id,
                                            loc_alias_id,
                                            shef_pe_code,
                                            shef_tse_code,
                                            shef_duration_code,
                                            shef_time_zone_id,
                                            dl_time,
                                            unit_id,
                                            interval_utc_offset,
                                            interval_forward,
                                            interval_backward,
                                            active_flag
                                           )
AS
   SELECT a.ts_code, b.cwms_ts_id, c.data_stream_id, b.db_office_id,
          e.loc_group_id, f.loc_category_id,
          CASE
             WHEN d.loc_alias_id IS NULL
                THEN b.location_id
             ELSE d.loc_alias_id
          END loc_alias_id,
          a.shef_pe_code, a.shef_tse_code, a.shef_duration_code,
          g.shef_time_zone_id, a.dl_time, i.unit_id,
          CASE
             WHEN h.interval_utc_offset = -2147483648
                THEN 'N/A'
             WHEN h.interval_utc_offset = 2147483647
                THEN 'Undefined'
             ELSE TO_CHAR (h.interval_utc_offset,
                           '9999999999'
                          )
          END interval_utc_offset,
          h.interval_forward, h.interval_backward, h.active_flag
     FROM at_shef_decode a,
          mv_cwms_ts_id b,
          at_data_stream_id c,
          at_loc_group_assignment d,
          at_loc_group e,
          at_loc_category f,
          cwms_shef_time_zone g,
          at_cwms_ts_spec h,
          cwms_unit i
    WHERE a.ts_code = b.ts_code
      AND a.data_stream_code = c.data_stream_code
      AND a.loc_group_code = d.loc_group_code
      AND a.location_code = d.location_code
      AND d.loc_group_code = e.loc_group_code
      AND e.loc_category_code = f.loc_category_code
      AND a.shef_time_zone_code = g.shef_time_zone_code
      AND a.ts_code = h.ts_code
      AND a.shef_unit_code = i.unit_code
/