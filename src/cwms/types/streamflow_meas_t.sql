set define off
create type streamflow_meas_t
/**
 * Holds a stream flow measurement
 * @since CWMS 3.0
 *
 * @member location       The location for this measurement
 * @member meas_number    The serial number of the measurement
 * @member date_time      The date and time the measurement was performed
 * @member used           Flag (T/F) indicating if the discharge measurement is marked as used
 * @member party          The person(s) that performed the measurement
 * @member agency_id      The agency that performed the measurement
 * @member gage_height    Gage height as shown on the inside staff gage or read off the recorder inside the gage house
 * @member flow           The computed discharge
 * @member cur_rating_num The number of the rating used to calculate the streamflow from the gage height
 * @member shift_used     The current shift being applied to the rating
 * @member pct_diff       The percent difference between the measurement and the rating with the shift applied
 * @member quality        The relative quality of the measurement
 * @member delta_height   The amount the gage height changed while the measurement was being made
 * @member delta_time     The amount of time elapsed while the measurement was being made (hours)
 * @member ctrl_cond_id   The condition of the rating control at the time of the measurement
 * @member flow_adj_id    The adjustment code for the measured discharge
 * @member remarks        Any remarks about the rating
 * @member time_zone      The time zone of the date_time field    
 * @member height_unit    The unit of the gage_height, shift_used, and delta_height fields
 * @member flow_unit      The unit of the flow field
 */
as object (
   location       location_ref_t,
   meas_number    integer,
   date_time      date,
   used           varchar2(1),
   party          varchar2(12),
   agency_id      varchar2(6),
   gage_height    binary_double,
   flow           binary_double,
   cur_rating_num varchar2(4),
   shift_used     binary_double,
   pct_diff       binary_double,
   quality        varchar2(1),
   delta_height   binary_double,
   delta_time     binary_double,
   ctrl_cond_id   varchar2(4),
   flow_adj_id    varchar2(4),
   remarks        varchar2(256),
   time_zone      varchar2(28),
   height_unit    varchar2(16),
   flow_unit      varchar2(16),
   
   /**
    * Constructs a streamflow_meas_t object from one record of a rdb-formated measurement from USGS NWIS
    *
    * @param p_rdb_line   The rdb-formatted record
    * @param p_office_id  The office to construct the measurement for. If not specified or NULL, the session user's default office is used
    */
   constructor function streamflow_meas_t (
      p_rdb_line  in varchar2,
      p_office_id in varchar2 default null)
      return self as result,
   /**
    * Contstucts a streamflow_meas_t object from an XML document.
    *
    * @param p_xml The XML document. The format required is like:
    * <pre><big>
    * &lt;stream-flow-measurement office-id="SWT" height-unit="ft" flow-unit="cfs" used="true"&gt;
    *   &lt;location&gt;TULA&lt;/location&gt;
    *   &lt;number&gt;1737&lt;/number&gt;
    *   &lt;date&gt;2014-01-14T17:08:30Z&lt;/date&gt;
    *   &lt;agency&gt;USGS&lt;/agency&gt;
    *   &lt;party&gt;WZM/JEP&lt;/party&gt;
    *   &lt;gage-height&gt;.81&lt;/gage-height&gt;
    *   &lt;flow&gt;221&lt;/flow&gt;
    *   &lt;current-rating&gt;19.0&lt;/current-rating&gt;
    *   &lt;shift-used&gt;.88&lt;/shift-used&gt;
    *   &lt;percent-difference&gt;61.3&lt;/percent-difference&gt;
    *   &lt;quality&gt;Fair&lt;/quality&gt;
    *   &lt;delta-height&gt;-.02&lt;/delta-height&gt;
    *   &lt;delta-time&gt;1.07&lt;/delta-time&gt;
    *   &lt;control-condition&gt;CLER&lt;/control-condition&gt;
    *   &lt;flow-adjustment&gt;MEAS&lt;/flow-adjustment&gt;
    *   &lt;remarks/&gt;
    * &lt;/stream-flow-measurement&gt;
    * </big></pre>
    */
   constructor function streamflow_meas_t (
      p_xml in xmltype)
      return self as result,       
   /**
    * Contstucts a streamflow_meas_t object from an entry in the CWMS database
    *
    * @param p_location    The location of the measurements
    * @param p_date_time   The date and time of the measuerement
    * @param p_unit_system The unit system (EN/SI) for the height and flow values
    * @param p_time_zone   The time zone of the p_date_time parameter. If not specified or NULL, the location's time zone is use 
    */
   constructor function streamflow_meas_t (
      p_location    in location_ref_t,
      p_date_time   in date,
      p_unit_system in varchar2 default 'EN',
      p_time_zone   in varchar2 default null)
      return self as result,      
   /**
    * Contstucts a streamflow_meas_t object from an entry in the CWMS database
    *
    * @param p_location    The location of the measurements
    * @param p_date_time   The serial number of the measurement
    * @param p_unit_system The unit system (EN/SI) for the height and flow values
    */
   constructor function streamflow_meas_t (
      p_location    in location_ref_t,
      p_meas_number in integer,
      p_unit_system in varchar2 default 'EN')
      return self as result,
   /**
    * Contstucts a streamflow_meas_t object from an entry in the CWMS database
    *
    * @param p_rowid       The row identifier of the measurement's record in the AT_STREAMFLOW_MEAS table. 
    * @param p_unit_system The unit system (EN/SI) for the height and flow values
    */
   constructor function streamflow_meas_t (
      p_rowid       in urowid,
      p_unit_system in varchar2 default 'EN')
      return self as result,
   /**
    * Sets the height unit for the streamflow_meas_t object, converting all heights to the specified unit
    *
    * @param h_height_unit The height unit to use.  If 'EN' or 'SI' are specified, the height unit is set to the default for or Engilsh or SI unit system, respectively
    */ 
   member procedure set_height_unit(
      p_height_unit in varchar2),
   /**
    * Sets the flow unit for the streamflow_meas_t object, converting the flow to the specified unit
    *
    * @param h_flow_unit The flow unit to use.  If 'EN' or 'SI' are specified, the flow unit is set to the default for or Engilsh or SI unit system, respectively
    */ 
   member procedure set_flow_unit(
      p_flow_unit in varchar2),
   /**
    * Sets the time zone for the streamflow_meas_t object, converting the date_time field.
    *
    * @param p_time_zone The time zone to use. If not specified or NULL, the measurement location's local time zone is used.
    */
   member procedure set_time_zone(
      p_time_zone in varchar2 default null),
   /**
    * Stores a streamflow_meas_t object to the database
    */
   member procedure store(
      p_fail_if_exists varchar2),
   /**
    * Returns a streamflow_meas_t object as an XMLTYPE
    *
    * @return The object as an XMLTYPE
    */
   member function to_xml
      return xmltype,
   /**
    * Returns a streamflow_meas_t object as a VARCHAR2.  The preferred name of to_string
    * cause conlicts with JPublisher-generated Java function toString().
    *
    * @return The object as a VARCHAR2
    */
   member function to_string1
      return varchar2         
);
/

show errors

create or replace public synonym cwms_t_streamflow_meas for streamflow_meas_t;

