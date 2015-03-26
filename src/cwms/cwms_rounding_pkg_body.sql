create or replace package body cwms_rounding
as

procedure validate_rounding_spec(
   p_rounding_spec in varchar2)
is
   n number;
   procedure invalid is
   begin
      cwms_err.raise(
         'INVALID_ITEM',
         nvl(p_rounding_spec, '<NULL>'),
         'USGS rounding specification');
   end;
begin
   if p_rounding_spec is null or length(p_rounding_spec) != 10 then
      invalid;
   end if;
   begin
      n := to_number(p_rounding_spec);
   exception
      when others then
         if sqlcode = -6502 then
            invalid;
         end if;
   end;
end validate_rounding_spec;

--------------------------------------------------------------------------------
-- round_f
function round_f(
   p_value         in number,
   p_sig_digits    in integer,
   p_round_to_even in varchar2 default 'T')
return number deterministic
is
   c_epsilon       constant number := 1e-8; -- "close enough to zero" value
   l_value         number := p_value;
   l_magnitude     number; -- log10 magnitude of value
   l_factor        number; -- divide value by this to get number in range [1,10)
   l_integer       number; -- integer portion of factored value
   l_fraction      number; -- fractional portion of factored value
   l_result        number; 
   l_round_to_even boolean := cwms_util.return_true_or_false(p_round_to_even);
begin
   if l_value is null or l_value is nan or l_value = 0 then
      l_result := l_value;
   else
      --------------------------------------------------------------------                  
      -- factor the value and work with integer and fractional portions --
      --------------------------------------------------------------------                  
      l_magnitude := floor(log(10, abs(l_value)));
      l_factor := 10 ** (l_magnitude - p_sig_digits + 1);
      l_value := l_value / l_factor; 
      l_integer := trunc(l_value);
      l_fraction := abs(l_value - l_integer);
      if abs(l_fraction - .5) < c_epsilon then
         --------------------------------------
         -- fraction is "close enough" to .5 --
         --------------------------------------
         if l_round_to_even and mod(l_integer, 2) = 0 then
            -------------------------------------------------------------------------- 
            -- rounding to closest even number, and integer portion is already even --
            -------------------------------------------------------------------------- 
            null; 
         else
            ------------------------------------------
            -- round away from zero to next integer --
            ------------------------------------------
            l_integer := l_integer + sign(l_integer);
         end if;
      else
         ---------------------------------------------
         -- round away from zero to closest integer --
         ---------------------------------------------
         l_integer := trunc(l_value + .5 * sign(l_value));
      end if;
      ------------------------------------------------------------
      -- factor the rounded value back to the correct magnitude --
      ------------------------------------------------------------
      l_result := l_integer * l_factor; 
   end if;
   return l_result;
end round_f;   

--------------------------------------------------------------------------------
-- round_f
function round_f(
   p_value         in binary_double,
   p_sig_digits    in integer,
   p_round_to_even in varchar2 default 'T')
return binary_double deterministic
is
   numeric_overflow exception;
   pragma exception_init(numeric_overflow, -1426);
   c_epsilon       constant binary_double := 1e-8d; -- "close enough to zero" value
   l_value         binary_double := p_value;
   l_magnitude     binary_integer; -- log10 magnitude of value
   l_factor        binary_double;  -- divide value by this to get number in range [1,10)
   l_integer       binary_integer; -- integer portion of factored value
   l_fraction      binary_double;  -- fractional portion of factored value
   l_result        binary_double; 
   l_round_to_even boolean := cwms_util.return_true_or_false(p_round_to_even);
