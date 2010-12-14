create or replace package cwms_rating
as

--------------------------------------------------------------------------------
-- INDIVIDUAL RATING TEMPLATES
--
procedure store_rating_template(
   p_xml            in xmltype,
   p_fail_if_exists in varchar2);

procedure store_rating_template(
   p_xml            in varchar2,
   p_fail_if_exists in varchar2);

procedure store_rating_template(
   p_xml            in clob,
   p_fail_if_exists in varchar2);

procedure store_rating_template(
   p_rating_template in rating_template_t,
   p_fail_if_exists  in varchar2);

--------------------------------------------------------------------------------
-- INDIVIDUAL RATING SPECIFICATIONS
--
procedure store_rating_spec(
   p_xml            in xmltype,
   p_fail_if_exists in varchar2);

procedure store_rating_spec(
   p_xml            in varchar2,
   p_fail_if_exists in varchar2);

procedure store_rating_spec(
   p_xml            in clob,
   p_fail_if_exists in varchar2);

procedure store_rating_spec(
   p_rating_spec    in rating_spec_t,
   p_fail_if_exists in varchar2);
   
--------------------------------------------------------------------------------
-- INDIVIDUAL RATINGS
--
procedure store_rating(
   p_xml            in xmltype,
   p_fail_if_exists in varchar2);

procedure store_rating(
   p_xml            in varchar2,
   p_fail_if_exists in varchar2);

procedure store_rating(
   p_xml            in clob,
   p_fail_if_exists in varchar2);
   
procedure store_rating(
   p_rating         in rating_t,
   p_fail_if_exists in varchar2);   
   
procedure store_rating(
   p_rating         in stream_rating_t,
   p_fail_if_exists in varchar2);   
   
--------------------------------------------------------------------------------
-- MULTIPLE TEMPLATES/SPECIFICATIONS/RATINGS 
--
procedure store_ratings_xml(
   p_xml            in xmltype,
   p_fail_if_exists in varchar2);
   
end;
/
show errors;
