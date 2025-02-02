create or replace TYPE project_obj_t
/**
 * Holds information about a CWMS project
 *
 * @member project_location               Location identifier of project
 * @member pump_back_location             Location identifier of pump-back to this project, if any
 * @member near_gage_location             Location identifier of the nearest gage to the project
 * @member authorizing_law                The law that authorized construction of the project
 * @member cost_year                      Year that costs are indexed to
 * @member federal_cost                   Federal cost to construct the project
 * @member nonfederal_cost                Non-federal cost to construct the project
 * @member federal_om_cost                Federal cost of annual operation and maintenance
 * @member nonfederal_om_cost             Non-federal cost of annual operation and maintenance
 * @member cost_units_id                  Unit of costs
 * @member remarks                        General remarks about project
 * @member project_owner                  Owner of the project
 * @member hydropower_description         Description of the hydopower at this project, if applicable
 * @member sedimentation_description      Description of the sedimentation at this project, if applicable
 * @member downstream_urban_description   Description of urbanization downstream of this project, if applicable
 * @member bank_full_capacity_description Description of the bank-full capacity at th is project, if applicable
 * @member yield_time_frame_start         Beginning of time window for critical period for this project
 * @member yield_time_frame_end           End of time window for critical period for this project
 */
AS
  OBJECT
  (

    --locations
    --the location associated with this project,
    --an instance of the location type.
    --has the db office id for this project.
    project_location location_obj_t,
    --The location code where the water is pumped back to
    pump_back_location location_obj_t,
    --The location code known as the near gage for the project
    near_gage_location location_obj_t,
    --The law authorizing this project
    authorizing_law VARCHAR2(32),
    --The year the project cost data is from
    cost_year DATE,
    federal_cost       NUMBER, --Param: Currency. The federal cost of this project
    nonfederal_cost    NUMBER, --Param: Currency. The non-federal cost of this project
    federal_om_cost    NUMBER, --Param: Currency. The om federal cost of this project
    nonfederal_om_cost NUMBER, --Param: Currency. the non-federal cost of this project
    -- the units id of the cost fields.
    cost_units_id VARCHAR2(16),
    --The general remarks regarding this project
    --Should this be a  CLOB?
    remarks VARCHAR2(1000),
    --The assigned owner of this project
    project_owner VARCHAR2(255),
    --The description of the hydro-power located at this project
    hydropower_description VARCHAR2(255),
    --The description of the projects sedimentation
    sedimentation_description VARCHAR2(255),
    --The description of the urban area downstream
    downstream_urban_description VARCHAR2(255),
    --The description of the full capacity
    bank_full_capacity_description VARCHAR2(255),
    --The start date of the yield time frame
    yield_time_frame_start DATE,
    --The end date of the yield time frame
    yield_time_frame_end DATE,
    
   constructor function project_obj_t(
      self                             in out nocopy project_obj_t,
      p_project_location               in            location_obj_t,
      p_pump_back_location             in            location_obj_t,
      p_near_gage_location             in            location_obj_t,
      p_authorizing_law                in            varchar2,
      p_cost_year                      in            date,
      p_federal_cost                   in            number,
      p_nonfederal_cost                in            number,
      p_federal_om_cost                in            number,
      p_nonfederal_om_cost             in            number,
      p_remarks                        in            varchar2,
      p_project_owner                  in            varchar2,
      p_hydropower_description         in            varchar2,
      p_sedimentation_description      in            varchar2,
      p_downstream_urban_description   in            varchar2,
      p_bank_full_capacity_descript    in            varchar2,
      p_yield_time_frame_start         in            date,
      p_yield_time_frame_end           in            date)
      return self as result       
   )
/

create or replace public synonym cwms_t_project_obj for project_obj_t;