begin
   if l_value is null or l_value is nan or l_value = 0 then
      l_result := l_value;
   else
      --------------------------------------------------------------------                  
      -- factor the value and work with integer and fractional portions --
      --------------------------------------------------------------------                  
      l_magnitude := floor(log(10, abs(l_value)));
      l_factor := 10d ** (l_magnitude - p_sig_digits + 1);
      l_value := l_value / l_factor; 
      l_integer := trunc(l_value);
      l_fraction := abs(l_value - l_integer);
      if abs(l_fraction - .5d) < c_epsilon then
         --------------------------------------
         -- fraction is "close enough" to .5 --
         --------------------------------------
         if l_round_to_even and mod(l_integer, 2) = 0 then
            -------------------------------------------------------------------------- 
            -- rounding to closest even number, and integer portion is already even --
            -------------------------------------------------------------------------- 
            null; 
         else
            ------------------------------------------
            -- round away from zero to next integer --
            ------------------------------------------
            l_integer := l_integer + sign(l_integer);
         end if;
      else
         ---------------------------------------------
         -- round away from zero to closest integer --
         ---------------------------------------------
         l_integer := trunc(l_value + .5d * sign(l_value));
      end if;
      ------------------------------------------------------------
      -- factor the rounded value back to the correct magnitude --
      ------------------------------------------------------------
      l_result := l_integer * l_factor; 
   end if;
   return l_result;
exception
   when numeric_overflow then
      return round_f(to_number(p_value), p_sig_digits, p_round_to_even);   
end round_f;   

--------------------------------------------------------------------------------
-- round_nn_f
function round_nn_f(
   p_value         in number,
   p_rounding_spec in varchar2,
   p_round_to_even in varchar2 default 'T')
return number deterministic   
is
   c_epsilon       constant number := 1e-8; -- "close enough to zero" value
   l_value         number := p_value;
   l_max_places    number; -- max number of places to right of decimal point as per rounding spec
   l_magnitude     number; -- log10 magnitude of value
   l_spec_pos      number; -- position (1-based) in the rounding spec for this magnitude
   l_digits        number; -- number of significant digits to use 
   l_factor        number; -- divide value by this to get number in range [1,10)
   l_integer       number; -- integer portion of factored value
   l_fraction      number; -- fractional portion of factored value
   l_result        number; 
   l_round_to_even boolean := cwms_util.return_true_or_false(p_round_to_even);
begin
   l_max_places := to_number(substr(p_rounding_spec, 10, 1));
   if l_value is null or l_value is nan or l_value = 0 then
      l_result := l_value;
   else
      ---------------------------------------------------------------------  
      -- determine the magnitude and number of significant digits to use --
      ---------------------------------------------------------------------  
      l_magnitude := floor(log(10, abs(l_value)));
      l_spec_pos := least(5, greatest(-3, l_magnitude)) + 4;
      l_digits := to_number(substr(p_rounding_spec, l_spec_pos, 1)); -- from rounding spec
      l_digits := case l_digits + l_magnitude >= l_digits            -- decrease if ncecessary due to max decimal places
                  when true then l_digits
                  else least(l_max_places, l_digits + l_magnitude + 1)
                  end;
      --------------------------------------------------------------------                  
      -- factor the value and work with integer and fractional portions --
      --------------------------------------------------------------------                  
      l_factor := 10 ** (l_magnitude - l_digits + 1);
      l_value := l_value / l_factor; 
      l_integer := trunc(l_value);
      l_fraction := abs(l_value - l_integer);
      if abs(l_fraction - .5) < c_epsilon then
         --------------------------------------
         -- fraction is "close enough" to .5 --
         --------------------------------------
         if l_round_to_even and mod(l_integer, 2) = 0 then
            -------------------------------------------------------------------------- 
            -- rounding to closest even number, and integer portion is already even --
            -------------------------------------------------------------------------- 
            null; 
         else
            ------------------------------------------
            -- round away from zero to next integer --
            ------------------------------------------
            l_integer := l_integer + sign(l_integer);
         end if;
      else
         ---------------------------------------------
         -- round away from zero to closest integer --
         ---------------------------------------------
         l_integer := trunc(l_value + .5 * sign(l_value));
      end if;
      ------------------------------------------------------------
      -- factor the rounded value back to the correct magnitude --
      ------------------------------------------------------------
      l_result := l_integer * l_factor; 
   end if;
   return l_result;
