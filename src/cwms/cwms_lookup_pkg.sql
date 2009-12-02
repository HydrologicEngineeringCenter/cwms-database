create or replace package cwms_lookup
as

--------------------------------------------------------------------------------
-- TYPES
--------------------------------------------------------------------------------
type sequence_properties_t is record(
   null_value       boolean,
   increasing_range boolean,
   decreasing_range boolean,
   constant_range   boolean);
   
--------------------------------------------------------------------------------
-- CONSTANTS
--------------------------------------------------------------------------------
in_range_interp   constant integer :=   1; -- interpolate if value is in range
in_range_prev     constant integer :=   2; -- previous val if value is in range
in_range_next     constant integer :=   4; -- next val if value is in range
in_range_nearest  constant integer :=   8; -- nearest if value is in range

out_range_null    constant integer :=  16; -- null if value not in range
out_range_error   constant integer :=  32; -- exception if value not in range
out_range_nearest constant integer :=  64; -- nearest val if value not in range
out_range_extrap  constant integer := 128; -- extrapolate if value not in range

--------------------------------------------------------------------------------
-- FUNCTION analyze_sequence
--------------------------------------------------------------------------------
function analyze_sequence(
   p_sequence in number_tab_t)
   return sequence_properties_t;

--------------------------------------------------------------------------------
-- FUNCTION find_high_index
--------------------------------------------------------------------------------
function find_high_index(
   p_value           in number,
   p_sequence        in number_tab_t,
   p_properties      in sequence_properties_t default null,
   p_out_range_error in boolean default false) -- return NULL otherwise
   return integer;
   
--------------------------------------------------------------------------------
-- FUNCTION find_ratio
--------------------------------------------------------------------------------
function find_ratio(
   p_use_log            in out boolean,
   p_value              in     number,
   p_sequence           in     number_tab_t,
   p_high_index         in     integer,
   p_increasing         in     boolean,
   p_in_range_behavior  in     integer default in_range_interp,
   p_out_range_behavior in     integer default out_range_null)
   return number;

--------------------------------------------------------------------------------
-- FUNCTION lookup
--------------------------------------------------------------------------------
function lookup(
   p_value                  in number,
   p_independent            in number_tab_t,
   p_dependent              in number_tab_t,
   p_independent_log        in boolean default false,
   p_dependent_log          in boolean default false,
   p_independent_properties in sequence_properties_t default null,
   p_in_range_behavior      in integer default in_range_interp,
   p_out_range_behavior     in integer default out_range_null)
   return number;

end cwms_lookup;
/
commit;
show errors;