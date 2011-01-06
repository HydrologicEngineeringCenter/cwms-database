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
-- FUNCTION analyze_sequence
--------------------------------------------------------------------------------
function analyze_sequence(
   p_sequence in double_tab_t)
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
   p_properties      in sequence_properties_t default null)
   return pls_integer
is
   l_properties sequence_properties_t;
   l_hi         pls_integer := null;
   l_lo         pls_integer;
   l_mid        pls_integer;
   l_in_range   boolean := false;
begin
   --------------------------
   -- general sanity check --
   --------------------------
   if p_value is null then
      cwms_err.raise(
         'ERROR',
         'Value cannot be null');
   elsif p_sequence is null then
      cwms_err.raise(
         'ERROR',
         'Sequence cannot be null');
   elsif p_sequence.count < 2 then
      cwms_err.raise(
         'ERROR',
         'Sequence must have at least two values');
   end if;
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
   if l_properties.increasing_range then
      --------------------------------
      -- handle increasing sequence --
      --------------------------------
      if p_value <= p_sequence(1) then
         l_hi := 2;
      elsif p_value >= p_sequence(p_sequence.count) then
         l_hi := p_sequence.count;
      else
         l_lo := 1;
         l_hi := p_sequence.count;
         while l_hi - l_lo > 1 loop
            l_mid := trunc((l_lo + l_hi) / 2);
            if p_sequence(l_mid) > p_value then
               l_hi := l_mid;
            else
               l_lo := l_mid;
            end if;
         end loop;
      end if;
   else
      --------------------------------
      -- handle decreasing sequence --
      --------------------------------
      if p_value >= p_sequence(1) then
         l_hi := 2;
      elsif p_value <= p_sequence(p_sequence.count) then
         l_hi := p_sequence.count;
      else
         l_lo := 1;
         l_hi := p_sequence.count;
         while l_hi - l_lo > 1 loop
            l_mid := trunc((l_lo + l_hi) / 2);
            if p_sequence(l_mid) < p_value then
               l_hi := l_mid;
            else
               l_lo := l_mid;
            end if;
         end loop;
      end if;
   end if;
   return l_hi;
end find_high_index;

--------------------------------------------------------------------------------
-- FUNCTION find_high_index
--------------------------------------------------------------------------------
function find_high_index(
   p_value           in binary_double,
   p_sequence        in double_tab_t,
   p_properties      in sequence_properties_t default null)
   return pls_integer
is
   l_properties sequence_properties_t;
   l_hi         pls_integer := null;
   l_lo         pls_integer;
   l_mid        pls_integer;
   l_in_range   boolean := false;
begin
   --------------------------
   -- general sanity check --
   --------------------------
   if p_value is null then
      cwms_err.raise(
         'ERROR',
         'Value cannot be null');
   elsif p_sequence is null then
      cwms_err.raise(
         'ERROR',
         'Sequence cannot be null');
   elsif p_sequence.count < 2 then
      cwms_err.raise(
         'ERROR',
         'Sequence must have at least two values');
   end if;
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
   if l_properties.increasing_range then
      --------------------------------
      -- handle increasing sequence --
      --------------------------------
      if p_value <= p_sequence(1) then
         l_hi := 2;
      elsif p_value >= p_sequence(p_sequence.count) then
         l_hi := p_sequence.count;
      else
         l_lo := 1;
         l_hi := p_sequence.count;
         while l_hi - l_lo > 1 loop
            l_mid := trunc((l_lo + l_hi) / 2);
            if p_sequence(l_mid) > p_value then
               l_hi := l_mid;
            else
               l_lo := l_mid;
            end if;
         end loop;
      end if;
   else
      --------------------------------
      -- handle decreasing sequence --
      --------------------------------
      if p_value >= p_sequence(1) then
         l_hi := 2;
      elsif p_value <= p_sequence(p_sequence.count) then
         l_hi := p_sequence.count;
      else
         l_lo := 1;
         l_hi := p_sequence.count;
         while l_hi - l_lo > 1 loop
            l_mid := trunc((l_lo + l_hi) / 2);
            if p_sequence(l_mid) < p_value then
               l_hi := l_mid;
            else
               l_lo := l_mid;
            end if;
         end loop;
      end if;
   end if;
   return l_hi;
end find_high_index;

--------------------------------------------------------------------------------
-- FUNCTION find_ratio
--------------------------------------------------------------------------------
function find_ratio(
   p_log_used                out boolean,
   p_value                   in  number,
   p_sequence                in  number_tab_t,
   p_high_index              in  pls_integer,
   p_increasing              in  boolean,
   p_in_range_behavior       in  pls_integer default method_linear,
   p_out_range_low_behavior  in  pls_integer default method_null,
   p_out_range_high_behavior in  pls_integer default method_null)
   return number
