from decimal import *
from mathComputations import Computation
import re, string, StringIO, traceback, datetime

getcontext().prec = 16 # floating point precision to use

regexQuant    = r'(([a-z0-9_ /*-]+_per_[a-z0-9_ /*-]+)(\^(\d+))?)'
regexUnit     = r'(\[(.+?)\])'
regexFunction = r'function%s/%s' % (regexUnit, regexUnit)
regexIdent    = '(%s?%s/%s?%s|%s)' % (regexQuant, regexUnit, regexQuant, regexUnit, regexFunction)
patternIdent  = re.compile(regexIdent, re.I)
patternFunc   = re.compile(regexFunction, re.I)

#
# Base unit conversion factors to be used in the dimensional analysis
#
conversion_factors = {
#
#	English from NIST (http://physics.nist.gov/cuu/pdf/sp811.pdf)
#
	'ftUS_per_ft'      : Decimal('0.999998'),         # pg 42-3
	'ftUS_per_miUS'    : Decimal('5280'),             # pg 42-3 (not used)
#
#	English
#
	'ft_per_mile'      : Decimal('5280'),
	'in_per_ft'        : Decimal('12'),
	'ft2_per_acre'     : Decimal('43560'), # technically incorrect - 1 acre == 43560 ftUS
	'lbm_per_ton'      : Decimal('2e3'),
#
#	SI
#
	'l_per_m3'         : Decimal('1e3'),
	'm2_per_ha'        : Decimal('1e4'),
	'C_per_K'          : Decimal(1),
	'kg_per_tonne'     : Decimal('1e3'), # pg 63
#
#	English-->SI from NIST (http://physics.nist.gov/cuu/pdf/sp811.pdf)
#
	'J/m2_per_langley' : Decimal('4.184e4'),              # pg 51
	'kg_per_lbm'       : Decimal('4.5359237e-1'),         # pg 53 (footnote)
	'm/s_per_knot'     : Decimal('1852')/Decimal('3600'), # pg 10
	'm3_per_gal'       : Decimal('3.785412e-3'),          # pg 50
	'm_per_ft'         : Decimal('3.048e-1'),             # pg 49
	'Pa_per_bar'       : Decimal('1e5'),                  # pg 45
	'Pa_per_in-hg'     : Decimal('3.386389e3'),           # pg 50
	'Pa_per_mm-hg'     : Decimal('1.333224e2'),           # pg 52
	'Pa_per_psi'       : Decimal('6.894757e3'),           # pg 53
	'C_per_F'          : Decimal('1')/Decimal('1.8'),     # pg 48
	'rad_per_deg'      : Decimal('1.745329e-2'),          # pg 48
#
#	energy
#
	'J_per_Wh'         : Decimal('3.6e3'),                # pg 55
	'J_per_cal'        : Decimal('4.184e00'),             # pg 47 calorie_thermochemical
#
#	gravitational acceleration
#
	'm/s2_per_g'       : Decimal('9.80665'),              # pg 53 (footnote)
#
#	time
#
        'day_per_mon'      : Decimal('30.4375'),              # nominal
	'hr_per_day'       : Decimal('24'),                   # pg 8
	'min_per_hr'       : Decimal('60'),                   # pg 8
	's_per_min'        : Decimal('60'),                   # pg 8
#
#	angle
#
	'deg_per_rev'      : Decimal('360'),
#
#	scale
#
	'u*_per_*'         : Decimal('1e6'),  # micro-
	'm*_per_*'         : Decimal('1e3'),  # milli-
	'c*_per_*'         : Decimal('1e2'),  # centi-
	'*_per_k*'         : Decimal('1e3'),  # kilo-
	'*_per_M*'         : Decimal('1e6'),  # mega-
	'*_per_G*'         : Decimal('1e9'),  # giga-
	'*_per_T*'         : Decimal('1e12'), # tera-
}

