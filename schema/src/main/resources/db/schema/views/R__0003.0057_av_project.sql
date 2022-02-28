/**
 * Displays information on CWMS projects
 *
 * @since CWMS 2.1
 *
 * @field office_id                      Office owning the project
 * @field project_id                     Location identifier of the project
 * @field federal_cost                   Federal cost to construct
 * @field nonfederal_cost                Non-federal cost to construct
 * @field authorizing_law                Law authorizing construction
 * @field project_owner                  Owner of project
 * @field hydropower_description         Description of hydropower for project, if applicable
 * @field sedimentation_description      Description of sedimentation for project, if applicable
 * @field downstream_urban_description   Description of downstream urbanization for project, if applicable
 * @field bank_full_capacity_description Description of bank-full capacity of project, if applicable
 * @field pump_back_location_id          Location identifier of pump-back into project, if applicable
 * @field near_gage_location_id          Location identifier of gaging station nearest to project
 * @field yield_time_frame_start         Beginning of critical period for yield analysis, if applicable
 * @field yield_time_frame_end           End of critical period for yield analysis, if applicable
 * @field project_remarks                General remarks for project
 */
create or replace force view av_project
(
   office_id,
   project_id,
   federal_cost,
   nonfederal_cost,
   authorizing_law,
   project_owner,
   hydropower_description,
   sedimentation_description,
   downstream_urban_description,
   bank_full_capacity_description,
   pump_back_location_id,
   near_gage_location_id,
   yield_time_frame_start,
   yield_time_frame_end,
   project_remarks
)
as
select project.office_id,
       project.location_id as project_id,
       project.federal_cost,
       project.nonfederal_cost,authorizing_law,
       project.project_owner,
       project.hydropower_description,
       project.sedimentation_description,
       project.downstream_urban_description,
       project.bank_full_capacity_description,
       pumpback.location_id as pump_back_location_id,
       neargage.location_id as near_gage_location_id,
       project.yield_time_frame_start,
       project.yield_time_frame_end,
       project.project_remarks
  from ( select o.office_id as office_id,
                bl.base_location_id
                ||substr('-', 1, length(pl.sub_location_id))
                ||pl.sub_location_id as location_id,
                p.federal_cost,
                p.nonfederal_cost,authorizing_law,
                p.project_owner,
                p.hydropower_description,
                p.sedimentation_description,
                p.downstream_urban_description,
                p.bank_full_capacity_description,
                p.pump_back_location_code,
                p.near_gage_location_code,
                p.yield_time_frame_start,
                p.yield_time_frame_end,
                p.project_remarks
           from cwms_office o,
                at_base_location bl,
                at_physical_location pl,
                at_project p
          where bl.db_office_code = o.office_code
            and pl.base_location_code = bl.base_location_code
            and p.project_location_code = pl.location_code
       ) project
       left outer join
       ( select pl.location_code,
                bl.base_location_id
                ||substr('-', 1, length(pl.sub_location_id))
                ||pl.sub_location_id as location_id
           from at_base_location bl,
                at_physical_location pl,
                at_project p
          where pl.base_location_code = bl.base_location_code
            and p.project_location_code = pl.location_code
       ) pumpback on pumpback.location_code = project.pump_back_location_code
       left outer join
       ( select pl.location_code,
                bl.base_location_id
                ||substr('-', 1, length(pl.sub_location_id))
                ||pl.sub_location_id as location_id
           from at_base_location bl,
                at_physical_location pl,
                at_project p
          where pl.base_location_code = bl.base_location_code
            and p.project_location_code = pl.location_code
       ) neargage on neargage.location_code = project.near_gage_location_code
/