is
   l_in_range_behavior       pls_integer := p_in_range_behavior;
   l_out_range_low_behavior  pls_integer := p_out_range_low_behavior;
   l_out_range_high_behavior pls_integer := p_out_range_high_behavior;
   l_in_range                boolean;
   l_out_low                 boolean;
   l_use_log                 boolean;
   i                         pls_integer := p_high_index;
   l_val                     number      := p_value;
   l_hi_val                  number      := p_sequence(i);
   l_lo_val                  number      := p_sequence(i-1);
   l_ratio                   number;
begin
   --------------------------
   -- general sanity check --
   --------------------------
   if p_value is null then
      cwms_err.raise(
         'ERROR',
         'Value cannot be null');
   elsif p_sequence is null then
      cwms_err.raise(
         'ERROR',
         'Sequence cannot be null');
   elsif p_sequence.count < 2 then
      cwms_err.raise(
         'ERROR',
         'Sequence must have at least two values');
   end if;
   -----------------------------
   -- sanity check on methods --
   -----------------------------
   if l_in_range_behavior in 
      (  method_lin_log,
         method_log_lin,
         method_conic,
         method_nearest
      )
   then   
      cwms_err.raise(
         'INVALID_ITEM',
         l_in_range_behavior,
         'in range behavior for CWMS_LOOKUP.FIND_RATIO');
   end if;
   if p_increasing then
      if l_out_range_low_behavior in 
         (  method_lin_log,
            method_log_lin,
            method_conic,
            method_previous,
            method_lower
         )
      then   
         cwms_err.raise(
            'INVALID_ITEM',
            l_out_range_low_behavior,
            'out-of-range low behavior for CWMS_LOOKUP.FIND_RATIO');
      end if;   
      if l_out_range_high_behavior in 
         (  method_lin_log,
            method_log_lin,
            method_conic,
            method_next,
            method_higher
         )
      then   
         cwms_err.raise(
            'INVALID_ITEM',
            l_out_range_high_behavior,
            'out-of-range high behavior for CWMS_LOOKUP.FIND_RATIO');
      end if;
      -----------------------------------------------------
      -- translate value-based methods to position-based --
      -----------------------------------------------------
      if    l_in_range_behavior        = method_lower then
            l_in_range_behavior       := method_previous;
      elsif l_in_range_behavior        = method_higher then
            l_in_range_behavior       := method_next;
      end if; 
      if    l_out_range_low_behavior   = method_higher then
            l_out_range_low_behavior  := method_next;
      elsif l_out_range_low_behavior   = method_nearest then
            l_out_range_low_behavior  := method_next;
      elsif l_out_range_low_behavior   = method_closest then
            l_out_range_low_behavior  := method_next;
      end if; 
      if    l_out_range_high_behavior  = method_lower then
            l_out_range_high_behavior := method_previous;
      elsif l_out_range_high_behavior  = method_nearest then
            l_out_range_high_behavior := method_previous;
      elsif l_out_range_high_behavior  = method_closest then
            l_out_range_high_behavior := method_previous;
      end if; 
   else   
      if l_out_range_low_behavior in 
         (  method_lin_log,
            method_log_lin,
            method_conic,
            method_next,
            method_lower
         )
      then   
         cwms_err.raise(
            'INVALID_ITEM',
            l_out_range_low_behavior,
            'out-of-range low behavior for CWMS_LOOKUP.FIND_RATIO');
      end if;   
      if l_out_range_high_behavior in 
         (  method_lin_log,
            method_log_lin,
            method_conic,
            method_previous,
            method_higher
         )
      then   
         cwms_err.raise(
            'INVALID_ITEM',
            l_out_range_high_behavior,
            'out-of-range high behavior for CWMS_LOOKUP.FIND_RATIO');
      end if;
      -----------------------------------------------------
      -- translate value-based methods to position-based --
      -----------------------------------------------------
      if    l_in_range_behavior        = method_lower then
            l_in_range_behavior       := method_next;
      elsif l_in_range_behavior        = method_higher then
            l_in_range_behavior       := method_previous;
      end if; 
      if    l_out_range_low_behavior   = method_higher then
            l_out_range_low_behavior  := method_previous;
      elsif l_out_range_low_behavior   = method_nearest then
            l_out_range_low_behavior  := method_previous;
      elsif l_out_range_low_behavior   = method_closest then
            l_out_range_low_behavior  := method_previous;
      end if; 
      if    l_out_range_high_behavior  = method_lower then
            l_out_range_high_behavior := method_next;
      elsif l_out_range_high_behavior  = method_nearest then
            l_out_range_high_behavior := method_next;
      elsif l_out_range_high_behavior  = method_closest then
            l_out_range_high_behavior := method_next;
      end if; 
   end if;   
         
   l_use_log := l_in_range_behavior = method_logarithmic;
   if l_use_log then
      begin
         l_val    := log(10, l_val);
         l_hi_val := log(10, l_hi_val);
         l_lo_val := log(10, l_lo_val);
         p_log_used   := true;
      exception
         when others then
            l_val    := p_value;
            l_hi_val := p_sequence(i);
            l_lo_val := p_sequence(i-1);
            p_log_used := false;
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
      case l_in_range_behavior
         when method_null then
            -------------------------------
            -- don't use log values here --
            -------------------------------
            if p_value = p_sequence(i-1) then
               l_ratio := 0.;
            elsif p_value = p_sequence(i) then
               l_ratio := 1.;
            else
               l_ratio := null;
            end if;
         when method_error then
            -------------------------------
            -- don't use log values here --
            -------------------------------
            if p_value = p_sequence(i-1) then
               l_ratio := 0.;
            elsif p_value = p_sequence(i) then
               l_ratio := 1.;
            else
               cwms_err.raise('ERROR', 'Value does not equal any value in sequence');
            end if;
         when method_linear then
            l_ratio := (l_val - l_lo_val) / (l_hi_val - l_lo_val);
         when method_logarithmic then
            l_ratio := (l_val - l_lo_val) / (l_hi_val - l_lo_val);
         when method_previous then 
            l_ratio := 0.;
         when method_next then 
            l_ratio := 1.;
         when method_closest then
            -------------------------------
            -- don't use log values here --
            -------------------------------
            case abs(p_value - p_sequence(i-1)) < abs(p_value - p_sequence(i))
               when true then l_ratio := 0.;
               else           l_ratio := 1.;
            end case;
         else
            cwms_err.raise(
               'INVALID_ITEM',
               l_in_range_behavior,
               'in range behavior for CWMS_LOOKUP.FIND_RATIO');
      end case;
   else 
      -------------------------------------------------------
      -- out of range, determine if we are out low or high --
      -------------------------------------------------------
      if p_increasing then
         l_out_low := p_value < p_sequence(1);
      else
         l_out_low := p_value > p_sequence(p_sequence.count);
      end if;
      if l_out_low then
         ----------------------
         -- out of range low --
         ----------------------
         case l_out_range_low_behavior
            when method_null then
               l_ratio := null;
            when method_error then
               cwms_err.raise('ERROR', 'Value is out of range low');
            when method_linear then
               l_ratio := (l_val - l_lo_val) / (l_hi_val - l_lo_val);
            when method_logarithmic then
               l_ratio := (l_val - l_lo_val) / (l_hi_val - l_lo_val);
            when method_previous then
               l_ratio := 1.;
            when method_next then
               l_ratio := 0.;
            else
               cwms_err.raise(
                  'INVALID_ITEM',
                  l_out_range_low_behavior,
                  'out-of-range low behavior for CWMS_LOOKUP.FIND_RATIO');
         end case;
      else
         -----------------------
         -- out of range high --
         -----------------------
         case l_out_range_high_behavior
            when method_null then
               l_ratio := null;
            when method_error then
               cwms_err.raise('ERROR', 'Value is out of range high');
            when method_linear then
               l_ratio := (l_val - l_lo_val) / (l_hi_val - l_lo_val);
            when method_logarithmic then
               l_ratio := (l_val - l_lo_val) / (l_hi_val - l_lo_val);
            when method_previous then
               l_ratio := 1.;
            when method_next then
               l_ratio := 0.;
            else
               cwms_err.raise(
                  'INVALID_ITEM',
                  l_out_range_high_behavior,
                  'out-of-range high behavior for CWMS_LOOKUP.FIND_RATIO');
         end case;
      end if;
   end if;
   
   return l_ratio;
