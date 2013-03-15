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
   p_value      in number,
   p_sig_digits in integer)
return number
is
   l_value      number;
   l_magnitude  binary_integer; -- integer power of 10
   l_dec_places binary_integer; -- decimal places to round input number to
begin
   if p_value is null then
      l_value := null;
   elsif p_value = 0 then
      l_value := 0;      
   else                
      l_value      := p_value;
      l_magnitude  := trunc(log(10, abs(l_value)));
      if p_sig_digits <= 0 then
         l_value := 0;
      end if;
      l_dec_places := p_sig_digits - l_magnitude - 1;
      l_value := round(l_value, l_dec_places);
   end if;
   return l_value;
end round_f;   

--------------------------------------------------------------------------------
-- round_f
function round_f(
   p_value      in binary_double,
   p_sig_digits in integer)
return binary_double
is
   l_value      binary_double;
   l_magnitude  binary_integer; -- integer power of 10
   l_dec_places binary_integer; -- decimal places to round input number to
begin
   if p_value is null then
      l_value := null;
   elsif p_value = 0 then
      l_value := 0;      
   else                
      l_value      := p_value;
      l_magnitude  := trunc(log(10, abs(l_value)));
      if p_sig_digits <= 0 then
         l_value := 0;
      end if;
      l_dec_places := p_sig_digits - l_magnitude - 1;
      l_value := round(l_value, l_dec_places);
   end if;
   return l_value;
end round_f;   

--------------------------------------------------------------------------------
-- round_nn_f
function round_nn_f(
   p_value         in  number,
   p_rounding_spec in  varchar2)
return number deterministic   
is
   l_value      number;
   l_magnitude  binary_integer; -- integer power of 10
   l_spec_pos   binary_integer; -- 1-based position in rounding spec
   l_sig_digits binary_integer; -- significant digits based on rounding spec
   l_dec_places binary_integer; -- decimal places to round input number to
   l_max_places binary_integer; -- maximum number of decimal places
begin
   if p_value is null then
      return null;
   elsif p_value = 0 then
      return 0;      
   else                
      validate_rounding_spec(p_rounding_spec);
      l_value      := p_value;
      l_magnitude  := trunc(log(10, abs(l_value)));
      l_spec_pos   := least(5, greatest(-3, l_magnitude)) + 4;
      l_sig_digits := to_number(substr(p_rounding_spec, l_spec_pos, 1));
      if l_sig_digits = 0 then
         l_value := 0;
      end if;
      l_max_places := to_number(substr(p_rounding_spec, 10));
      l_dec_places := least(l_sig_digits - l_magnitude - 1, l_max_places);
      return round(l_value, l_dec_places);
   end if;
end round_nn_f;

--------------------------------------------------------------------------------
-- round_nd_f
function round_nd_f(
   p_value         in  number,
   p_rounding_spec in  varchar2)
return binary_double deterministic   
is
begin
   return cast(round_nn_f(p_value, p_rounding_spec) as binary_double);
end round_nd_f;

--------------------------------------------------------------------------------
-- round_nt_f
function round_nt_f(
   p_value         in  number,
   p_rounding_spec in  varchar2)
return varchar2 deterministic   
is
begin
   return to_char(round_nn_f(p_value, p_rounding_spec));
end round_nt_f;

--------------------------------------------------------------------------------
-- round_dd_f
function round_dd_f(
   p_value         in  binary_double,
   p_rounding_spec in  varchar2)
return binary_double deterministic   
is
   l_value      binary_double;
   l_magnitude  binary_integer; -- integer power of 10
   l_spec_pos   binary_integer; -- 1-based position in rounding spec
   l_sig_digits binary_integer; -- significant digits based on rounding spec
   l_dec_places binary_integer; -- decimal places to round input number to
   l_max_places binary_integer; -- maximum number of decimal places
begin
   if p_value is null then
      return null;
   elsif p_value = 0 then
      return 0;      
   else                
      validate_rounding_spec(p_rounding_spec);
      l_value      := p_value;
      l_magnitude  := trunc(log(10, abs(l_value)));
      l_spec_pos   := least(5, greatest(-3, l_magnitude)) + 4;
      l_sig_digits := to_number(substr(p_rounding_spec, l_spec_pos, 1));
      if l_sig_digits = 0 then
         l_value := 0;
      end if;
      l_max_places := to_number(substr(p_rounding_spec, 10));
      l_dec_places := least(l_sig_digits - l_magnitude - 1, l_max_places);
      return round(l_value, l_dec_places);
   end if;
