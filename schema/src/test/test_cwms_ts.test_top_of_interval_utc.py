from datetime import datetime
from datetime import timedelta

class DateTimeWithAddMonths(datetime) :
	'''
	Extension of datetime.datetime that allows adding and substracting integer months
	'''
	@staticmethod
	def clone(dt) :
		return DateTimeWithAddMonths(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second, dt.microsecond)

	def get_dt(self) :
		return datetime(self.year, self.month, self.day, self.hour, self.minute, self.second, self.microsecond)

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
			raise TypeError("Interval must be timedelta object or integer months")
		return DateTimeWithAddMonths.clone(dt)

	def __sub__(self, interval) :
		dt = self.get_dt()
		if isinstance(interval, timedelta) :
			dt -= interval
		elif isinstance(interval, int) :
			y, m = dt.year, dt.month
			m -= interval
			while m > 12 :
				y += 1
				m -= 12
			while m < 1 :
				y -= 1
				m += 12
			dt = dt.replace(year=y, month=m)
		else :
			raise TypeError("Interval must be timedelta object or integer months")
		return DateTimeWithAddMonths.clone(dt)

def top_of_interval(dt, interval, intvl_tz_offset_hours = 0, next_interval = False) :
	'''
	increment from Unix epoch to top of interval for dt by interval
	'''
	toi = DateTimeWithAddMonths(1970,1,1)
	if intvl_tz_offset_hours != 0 :
		toi += timedelta(hours = intvl_tz_offset_hours)
	if isinstance(interval, timedelta) :
		diff = dt - toi
		diff_secs = diff.days * 86400 + diff.seconds
		intvl_secs = interval.days * 86400 + interval.seconds
		count = diff_secs // intvl_secs
		toi += timedelta(seconds = count * intvl_secs)
	while toi < dt :
		toi += interval
	if not next_interval and toi > dt :
		toi -= interval
	return toi.strftime("%Y-%m-%d %H:%M")

dt = datetime(2020, 1, 1, 0, 1)

print("-----------------------------------------------")
print("-- test previous interval, interval tz = UTC --")
print("-----------------------------------------------")
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Minute',   'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=1), 0, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '2Minutes',  'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=2), 0, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '3Minutes',  'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=3), 0, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '4Minutes',  'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=4), 0, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '5Minutes',  'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=5), 0, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '6Minutes',  'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=6), 0, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '8Minutes',  'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=8), 0, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '10Minutes', 'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=10), 0, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '12Minutes', 'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=12), 0, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '15Minutes', 'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=15), 0, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '20Minutes', 'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=20), 0, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '30Minutes', 'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=30), 0, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Hour',     'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(hours=1), 0, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '2Hours',    'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(hours=2), 0, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '3Hours',    'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(hours=3), 0, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '4Hours',    'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(hours=4), 0, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '6Hours',    'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(hours=6), 0, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '8Hours',    'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(hours=8), 0, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '12Hours',   'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(hours=12), 0, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Day',      'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(days=1), 0, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '2Days',     'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(days=2), 0, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '3Days',     'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(days=3), 0, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '4Days',     'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(days=4), 0, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '5Days',     'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(days=5), 0, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '6Days',     'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(days=6), 0, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Week',     'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(days=7), 0, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Month',    'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, 1, 0, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Year',     'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, 12, 0, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Decade',   'UTC', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, 120, 0, False)))
print("-------------------------------------------")
print("-- test next interval, interval tz = UTC --")
print("-------------------------------------------")
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Minute',   'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=1), 0, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '2Minutes',  'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=2), 0, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '3Minutes',  'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=3), 0, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '4Minutes',  'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=4), 0, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '5Minutes',  'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=5), 0, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '6Minutes',  'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=6), 0, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '8Minutes',  'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=8), 0, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '10Minutes', 'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=10), 0, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '12Minutes', 'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=12), 0, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '15Minutes', 'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=15), 0, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '20Minutes', 'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=20), 0, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '30Minutes', 'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=30), 0, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Hour',     'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(hours=1), 0, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '2Hours',    'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(hours=2), 0, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '3Hours',    'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(hours=3), 0, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '4Hours',    'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(hours=4), 0, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '6Hours',    'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(hours=6), 0, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '8Hours',    'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(hours=8), 0, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '12Hours',   'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(hours=12), 0, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Day',      'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(days=1), 0, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '2Days',     'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(days=2), 0, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '3Days',     'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(days=3), 0, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '4Days',     'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(days=4), 0, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '5Days',     'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(days=5), 0, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '6Days',     'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(days=6), 0, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Week',     'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(days=7), 0, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Month',    'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, 1, 0, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Year',     'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, 12, 0, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Decade',   'UTC', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, 120, 0, True)))
print("------------------------------------------------------")
print("-- test previous interval, interval tz = US/Pacific --")
print("------------------------------------------------------")
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Minute',   'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=1), 8, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '2Minutes',  'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=2), 8, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '3Minutes',  'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=3), 8, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '4Minutes',  'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=4), 8, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '5Minutes',  'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=5), 8, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '6Minutes',  'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=6), 8, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '8Minutes',  'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=8), 8, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '10Minutes', 'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=10), 8, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '12Minutes', 'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=12), 8, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '15Minutes', 'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=15), 8, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '20Minutes', 'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=20), 8, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '30Minutes', 'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=30), 8, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Hour',     'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(hours=1), 8, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '2Hours',    'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(hours=2), 8, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '3Hours',    'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(hours=3), 8, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '4Hours',    'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(hours=4), 8, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '6Hours',    'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(hours=6), 8, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '8Hours',    'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(hours=8), 8, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '12Hours',   'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(hours=12), 8, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Day',      'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(days=1), 8, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '2Days',     'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(days=2), 8, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '3Days',     'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(days=3), 8, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '4Days',     'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(days=4), 8, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '5Days',     'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(days=5), 8, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '6Days',     'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(days=6), 8, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Week',     'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(days=7), 8, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Month',    'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, 1, 8, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Year',     'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, 12, 8, False)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Decade',   'US/Pacific', 'F')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, 120, 8, False)))
print("--------------------------------------------------")
print("-- test next interval, interval tz = US/Pacific --")
print("--------------------------------------------------")
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Minute',   'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=1), 8, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '2Minutes',  'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=2), 8, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '3Minutes',  'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=3), 8, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '4Minutes',  'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=4), 8, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '5Minutes',  'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=5), 8, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '6Minutes',  'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=6), 8, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '8Minutes',  'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=8), 8, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '10Minutes', 'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=10), 8, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '12Minutes', 'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=12), 8, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '15Minutes', 'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=15), 8, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '20Minutes', 'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=20), 8, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '30Minutes', 'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(minutes=30), 8, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Hour',     'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(hours=1), 8, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '2Hours',    'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(hours=2), 8, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '3Hours',    'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(hours=3), 8, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '4Hours',    'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(hours=4), 8, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '6Hours',    'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(hours=6), 8, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '8Hours',    'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(hours=8), 8, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '12Hours',   'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(hours=12), 8, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Day',      'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(days=1), 8, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '2Days',     'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(days=2), 8, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '3Days',     'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(days=3), 8, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '4Days',     'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(days=4), 8, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '5Days',     'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(days=5), 8, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '6Days',     'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(days=6), 8, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Week',     'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, timedelta(days=7), 8, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Month',    'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, 1, 8, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Year',     'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, 12, 8, True)))
print("ut.expect(cwms_ts.top_of_interval_utc(l_utc_time, '1Decade',   'US/Pacific', 'T')).to_equal(to_date('{}', l_date_fmt));".format(top_of_interval(dt, 120, 8, True)))