end find_ratio;

--------------------------------------------------------------------------------
-- FUNCTION find_ratio
--------------------------------------------------------------------------------
function find_ratio(
   p_log_used                out boolean,
   p_value                   in  binary_double,
   p_sequence                in  double_tab_t,
   p_high_index              in  pls_integer,
   p_increasing              in  boolean,
   p_in_range_behavior       in  pls_integer default method_linear,
   p_out_range_low_behavior  in  pls_integer default method_null,
   p_out_range_high_behavior in  pls_integer default method_null)
   return binary_double
is
   l_in_range_behavior       pls_integer    := p_in_range_behavior;
   l_out_range_low_behavior  pls_integer    := p_out_range_low_behavior;
   l_out_range_high_behavior pls_integer    := p_out_range_high_behavior;
   l_in_range                boolean;
   l_out_low                 boolean;
   l_use_log                 boolean;
   i                         pls_integer    := p_high_index;
   l_val                     binary_double  := p_value;
   l_hi_val                  binary_double  := p_sequence(i);
   l_lo_val                  binary_double  := p_sequence(i-1);
   l_ratio                   binary_double;
begin
   --------------------------
   -- general sanity check --
   --------------------------
   if p_value is null then
      cwms_err.raise(
         'ERROR',
         'Value cannot be null');
   elsif p_sequence is null then
      cwms_err.raise(
         'ERROR',
         'Sequence cannot be null');
   elsif p_sequence.count < 2 then
      cwms_err.raise(
         'ERROR',
         'Sequence must have at least two values');
   end if;
   -----------------------------
   -- sanity check on methods --
   -----------------------------
   if l_in_range_behavior in 
      (  method_lin_log,
         method_log_lin,
         method_conic,
         method_nearest
      )
   then   
      cwms_err.raise(
         'INVALID_ITEM',
         l_in_range_behavior,
         'in range behavior for CWMS_LOOKUP.FIND_RATIO');
   end if;
   if p_increasing then
      if l_out_range_low_behavior in 
         (  method_lin_log,
            method_log_lin,
            method_conic,
            method_previous,
            method_lower
         )
      then   
         cwms_err.raise(
            'INVALID_ITEM',
            l_out_range_low_behavior,
            'out-of-range low behavior for CWMS_LOOKUP.FIND_RATIO');
      end if;   
      if l_out_range_high_behavior in 
         (  method_lin_log,
            method_log_lin,
            method_conic,
            method_next,
            method_higher
         )
      then   
         cwms_err.raise(
            'INVALID_ITEM',
            l_out_range_high_behavior,
            'out-of-range high behavior for CWMS_LOOKUP.FIND_RATIO');
      end if;
      -----------------------------------------------------
      -- translate value-based methods to position-based --
      -----------------------------------------------------
      if    l_in_range_behavior        = method_lower then
            l_in_range_behavior       := method_previous;
      elsif l_in_range_behavior        = method_higher then
            l_in_range_behavior       := method_next;
      end if; 
      if    l_out_range_low_behavior   = method_higher then
            l_out_range_low_behavior  := method_next;
      elsif l_out_range_low_behavior   = method_nearest then
            l_out_range_low_behavior  := method_next;
      elsif l_out_range_low_behavior   = method_closest then
            l_out_range_low_behavior  := method_next;
      end if; 
      if    l_out_range_high_behavior  = method_lower then
            l_out_range_high_behavior := method_previous;
      elsif l_out_range_high_behavior  = method_nearest then
            l_out_range_high_behavior := method_previous;
      elsif l_out_range_high_behavior  = method_closest then
            l_out_range_high_behavior := method_previous;
      end if; 
   else   
      if l_out_range_low_behavior in 
         (  method_lin_log,
            method_log_lin,
            method_conic,
            method_next,
            method_lower
         )
      then   
         cwms_err.raise(
            'INVALID_ITEM',
            l_out_range_low_behavior,
            'out-of-range low behavior for CWMS_LOOKUP.FIND_RATIO');
      end if;   
      if l_out_range_high_behavior in 
         (  method_lin_log,
            method_log_lin,
            method_conic,
            method_previous,
            method_higher
         )
      then   
         cwms_err.raise(
            'INVALID_ITEM',
            l_out_range_high_behavior,
            'out-of-range high behavior for CWMS_LOOKUP.FIND_RATIO');
      end if;
      -----------------------------------------------------
      -- translate value-based methods to position-based --
      -----------------------------------------------------
      if    l_in_range_behavior        = method_lower then
            l_in_range_behavior       := method_next;
      elsif l_in_range_behavior        = method_higher then
            l_in_range_behavior       := method_previous;
      end if; 
      if    l_out_range_low_behavior   = method_higher then
            l_out_range_low_behavior  := method_previous;
      elsif l_out_range_low_behavior   = method_nearest then
            l_out_range_low_behavior  := method_previous;
      elsif l_out_range_low_behavior   = method_closest then
            l_out_range_low_behavior  := method_previous;
      end if; 
      if    l_out_range_high_behavior  = method_lower then
            l_out_range_high_behavior := method_next;
      elsif l_out_range_high_behavior  = method_nearest then
            l_out_range_high_behavior := method_next;
      elsif l_out_range_high_behavior  = method_closest then
            l_out_range_high_behavior := method_next;
      end if; 
   end if;   
         
   l_use_log := l_in_range_behavior = method_logarithmic;
   if l_use_log then
      begin
         l_val    := log(10, l_val);
         l_hi_val := log(10, l_hi_val);
         l_lo_val := log(10, l_lo_val);
         p_log_used   := true;
      exception
         when others then
            l_val    := p_value;
            l_hi_val := p_sequence(i);
            l_lo_val := p_sequence(i-1);
            p_log_used := false;
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
      case l_in_range_behavior
         when method_null then
            -------------------------------
            -- don't use log values here --
            -------------------------------
            if p_value = p_sequence(i-1) then
               l_ratio := 0.;
            elsif p_value = p_sequence(i) then
               l_ratio := 1.;
            else
               l_ratio := null;
            end if;
         when method_error then
            -------------------------------
            -- don't use log values here --
            -------------------------------
            if p_value = p_sequence(i-1) then
               l_ratio := 0.;
            elsif p_value = p_sequence(i) then
               l_ratio := 1.;
            else
               cwms_err.raise('ERROR', 'Value does not equal any value in sequence');
            end if;
         when method_linear then
            l_ratio := (l_val - l_lo_val) / (l_hi_val - l_lo_val);
         when method_logarithmic then
            l_ratio := (l_val - l_lo_val) / (l_hi_val - l_lo_val);
         when method_previous then 
            l_ratio := 0.;
         when method_next then 
            l_ratio := 1.;
         when method_closest then
            -------------------------------
            -- don't use log values here --
            -------------------------------
            case abs(p_value - p_sequence(i-1)) < abs(p_value - p_sequence(i))
               when true then l_ratio := 0.;
               else           l_ratio := 1.;
            end case;
         else
            cwms_err.raise(
               'INVALID_ITEM',
               l_in_range_behavior,
               'in range behavior for CWMS_LOOKUP.FIND_RATIO');
      end case;
   else 
      -------------------------------------------------------
      -- out of range, determine if we are out low or high --
      -------------------------------------------------------
      if p_increasing then
         l_out_low := p_value < p_sequence(1);
      else
         l_out_low := p_value > p_sequence(p_sequence.count);
      end if;
      if l_out_low then
         ----------------------
         -- out of range low --
         ----------------------
         case l_out_range_low_behavior
            when method_null then
               l_ratio := null;
            when method_error then
               cwms_err.raise('ERROR', 'Value is out of range low');
            when method_linear then
               l_ratio := (l_val - l_lo_val) / (l_hi_val - l_lo_val);
            when method_logarithmic then
               l_ratio := (l_val - l_lo_val) / (l_hi_val - l_lo_val);
            when method_previous then
               l_ratio := 1.;
            when method_next then
               l_ratio := 0.;
            else
               cwms_err.raise(
                  'INVALID_ITEM',
                  l_out_range_low_behavior,
                  'out-of-range low behavior for CWMS_LOOKUP.FIND_RATIO');
         end case;
      else
         -----------------------
         -- out of range high --
         -----------------------
         case l_out_range_high_behavior
            when method_null then
               l_ratio := null;
            when method_error then
               cwms_err.raise('ERROR', 'Value is out of range high');
            when method_linear then
               l_ratio := (l_val - l_lo_val) / (l_hi_val - l_lo_val);
            when method_logarithmic then
               l_ratio := (l_val - l_lo_val) / (l_hi_val - l_lo_val);
            when method_previous then
               l_ratio := 1.;
            when method_next then
               l_ratio := 0.;
            else
               cwms_err.raise(
                  'INVALID_ITEM',
                  l_out_range_high_behavior,
                  'out-of-range high behavior for CWMS_LOOKUP.FIND_RATIO');
         end case;
      end if;
   end if;
   
   return l_ratio;
