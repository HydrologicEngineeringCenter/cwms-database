create or replace package cwms_rpt

is

-------------------------------------------------------------------------------
--
-- procedure GET_REPORT_TEMPLATES
--
-- This procedure retieves header, record and footer templates associated
-- in the database with the specified report template id.
--
procedure get_report_templates(
   p_header_template out varchar2,
   p_record_template out varchar2,
   p_footer_template out varchar2,
   p_template_id     in  varchar2);

-------------------------------------------------------------------------------
--
-- CLOB function REPORT
--
-- This function generates a text report from the records in the supplied
-- cursor according to the report templates associated in the database with
-- the specified report template id.
--
-- Any missing (null) values in the records will be replaced with the text
-- specified by the p_missing_string parameter.
--
-- The report is returned as a CLOB.
--
function report(
   p_cursor         in sys_refcursor,
   p_template_id    in varchar2,
   p_missing_string in varchar2 default '-M-')
   return           clob;

-------------------------------------------------------------------------------
--
-- CLOB function REPORT
--
-- This function generates a text report from the records in the supplied
-- cursor according to the report templates specified in the p_xxx_template
-- parameters.
--
-- Any missing (null) values in the records will be replaced with the text
-- specified by the p_missing_string parameter.
--
-- The report is returned as a CLOB.
--
function report(
   p_cursor          in sys_refcursor,
   p_header_template in varchar2,
   p_record_template in varchar2,
   p_footer_template in varchar2,
   p_missing_string  in varchar2 default '-M-')
   return           clob;

end cwms_rpt;
/