end round_nn_f;

--------------------------------------------------------------------------------
-- round_nd_f
function round_nd_f(
   p_value         in number,
   p_rounding_spec in varchar2,
   p_round_to_even in varchar2 default 'T')
return binary_double deterministic   
is
begin
   return to_binary_double(round_nn_f(p_value, p_rounding_spec, p_round_to_even));
end round_nd_f;

--------------------------------------------------------------------------------
-- round_nt_f
function round_nt_f(
   p_value         in number,
   p_rounding_spec in varchar2,
   p_round_to_even in varchar2 default 'T')
return varchar2 deterministic   
is
begin
   return to_char(round_nn_f(p_value, p_rounding_spec, p_round_to_even));
end round_nt_f;

--------------------------------------------------------------------------------
-- round_dd_f
function round_dd_f(
   p_value         in binary_double,
   p_rounding_spec in varchar2,
   p_round_to_even in varchar2 default 'T')
return binary_double deterministic   
is
   numeric_overflow exception;
   pragma exception_init(numeric_overflow, -1426);
   c_epsilon       constant binary_double := 1e-8d; -- "close enough to zero" value
   l_value         binary_double := p_value;
   l_max_places    binary_integer; -- max number of places to right of decimal point as per rounding spec
   l_magnitude     binary_integer; -- log10 magnitude of value
   l_spec_pos      binary_integer; -- position (1-based) in the rounding spec for this magnitude
   l_digits        binary_integer; -- number of significant digits to use 
   l_factor        binary_double;  -- divide value by this to get number in range [1,10)
   l_integer       binary_integer; -- integer portion of factored value
   l_fraction      binary_double;  -- fractional portion of factored value
   l_result        binary_double; 
   l_round_to_even boolean := cwms_util.return_true_or_false(p_round_to_even);
begin
   l_max_places := to_number(substr(p_rounding_spec, 10, 1));
   if l_value is null or l_value is nan or l_value = 0 then
      l_result := l_value;
   else
      ---------------------------------------------------------------------  
      -- determine the magnitude and number of significant digits to use --
      ---------------------------------------------------------------------  
      l_magnitude := floor(log(10, abs(l_value)));
      l_spec_pos := least(5, greatest(-3, l_magnitude)) + 4;
      l_digits := to_number(substr(p_rounding_spec, l_spec_pos, 1)); -- from rounding spec
      l_digits := case l_digits + l_magnitude >= l_digits            -- decrease if ncecessary due to max decimal places
                  when true then l_digits
                  else least(l_max_places, l_digits + l_magnitude + 1)
                  end;
      --------------------------------------------------------------------                  
      -- factor the value and work with integer and fractional portions --
      --------------------------------------------------------------------                  
      l_factor := 10d ** (l_magnitude - l_digits + 1);
      l_value := l_value / l_factor; 
      l_integer := trunc(l_value);
      l_fraction := abs(l_value - l_integer);
      if abs(l_fraction - .5d) < c_epsilon then
         --------------------------------------
         -- fraction is "close enough" to .5 --
         --------------------------------------
         if l_round_to_even and mod(l_integer, 2) = 0 then
            -------------------------------------------------------------------------- 
            -- rounding to closest even number, and integer portion is already even --
            -------------------------------------------------------------------------- 
            null; 
         else
            ------------------------------------------
            -- round away from zero to next integer --
            ------------------------------------------
            l_integer := l_integer + sign(l_integer);
         end if;
      else
         ---------------------------------------------
         -- round away from zero to closest integer --
         ---------------------------------------------
         l_integer := trunc(l_value + .5d * sign(l_value));
      end if;
      ------------------------------------------------------------
      -- factor the rounded value back to the correct magnitude --
      ------------------------------------------------------------
      l_result := l_integer * l_factor; 
   end if;
   return l_result;
exception
   when numeric_overflow then
      return round_nn_f(p_value, p_rounding_spec, p_round_to_even);   
end round_dd_f;