end find_ratio;

--------------------------------------------------------------------------------
-- FUNCTION lookup
--------------------------------------------------------------------------------
function lookup(
   p_value                   in number,
   p_independent             in number_tab_t,
   p_dependent               in number_tab_t,
   p_independent_properties  in sequence_properties_t default null,
   p_in_range_behavior       in pls_integer default method_linear,
   p_out_range_low_behavior  in pls_integer default method_null,
   p_out_range_high_behavior in pls_integer default method_null)
   return number
is
   l_values number_tab_t;
begin
   l_values := lookup(
      number_tab_t(null),
      p_independent,
      p_dependent,
      p_independent_properties,
      p_in_range_behavior,
      p_out_range_low_behavior,
      p_out_range_high_behavior);
      
   return l_values(1);            
end lookup;   

--------------------------------------------------------------------------------
-- FUNCTION lookup
--------------------------------------------------------------------------------
function lookup(
   p_value                   in binary_double,
   p_independent             in double_tab_t,
   p_dependent               in double_tab_t,
   p_independent_properties  in sequence_properties_t default null,
   p_in_range_behavior       in pls_integer default method_linear,
   p_out_range_low_behavior  in pls_integer default method_null,
   p_out_range_high_behavior in pls_integer default method_null)
   return binary_double
