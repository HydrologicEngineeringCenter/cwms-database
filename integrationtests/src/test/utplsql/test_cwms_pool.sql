create or replace package &cwms_schema..test_cwms_pool
as

--%suite(Test CWMS_POOL package)

--%beforeall(setup)
--%afterall(teardown)
--%rollback(manual)

--%test(Test for duplicate pools in CAT_POOLS)
procedure test_duplicate_pools;

procedure setup;
procedure teardown;

c_office_id      constant varchar2(16)   := '&&office_id';
c_location_id    constant varchar2(57)   := 'TestCwmsPool';
c_time_zone      constant varchar2(28)   := 'US/Central';
c_parameter      constant varchar2(49)   := 'Elev';
c_param_type     constant varchar2(16)   := 'Inst';
c_duration       constant varchar2(16)   := '0'; 
c_implicit_names constant cwms_t_str_tab := cwms_t_str_tab('Normal', 'Flood', 'Exclusive Flood Control');
c_explicit_name  constant varchar2(32)   := 'Total Flood';

end test_cwms_pool;
/
create or replace package body &cwms_schema..test_cwms_pool
as
--------------------------------------------------------------------------------
-- procedure teaardown
--------------------------------------------------------------------------------
procedure teardown
is
begin
   begin
      cwms_project.delete_project(
         p_project_id    => c_location_id,
         p_delete_action => cwms_util.delete_all,
         p_db_office_id  => c_office_id);
   exception
      when others then null;
   end;   
      
   begin
      cwms_loc.delete_location(
         p_location_id   => c_location_id,
         p_delete_action => cwms_util.delete_all,
         p_db_office_id  => c_office_id);
   exception
      when others then null;
   end;   
         
   begin
      cwms_pool.delete_pool_name(
         p_pool_name     => c_explicit_name,
         p_delete_action => cwms_util.delete_key,
         p_office_id     => c_office_id);
   exception
      when others then null;
   end;
end teardown;   
--------------------------------------------------------------------------------
-- procedure setup
--------------------------------------------------------------------------------
procedure setup
is
begin
   teardown;
   -------------------------------------
   -- store the location as a project --
   -------------------------------------
   cwms_loc.store_location (
      p_location_id  => c_location_id,
      p_time_zone_id => c_time_zone,
		p_db_office_id	=> c_office_id);
      
   cwms_project.store_project(project_obj_t(
      p_project_location             => cwms_t_location_obj(cwms_t_location_ref(c_location_id, c_office_id)),
      p_pump_back_location           => null,
      p_near_gage_location           => null,
      p_authorizing_law              => null,
      p_cost_year                    => null,
      p_federal_cost                 => null,
      p_nonfederal_cost              => null,
      p_federal_om_cost              => null,
      p_nonfederal_om_cost           => null,
      p_remarks                      => null,
      p_project_owner                => null,
      p_hydropower_description       => null,
      p_sedimentation_description    => null,
      p_downstream_urban_description => null,
      p_bank_full_capacity_descript  => null,
      p_yield_time_frame_start       => null,
      p_yield_time_frame_end         => null)); 
                            
   for i in 1..c_implicit_names.count loop
      ---------------------------------------------------
      -- create the location levels for implicit pools --
      ---------------------------------------------------
      cwms_level.store_location_level(
         p_location_level_id => c_location_id||'.'||c_parameter||'.'||c_param_type||'.'||c_duration||'.Bottom of '||c_implicit_names(i),
         p_level_value       => 100 * i,
         p_level_units       => 'ft',
         p_effective_date    => date '2000-01-01',
         p_office_id         => c_office_id);  
         
      cwms_level.store_location_level(
         p_location_level_id => c_location_id||'.'||c_parameter||'.'||c_param_type||'.'||c_duration||'.Top of '||c_implicit_names(i),
         p_level_value       => 100 * (i + 1),
         p_level_units       => 'ft',
         p_effective_date    => date '2000-01-01',
         p_office_id         => c_office_id);
      if i = 1 then
         ---------------------------------------------
         -- try to create a duplicate implicit pool --
         ---------------------------------------------
         cwms_level.store_location_level(
            p_location_level_id => c_location_id||'.'||c_parameter||'.'||c_param_type||'.'||c_duration||'.Bottom of '||c_implicit_names(i),
            p_level_value       => 100 * i + 5,
            p_level_units       => 'ft',
            p_effective_date    => date '2010-01-01',
            p_fail_if_exists    => 'F',
            p_office_id         => c_office_id);  
      elsif i = 2 then
         ---------------------------------------------------
         -- convert the implicit pool to an explicit pool --
         ---------------------------------------------------
         cwms_pool.store_pool(
            p_project_id      => c_location_id,
            p_pool_name       => c_implicit_names(i),
            p_bottom_level_id => c_location_id||'.'||c_parameter||'.'||c_param_type||'.'||c_duration||'.Bottom of '||c_implicit_names(i),
            p_top_level_id    => c_location_id||'.'||c_parameter||'.'||c_param_type||'.'||c_duration||'.Top of '||c_implicit_names(i),
            p_office_id       => c_office_id);
      end if;      
   end loop;
   --------------------------------------------------
   -- create the location levels for explicit pool --
   --------------------------------------------------
   cwms_level.store_location_level(
      p_location_level_id => c_location_id||'.'||c_parameter||'.'||c_param_type||'.'||c_duration||'.'||c_explicit_name||' Bottom',
      p_level_value       => 100 ,
      p_level_units       => 'ft',
      p_effective_date    => date '2000-01-01',
      p_office_id         => c_office_id);  
      
   cwms_level.store_location_level(
      p_location_level_id => c_location_id||'.'||c_parameter||'.'||c_param_type||'.'||c_duration||'.'||c_explicit_name||' Top',
      p_level_value       => 200,
      p_level_units       => 'ft',
      p_effective_date    => date '2000-01-01',
      p_office_id         => c_office_id);  
   -----------------------------------
   -- create an explicit pool pools --
   -----------------------------------
   cwms_pool.store_pool_name(
      p_pool_name      => c_explicit_name,
      p_office_id      => c_office_id);
      
   cwms_pool.store_pool(
      p_project_id      => c_location_id,
      p_pool_name       => c_explicit_name,
      p_bottom_level_id => c_location_id||'.'||c_parameter||'.'||c_param_type||'.'||c_duration||'.'||c_explicit_name||' Bottom',
      p_top_level_id    => c_location_id||'.'||c_parameter||'.'||c_param_type||'.'||c_duration||'.'||c_explicit_name||' Top',
      p_office_id       => c_office_id);
   ---------------------------------------------
   -- try to create a duplicate explicit pool --
   ---------------------------------------------
   cwms_level.store_location_level(
      p_location_level_id => c_location_id||'.'||c_parameter||'.'||c_param_type||'.'||c_duration||'.'||c_explicit_name||' Bottom',
      p_level_value       => 105,
      p_level_units       => 'ft',
      p_effective_date    => date '2010-01-01',
      p_office_id         => c_office_id);  
