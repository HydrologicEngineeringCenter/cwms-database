create type vdatum_stream_rating_t
/**
 * Holds a USGS-style stream rating with vertical datum information
 *
 * @see type rating_t
 *
 * @member native_datum   The location's vertical datum in the datbase
 * @member current_datum  The vertical datum the rating is currently represented in
 * @member elev_positions A table of positions in the parameter list that are elevations. Positive positions indicate independent parameters, -1 indicates the dependent parameter.
 */
under stream_rating_t
(
-- office_id      varchar2(16),
-- rating_spec_id varchar2(372),
-- effective_date date,
-- create_date    date,
-- active_flag    varchar2(1),
-- formula        varchar2(1000),
-- native_units   varchar2(256),
-- description    varchar2(256),
-- rating_info    rating_ind_parameter_t,
-- current_units  varchar2(1), -- 'D' = database, 'N' = native, other = don't know
-- current_time   varchar2(2), -- 'D' = database, 'L' = native, other = don't know
-- offsets        rating_t,
-- shifts         rating_tab_t,
   native_datum   varchar2(16),
   current_datum  varchar2(16),
   elev_position  number,  
                           
   /**
    * Constructs a vdatum_stream_rating_t object from a stream_rating_t object and a current datum
    *
    * @param p_rating         The existing stream_rating_t object
    * @param p_current_datum  The current datum that the rating object is represented in
    *
    */
   constructor function vdatum_stream_rating_t(
      p_rating         in stream_rating_t,
      p_current_datum  in varchar2
   ) return self as result,   
   /**
    * Copy constructor
    */
   constructor function vdatum_stream_rating_t(
      p_other in vdatum_stream_rating_t
   ) return self as result,
   /**
    * Modifies the elevations in the rating to be in the specified datum
    *
    * @param p_vertical_datum The vertical datum to adjust the elevations to
    */   
   member procedure to_vertical_datum(
      p_vertical_datum in varchar2),
   /**
    * Modifies the elevations in the rating to be in the location's local datum
    */      
   member procedure to_native_datum,
   /**
    * Retrieves the rating as an XML instance in an CLOB object
    *
    * @return the rating as an XML instance in an CLOB object
    */
   overriding member function to_clob(
      self         in out nocopy vdatum_stream_rating_t,
      p_timezone   in varchar2 default null,
      p_units      in varchar2 default null,
      p_vert_datum in varchar2 default null)
      return clob,
   /**
    * Retrieves the rating as an XML instance in an XMLTYPE object
    *
    * @return the rating as an XML instance in an XMLTYPE object
    */
   overriding member function to_xml(
      self         in out nocopy vdatum_stream_rating_t,
      p_timezone   in varchar2 default null,
      p_units      in varchar2 default null,
      p_vert_datum in varchar2 default null)
      return xmltype      
);
/


create or replace public synonym cwms_t_vdatum_stream_rating for vdatum_stream_rating_t;