is
   l_values double_tab_t;
begin
   l_values := lookup(
      double_tab_t(null),
      p_independent,
      p_dependent,
      p_independent_properties,
      p_in_range_behavior,
      p_out_range_low_behavior,
      p_out_range_high_behavior);
      
   return l_values(1);            
end lookup;

--------------------------------------------------------------------------------
-- FUNCTION lookup
--------------------------------------------------------------------------------
function lookup(
   p_values                  in number_tab_t,
   p_independent             in number_tab_t,
   p_dependent               in number_tab_t,
   p_independent_properties  in sequence_properties_t default null,
   p_in_range_behavior       in pls_integer default method_linear,
   p_out_range_low_behavior  in pls_integer default method_null,
   p_out_range_high_behavior in pls_integer default method_null)
   return number_tab_t
is
   l_independent_properties sequence_properties_t;
   l_in_range_behavior      pls_integer;
   l_high_index             pls_integer;
   l_val                    number;
   l_hi_val                 number;
   l_lo_val                 number;
   l_ratio                  number;
   l_independent_log        boolean;
   l_dependent_log          boolean;
   l_values                 number_tab_t;
begin
   ---------------------------------------------------
   -- sanity checks (more occur in find_high_index) --
   ---------------------------------------------------
   if p_independent is null then
      cwms_err.raise(
         'ERROR',
         'Independent sequence cannot be null');
   elsif p_dependent is null then
      cwms_err.raise(
         'ERROR',
         'Dependent sequence cannot be null');
   elsif p_dependent.count != p_independent.count then
      cwms_err.raise(
         'ERROR',
         'Independent and dependent sequences must have same length');
   end if;
   
   if p_values is null then
      return l_values;
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
   l_values := number_tab_t();
   l_values.extend(p_values.count);
   for i in 1..p_values.count loop
      ---------------------------------------------------------
      -- find the high index for interpolation/extrapolation --
      ---------------------------------------------------------
      l_high_index := find_high_index(
         p_values(i),
         p_independent,
         l_independent_properties);
      -----------------------------------------------------
      -- find the ratio for interpolation/extrapoloation --
      -----------------------------------------------------
      if p_in_range_behavior = method_lin_log then
         l_in_range_behavior := method_linear;
      elsif p_in_range_behavior = method_log_lin then
         l_in_range_behavior := method_logarithmic;
      else 
         l_in_range_behavior := p_in_range_behavior;
      end if;
      l_ratio := find_ratio(
         l_independent_log,
         p_values(i),
         p_independent,
         l_high_index,
         l_independent_properties.increasing_range,
         l_in_range_behavior,
         p_out_range_low_behavior,
         p_out_range_high_behavior);  
      if l_ratio is not null then 
         ---------------------------------------      
         -- set log properties dependent axis --
         ---------------------------------------
         l_dependent_log := p_in_range_behavior in (method_logarithmic, method_lin_log);
         if l_dependent_log then
            if p_in_range_behavior in (method_logarithmic, method_log_lin) and not l_independent_log then
               ---------------------------------------
               -- fall back from LOG-LoG to LIN-LIN --
               ---------------------------------------
               l_dependent_log := false;
            end if;
         end if;      
         ------------------------------------------------------------------
         -- handle log interpolation/extrapolation on dependent sequence --
         ------------------------------------------------------------------
         l_hi_val := p_dependent(l_high_index);
         l_lo_val := p_dependent(l_high_index-1);
         if l_dependent_log then
            begin
               l_hi_val := log(10, l_hi_val);
               l_lo_val := log(10, l_lo_val);
            exception
               when others then
                  l_dependent_log := false;
                  l_hi_val := p_dependent(l_high_index);
                  l_lo_val := p_dependent(l_high_index-1);
                  if l_independent_log then
                     ---------------------------------------
                     -- fall back from LOG-LoG to LIN-LIN --
                     ---------------------------------------
                     l_independent_log := false;
                     l_ratio := find_ratio(
                        l_independent_log,
                        p_values(i),
                        p_independent,
                        l_high_index,
                        l_independent_properties.increasing_range,
                        method_linear,
                        p_out_range_low_behavior,
                        p_out_range_high_behavior);
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
         l_values(i) := l_val;
      end if;
   end loop;      
   return l_values;