end setup;
--------------------------------------------------------------------------------
-- procedure test_duplicate_pools
--------------------------------------------------------------------------------
procedure test_duplicate_pools
is
   l_crsr           sys_refcursor;
   l_office_ids     cwms_t_str_tab;
   l_project_ids    cwms_t_str_tab;
   l_pool_names     cwms_t_str_tab;
   l_bottom_levels  cwms_t_str_tab;
   l_top_levels     cwms_t_str_tab;
   l_attributes     cwms_t_number_tab;
   l_descriptions   cwms_t_str_tab;
   l_clob_codes     cwms_t_number_tab;
   l_clob_values    cwms_t_clob_tab;
   l_count          pls_integer;
begin
   ---------------------------------------
   -- catalog the pools (implicit only) --
   ---------------------------------------
   l_crsr := cwms_pool.cat_pools_f(
      p_project_id_mask   => c_location_id,
      p_pool_name_mask    => '*',
      p_bottom_level_mask => '*',
      p_top_level_mask    => '*',
      p_include_explicit  => 'F',
      p_include_implicit  => 'T',
      p_office_id_mask    => c_office_id);
   
   fetch l_crsr
     bulk collect
     into l_office_ids,   
          l_project_ids,
          l_pool_names,   
          l_bottom_levels,
          l_top_levels,   
          l_attributes,   
          l_descriptions, 
          l_clob_codes,   
          l_clob_values;
   close l_crsr;
   
   ut.expect(l_pool_names.count).to_equal(2);
   select count(*) into l_count from table(l_pool_names) where column_value = c_implicit_names(1);
   ut.expect(l_count).to_equal(1);
   select count(*) into l_count from table(l_pool_names) where column_value = c_implicit_names(3);
   ut.expect(l_count).to_equal(1);
   ---------------------------------------
   -- catalog the pools (explicit only) --
   ---------------------------------------
   l_crsr := cwms_pool.cat_pools_f(
      p_project_id_mask   => c_location_id,
      p_pool_name_mask    => '*',
      p_bottom_level_mask => '*',
      p_top_level_mask    => '*',
      p_include_explicit  => 'T',
      p_include_implicit  => 'F',
      p_office_id_mask    => c_office_id);
   
   fetch l_crsr
     bulk collect
     into l_office_ids,   
          l_project_ids,
          l_pool_names,   
          l_bottom_levels,
          l_top_levels,   
          l_attributes,   
          l_descriptions, 
          l_clob_codes,   
          l_clob_values;
   close l_crsr;          
          
   ut.expect(l_pool_names.count).to_equal(2);
   select count(*) into l_count from table(l_pool_names) where column_value = c_implicit_names(2);
   ut.expect(l_count).to_equal(1);
   select count(*) into l_count from table(l_pool_names) where column_value = c_explicit_name;
   ut.expect(l_count).to_equal(1);
   -----------------------------------------------
   -- catalog the pools (implicit and explicit) --
   -----------------------------------------------
   l_crsr := cwms_pool.cat_pools_f(
      p_project_id_mask   => c_location_id,
      p_pool_name_mask    => '*',
      p_bottom_level_mask => '*',
      p_top_level_mask    => '*',
      p_include_explicit  => 'T',
      p_include_implicit  => 'T',
      p_office_id_mask    => c_office_id);
   
   fetch l_crsr
     bulk collect
     into l_office_ids,   
          l_project_ids,
          l_pool_names,   
          l_bottom_levels,
          l_top_levels,   
          l_attributes,   
          l_descriptions, 
          l_clob_codes,   
          l_clob_values;
   close l_crsr;          
          
   ut.expect(l_pool_names.count).to_equal(4);
   select count(*) into l_count from table(l_pool_names) where column_value = c_implicit_names(1);
   ut.expect(l_count).to_equal(1);
   select count(*) into l_count from table(l_pool_names) where column_value = c_implicit_names(2);
   ut.expect(l_count).to_equal(1);
   select count(*) into l_count from table(l_pool_names) where column_value = c_implicit_names(3);
   ut.expect(l_count).to_equal(1);
   select count(*) into l_count from table(l_pool_names) where column_value = c_explicit_name;
   ut.expect(l_count).to_equal(1);
end test_duplicate_pools;
end test_cwms_pool;
/
grant execute on &cwms_schema..test_cwms_pool to cwms_user;