#
# Handy conversion factors that can be derived from the base factors
#
conversion_factors['km_per_mile'] = conversion_factors['ft_per_mile'] * conversion_factors['m_per_ft']   / conversion_factors['*_per_k*']
conversion_factors['min_per_day'] = conversion_factors['min_per_hr']  * conversion_factors['hr_per_day']
conversion_factors['s_per_hr']    = conversion_factors['s_per_min']   * conversion_factors['min_per_hr']
conversion_factors['s_per_day']   = conversion_factors['s_per_hr']    * conversion_factors['hr_per_day']
conversion_factors['s_per_mon']   = conversion_factors['s_per_day']   * conversion_factors['day_per_mon']
conversion_factors['ft3_per_dsf'] = conversion_factors['s_per_day']
#
# Offsets for conversions that require them (applied after factors)
#
offsets = {
	'C_to_F' : Decimal('32'),
	'C_to_K' : Decimal('273.15'),
	'F_to_C' : Decimal('-32') * conversion_factors['C_per_F'],
	'K_to_C' : Decimal('-273.15'),
}
#
# Functions for conversions that require them (used instead of factors and offsets)
#
functions = {
	'Hz_to_B' : 'ARG 0|2|^|1000|/',
	'B_to_Hz' : 'ARG 0|1000|*|.5|^',
	'F_to_K'  : 'ARG 0|32|-|1.8|/|273.15|+',
	'K_to_F'  : 'ARG 0|273.15|-|1.8|*|32|+',
}
#
# Conversion definitions in dimensional analysis format
#
# Conversion identities are separated by  the | character
#
# Each identity requires a numerator and a denominator with units enclosed in [] characters
#
# The numerator and/or denominator may also have quantities which must be specified
# as keys into the conversion_factors dictionary.  Quantities may be exponentiated
# using the ^ character
#
conversion_definitions = [
#
#	from_unit      to_unit         conversion identities
#	-------------  -------------   --------------------------------------------------------------------------------------------
	('$',           'k$',          '[k$]/*_per_k*[$]'),
	('$/kaf',       '$/mcm',       '[kaf]/*_per_k*[ac-ft] | [ac-ft]/ft2_per_acre[ft3] | [ft3]/m_per_ft^3[m3] | *_per_M*[m3]/[mcm]'),
	('$/mcm',       '$/kaf',       '[mcm]/*_per_M*[m3] | m_per_ft^3[m3]/[ft3] | ft2_per_acre[ft3]/[ac-ft] | *_per_k*[ac-ft]/[kaf]'),
	('%',           'n/a',         '[n/a]/c*_per_*[%]'),
	('1/ft',        '1/m',         '[ft]/m_per_ft[m]'),
	('1/m',         '1/ft',        'm_per_ft[m]/[ft]'),
	('1000 acre',   '1000 m2',     '*_per_k*[acre]/[1000 acre] | ft2_per_acre[ft2]/[acre] | m_per_ft^2[m2]/[ft2] | [1000 m2]/*_per_k*[m2]'),
	('1000 acre',   'acre',        '*_per_k*[acre]/[1000 acre]'),
	('1000 acre',   'cm2',         '*_per_k*[acre]/[1000 acre] | ft2_per_acre[ft2]/[acre] | m_per_ft^2[m2]/[ft2] | c*_per_*^2[cm2]/[m2]'),
	('1000 acre',   'ft2',         '*_per_k*[acre]/[1000 acre] | ft2_per_acre[ft2]/[acre]'),
	('1000 acre',   'ha',          '*_per_k*[acre]/[1000 acre] | ft2_per_acre[ft2]/[acre] | m_per_ft^2[m2]/[ft2] | [ha]/m2_per_ha[m2]'),
	('1000 acre',   'km2',         '*_per_k*[acre]/[1000 acre] | ft2_per_acre[ft2]/[acre] | m_per_ft^2[m2]/[ft2] | [km2]/*_per_k*^2[m2]'),
	('1000 acre',   'm2',          '*_per_k*[acre]/[1000 acre] | ft2_per_acre[ft2]/[acre] | m_per_ft^2[m2]/[ft2]'),
	('1000 acre',   'mile2',       '*_per_k*[acre]/[1000 acre] | ft2_per_acre[ft2]/[acre] | [mile2]/ft_per_mile^2[ft2]'),
	('1000 m2',     '1000 acre',   '*_per_k*[m2]/[1000 m2] | [ft2]/m_per_ft^2[m2] | [acre]/ft2_per_acre[ft2] | [1000 acre]/*_per_k*[acre]'),
	('1000 m2',     'acre',        '*_per_k*[m2]/[1000 m2] | [ft2]/m_per_ft^2[m2] | [acre]/ft2_per_acre[ft2]'),
	('1000 m2',     'cm2',         '*_per_k*[m2]/[1000 m2] | c*_per_*^2[cm2]/[m2]'),
	('1000 m2',     'ft2',         '*_per_k*[m2]/[1000 m2] | [ft2]/m_per_ft^2[m2]'),
	('1000 m2',     'ha',          '*_per_k*[m2]/[1000 m2] | [ha]/m2_per_ha[m2]'),
	('1000 m2',     'km2',         '*_per_k*[m2]/[1000 m2] | [km2]/*_per_k*^2[m2]'),
	('1000 m2',     'm2',          '*_per_k*[m2]/[1000 m2]'),
	('1000 m2',     'mile2',       '*_per_k*[m2]/[1000 m2] | [ft2]/m_per_ft^2[m2] | [mile2]/ft_per_mile^2[ft2]'),
	('1000 m3',     'ac-ft',       '*_per_k*[m3]/[1000 m3] | [ft3]/m_per_ft^3[m3] | [ac-ft]/ft2_per_acre[ft3]'),
	('1000 m3',     'dsf',         '*_per_k*[m3]/[1000 m3] | [ft3]/m_per_ft^3[m3] | [dsf]/ft3_per_dsf[ft3]'),
	('1000 m3',     'ft3',         '*_per_k*[m3]/[1000 m3] | [ft3]/m_per_ft^3[m3]'),
	('1000 m3',     'gal',         '*_per_k*[m3]/[1000 m3] | [gal]/m3_per_gal[m3]'),
	('1000 m3',     'kaf',         '*_per_k*[m3]/[1000 m3] | [ft3]/m_per_ft^3[m3] | [ac-ft]/ft2_per_acre[ft3] | [kaf]/*_per_k*[ac-ft]'),
	('1000 m3',     'kdsf',        '*_per_k*[m3]/[1000 m3] | [ft3]/m_per_ft^3[m3] | [dsf]/ft3_per_dsf[ft3] | [kdsf]/*_per_k*[dsf]'),
	('1000 m3',     'kgal',        '*_per_k*[m3]/[1000 m3] | [gal]/m3_per_gal[m3] | [kgal]/*_per_k*[gal]'),
	('1000 m3',     'km3',         '*_per_k*[m3]/[1000 m3] | [km3]/*_per_k*^3[m3]'),
	('1000 m3',     'm3',          '*_per_k*[m3]/[1000 m3]'),
	('1000 m3',     'mcm',         '*_per_k*[m3]/[1000 m3] | [mcm]/*_per_M*[m3]'),
	('1000 m3',     'mgal',        '*_per_k*[m3]/[1000 m3] | [gal]/m3_per_gal[m3] | [mgal]/*_per_M*[gal]'),
	('1000 m3',     'mile3',       '*_per_k*[m3]/[1000 m3] | [ft3]/m_per_ft^3[m3] | [mile3]/ft_per_mile^3[ft3]'),
	('B',           'Hz',          'function[Hz]/[B]'),
	('B',           'MHz',         'function[Hz]/[B] | [MHz]/*_per_M*[Hz]'),
	('B',           'kHz',         'function[Hz]/[B] | [kHz]/*_per_k*[Hz]'),
	('C',           'F',           '[F]/C_per_F[C]'),
	('C',           'K',           '[K]/C_per_K[C]'),
	('C-day',       'F-day',       '[F-day]/C_per_F[C-day]'),
	('F',           'C',           'C_per_F[C]/[F]'),
	('F',           'K',           'function[K]/[F]'),
	('F-day',       'C-day',       'C_per_F[C-day]/[F-day]'),
	('GW',          'MW',          '*_per_G*[W]/[GW] | [MW]/*_per_M*[W]'),
	('GW',          'TW',          '*_per_G*[W]/[GW] | [TW]/*_per_T*[W]'),
	('GW',          'W',           '*_per_G*[W]/[GW]'),
	('GW',          'kW',          '*_per_G*[W]/[GW] | [kW]/*_per_k*[W]'),
	('GWh',         'J',           '*_per_G*[Wh]/[GWh] | J_per_Wh[J]/[Wh]'),
	('GWh',         'MJ',          '*_per_G*[Wh]/[GWh] | J_per_Wh[J]/[Wh] | [MJ]/*_per_M*[J]'),
	('GWh',         'MWh',         '*_per_G*[Wh]/[GWh] | [MWh]/*_per_M*[Wh]'),
	('GWh',         'TWh',         '*_per_G*[Wh]/[GWh] | [TWh]/*_per_T*[Wh]'),
	('GWh',         'Wh',          '*_per_G*[Wh]/[GWh]'),
	('GWh',         'cal',         '*_per_G*[Wh]/[GWh] | J_per_Wh[J]/[Wh] | [cal]/J_per_cal[J]'),
	('GWh',         'kWh',         '*_per_G*[Wh]/[GWh] | [kWh]/*_per_k*[Wh]'),
	('Hz',          'B',           'function[B]/[Hz]'),
	('Hz',          'MHz',         '[MHz]/*_per_M*[Hz]'),
	('Hz',          'kHz',         '[kHz]/*_per_k*[Hz]'),
	('J',           'GWh',         '[Wh]/J_per_Wh[J] | [GWh]/*_per_G*[Wh]'),
	('J',           'MJ',          '[MJ]/*_per_M*[J]'),
	('J',           'MWh',         '[Wh]/J_per_Wh[J] | [MWh]/*_per_M*[Wh]'),
	('J',           'TWh',         '[Wh]/J_per_Wh[J] | [TWh]/*_per_T*[Wh]'),
	('J',           'Wh',          '[Wh]/J_per_Wh[J]'),
	('J',           'cal',         '[cal]/J_per_cal[J]'),
	('J',           'kWh',         '[Wh]/J_per_Wh[J] | [kWh]/*_per_k*[Wh]'),
	('J/m2',        'langley',     '[langley]/J/m2_per_langley[J/m2]'),
	('K',           'C',           'C_per_K[C]/[K]'),
	('K',           'F',           'function[F]/[K]'),
	('KAF/mon',     'cfs',         '[kaf]/[KAF] | *_per_k*[ac-ft]/[kaf] | ft2_per_acre[ft3]/[ac-ft] | [mon]/s_per_mon[s] | [cfs]/[ft3/s]'),
	('KAF/mon',     'cms',         '[kaf]/[KAF] | *_per_k*[ac-ft]/[kaf] | ft2_per_acre[ft3]/[ac-ft] | [mon]/s_per_mon[s] | m_per_ft^3[m3]/[ft3] | [cms]/[m3/s]'),
	('KAF/mon',     'gpm',         '[kaf]/[KAF] | *_per_k*[ac-ft]/[kaf] | ft2_per_acre[ft3]/[ac-ft] | [mon]/s_per_mon[s] | m_per_ft^3[m3]/[ft3] | [gal]/m3_per_gal[m3] | s_per_min[s]/[min] | [gpm]/[gal/min]'),
	('KAF/mon',     'kcfs',        '[kaf]/[KAF] | *_per_k*[ac-ft]/[kaf] | ft2_per_acre[ft3]/[ac-ft] | [mon]/s_per_mon[s] | [cfs]/[ft3/s] | [kcfs]/*_per_k*[cfs]'),
	('KAF/mon',     'kcms',        '[kaf]/[KAF] | *_per_k*[ac-ft]/[kaf] | ft2_per_acre[ft3]/[ac-ft] | [mon]/s_per_mon[s] | m_per_ft^3[m3]/[ft3] | [cms]/[m3/s] | [kcms]/*_per_k*[cms]'),
	('KAF/mon',     'mcm/mon',     ' [kaf]/[KAF] | *_per_k*[ac-ft]/[kaf] | ft2_per_acre[ft3]/[ac-ft] | m_per_ft^3[m3]/[ft3] | [mcm]/*_per_M*[m3]'),
	('KAF/mon',     'mcm/mon',     '[kaf]/[KAF] | *_per_k*[ac-ft]/[kaf] | ft2_per_acre[ft3]/[ac-ft] | m_per_ft^3[m3]/[ft3] | [mcm]/*_per_M*[m3]'),
	('KAF/mon',     'mgd',         '[kaf]/[KAF] | *_per_k*[ac-ft]/[kaf] | ft2_per_acre[ft3]/[ac-ft] | [mon]/s_per_mon[s] | m_per_ft^3[m3]/[ft3] | [gal]/m3_per_gal[m3] | [mgal]/*_per_M*[gal] | s_per_day[s]/[day] | [mgd]/[mgal/day]'),
	('MHz',         'B',           '*_per_M*[Hz]/[MHz] | function[B]/[Hz]'),
	('MHz',         'Hz',          '*_per_M*[Hz]/[MHz]'),
	('MHz',         'kHz',         '*_per_M*[Hz]/[MHz] | [kHz]/*_per_k*[Hz]'),
	('MJ',          'GWh',         '*_per_M*[J]/[MJ] | [Wh]/J_per_Wh[J] | [GWh]/*_per_G*[Wh]'),
	('MJ',          'J',           '*_per_M*[J]/[MJ]'),
	('MJ',          'MWh',         '*_per_M*[J]/[MJ] | [Wh]/J_per_Wh[J] | [MWh]/*_per_M*[Wh]'),
	('MJ',          'TWh',         '*_per_M*[J]/[MJ] | [Wh]/J_per_Wh[J] | [TWh]/*_per_T*[Wh]'),
	('MJ',          'Wh',          '*_per_M*[J]/[MJ] | [Wh]/J_per_Wh[J]'),
	('MJ',          'cal',         '*_per_M*[J]/[MJ] | [cal]/J_per_cal[J]'),
	('MJ',          'kWh',         '*_per_M*[J]/[MJ] | [Wh]/J_per_Wh[J] | [kWh]/*_per_k*[Wh]'),
	('MW',          'GW',          '*_per_M*[W]/[MW] | [GW]/*_per_G*[W]'),
	('MW',          'TW',          '*_per_M*[W]/[MW] | [TW]/*_per_T*[W]'),
	('MW',          'W',           '*_per_M*[W]/[MW]'),
	('MW',          'kW',          '*_per_M*[W]/[MW] | [kW]/*_per_k*[W]'),
	('MWh',         'GWh',         '*_per_M*[Wh]/[MWh] | [GWh]/*_per_G*[Wh]'),
	('MWh',         'J',           '*_per_M*[Wh]/[MWh] | J_per_Wh[J]/[Wh]'),
	('MWh',         'MJ',          '*_per_M*[Wh]/[MWh] | J_per_Wh[J]/[Wh] | [MJ]/*_per_M*[J]'),
	('MWh',         'TWh',         '*_per_M*[Wh]/[MWh] | [TWh]/*_per_T*[Wh]'),
	('MWh',         'Wh',          '*_per_M*[Wh]/[MWh]'),
	('MWh',         'cal',         '*_per_M*[Wh]/[MWh] | J_per_Wh[J]/[Wh] | [cal]/J_per_cal[J]'),
	('MWh',         'kWh',         '*_per_M*[Wh]/[MWh] | [kWh]/*_per_k*[Wh]'),
	('N',           'lb',          '[kg*m/s2]/[N] | [lbm]/kg_per_lbm[kg] | [g]/m/s2_per_g[m/s2] | [lb]/[lbm*g]'),
	('S',           'mho',         '[mho]/[S]'),
	('S',           'uS',          'u*_per_*[uS]/[S]'),
	('S',           'umho',        'u*_per_*[umho]/[S]'),
	('TW',          'GW',          '*_per_T*[W]/[TW] | [GW]/*_per_G*[W]'),
	('TW',          'MW',          '*_per_T*[W]/[TW] | [MW]/*_per_M*[W]'),
	('TW',          'W',           '*_per_T*[W]/[TW]'),
	('TW',          'kW',          '*_per_T*[W]/[TW] | [kW]/*_per_k*[W]'),
	('TWh',         'GWh',         '*_per_T*[Wh]/[TWh] | [GWh]/*_per_G*[Wh]'),
	('TWh',         'J',           '*_per_T*[Wh]/[TWh] | J_per_Wh[J]/[Wh]'),
	('TWh',         'MJ',          '*_per_T*[Wh]/[TWh] | J_per_Wh[J]/[Wh] | [MJ]/*_per_M*[J]'),
	('TWh',         'MWh',         '*_per_T*[Wh]/[TWh] | [MWh]/*_per_M*[Wh]'),
	('TWh',         'Wh',          '*_per_T*[Wh]/[TWh]'),
	('TWh',         'cal',         '*_per_T*[Wh]/[TWh] | J_per_Wh[J]/[Wh] | [cal]/J_per_cal[J]'),
	('TWh',         'kWh',         '*_per_T*[Wh]/[TWh] | [kWh]/*_per_k*[Wh]'),
	('W',           'GW',          '[GW]/*_per_G*[W]'),
	('W',           'MW',          '[MW]/*_per_M*[W]'),
	('W',           'TW',          '[TW]/*_per_T*[W]'),
	('W',           'kW',          '[kW]/*_per_k*[W]'),
	('W/m2',        'langley/min', '[J/s]/[W] | [langley]/J/m2_per_langley[J/m2] | s_per_min[s]/[min]'),
	('Wh',          'GWh',         '[GWh]/*_per_G*[Wh]'),
	('Wh',          'J',           'J_per_Wh[J]/[Wh]'),
	('Wh',          'MJ',          'J_per_Wh[J]/[Wh] | [MJ]/*_per_M*[J]'),
	('Wh',          'MWh',         '[MWh]/*_per_M*[Wh]'),
	('Wh',          'TWh',         '[TWh]/*_per_T*[Wh]'),
	('Wh',          'cal',         'J_per_Wh[J]/[Wh] | [cal]/J_per_cal[J]'),
	('Wh',          'kWh',         '[kWh]/*_per_k*[Wh]'),
	('ac-ft',       '1000 m3',     'ft2_per_acre[ft3]/[ac-ft] | m_per_ft^3[m3]/[ft3] | [1000 m3]/*_per_k*[m3]'),
	('ac-ft',       'dsf',         'ft2_per_acre[ft3]/[ac-ft] | [dsf]/ft3_per_dsf[ft3]'),
	('ac-ft',       'ft3',         'ft2_per_acre[ft3]/[ac-ft]'),
	('ac-ft',       'gal',         'ft2_per_acre[ft3]/[ac-ft] | m_per_ft^3[m3]/[ft3] | [gal]/m3_per_gal[m3]'),
	('ac-ft',       'kaf',         '[kaf]/*_per_k*[ac-ft]'),
	('ac-ft',       'kdsf',        'ft2_per_acre[ft3]/[ac-ft] | [dsf]/ft3_per_dsf[ft3] | [kdsf]/*_per_k*[dsf]'),
	('ac-ft',       'kgal',        'ft2_per_acre[ft3]/[ac-ft] | m_per_ft^3[m3]/[ft3] | [gal]/m3_per_gal[m3] | [kgal]/*_per_k*[gal]'),
	('ac-ft',       'km3',         'ft2_per_acre[ft3]/[ac-ft] | m_per_ft^3[m3]/[ft3] | [km3]/*_per_k*^3[m3]'),
	('ac-ft',       'm3',          'ft2_per_acre[ft3]/[ac-ft] | m_per_ft^3[m3]/[ft3]'),
	('ac-ft',       'mcm',         'ft2_per_acre[ft3]/[ac-ft] | m_per_ft^3[m3]/[ft3] | [mcm]/*_per_M*[m3]'),
	('ac-ft',       'mgal',        'ft2_per_acre[ft3]/[ac-ft] | m_per_ft^3[m3]/[ft3] | [gal]/m3_per_gal[m3] | [mgal]/*_per_M*[gal]'),
	('ac-ft',       'mile3',       'ft2_per_acre[ft3]/[ac-ft] | [mile3]/ft_per_mile^3[ft3]'),
	('acre',        '1000 m2',     'ft2_per_acre[ft2]/[acre] | m_per_ft^2[m2]/[ft2] | [1000 m2]/*_per_k*[m2]'),
	('acre',        'cm2',         'ft2_per_acre[ft2]/[acre] | m_per_ft^2[m2]/[ft2] | c*_per_*^2[cm2]/[m2]'),
	('acre',        'ft2',         'ft2_per_acre[ft2]/[acre]'),
	('acre',        'ha',          'ft2_per_acre[ft2]/[acre] | m_per_ft^2[m2]/[ft2] | [ha]/m2_per_ha[m2]'),
	('acre',        'km2',         'ft2_per_acre[ft2]/[acre] | m_per_ft^2[m2]/[ft2] | [km2]/*_per_k*^2[m2]'),
	('acre',        'm2',          'ft2_per_acre[ft2]/[acre] | m_per_ft^2[m2]/[ft2]'),
	('acre',        'mile2',       'ft2_per_acre[ft2]/[acre] | [mile2]/ft_per_mile^2[ft2]'),
	('bar',         'in-hg',       'Pa_per_bar[Pa]/[bar] | [in-hg]/Pa_per_in-hg[Pa]'),
	('bar',         'kPa',         'Pa_per_bar[Pa]/[bar] | [kPa]/*_per_k*[Pa]'),
	('bar',         'mb',          'm*_per_*[mb]/[bar]'),
	('bar',         'mm-hg',       'Pa_per_bar[Pa]/[bar] | [mm-hg]/Pa_per_mm-hg[Pa]'),
	('bar',         'psi',         'Pa_per_bar[Pa]/[bar] | [psi]/Pa_per_psi[Pa]'),
	('cal',         'GWh',         'J_per_cal[J]/[cal] | [Wh]/J_per_Wh[J] | [GWh]/*_per_G*[Wh]'),
	('cal',         'J',           'J_per_cal[J]/[cal]'),
	('cal',         'MJ',          'J_per_cal[J]/[cal] | [MJ]/*_per_M*[J]'),
	('cal',         'MWh',         'J_per_cal[J]/[cal] | [Wh]/J_per_Wh[J] | [MWh]/*_per_M*[Wh]'),
	('cal',         'TWh',         'J_per_cal[J]/[cal] | [Wh]/J_per_Wh[J] | [TWh]/*_per_T*[Wh]'),
	('cal',         'Wh',          'J_per_cal[J]/[cal] | [Wh]/J_per_Wh[J]'),
	('cal',         'kWh',         'J_per_cal[J]/[cal] | [Wh]/J_per_Wh[J] | [kWh]/*_per_k*[Wh]'),
	('cfs',         'KAF/mon',     '[ft3/s]/[cfs] | s_per_mon[s]/[mon] | [ac-ft]/ft2_per_acre[ft3] | [kaf]/*_per_k*[ac-ft] | [KAF]/[kaf]'),
	('cfs',         'cms',         '[ft3/s]/[cfs] | m_per_ft^3[m3]/[ft3] | [cms]/[m3/s]'),
	('cfs',         'gpm',         '[ft3/s]/[cfs] | m_per_ft^3[m3]/[ft3] | [gal]/m3_per_gal[m3] | s_per_min[s]/[min] | [gpm]/[gal/min]'),
	('cfs',         'kcfs',        '[kcfs]/*_per_k*[cfs]'),
	('cfs',         'kcms',        '[ft3/s]/[cfs] | m_per_ft^3[m3]/[ft3] | [cms]/[m3/s] | [kcms]/*_per_k*[cms]'),
	('cfs',         'mcm/mon',     '[ft3/s]/[cfs] | s_per_mon[s]/[mon] | m_per_ft^3[m3]/[ft3] | [mcm]/*_per_M*[m3]'),
	('cfs',         'mgd',         '[ft3/s]/[cfs] | m_per_ft^3[m3]/[ft3] | [gal]/m3_per_gal[m3] | [mgal]/*_per_M*[gal] | s_per_day[s]/[day] | [mgd]/[mgal/day]'),
	('cfs/mi2',     'cms/km2',     '[ft3/s]/[cfs] | m_per_ft^3[m3]/[ft3] | [mi2]/km_per_mile^2[km2] | [cms]/[m3/s]'),
	('cm',          'ft',          '[m]/c*_per_*[cm] | [ft]/m_per_ft[m]'),
	('cm',          'ftUS',        '[m]/c*_per_*[cm] | [ft]/m_per_ft[m] | ftUS_per_ft[ftUS]/[ft]'),
	('cm',          'in',          '[m]/c*_per_*[cm] | [ft]/m_per_ft[m] | in_per_ft[in]/[ft]'),
	('cm',          'km',          '[m]/c*_per_*[cm] | [km]/*_per_k*[m]'),
	('cm',          'm',           '[m]/c*_per_*[cm]'),
	('cm',          'mi',          '[m]/c*_per_*[cm] | [ft]/m_per_ft[m] | [mi]/ft_per_mile[ft]'),
	('cm',          'mm',          '[m]/c*_per_*[cm] | m*_per_*[mm]/[m]'),
	('cm/day',      'ft/hr',       '[m]/c*_per_*[cm] | [ft]/m_per_ft[m] | [day]/hr_per_day[hr]'),
	('cm/day',      'ft/s',        '[m]/c*_per_*[cm] | [ft]/m_per_ft[m] | [day]/s_per_day[s]'),
	('cm/day',      'in/day',      '[m/day]/c*_per_*[cm/day] | [ft/day]/m_per_ft[m/day] | in_per_ft[in/day]/[ft/day]'),
	('cm/day',      'in/hr',       '[m/day]/c*_per_*[cm/day] | [ft/day]/m_per_ft[m/day] | in_per_ft[in/day]/[ft/day] | [in/hr]/hr_per_day[in/day]'),
	('cm/day',      'knot',        '[m/day]/c*_per_*[cm/day] | [m/s]/s_per_day[m/day] | [knot]/m/s_per_knot[m/s]'),
	('cm/day',      'kph',         '[m/day]/c*_per_*[cm/day] | [km/day]/*_per_k*[m/day] | [km/h]/hr_per_day[km/day] | [kph]/[km/h]'),
	('cm/day',      'm/hr',        '[m/day]/c*_per_*[cm/day] | [m/hr]/hr_per_day[m/day]'),
	('cm/day',      'm/s',         '[m/day]/c*_per_*[cm/day] | [m/s]/s_per_day[m/day]'),
	('cm/day',      'mm/day',      'm*_per_*[mm]/c*_per_*[cm]'),
	('cm/day',      'mm/hr',       'm*_per_*[mm]/c*_per_*[cm] | [cm/hr]/hr_per_day[cm/day]'),
	('cm/day',      'mph',         '[m/day]/c*_per_*[cm/day] | [ft/day]/m_per_ft[m/day] | [mile/day]/ft_per_mile[ft/day] | [mile/hr]/hr_per_day[mile/day] | [mph]/[mile/hr]'),
	('cm2',         '1000 acre',   '[m2]/c*_per_*^2[cm2] | [ft2]/m_per_ft^2[m2] | [acre]/ft2_per_acre[ft2] | [1000 acre]/*_per_k*[acre]'),
	('cm2',         '1000 m2',     '[m2]/c*_per_*^2[cm2] | [1000 m2]/*_per_k*[m2]'),
	('cm2',         'acre',        '[m2]/c*_per_*^2[cm2] | [ft2]/m_per_ft^2[m2] | [acre]/ft2_per_acre[ft2]'),
	('cm2',         'ft2',         '[m2]/c*_per_*^2[cm2] | [ft2]/m_per_ft^2[m2]'),
	('cm2',         'ha',          '[m2]/c*_per_*^2[cm2] | [ha]/m2_per_ha[m2]'),
	('cm2',         'km2',         '[m2]/c*_per_*^2[cm2] | [km2]/*_per_k*^2[m2]'),
	('cm2',         'm2',          '[m2]/c*_per_*^2[cm2]'),
	('cm2',         'mile2',       '[m2]/c*_per_*^2[cm2] | [ft2]/m_per_ft^2[m2] | [mile2]/ft_per_mile^2[ft2]'),
	('cms',         'KAF/mon',     '[m3/s]/[cms] | [ft3]/m_per_ft^3[m3] | s_per_mon[s]/[mon] | [ac-ft]/ft2_per_acre[ft3] | [kaf]/*_per_k*[ac-ft] | [KAF]/[kaf]'),
	('cms',         'cfs',         '[m3/s]/[cms] | [ft3]/m_per_ft^3[m3] | [cfs]/[ft3/s]'),
	('cms',         'gpm',         '[m3/s]/[cms] | [gal]/m3_per_gal[m3] | s_per_min[s]/[min] | [gpm]/[gal/min]'),
	('cms',         'kcfs',        '[m3/s]/[cms] | [ft3]/m_per_ft^3[m3] | [kcfs]/*_per_k*[ft3/s]'),
	('cms',         'kcms',        '[kcms]/*_per_k*[cms]'),
	('cms',         'mcm/mon',     '[m3/s]/[cms] | [ft3]/m_per_ft^3[m3] | s_per_mon[s]/[mon] | m_per_ft^3[m3]/[ft3] | [mcm]/*_per_M*[m3]'),
	('cms',         'mgd',         '[m3/s]/[cms] | [gal]/m3_per_gal[m3] | [mgal]/*_per_M*[gal] | s_per_day[s]/[day] | [mgd]/[mgal/day]'),
	('cms/km2',     'cfs/mi2',     '[m3/s]/[cms] | [ft3]/m_per_ft^3[m3] | km_per_mile^2[km2]/[mi2] | [cfs]/[ft3/s]'),
	('day',         'hr',          'hr_per_day[hr]/[day]'),
	('day',         'min',         'min_per_day[min]/[day]'),
	('day',         'sec',         's_per_day[sec]/[day]'),
	('deg',         'rad',         'rad_per_deg[rad]/[deg]'),
	('deg',         'rev',         '[rev]/deg_per_rev[deg]'),
	('dsf',         '1000 m3',     'ft3_per_dsf[ft3]/[dsf] | m_per_ft^3[m3]/[ft3] | [1000 m3]/*_per_k*[m3]'),
	('dsf',         'ac-ft',       'ft3_per_dsf[ft3]/[dsf] | [ac-ft]/ft2_per_acre[ft3]'),
	('dsf',         'ft3',         'ft3_per_dsf[ft3]/[dsf]'),
	('dsf',         'gal',         'ft3_per_dsf[ft3]/[dsf] | m_per_ft^3[m3]/[ft3] | [gal]/m3_per_gal[m3]'),
	('dsf',         'kaf',         'ft3_per_dsf[ft3]/[dsf] | [ac-ft]/ft2_per_acre[ft3] | [kaf]/*_per_k*[ac-ft]'),
	('dsf',         'kdsf',        '[kdsf]/*_per_k*[dsf]'),
	('dsf',         'kgal',        'ft3_per_dsf[ft3]/[dsf] | m_per_ft^3[m3]/[ft3] | [gal]/m3_per_gal[m3] | [kgal]/*_per_k*[gal]'),
	('dsf',         'km3',         'ft3_per_dsf[ft3]/[dsf] | m_per_ft^3[m3]/[ft3] | [km3]/*_per_k*^3[m3]'),
	('dsf',         'm3',          'ft3_per_dsf[ft3]/[dsf] | m_per_ft^3[m3]/[ft3]'),
	('dsf',         'mcm',         'ft3_per_dsf[ft3]/[dsf] | m_per_ft^3[m3]/[ft3] | [mcm]/*_per_M*[m3]'),
	('dsf',         'mgal',        'ft3_per_dsf[ft3]/[dsf] | m_per_ft^3[m3]/[ft3] | [gal]/m3_per_gal[m3] | [mgal]/*_per_M*[gal]'),
	('dsf',         'mile3',       'ft3_per_dsf[ft3]/[dsf] | [mile3]/ft_per_mile^3[ft3]'),
	('ft',          'cm',          'm_per_ft[m]/[ft] | c*_per_*[cm]/[m]'),
	('ft',          'ftUS',        'ftUS_per_ft[ftUS]/[ft]'),
	('ft',          'in',          'in_per_ft[in]/[ft]'),
	('ft',          'km',          'm_per_ft[m]/[ft] | [km]/*_per_k*[m]'),
	('ft',          'm',           'm_per_ft[m]/[ft]'),
	('ft',          'mi',          '[mi]/ft_per_mile[ft]'),
	('ft',          'mm',          'm_per_ft[m]/[ft] | m*_per_*[mm]/[m]'),
	('ft/hr',       'cm/day',      'm_per_ft[m]/[ft] | c*_per_*[cm]/[m] | hr_per_day[hr]/[day]'),
	('ft/hr',       'ft/s',        '[hr]/s_per_hr[s]'),
	('ft/hr',       'in/day',      'in_per_ft[in]/[ft] | hr_per_day[hr]/[day]'),
	('ft/hr',       'in/hr',       'in_per_ft[in]/[ft]'),
	('ft/hr',       'knot',        '[hr]/s_per_hr[s] | m_per_ft[m/s]/[ft/s] | [knot]/m/s_per_knot[m/s]'),
	('ft/hr',       'kph',         'm_per_ft[m]/[ft] | [km]/*_per_k*[m] | [kph]/[km/hr]'),
	('ft/hr',       'm/hr',        'm_per_ft[m]/[ft]'),
	('ft/hr',       'm/s',         'm_per_ft[m]/[ft] | [hr]/s_per_hr[s]'),
	('ft/hr',       'mm/day',      'm_per_ft[m]/[ft] | m*_per_*[mm]/[m] | hr_per_day[hr]/[day]'),
	('ft/hr',       'mm/hr',       'm_per_ft[m]/[ft] | m*_per_*[mm]/[m]'),
	('ft/hr',       'mph',         '[mi]/ft_per_mile[ft] | [mph]/[mi/hr]'),
	('ft/s',        'cm/day',      'm_per_ft[m]/[ft] | c*_per_*[cm]/[m] | s_per_day[s]/[day]'),
	('ft/s',        'ft/hr',       's_per_hr[s]/[hr]'),
	('ft/s',        'in/day',      'in_per_ft[in]/[ft] | s_per_day[s]/[day]'),
	('ft/s',        'in/hr',       'in_per_ft[in]/[ft] | s_per_hr[s]/[hr]'),
	('ft/s',        'knot',        'm_per_ft[m/s]/[ft/s] | [knot]/m/s_per_knot[m/s]'),
	('ft/s',        'kph',         'm_per_ft[m]/[ft] | [km]/*_per_k*[m] | s_per_hr[s]/[hr] | [kph]/[km/hr]'),
	('ft/s',        'm/hr',        'm_per_ft[m]/[ft] | s_per_hr[s]/[hr]'),
	('ft/s',        'm/s',         'm_per_ft[m]/[ft]'),
	('ft/s',        'mm/day',      'm_per_ft[m]/[ft] | m*_per_*[mm]/[m] | s_per_day[s]/[day]'),
	('ft/s',        'mm/hr',       'm_per_ft[m]/[ft] | m*_per_*[mm]/[m] | s_per_hr[s]/[hr]'),
	('ft/s',        'mph',         '[mi]/ft_per_mile[ft] | s_per_hr[s]/[hr] | [mph]/[mi/hr]'),
	('ft2',         '1000 acre',   '[acre]/ft2_per_acre[ft2] | [1000 acre]/*_per_k*[acre]'),
	('ft2',         '1000 m2',     'm_per_ft^2[m2]/[ft2] | [1000 m2]/*_per_k*[m2]'),
	('ft2',         'acre',        '[acre]/ft2_per_acre[ft2]'),
	('ft2',         'cm2',         'm_per_ft^2[m2]/[ft2] | c*_per_*^2[cm2]/[m2]'),
	('ft2',         'ha',          'm_per_ft^2[m2]/[ft2] | [ha]/m2_per_ha[m2]'),
	('ft2',         'km2',         'm_per_ft^2[m2]/[ft2] | [km2]/*_per_k*^2[m2]'),
	('ft2',         'm2',          'm_per_ft^2[m2]/[ft2]'),
	('ft2',         'mile2',       '[mile2]/ft_per_mile^2[ft2]'),
	('ft3',         '1000 m3',     'm_per_ft^3[m3]/[ft3] | [1000 m3]/*_per_k*[m3]'),
	('ft3',         'ac-ft',       '[ac-ft]/ft2_per_acre[ft3]'),
	('ft3',         'dsf',         '[dsf]/ft3_per_dsf[ft3]'),
	('ft3',         'gal',         'm_per_ft^3[m3]/[ft3] | [gal]/m3_per_gal[m3]'),
	('ft3',         'kaf',         '[ac-ft]/ft2_per_acre[ft3] | [kaf]/*_per_k*[ac-ft]'),
	('ft3',         'kdsf',        '[dsf]/ft3_per_dsf[ft3] | [kdsf]/*_per_k*[dsf]'),
	('ft3',         'kgal',        'm_per_ft^3[m3]/[ft3] | [gal]/m3_per_gal[m3] | [kgal]/*_per_k*[gal]'),
	('ft3',         'km3',         'm_per_ft^3[m3]/[ft3] | [km3]/*_per_k*^3[m3]'),
	('ft3',         'm3',          'm_per_ft^3[m3]/[ft3]'),
	('ft3',         'mcm',         'm_per_ft^3[m3]/[ft3] | [mcm]/*_per_M*[m3]'),
	('ft3',         'mgal',        'm_per_ft^3[m3]/[ft3] | [gal]/m3_per_gal[m3] | [mgal]/*_per_M*[gal]'),
	('ft3',         'mile3',       '[mile3]/ft_per_mile^3[ft3]'),
	('ftUS',        'cm',          '[ft]/ftUS_per_ft[ftUS] | m_per_ft[m]/[ft] | c*_per_*[cm]/[m]'),
	('ftUS',        'ft',          '[ft]/ftUS_per_ft[ftUS]'),
	('ftUS',        'in',          '[ft]/ftUS_per_ft[ftUS] | in_per_ft[in]/[ft]'),
	('ftUS',        'km',          '[ft]/ftUS_per_ft[ftUS] | m_per_ft[m]/[ft] | [km]/*_per_k*[m]'),
	('ftUS',        'm',           '[ft]/ftUS_per_ft[ftUS] | m_per_ft[m]/[ft]'),
	('ftUS',        'mi',          '[ft]/ftUS_per_ft[ftUS] | [mi]/ft_per_mile[ft]'),
	('ftUS',        'mm',          '[ft]/ftUS_per_ft[ftUS] | m_per_ft[m]/[ft] | m*_per_*[mm]/[m]'),
	('g',           'kg',          '[kg]/*_per_k*[g]'),
	('g',           'lbm',         '[kg]/*_per_k*[g] | [lbm]/kg_per_lbm[kg]'),
	('g',           'mg',          'm*_per_*[mg]/[g]'),
	('g',           'ton',         '[kg]/*_per_k*[g] | [lbm]/kg_per_lbm[kg] | [ton]/lbm_per_ton[lbm]'),
	('g',           'tonne',       '[kg]/*_per_k*[g] | [tonne]/kg_per_tonne[kg]'),
	('g/l',         'g/m3',        'l_per_m3[l]/[m3]'),
	('g/l',         'gm/cm3',      'l_per_m3[l]/[m3] | [m3]/c*_per_*^3[cm3] | [gm]/[g]'),
	('g/l',         'lbm/ft3',     '[kg]/*_per_k*[g] | [lbm]/kg_per_lbm[kg] | l_per_m3[l]/[m3] | m_per_ft^3[m3]/[ft3]'),
	('g/l',         'mg/l',        'm*_per_*[mg/l]/[g/l]'),
	('g/l',         'ppm',         'm*_per_*[mg/l]/[g/l] | [ppm]/[mg/l]'),
	('g/m3',        'g/l',         '[m3]/l_per_m3[l]'),
	('g/m3',        'gm/cm3',      '[gm]/[g] | [m3]/c*_per_*^3[cm3]'),
	('g/m3',        'lbm/ft3',     '[kg]/*_per_k*[g] | [lbm]/kg_per_lbm[kg] | m_per_ft^3[m3]/[ft3]'),
	('g/m3',        'mg/l',        '[m3]/l_per_m3[l] | m*_per_*[mg]/[g]'),
	('g/m3',        'ppm',         '[m3]/l_per_m3[l] | m*_per_*[mg]/[g] | [ppm]/[mg/l]'),
	('gal',         '1000 m3',     'm3_per_gal[m3]/[gal] | [1000 m3]/*_per_k*[m3]'),
	('gal',         'ac-ft',       'm3_per_gal[m3]/[gal] | [ft3]/m_per_ft^3[m3] | [ac-ft]/ft2_per_acre[ft3]'),
	('gal',         'dsf',         'm3_per_gal[m3]/[gal] | [ft3]/m_per_ft^3[m3] | [dsf]/ft3_per_dsf[ft3]'),
	('gal',         'ft3',         'm3_per_gal[m3]/[gal] | [ft3]/m_per_ft^3[m3]'),
	('gal',         'kaf',         'm3_per_gal[m3]/[gal] | [ft3]/m_per_ft^3[m3] | [ac-ft]/ft2_per_acre[ft3] | [kaf]/*_per_k*[ac-ft]'),
	('gal',         'kdsf',        'm3_per_gal[m3]/[gal] | [ft3]/m_per_ft^3[m3] | [dsf]/ft3_per_dsf[ft3] | [kdsf]/*_per_k*[dsf]'),
	('gal',         'kgal',        '[kgal]/*_per_k*[gal]'),
	('gal',         'km3',         'm3_per_gal[m3]/[gal] | [km3]/*_per_k*^3[m3]'),
	('gal',         'm3',          'm3_per_gal[m3]/[gal]'),
	('gal',         'mcm',         'm3_per_gal[m3]/[gal] | [mcm]/*_per_M*[m3]'),
	('gal',         'mgal',        '[mgal]/*_per_M*[gal]'),
	('gal',         'mile3',       'm3_per_gal[m3]/[gal] | [ft3]/m_per_ft^3[m3] | [mile3]/ft_per_mile^3[ft3]'),
	('gm/cm3',      'g/l',         '[g]/[gm] | c*_per_*^3[cm3]/[m3] | [m3]/l_per_m3[l]'),
	('gm/cm3',      'g/m3',        '[g]/[gm] | c*_per_*^3[cm3]/[m3]'),
	('gm/cm3',      'lbm/ft3',     '[g]/[gm] | [kg]/*_per_k*[g] | [lbm]/kg_per_lbm[kg] | c*_per_*^3[cm3]/[m3] | m_per_ft^3[m3]/[ft3]'),
	('gm/cm3',      'mg/l',        '[g]/[gm] | c*_per_*^3[cm3]/[m3] | [m3]/l_per_m3[l] | m*_per_*[mg]/[g]'),
	('gm/cm3',      'ppm',         '[g]/[gm] | c*_per_*^3[cm3]/[m3] | [m3]/l_per_m3[l] | m*_per_*[mg]/[g] | [ppm]/[mg/l]'),
	('gpm',         'KAF/mon',     '[gal/min]/[gpm] | [min]/s_per_min[s] | m3_per_gal[m3]/[gal] | [ft3]/m_per_ft^3[m3] | s_per_mon[s]/[mon] | [ac-ft]/ft2_per_acre[ft3] | [kaf]/*_per_k*[ac-ft] | [KAF]/[kaf]'),
	('gpm',         'cfs',         '[gal/min]/[gpm] | m3_per_gal[m3]/[gal] | [ft3]/m_per_ft^3[m3] | [min]/s_per_min[s] | [cfs]/[ft3/s]'),
	('gpm',         'cms',         '[gal/min]/[gpm] | m3_per_gal[m3]/[gal] | [min]/s_per_min[s] | [cms]/[m3/s]'),
	('gpm',         'kcfs',        '[gal/min]/[gpm] | m3_per_gal[m3]/[gal] | [ft3]/m_per_ft^3[m3] | [min]/s_per_min[s] | [cfs]/[ft3/s] | [kcfs]/*_per_k*[cfs]'),
	('gpm',         'kcms',        '[gal/min]/[gpm] | m3_per_gal[m3]/[gal] | [min]/s_per_min[s] | [cms]/[m3/s] | [kcms]/*_per_k*[cms]'),
	('gpm',         'mcm/mon',     '[gal/min]/[gpm] | [min]/s_per_min[s] | m3_per_gal[m3]/[gal] | [ft3]/m_per_ft^3[m3] | s_per_mon[s]/[mon] | m_per_ft^3[m3]/[ft3] | [mcm]/*_per_M*[m3]'),
	('gpm',         'mgd',         '[gal/min]/[gpm] | [Mgal]/*_per_M*[gal] | min_per_day[min]/[day] | [mgd]/[Mgal/day]'),
	('ha',          '1000 acre',   'm2_per_ha[m2]/[ha] | [ft2]/m_per_ft^2[m2] | [acre]/ft2_per_acre[ft2] | [1000 acre]/*_per_k*[acre]'),
	('ha',          '1000 m2',     'm2_per_ha[m2]/[ha] | [1000 m2]/*_per_k*[m2]'),
	('ha',          'acre',        'm2_per_ha[m2]/[ha] | [ft2]/m_per_ft^2[m2] | [acre]/ft2_per_acre[ft2]'),
	('ha',          'cm2',         'm2_per_ha[m2]/[ha] | c*_per_*^2[cm2]/[m2]'),
	('ha',          'ft2',         'm2_per_ha[m2]/[ha] | [ft2]/m_per_ft^2[m2]'),
	('ha',          'km2',         'm2_per_ha[m2]/[ha] | [km2]/*_per_k*^2[m2]'),
	('ha',          'm2',          'm2_per_ha[m2]/[ha]'),
	('ha',          'mile2',       'm2_per_ha[m2]/[ha] | [ft2]/m_per_ft^2[m2] | [mile2]/ft_per_mile^2[ft2]'),
	('hr',          'day',         '[day]/hr_per_day[hr]'),
	('hr',          'min',         'min_per_hr[min]/[hr]'),
	('hr',          'sec',         's_per_hr[sec]/[hr]'),
	('in',          'cm',          '[ft]/in_per_ft[in] | m_per_ft[m]/[ft] | c*_per_*[cm]/[m]'),
	('in',          'ft',          '[ft]/in_per_ft[in]'),
	('in',          'ftUS',        '[ft]/in_per_ft[in] | ftUS_per_ft[ftUS]/[ft]'),
	('in',          'km',          '[ft]/in_per_ft[in] | m_per_ft[m]/[ft] | [km]/*_per_k*[m]'),
	('in',          'm',           '[ft]/in_per_ft[in] | m_per_ft[m]/[ft]'),
	('in',          'mi',          '[ft]/in_per_ft[in] | [mi]/ft_per_mile[ft]'),
	('in',          'mm',          '[ft]/in_per_ft[in] | m_per_ft[m]/[ft] | m*_per_*[mm]/[m]'),
	('in-hg',       'bar',         'Pa_per_in-hg[Pa]/[in-hg] | [bar]/Pa_per_bar[Pa]'),
	('in-hg',       'kPa',         'Pa_per_in-hg[Pa]/[in-hg] | [kPa]/*_per_k*[Pa]'),
	('in-hg',       'mb',          'Pa_per_in-hg[Pa]/[in-hg] | [bar]/Pa_per_bar[Pa] | m*_per_*[mb]/[bar]'),
	('in-hg',       'mm-hg',       '[ft-hg]/in_per_ft[in-hg] | m_per_ft[m-hg]/[ft-hg] | m*_per_*[mm-hg]/[m-hg]'),
	('in-hg',       'psi',         'Pa_per_in-hg[Pa]/[in-hg] | [psi]/Pa_per_psi[Pa]'),
	('in/day',      'cm/day',      '[ft]/in_per_ft[in] | m_per_ft[m]/[ft] | c*_per_*[cm]/[m]'),
	('in/day',      'ft/hr',       '[ft]/in_per_ft[in] | [day]/hr_per_day[hr]'),
	('in/day',      'ft/s',        '[ft]/in_per_ft[in] | [day]/s_per_day[s]'),
	('in/day',      'in/hr',       '[day]/hr_per_day[hr]'),
	('in/day',      'knot',        '[ft/day]/in_per_ft[in/day] | [ft/s]/s_per_day[ft/day] | m_per_ft[m/s]/[ft/s] | [knot]/m/s_per_knot[m/s]'),
	('in/day',      'kph',         '[ft]/in_per_ft[in] | m_per_ft[m]/[ft] | [km]/*_per_k*[m] | [day]/hr_per_day[hr] | [kph]/[km/hr]'),
	('in/day',      'm/hr',        '[ft]/in_per_ft[in] | m_per_ft[m]/[ft] | [day]/hr_per_day[hr]'),
	('in/day',      'm/s',         '[ft]/in_per_ft[in] | m_per_ft[m]/[ft] | [day]/s_per_day[s]'),
	('in/day',      'mm/day',      '[ft]/in_per_ft[in] | m_per_ft[m]/[ft] | m*_per_*[mm]/[m]'),
	('in/day',      'mm/hr',       '[ft]/in_per_ft[in] | m_per_ft[m]/[ft] | m*_per_*[mm]/[m] | [day]/hr_per_day[hr]'),
	('in/day',      'mph',         '[ft]/in_per_ft[in] | [mi]/ft_per_mile[ft] | [day]/hr_per_day[hr] | [mph]/[mi/hr]'),
	('in/deg-day',  'mm/deg-day',  '[ft]/in_per_ft[in] | m_per_ft[m]/[ft] | m*_per_*[mm]/[m] | [deg-day]/C_per_F[deg-day]'),
	('in/hr',       'cm/day',      '[ft]/in_per_ft[in] | m_per_ft[m]/[ft] | c*_per_*[cm]/[m] | hr_per_day[hr]/[day]'),
	('in/hr',       'ft/hr',       '[ft]/in_per_ft[in]'),
	('in/hr',       'ft/s',        '[ft]/in_per_ft[in] | [hr]/s_per_hr[s]'),
	('in/hr',       'in/day',      'hr_per_day[hr]/[day]'),
	('in/hr',       'knot',        '[ft/hr]/in_per_ft[in/hr] | [ft/s]/s_per_hr[ft/hr] | m_per_ft[m/s]/[ft/s] | [knot]/m/s_per_knot[m/s]'),
	('in/hr',       'kph',         '[ft]/in_per_ft[in] | m_per_ft[m]/[ft] | [km]/*_per_k*[m] | [kph]/[km/hr]'),
	('in/hr',       'm/hr',        '[ft]/in_per_ft[in] | m_per_ft[m]/[ft]'),
	('in/hr',       'm/s',         '[ft]/in_per_ft[in] | m_per_ft[m]/[ft] | [hr]/s_per_hr[s]'),
	('in/hr',       'mm/day',      '[ft]/in_per_ft[in] | m_per_ft[m]/[ft] | m*_per_*[mm]/[m] | hr_per_day[hr]/[day]'),
	('in/hr',       'mm/hr',       '[ft]/in_per_ft[in] | m_per_ft[m]/[ft] | m*_per_*[mm]/[m]'),
	('in/hr',       'mph',         '[ft]/in_per_ft[in] | [mi]/ft_per_mile[ft] | [mph]/[mi/hr]'),
	('k$',          '$',           '*_per_k*[$]/[k$]'),
	('kHz',         'B',           '*_per_k*[Hz]/[kHz] | function[B]/[Hz]'),
	('kHz',         'Hz',          '*_per_k*[Hz]/[kHz]'),
	('kHz',         'MHz',         '*_per_k*[Hz]/[kHz] | [MHz]/*_per_M*[Hz]'),
	('kPa',         'bar',         '*_per_k*[Pa]/[kPa] | [bar]/Pa_per_bar[Pa]'),
	('kPa',         'in-hg',       '*_per_k*[Pa]/[kPa] | [in-hg]/Pa_per_in-hg[Pa]'),
	('kPa',         'mb',          '*_per_k*[Pa]/[kPa] | [bar]/Pa_per_bar[Pa] | m*_per_*[mb]/[bar]'),
	('kPa',         'mm-hg',       '*_per_k*[Pa]/[kPa] | [mm-hg]/Pa_per_mm-hg[Pa]'),
	('kPa',         'psi',         '*_per_k*[Pa]/[kPa] | [psi]/Pa_per_psi[Pa]'),
	('kW',          'GW',          '*_per_k*[W]/[kW] | [GW]/*_per_G*[W]'),
	('kW',          'MW',          '*_per_k*[W]/[kW] | [MW]/*_per_M*[W]'),
	('kW',          'TW',          '*_per_k*[W]/[kW] | [TW]/*_per_T*[W]'),
	('kW',          'W',           '*_per_k*[W]/[kW]'),
	('kWh',         'GWh',         '*_per_k*[Wh]/[kWh] | [GWh]/*_per_G*[Wh]'),
	('kWh',         'J',           '*_per_k*[Wh]/[kWh] | J_per_Wh[J]/[Wh]'),
	('kWh',         'MJ',          '*_per_k*[Wh]/[kWh] | J_per_Wh[J]/[Wh] | [MJ]/*_per_M*[J]'),
	('kWh',         'MWh',         '*_per_k*[Wh]/[kWh] | [MWh]/*_per_M*[Wh]'),
	('kWh',         'TWh',         '*_per_k*[Wh]/[kWh] | [TWh]/*_per_T*[Wh]'),
	('kWh',         'Wh',          '*_per_k*[Wh]/[kWh]'),
	('kWh',         'cal',         '*_per_k*[Wh]/[kWh] | J_per_Wh[J]/[Wh] | [cal]/J_per_cal[J]'),
	('kaf',         '1000 m3',     '*_per_k*[ac-ft]/[kaf] | ft2_per_acre[ft3]/[ac-ft] | m_per_ft^3[m3]/[ft3] | [1000 m3]/*_per_k*[m3]'),
	('kaf',         'ac-ft',       '*_per_k*[ac-ft]/[kaf]'),
	('kaf',         'dsf',         '*_per_k*[ac-ft]/[kaf] | ft2_per_acre[ft3]/[ac-ft] | [dsf]/ft3_per_dsf[ft3]'),
	('kaf',         'ft3',         '*_per_k*[ac-ft]/[kaf] | ft2_per_acre[ft3]/[ac-ft]'),
	('kaf',         'gal',         '*_per_k*[ac-ft]/[kaf] | ft2_per_acre[ft3]/[ac-ft] | m_per_ft^3[m3]/[ft3] | [gal]/m3_per_gal[m3]'),
	('kaf',         'kdsf',        '*_per_k*[ac-ft]/[kaf] | ft2_per_acre[ft3]/[ac-ft] | [dsf]/ft3_per_dsf[ft3] | [kdsf]/*_per_k*[dsf]'),
	('kaf',         'kgal',        '*_per_k*[ac-ft]/[kaf] | ft2_per_acre[ft3]/[ac-ft] | m_per_ft^3[m3]/[ft3] | [gal]/m3_per_gal[m3] | [kgal]/*_per_k*[gal]'),
	('kaf',         'km3',         '*_per_k*[ac-ft]/[kaf] | ft2_per_acre[ft3]/[ac-ft] | m_per_ft^3[m3]/[ft3] | [km3]/*_per_k*^3[m3]'),
	('kaf',         'm3',          '*_per_k*[ac-ft]/[kaf] | ft2_per_acre[ft3]/[ac-ft] | m_per_ft^3[m3]/[ft3]'),
	('kaf',         'mcm',         '*_per_k*[ac-ft]/[kaf] | ft2_per_acre[ft3]/[ac-ft] | m_per_ft^3[m3]/[ft3] | [mcm]/*_per_M*[m3]'),
	('kaf',         'mgal',        '*_per_k*[ac-ft]/[kaf] | ft2_per_acre[ft3]/[ac-ft] | m_per_ft^3[m3]/[ft3] | [gal]/m3_per_gal[m3] | [mgal]/*_per_M*[gal]'),
	('kaf',         'mile3',       '*_per_k*[ac-ft]/[kaf] | ft2_per_acre[ft3]/[ac-ft] | [mile3]/ft_per_mile^3[ft3]'),
	('kcfs',        'KAF/mon',     '*_per_k*[cfs]/[kcfs] | [ft3/s]/[cfs] | s_per_mon[s]/[mon] | [ac-ft]/ft2_per_acre[ft3] | [kaf]/*_per_k*[ac-ft] | [KAF]/[kaf]'),
	('kcfs',        'cfs',         '*_per_k*[cfs]/[kcfs]'),
	('kcfs',        'cms',         '*_per_k*[ft3/s]/[kcfs] | m_per_ft^3[m3]/[ft3] | [cms]/[m3/s]'),
	('kcfs',        'gpm',         '*_per_k*[ft3/s]/[kcfs] | m_per_ft^3[m3]/[ft3] | [gal]/m3_per_gal[m3] | s_per_min[s]/[min] | [gpm]/[gal/min]'),
	('kcfs',        'kcms',        '*_per_k*[ft3/s]/[kcfs] | m_per_ft^3[m3]/[ft3] | [cms]/[m3/s] | [kcms]/*_per_k*[cms]'),
	('kcfs',        'mcm/mon',     '*_per_k*[cfs]/[kcfs] | [ft3/s]/[cfs] | s_per_mon[s]/[mon] | m_per_ft^3[m3]/[ft3] | [mcm]/*_per_M*[m3]'),
	('kcfs',        'mgd',         '*_per_k*[ft3/s]/[kcfs] | m_per_ft^3[m3]/[ft3] | [gal]/m3_per_gal[m3] | [mgal]/*_per_M*[gal] | s_per_day[s]/[day] | [mgd]/[mgal/day]'),
	('kcms',        'KAF/mon',     '*_per_k*[cms]/[kcms] | [m3/s]/[cms] | [ft3]/m_per_ft^3[m3] | [cfs]/[ft3/s] | [ft3/s]/[cfs] | s_per_mon[s]/[mon] | [ac-ft]/ft2_per_acre[ft3] | [kaf]/*_per_k*[ac-ft] | [KAF]/[kaf]'),
	('kcms',        'cfs',         '*_per_k*[cms]/[kcms] | [m3/s]/[cms] | [ft3]/m_per_ft^3[m3] | [cfs]/[ft3/s]'),
	('kcms',        'cms',         '*_per_k*[cms]/[kcms]'),
	('kcms',        'gpm',         '*_per_k*[cms]/[kcms] | [m3/s]/[cms] | [gal]/m3_per_gal[m3] | s_per_min[s]/[min] | [gpm]/[gal/min]'),
	('kcms',        'kcfs',        '*_per_k*[cms]/[kcms] | [m3/s]/[cms] | [ft3]/m_per_ft^3[m3] | [kcfs]/*_per_k*[ft3/s]'),
	('kcms',        'mcm/mon',     '*_per_k*[cms]/[kcms] | [m3/s]/[cms] | [ft3]/m_per_ft^3[m3] | s_per_mon[s]/[mon] | m_per_ft^3[m3]/[ft3] | [mcm]/*_per_M*[m3]'),
	('kcms',        'mgd',         '*_per_k*[cms]/[kcms] | [m3/s]/[cms] | [gal]/m3_per_gal[m3] | [mgal]/*_per_M*[gal] | s_per_day[s]/[day] | [mgd]/[mgal/day]'),
	('kdsf',        '1000 m3',     '*_per_k*[dsf]/[kdsf] | ft3_per_dsf[ft3]/[dsf] | m_per_ft^3[m3]/[ft3] | [1000 m3]/*_per_k*[m3]'),
	('kdsf',        'ac-ft',       '*_per_k*[dsf]/[kdsf] | ft3_per_dsf[ft3]/[dsf] | [ac-ft]/ft2_per_acre[ft3]'),
	('kdsf',        'dsf',         '*_per_k*[dsf]/[kdsf]'),
	('kdsf',        'ft3',         '*_per_k*[dsf]/[kdsf] | ft3_per_dsf[ft3]/[dsf]'),
	('kdsf',        'gal',         '*_per_k*[dsf]/[kdsf] | ft3_per_dsf[ft3]/[dsf] | m_per_ft^3[m3]/[ft3] | [gal]/m3_per_gal[m3]'),
	('kdsf',        'kaf',         '*_per_k*[dsf]/[kdsf] | ft3_per_dsf[ft3]/[dsf] | [ac-ft]/ft2_per_acre[ft3] | [kaf]/*_per_k*[ac-ft]'),
	('kdsf',        'kgal',        '*_per_k*[dsf]/[kdsf] | ft3_per_dsf[ft3]/[dsf] | m_per_ft^3[m3]/[ft3] | [gal]/m3_per_gal[m3] | [kgal]/*_per_k*[gal]'),
	('kdsf',        'km3',         '*_per_k*[dsf]/[kdsf] | ft3_per_dsf[ft3]/[dsf] | m_per_ft^3[m3]/[ft3] | [km3]/*_per_k*^3[m3]'),
	('kdsf',        'm3',          '*_per_k*[dsf]/[kdsf] | ft3_per_dsf[ft3]/[dsf] | m_per_ft^3[m3]/[ft3]'),
	('kdsf',        'mcm',         '*_per_k*[dsf]/[kdsf] | ft3_per_dsf[ft3]/[dsf] | m_per_ft^3[m3]/[ft3] | [mcm]/*_per_M*[m3]'),
	('kdsf',        'mgal',        '*_per_k*[dsf]/[kdsf] | ft3_per_dsf[ft3]/[dsf] | m_per_ft^3[m3]/[ft3] | [gal]/m3_per_gal[m3] | [mgal]/*_per_M*[gal]'),
	('kdsf',        'mile3',       '*_per_k*[dsf]/[kdsf] | ft3_per_dsf[ft3]/[dsf] | [mile3]/ft_per_mile^3[ft3]'),
	('kg',          'g',           '*_per_k*[g]/[kg]'),
	('kg',          'lbm',         '[lbm]/kg_per_lbm[kg]'),
	('kg',          'mg',          '*_per_k*[g]/[kg] | m*_per_*[mg]/[g]'),
	('kg',          'ton',         '[lbm]/kg_per_lbm[kg] | [ton]/lbm_per_ton[lbm]'),
	('kg',          'tonne',       '[tonne]/kg_per_tonne[kg]'),
	('kgal',        '1000 m3',     '*_per_k*[gal]/[kgal] | m3_per_gal[m3]/[gal] | [1000 m3]/*_per_k*[m3]'),
	('kgal',        'ac-ft',       '*_per_k*[gal]/[kgal] | m3_per_gal[m3]/[gal] | [ft3]/m_per_ft^3[m3] | [ac-ft]/ft2_per_acre[ft3]'),
	('kgal',        'dsf',         '*_per_k*[gal]/[kgal] | m3_per_gal[m3]/[gal] | [ft3]/m_per_ft^3[m3] | [dsf]/ft3_per_dsf[ft3]'),
	('kgal',        'ft3',         '*_per_k*[gal]/[kgal] | m3_per_gal[m3]/[gal] | [ft3]/m_per_ft^3[m3]'),
	('kgal',        'gal',         '*_per_k*[gal]/[kgal]'),
	('kgal',        'kaf',         '*_per_k*[gal]/[kgal] | m3_per_gal[m3]/[gal] | [ft3]/m_per_ft^3[m3] | [ac-ft]/ft2_per_acre[ft3] | [kaf]/*_per_k*[ac-ft]'),
	('kgal',        'kdsf',        '*_per_k*[gal]/[kgal] | m3_per_gal[m3]/[gal] | [ft3]/m_per_ft^3[m3] | [dsf]/ft3_per_dsf[ft3] | [kdsf]/*_per_k*[dsf]'),
	('kgal',        'km3',         '*_per_k*[gal]/[kgal] | m3_per_gal[m3]/[gal] | [km3]/*_per_k*^3[m3]'),
	('kgal',        'm3',          '*_per_k*[gal]/[kgal] | m3_per_gal[m3]/[gal]'),
	('kgal',        'mcm',         '*_per_k*[gal]/[kgal] | m3_per_gal[m3]/[gal] | [mcm]/*_per_M*[m3]'),
	('kgal',        'mgal',        '*_per_k*[gal]/[kgal] | [mgal]/*_per_M*[gal]'),
	('kgal',        'mile3',       '*_per_k*[gal]/[kgal] | m3_per_gal[m3]/[gal] | [ft3]/m_per_ft^3[m3] | [mile3]/ft_per_mile^3[ft3]'),
	('km',          'cm',          '*_per_k*[m]/[km] | c*_per_*[cm]/[m]'),
	('km',          'ft',          '*_per_k*[m]/[km] | [ft]/m_per_ft[m]'),
	('km',          'ftUS',        '*_per_k*[m]/[km] | [ft]/m_per_ft[m] | ftUS_per_ft[ftUS]/[ft]'),
	('km',          'in',          '*_per_k*[m]/[km] | [ft]/m_per_ft[m] | in_per_ft[in]/[ft]'),
	('km',          'm',           '*_per_k*[m]/[km]'),
	('km',          'mi',          '*_per_k*[m]/[km] | [ft]/m_per_ft[m] | [mi]/ft_per_mile[ft]'),
	('km',          'mm',          '*_per_k*[m]/[km] | m*_per_*[mm]/[m]'),
	('km2',         '1000 acre',   '*_per_k*^2[m2]/[km2] | [ft2]/m_per_ft^2[m2] | [acre]/ft2_per_acre[ft2] | [1000 acre]/*_per_k*[acre]'),
	('km2',         '1000 m2',     '*_per_k*^2[m2]/[km2] | [1000 m2]/*_per_k*[m2]'),
	('km2',         'acre',        '*_per_k*^2[m2]/[km2] | [ft2]/m_per_ft^2[m2] | [acre]/ft2_per_acre[ft2]'),
	('km2',         'cm2',         '*_per_k*^2[m2]/[km2] | c*_per_*^2[cm2]/[m2]'),
	('km2',         'ft2',         '*_per_k*^2[m2]/[km2] | [ft2]/m_per_ft^2[m2]'),
	('km2',         'ha',          '*_per_k*^2[m2]/[km2] | [ha]/m2_per_ha[m2]'),
	('km2',         'm2',          '*_per_k*^2[m2]/[km2]'),
	('km2',         'mile2',       '[mile2]/km_per_mile^2[km2]'),
	('km3',         '1000 m3',     '*_per_k*^3[m3]/[km3] | [1000 m3]/*_per_k*[m3]'),
	('km3',         'ac-ft',       '*_per_k*^3[m3]/[km3] | [ft3]/m_per_ft^3[m3] | [ac-ft]/ft2_per_acre[ft3]'),
	('km3',         'dsf',         '*_per_k*^3[m3]/[km3] | [ft3]/m_per_ft^3[m3] | [dsf]/ft3_per_dsf[ft3]'),
	('km3',         'ft3',         '*_per_k*^3[m3]/[km3] | [ft3]/m_per_ft^3[m3]'),
	('km3',         'gal',         '*_per_k*^3[m3]/[km3] | [gal]/m3_per_gal[m3]'),
	('km3',         'kaf',         '*_per_k*^3[m3]/[km3] | [ft3]/m_per_ft^3[m3] | [ac-ft]/ft2_per_acre[ft3] | [kaf]/*_per_k*[ac-ft]'),
	('km3',         'kdsf',        '*_per_k*^3[m3]/[km3] | [ft3]/m_per_ft^3[m3] | [dsf]/ft3_per_dsf[ft3] | [kdsf]/*_per_k*[dsf]'),
	('km3',         'kgal',        '*_per_k*^3[m3]/[km3] | [gal]/m3_per_gal[m3] | [kgal]/*_per_k*[gal]'),
	('km3',         'm3',          '*_per_k*^3[m3]/[km3]'),
	('km3',         'mcm',         '*_per_k*^3[m3]/[km3] | [mcm]/*_per_M*[m3]'),
	('km3',         'mgal',        '*_per_k*^3[m3]/[km3] | [gal]/m3_per_gal[m3] | [mgal]/*_per_M*[gal]'),
	('km3',         'mile3',       '*_per_k*^3[m3]/[km3] | [ft3]/m_per_ft^3[m3] | [mile3]/ft_per_mile^3[ft3]'),
	('knot',        'cm/day',      'm/s_per_knot[m/s]/[knot] | s_per_day[m/day]/[m/s] | c*_per_*[cm/day]/[m/day]'),
	('knot',        'ft/hr',       'm/s_per_knot[m/s]/[knot] | [ft/s]/m_per_ft[m/s] | s_per_hr[s]/[hr]'),
	('knot',        'ft/s',        'm/s_per_knot[m/s]/[knot] | [ft/s]/m_per_ft[m/s]'),
	('knot',        'in/day',      'm/s_per_knot[m/s]/[knot] | [ft/s]/m_per_ft[m/s] | s_per_day[ft/day]/[ft/s] | in_per_ft[in/day]/[ft/day]'),
	('knot',        'in/hr',       'm/s_per_knot[m/s]/[knot] | [ft/s]/m_per_ft[m/s] | s_per_hr[ft/hr]/[ft/s] | in_per_ft[in/hr]/[ft/hr]'),
	('knot',        'kph',         'm/s_per_knot[m/s]/[knot] | s_per_hr[m/hr]/[m/s] | [kph]/*_per_k*[m/hr]'),
	('knot',        'm/hr',        'm/s_per_knot[m/s]/[knot] | s_per_hr[s]/[hr]'),
	('knot',        'm/s',         'm/s_per_knot[m/s]/[knot]'),
	('knot',        'mm/day',      'm/s_per_knot[m/s]/[knot] | s_per_day[m/day]/[m/s] | m*_per_*[mm/day]/[m/day]'),
	('knot',        'mm/hr',       'm/s_per_knot[m/s]/[knot] | s_per_hr[m/hr]/[m/s] | m*_per_*[mm/hr]/[m/hr]'),
	('knot',        'mph',         'm/s_per_knot[m/s]/[knot] | s_per_hr[s]/[hr] | [ft]/m_per_ft[m] | [mile]/ft_per_mile[ft] | [mph]/[mile/hr]'),
	('kph',         'cm/day',      '[km/hr]/[kph] | *_per_k*[m]/[km] | c*_per_*[cm]/[m] | hr_per_day[hr]/[day]'),
	('kph',         'ft/hr',       '[km/hr]/[kph] | *_per_k*[m]/[km] | [ft]/m_per_ft[m]'),
	('kph',         'ft/s',        '[km/hr]/[kph] | *_per_k*[m]/[km] | [ft]/m_per_ft[m] | [hr]/s_per_hr[s]'),
	('kph',         'in/day',      '[km/hr]/[kph] | *_per_k*[m]/[km] | [ft]/m_per_ft[m] | in_per_ft[in]/[ft] | hr_per_day[hr]/[day]'),
	('kph',         'in/hr',       '[km/hr]/[kph] | *_per_k*[m]/[km] | [ft]/m_per_ft[m] | in_per_ft[in]/[ft]'),
	('kph',         'knot',        '*_per_k*[m/hr]/[kph] | [m/s]/s_per_hr[m/hr] | [knot]/m/s_per_knot[m/s]'),
	('kph',         'm/hr',        '[km/hr]/[kph] | *_per_k*[m]/[km]'),
	('kph',         'm/s',         '[km/hr]/[kph] | *_per_k*[m]/[km] | [hr]/s_per_hr[s]'),
	('kph',         'mm/day',      '[km/hr]/[kph] | *_per_k*[m]/[km] | m*_per_*[mm]/[m] | hr_per_day[hr]/[day]'),
	('kph',         'mm/hr',       '[km/hr]/[kph] | *_per_k*[m]/[km] | m*_per_*[mm]/[m]'),
	('kph',         'mph',         '[km/hr]/[kph] | *_per_k*[m]/[km] | [ft]/m_per_ft[m] | [mi]/ft_per_mile[ft] | [mph]/[mi/hr]'),
	('langley',     'J/m2',        'J/m2_per_langley[J/m2]/[langley]'),
	('langley/min', 'W/m2',        'J/m2_per_langley[J/m2]/[langley] | [W]/[J/s] | [min]/s_per_min[s]'),
	('lb',          'N',           '[lbm*g]/[lb] | m/s2_per_g[m/s2]/[g] | kg_per_lbm[kg]/[lbm] | [N]/[kg*m/s2]'),
	('lbm',         'g',           'kg_per_lbm[kg]/[lbm] | *_per_k*[g]/[kg]'),
	('lbm',         'kg',          'kg_per_lbm[kg]/[lbm]'),
	('lbm',         'mg',          'kg_per_lbm[kg]/[lbm] | *_per_k*[g]/[kg] | m*_per_*[mg]/[g]'),
	('lbm',         'ton',         '[ton]/lbm_per_ton[lbm]'),
	('lbm',         'tonne',       'kg_per_lbm[kg]/[lbm] | [tonne]/kg_per_tonne[kg]'),
	('lbm/ft3',     'g/l',         'kg_per_lbm[kg]/[lbm] | *_per_k*[g]/[kg] | [ft3]/m_per_ft^3[m3] | [m3]/l_per_m3[l]'),
	('lbm/ft3',     'g/m3',        'kg_per_lbm[kg]/[lbm] | *_per_k*[g]/[kg] | [ft3]/m_per_ft^3[m3]'),
	('lbm/ft3',     'gm/cm3',      'kg_per_lbm[kg]/[lbm] | *_per_k*[g]/[kg] | [gm]/[g] | [ft3]/m_per_ft^3[m3] | [m3]/c*_per_*^3[cm3]'),
	('lbm/ft3',     'mg/l',        'kg_per_lbm[kg]/[lbm] | *_per_k*[g]/[kg] | m*_per_*[mg]/[g] | [ft3]/m_per_ft^3[m3] | [m3]/l_per_m3[l]'),
	('lbm/ft3',     'ppm',         'kg_per_lbm[kg]/[lbm] | *_per_k*[g]/[kg] | m*_per_*[mg]/[g] | [ft3]/m_per_ft^3[m3] | [m3]/l_per_m3[l] | [ppm]/[mg/l]'),
	('m',           'cm',          'c*_per_*[cm]/[m]'),
	('m',           'ft',          '[ft]/m_per_ft[m]'),
	('m',           'ftUS',        '[ft]/m_per_ft[m] | ftUS_per_ft[ftUS]/[ft]'),
	('m',           'in',          '[ft]/m_per_ft[m] | in_per_ft[in]/[ft]'),
	('m',           'km',          '[km]/*_per_k*[m]'),
	('m',           'mi',          '[ft]/m_per_ft[m] | [mi]/ft_per_mile[ft]'),
	('m',           'mm',          'm*_per_*[mm]/[m]'),
	('m/hr',        'cm/day',      'c*_per_*[cm]/[m] | hr_per_day[hr]/[day]'),
	('m/hr',        'ft/hr',       '[ft]/m_per_ft[m]'),
	('m/hr',        'ft/s',        '[ft]/m_per_ft[m] | [hr]/s_per_hr[s]'),
	('m/hr',        'in/day',      '[ft]/m_per_ft[m] | in_per_ft[in]/[ft] | hr_per_day[hr]/[day]'),
	('m/hr',        'in/hr',       '[ft]/m_per_ft[m] | in_per_ft[in]/[ft]'),
	('m/hr',        'knot',        '[knot]/m/s_per_knot[m/s] | [hr]/s_per_hr[s]'),
	('m/hr',        'kph',         '[km]/*_per_k*[m] | [kph]/[km/hr]'),
	('m/hr',        'm/s',         '[hr]/s_per_hr[s]'),
	('m/hr',        'mm/day',      'm*_per_*[mm]/[m] | hr_per_day[hr]/[day]'),
	('m/hr',        'mm/hr',       'm*_per_*[mm]/[m]'),
	('m/hr',        'mph',         '[ft]/m_per_ft[m] | [mi]/ft_per_mile[ft] | [mph]/[mi/hr]'),
	('m/s',         'cm/day',      'c*_per_*[cm]/[m] | s_per_day[s]/[day]'),
	('m/s',         'ft/hr',       '[ft]/m_per_ft[m] | s_per_hr[s]/[hr]'),
	('m/s',         'ft/s',        '[ft]/m_per_ft[m]'),
	('m/s',         'in/day',      '[ft]/m_per_ft[m] | in_per_ft[in]/[ft] | s_per_day[s]/[day]'),
	('m/s',         'in/hr',       '[ft]/m_per_ft[m] | in_per_ft[in]/[ft] | s_per_hr[s]/[hr]'),
	('m/s',         'knot',        '[knot]/m/s_per_knot[m/s]'),
	('m/s',         'kph',         '[km]/*_per_k*[m] | s_per_hr[s]/[hr] | [kph]/[km/hr]'),
	('m/s',         'm/hr',        's_per_hr[s]/[hr]'),
	('m/s',         'mm/day',      'm*_per_*[mm]/[m] | s_per_day[s]/[day]'),
	('m/s',         'mm/hr',       'm*_per_*[mm]/[m] | s_per_hr[s]/[hr]'),
	('m/s',         'mph',         '[ft]/m_per_ft[m] | [mi]/ft_per_mile[ft] | s_per_hr[s]/[hr] | [mph]/[mi/hr]'),
	('m2',          '1000 acre',   '[ft2]/m_per_ft^2[m2] | [acre]/ft2_per_acre[ft2] | [1000 acre]/*_per_k*[acre]'),
	('m2',          '1000 m2',     '[1000 m2]/*_per_k*[m2]'),
	('m2',          'acre',        '[ft2]/m_per_ft^2[m2] | [acre]/ft2_per_acre[ft2]'),
	('m2',          'cm2',         'c*_per_*^2[cm2]/[m2]'),
	('m2',          'ft2',         '[ft2]/m_per_ft^2[m2]'),
	('m2',          'ha',          '[ha]/m2_per_ha[m2]'),
	('m2',          'km2',         '[km2]/*_per_k*^2[m2]'),
	('m2',          'mile2',       '[ft2]/m_per_ft^2[m2] | [mile2]/ft_per_mile^2[ft2]'),
	('m3',          '1000 m3',     '[1000 m3]/*_per_k*[m3]'),
	('m3',          'ac-ft',       '[ft3]/m_per_ft^3[m3] | [ac-ft]/ft2_per_acre[ft3]'),
	('m3',          'dsf',         '[ft3]/m_per_ft^3[m3] | [dsf]/ft3_per_dsf[ft3]'),
	('m3',          'ft3',         '[ft3]/m_per_ft^3[m3]'),
	('m3',          'gal',         '[gal]/m3_per_gal[m3]'),
	('m3',          'kaf',         '[ft3]/m_per_ft^3[m3] | [ac-ft]/ft2_per_acre[ft3] | [kaf]/*_per_k*[ac-ft]'),
	('m3',          'kdsf',        '[ft3]/m_per_ft^3[m3] | [dsf]/ft3_per_dsf[ft3] | [kdsf]/*_per_k*[dsf]'),
	('m3',          'kgal',        '[gal]/m3_per_gal[m3] | [kgal]/*_per_k*[gal]'),
	('m3',          'km3',         '[km3]/*_per_k*^3[m3]'),
	('m3',          'mcm',         '[mcm]/*_per_M*[m3]'),
	('m3',          'mgal',        '[gal]/m3_per_gal[m3] | [mgal]/*_per_M*[gal]'),
	('m3',          'mile3',       '[ft3]/m_per_ft^3[m3] | [mile3]/ft_per_mile^3[ft3]'),
	('mb',          'bar',         '[bar]/m*_per_*[mb]'),
	('mb',          'in-hg',       '[bar]/m*_per_*[mb] | Pa_per_bar[Pa]/[bar] | [in-hg]/Pa_per_in-hg[Pa]'),
	('mb',          'kPa',         '[bar]/m*_per_*[mb] | Pa_per_bar[Pa]/[bar] | [kPa]/*_per_k*[Pa]'),
	('mb',          'mm-hg',       '[bar]/m*_per_*[mb] | Pa_per_bar[Pa]/[bar] | [mm-hg]/Pa_per_mm-hg[Pa]'),
	('mb',          'psi',         '[bar]/m*_per_*[mb] | Pa_per_bar[Pa]/[bar] | [psi]/Pa_per_psi[Pa]'),
	('mcm',         '1000 m3',     '*_per_M*[m3]/[mcm] | [1000 m3]/*_per_k*[m3]'),
	('mcm',         'ac-ft',       '*_per_M*[m3]/[mcm] | [ft3]/m_per_ft^3[m3] | [ac-ft]/ft2_per_acre[ft3]'),
	('mcm',         'dsf',         '*_per_M*[m3]/[mcm] | [ft3]/m_per_ft^3[m3] | [dsf]/ft3_per_dsf[ft3]'),
	('mcm',         'ft3',         '*_per_M*[m3]/[mcm] | [ft3]/m_per_ft^3[m3]'),
	('mcm',         'gal',         '*_per_M*[m3]/[mcm] | [gal]/m3_per_gal[m3]'),
	('mcm',         'kaf',         '*_per_M*[m3]/[mcm] | [ft3]/m_per_ft^3[m3] | [ac-ft]/ft2_per_acre[ft3] | [kaf]/*_per_k*[ac-ft]'),
	('mcm',         'kdsf',        '*_per_M*[m3]/[mcm] | [ft3]/m_per_ft^3[m3] | [dsf]/ft3_per_dsf[ft3] | [kdsf]/*_per_k*[dsf]'),
	('mcm',         'kgal',        '*_per_M*[m3]/[mcm] | [gal]/m3_per_gal[m3] | [kgal]/*_per_k*[gal]'),
	('mcm',         'km3',         '*_per_M*[m3]/[mcm] | [km3]/*_per_k*^3[m3]'),
	('mcm',         'm3',          '*_per_M*[m3]/[mcm]'),
	('mcm',         'mgal',        '*_per_M*[m3]/[mcm] | [gal]/m3_per_gal[m3] | [mgal]/*_per_M*[gal]'),
	('mcm',         'mile3',       '*_per_M*[m3]/[mcm] | [km3]/*_per_k*^3[m3] | [mile3]/km_per_mile^3[km3]'),
	('mcm/mon',     'KAF/mon',     '*_per_M*[m3]/[mcm] | [ft3]/m_per_ft^3[m3] | [ac-ft]/ft2_per_acre[ft3] | [kaf]/*_per_k*[ac-ft] | [KAF]/[kaf]'),
	('mcm/mon',     'cfs',         '*_per_M*[m3]/[mcm] | [ft3]/m_per_ft^3[m3] | [mon]/s_per_mon[s] | [cfs]/[ft3/s]'),
	('mcm/mon',     'cms',         '*_per_M*[m3]/[mcm] | [ft3]/m_per_ft^3[m3] | [mon]/s_per_mon[s] | m_per_ft^3[m3]/[ft3] | [cms]/[m3/s]'),
	('mcm/mon',     'gpm',         '*_per_M*[m3]/[mcm] | [ft3]/m_per_ft^3[m3] | [mon]/s_per_mon[s] | m_per_ft^3[m3]/[ft3] | [gal]/m3_per_gal[m3] | s_per_min[s]/[min] | [gpm]/[gal/min]'),
	('mcm/mon',     'kcfs',        '*_per_M*[m3]/[mcm] | [ft3]/m_per_ft^3[m3] | [mon]/s_per_mon[s] | [cfs]/[ft3/s] | [kcfs]/*_per_k*[cfs]'),
	('mcm/mon',     'kcms',        '*_per_M*[m3]/[mcm] | [ft3]/m_per_ft^3[m3] | [mon]/s_per_mon[s] | m_per_ft^3[m3]/[ft3] | [cms]/[m3/s] | [kcms]/*_per_k*[cms]'),
	('mcm/mon',     'mgd',         '*_per_M*[m3]/[mcm] | [ft3]/m_per_ft^3[m3] | [mon]/s_per_mon[s] | m_per_ft^3[m3]/[ft3] | [gal]/m3_per_gal[m3] | [mgal]/*_per_M*[gal] | s_per_day[s]/[day] | [mgd]/[mgal/day]'),
	('mg',          'g',           '[g]/m*_per_*[mg]'),
	('mg',          'kg',          '[g]/m*_per_*[mg] | [kg]/*_per_k*[g]'),
	('mg',          'lbm',         '[g]/m*_per_*[mg] | [kg]/*_per_k*[g] | [lbm]/kg_per_lbm[kg]'),
	('mg',          'ton',         '[g]/m*_per_*[mg] | [kg]/*_per_k*[g] | [lbm]/kg_per_lbm[kg] | [ton]/lbm_per_ton[lbm]'),
	('mg',          'tonne',       '[g]/m*_per_*[mg] | [kg]/*_per_k*[g] | [tonne]/kg_per_tonne[kg]'),
	('mg/l',        'g/l',         '[g/l]/m*_per_*[mg/l]'),
	('mg/l',        'g/m3',        '[g]/m*_per_*[mg] | l_per_m3[l]/[m3]'),
	('mg/l',        'gm/cm3',      '[g]/m*_per_*[mg] | l_per_m3[l]/[m3] | [m3]/c*_per_*^3[cm3] | [gm]/[g]'),
	('mg/l',        'lbm/ft3',     '[g]/m*_per_*[mg] | [kg]/*_per_k*[g] | [lbm]/kg_per_lbm[kg] | l_per_m3[l]/[m3] | m_per_ft^3[m3]/[ft3]'),
	('mg/l',        'ppm',         '[ppm]/[mg/l]'),
	('mgal',        '1000 m3',     '*_per_M*[gal]/[mgal] | m3_per_gal[m3]/[gal] | [1000 m3]/*_per_k*[m3]'),
	('mgal',        'ac-ft',       '*_per_M*[gal]/[mgal] | m3_per_gal[m3]/[gal] | [ft3]/m_per_ft^3[m3] | [ac-ft]/ft2_per_acre[ft3]'),
	('mgal',        'dsf',         '*_per_M*[gal]/[mgal] | m3_per_gal[m3]/[gal] | [ft3]/m_per_ft^3[m3] | [dsf]/ft3_per_dsf[ft3]'),
	('mgal',        'ft3',         '*_per_M*[gal]/[mgal] | m3_per_gal[m3]/[gal] | [ft3]/m_per_ft^3[m3]'),
	('mgal',        'gal',         '*_per_M*[gal]/[mgal]'),
	('mgal',        'kaf',         '*_per_M*[gal]/[mgal] | m3_per_gal[m3]/[gal] | [ft3]/m_per_ft^3[m3] | [ac-ft]/ft2_per_acre[ft3] | [kaf]/*_per_k*[ac-ft]'),
	('mgal',        'kdsf',        '*_per_M*[gal]/[mgal] | m3_per_gal[m3]/[gal] | [ft3]/m_per_ft^3[m3] | [dsf]/ft3_per_dsf[ft3] | [kdsf]/*_per_k*[dsf]'),
	('mgal',        'kgal',        '*_per_M*[gal]/[mgal] | [kgal]/*_per_k*[gal]'),
	('mgal',        'km3',         '*_per_M*[gal]/[mgal] | m3_per_gal[m3]/[gal] | [km3]/*_per_k*^3[m3]'),
	('mgal',        'm3',          '*_per_M*[gal]/[mgal] | m3_per_gal[m3]/[gal]'),
	('mgal',        'mcm',         '*_per_M*[gal]/[mgal] | m3_per_gal[m3]/[gal] | [mcm]/*_per_M*[m3]'),
	('mgal',        'mile3',       '*_per_M*[gal]/[mgal] | m3_per_gal[m3]/[gal] | [ft3]/m_per_ft^3[m3] | [mile3]/ft_per_mile^3[ft3]'),
	('mgd',         'KAF/mon',     '[mgal/day]/[mgd] | *_per_M*[gal]/[mgal] | m3_per_gal[m3]/[gal] | [ft3]/m_per_ft^3[m3] | [day]/s_per_day[s] | [cfs]/[ft3/s] | [ft3/s]/[cfs] | s_per_mon[s]/[mon] | [ac-ft]/ft2_per_acre[ft3] | [kaf]/*_per_k*[ac-ft] | [KAF]/[kaf]'),
	('mgd',         'cfs',         '[mgal/day]/[mgd] | *_per_M*[gal]/[mgal] | m3_per_gal[m3]/[gal] | [ft3]/m_per_ft^3[m3] | [day]/s_per_day[s] | [cfs]/[ft3/s]'),
	('mgd',         'cms',         '[mgal/day]/[mgd] | *_per_M*[gal]/[mgal] | m3_per_gal[m3]/[gal] | [day]/s_per_day[s] | [cms]/[m3/s]'),
	('mgd',         'gpm',         '*_per_M*[gal/day]/[mgd] | [day]/min_per_day[min] | [gpm]/[gal/min]'),
	('mgd',         'kcfs',        '[mgal/day]/[mgd] | *_per_M*[gal]/[mgal] | m3_per_gal[m3]/[gal] | [ft3]/m_per_ft^3[m3] | [day]/s_per_day[s] | [kcfs]/*_per_k*[ft3/s]'),
	('mgd',         'kcms',        '[mgal/day]/[mgd] | *_per_M*[gal]/[mgal] | m3_per_gal[m3]/[gal] | [day]/s_per_day[s] | [cms]/[m3/s] | [kcms]/*_per_k*[cms]'),
	('mgd',         'mcm/mon',     '[mgal/day]/[mgd] | [day]/s_per_day[s] | *_per_M*[gal]/[mgal] | m3_per_gal[m3]/[gal] | [ft3]/m_per_ft^3[m3] | s_per_mon[s]/[mon] | m_per_ft^3[m3]/[ft3] | [mcm]/*_per_M*[m3]'),
	('mho',         'S',           '[S]/[mho]'),
	('mho',         'uS',          '[S]/[mho] | u*_per_*[uS]/[S]'),
	('mho',         'umho',        'u*_per_*[umho]/[mho]'),
	('mi',          'cm',          'ft_per_mile[ft]/[mi] | m_per_ft[m]/[ft] | c*_per_*[cm]/[m]'),
	('mi',          'ft',          'ft_per_mile[ft]/[mi]'),
	('mi',          'ftUS',        'ft_per_mile[ft]/[mi] | ftUS_per_ft[ftUS]/[ft]'),
	('mi',          'in',          'ft_per_mile[ft]/[mi] | in_per_ft[in]/[ft]'),
	('mi',          'km',          'ft_per_mile[ft]/[mi] | m_per_ft[m]/[ft] | [km]/*_per_k*[m]'),
	('mi',          'm',           'ft_per_mile[ft]/[mi] | m_per_ft[m]/[ft]'),
	('mi',          'mm',          'ft_per_mile[ft]/[mi] | m_per_ft[m]/[ft] | m*_per_*[mm]/[m]'),
	('mile2',       '1000 acre',   'ft_per_mile^2[ft2]/[mile2] | [acre]/ft2_per_acre[ft2] | [1000 acre]/*_per_k*[acre]'),
	('mile2',       '1000 m2',     'ft_per_mile^2[ft2]/[mile2] | m_per_ft^2[m2]/[ft2] | [1000 m2]/*_per_k*[m2]'),
	('mile2',       'acre',        'ft_per_mile^2[ft2]/[mile2] | [acre]/ft2_per_acre[ft2]'),
	('mile2',       'cm2',         'km_per_mile^2[km2]/[mile2] | *_per_k*^2[m2]/[km2] | c*_per_*^2[cm2]/[m2]'),
	('mile2',       'ft2',         'ft_per_mile^2[ft2]/[mile2]'),
	('mile2',       'ha',          'km_per_mile^2[km2]/[mile2] | *_per_k*^2[m2]/[km2] | [ha]/m2_per_ha[m2]'),
	('mile2',       'km2',         'km_per_mile^2[km2]/[mile2]'),
	('mile2',       'm2',          'km_per_mile^2[km2]/[mile2] | *_per_k*^2[m2]/[km2]'),
	('mile3',       '1000 m3',     'km_per_mile^3[km3]/[mile3] | *_per_k*^3[m3]/[km3] | [1000 m3]/*_per_k*[m3]'),
	('mile3',       'ac-ft',       'ft_per_mile^3[ft3]/[mile3] | [ac-ft]/ft2_per_acre[ft3]'),
	('mile3',       'dsf',         'ft_per_mile^3[ft3]/[mile3] | [dsf]/ft3_per_dsf[ft3]'),
	('mile3',       'ft3',         'ft_per_mile^3[ft3]/[mile3]'),
	('mile3',       'gal',         'km_per_mile^3[km3]/[mile3] | *_per_k*^3[m3]/[km3] | [gal]/m3_per_gal[m3]'),
	('mile3',       'kaf',         'ft_per_mile^3[ft3]/[mile3] | [ac-ft]/ft2_per_acre[ft3] | [kaf]/*_per_k*[ac-ft]'),
	('mile3',       'kdsf',        'ft_per_mile^3[ft3]/[mile3] | [dsf]/ft3_per_dsf[ft3] | [kdsf]/*_per_k*[dsf]'),
	('mile3',       'kgal',        'km_per_mile^3[km3]/[mile3] | *_per_k*^3[m3]/[km3] | [gal]/m3_per_gal[m3]] | [kgal]/*_per_k*[gal]'),
	('mile3',       'km3',         'ft_per_mile^3[ft3]/[mile3] | m_per_ft^3[m3]/[ft3] | [km3]/*_per_k*^3[m3]'),
	('mile3',       'm3',          'km_per_mile^3[km3]/[mile3] | *_per_k*^3[m3]/[km3]'),
	('mile3',       'mcm',         'km_per_mile^3[km3]/[mile3] | *_per_k*^3[m3]/[km3] | [mcm]/*_per_M*[m3]'),
	('mile3',       'mgal',        'km_per_mile^3[km3]/[mile3] | *_per_k*^3[m3]/[km3] | [gal]/m3_per_gal[m3]] | [mgal]/*_per_M*[gal]'),
	('min',         'day',         '[day]/min_per_day[min]'),
	('min',         'hr',          '[hr]/min_per_hr[min]'),
	('min',         'sec',         's_per_min[sec]/[min]'),
	('mm',          'cm',          '[m]/m*_per_*[mm] | c*_per_*[cm]/[m]'),
	('mm',          'ft',          '[m]/m*_per_*[mm] | [ft]/m_per_ft[m]'),
	('mm',          'ftUS',        '[m]/m*_per_*[mm] | [ft]/m_per_ft[m] | ftUS_per_ft[ftUS]/[ft]'),
	('mm',          'in',          '[m]/m*_per_*[mm] | [ft]/m_per_ft[m] | in_per_ft[in]/[ft]'),
	('mm',          'km',          '[m]/m*_per_*[mm] | [km]/*_per_k*[m]'),
	('mm',          'm',           '[m]/m*_per_*[mm]'),
	('mm',          'mi',          '[m]/m*_per_*[mm] | [ft]/m_per_ft[m] | [mi]/ft_per_mile[ft]'),
	('mm-hg',       'bar',         'Pa_per_mm-hg[Pa]/[mm-hg] | [bar]/Pa_per_bar[Pa]'),
	('mm-hg',       'in-hg',       '[m-hg]/m*_per_*[mm-hg] | [ft-hg]/m_per_ft[m-hg] | in_per_ft[in-hg]/[ft-hg]'),
	('mm-hg',       'kPa',         'Pa_per_mm-hg[Pa]/[mm-hg] | [kPa]/*_per_k*[Pa]'),
	('mm-hg',       'mb',          'Pa_per_mm-hg[Pa]/[mm-hg] | [bar]/Pa_per_bar[Pa] | m*_per_*[mb]/[bar]'),
	('mm-hg',       'psi',         'Pa_per_mm-hg[Pa]/[mm-hg] | [psi]/Pa_per_psi[Pa]'),
	('mm/day',      'cm/day',      'c*_per_*[cm]/m*_per_*[mm]'),
	('mm/day',      'ft/hr',       '[m]/m*_per_*[mm] | [ft]/m_per_ft[m] | [day]/hr_per_day[hr]'),
	('mm/day',      'ft/s',        '[m]/m*_per_*[mm] | [ft]/m_per_ft[m] | [day]/s_per_day[s]'),
	('mm/day',      'in/day',      '[m/day]/m*_per_*[mm/day] | [ft/day]/m_per_ft[m/day] | in_per_ft[in/day]/[ft/day]'),
	('mm/day',      'in/hr',       '[m/day]/m*_per_*[mm/day] | [ft/day]/m_per_ft[m/day] | in_per_ft[in/day]/[ft/day] | [in/hr]/hr_per_day[in/day]'),
	('mm/day',      'knot',        '[m/day]/m*_per_*[mm/day] | [m/s]/s_per_day[m/day] | [knot]/m/s_per_knot[m/s]'),
	('mm/day',      'kph',         '[m/day]/m*_per_*[mm/day] | [km/day]/*_per_k*[m/day] | [km/h]/hr_per_day[km/day] | [kph]/[km/h]'),
	('mm/day',      'm/hr',        '[m/day]/m*_per_*[mm/day] | [m/hr]/hr_per_day[m/day]'),
	('mm/day',      'm/s',         '[m/day]/m*_per_*[mm/day] | [m/s]/s_per_day[m/day]'),
	('mm/day',      'mm/hr',       '[mm/hr]/hr_per_day[mm/day]'),
	('mm/day',      'mph',         '[m/day]/m*_per_*[mm/day] | [ft/day]/m_per_ft[m/day] | [mile/day]/ft_per_mile[ft/day] | [mile/hr]/hr_per_day[mile/day] | [mph]/[mile/hr]'),
	('mm/deg-day',  'in/deg-day',  '[m]/m*_per_*[mm] | [ft]/m_per_ft[m] | in_per_ft[in]/[ft] | C_per_F[deg-day]/[deg-day]'),
	('mm/hr',       'cm/day',      'c*_per_*[cm]/m*_per_*[mm] | hr_per_day[hr]/[day]'),
	('mm/hr',       'ft/hr',       '[m]/m*_per_*[mm] | [ft]/m_per_ft[m]'),
	('mm/hr',       'ft/s',        '[m]/m*_per_*[mm] | [ft]/m_per_ft[m] | [hr]/s_per_hr[s]'),
	('mm/hr',       'in/day',      '[m]/m*_per_*[mm] | [ft]/m_per_ft[m] | in_per_ft[in]/[ft] | hr_per_day[hr]/[day]'),
	('mm/hr',       'in/hr',       '[m]/m*_per_*[mm] | [ft]/m_per_ft[m] | in_per_ft[in]/[ft]'),
	('mm/hr',       'knot',        '[m/hr]/m*_per_*[mm/hr] | [m/s]/s_per_hr[m/hr] | [knot]/m/s_per_knot[m/s]'),
	('mm/hr',       'kph',         '[m]/m*_per_*[mm] | [km]/*_per_k*[m] | [kph]/[km/hr]'),
	('mm/hr',       'm/hr',        '[m]/m*_per_*[mm]'),
	('mm/hr',       'm/s',         '[m]/m*_per_*[mm] | [hr]/s_per_hr[s]'),
	('mm/hr',       'mm/day',      'hr_per_day[hr]/[day]'),
	('mm/hr',       'mph',         '[m]/m*_per_*[mm] | [ft]/m_per_ft[m] | [mile]/ft_per_mile[ft] | [mph]/[mile/hr]'),
	('mph',         'cm/day',      '[mile/hr]/[mph] | ft_per_mile[ft]/[mile] | m_per_ft[m]/[ft] | c*_per_*[cm]/[m] | hr_per_day[hr]/[day]'),
	('mph',         'ft/hr',       '[mile/hr]/[mph] | ft_per_mile[ft]/[mile]'),
	('mph',         'ft/s',        '[mile/hr]/[mph] | ft_per_mile[ft]/[mile] | [hr]/s_per_hr[s]'),
	('mph',         'in/day',      '[mile/hr]/[mph] | ft_per_mile[ft]/[mile] | in_per_ft[in]/[ft] | hr_per_day[hr]/[day]'),
	('mph',         'in/hr',       '[mile/hr]/[mph] | ft_per_mile[ft]/[mile] | in_per_ft[in]/[ft]'),
	('mph',         'knot',        '[mile/hr]/[mph] | ft_per_mile[ft]/[mile] | m_per_ft[m]/[ft] | [hr]/s_per_hr[s] | [knot]/m/s_per_knot[m/s]'),
	('mph',         'kph',         '[mile/hr]/[mph] | ft_per_mile[ft]/[mile] | m_per_ft[m]/[ft] | [km]/*_per_k*[m] | [kph]/[km/hr]'),
	('mph',         'm/hr',        '[mile/hr]/[mph] | ft_per_mile[ft]/[mile] | m_per_ft[m]/[ft]'),
	('mph',         'm/s',         '[mile/hr]/[mph] | ft_per_mile[ft]/[mile] | m_per_ft[m]/[ft] | [hr]/s_per_hr[s]'),
	('mph',         'mm/day',      '[mile/hr]/[mph] | ft_per_mile[ft]/[mile] | m_per_ft[m]/[ft] | m*_per_*[mm]/[m] | hr_per_day[hr]/[day]'),
	('mph',         'mm/hr',       '[mile/hr]/[mph] | ft_per_mile[ft]/[mile] | m_per_ft[m]/[ft] | m*_per_*[mm]/[m]'),
	('n/a',         '%',           'c*_per_*[%]/[n/a]'),
	('ppm',         'g/l',         '[mg/l]/[ppm] | [g]/m*_per_*[mg]'),
	('ppm',         'g/m3',        '[mg/l]/[ppm] | [g]/m*_per_*[mg] | l_per_m3[l]/[m3]'),
	('ppm',         'gm/cm3',      '[mg/l]/[ppm] | [g]/m*_per_*[mg] | l_per_m3[l]/[m3] | [m3]/c*_per_*^3[cm3] | [gm]/[g]'),
	('ppm',         'lbm/ft3',     '[mg/l]/[ppm] | [g]/m*_per_*[mg] | [kg]/*_per_k*[g] | [lbm]/kg_per_lbm[kg] | l_per_m3[l]/[m3] | m_per_ft^3[m3]/[ft3]'),
	('ppm',         'mg/l',        '[mg/l]/[ppm]'),
	('psi',         'bar',         'Pa_per_psi[Pa]/[psi] | [bar]/Pa_per_bar[Pa]'),
	('psi',         'in-hg',       'Pa_per_psi[Pa]/[psi] | [in-hg]/Pa_per_in-hg[Pa]'),
	('psi',         'kPa',         'Pa_per_psi[Pa]/[psi] | [kPa]/*_per_k*[Pa]'),
	('psi',         'mb',          'Pa_per_psi[Pa]/[psi] | [bar]/Pa_per_bar[Pa] | m*_per_*[mb]/[bar]'),
	('psi',         'mm-hg',       'Pa_per_psi[Pa]/[psi] | [mm-hg]/Pa_per_mm-hg[Pa]'),
	('rad',         'deg',         '[deg]/rad_per_deg[rad]'),
	('rad',         'rev',         '[rev]/deg_per_rev[deg] | [deg]/rad_per_deg[rad]'),
	('rev',         'deg',         'deg_per_rev[deg]/[rev]'),
	('rev',         'rad',         'rad_per_deg[rad]/[deg] | deg_per_rev[deg]/[rev]'),
	('sec',         'day',         '[day]/s_per_day[sec]'),
	('sec',         'hr',          '[hr]/s_per_hr[sec]'),
	('sec',         'min',         '[min]/s_per_min[sec]'),
	('ton',         'g',           'lbm_per_ton[lbm]/[ton] | kg_per_lbm[kg]/[lbm] | *_per_k*[g]/[kg]'),
	('ton',         'kg',          'lbm_per_ton[lbm]/[ton] | kg_per_lbm[kg]/[lbm]'),
	('ton',         'lbm',         'lbm_per_ton[lbm]/[ton]'),
	('ton',         'mg',          'lbm_per_ton[lbm]/[ton] | kg_per_lbm[kg]/[lbm] | *_per_k*[g]/[kg] | m*_per_*[mg]/[g]'),
	('ton',         'tonne',       'lbm_per_ton[lbm]/[ton] | kg_per_lbm[kg]/[lbm] | [tonne]/kg_per_tonne[kg]'),
	('ton/day',     'tonne/day',   'lbm_per_ton[lbm]/[ton] | kg_per_lbm[kg]/[lbm] | [tonne]/kg_per_tonne[kg]'),
	('tonne',       'g',           'kg_per_tonne[kg]/[tonne] | *_per_k*[g]/[kg]'),
	('tonne',       'kg',          'kg_per_tonne[kg]/[tonne]'),
	('tonne',       'lbm',         'kg_per_tonne[kg]/[tonne] | [lbm]/kg_per_lbm[kg]'),
	('tonne',       'mg',          'kg_per_tonne[kg]/[tonne] | *_per_k*[g]/[kg] | m*_per_*[mg]/[g]'),
	('tonne',       'ton',         'kg_per_tonne[kg]/[tonne] | [lbm]/kg_per_lbm[kg] | [ton]/lbm_per_ton[lbm]'),
	('tonne/day',   'ton/day',     'kg_per_tonne[kg]/[tonne] | [lbm]/kg_per_lbm[kg] | [ton]/lbm_per_ton[lbm]'),
	('uS',          'S',           '[S]/u*_per_*[uS]'),
	('uS',          'mho',         '[mho]/u*_per_*[uS]'),
	('uS',          'umho',        '[umho]/[uS]'),
	('umho',        'S',           '[mho]/u*_per_*[umho] | [S]/[mho]'),
	('umho',        'mho',         '[mho]/u*_per_*[umho]'),
	('umho',        'uS',          '[uS]/[umho]'),
]

