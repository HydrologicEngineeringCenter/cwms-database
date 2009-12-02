create or replace package body cwms_lookup
as

--------------------------------------------------------------------------------
-- FUNCTION analyze_sequence
--------------------------------------------------------------------------------
function analyze_sequence(
   p_sequence in number_tab_t)
   return sequence_properties_t
is
   l_sequence_properties sequence_properties_t;
begin
   l_sequence_properties.null_value       := false;
   l_sequence_properties.increasing_range := false;
   l_sequence_properties.decreasing_range := false;
   l_sequence_properties.constant_range   := false;
   if p_sequence.count > 0 then
      for i in 2..p_sequence.count loop
         if p_sequence(i) is null then
            l_sequence_properties.null_value := true;
         elsif p_sequence(i) > p_sequence(i-1) then
            l_sequence_properties.increasing_range := true;
         elsif p_sequence(i) < p_sequence(i-1) then
            l_sequence_properties.decreasing_range := true;
         else
            l_sequence_properties.constant_range := true;
         end if;
      end loop;
   end if;
   return l_sequence_properties;
end analyze_sequence;

--------------------------------------------------------------------------------
-- FUNCTION find_high_index
--------------------------------------------------------------------------------
function find_high_index(
   p_value           in number,
   p_sequence        in number_tab_t,
   p_properties      in sequence_properties_t default null,
   p_out_range_error in boolean default false) -- return NULL otherwise
   return integer
is
   l_properties sequence_properties_t;
   l_hi         integer := null;
   l_lo         integer;
   l_mid        integer;
   l_in_range   boolean := false;
begin
   --------------------------------------------------------
   -- return null on null inputs or sequence of length 1 --
   --------------------------------------------------------
   if p_value is not null and p_sequence is not null and p_sequence.count > 1 then
      --------------------------------------
      -- verify we have a proper sequence --
      --------------------------------------
   l_properties :=
      case
         when p_properties.null_value is null then
            analyze_sequence(p_sequence)
         else
            p_properties
      end;
      if l_properties.null_value then
         cwms_err.raise(
            'ERROR',
            'NULL value(s) in lookup sequence');
      elsif l_properties.increasing_range and l_properties.decreasing_range then
         cwms_err.raise(
            'ERROR',
            'Lookup sequence contains increasing and decreasing ranges');
      elsif not l_properties.increasing_range and not l_properties.decreasing_range then
         cwms_err.raise(
            'ERROR',
            'Lookup sequence doesn''t contain increasing or decreasing ranges');
      end if;
      ---------------------------------------------
      -- determine whether the value is in range --
      ---------------------------------------------
      l_in_range :=
         case
            when l_properties.increasing_range then
               p_value >= p_sequence(1) and p_value <= p_sequence(p_sequence.count)
            when l_properties.decreasing_range then
               p_value <= p_sequence(1) and p_value >= p_sequence(p_sequence.count)
         end;
      if l_in_range then
         --------------------------------------
         -- binary search for the high index --
         --------------------------------------
         l_lo := 1;
         l_hi := p_sequence.count;
         while l_hi - l_lo > 1 loop
            l_mid := trunc((l_lo + l_hi) / 2);
            if p_sequence(l_mid) > p_value then
               if l_properties.increasing_range then
                  l_hi := l_mid;
               else
                  l_lo := l_mid;
               end if;
            else
               if l_properties.increasing_range then
                  l_lo := l_mid;
               else
                  l_hi := l_mid;
               end if;
            end if;
         end loop;
      else
         ------------------
         -- out of range --
         ------------------
         if p_out_range_error then
            cwms_err.raise(
               'ERROR',
               'Lookup value is not in sequence range');
         end if;
      end if;
   end if;

   return l_hi;
end find_high_index;

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
   return number
is
   l_in_range boolean;
   i          integer := p_high_index;
   l_val      number  := p_value;
   l_hi_val   number  := p_sequence(i);
   l_lo_val   number  := p_sequence(i-1);
   l_ratio    number;
begin
   if p_use_log then
      declare
         l_log_val    number;
         l_log_hi_val number;
         l_log_lo_val number;
      begin
         l_log_val    := log(10, l_val);
         l_log_hi_val := log(10, l_hi_val);
         l_log_lo_val := log(10, l_lo_val);
         l_val        := l_log_val;
         l_hi_val     := l_log_hi_val;
         l_lo_val     := l_log_lo_val;
      exception
         when others then
            p_use_log := false;
      end;
   end if;
   ---------------------------------------------
   -- determine whether the value is in range --
   ---------------------------------------------
   l_in_range :=
      case
         when p_increasing then
            l_val >= p_sequence(1) and l_val <= p_sequence(p_sequence.count)
         else
            l_val <= p_sequence(1) and l_val >= p_sequence(p_sequence.count)
      end;
   if l_in_range then
      --------------
      -- in range --
      --------------
      case p_in_range_behavior
         when in_range_interp then
            l_ratio := (l_val - l_lo_val) / (l_hi_val - l_lo_val);
         when in_range_prev then l_ratio := 0.;
         when in_range_next then l_ratio := 1.;
         when in_range_nearest then
            case abs(p_value       - p_sequence(i-1)) <
                 abs(p_sequence(i) - p_sequence(i-1))
               ------------------------------------------------
               -- don't use log values in this comparison!!! --
               ------------------------------------------------
               when true then l_ratio := 0.;
               else           l_ratio := 1.;
            end case;
         else
            cwms_err.raise(
               'INVALID_ITEM',
               p_in_range_behavior,
               'in range behavior');
      end case;
   else
      ------------------
      -- out of range --
      ------------------
      case p_out_range_behavior
         when out_range_extrap then
            l_ratio := (l_val - l_lo_val) / (l_hi_val - l_lo_val);
         when out_range_null then l_ratio := null;
         when out_range_nearest then
            case
               when p_increasing then
                  case (p_value < p_sequence(1))
                     when true then l_ratio := 0.;
                     else           l_ratio := 1.;
                  end case;
               else
                  case (p_value > p_sequence(1))
                     when true then l_ratio := 0.;
                     else           l_ratio := 1.;
                  end case;
            end case;
         when out_range_error then
            cwms_err.raise(
               'ERROR',
               'Lookup value is not in sequence range');
         else
            cwms_err.raise(
               'INVALID_ITEM',
               p_out_range_behavior,
               'out of range behavior');
      end case;
   end if;
   
   return l_ratio;