end lookup;

--------------------------------------------------------------------------------
-- FUNCTION lookup
--------------------------------------------------------------------------------
function lookup(
   p_values                  in double_tab_t,
   p_independent             in double_tab_t,
   p_dependent               in double_tab_t,
   p_independent_properties  in sequence_properties_t default null,
   p_in_range_behavior       in pls_integer default method_linear,
   p_out_range_low_behavior  in pls_integer default method_null,
   p_out_range_high_behavior in pls_integer default method_null)
   return double_tab_t
is
   l_independent_properties sequence_properties_t;
   l_in_range_behavior      pls_integer;
   l_high_index             pls_integer;
   l_val                    binary_double;
   l_hi_val                 binary_double;
   l_lo_val                 binary_double;
   l_ratio                  binary_double;
   l_independent_log        boolean;
   l_dependent_log          boolean;
   l_values                 double_tab_t;
begin
   ---------------------------------------------------
   -- sanity checks (more occur in find_high_index) --
   ---------------------------------------------------
   if p_independent is null then
      cwms_err.raise(
         'ERROR',
         'Independent sequence cannot be null');
   elsif p_dependent is null then
      cwms_err.raise(
         'ERROR',
         'Dependent sequence cannot be null');
   elsif p_dependent.count != p_independent.count then
      cwms_err.raise(
         'ERROR',
         'Independent and dependent sequences must have same length');
   end if;
   
   if p_values is null then
      return l_values;
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
   l_values := double_tab_t();
   l_values.extend(p_values.count);
   for i in 1..p_values.count loop
      ---------------------------------------------------------
      -- find the high index for interpolation/extrapolation --
      ---------------------------------------------------------
      l_high_index := find_high_index(
         p_values(i),
         p_independent,
         l_independent_properties);
      -----------------------------------------------------
      -- find the ratio for interpolation/extrapoloation --
      -----------------------------------------------------
      if p_in_range_behavior = method_lin_log then
         l_in_range_behavior := method_linear;
      elsif p_in_range_behavior = method_log_lin then
         l_in_range_behavior := method_logarithmic;
      else 
         l_in_range_behavior := p_in_range_behavior;
      end if;
      l_ratio := find_ratio(
         l_independent_log,
         p_values(i),
         p_independent,
         l_high_index,
         l_independent_properties.increasing_range,
         l_in_range_behavior,
         p_out_range_low_behavior,
         p_out_range_high_behavior);  
      if l_ratio is not null then 
         ---------------------------------------      
         -- set log properties dependent axis --
         ---------------------------------------
         l_dependent_log := p_in_range_behavior in (method_logarithmic, method_lin_log);
         if l_dependent_log then
            if p_in_range_behavior in (method_logarithmic, method_log_lin) and not l_independent_log then
               ---------------------------------------
               -- fall back from LOG-LoG to LIN-LIN --
               ---------------------------------------
               l_dependent_log := false;
            end if;
         end if;      
         ------------------------------------------------------------------
         -- handle log interpolation/extrapolation on dependent sequence --
         ------------------------------------------------------------------
         l_hi_val := p_dependent(l_high_index);
         l_lo_val := p_dependent(l_high_index-1);
         if l_dependent_log then
            begin
               l_hi_val := log(10, l_hi_val);
               l_lo_val := log(10, l_lo_val);
            exception
               when others then
                  l_dependent_log := false;
                  l_hi_val := p_dependent(l_high_index);
                  l_lo_val := p_dependent(l_high_index-1);
                  if l_independent_log then
                     ---------------------------------------
                     -- fall back from LOG-LoG to LIN-LIN --
                     ---------------------------------------
                     l_independent_log := false;
                     l_ratio := find_ratio(
                        l_independent_log,
                        p_values(i),
                        p_independent,
                        l_high_index,
                        l_independent_properties.increasing_range,
                        method_linear,
                        p_out_range_low_behavior,
                        p_out_range_high_behavior);
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
         l_values(i) := l_val;
      end if;
   end loop;      
   return l_values;