english_units = {"English" : [
	"$",
	"$/kaf",
	"%",
	"1/ft",
	"1000 acre",
	"ac-ft",
	"acre",
	"ampere",
	"B",
	"bar",
	"cfs",
	"cfs/mi2",
	"day",
	"deg",
	"dsf",
	"F",
	"F-day",
	"FNU",
	"ft",
	"ft/hr",
	"ft/s",
	"ft2",
	"ft3",
	"ftUS",
	"g/l",
	"gal",
	"gpm",
	"GW",
	"GWh",
	"hr",
	"Hz",
	"in",
	"in-hg",
	"in/day",
	"in/deg-day",
	"in/hr",
	"J/m2",
	"JTU",
	"k$",
	"kaf",
	"KAF/mon",
	"kcfs",
	"kdsf",
	"kgal",
	"kHz",
	"knot",
	"kW",
	"kWh",
	"langley",
	"langley/min",
	"lb",
	"lbm",
	"lbm/ft3",
	"mgal",
	"mgd",
	"mho",
	"MHz",
	"mi",
	"mile2",
	"mile3",
	"min",
	"mph",
	"MW",
	"MWh",
	"n/a",
	"NTU",
	"ppm",
	"psi",
	"rad",
	"rev",
	"rpm",
	"S",
	"sec",
	"su",
	"ton",
	"ton/day",
	"TW",
	"TWh",
	"umho",
	"umho/cm",
	"unit",
	"uS",
	"volt",
	"W",
	"W/m2",
	"Wh",
]}

