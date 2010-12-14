create or replace package body cwms_rating
as
--------------------------------------------------------------------------------
-- INDIVIDUAL RATING TEMPLATES
--
procedure store_rating_template(
   p_xml            in xmltype,
   p_fail_if_exists in varchar2)
is
   l_rating_template rating_template_t;
begin
   l_rating_template := rating_template_t(p_xml);
   l_rating_template.store(p_fail_if_exists);
end store_rating_template;   

procedure store_rating_template(
   p_xml            in varchar2,
   p_fail_if_exists in varchar2)
is
begin
   store_rating_template(xmltype(p_xml), p_fail_if_exists);
end store_rating_template;   

procedure store_rating_template(
   p_xml            in clob,
   p_fail_if_exists in varchar2)
is
begin
   store_rating_template(xmltype(p_xml), p_fail_if_exists);
end store_rating_template;

procedure store_rating_template(
   p_rating_template in rating_template_t,
   p_fail_if_exists  in varchar2)
is
   l_rating_template rating_template_t := p_rating_template;
begin
   l_rating_template.store(p_fail_if_exists);
end store_rating_template;   

--------------------------------------------------------------------------------
-- INDIVIDUAL RATING SPECIFICATIONS
--
procedure store_rating_spec(
   p_xml            in xmltype,
   p_fail_if_exists in varchar2)
is
   l_rating_spec rating_spec_t;
begin
   l_rating_spec := rating_spec_t(p_xml);
   l_rating_spec.store(p_fail_if_exists);
end store_rating_spec;   

procedure store_rating_spec(
   p_xml            in varchar2,
   p_fail_if_exists in varchar2)
is
begin
   store_rating_spec(xmltype(p_xml), p_fail_if_exists);
end store_rating_spec;   

procedure store_rating_spec(
   p_xml            in clob,
   p_fail_if_exists in varchar2)
is
begin
   store_rating_spec(xmltype(p_xml), p_fail_if_exists);
end store_rating_spec;

procedure store_rating_spec(
   p_rating_spec    in rating_spec_t,
   p_fail_if_exists in varchar2)
is
   l_rating_spec rating_spec_t := p_rating_spec;
begin
   l_rating_spec.store(p_fail_if_exists);
end store_rating_spec;   

--------------------------------------------------------------------------------
-- INDIVIDUAL RATINGS
--
procedure store_rating(
   p_xml            in xmltype,
   p_fail_if_exists in varchar2)
is
   l_rating        rating_t;
   l_stream_rating stream_rating_t;
begin
   if p_xml.existsnode('/rating') = 1 then
      l_rating := rating_t(p_xml);
      l_rating.store(p_fail_if_exists);
   elsif p_xml.existsnode('/usgs-stream-rating') = 1 then
      l_stream_rating := stream_rating_t(p_xml);
      l_stream_rating.store(p_fail_if_exists);
   else
      cwms_err.raise(
         'ERROR',
         'XML cannot be parsed as valid rating_t or stream_rating_t object');
   end if;
end store_rating;   

procedure store_rating(
   p_xml            in varchar2,
   p_fail_if_exists in varchar2)
is
begin
   store_rating(xmltype(p_xml), p_fail_if_exists);
end store_rating;   

procedure store_rating(
   p_xml            in clob,
   p_fail_if_exists in varchar2)
is
begin
   store_rating(xmltype(p_xml), p_fail_if_exists);
end store_rating;
   
procedure store_rating(
   p_rating         in rating_t,
   p_fail_if_exists in varchar2)
is
   l_rating rating_t := p_rating;
begin
   l_rating.store(p_fail_if_exists);
end store_rating;      
   
procedure store_rating(
   p_rating         in stream_rating_t,
   p_fail_if_exists in varchar2)
is
   l_rating stream_rating_t := p_rating;
begin
   l_rating.store(p_fail_if_exists);
end store_rating;      
   
