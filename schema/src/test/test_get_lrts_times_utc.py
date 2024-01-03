from datetime import datetime
from datetime import timedelta
from zoneinfo import ZoneInfo

time_format1 = "%Y-%m-%d %H:%M"
time_format2 = "%Y-%m-%d %H"
utc = ZoneInfo("UTC")

class DateTimeWithAddMonths(datetime) :
	'''
	Extension of datetime.datetime that allows adding and substracting integer months
	'''
	@staticmethod
	def clone(dt) :
		return DateTimeWithAddMonths(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second, dt.microsecond, dt.tzinfo)

	def get_dt(self) :
		return datetime(self.year, self.month, self.day, self.hour, self.minute, self.second, self.microsecond, self.tzinfo)

	def from_tz(self, tzinfo) :
		return DateTimeWithAddMonths(self.year, self.month, self.day, self.hour, self.minute, self.second, self.microsecond, tzinfo)

	def at_tz(self, tzinfo) :
		return self.clone(self.astimezone(tzinfo))

	def __add__(self, interval) :
		dt = self.get_dt()
		if isinstance(interval, timedelta) :
			dt += interval
		elif isinstance(interval, int) :
			y, m = dt.year, dt.month
			m += interval
			while m > 12 :
				y += 1
				m -= 12
			while m < 1 :
				y -= 1
				m += 12
			dt = dt.replace(year=y, month=m)
		else :
			raise TypeError("Interval must be timedelta object or integer months, not {}".format(interval.__class__.__name__))
		return DateTimeWithAddMonths.clone(dt)

	def __sub__(self, subtrahend) :
		dt = self.get_dt()
		if isinstance(subtrahend, timedelta) :
			dt -= subtrahend
		elif isinstance(subtrahend, datetime) :
			dt -= subtrahend
		elif isinstance(subtrahend, int) :
			y, m = dt.year, dt.month
			m -= subtrahend
			while m > 12 :
				y += 1
				m -= 12
			while m < 1 :
				y -= 1
				m += 12
			dt = dt.replace(year=y, month=m)
		else :
			raise TypeError("Subtrahend must be datetime or timedelta object or integer months, not {}".format(subtrahend.__class__.__name__))
		if isinstance(subtrahend, datetime) :
			return dt
		return DateTimeWithAddMonths.clone(dt)