si_units = {"SI" : [
	"$",
	"$/mcm",
	"%",
	"1/m",
	"1000 m2",
	"1000 m3",
	"ampere",
	"B",
	"bar",
	"C",
	"C-day",
	"cal",
	"cm",
	"cm/day",
	"cm2",
	"cms",
	"cms/km2",
	"day",
	"deg",
	"FNU",
	"g",
	"g/l",
	"g/m3",
	"gm/cm3",
	"GW",
	"GWh",
	"ha",
	"hr",
	"Hz",
	"J",
	"J/m2",
	"JTU",
	"K",
	"k$",
	"kcms",
	"kg",
	"kHz",
	"km",
	"km2",
	"km3",
	"kPa",
	"kph",
	"kW",
	"kWh",
	"langley",
	"langley/min",
	"m",
	"m/hr",
	"m/s",
	"m2",
	"m3",
	"mb",
	"mcm",
	"mcm/mon",
	"mg",
	"mg/l",
	"mho",
	"MHz",
	"min",
	"mm",
	"mm-hg",
	"mm/day",
	"mm/deg-day",
	"mm/hr",
	"MJ",
	"MW",
	"MWh",
	"N",
	"n/a",
	"NTU",
	"ppm",
	"rad",
	"rev",
	"rpm",
	"S",
	"sec",
	"su",
	"tonne",
	"tonne/day",
	"TW",
	"TWh",
	"umho",
	"umho/cm",
	"unit",
	"uS",
	"volt",
	"W",
	"W/m2",
	"Wh",
]}