--------------------------------------------------------------------------------
-- round_dn_f
function round_dn_f(
   p_value         in binary_double,
   p_rounding_spec in varchar2, 
   p_round_to_even in varchar2 default 'T')
return number deterministic   
is
begin
   return to_number(round_dd_f(p_value, p_rounding_spec, p_round_to_even));
end round_dn_f;

--------------------------------------------------------------------------------
-- round_dt_f
function round_dt_f(
   p_value         in binary_double,
   p_rounding_spec in varchar2, 
   p_round_to_even in varchar2 default 'T')
return varchar2 deterministic   
is
begin
   return round_nt_f(to_number(p_value), p_rounding_spec, p_round_to_even);
end round_dt_f;

--------------------------------------------------------------------------------
-- round_td_f
function round_td_f(
   p_value         in varchar2,
   p_rounding_spec in varchar2, 
   p_round_to_even in varchar2 default 'T')
return binary_double deterministic
is
begin
   return round_dd_f(to_binary_double(p_value), p_rounding_spec, p_round_to_even);
end round_td_f;   

--------------------------------------------------------------------------------
-- round_tn_f
function round_tn_f(
   p_value         in varchar2,
   p_rounding_spec in varchar2,
   p_round_to_even in varchar2 default 'T')
return number deterministic
is
begin
   return round_dn_f(to_binary_double(p_value), p_rounding_spec, p_round_to_even);
end round_tn_f;   

--------------------------------------------------------------------------------
-- round_tt_f
function round_tt_f(
   p_value         in varchar2,
   p_rounding_spec in varchar2, 
   p_round_to_even in varchar2 default 'T')
return varchar2 deterministic
is
begin
   return round_nt_f(to_number(p_value), p_rounding_spec, p_round_to_even);
end round_tt_f;   

--------------------------------------------------------------------------------
-- round_n_tab
procedure round_n_tab(
   p_values        in out nocopy number_tab_t,
   p_rounding_spec in            varchar2, 
   p_round_to_even in            varchar2 default 'T')
is
   c_epsilon       constant number := 1e-8; -- "close enough to zero" value
   l_value         number;
   l_max_places    number; -- max number of places to right of decimal point as per rounding spec
   l_magnitude     number; -- log10 magnitude of value
   l_spec_pos      number; -- position (1-based) in the rounding spec for this magnitude
   l_digits        number; -- number of significant digits to use 
   l_factor        number; -- divide value by this to get number in range [1,10)
   l_integer       number; -- integer portion of factored value
   l_fraction      number; -- fractional portion of factored value
   l_result        number; 
   l_round_to_even boolean := cwms_util.return_true_or_false(p_round_to_even);
begin
   if p_values is not null then
      validate_rounding_spec(p_rounding_spec);
      l_max_places := to_number(substr(p_rounding_spec, 10));
      for i in 1..p_values.count loop
         l_value := p_values(i);
         if l_value is null or l_value is nan or l_value = 0 then
            l_result := l_value;
         else
            ---------------------------------------------------------------------  
            -- determine the magnitude and number of significant digits to use --
            ---------------------------------------------------------------------  
            l_magnitude := floor(log(10, abs(l_value)));
            l_spec_pos := least(5, greatest(-3, l_magnitude)) + 4;
            l_digits := to_number(substr(p_rounding_spec, l_spec_pos, 1)); -- from rounding spec
            l_digits := case l_digits + l_magnitude >= l_digits            -- decrease if ncecessary due to max decimal places
                        when true then l_digits
                        else least(l_max_places, l_digits + l_magnitude + 1)
                        end;
            --------------------------------------------------------------------                  
            -- factor the value and work with integer and fractional portions --
            --------------------------------------------------------------------                  
            l_factor := 10 ** (l_magnitude - l_digits + 1);
            l_value := l_value / l_factor; 
            l_integer := trunc(l_value);
            l_fraction := abs(l_value - l_integer);
            if abs(l_fraction - .5) < c_epsilon then
               --------------------------------------
               -- fraction is "close enough" to .5 --
               --------------------------------------
               if l_round_to_even and mod(l_integer, 2) = 0 then
                  -------------------------------------------------------------------------- 
                  -- rounding to closest even number, and integer portion is already even --
                  -------------------------------------------------------------------------- 
                  null; 
               else
                  ------------------------------------------
                  -- round away from zero to next integer --
                  ------------------------------------------
                  l_integer := l_integer + sign(l_integer);
               end if;
            else
               ---------------------------------------------
               -- round away from zero to closest integer --
               ---------------------------------------------
               l_integer := trunc(l_value + .5 * sign(l_value));
            end if;
            ------------------------------------------------------------
            -- factor the rounded value back to the correct magnitude --
            ------------------------------------------------------------
            l_result := l_integer * l_factor; 
         end if;
         p_values(i) := l_result;
      end loop;
   end if;