end round_dd_f;

--------------------------------------------------------------------------------
-- round_dn_f
function round_dn_f(
   p_value         in  binary_double,
   p_rounding_spec in  varchar2)
return number deterministic   
is
begin
   return cast(round_dd_f(p_value, p_rounding_spec) as number);
end round_dn_f;

--------------------------------------------------------------------------------
-- round_dt_f
function round_dt_f(
   p_value         in  binary_double,
   p_rounding_spec in  varchar2)
return varchar2 deterministic   
is
begin
   return round_nt_f(cast(p_value as number), p_rounding_spec);
end round_dt_f;

--------------------------------------------------------------------------------
-- round_td_f
function round_td_f(
   p_value         in  varchar2,
   p_rounding_spec in  varchar2)
return binary_double deterministic
is
begin
   return round_nd_f(to_number(p_value), p_rounding_spec);
end round_td_f;   

--------------------------------------------------------------------------------
-- round_tn_f
function round_tn_f(
   p_value         in  varchar2,
   p_rounding_spec in  varchar2)
return number deterministic
is
begin
   return round_nn_f(to_number(p_value), p_rounding_spec);
end round_tn_f;   

--------------------------------------------------------------------------------
-- round_tt_f
function round_tt_f(
   p_value         in  varchar2,
   p_rounding_spec in  varchar2)
return varchar2 deterministic
is
begin
   return round_nt_f(to_number(p_value), p_rounding_spec);
end round_tt_f;   

--------------------------------------------------------------------------------
-- round_n_tab
procedure round_n_tab(
   p_values        in out nocopy number_tab_t,
   p_rounding_spec in            varchar2)
is
   l_value      number;
   l_magnitude  binary_integer; -- integer power of 10
   l_spec_pos   binary_integer; -- 1-based position in rounding spec
   l_sig_digits binary_integer; -- significant digits based on rounding spec
   l_dec_places binary_integer; -- decimal places to round input number to
   l_max_places binary_integer; -- maximum number of decimal places
begin
   if p_values is not null then
      validate_rounding_spec(p_rounding_spec);
      l_max_places := to_number(substr(p_rounding_spec, 10));
      for i in 1..p_values.count loop
         continue when p_values(i) is null or p_values(i) = 0;
         l_value      := p_values(i);
         l_magnitude  := trunc(log(10, abs(l_value)));
         l_spec_pos   := least(5, greatest(-3, l_magnitude)) + 4;
         l_sig_digits := to_number(substr(p_rounding_spec, l_spec_pos, 1));
         if l_sig_digits = 0 then
            l_value := 0;
         end if;
         l_dec_places := least(l_sig_digits - l_magnitude - 1, l_max_places);
         p_values(i)  := round(l_value, l_dec_places);
      end loop;
   end if;
end round_n_tab;

--------------------------------------------------------------------------------
-- round_d_tab
procedure round_d_tab(
   p_values        in out nocopy double_tab_t,
   p_rounding_spec in            varchar2)
is
   l_value      binary_double;
   l_magnitude  binary_integer; -- integer power of 10
   l_spec_pos   binary_integer; -- 1-based position in rounding spec
   l_sig_digits binary_integer; -- significant digits based on rounding spec
   l_dec_places binary_integer; -- decimal places to round input number to
   l_max_places binary_integer; -- maximum number of decimal places
begin
   if p_values is not null then
      validate_rounding_spec(p_rounding_spec);
      l_max_places := to_number(substr(p_rounding_spec, 10));
      for i in 1..p_values.count loop
         continue when p_values(i) is null or p_values(i) = 0;
         l_value      := p_values(i);
         l_magnitude  := trunc(log(10, abs(l_value)));
         l_spec_pos   := least(5, greatest(-3, l_magnitude)) + 4;
         l_sig_digits := to_number(substr(p_rounding_spec, l_spec_pos, 1));
         if l_sig_digits = 0 then
            l_value := 0;
         end if;
         l_dec_places := least(l_sig_digits - l_magnitude - 1, l_max_places);
         p_values(i)  := round(l_value, l_dec_places);
      end loop;
   end if;