units_by_unit_system = [
	english_units,
	si_units
]

angle_units = {"Angle" : [
	"deg",
	"rad",
	"rev",
]}

angular_speed_units = {"Angluar Speed" : [
	"rpm",
]}

area_units = {"Area" : [
	"1000 acre",
	"1000 m2",
	"acre",
	"cm2",
	"ft2",
	"ha",
	"km2",
	"m2",
	"mile2",
]}

areal_volume_rate_units = {"Areal Volume Rate" : [
	"cfs/mi2",
	"cms/km2",
]}

conductance_units = {"Conductance" : [
	"mho",
	"S",
	"umho",
	"uS",
]}

conductivity_units = {"Conductivity" : [
	"umho/cm",
]}

count_units = {"Count" : [
	"unit",
]}

currency_units = {"Currency" :[
	"$",
]}

currency_per_volume_units = {"Currency per Volume" : [
	"$/kaf",
	"$/mcm",
]}

decay_coefficient_units = {"Decay Coeffs" : [
	"1/ft",
	"1/m",
]}

elapsed_time_units = {"Elapsed Time" : [
	"day",
	"hr",
	"min",
	"sec",
]}

electric_charge_rate_units = {"Electric Charge Rate" : [
	"ampere",
]}

electromotive_potential_units = {"Electromotive Potential" : [
	"volt",
]}