--------------------------------------------------------------------------------
-- MULTIPLE TEMPLATES/SPECIFICATIONS/RATINGS 
--
procedure store_ratings_xml(
   p_xml            in xmltype,
   p_fail_if_exists in varchar2)
is
   l_xml  xmltype;
   l_node xmltype;
   l_rating rating_t;
begin
   l_xml := cwms_util.get_xml_node(p_xml, '/ratings');
   if l_xml is null then
      cwms_err.raise('ERROR', 'XML does not have <ratings> root element');
   end if;
   cwms_msg.log_db_message(
      'cwms_rating.store_ratings_xml',
      cwms_msg.msg_level_verbose,
      'Processing ratings XML');
   for i in 1..9999999 loop
      l_node := cwms_util.get_xml_node(l_xml, '/ratings/rating-template['||i||']');
      exit when l_node is null;
      cwms_msg.log_db_message(
         'cwms_rating.store_ratings_xml',
         cwms_msg.msg_level_verbose,
         'Processing rating template ' || i);
      begin
         store_rating_template(l_node, p_fail_if_exists);
      exception
         when others then
            cwms_msg.log_db_message(
               'cwms_rating.store_ratings_xml',
               cwms_msg.msg_level_normal,
               sqlerrm);
            cwms_msg.log_db_message(
               'cwms_rating.store_ratings_xml',
               cwms_msg.msg_level_detailed,
               dbms_utility.format_error_backtrace);
      end;
   end loop;
   commit;
   for i in 1..9999999 loop
      l_node := cwms_util.get_xml_node(l_xml, '/ratings/rating-spec['||i||']');
      exit when l_node is null;
      cwms_msg.log_db_message(
         'cwms_rating.store_ratings_xml',
         cwms_msg.msg_level_verbose,
         'Processing rating specification ' || i);
      begin
         store_rating_spec(l_node, p_fail_if_exists);
      exception
         when others then
            cwms_msg.log_db_message(
               'cwms_rating.store_ratings_xml',
               cwms_msg.msg_level_normal,
               sqlerrm);
            cwms_msg.log_db_message(
               'cwms_rating.store_ratings_xml',
               cwms_msg.msg_level_detailed,
               dbms_utility.format_error_backtrace);
      end;
   end loop;
   commit;
   for i in 1..9999999 loop
      l_node := cwms_util.get_xml_node(l_xml, '/ratings/rating['||i||']');
      exit when l_node is null;
      cwms_msg.log_db_message(
         'cwms_rating.store_ratings_xml',
         cwms_msg.msg_level_verbose,
         'Processing rating ' || i);
      begin
         store_rating(l_node, p_fail_if_exists);
      exception
         when others then
            cwms_msg.log_db_message(
               'cwms_rating.store_ratings_xml',
               cwms_msg.msg_level_normal,
               sqlerrm);
            cwms_msg.log_db_message(
               'cwms_rating.store_ratings_xml',
               cwms_msg.msg_level_detailed,
               dbms_utility.format_error_backtrace);
      end;
   end loop;
   commit;
   for i in 1..999999 loop
      l_node := cwms_util.get_xml_node(l_xml, '/ratings/usgs-stream-rating['||i||']');
      exit when l_node is null;
      cwms_msg.log_db_message(
         'cwms_rating.store_ratings_xml',
         cwms_msg.msg_level_verbose,
         'Processing stream rating ' || i);
      begin
         store_rating(l_node, p_fail_if_exists);
      exception
         when others then
            cwms_msg.log_db_message(
               'cwms_rating.store_ratings_xml',
               cwms_msg.msg_level_normal,
               sqlerrm);
            cwms_msg.log_db_message(
               'cwms_rating.store_ratings_xml',
               cwms_msg.msg_level_detailed,
               dbms_utility.format_error_backtrace);
      end;
   end loop;
   commit;
end store_ratings_xml;

end;
/
show errors;