end round_n_tab;

--------------------------------------------------------------------------------
-- round_d_tab
procedure round_d_tab(
   p_values        in out nocopy double_tab_t,
   p_rounding_spec in            varchar2,
   p_round_to_even in            varchar2 default 'T')
is
   numeric_overflow exception;
   pragma exception_init(numeric_overflow, -1426);
   c_epsilon       constant binary_double := 1e-8d; -- "close enough to zero" value
   l_value         binary_double;
   l_max_places    binary_integer; -- max number of places to right of decimal point as per rounding spec
   l_magnitude     binary_integer; -- log10 magnitude of value
   l_spec_pos      binary_integer; -- position (1-based) in the rounding spec for this magnitude
   l_digits        binary_integer; -- number of significant digits to use 
   l_factor        binary_double;  -- divide value by this to get number in range [1,10)
   l_integer       binary_integer; -- integer portion of factored value
   l_fraction      binary_double;  -- fractional portion of factored value
   l_result        binary_double; 
   l_round_to_even boolean := cwms_util.return_true_or_false(p_round_to_even);
begin
   if p_values is not null then
      validate_rounding_spec(p_rounding_spec);
      l_max_places := to_number(substr(p_rounding_spec, 10));
      for i in 1..p_values.count loop
         l_value := p_values(i);
         if l_value is null or l_value is nan or l_value = 0 then
            l_result := l_value;
         else
            begin
               l_value := p_values(i);
               ---------------------------------------------------------------------  
               -- determine the magnitude and number of significant digits to use --
               ---------------------------------------------------------------------  
               l_magnitude := floor(log(10, abs(l_value)));
               l_spec_pos := least(5, greatest(-3, l_magnitude)) + 4;
               l_digits := to_number(substr(p_rounding_spec, l_spec_pos, 1)); -- from rounding spec
               l_digits := case l_digits + l_magnitude >= l_digits            -- decrease if ncecessary due to max decimal places
                           when true then l_digits
                           else least(l_max_places, l_digits + l_magnitude + 1)
                           end;
               --------------------------------------------------------------------                  
               -- factor the value and work with integer and fractional portions --
               --------------------------------------------------------------------                  
               l_factor := 10d ** (l_magnitude - l_digits + 1);
               l_value := l_value / l_factor; 
               l_integer := trunc(l_value);
               l_fraction := abs(l_value - l_integer);
               if abs(l_fraction - .5d) < c_epsilon then
                  --------------------------------------
                  -- fraction is "close enough" to .5 --
                  --------------------------------------
                  if l_round_to_even and mod(l_integer, 2) = 0 then
                     -------------------------------------------------------------------------- 
                     -- rounding to closest even number, and integer portion is already even --
                     -------------------------------------------------------------------------- 
                     null; 
                  else
                     ------------------------------------------
                     -- round away from zero to next integer --
                     ------------------------------------------
                     l_integer := l_integer + sign(l_integer);
                  end if;
               else
                  ---------------------------------------------
                  -- round away from zero to closest integer --
                  ---------------------------------------------
                  l_integer := trunc(l_value + .5d * sign(l_value));
               end if;
               ------------------------------------------------------------
               -- factor the rounded value back to the correct magnitude --
               ------------------------------------------------------------
               l_result := l_integer * l_factor;
            exception
               when numeric_overflow then
                  l_result := round_nn_f(p_values(i), p_rounding_spec, p_round_to_even);   
            end; 
         end if;
         p_values(i) := l_result;
      end loop;
   end if;