end lookup;

--------------------------------------------------------------------------------
-- FUNCTION lookup
--------------------------------------------------------------------------------
function lookup(
   p_array                   in tsv_array,
   p_independent             in double_tab_t,
   p_dependent               in double_tab_t,
   p_independent_properties  in sequence_properties_t default null,
   p_in_range_behavior       in pls_integer default method_linear,
   p_out_range_low_behavior  in pls_integer default method_null,
   p_out_range_high_behavior in pls_integer default method_null)
   return tsv_array
is
   l_values   double_tab_t;
   l_array    tsv_array;
   l_validity varchar2(16);
begin
   if p_array is null then
      return l_array;
   end if;
   
   l_values := double_tab_t();
   l_values.extend(p_array.count);
   for i in 1..p_array.count loop
      select validity_id
        into l_validity
        from cwms_data_quality
       where quality_code = p_array(i).quality_code;
      if l_validity not in ('MISSING', 'REJECTED') then       
         l_values(i) := p_array(i).value;
      end if;
   end loop;
   
   l_values := lookup(
      l_values,
      p_independent,
      p_dependent,
      p_independent_properties,
      p_in_range_behavior,
      p_out_range_low_behavior,
      p_out_range_high_behavior);
      
   l_array := tsv_array();
   l_array.extend(p_array.count);
   for i in 1..p_array.count loop
      l_array(i).date_time := p_array(i).date_time;
      l_array(i).value     := l_values(i);
      if l_values(i) is null then
         l_array(i).quality_code := 5; -- MISSING
      else
         l_array(i).quality_code := 0; -- UNSCREENED
      end if;
   end loop;
   return l_array;   
