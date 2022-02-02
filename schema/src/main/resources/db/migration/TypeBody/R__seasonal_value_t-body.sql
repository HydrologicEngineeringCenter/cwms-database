create or replace type body seasonal_value_t
as
   constructor function seasonal_value_t(
      p_calendar_offset in yminterval_unconstrained,
      p_time_offset     in dsinterval_unconstrained,
      p_value           in number)
      return self as result
   is
   begin
      init(cwms_util.yminterval_to_months(p_calendar_offset),
           cwms_util.dsinterval_to_minutes(p_time_offset),
           p_value);
      return;
   end seasonal_value_t;

   member procedure init(
      p_offset_months  in integer,
      p_offset_minutes in integer,
      p_value          in number)
   is
   begin
      offset_months  := p_offset_months;
      offset_minutes := p_offset_minutes;
      value          := p_value;
   end init;

end;