end round_d_tab;

--------------------------------------------------------------------------------
-- round_t_tab
procedure round_t_tab(
   p_values        in out nocopy str_tab_t,
   p_rounding_spec in            varchar2,
   p_round_to_even in            varchar2 default 'T')
is
   l_values double_tab_t;
begin
   if p_values is not null then
      select to_binary_double(column_value)
        bulk collect
        into l_values
        from table(p_values);
      round_d_tab(l_values, p_rounding_spec, p_round_to_even);
      select to_char(column_value)
        bulk collect
        into p_values
        from table(l_values);
   end if;
end round_t_tab;

--------------------------------------------------------------------------------
-- round_tsv_array
procedure round_tsv_array(
   p_values        in out nocopy tsv_array,
   p_rounding_spec in            varchar2,
   p_round_to_even in            varchar2 default 'T')
is
   numeric_overflow exception;
   pragma exception_init(numeric_overflow, -1426);
   c_epsilon       constant binary_double := 1e-8d; -- "close enough to zero" value
   l_value         binary_double;
   l_max_places    binary_integer; -- max number of places to right of decimal point as per rounding spec
   l_magnitude     binary_integer; -- log10 magnitude of value
   l_spec_pos      binary_integer; -- position (1-based) in the rounding spec for this magnitude
   l_digits        binary_integer; -- number of significant digits to use 
   l_factor        binary_double;  -- divide value by this to get number in range [1,10)
   l_integer       binary_integer; -- integer portion of factored value
   l_fraction      binary_double;  -- fractional portion of factored value
   l_result        binary_double; 
   l_round_to_even boolean := cwms_util.return_true_or_false(p_round_to_even);
begin
   if p_values is not null then
      validate_rounding_spec(p_rounding_spec);
      l_max_places := to_number(substr(p_rounding_spec, 10));
      for i in 1..p_values.count loop
         l_value := p_values(i).value;
         if l_value is null or l_value is nan or l_value = 0 then
            l_result := l_value;
         else                    
            begin
               ---------------------------------------------------------------------  
               -- determine the magnitude and number of significant digits to use --
               ---------------------------------------------------------------------  
               l_magnitude := floor(log(10, abs(l_value)));
               l_spec_pos := least(5, greatest(-3, l_magnitude)) + 4;
               l_digits := to_number(substr(p_rounding_spec, l_spec_pos, 1)); -- from rounding spec
               l_digits := case l_digits + l_magnitude >= l_digits            -- decrease if ncecessary due to max decimal places
                           when true then l_digits
                           else least(l_max_places, l_digits + l_magnitude + 1)
                           end;
               --------------------------------------------------------------------                  
               -- factor the value and work with integer and fractional portions --
               --------------------------------------------------------------------                  
               l_factor := 10d ** (l_magnitude - l_digits + 1);
               l_value := l_value / l_factor; 
               l_integer := trunc(l_value);
               l_fraction := abs(l_value - l_integer);
               if abs(l_fraction - .5d) < c_epsilon then
                  --------------------------------------
                  -- fraction is "close enough" to .5 --
                  --------------------------------------
                  if l_round_to_even and mod(l_integer, 2) = 0 then
                     -------------------------------------------------------------------------- 
                     -- rounding to closest even number, and integer portion is already even --
                     -------------------------------------------------------------------------- 
                     null; 
                  else
                     ------------------------------------------
                     -- round away from zero to next integer --
                     ------------------------------------------
                     l_integer := l_integer + sign(l_integer);
                  end if;
               else
                  ---------------------------------------------
                  -- round away from zero to closest integer --
                  ---------------------------------------------
                  l_integer := trunc(l_value + .5d * sign(l_value));
               end if;
               ------------------------------------------------------------
               -- factor the rounded value back to the correct magnitude --
               ------------------------------------------------------------
               l_result := l_integer * l_factor; 
            exception
               when numeric_overflow then
                  l_result := round_nn_f(p_values(i).value, p_rounding_spec, p_round_to_even);   
            end; 
         end if;
         p_values(i).value := l_result;
      end loop;
   end if;
