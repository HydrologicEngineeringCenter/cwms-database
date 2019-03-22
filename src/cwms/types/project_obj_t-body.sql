create or replace type body project_obj_t
as
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
   is
      l_currency_unit varchar2(16);
   begin
      ------------------------------------------------------------
      -- this will explode if we ever add another currency unit --
      --                                                        --
      -- if that happens we will have to add a currency_unit    --
      -- column to the AT_PROJECT table                         --
      --                                                        --
      -- for now, it's always $                                 --
      ------------------------------------------------------------
      begin
         select unit_id
           into l_currency_unit
           from cwms_unit
          where abstract_param_code = (select abstract_param_code 
                                         from cwms_abstract_parameter
                                        where abstract_param_id = 'Currency'
                                      );
      exception
         when too_many_rows then 
            cwms_err.raise(
               'ERROR',
               'Cannot use this PROJECT_OBJ_T constructor because a cost unit must be specified.');
      end;
      
      project_location               := p_project_location;
      pump_back_location             := p_pump_back_location;
      near_gage_location             := p_near_gage_location;
      authorizing_law                := p_authorizing_law;
      cost_year                      := p_cost_year;
      federal_cost                   := p_federal_cost;
      nonfederal_cost                := p_nonfederal_cost;
      federal_om_cost                := p_federal_om_cost;
      nonfederal_om_cost             := p_nonfederal_om_cost;
      cost_units_id                  := l_currency_unit;
      remarks                        := p_remarks;
      project_owner                  := p_project_owner;
      hydropower_description         := p_hydropower_description;
      sedimentation_description      := p_sedimentation_description;
      downstream_urban_description   := p_downstream_urban_description;
      bank_full_capacity_description := p_bank_full_capacity_descript;
      yield_time_frame_start         := p_yield_time_frame_start;
      yield_time_frame_end           := p_yield_time_frame_end;
      
      return;
   end project_obj_t;
end;
/
show errors