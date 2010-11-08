create or replace package cwms_rounding
as
--------------------------------------------------------------------------------
-- round_nn_f
function round_nn_f(
   p_value         in  number,   -- input as number
   p_rounding_spec in  varchar2) -- string of significant digits for powers of 10 in range -3..6
return number;   

--------------------------------------------------------------------------------
-- round_nd_f
function round_nd_f(
   p_value         in  number,   -- input as number
   p_rounding_spec in  varchar2) -- string of significant digits for powers of 10 in range -3..6
return binary_double;   

--------------------------------------------------------------------------------
-- round_nt_f
function round_nt_f(
   p_value         in  number,   -- input as number
   p_rounding_spec in  varchar2) -- string of significant digits for powers of 10 in range -3..6
return varchar2;   

--------------------------------------------------------------------------------
-- round_dd_f
function round_dd_f(
   p_value         in  binary_double, -- input as binary_double
   p_rounding_spec in  varchar2)      -- string of significant digits for powers of 10 in range -3..6
return binary_double;   

--------------------------------------------------------------------------------
-- round_dn_f
function round_dn_f(
   p_value         in  binary_double, -- input as binary_double
   p_rounding_spec in  varchar2)      -- string of significant digits for powers of 10 in range -3..6
return number;   

--------------------------------------------------------------------------------
-- round_dt_f
function round_dt_f(
   p_value         in  binary_double, -- input as binary_double
   p_rounding_spec in  varchar2)      -- string of significant digits for powers of 10 in range -3..6
return varchar2;   

--------------------------------------------------------------------------------
-- round_td_f
function round_td_f(
   p_value         in  varchar2, -- input as text
   p_rounding_spec in  varchar2) -- string of significant digits for powers of 10 in range -3..6
return binary_double;   

--------------------------------------------------------------------------------
-- round_tn_f
function round_tn_f(
   p_value         in  varchar2, -- input as text
   p_rounding_spec in  varchar2) -- string of significant digits for powers of 10 in range -3..6
return number;   

--------------------------------------------------------------------------------
-- round_tt_f
function round_tt_f(
   p_value         in  varchar2, -- input as text
   p_rounding_spec in  varchar2) -- string of significant digits for powers of 10 in range -3..6
return varchar2;   

--------------------------------------------------------------------------------
-- round_n_tab
procedure round_n_tab(
   p_values        in out nocopy number_tab_t, -- input as table of numbers
   p_rounding_spec in            varchar2);    -- string of significant digits for powers of 10 in range -3..6

--------------------------------------------------------------------------------
-- round_d_tab
procedure round_d_tab(
   p_values        in out nocopy double_tab_t, -- input as table of binary_doubles
   p_rounding_spec in            varchar2);    -- string of significant digits for powers of 10 in range -3..6

--------------------------------------------------------------------------------
-- round_t_tab
procedure round_t_tab(
   p_values        in out nocopy str_tab_t, -- input as table of text
   p_rounding_spec in            varchar2); -- string of significant digits for powers of 10 in range -3..6

--------------------------------------------------------------------------------
-- round_tsv_array
procedure round_tsv_array(
   p_values        in out nocopy tsv_array, -- input as tsv_array
   p_rounding_spec in            varchar2); -- string of significant digits for powers of 10 in range -3..6

--------------------------------------------------------------------------------
-- round_ztsv_array
procedure round_ztsv_array(
   p_values        in out nocopy ztsv_array, -- input as ztsv_array
   p_rounding_spec in            varchar2);  -- string of significant digits for powers of 10 in range -3..6
   
end cwms_rounding;
/
show errors;
grant execute on cwms_rounding to cwms_user;
