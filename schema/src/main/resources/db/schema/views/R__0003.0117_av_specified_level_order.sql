/**
 * Displays AV_SPECIFIED_LEVEL_ORDER information
 *
 * @since CWMS 2.1
 *
 * @field db_office_id               The..
 * @field office_code                The..
 * @field specified_level_code       The..
 * @field specified_level_id         The..
 * @field description                The..
 * @field sort_order                 The..
 */
CREATE OR REPLACE VIEW av_specified_level_order
(
   db_office_id,
   office_code,
   specified_level_code,
   specified_level_id,
   description,
   sort_order
)
AS
   SELECT o.office_id db_office_id,
          o.office_code,
          slo.specified_level_code,
          sl.specified_level_id,
          sl.description,
          slo.sort_order
     FROM at_sPECIFIED_LEVEL_order slo, at_specified_level sl, cwms_office o
    WHERE     slo.specified_level_code = sl.specified_level_code
          AND slo.office_code = o.office_code
/
