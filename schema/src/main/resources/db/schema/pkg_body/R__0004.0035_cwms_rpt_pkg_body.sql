create or replace package body cwms_rpt

is

-------------------------------------------------------------------------------
--
-- CLOB function REPORT_
--
-- This function serves as an interface between the REPORT function with the
-- same signature and the Java code, allowing the PL/SQL function to use
-- default arguments.
--
function report_(
   p_cursor         in sys_refcursor,
   p_template_id    in varchar2,
   p_missing_string in varchar2)
   return           clob
is language java name
'cwmsdb.ReportGenerator.generateReport(
   java.sql.ResultSet,
   java.lang.String,
   java.lang.String)
return oracle.sql.CLOB';

-------------------------------------------------------------------------------
--
-- CLOB function REPORT_
--
-- This function serves as an interface between the REPORT function with the
-- same signature and the Java code, allowing the PL/SQL function to use
-- default arguments.
--
function report_(
   p_cursor          in sys_refcursor,
   p_header_template in varchar2,
   p_record_template in varchar2,
   p_footer_template in varchar2,
   p_missing_string  in varchar2)
   return           clob
is language java name
'cwmsdb.ReportGenerator.generateReport(
   java.sql.ResultSet,
   java.lang.String,
   java.lang.String,
   java.lang.String,
   java.lang.String)
return oracle.sql.CLOB';

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
   p_template_id     in  varchar2)

is

begin

   select header_template,
          record_template,
          footer_template
   into   p_header_template,
          p_record_template,
          p_footer_template
   from   at_report_templates
   where  id = p_template_id;

   p_header_template := nvl(p_header_template, '');
   p_record_template := nvl(p_record_template, '');
   p_footer_template := nvl(p_footer_template, '');

exception

   when no_data_found then
      p_header_template := '';
      p_record_template := '';
      p_footer_template := '';

end get_report_templates;

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
-- This function calls the report_ function to perform the actual work because
-- Java cannot take default values.
--
-- The report is returned as a CLOB.
--
function report(
   p_cursor         in sys_refcursor,
   p_template_id    in varchar2,
   p_missing_string in varchar2 default '-M-')
   return           clob

is

begin

   return report_(p_cursor, p_template_id, p_missing_string);

end report;

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
-- This function calls the report_ function to perform the actual work because
-- Java cannot take default values.
--
-- The report is returned as a CLOB.
--
function report(
   p_cursor          in sys_refcursor,
   p_header_template in varchar2,
   p_record_template in varchar2,
   p_footer_template in varchar2,
   p_missing_string  in varchar2 default '-M-')
   return           clob

is

begin

   return report_(p_cursor, p_header_template, p_record_template, p_footer_template, p_missing_string);

end report;

end cwms_rpt;
/