end round_d_tab;

--------------------------------------------------------------------------------
-- round_t_tab
procedure round_t_tab(
   p_values        in out nocopy str_tab_t,
   p_rounding_spec in            varchar2)
is
   l_value      number;
   l_magnitude  binary_integer; -- integer power of 10
   l_spec_pos   binary_integer; -- 1-based position in rounding spec
   l_sig_digits binary_integer; -- significant digits based on rounding spec
   l_dec_places binary_integer; -- decimal places to round input number to
   l_max_places binary_integer; -- maximum number of decimal places
begin
   if p_values is not null then
      validate_rounding_spec(p_rounding_spec);
      l_max_places := to_number(substr(p_rounding_spec, 10));
      for i in 1..p_values.count loop
         l_value      := to_number(p_values(i));
         continue when l_value is null or l_value = 0;
         l_magnitude  := trunc(log(10, abs(l_value)));
         l_spec_pos   := least(5, greatest(-3, l_magnitude)) + 4;
         l_sig_digits := to_number(substr(p_rounding_spec, l_spec_pos, 1));
         if l_sig_digits = 0 then
            l_value := 0;
         end if;
         l_dec_places := least(l_sig_digits - l_magnitude - 1, l_max_places);
         p_values(i)  := round(l_value, l_dec_places);
      end loop;
   end if;
end round_t_tab;

--------------------------------------------------------------------------------
-- round_tsv_array
procedure round_tsv_array(
   p_values        in out nocopy tsv_array,
   p_rounding_spec in            varchar2)
is
   l_value      binary_double;
   l_magnitude  binary_integer; -- integer power of 10
   l_spec_pos   binary_integer; -- 1-based position in rounding spec
   l_sig_digits binary_integer; -- significant digits based on rounding spec
   l_dec_places binary_integer; -- decimal places to round input number to
   l_max_places binary_integer; -- maximum number of decimal places
begin
   if p_values is not null then
      validate_rounding_spec(p_rounding_spec);
      l_max_places := to_number(substr(p_rounding_spec, 10));
      for i in 1..p_values.count loop
         continue when p_values(i).value is null or p_values(i).value = 0;
         l_value      := p_values(i).value;
         l_magnitude  := trunc(log(10, abs(l_value)));
         l_spec_pos   := least(5, greatest(-3, l_magnitude)) + 4;
         l_sig_digits := to_number(substr(p_rounding_spec, l_spec_pos, 1));
         if l_sig_digits = 0 then
            l_value := 0;
         end if;
         l_dec_places := least(l_sig_digits - l_magnitude - 1, l_max_places);
         p_values(i).value := round(l_value, l_dec_places);
      end loop;
   end if;
end round_tsv_array;

--------------------------------------------------------------------------------
-- round_ztsv_array
procedure round_ztsv_array(
   p_values        in out nocopy ztsv_array,
   p_rounding_spec in            varchar2)
is
   l_value      binary_double;
   l_magnitude  binary_integer; -- integer power of 10
   l_spec_pos   binary_integer; -- 1-based position in rounding spec
   l_sig_digits binary_integer; -- significant digits based on rounding spec
   l_dec_places binary_integer; -- decimal places to round input number to
   l_max_places binary_integer; -- maximum number of decimal places
begin
   if p_values is not null then
      validate_rounding_spec(p_rounding_spec);
      l_max_places := to_number(substr(p_rounding_spec, 10));
      for i in 1..p_values.count loop
         continue when p_values(i).value is null or p_values(i).value = 0;
         l_value      := p_values(i).value;
         l_magnitude  := trunc(log(10, abs(l_value)));
         l_spec_pos   := least(5, greatest(-3, l_magnitude)) + 4;
         l_sig_digits := to_number(substr(p_rounding_spec, l_spec_pos, 1));
         if l_sig_digits = 0 then
            l_value := 0;
         end if;
         l_dec_places := least(l_sig_digits - l_magnitude - 1, l_max_places);
         p_values(i).value := round(l_value, l_dec_places);
      end loop;
   end if;
end round_ztsv_array;

end cwms_rounding;
/
show errors;