end find_ratio;

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
   return number
is
   l_independent_properties sequence_properties_t;
   l_high_index             integer;
   l_val                    number := null;
   l_hi_val                 number;
   l_lo_val                 number;
   l_ratio                  number;
   l_independent_log        boolean := p_independent_log;
   l_dependent_log          boolean := p_dependent_log;
   l_compute                boolean := true;
   i                        integer;
begin
   --------------------------------------------------
   -- sanity check (more occur in find_high_index) --
   --------------------------------------------------
   if p_dependent.count != p_independent.count then
      cwms_err.raise(
         'ERROR',
         'Independent and dependent sequences must have same length');
   end if;
   ---------------------------------------------------------
   -- make sure we have analyzed the independent sequence --
   ---------------------------------------------------------
   l_independent_properties :=
      case
         when p_independent_properties.null_value is null then
            analyze_sequence(p_independent)
         else
            p_independent_properties
      end;
   ---------------------------------------------------------
   -- find the high index for interpolation/extrapolation --
   ---------------------------------------------------------
   l_high_index := find_high_index(
      p_value,
      p_independent,
      l_independent_properties,
      p_out_range_behavior = out_range_error);
   if l_high_index is null then
      -----------------------------------
      -- not in range of lookup values --
      -----------------------------------
      case p_out_range_behavior
         when out_range_error then
            cwms_err.raise(
               'ERROR',
               'Lookup value is not in sequence range');
         when out_range_nearest then
            l_val :=
               case l_independent_properties.increasing_range
                  when true then case p_value < p_independent(1)
                     when true then p_dependent(1)
                     else p_dependent(p_dependent.count)
                  end
                  when false then case p_value > p_independent(1)
                     when true then p_dependent(1)
                     else p_dependent(p_dependent.count)
                  end
               end;
            l_compute := false;
         when out_range_null then
            l_compute := false;
         when out_range_extrap then
            l_high_index :=
               case l_independent_properties.increasing_range
                  when true then case p_value < p_independent(1)
                     when true  then 2
                     when false then p_dependent.count
                  end
                  when false then case p_value > p_independent(1)
                     when true  then 2
                     when false then p_dependent.count
                  end
               end;
      end case;
   end if;
   if l_compute then
      -----------------------------------------------------
      -- find the ratio for interpolation/extrapoloation --
      -----------------------------------------------------
      i := l_high_index;
      l_ratio := find_ratio(
         l_independent_log,
         p_value,
         p_independent,
         l_high_index,
         l_independent_properties.increasing_range,
         p_in_range_behavior,
         p_out_range_behavior);
      if p_independent_log and p_dependent_log and not l_independent_log then
         ---------------------------------------
         -- fall back from LOG-LoG to LIN-LIN --
         ---------------------------------------
         l_dependent_log := false;
      end if;
      ------------------------------------------------------------------
      -- handle log interpolation/extrapolation on dependent sequence --
      ------------------------------------------------------------------
      l_hi_val := p_dependent(i);
      l_lo_val := p_dependent(i-1);
      if l_dependent_log then
         declare
            l_log_hi_val number;
            l_log_lo_val number;
         begin
            l_log_hi_val := log(10, l_hi_val);
            l_log_lo_val := log(10, l_lo_val);
            l_hi_val     := l_log_hi_val;
            l_lo_val     := l_log_lo_val;
         exception
            when others then
               l_dependent_log := false;
               if l_independent_log then
                  ---------------------------------------
                  -- fall back from LOG-LoG to LIN-LIN --
                  ---------------------------------------
                  l_independent_log := false;
                  l_ratio := find_ratio(
                     l_independent_log,
                     p_value,
                     p_independent,
                     l_high_index,
                     l_independent_properties.increasing_range,
                     p_in_range_behavior,
                     p_out_range_behavior);
               end if;
         end;
      end if;
      -------------------------------
      -- interpolate / extrapolate --
      -------------------------------
      l_val := l_lo_val + l_ratio * (l_hi_val - l_lo_val);
      --------------------------------------------------------------------
      -- apply anti-log if log interpolation/extrapolation of dependent --
      --------------------------------------------------------------------
      if l_dependent_log then
         l_val := power(10, l_val);
      end if;
   end if;
   return l_val;
end lookup;


end cwms_lookup;
/
commit;
show errors;