energy_units = {"Energy" : [
	"GWh",
	"kWh",
	"MWh",
	"TWh",
	"Wh",
	"J",
	"MJ",
	"cal"
]}

force_units = {"Force" : [
	"lb",
	"N",
]}

frequency_units = {"Frequency" : [
	"B",
	"Hz",
	"kHz",
	"MHz",
]}

heating_and_cooling_units = {"Heating and Cooling" : [
	"C-day",
	"F-day",
]}

hydrogen_ion_concentration_index_units = {"Hydrogen Ion Concentration" : [
	"su",
]}

irradiance_units = {"Irradiance" : [
	"langley/min",
	"W/m2",
]}

irradiation_units = {"Irradiation" : [
	"J/m2",
	"langley",
]}

length_units = {"Length" : [
	"cm",
	"ft",
	"ftUS",
	"in",
	"km",
	"m",
	"mi",
	"mm",
]}

linear_speed_units = {"Linear Speed" : [
	"cm/day",
	"ft/hr",
	"ft/s",
	"in/day",
	"in/hr",
	"knot",
	"kph",
	"m/hr",
	"m/s",
	"mm/day",
	"mm/hr",
	"mph",
]}

mass_units = {"Mass" : [
	"g",
	"kg",
	"lbm",
	"mg",
	"ton",
	"tonne",
]}