end round_tsv_array;

--------------------------------------------------------------------------------
-- round_ztsv_array
procedure round_ztsv_array(
   p_values        in out nocopy ztsv_array,
   p_rounding_spec in            varchar2,
   p_round_to_even in            varchar2 default 'T')
is
   numeric_overflow exception;
   pragma exception_init(numeric_overflow, -1426);
   c_epsilon       constant binary_double := 1e-8d; -- "close enough to zero" value
   l_value         binary_double;
   l_max_places    binary_integer; -- max number of places to right of decimal point as per rounding spec
   l_magnitude     binary_integer; -- log10 magnitude of value
   l_spec_pos      binary_integer; -- position (1-based) in the rounding spec for this magnitude
   l_digits        binary_integer; -- number of significant digits to use 
   l_factor        binary_double;  -- divide value by this to get number in range [1,10)
   l_integer       binary_integer; -- integer portion of factored value
   l_fraction      binary_double;  -- fractional portion of factored value
   l_result        binary_double; 
   l_round_to_even boolean := cwms_util.return_true_or_false(p_round_to_even);
begin
   if p_values is not null then
      validate_rounding_spec(p_rounding_spec);
      l_max_places := to_number(substr(p_rounding_spec, 10));
      for i in 1..p_values.count loop
         l_value := p_values(i).value;
         if l_value is null or l_value is nan or l_value = 0 then
            l_result := l_value;
         else    
            begin
               ---------------------------------------------------------------------  
               -- determine the magnitude and number of significant digits to use --
               ---------------------------------------------------------------------  
               l_magnitude := floor(log(10, abs(l_value)));
               l_spec_pos := least(5, greatest(-3, l_magnitude)) + 4;
               l_digits := to_number(substr(p_rounding_spec, l_spec_pos, 1)); -- from rounding spec
               l_digits := case l_digits + l_magnitude >= l_digits            -- decrease if ncecessary due to max decimal places
                           when true then l_digits
                           else least(l_max_places, l_digits + l_magnitude + 1)
                           end;
               --------------------------------------------------------------------                  
               -- factor the value and work with integer and fractional portions --
               --------------------------------------------------------------------                  
               l_factor := 10d ** (l_magnitude - l_digits + 1);
               l_value := l_value / l_factor; 
               l_integer := trunc(l_value);
               l_fraction := abs(l_value - l_integer);
               if abs(l_fraction - .5d) < c_epsilon then
                  --------------------------------------
                  -- fraction is "close enough" to .5 --
                  --------------------------------------
                  if l_round_to_even and mod(l_integer, 2) = 0 then
                     -------------------------------------------------------------------------- 
                     -- rounding to closest even number, and integer portion is already even --
                     -------------------------------------------------------------------------- 
                     null; 
                  else
                     ------------------------------------------
                     -- round away from zero to next integer --
                     ------------------------------------------
                     l_integer := l_integer + sign(l_integer);
                  end if;
               else
                  ---------------------------------------------
                  -- round away from zero to closest integer --
                  ---------------------------------------------
                  l_integer := trunc(l_value + .5d * sign(l_value));
               end if;
               ------------------------------------------------------------
               -- factor the rounded value back to the correct magnitude --
               ------------------------------------------------------------
               l_result := l_integer * l_factor; 
            exception
               when numeric_overflow then
                  l_result := round_nn_f(p_values(i).value, p_rounding_spec, p_round_to_even);   
            end; 
         end if;
         p_values(i).value := l_result;
      end loop;
   end if;
end round_ztsv_array;

end cwms_rounding;
/
show errors;