def interval_name(interval, quote_char=None) :
	if isinstance(interval, timedelta) :
		name = "1Minute"                                     if interval == timedelta(seconds=60)                       \
			else "{}Minutes".format(interval.seconds // 60)  if timedelta(seconds=120) <= interval < timedelta(hours=1) \
			else "1Hour"                                     if interval == timedelta(hours=1)                          \
			else "{}Hours".format(interval.seconds // 3600)  if timedelta(hours=1) < interval < timedelta(days=1)       \
			else "1Day"                                      if interval == timedelta(days=1)                           \
			else "{}Days".format(interval.days)              if timedelta(days=1) < interval < timedelta(days=7)        \
			else "1Week"                                     if interval == timedelta(days=7)                           \
			else None
	elif isinstance(interval, int) :
		name = "1Month"    if interval == 1   \
			else "1Year"   if interval == 12  \
			else "1Decade" if interval == 120 \
			else None
	else :
		raise TypeError("interval must be timedelta object or integer months, not {}".format(interval.__class__.__name__))
	if name is None :
		raise ValueError("Invalid interval: {}".format(interval))
	if quote_char : name = quote_char + name + quote_char
	return name

def get_skipped_hour(year, tz) :
	def utc_offset(dt, tz) :
		dt1 = dt.from_tz(tz).at_tz(utc)
		dt1 = DateTimeWithAddMonths(dt1.year, dt1.month, dt1.day, dt1.hour, dt1.minute, dt1.second)
		return dt1-dt

	dt_low  = DateTimeWithAddMonths(year, 1, 1)
	dt_high = DateTimeWithAddMonths(year, 6, 1)
	summer_offset = utc_offset(dt_high, tz)
	while True :
		dt = dt_low + (dt_high - dt_low) / 2
		dt = dt.replace(microsecond=0)
		if utc_offset(dt, tz) == summer_offset :
			if dt_high - dt < timedelta(hours=1) and dt_high.hour == dt.hour :
				break
			dt_high = dt
		else :
			dt_low = dt
	dt -= timedelta(hours=1)
	return DateTimeWithAddMonths(dt.year, dt.month, dt.day, dt.hour)

def in_skipped_hour(dt) :
	skipped_hour = get_skipped_hour(dt.year, dt.tzinfo)
	return DateTimeWithAddMonths(dt.year, dt.month, dt.day, dt.hour) == skipped_hour

def top_of_interval(dt, interval, zoneinfo, next_interval = False) :
	'''
	increment from Unix epoch to top of interval for dt by interval
	'''
	toi = DateTimeWithAddMonths(1970, 1, 1)
	if isinstance(interval, timedelta) :
		diff = dt - toi
		diff_secs = diff.days * 86400 + diff.seconds
		intvl_secs = interval.days * 86400 + interval.seconds
		count = diff_secs // intvl_secs
		toi += timedelta(seconds = count * intvl_secs)
		toi = DateTimeWithAddMonths.clone(toi)
	while toi < dt :
		toi += interval
	if not next_interval and toi > dt :
		toi -= interval
	toi = DateTimeWithAddMonths(toi.year, toi.month, toi.day, toi.hour, toi.minute, toi.second, tzinfo=zoneinfo)
	toi_prev = toi-interval
	toi_next = toi+interval
	tois = [toi for toi in [toi_prev, toi, toi_next] if not isinstance(interval, int) and interval < timedelta(hours=1) or not in_skipped_hour(toi)]
	tois = [toi.at_tz(utc).at_tz(zoneinfo) for toi in tois]
	if len(tois) == 2 :
		s = "   test_returned_times(cwms_t_date_table(d('{0}'),d('{1}')), {2:>33s}, 'US/Central');".format(
			tois[0].strftime(time_format1),
			tois[1].strftime(time_format1),
			interval_name(interval, "'"))
	else :
		s = "   test_returned_times(cwms_t_date_table(d('{0}'),d('{1}'),d('{2}')), {3:>11s}, 'US/Central');".format(
			tois[0].strftime(time_format1),
			tois[1].strftime(time_format1),
			tois[2].strftime(time_format1),
			interval_name(interval, "'"))
	print(s)

tz = ZoneInfo("US/Central")

print("   ------------------------------------------------------------")
print("   -- test crossing spring DST boundary with 0100 local time --")
print("   ------------------------------------------------------------")
dt = DateTimeWithAddMonths(2020, 3, 8, 1)
top_of_interval(dt, timedelta(hours=1), tz, False)
top_of_interval(dt, timedelta(hours=2), tz, False)
top_of_interval(dt, timedelta(hours=3), tz, False)
top_of_interval(dt, timedelta(hours=4), tz, False)
top_of_interval(dt, timedelta(hours=6), tz, False)
top_of_interval(dt, timedelta(hours=8), tz, False)
top_of_interval(dt, timedelta(hours=12), tz, False)
top_of_interval(dt, timedelta(days=1), tz, False)
top_of_interval(dt, timedelta(days=2), tz, False)
top_of_interval(dt, timedelta(days=3), tz, False)
top_of_interval(dt, timedelta(days=4), tz, False)
top_of_interval(dt, timedelta(days=5), tz, False)
top_of_interval(dt, timedelta(days=6), tz, False)
top_of_interval(dt, timedelta(days=7), tz, False)
top_of_interval(dt, 1, tz, False)
top_of_interval(dt, 12, tz, False)
top_of_interval(dt, 120, tz, False)

print("   -----------------------------------------------------------------------------------")
print("   -- test crossing spring DST boundary with 0200 local time (unconvertable to UTC) --")
print("   -----------------------------------------------------------------------------------")
dt = DateTimeWithAddMonths(2020, 3, 8, 2)
top_of_interval(dt, timedelta(minutes=1), tz, False)
top_of_interval(dt, timedelta(minutes=2), tz, False)
top_of_interval(dt, timedelta(minutes=3), tz, False)
top_of_interval(dt, timedelta(minutes=4), tz, False)
top_of_interval(dt, timedelta(minutes=5), tz, False)
top_of_interval(dt, timedelta(minutes=6), tz, False)
top_of_interval(dt, timedelta(minutes=8), tz, False)
top_of_interval(dt, timedelta(minutes=10), tz, False)
top_of_interval(dt, timedelta(minutes=12), tz, False)
top_of_interval(dt, timedelta(minutes=15), tz, False)
top_of_interval(dt, timedelta(minutes=20), tz, False)
top_of_interval(dt, timedelta(minutes=30), tz, False)
top_of_interval(dt, timedelta(hours=1), tz, False)
top_of_interval(dt, timedelta(hours=2), tz, False)
top_of_interval(dt, timedelta(hours=3), tz, False)
top_of_interval(dt, timedelta(hours=4), tz, False)
top_of_interval(dt, timedelta(hours=6), tz, False)
top_of_interval(dt, timedelta(hours=8), tz, False)
top_of_interval(dt, timedelta(hours=12), tz, False)
top_of_interval(dt, timedelta(days=1), tz, False)
top_of_interval(dt, timedelta(days=2), tz, False)
top_of_interval(dt, timedelta(days=3), tz, False)
top_of_interval(dt, timedelta(days=4), tz, False)
top_of_interval(dt, timedelta(days=5), tz, False)
top_of_interval(dt, timedelta(days=6), tz, False)
top_of_interval(dt, timedelta(days=7), tz, False)
top_of_interval(dt, 1, tz, False)
top_of_interval(dt, 12, tz, False)
top_of_interval(dt, 120, tz, False)

print("   ------------------------------------------------------------")
print("   -- test crossing spring DST boundary with 0300 local time --")
print("   ------------------------------------------------------------")
dt = DateTimeWithAddMonths(2020, 3, 8, 3)
top_of_interval(dt, timedelta(hours=1), tz, False)
top_of_interval(dt, timedelta(hours=2), tz, False)
top_of_interval(dt, timedelta(hours=3), tz, False)
top_of_interval(dt, timedelta(hours=4), tz, False)
top_of_interval(dt, timedelta(hours=6), tz, False)
top_of_interval(dt, timedelta(hours=8), tz, False)
top_of_interval(dt, timedelta(hours=12), tz, False)
top_of_interval(dt, timedelta(days=1), tz, False)
top_of_interval(dt, timedelta(days=2), tz, False)
top_of_interval(dt, timedelta(days=3), tz, False)
top_of_interval(dt, timedelta(days=4), tz, False)
top_of_interval(dt, timedelta(days=5), tz, False)
top_of_interval(dt, timedelta(days=6), tz, False)
top_of_interval(dt, timedelta(days=7), tz, False)
top_of_interval(dt, 1, tz, False)
top_of_interval(dt, 12, tz, False)
top_of_interval(dt, 120, tz, False)

print("   ----------------------------------------------------------")
print("   -- test crossing fall DST boundary with 0100 local time --")
print("   ----------------------------------------------------------")
dt = DateTimeWithAddMonths(2020, 11, 1, 1)
top_of_interval(dt, timedelta(hours=1), tz, False)
top_of_interval(dt, timedelta(hours=2), tz, False)
top_of_interval(dt, timedelta(hours=3), tz, False)
top_of_interval(dt, timedelta(hours=4), tz, False)
top_of_interval(dt, timedelta(hours=6), tz, False)
top_of_interval(dt, timedelta(hours=8), tz, False)
top_of_interval(dt, timedelta(hours=12), tz, False)
top_of_interval(dt, timedelta(days=1), tz, False)
top_of_interval(dt, timedelta(days=2), tz, False)
top_of_interval(dt, timedelta(days=3), tz, False)
top_of_interval(dt, timedelta(days=4), tz, False)
top_of_interval(dt, timedelta(days=5), tz, False)
top_of_interval(dt, timedelta(days=6), tz, False)
top_of_interval(dt, timedelta(days=7), tz, False)
top_of_interval(dt, 1, tz, False)
top_of_interval(dt, 12, tz, False)
top_of_interval(dt, 120, tz, False)

print("   ----------------------------------------------------------")
print("   -- test crossing fall DST boundary with 0200 local time --")
print("   ----------------------------------------------------------")
dt = DateTimeWithAddMonths(2020, 11, 1, 2)
top_of_interval(dt, timedelta(minutes=1), tz, False)
top_of_interval(dt, timedelta(minutes=2), tz, False)
top_of_interval(dt, timedelta(minutes=3), tz, False)
top_of_interval(dt, timedelta(minutes=4), tz, False)
top_of_interval(dt, timedelta(minutes=5), tz, False)
top_of_interval(dt, timedelta(minutes=6), tz, False)
top_of_interval(dt, timedelta(minutes=8), tz, False)
top_of_interval(dt, timedelta(minutes=10), tz, False)
top_of_interval(dt, timedelta(minutes=12), tz, False)
top_of_interval(dt, timedelta(minutes=15), tz, False)
top_of_interval(dt, timedelta(minutes=20), tz, False)
top_of_interval(dt, timedelta(minutes=30), tz, False)
top_of_interval(dt, timedelta(hours=1), tz, False)
top_of_interval(dt, timedelta(hours=2), tz, False)
top_of_interval(dt, timedelta(hours=3), tz, False)
top_of_interval(dt, timedelta(hours=4), tz, False)
top_of_interval(dt, timedelta(hours=6), tz, False)
top_of_interval(dt, timedelta(hours=8), tz, False)
top_of_interval(dt, timedelta(hours=12), tz, False)
top_of_interval(dt, timedelta(days=1), tz, False)
top_of_interval(dt, timedelta(days=2), tz, False)
top_of_interval(dt, timedelta(days=3), tz, False)
top_of_interval(dt, timedelta(days=4), tz, False)
top_of_interval(dt, timedelta(days=5), tz, False)
top_of_interval(dt, timedelta(days=6), tz, False)
top_of_interval(dt, timedelta(days=7), tz, False)
top_of_interval(dt, 1, tz, False)
top_of_interval(dt, 12, tz, False)
top_of_interval(dt, 120, tz, False)

print("   ----------------------------------------------------------")
print("   -- test crossing fall DST boundary with 0300 local time --")
print("   ----------------------------------------------------------")
dt = DateTimeWithAddMonths(2020, 11, 1, 3)
top_of_interval(dt, timedelta(hours=1), tz, False)
top_of_interval(dt, timedelta(hours=2), tz, False)
top_of_interval(dt, timedelta(hours=3), tz, False)
top_of_interval(dt, timedelta(hours=4), tz, False)
top_of_interval(dt, timedelta(hours=6), tz, False)
top_of_interval(dt, timedelta(hours=8), tz, False)
top_of_interval(dt, timedelta(hours=12), tz, False)
top_of_interval(dt, timedelta(days=1), tz, False)
top_of_interval(dt, timedelta(days=2), tz, False)
top_of_interval(dt, timedelta(days=3), tz, False)
top_of_interval(dt, timedelta(days=4), tz, False)
top_of_interval(dt, timedelta(days=5), tz, False)
top_of_interval(dt, timedelta(days=6), tz, False)
top_of_interval(dt, timedelta(days=7), tz, False)
top_of_interval(dt, 1, tz, False)
top_of_interval(dt, 12, tz, False)
top_of_interval(dt, 120, tz, False)