mass_concentration_units = {"Mass Concentration" : [
	"g/l",
	"g/m3",
	"gm/cm3",
	"lbm/ft3",
	"mg/l",
	"ppm",
]}

mass_rate_units = {"Mass Rate" : [
	"ton/day",
	"tonne/day",
]}

monthly_volume_rate_units = {"Monthly Volume Rate" : [
	"KAF/mon",
	"mcm/mon",
]}

none_units = {"None" : [
	"%",
	"n/a",
]}

penalty_units = {"Penalty" : [
	"k$",
]}

phase_change_rate_index_units = {"Phase Change Rate Index" : [
	"in/deg-day",
	"mm/deg-day",
]}

power_units = {"Power" : [
	"GW",
	"kW",
	"MW",
	"TW",
	"W",
]}

pressure_units = {"Pressure" : [
	"bar",
	"in-hg",
	"kPa",
	"mb",
	"mm-hg",
	"psi",
]}

temperature_units = {"Temperature" : [
	"C",
	"F",
	"K",
]}

turbidity_units = {"Turbidity" : [
	"FNU",
	"JTU",
	"NTU",
]}

volume_units = {"Volume" : [
	"1000 m3",
	"ac-ft",
	"dsf",
	"ft3",
	"gal",
	"kaf",
	"kdsf",
	"kgal",
	"km3",
	"m3",
	"mcm",
	"mgal",
	"mile3",
]}

volume_rate_units = {"Volume Rate" : [
	"cfs",
	"cms",
	"gpm",
	"kcfs",
	"kcms",
	"mgd",
]}

units_by_param = [
	angle_units,
	angular_speed_units,
	area_units,
	areal_volume_rate_units,
	conductance_units,
	conductivity_units,
	count_units,
	currency_units,
	currency_per_volume_units,
	decay_coefficient_units,
	elapsed_time_units,
	electric_charge_rate_units,
	electromotive_potential_units,
	energy_units,
	force_units,
	frequency_units,
	heating_and_cooling_units,
	hydrogen_ion_concentration_index_units,
	irradiance_units,
	irradiation_units,
	length_units,
	linear_speed_units,
	mass_units,
	mass_concentration_units,
	mass_rate_units,
	monthly_volume_rate_units,
	none_units,
	penalty_units,
	phase_change_rate_index_units,
	power_units,
	pressure_units,
	temperature_units,
	turbidity_units,
	volume_units,
	volume_rate_units,
]

all_from_units        = [cd[0] for cd in conversion_definitions]
all_to_units          = [cd[1] for cd in conversion_definitions]
all_unit_system_units = reduce(lambda a, b : {"" : a.values()[0] + b.values()[0]}, units_by_unit_system)
all_unit_system_units = all_unit_system_units.values()[0]
all_param_units       = reduce(lambda a, b : {"" : a.values()[0] + b.values()[0]}, units_by_param)
all_param_units       = all_param_units.values()[0]

all_units_lists = [
	all_from_units,
	all_to_units,
	all_unit_system_units,
	all_param_units
]

no_conversion_units = [
	"$",
	"FNU",
	"JTU",
	"NTU",
	"ampere",
	"k$",
	"rpm",
	"su",
	"umho/cm",
	"unit",
	"volt"
]

unit_aliases = {
	"$/kaf"      : ["$/KAF"],
	"%"          : ["percent","PERCENT"],
	"1000 acre"  : ["1000 acres","1000 ACRE","1000 ACRES"],
	"1000 m2"    : ["1000 sq m","1000 sq meters","1000 M2"],
	"1000 m3"    : ["1000 cu m","1000 M3"],
	"ac-ft"      : ["AC-FT","ACFT","acft","acre-feet","acre-ft"],
	"acre"       : ["acres","ACRES"],
	"ampere"     : ["amp","AMP","Amp","AMPERE","Ampere","Amperes","AMPERES","amperes","AMPS","amps","Amps"],
	"B"          : ["b", "b_unit", "b-unit", "B_UNIT", "B-UNIT"],
	"bar"        : ["BAR", 'bars', "BARS","atm", "ATM","atmosphere", "ATMOSPHERE", "atmospheres", "ATMOSPHERES"],
	"C"          : ["Celsius","Centigrade","DEG C","deg C","DEG-C","Deg-C","DegC","degC","deg c"],
	"C-day"      : ["degC-day"],
	"cal"        : ["calorie", "calories"],
	"cfs"        : ["CFS","cu-ft/sec","cuft/sec","cusecs","ft3/sec","ft^3/s","FT3/S","FT3/SEC","ft3/s"],
	"cm"         : ["centimeter","centimeters"],
	"cms"        : ["CMS","cu-meters/sec","M3/S","m3/s","m3/sec","M3/SEC"],
	"day"        : ["DAY","day","DAYS","days"],
	"dsf"        : ["DSF","SFD","cfs-day","second-foot-day","sfd"],
	"F"          : ["DEG F","deg F","deg f","DEG-F","Deg-F","DegF","degF","Fahrenheit"],
	"F-day"      : ["degF-day"],
	"FNU"        : ["fnu"],
	"ft"         : ["FEET","feet","foot","FT","Feet"],
	"ftUS"       : ["survey foot", "survey feet", "SURVEY FOOT", "SURVEY FEET"],
	"ft/s"       : ["fps","ft/sec"],
	"ft2"        : ["sq ft","square feet"],
	"ft3"        : ["cu ft","cubic feet"],
	"g"          : ["gm"],
	"g/l"        : ["gm/l","grams per liter","grams/liter"],
	"g/m3"       : ["gm/m3"],
	"gal"        : ["GAL","gallon","gallons"],
	"gm/cm3"     : ["g/cm3"],
	"gpm"        : ["Gal/min","gallons per minute","GPM"],
	"GWh"        : ["GWH"],
	"ha"         : ["hectare","hectares"],
	"hr"         : ["hour","hours","HR","HOUR","HOURS"],
	"Hz"         : ["cycles/s", "cycles/sec", "hz", "HZ"],
	"in"         : ["IN","inch","inches","INCHES","Inch"],
	"in/deg-day" : ["in/deg-d"],
	"J"          : ["joule", "joules", "JOULE", "JOULES"],
	"JTU"        : ["jtu"],
	"K"          : ["k", "KELVIN", "kelvin", "KELVINS", "kelvins"],
	"k$"         : ["K$"],
	"kaf"        : ["1000 ac-ft","KAF"],
	"KAF/mon"    : ["1000 ac-ft/mon"],
	"kcfs"       : ["1000 cfs","1000 cu-ft/sec","1000 ft3/sec","KCFS"],
	"kcms"       : ["1000 cms","KCMS"],
	"kgal"       : ["1000 gallon","1000 gallons","KGAL","TGAL","tgal"],
	"kHz"        : ["khz", "KHZ", "KHz"],
	"km"         : ["kilometer","kilometers"],
	"km2"        : ["sq km","sq.km","sqkm"],
	"km3"        : ["cu km"],
	"knot"       : ["knots","kt"],
	"kPa"        : ["kN/m2"],
	"kW"         : ["KW"],
	"kWh"        : ["KWH"],
	"lb"         : ["lbf", "lbs", "pounds", "POUNDS"],
	"lbm/ft3"    : ["lb/ft3", "lbs/ft3"],
	"m"          : ["meter","meters","metre","metres","METERS"],
	"m2"         : ["sq m","sq meter","sq meters","square meters","M2"],
	"m3"         : ["cu m","cu meter","cu meters","cubic meters","M3"],
	"mb"         : ["mbar","mbars","millibar","millibars"],
	"mcm"        : ["1000000 m3"],
	"mg/l"       : ["millgrams/liter","milligrams per liter","mg/L"],
	"mgal"       : ["MGAL","million gallon","millon gallons"],
	"mgd"        : ["MGD","million gallons/day"],
	"MHz"        : ["mhz", "mHz", "MHZ"],
	"mi"         : ["mile","miles","Mile"],
	"mile2"      : ["mi2","sq mi","sq mile","sq miles","square miles"],
	"mile3"      : ["cu mile","cu miles"],
	"min"        : ["minute","minutes","MIN","MINUTE","MINUTES"],
	"MJ"         : ["megajoule", "megajoules", "MEGAJOULE", "MEGAJOULES"],
	"mm"         : ["millimeter","millimeters","MM"],
	"mm/deg-day" : ["mm/deg-d"],
	"MWh"        : ["MWH"],
	"N"          : ["newton", "newtons"],
	"NTU"        : ["ntu"],
	"psi"        : ["lbs/sqin"],
	"rpm"        : ["rev/min","revolutions per minute"],
	"sec"        : ["second","seconds","SEC","SECOND","SECONDS"],
	"TWh"        : ["TWH"],
	"Wh"         : ["WH"],
	"umho/cm"    : ["umhos/cm","UMHO/CM","UMHOS/CM"],
	"volt"       : ["Volt","VOLT","Volts","volts","VOLTS"],
}