end lookup; 
  
--------------------------------------------------------------------------------
-- FUNCTION lookup
--------------------------------------------------------------------------------
function lookup(
   p_array                   in ztsv_array,
   p_independent             in double_tab_t,
   p_dependent               in double_tab_t,
   p_independent_properties  in sequence_properties_t default null,
   p_in_range_behavior       in pls_integer default method_linear,
   p_out_range_low_behavior  in pls_integer default method_null,
   p_out_range_high_behavior in pls_integer default method_null)
   return ztsv_array
is
   l_values   double_tab_t;
   l_array    ztsv_array;
   l_validity varchar2(16);
begin
   if p_array is null then
      return l_array;
   end if;
   
   l_values := double_tab_t();
   l_values.extend(p_array.count);
   for i in 1..p_array.count loop
      select validity_id
        into l_validity
        from cwms_data_quality
       where quality_code = p_array(i).quality_code;
      if l_validity not in ('MISSING', 'REJECTED') then       
         l_values(i) := p_array(i).value;
      end if;
   end loop;
   
   l_values := lookup(
      l_values,
      p_independent,
      p_dependent,
      p_independent_properties,
      p_in_range_behavior,
      p_out_range_low_behavior,
      p_out_range_high_behavior);
      
   l_array := ztsv_array();
   l_array.extend(p_array.count);
   for i in 1..p_array.count loop
      l_array(i).date_time := p_array(i).date_time;
      l_array(i).value     := l_values(i);
      if l_values(i) is null then
         l_array(i).quality_code := 5; -- MISSING
      else
         l_array(i).quality_code := 0; -- UNSCREENED
      end if;
   end loop;
   return l_array;   
end lookup; 

----------------------------------
-- INITIALIZE PACKAGE VARIABLES --
----------------------------------
begin
   select rating_method_code into method_null        from cwms_rating_method where rating_method_id = 'NULL';
   select rating_method_code into method_error       from cwms_rating_method where rating_method_id = 'ERROR';
   select rating_method_code into method_linear      from cwms_rating_method where rating_method_id = 'LINEAR';
   select rating_method_code into method_logarithmic from cwms_rating_method where rating_method_id = 'LOGARITHMIC';
   select rating_method_code into method_lin_log     from cwms_rating_method where rating_method_id = 'LIN-LOG';
   select rating_method_code into method_log_lin     from cwms_rating_method where rating_method_id = 'LOG-LIN';
   select rating_method_code into method_conic       from cwms_rating_method where rating_method_id = 'CONIC';
   select rating_method_code into method_previous    from cwms_rating_method where rating_method_id = 'PREVIOUS';
   select rating_method_code into method_next        from cwms_rating_method where rating_method_id = 'NEXT';
   select rating_method_code into method_nearest     from cwms_rating_method where rating_method_id = 'NEAREST';
   select rating_method_code into method_lower       from cwms_rating_method where rating_method_id = 'LOWER';
   select rating_method_code into method_higher      from cwms_rating_method where rating_method_id = 'HIGHER';
   select rating_method_code into method_closest     from cwms_rating_method where rating_method_id = 'CLOSEST';
end cwms_lookup;
/
commit;
show errors;