create or replace type body date_range_t
as
--------------------------------------------------------------------------------
-- constructor function date_range_t (0-parameter constructor)
--------------------------------------------------------------------------------
constructor function date_range_t
   return self as result
is
begin
   self.time_zone       := 'UTC';
   self.start_inclusive := 'T';
   self.end_inclusive   := 'T';
   return;
end date_range_t;
--------------------------------------------------------------------------------
-- constructor function date_range_t (2-parameter constructor)
--------------------------------------------------------------------------------
constructor function date_range_t(
   p_start_date date,
   p_end_date   date)
   return self as result
is
begin
   self.start_date      := p_start_date;
   self.end_date        := p_end_date;
   self.time_zone       := 'UTC';
   self.start_inclusive := 'T';
   self.end_inclusive   := 'T';
   return;
end date_range_t;
--------------------------------------------------------------------------------
-- constructor function date_range_t (3-parameter constructor)
--------------------------------------------------------------------------------
constructor function date_range_t(
   p_start_date date,
   p_end_date   date,
   p_time_zone  varchar2)
   return self as result
is
begin
   self.start_date      := p_start_date;
   self.end_date        := p_end_date;
   self.time_zone       := p_time_zone;
   self.start_inclusive := 'T';
   self.end_inclusive   := 'T';
   return;
end date_range_t;
--------------------------------------------------------------------------------
-- constructor function date_range_t (5-parameter constructor)
--------------------------------------------------------------------------------
constructor function date_range_t(
   p_start_date      date,
   p_end_date        date,
   p_time_zone       varchar2,
   p_start_inclusive varchar2,
   p_end_inclusive   varchar2)
   return self as result
is
begin
   self.start_date      := p_start_date;
   self.end_date        := p_end_date;
   self.time_zone       := p_time_zone;
   self.start_inclusive := cwms_util.return_t_or_f_flag(p_start_inclusive);
   self.end_inclusive   := cwms_util.return_t_or_f_flag(p_end_inclusive);
   return;
end date_range_t;
--------------------------------------------------------------------------------
-- member function start_time
--------------------------------------------------------------------------------
member function start_time(
   p_time_zone varchar2 default null)
   return date
is
   l_time_zone  varchar2(28);
   l_start_time date := self.start_date;
begin
   if not cwms_util.return_true_or_false(self.start_inclusive) then
      l_start_time := l_start_time + 1/86400;
   end if;
   l_time_zone := cwms_util.get_time_zone_name(
      case
      when p_time_zone is null then self.time_zone
      else cwms_util.get_time_zone_name(p_time_zone)
      end);
   return case l_time_zone
          when self.time_zone then l_start_time
          else cwms_util.change_timezone(l_start_time, self.time_zone, l_time_zone)
          end;
end start_time;
--------------------------------------------------------------------------------
-- member function end_time
--------------------------------------------------------------------------------
member function end_time(
   p_time_zone varchar2 default null)
   return date
is
   l_time_zone varchar2(28);
   l_end_time  date := self.end_date;
begin
   if not cwms_util.return_true_or_false(self.end_inclusive) then
      l_end_time := l_end_time - 1/86400;
   end if;
   l_time_zone := cwms_util.get_time_zone_name(
      case
      when p_time_zone is null then self.time_zone
      else cwms_util.get_time_zone_name(p_time_zone)
      end);
   return case l_time_zone
          when self.time_zone then l_end_time
          else cwms_util.change_timezone(l_end_time, self.time_zone, l_time_zone)
          end;
end end_time;
--------------------------------------------------------------------------------
-- member function to_string
--------------------------------------------------------------------------------
member function to_string
   return varchar2
is
begin
   return
      to_char(self.start_date, 'yyyy-mm-dd hh24:mi:ss')
      ||' ('||self.start_inclusive||') '
      ||' -> '||to_char(self.end_date, 'yyyy-mm-dd hh24:mi:ss')
      ||' ('||self.end_inclusive||') '
      ||' '||self.time_zone;
end to_string;

end;
/