contains_unit = {
	"%"           : ["c"],
	"1000 acre"   : ["kacre"],
	"1000 m"      : ["km"],
	"ac-ft"       : ["acre"],
	"deg"         : ["F", "C"],
	"gpm"         : ["gal"],
	"h"           : ["hr"],
	"kaf"         : ["ac-ft"],
	"mcm"         : ["m", "Mm3"],
	"mgal"        : ["Mgal"],
	"mgd"         : ["Mgal"],
	"mi"          : ["mile"],
	"mph"         : ["mile"],
	"sec"         : ["s"],
}

java_primary_units = set([
	"$/KAF",
	"degC-day",
	"degF-day",
	"fnu",
	"gm",
	"g/cm3",
	"jtu",
	"K$",
	"lb/ft3",
	"ntu",
])

#
# Verify that every unit alias references a unit that is specified both by unit system and by parameter
#
for unit in sorted(unit_aliases.keys()) :
	if unit not in all_unit_system_units :
		raise Exception("Unit %s is not in any unit system list" % unit);
	if unit not in all_param_units :
		raise Exception("Unit %s is not in any parameter list" % unit);
#
# Verify that every unit in every list is identified by unit system and by parameter, and that
# every unit except those specified to have no conversions are listed as conversion sources and
# conversion targets.
#
for i in range(len(all_units_lists)) :
	for j in range(len(all_units_lists)) :
		if i == j : continue
		for unit in all_units_lists[i] :
			if unit in no_conversion_units and j < 2 :
				continue
			if unit not in all_units_lists[j] :
				raise Exception("Unit %s is not in list %d (%s)" % (unit, j, all_units_lists[j]))

def contains(test, unit) :
	if type(test) == type([]) :
		found =  any([contains(item, unit) for item in test])
		if found : return True
		if re.search("\d+", unit) is not None :
			return contains(test, re.sub("\s+", "", re.sub("\^?\d+", "", unit)))
		else :
			return False
	if test == unit : return True
	if test.find("-") != -1 and contains(test.split("-"), unit) : return True
	if re.search("\d+", test) is not None and contains(re.sub("\s+", "", re.sub("\^?\d+", "", test)), unit) : return True
	if contains_unit.has_key(test) and contains(contains_unit[test], unit) : return True
	return False

def expand_units(unit) :
	'''
	m     -> [m]
	m2    -> [m, m]
	m3*s2 -> [m, m, m, s, s]
	etc..
	'''
	units = []
	if unit :
		if unit.find("*") != -1 :
			#----------------------------#
			# expand each unit component #
			#----------------------------#
			for part in unit.split("*") :
				units.extend(expand_units(part))
		else :
			#---------------------------#
			# expand a single component #
			#---------------------------#
			if unit[-1].isdigit() :
				unit, count = unit[:-1], int(unit[-1])
			else :
				count = 1
			units = count * [unit]
	return units

def process_conversion_definition(from_unit, definition) :
	'''
	perform dimensional analysis to determine the conversion factor
	'''
	#--------------------------------#
	# parse the quantities and units #
	#--------------------------------#
	n_units = []
	d_units = []
	identities = map(string.strip, definition.split('|'))
	id_count = len(identities)
	func_ids = []
	for i in range(id_count) :
		if patternFunc.match(identities[i]) :
			if i in (0, id_count-1) :
				func_ids.append(i)
			else :
				raise Exception("Function can only appear in first or last identity: %s" % definition)
	if len(func_ids) > 1 :
		raise Exception("Only one function can appear in an identity: %s" % definition)
	elif len(func_ids) == 1 :
		#-----------------------#
		# non-linear conversion #
		#-----------------------#
		m = patternFunc.match(identities[func_ids[0]])
		_to_unit = m.group(2)
		_from_unit = m.group(4)
		func_name = "%s_to_%s" % (_from_unit, _to_unit)
		func_body = functions[func_name]
		if id_count == 1 :
			unit = _to_unit
		else :
			if func_ids[0] == 0:
				factor, dummy, unit = process_conversion_definition(_to_unit, " | ".join(identities[1:]))
				func_body  += "|%s|*" % factor
				try    : offset = offsets["%s_to_%s" % (_to_unit, unit)]
				except : offset = None
				if offset :
					if offset < 0 :
						func_body  += "|%s|-" % offset
					else :
						func_body  += "|%s|+" % offset

			else :
				factor, dummy, unit = process_conversion_definition(_from_unit, " | ".join(identities[:-1]))
				try    : offset = offsets["%s_to_%s" % (from_unit, _from_unit)]
				except : offset = None
				if offset :
					if offset < 0 :
						func_body = func_body.replace("ARG 0", "ARG 0|%s|*|%s|-" % (factor, offset))
					else :
						func_body = func_body.replace("ARG 0", "ARG 0|%s|*|%s|+" % (factor, offset))
				else :
					func_body = func_body.replace("ARG 0", "ARG 0|%s|*" % factor)
				unit = _to_unit
		factor = offset = None
	else :
		#-------------------#
		# linear conversion #
		#-------------------#
		try    : n, d = map(string.strip, from_unit.split('/'))
		except : n, d = from_unit.strip(), None
		n_units.extend(expand_units(n))
		d_units.extend(expand_units(d))
		factor    = Decimal('1.0')
		for identity in identities :
			m = patternIdent.match(identity)
			assert m is not None
			func_body = None
			n_quant   = m.group(3)
			n_power   = m.group(5)
			n_unit    = m.group(7)
			d_quant   = m.group(9)
			d_power   = m.group(11)
			d_unit    = m.group(13)
			if n_quant :
				if n_power :
					factor *= conversion_factors[n_quant] ** Decimal(n_power)
				else :
					factor *= conversion_factors[n_quant]
			if d_quant :
				if d_power :
					factor /= conversion_factors[d_quant] ** Decimal(d_power)
				else :
					factor /= conversion_factors[d_quant]

			try    : n, d = map(string.strip, n_unit.split('/'))
			except : n, d = n_unit.strip(), None
			n_units.extend(expand_units(n))
			d_units.extend(expand_units(d))
			try    : n, d = map(string.strip, d_unit.split('/'))
			except : n, d = d_unit.strip(), None
			d_units.extend(expand_units(n))
			n_units.extend(expand_units(d))
			if m.group(2) is not None :
				n_unit, d_unit = m.group(2).split("_per_")
				if n_unit.find("/") != -1 :
					parts = n_unit.split("/")
					n_unit = parts[0]
					d_unit = d_unit + "-" + parts[1]
				if d_unit.find("/") != -1 :
					parts = d_unit.split("/")
					d_unit = parts[0]
					n_unit = n_unit + "-" + parts[1]
				if n_unit.startswith("*") :
					pass
				elif n_unit[1:].startswith("*") :
					prefix = n_unit[0]
					for unit in n_units :
						if unit.startswith(prefix) :
							break
						found = False
						if contains_unit.has_key(unit) :
							for _unit in contains_unit[unit] :
								if _unit.startswith(prefix) :
									found = True
									break
							if found : break
					else :
						raise Exception("%s is not in %s for identity %s" % (n_unit, n_units, identity))
				else :
					for _n_unit in n_unit.split("-") :
						if _n_unit not in n_units and not contains(n_units, _n_unit):
							raise Exception("%s is not in %s for identity %s" % (_n_unit, n_units, identity))
				if d_unit.startswith("*") :
					pass
				elif d_unit[1:].startswith("*") :
					prefix = d_unit[0]
					for unit in d_units :
						if unit.startswith(prefix) :
							break
						found = False
						if contains_unit.has_key(unit) :
							for _unit in contains_unit[unit] :
								if _unit.startswith(prefix) :
									found = True
									break
							if found : break
					else :
						raise Exception("%s is not in %s for identity %s" % (d_unit, d_units, identity))
				else :
					for _d_unit in d_unit.split("-") :
						if _d_unit not in d_units and not contains(d_units, _d_unit):
							raise Exception("%s is not in %s for identity %s" % (_d_unit, d_units, identity))
			elif m.group(9) is not None :
				d_unit, n_unit = m.group(9).split("_per_")
				if n_unit.find("/") != -1 :
					parts = n_unit.split("/")
					n_unit = parts[0]
					d_unit = d_unit + "-" + parts[1]
				if d_unit.find("/") != -1 :
					parts = d_unit.split("/")
					d_unit = parts[0]
					n_unit = n_unit + "-" + parts[1]
				if n_unit.startswith("*") :
					pass
				elif n_unit[1:].startswith("*") :
					prefix = n_unit[0]
					for unit in n_units :
						if unit.startswith(prefix) :
							break
						found = False
						if contains_unit.has_key(unit) :
							for _unit in contains_unit[unit] :
								if _unit.startswith(prefix) :
									found = True
									break
							if found : break
					else :
						raise Exception("%s is not in %s for identity %s" % (n_unit, n_units, identity))
				else :
					for _n_unit in n_unit.split("-") :
						if _n_unit not in n_units and not contains(n_units, _n_unit):
							raise Exception("%s is not in %s for identity %s" % (_n_unit, n_units, identity))
				if d_unit.startswith("*") :
					pass
				elif d_unit[1:].startswith("*") :
					prefix = d_unit[0]
					for unit in d_units :
						if unit.startswith(prefix) :
							break
						found = False
						if contains_unit.has_key(unit) :
							for _unit in contains_unit[unit] :
								if _unit.startswith(prefix) :
									found = True
									break
							if found : break
				else :
					for _d_unit in d_unit.split("-") :
						if _d_unit not in d_units and not contains(d_units, _d_unit):
							raise Exception("%s is not in %s for identity %s" % (_d_unit, d_units, identity))
		#------------------#
		# reduce the units #
		#------------------#
		while True :
			reduced = False
			for unit in n_units :
				if unit in d_units :
					n_units.remove(unit)
					d_units.remove(unit)
					reduced = True
					break
			if not reduced : break
		failed = False
		if len(n_units) == 1 :
			n_units = n_units[0]
		elif n_units == len(n_units) * [n_units[0]] :
			n_units = '%s%d' % (n_units[0], len(n_units))
		else :
			failed = True
		if len(d_units) == 0 :
			d_units = None
		elif len(d_units) == 1 :
			d_units = d_units[0]
		elif d_units == len(d_units) * [d_units[0]] :
			d_units = '%s%d' % (d_units[0], len(d_units))
		else :
			failed = True
		if failed :
			raise Exception('Unexpected units: %s / %s' % (n_units, d_units))
		if d_units :
			unit = '%s/%s' % (n_units, d_units)
		else :
			unit = n_units
		func_body = None
	return factor, func_body, unit

conversions = {}
for from_unit, to_unit, definition in conversion_definitions :
	try :
		factor, func_body, unit = process_conversion_definition(from_unit, definition)
	except :
		raise Exception('Error processing %s -> %s conversion.\n%s' % (from_unit, to_unit, traceback.format_exc()))
	if unit != to_unit and unit != to_unit.replace("1/", "/") :
		raise Exception('Expected unit %s, got %s converting from %s' % (to_unit, unit, from_unit))
	conversion_to = conversions.setdefault(from_unit, {})
	if factor is None :
		offset = None
	else :
		try    : offset = offsets['%s_to_%s' % (from_unit, to_unit)]
		except : offset = Decimal('0')
	conversion_to[to_unit] = {"factor" : factor, "offset" : offset, "function" : func_body}

def convert(value, from_unit, to_unit) :
	try :
		factor   = conversions[from_unit][to_unit]["factor"]
		offset   = conversions[from_unit][to_unit]["offset"]
		function = conversions[from_unit][to_unit]["function"]
	except :
		raise Exception("No conversion defined from '%s' to '%s'" % (from_unit, to_unit))
	if function :
		result = Computation(function).compute(value)
	else :
		result = float(Decimal(value) * factor + offset)
	return result

def get_java_resource_format() :
	buf = StringIO.StringIO()
	date_str = datetime.datetime.now().strftime('%Y-%m-%d %H:%M')
	p4_header = "$Header$"
	p4_header = p4_header.replace("$","")
	p4_header = p4_header.replace("Header","")
	buf.write("// Generated from" + p4_header + " on " + date_str + "\n" )
	buf.write("// UNIT DEFINITIONS\n")
	buf.write("//  UnitSystem;UnitName;UnitAliases...;...;\n")
	for d in [d for d in units_by_param] :
		param = d.keys()[0]
		buf2 = StringIO.StringIO()
		buf.write("\n//%s\n" % param)
		units = d.values()[0]
		for unit_system_units in units_by_unit_system :
			unit_system = unit_system_units.keys()[0];
			for unit in [u for u in sorted(units) if u in unit_system_units.values()[0]] :
				java_unit, java_aliases = unit, None
				if unit_aliases.has_key(unit) :
					aliases = unit_aliases[unit][:]
					intersection = java_primary_units & set(aliases)
					if intersection :
						assert(len(intersection) == 1)
						java_unit = intersection.pop()
						aliases[aliases.index(java_unit)] = unit
					java_aliases = aliases
				buf.write("%s;%s" % (unit_system, java_unit))
				if unit_aliases.has_key(unit) :
					buf.write(";%s" % ";".join(sorted(java_aliases)))
				buf.write("\n")
				#write out conversion for same unit to different unit system
				for check_units in units_by_unit_system :
					check_unit_system = check_units.keys()[0];
					#is this the unit system that we are looking at right now
					if (check_unit_system == unit_system) :
						#dont do conversions to our selves in the same unit system
						continue
					#check if our unit is in this other unit system
					if (unit in check_units.values()[0]) :
						#it is - so write out the same unit btwn systems conversion
						buf2.write("%s;%s>%s;%s;1.0\n" % (unit_system, java_unit, check_unit_system, java_unit))
				#write out all conversions to other units
				if conversions.has_key(unit) :
					for to_unit_system_units in units_by_unit_system :
						for to_unit in sorted(conversions[unit].keys()) :
							if not to_unit in to_unit_system_units.values()[0] : continue
							to_unit_system = to_unit_system_units.keys()[0]
							conversion = conversions[unit][to_unit]
							factor, offset, function = conversion["factor"], conversion["offset"], conversion["function"]
							if unit_aliases.has_key(to_unit) :
								aliases = unit_aliases[to_unit][:]
								intersection = java_primary_units & set(aliases)
								if intersection :
									assert(len(intersection) == 1)
									to_unit = intersection.pop()
							buf2.write("%s;%s>%s;%s;" % (unit_system, java_unit, to_unit_system, to_unit))
							if function :
								buf2.write("%s\n" % function)
							elif offset :
								if offset < 0 :
										if factor  == 1.0 :
											buf2.write("ARG 0|%s|-\n" % (-offset))
										else :
											buf2.write("ARG 0|%s|*|%s|-\n" % (factor, -offset))
								else :
										if factor == 1.0 :
											buf2.write("ARG 0|%s|+\n" % (offset))
										else :
											buf2.write("ARG 0|%s|*|%s|+\n" % (factor, offset))
							else :
								buf2.write("%s\n" % factor)
		conversion_text = buf2.getvalue()
		buf2.close()
		if conversion_text :
			buf.write("\n//%s Conversions\n%s" % (param, conversion_text))
	text = buf.getvalue()
	buf.close
	return text

if __name__ == "__main__" :
# 	for from_unit in sorted(conversions.keys()) :
# 		for to_unit in sorted(conversions[from_unit].keys()) :
# 			factor   = conversions[from_unit][to_unit]["factor"]
# 			offset   = conversions[from_unit][to_unit]["offset"]
# 			function = conversions[from_unit][to_unit]["function"]
# 			if function :
# 				print("1 %s = %s (%s) %s " % (from_unit, function, convert(1, from_unit, to_unit), to_unit))
# 			else :
# 				if int(offset) :
# 					print("1 %s = %s + %s (%s) %s" % (from_unit, factor, offset, convert(1, from_unit, to_unit), to_unit))
# 				else :
# 					print("1 %s = %s (%s) %s " % (from_unit, factor, convert(1, from_unit, to_unit), to_unit))

	print get_java_resource_format()
