#!/bin/env python
# -*- coding: utf-8 -*-
import sys, os

def uniqueCombinationsGenerator(items, n):
    '''
    Generator which yields the combinations of a list of items taken n at a time
    '''
    if n==0: 
        yield []
    else:
        for i in xrange(len(items)):
            for comb in uniqueCombinationsGenerator(items[i+1:],n-1):
                yield [items[i]] + comb

def uniqueCombinations(items):
    '''
    Function returning all possible combinations of a list of items
    '''    
    count = len(items)
    results = []
    for i in xrange(count) :
        for comb in uniqueCombinationsGenerator(items, i+1) :
            results.append(comb)
    return results
                
testAccount  = None
db_office_id = None
office_ids   = []
tempFilename = os.tmpnam()


#-------------------------#
# Handle the command line #
#-------------------------#
try :
    user = sys.argv[1].upper()
except :
    sys.stderr.write("Usage: python buildSqlScripts.py <schema name>\n")
    sys.stderr.write("Ex:    python buildSqlScripts.py cwms\n")
    sys.exit(-1)


args = sys.argv[2:]
for arg in args :
    arg = arg.upper()
    if arg in ('/TESTACCOUNT', '-TESTACCOUNT') :
        testAccount = True
    elif arg in ('/NOTESTACCOUNT', '-NOTESTACCOUNT') :
        testAccount = False
    elif db_office_id == None :
        db_office_id = arg
    else :
        office_ids.append(arg)

#-----------------------------------------------------------------------------#
# Prefixes are pre-pended to every line of the first-round output to identify #
# which script should actually contain the commands. After the first-round    #
# output is complete, it is read back in and split into individual scripts.   #
#-----------------------------------------------------------------------------#
prefix = ["BUILDCWMS~", "BUILDUSER~", "BUILDCWMS,BUILDUSER~", "BUILDCWMS,BUILDUSER,DROPCWMS,DROPUSER~"]
CWMS, USER, BUILD, ALL = 0, 1, 2, 3

sqlFileName              = {}
sqlFileName["BUILDCWMS"] = "py_BuildCwms.sql"
#sqlFileName["BUILDUSER"] = "buildCwmsPd.sql"
sqlFileName["DROPCWMS"]  = "dropCwms.sql"
#sqlFileName["DROPUSER"]  = "dropCwmsPd.sql"

logFileName              = {}
logFileName["BUILDCWMS"] = "buildCwms.lst"
#logFileName["BUILDUSER"] = "buildCwmsPd.lst"
logFileName["DROPCWMS"]  = "dropCwms.lst"
#logFileName["DROPUSER"]  = "dropCwmsPd.lst"

cwmsTableSpaceName = "CWMS_20DATA"
#userTableSpaceName = "%sCWMSDATA" % user
#tsTableSpaceName = "%sCWMSTS" % user
#userSchema = "%sCWMSPD" % user

cwmsSequences = [
#    NAME             START  INCREMENT  MINIMUM  MAXIMUM  CYCLE  CACHE
    #["CWMS_LOG_MSG_SEQ",  0,        1,         0,          999,   True, 20],
]

#------------------------------------------------------------------------------#
# Table information.  Each table must have an entry in the tableInfo list, and #
# must also have an associated template.  It may also have code below to       #
# populate the table, if appropriate.                                          #
#------------------------------------------------------------------------------#
tableInfo = [
    {"ID" : "states",             "TABLE" : "CWMS_STATE",                 "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "counties",           "TABLE" : "CWMS_COUNTY",                "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "cwmsOffice",         "TABLE" : "CWMS_OFFICE",                "SCHEMA" : "CWMS", "USERACCESS" : True},
#   {"ID" : "subLocation",        "TABLE" : "CWMS_SUBCWMS",               "SCHEMA" : "CWMS", "USERACCESS" : False},
    {"ID" : "intervalOffset",     "TABLE" : "CWMS_INTERVAL_OFFSET",       "SCHEMA" : "CWMS", "USERACCESS" : False},
#   {"ID" : "validValues",        "TABLE" : "CWMS_VALID_VALUES",          "SCHEMA" : "CWMS", "USERACCESS" : False},
#   {"ID" : "errorMessage",       "TABLE" : "CWMS_ERROR_MSG",             "SCHEMA" : "CWMS", "USERACCESS" : False},
    {"ID" : "errorMessageNew",    "TABLE" : "CWMS_ERROR",                 "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "timezone",           "TABLE" : "CWMS_TIME_ZONE",             "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "timezoneAlias",      "TABLE" : "CWMS_TIME_ZONE_ALIAS",       "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "tzUsage",            "TABLE" : "CWMS_TZ_USAGE",              "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "interval",           "TABLE" : "CWMS_INTERVAL",              "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "duration",           "TABLE" : "CWMS_DURATION",              "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "shefDuration",       "TABLE" : "CWMS_SHEF_DURATION",         "SCHEMA" : "CWMS", "USERACCESS" : True},
#   {"ID" : "catalog",            "TABLE" : "CWMS_META_CATALOG",          "SCHEMA" : "CWMS", "USERACCESS" : False},
    {"ID" : "abstractParam",      "TABLE" : "CWMS_ABSTRACT_PARAMETER",    "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "unit",               "TABLE" : "CWMS_UNIT",                  "SCHEMA" : "CWMS", "USERACCESS" : True},
#   {"ID" : "cwmsUnit",           "TABLE" : "CWMS_DB_UNIT",               "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "conversion",         "TABLE" : "CWMS_UNIT_CONVERSION",       "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "parameterType",      "TABLE" : "CWMS_PARAMETER_TYPE",        "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "parameter",          "TABLE" : "CWMS_BASE_PARAMETER",        "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "subParameter",       "TABLE" : "AT_PARAMETER",               "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "displayUnits",       "TABLE" : "AT_DISLAY_UNITS",            "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "qScreened",          "TABLE" : "CWMS_DATA_Q_SCREENED",       "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "qValidity",          "TABLE" : "CWMS_DATA_Q_VALIDITY",       "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "qRange",             "TABLE" : "CWMS_DATA_Q_RANGE",          "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "qChanged",           "TABLE" : "CWMS_DATA_Q_CHANGED",        "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "qReplCause",         "TABLE" : "CWMS_DATA_Q_REPL_CAUSE",     "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "qReplMethod",        "TABLE" : "CWMS_DATA_Q_REPL_METHOD",    "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "qTestFailed",        "TABLE" : "CWMS_DATA_Q_TEST_FAILED",    "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "qProtection",        "TABLE" : "CWMS_DATA_Q_PROTECTION",     "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "quality",            "TABLE" : "CWMS_DATA_QUALITY",          "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "ratingMethod",       "TABLE" : "CWMS_RATING_METHOD",         "SCHEMA" : "CWMS", "USERACCESS" : True}, 
    {"ID" : "dssParameterType",   "TABLE" : "CWMS_DSS_PARAMETER_TYPE",    "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "dssXchgDirection",   "TABLE" : "CWMS_DSS_XCHG_DIRECTION",    "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "logMessageTypes",    "TABLE" : "CWMS_LOG_MESSAGE_TYPES",     "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "logMessagePropTypes","TABLE" : "CWMS_LOG_MESSAGE_PROP_TYPES","SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "interpolateUnits"   ,"TABLE" : "CWMS_INTERPOLATE_UNITS",     "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "locationKind",       "TABLE" : "AT_LOCATION_KIND",           "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "gageMethod",         "TABLE" : "CWMS_GAGE_METHOD",           "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "gageType",           "TABLE" : "CWMS_GAGE_TYPE",             "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "nation",             "TABLE" : "CWMS_NATION",                "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "streamType",         "TABLE" : "CWMS_STREAM_TYPE",           "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "msgId",              "TABLE" : "CWMS_MSG_ID",                "SCHEMA" : "CWMS", "USERACCESS" : True},
    {"ID" : "schemaObjVersion",   "TABLE" : "CWMS_SCHEMA_OBJECT_VERSION", "SCHEMA" : "CWMS", "USERACCESS" : True},
]

tables = []
schema = {}
userAccess = {}
for item in tableInfo :
    id = item["ID"]
    tables.append(id)
    exec("%sTableName = %s" % (id, `item["TABLE"]`))
    schemaName = item["SCHEMA"]
    schema[id] = schemaName
    if schemaName == "CWMS" : userAccess[id] = item["USERACCESS"]



#---------------#
# SHEF_Duration #
#---------------#
sys.stderr.write("Processing shef_durations.\n")
shef_duration = [
#    SHEF                                                                                                                      SHEF    CWMS 
#    CODE  Description                                                                                                         Numeric CODE
#    ----  ------------------------------------------------------------------------------------------------------------------- ------ -----
    ['I', 'Instantaneous',                                                                                                     '0',    29],
    ['U', '1 Minute',                                                                                                          '1',     1],
    ['C', '15 Minutes',                                                                                                        '15',    9],
    ['J', '30 Minutes',                                                                                                        '30',   11],
    ['H', '1 Hour',                                                                                                            '1001', 12],
    ['B', '2 Hour',                                                                                                            '1002', 13],
    ['T', '3 Hour',                                                                                                            '1003', 14],
    ['F', '4 Hour',                                                                                                            '1004', 15],
    ['Q', '6 Hour',                                                                                                            '1006', 16],
    ['A', '8 Hour',                                                                                                            '1008', 17],
    ['K', '12 Hour',                                                                                                           '1012', 18],
    ['L', '18 Hour',                                                                                                           '1018', 'NULL'],
    ['D', '1 Day',                                                                                                             '2001', 19],
    ['W', '1 Week',                                                                                                            '2007', 25],
    ['N', 'Mid month, duration for the period from the 1st day of the month to and ending on the 15th day of the same month',  'NULL', 'NULL'],
    ['M', '1 Month',                                                                                                           '3001', 26],
    ['Y', '1 Year',                                                                                                            '4001', 27],
    ['P', 'Duration for a period beginning at previous 7 a.m. local and ending at time of observation',                        '5004', 19],
    ['V', 'Variable period, duration defined separately (see Tables 11a and 11b) 1/',                                          'NULL', 'NULL'],
    ['S', 'Period of seasonal duration (normally used to designate a partial period, for example, 1 January to current date)', '5001', 'NULL'],
    ['R', 'Entire period of record',                                                                                           '5002', 'NULL'],
    ['X', 'Unknown duration',                                                                                                  '5005', 'NULL'],
    ['Z', 'Filler character, pointer to default duration for that physical element as shown in Table 7.',                      'NULL', 'NULL'],
]

#--------#
# States #
#--------#
sys.stderr.write("Processing states.\n")
states = [
#    ID    Initial  Name
#    ----  -------  ----------------------------
    ['00', '00',    'Unknown State or State N/A'],
    ['01', 'AL',    'Alabama'                   ],
    ['02', 'AK',    'Alaska'                    ],
    ['04', 'AZ',    'Arizona'                   ],
    ['05', 'AR',    'Arkansas'                  ],
    ['06', 'CA',    'California'                ],
    ['08', 'CO',    'Colorado'                  ],
    ['09', 'CT',    'Connecticut'               ],
    ['10', 'DE',    'Delaware'                  ],
    ['11', 'DC',    'District of Columbia'      ],
    ['12', 'FL',    'Florida'                   ],
    ['13', 'GA',    'Georgia'                   ],
    ['15', 'HI',    'Hawaii'                    ],
    ['16', 'ID',    'Idaho'                     ],
    ['17', 'IL',    'Illinois'                  ],
    ['18', 'IN',    'Indiana'                   ],
    ['19', 'IA',    'Iowa'                      ],
    ['20', 'KS',    'Kansas'                    ],
    ['21', 'KY',    'Kentucky'                  ],
    ['22', 'LA',    'Louisiana'                 ],
    ['23', 'ME',    'Maine'                     ],
    ['24', 'MD',    'Maryland'                  ],
    ['25', 'MA',    'Massachusetts'             ],
    ['26', 'MI',    'Michigan'                  ],
    ['27', 'MN',    'Minnesota'                 ],
    ['28', 'MS',    'Mississippi'               ],
    ['29', 'MO',    'Missouri'                  ],
    ['30', 'MT',    'Montana'                   ],
    ['31', 'NE',    'Nebraska'                  ],
    ['32', 'NV',    'Nevada'                    ],
    ['34', 'NJ',    'New Jersey'                ],
    ['33', 'NH',    'New Hampshire'             ],
    ['36', 'NY',    'New York'                  ],
    ['35', 'NM',    'New Mexico'                ],
    ['38', 'ND',    'North Dakota'              ],
    ['37', 'NC',    'North Carolina'            ],
    ['39', 'OH',    'Ohio'                      ],
    ['40', 'OK',    'Oklahoma'                  ],
    ['41', 'OR',    'Oregon'                    ],
    ['42', 'PA',    'Pennsylvania'              ],
    ['44', 'RI',    'Rhode Island'              ],
    ['46', 'SD',    'South Dakota'              ],
    ['45', 'SC',    'South Carolina'            ],
    ['47', 'TN',    'Tennessee'                 ],
    ['48', 'TX',    'Texas'                     ],
    ['49', 'UT',    'Utah'                      ],
    ['50', 'VT',    'Vermont'                   ],
    ['51', 'VA',    'Virginia'                  ],
    ['53', 'WA',    'Washington'                ],
    ['54', 'WV',    'West Virginia'             ],
    ['55', 'WI',    'Wisconsin'                 ],
    ['56', 'WY',    'Wyoming'                   ],
    ['80', 'AB',    'Alberta'                   ],
    ['81', 'BC',    'British Columbia'          ],
    ['82', 'MB',    'Manitoba'                  ],
    ['83', 'NB',    'New Brunswick'             ],
    ['84', 'NF',    'Newfoundland'              ],
    ['85', 'NS',    'Nova Scotia'               ],
    ['86', 'NT',    'Northwest Territories'     ],
    ['87', 'NU',    'Nunavut'                   ],
    ['88', 'ON',    'Ontario'                   ],
    ['89', 'PE',    'Prince Edward Island'      ],
    ['90', 'QC',    'Quebec'                    ],
    ['91', 'SK',    'Saskatchewan'              ],
    ['92', 'YT',    'Yukon'                     ],
]
stateNamesById = {}
for id, initial, name in states : stateNamesById[id] = name;

#----------#
# Counties #
#----------#
sys.stderr.write("Processing counties.\n")
counties = [
    [    0, 'Unknown County or County N/A'],
    [ 1000, 'Unknown County or County N/A'],
    [ 1001, 'Autauga'],
    [ 1003, 'Baldwin'],
    [ 1005, 'Barbour'],
    [ 1007, 'Bibb'],
    [ 1009, 'Blount'],
    [ 1011, 'Bullock'],
    [ 1013, 'Butler'],
    [ 1015, 'Calhoun'],
    [ 1017, 'Chambers'],
    [ 1019, 'Cherokee'],
    [ 1021, 'Chilton'],
    [ 1023, 'Choctaw'],
    [ 1025, 'Clarke'],
    [ 1027, 'Clay'],
    [ 1029, 'Cleburne'],
    [ 1031, 'Coffee'],
    [ 1033, 'Colbert'],
    [ 1035, 'Conecuh'],
    [ 1037, 'Coosa'],
    [ 1039, 'Covington'],
    [ 1041, 'Crenshaw'],
    [ 1043, 'Cullman'],
    [ 1045, 'Dale'],
    [ 1047, 'Dallas'],
    [ 1049, 'De Kalb'],
    [ 1051, 'Elmore'],
    [ 1053, 'Escambia'],
    [ 1055, 'Etowah'],
    [ 1057, 'Fayette'],
    [ 1059, 'Franklin'],
    [ 1061, 'Geneva'],
    [ 1063, 'Greene'],
    [ 1065, 'Hale'],
    [ 1067, 'Henry'],
    [ 1069, 'Houston'],
    [ 1071, 'Jackson'],
    [ 1073, 'Jefferson'],
    [ 1075, 'Lamar'],
    [ 1077, 'Lauderdale'],
    [ 1079, 'Lawrence'],
    [ 1081, 'Lee'],
    [ 1083, 'Limestone'],
    [ 1085, 'Lowndes'],
    [ 1087, 'Macon'],
    [ 1089, 'Madison'],
    [ 1091, 'Marengo'],
    [ 1093, 'Marion'],
    [ 1095, 'Marshall'],
    [ 1097, 'Mobile'],
    [ 1099, 'Monroe'],
    [ 1101, 'Montgomery'],
    [ 1103, 'Morgan'],
    [ 1105, 'Perry'],
    [ 1107, 'Pickens'],
    [ 1109, 'Pike'],
    [ 1111, 'Randolph'],
    [ 1113, 'Russell'],
    [ 1115, 'St. Clair'],
    [ 1117, 'Shelby'],
    [ 1119, 'Sumter'],
    [ 1121, 'Talladega'],
    [ 1123, 'Tallapoosa'],
    [ 1125, 'Tuscaloosa'],
    [ 1127, 'Walker'],
    [ 1129, 'Washington'],
    [ 1131, 'Wilcox'],
    [ 1133, 'Winston'],
    [ 2000, 'Unknown County or County N/A'],
    [ 2013, 'Aleutians East'],
    [ 2016, 'Aleutians West'],
    [ 2020, 'Anchorage'],
    [ 2050, 'Bethel'],
    [ 2060, 'Bristol Bay'],
    [ 2070, 'Dillingham'],
    [ 2090, 'Fairbanks North Star'],
    [ 2100, 'Haines'],
    [ 2110, 'Juneau'],
    [ 2122, 'Kenai Peninsula'],
    [ 2130, 'Ketchikan Gateway'],
    [ 2150, 'Kodiak Island'],
    [ 2164, 'Lake and Peninsula'],
    [ 2170, 'Matanuska-Susitna'],
    [ 2180, 'Nome'],
    [ 2185, 'North Slope'],
    [ 2188, 'Northwest Arctic'],
    [ 2220, 'Sitka'],
    [ 2231, 'Skagway-Yakutat-Angoon'],
    [ 2240, 'Southeast Fairbanks'],
    [ 2261, 'Valdez-Cordova'],
    [ 2270, 'Wade Hampton'],
    [ 2280, 'Wrangell-Petersburg'],
    [ 2290, 'Yukon-Koyukuk'],
    [ 4000, 'Unknown County or County N/A'],
    [ 4001, 'Apache'],
    [ 4003, 'Cochise'],
    [ 4005, 'Coconino'],
    [ 4007, 'Gila'],
    [ 4009, 'Graham'],
    [ 4011, 'Greenlee'],
    [ 4012, 'La Paz'],
    [ 4013, 'Maricopa'],
    [ 4015, 'Mohave'],
    [ 4017, 'Navajo'],
    [ 4019, 'Pima'],
    [ 4021, 'Pinal'],
    [ 4023, 'Santa Cruz'],
    [ 4025, 'Yavapai'],
    [ 4027, 'Yuma'],
    [ 5000, 'Unknown County or County N/A'],
    [ 5001, 'Arkansas'],
    [ 5003, 'Ashley'],
    [ 5005, 'Baxter'],
    [ 5007, 'Benton'],
    [ 5009, 'Boone'],
    [ 5011, 'Bradley'],
    [ 5013, 'Calhoun'],
    [ 5015, 'Carroll'],
    [ 5017, 'Chicot'],
    [ 5019, 'Clark'],
    [ 5021, 'Clay'],
    [ 5023, 'Cleburne'],
    [ 5025, 'Cleveland'],
    [ 5027, 'Columbia'],
    [ 5029, 'Conway'],
    [ 5031, 'Craighead'],
    [ 5033, 'Crawford'],
    [ 5035, 'Crittenden'],
    [ 5037, 'Cross'],
    [ 5039, 'Dallas'],
    [ 5041, 'Desha'],
    [ 5043, 'Drew'],
    [ 5045, 'Faulkner'],
    [ 5047, 'Franklin'],
    [ 5049, 'Fulton'],
    [ 5051, 'Garland'],
    [ 5053, 'Grant'],
    [ 5055, 'Greene'],
    [ 5057, 'Hempstead'],
    [ 5059, 'Hot Spring'],
    [ 5061, 'Howard'],
    [ 5063, 'Independence'],
    [ 5065, 'Izard'],
    [ 5067, 'Jackson'],
    [ 5069, 'Jefferson'],
    [ 5071, 'Johnson'],
    [ 5073, 'Lafayette'],
    [ 5075, 'Lawrence'],
    [ 5077, 'Lee'],
    [ 5079, 'Lincoln'],
    [ 5081, 'Little River'],
    [ 5083, 'Logan'],
    [ 5085, 'Lonoke'],
    [ 5087, 'Madison'],
    [ 5089, 'Marion'],
    [ 5091, 'Miller'],
    [ 5093, 'Mississippi'],
    [ 5095, 'Monroe'],
    [ 5097, 'Montgomery'],
    [ 5099, 'Nevada'],
    [ 5101, 'Newton'],
    [ 5103, 'Ouachita'],
    [ 5105, 'Perry'],
    [ 5107, 'Phillips'],
    [ 5109, 'Pike'],
    [ 5111, 'Poinsett'],
    [ 5113, 'Polk'],
    [ 5115, 'Pope'],
    [ 5117, 'Prairie'],
    [ 5119, 'Pulaski'],
    [ 5121, 'Randolph'],
    [ 5123, 'St. Francis'],
    [ 5125, 'Saline'],
    [ 5127, 'Scott'],
    [ 5129, 'Searcy'],
    [ 5131, 'Sebastian'],
    [ 5133, 'Sevier'],
    [ 5135, 'Sharp'],
    [ 5137, 'Stone'],
    [ 5139, 'Union'],
    [ 5141, 'Van Buren'],
    [ 5143, 'Washington'],
    [ 5145, 'White'],
    [ 5147, 'Woodruff'],
    [ 5149, 'Yell'],
    [ 6000, 'Unknown County or County N/A'],
    [ 6001, 'Alameda'],
    [ 6003, 'Alpine'],
    [ 6005, 'Amador'],
    [ 6007, 'Butte'],
    [ 6009, 'Calaveras'],
    [ 6011, 'Colusa'],
    [ 6013, 'Contra Costa'],
    [ 6015, 'Del Norte'],
    [ 6017, 'El Dorado'],
    [ 6019, 'Fresno'],
    [ 6021, 'Glenn'],
    [ 6023, 'Humboldt'],
    [ 6025, 'Imperial'],
    [ 6027, 'Inyo'],
    [ 6029, 'Kern'],
    [ 6031, 'Kings'],
    [ 6033, 'Lake'],
    [ 6035, 'Lassen'],
    [ 6037, 'Los Angeles'],
    [ 6039, 'Madera'],
    [ 6041, 'Marin'],
    [ 6043, 'Mariposa'],
    [ 6045, 'Mendocino'],
    [ 6047, 'Merced'],
    [ 6049, 'Modoc'],
    [ 6051, 'Mono'],
    [ 6053, 'Monterey'],
    [ 6055, 'Napa'],
    [ 6057, 'Nevada'],
    [ 6059, 'Orange'],
    [ 6061, 'Placer'],
    [ 6063, 'Plumas'],
    [ 6065, 'Riverside'],
    [ 6067, 'Sacramento'],
    [ 6069, 'San Benito'],
    [ 6071, 'San Bernardino'],
    [ 6073, 'San Diego'],
    [ 6075, 'San Francisco'],
    [ 6077, 'San Joaquin'],
    [ 6079, 'San Luis Obispo'],
    [ 6081, 'San Mateo'],
    [ 6083, 'Santa Barbara'],
    [ 6085, 'Santa Clara'],
    [ 6087, 'Santa Cruz'],
    [ 6089, 'Shasta'],
    [ 6091, 'Sierra'],
    [ 6093, 'Siskiyou'],
    [ 6095, 'Solano'],
    [ 6097, 'Sonoma'],
    [ 6099, 'Stanislaus'],
    [ 6101, 'Sutter'],
    [ 6103, 'Tehama'],
    [ 6105, 'Trinity'],
    [ 6107, 'Tulare'],
    [ 6109, 'Tuolumne'],
    [ 6111, 'Ventura'],
    [ 6113, 'Yolo'],
    [ 6115, 'Yuba'],
    [ 8000, 'Unknown County or County N/A'],
    [ 8001, 'Adams'],
    [ 8003, 'Alamosa'],
    [ 8005, 'Arapahoe'],
    [ 8007, 'Archuleta'],
    [ 8009, 'Baca'],
    [ 8011, 'Bent'],
    [ 8013, 'Boulder'],
    [ 8015, 'Chaffee'],
    [ 8017, 'Cheyenne'],
    [ 8019, 'Clear Creek'],
    [ 8021, 'Conejos'],
    [ 8023, 'Costilla'],
    [ 8025, 'Crowley'],
    [ 8027, 'Custer'],
    [ 8029, 'Delta'],
    [ 8031, 'Denver'],
    [ 8033, 'Dolores'],
    [ 8035, 'Douglas'],
    [ 8037, 'Eagle'],
    [ 8039, 'Elbert'],
    [ 8041, 'El Paso'],
    [ 8043, 'Fremont'],
    [ 8045, 'Garfield'],
    [ 8047, 'Gilpin'],
    [ 8049, 'Grand'],
    [ 8051, 'Gunnison'],
    [ 8053, 'Hinsdale'],
    [ 8055, 'Huerfano'],
    [ 8057, 'Jackson'],
    [ 8059, 'Jefferson'],
    [ 8061, 'Kiowa'],
    [ 8063, 'Kit Carson'],
    [ 8065, 'Lake'],
    [ 8067, 'La Plata'],
    [ 8069, 'Larimer'],
    [ 8071, 'Las Animas'],
    [ 8073, 'Lincoln'],
    [ 8075, 'Logan'],
    [ 8077, 'Mesa'],
    [ 8079, 'Mineral'],
    [ 8081, 'Moffat'],
    [ 8083, 'Montezuma'],
    [ 8085, 'Montrose'],
    [ 8087, 'Morgan'],
    [ 8089, 'Otero'],
    [ 8091, 'Ouray'],
    [ 8093, 'Park'],
    [ 8095, 'Phillips'],
    [ 8097, 'Pitkin'],
    [ 8099, 'Prowers'],
    [ 8101, 'Pueblo'],
    [ 8103, 'Rio Blanco'],
    [ 8105, 'Rio Grande'],
    [ 8107, 'Routt'],
    [ 8109, 'Saguache'],
    [ 8111, 'San Juan'],
    [ 8113, 'San Miguel'],
    [ 8115, 'Sedgwick'],
    [ 8117, 'Summit'],
    [ 8119, 'Teller'],
    [ 8121, 'Washington'],
    [ 8123, 'Weld'],
    [ 8125, 'Yuma'],
    [ 9000, 'Unknown County or County N/A'],
    [ 9001, 'Fairfield'],
    [ 9003, 'Hartford'],
    [ 9005, 'Litchfield'],
    [ 9007, 'Middlesex'],
    [ 9009, 'New Haven'],
    [ 9011, 'New London'],
    [ 9013, 'Tolland'],
    [ 9015, 'Windham'],
    [10000, 'Unknown County or County N/A'],
    [10001, 'Kent'],
    [10003, 'New Castle'],
    [10005, 'Sussex'],
    [11000, 'Unknown County or County N/A'],                                                                      
    [11001, 'Washington'],
    [12000, 'Unknown County or County N/A'],                                                                      
    [12001, 'Alachua'],
    [12003, 'Baker'],
    [12005, 'Bay'],
    [12007, 'Bradford'],
    [12009, 'Brevard'],
    [12011, 'Broward'],
    [12013, 'Calhoun'],
    [12015, 'Charlotte'],
    [12017, 'Citrus'],
    [12019, 'Clay'],
    [12021, 'Collier'],
    [12023, 'Columbia'],
    [12025, 'Dade'],
    [12027, 'De Soto'],
    [12029, 'Dixie'],
    [12031, 'Duval'],
    [12033, 'Escambia'],
    [12035, 'Flagler'],
    [12037, 'Franklin'],
    [12039, 'Gadsden'],
    [12041, 'Gilchrist'],
    [12043, 'Glades'],
    [12045, 'Gulf'],
    [12047, 'Hamilton'],
    [12049, 'Hardee'],
    [12051, 'Hendry'],
    [12053, 'Hernando'],
    [12055, 'Highlands'],
    [12057, 'Hillsborough'],
    [12059, 'Holmes'],
    [12061, 'Indian River'],
    [12063, 'Jackson'],
    [12065, 'Jefferson'],
    [12067, 'Lafayette'],
    [12069, 'Lake'],
    [12071, 'Lee'],
    [12073, 'Leon'],
    [12075, 'Levy'],
    [12077, 'Liberty'],
    [12079, 'Madison'],
    [12081, 'Manatee'],
    [12083, 'Marion'],
    [12085, 'Martin'],
    [12087, 'Monroe'],
    [12089, 'Nassau'],
    [12091, 'Okaloosa'],
    [12093, 'Okeechobee'],
    [12095, 'Orange'],
    [12097, 'Osceola'],
    [12099, 'Palm Beach'],
    [12101, 'Pasco'],
    [12103, 'Pinellas'],
    [12105, 'Polk'],
    [12107, 'Putnam'],
    [12109, 'St. Johns'],
    [12111, 'St. Lucie'],
    [12113, 'Santa Rosa'],
    [12115, 'Sarasota'],
    [12117, 'Seminole'],
    [12119, 'Sumter'],
    [12121, 'Suwannee'],
    [12123, 'Taylor'],
    [12125, 'Union'],
    [12127, 'Volusia'],
    [12129, 'Wakulla'],
    [12131, 'Walton'],
    [12133, 'Washington'],
    [13000, 'Unknown County or County N/A'],                                                                      
    [13001, 'Appling'],
    [13003, 'Atkinson'],
    [13005, 'Bacon'],
    [13007, 'Baker'],
    [13009, 'Baldwin'],
    [13011, 'Banks'],
    [13013, 'Barrow'],
    [13015, 'Bartow'],
    [13017, 'Ben Hill'],
    [13019, 'Berrien'],
    [13021, 'Bibb'],
    [13023, 'Bleckley'],
    [13025, 'Brantley'],
    [13027, 'Brooks'],
    [13029, 'Bryan'],
    [13031, 'Bulloch'],
    [13033, 'Burke'],
    [13035, 'Butts'],
    [13037, 'Calhoun'],
    [13039, 'Camden'],
    [13043, 'Candler'],
    [13045, 'Carroll'],
    [13047, 'Catoosa'],
    [13049, 'Charlton'],
    [13051, 'Chatham'],
    [13053, 'Chattahoochee'],
    [13055, 'Chattooga'],
    [13057, 'Cherokee'],
    [13059, 'Clarke'],
    [13061, 'Clay'],
    [13063, 'Clayton'],
    [13065, 'Clinch'],
    [13067, 'Cobb'],
    [13069, 'Coffee'],
    [13071, 'Colquitt'],
    [13073, 'Columbia'],
    [13075, 'Cook'],
    [13077, 'Coweta'],
    [13079, 'Crawford'],
    [13081, 'Crisp'],
    [13083, 'Dade'],
    [13085, 'Dawson'],
    [13087, 'Decatur'],
    [13089, 'De Kalb'],
    [13091, 'Dodge'],
    [13093, 'Dooly'],
    [13095, 'Dougherty'],
    [13097, 'Douglas'],
    [13099, 'Early'],
    [13101, 'Echols'],
    [13103, 'Effingham'],
    [13105, 'Elbert'],
    [13107, 'Emanuel'],
    [13109, 'Evans'],
    [13111, 'Fannin'],
    [13113, 'Fayette'],
    [13115, 'Floyd'],
    [13117, 'Forsyth'],
    [13119, 'Franklin'],
    [13121, 'Fulton'],
    [13123, 'Gilmer'],
    [13125, 'Glascock'],
    [13127, 'Glynn'],
    [13129, 'Gordon'],
    [13131, 'Grady'],
    [13133, 'Greene'],
    [13135, 'Gwinnett'],
    [13137, 'Habersham'],
    [13139, 'Hall'],
    [13141, 'Hancock'],
    [13143, 'Haralson'],
    [13145, 'Harris'],
    [13147, 'Hart'],
    [13149, 'Heard'],
    [13151, 'Henry'],
    [13153, 'Houston'],
    [13155, 'Irwin'],
    [13157, 'Jackson'],
    [13159, 'Jasper'],
    [13161, 'Jeff Davis'],
    [13163, 'Jefferson'],
    [13165, 'Jenkins'],
    [13167, 'Johnson'],
    [13169, 'Jones'],
    [13171, 'Lamar'],
    [13173, 'Lanier'],
    [13175, 'Laurens'],
    [13177, 'Lee'],
    [13179, 'Liberty'],
    [13181, 'Lincoln'],
    [13183, 'Long'],
    [13185, 'Lowndes'],
    [13187, 'Lumpkin'],
    [13189, 'McDuffie'],
    [13191, 'McIntosh'],
    [13193, 'Macon'],
    [13195, 'Madison'],
    [13197, 'Marion'],
    [13199, 'Meriwether'],
    [13201, 'Miller'],
    [13205, 'Mitchell'],
    [13207, 'Monroe'],
    [13209, 'Montgomery'],
    [13211, 'Morgan'],
    [13213, 'Murray'],
    [13215, 'Muscogee'],
    [13217, 'Newton'],
    [13219, 'Oconee'],
    [13221, 'Oglethorpe'],
    [13223, 'Paulding'],
    [13225, 'Peach'],
    [13227, 'Pickens'],
    [13229, 'Pierce'],
    [13231, 'Pike'],
    [13233, 'Polk'],
    [13235, 'Pulaski'],
    [13237, 'Putnam'],
    [13239, 'Quitman'],
    [13241, 'Rabun'],
    [13243, 'Randolph'],
    [13245, 'Richmond'],
    [13247, 'Rockdale'],
    [13249, 'Schley'],
    [13251, 'Screven'],
    [13253, 'Seminole'],
    [13255, 'Spalding'],
    [13257, 'Stephens'],
    [13259, 'Stewart'],
    [13261, 'Sumter'],
    [13263, 'Talbot'],
    [13265, 'Taliaferro'],
    [13267, 'Tattnall'],
    [13269, 'Taylor'],
    [13271, 'Telfair'],
    [13273, 'Terrell'],
    [13275, 'Thomas'],
    [13277, 'Tift'],
    [13279, 'Toombs'],
    [13281, 'Towns'],
    [13283, 'Treutlen'],
    [13285, 'Troup'],
    [13287, 'Turner'],
    [13289, 'Twiggs'],
    [13291, 'Union'],
    [13293, 'Upson'],
    [13295, 'Walker'],
    [13297, 'Walton'],
    [13299, 'Ware'],
    [13301, 'Warren'],
    [13303, 'Washington'],
    [13305, 'Wayne'],
    [13307, 'Webster'],
    [13309, 'Wheeler'],
    [13311, 'White'],
    [13313, 'Whitfield'],
    [13315, 'Wilcox'],
    [13317, 'Wilkes'],
    [13319, 'Wilkinson'],
    [13321, 'Worth'],
    [15000, 'Unknown County or County N/A'],                                                                      
    [15001, 'Hawaii'],
    [15003, 'Honolulu'],
    [15007, 'Kauai'],
    [15009, 'Maui'],
    [16000, 'Unknown County or County N/A'],                                                                      
    [16001, 'Ada'],
    [16003, 'Adams'],
    [16005, 'Bannock'],
    [16007, 'Bear Lake'],
    [16009, 'Benewah'],
    [16011, 'Bingham'],
    [16013, 'Blaine'],
    [16015, 'Boise'],
    [16017, 'Bonner'],
    [16019, 'Bonneville'],
    [16021, 'Boundary'],
    [16023, 'Butte'],
    [16025, 'Camas'],
    [16027, 'Canyon'],
    [16029, 'Caribou'],
    [16031, 'Cassia'],
    [16033, 'Clark'],
    [16035, 'Clearwater'],
    [16037, 'Custer'],
    [16039, 'Elmore'],
    [16041, 'Franklin'],
    [16043, 'Fremont'],
    [16045, 'Gem'],
    [16047, 'Gooding'],
    [16049, 'Idaho'],
    [16051, 'Jefferson'],
    [16053, 'Jerome'],
    [16055, 'Kootenai'],
    [16057, 'Latah'],
    [16059, 'Lemhi'],
    [16061, 'Lewis'],
    [16063, 'Lincoln'],
    [16065, 'Madison'],
    [16067, 'Minidoka'],
    [16069, 'Nez Perce'],
    [16071, 'Oneida'],
    [16073, 'Owyhee'],
    [16075, 'Payette'],
    [16077, 'Power'],
    [16079, 'Shoshone'],
    [16081, 'Teton'],
    [16083, 'Twin Falls'],
    [16085, 'Valley'],
    [16087, 'Washington'],
    [17000, 'Unknown County or County N/A'],                                                                      
    [17001, 'Adams'],
    [17003, 'Alexander'],
    [17005, 'Bond'],
    [17007, 'Boone'],
    [17009, 'Brown'],
    [17011, 'Bureau'],
    [17013, 'Calhoun'],
    [17015, 'Carroll'],
    [17017, 'Cass'],
    [17019, 'Champaign'],
    [17021, 'Christian'],
    [17023, 'Clark'],
    [17025, 'Clay'],
    [17027, 'Clinton'],
    [17029, 'Coles'],
    [17031, 'Cook'],
    [17033, 'Crawford'],
    [17035, 'Cumberland'],
    [17037, 'De Kalb'],
    [17039, 'De Witt'],
    [17041, 'Douglas'],
    [17043, 'Du Page'],
    [17045, 'Edgar'],
    [17047, 'Edwards'],
    [17049, 'Effingham'],
    [17051, 'Fayette'],
    [17053, 'Ford'],
    [17055, 'Franklin'],
    [17057, 'Fulton'],
    [17059, 'Gallatin'],
    [17061, 'Greene'],
    [17063, 'Grundy'],
    [17065, 'Hamilton'],
    [17067, 'Hancock'],
    [17069, 'Hardin'],
    [17071, 'Henderson'],
    [17073, 'Henry'],
    [17075, 'Iroquois'],
    [17077, 'Jackson'],
    [17079, 'Jasper'],
    [17081, 'Jefferson'],
    [17083, 'Jersey'],
    [17085, 'Jo Daviess'],
    [17087, 'Johnson'],
    [17089, 'Kane'],
    [17091, 'Kankakee'],
    [17093, 'Kendall'],
    [17095, 'Knox'],
    [17097, 'Lake'],
    [17099, 'La Salle'],
    [17101, 'Lawrence'],
    [17103, 'Lee'],
    [17105, 'Livingston'],
    [17107, 'Logan'],
    [17109, 'McDonough'],
    [17111, 'McHenry'],
    [17113, 'McLean'],
    [17115, 'Macon'],
    [17117, 'Macoupin'],
    [17119, 'Madison'],
    [17121, 'Marion'],
    [17123, 'Marshall'],
    [17125, 'Mason'],
    [17127, 'Massac'],
    [17129, 'Menard'],
    [17131, 'Mercer'],
    [17133, 'Monroe'],
    [17135, 'Montgomery'],
    [17137, 'Morgan'],
    [17139, 'Moultrie'],
    [17141, 'Ogle'],
    [17143, 'Peoria'],
    [17145, 'Perry'],
    [17147, 'Piatt'],
    [17149, 'Pike'],
    [17151, 'Pope'],
    [17153, 'Pulaski'],
    [17155, 'Putnam'],
    [17157, 'Randolph'],
    [17159, 'Richland'],
    [17161, 'Rock Island'],
    [17163, 'St. Clair'],
    [17165, 'Saline'],
    [17167, 'Sangamon'],
    [17169, 'Schuyler'],
    [17171, 'Scott'],
    [17173, 'Shelby'],
    [17175, 'Stark'],
    [17177, 'Stephenson'],
    [17179, 'Tazewell'],
    [17181, 'Union'],
    [17183, 'Vermilion'],
    [17185, 'Wabash'],
    [17187, 'Warren'],
    [17189, 'Washington'],
    [17191, 'Wayne'],
    [17193, 'White'],
    [17195, 'Whiteside'],
    [17197, 'Will'],
    [17199, 'Williamson'],
    [17201, 'Winnebago'],
    [17203, 'Woodford'],
    [18000, 'Unknown County or County N/A'],                                                                      
    [18001, 'Adams'],
    [18003, 'Allen'],
    [18005, 'Bartholomew'],
    [18007, 'Benton'],
    [18009, 'Blackford'],
    [18011, 'Boone'],
    [18013, 'Brown'],
    [18015, 'Carroll'],
    [18017, 'Cass'],
    [18019, 'Clark'],
    [18021, 'Clay'],
    [18023, 'Clinton'],
    [18025, 'Crawford'],
    [18027, 'Daviess'],
    [18029, 'Dearborn'],
    [18031, 'Decatur'],
    [18033, 'De Kalb'],
    [18035, 'Delaware'],
    [18037, 'Dubois'],
    [18039, 'Elkhart'],
    [18041, 'Fayette'],
    [18043, 'Floyd'],
    [18045, 'Fountain'],
    [18047, 'Franklin'],
    [18049, 'Fulton'],
    [18051, 'Gibson'],
    [18053, 'Grant'],
    [18055, 'Greene'],
    [18057, 'Hamilton'],
    [18059, 'Hancock'],
    [18061, 'Harrison'],
    [18063, 'Hendricks'],
    [18065, 'Henry'],
    [18067, 'Howard'],
    [18069, 'Huntington'],
    [18071, 'Jackson'],
    [18073, 'Jasper'],
    [18075, 'Jay'],
    [18077, 'Jefferson'],
    [18079, 'Jennings'],
    [18081, 'Johnson'],
    [18083, 'Knox'],
    [18085, 'Kosciusko'],
    [18087, 'Lagrange'],
    [18089, 'Lake'],
    [18091, 'La Porte'],
    [18093, 'Lawrence'],
    [18095, 'Madison'],
    [18097, 'Marion'],
    [18099, 'Marshall'],
    [18101, 'Martin'],
    [18103, 'Miami'],
    [18105, 'Monroe'],
    [18107, 'Montgomery'],
    [18109, 'Morgan'],
    [18111, 'Newton'],
    [18113, 'Noble'],
    [18115, 'Ohio'],
    [18117, 'Orange'],
    [18119, 'Owen'],
    [18121, 'Parke'],
    [18123, 'Perry'],
    [18125, 'Pike'],
    [18127, 'Porter'],
    [18129, 'Posey'],
    [18131, 'Pulaski'],
    [18133, 'Putnam'],
    [18135, 'Randolph'],
    [18137, 'Ripley'],
    [18139, 'Rush'],
    [18141, 'St. Joseph'],
    [18143, 'Scott'],
    [18145, 'Shelby'],
    [18147, 'Spencer'],
    [18149, 'Starke'],
    [18151, 'Steuben'],
    [18153, 'Sullivan'],
    [18155, 'Switzerland'],
    [18157, 'Tippecanoe'],
    [18159, 'Tipton'],
    [18161, 'Union'],
    [18163, 'Vanderburgh'],
    [18165, 'Vermillion'],
    [18167, 'Vigo'],
    [18169, 'Wabash'],
    [18171, 'Warren'],
    [18173, 'Warrick'],
    [18175, 'Washington'],
    [18177, 'Wayne'],
    [18179, 'Wells'],
    [18181, 'White'],
    [18183, 'Whitley'],
    [19000, 'Unknown County or County N/A'],                                                                      
    [19001, 'Adair'],
    [19003, 'Adams'],
    [19005, 'Allamakee'],
    [19007, 'Appanoose'],
    [19009, 'Audubon'],
    [19011, 'Benton'],
    [19013, 'Black Hawk'],
    [19015, 'Boone'],
    [19017, 'Bremer'],
    [19019, 'Buchanan'],
    [19021, 'Buena Vista'],
    [19023, 'Butler'],
    [19025, 'Calhoun'],
    [19027, 'Carroll'],
    [19029, 'Cass'],
    [19031, 'Cedar'],
    [19033, 'Cerro Gordo'],
    [19035, 'Cherokee'],
    [19037, 'Chickasaw'],
    [19039, 'Clarke'],
    [19041, 'Clay'],
    [19043, 'Clayton'],
    [19045, 'Clinton'],
    [19047, 'Crawford'],
    [19049, 'Dallas'],
    [19051, 'Davis'],
    [19053, 'Decatur'],
    [19055, 'Delaware'],
    [19057, 'Des Moines'],
    [19059, 'Dickinson'],
    [19061, 'Dubuque'],
    [19063, 'Emmet'],
    [19065, 'Fayette'],
    [19067, 'Floyd'],
    [19069, 'Franklin'],
    [19071, 'Fremont'],
    [19073, 'Greene'],
    [19075, 'Grundy'],
    [19077, 'Guthrie'],
    [19079, 'Hamilton'],
    [19081, 'Hancock'],
    [19083, 'Hardin'],
    [19085, 'Harrison'],
    [19087, 'Henry'],
    [19089, 'Howard'],
    [19091, 'Humboldt'],
    [19093, 'Ida'],
    [19095, 'Iowa'],
    [19097, 'Jackson'],
    [19099, 'Jasper'],
    [19101, 'Jefferson'],
    [19103, 'Johnson'],
    [19105, 'Jones'],
    [19107, 'Keokuk'],
    [19109, 'Kossuth'],
    [19111, 'Lee'],
    [19113, 'Linn'],
    [19115, 'Louisa'],
    [19117, 'Lucas'],
    [19119, 'Lyon'],
    [19121, 'Madison'],
    [19123, 'Mahaska'],
    [19125, 'Marion'],
    [19127, 'Marshall'],
    [19129, 'Mills'],
    [19131, 'Mitchell'],
    [19133, 'Monona'],
    [19135, 'Monroe'],
    [19137, 'Montgomery'],
    [19139, 'Muscatine'],
    [19141, 'O''Brien'],
    [19143, 'Osceola'],
    [19145, 'Page'],
    [19147, 'Palo Alto'],
    [19149, 'Plymouth'],
    [19151, 'Pocahontas'],
    [19153, 'Polk'],
    [19155, 'Pottawattamie'],
    [19157, 'Poweshiek'],
    [19159, 'Ringgold'],
    [19161, 'Sac'],
    [19163, 'Scott'],
    [19165, 'Shelby'],
    [19167, 'Sioux'],
    [19169, 'Story'],
    [19171, 'Tama'],
    [19173, 'Taylor'],
    [19175, 'Union'],
    [19177, 'Van Buren'],
    [19179, 'Wapello'],
    [19181, 'Warren'],
    [19183, 'Washington'],
    [19185, 'Wayne'],
    [19187, 'Webster'],
    [19189, 'Winnebago'],
    [19191, 'Winneshiek'],
    [19193, 'Woodbury'],
    [19195, 'Worth'],
    [19197, 'Wright'],
    [20000, 'Unknown County or County N/A'],                                                                      
    [20001, 'Allen'],
    [20003, 'Anderson'],
    [20005, 'Atchison'],
    [20007, 'Barber'],
    [20009, 'Barton'],
    [20011, 'Bourbon'],
    [20013, 'Brown'],
    [20015, 'Butler'],
    [20017, 'Chase'],
    [20019, 'Chautauqua'],
    [20021, 'Cherokee'],
    [20023, 'Cheyenne'],
    [20025, 'Clark'],
    [20027, 'Clay'],
    [20029, 'Cloud'],
    [20031, 'Coffey'],
    [20033, 'Comanche'],
    [20035, 'Cowley'],
    [20037, 'Crawford'],
    [20039, 'Decatur'],
    [20041, 'Dickinson'],
    [20043, 'Doniphan'],
    [20045, 'Douglas'],
    [20047, 'Edwards'],
    [20049, 'Elk'],
    [20051, 'Ellis'],
    [20053, 'Ellsworth'],
    [20055, 'Finney'],
    [20057, 'Ford'],
    [20059, 'Franklin'],
    [20061, 'Geary'],
    [20063, 'Gove'],
    [20065, 'Graham'],
    [20067, 'Grant'],
    [20069, 'Gray'],
    [20071, 'Greeley'],
    [20073, 'Greenwood'],
    [20075, 'Hamilton'],
    [20077, 'Harper'],
    [20079, 'Harvey'],
    [20081, 'Haskell'],
    [20083, 'Hodgeman'],
    [20085, 'Jackson'],
    [20087, 'Jefferson'],
    [20089, 'Jewell'],
    [20091, 'Johnson'],
    [20093, 'Kearny'],
    [20095, 'Kingman'],
    [20097, 'Kiowa'],
    [20099, 'Labette'],
    [20101, 'Lane'],
    [20103, 'Leavenworth'],
    [20105, 'Lincoln'],
    [20107, 'Linn'],
    [20109, 'Logan'],
    [20111, 'Lyon'],
    [20113, 'McPherson'],
    [20115, 'Marion'],
    [20117, 'Marshall'],
    [20119, 'Meade'],
    [20121, 'Miami'],
    [20123, 'Mitchell'],
    [20125, 'Montgomery'],
    [20127, 'Morris'],
    [20129, 'Morton'],
    [20131, 'Nemaha'],
    [20133, 'Neosho'],
    [20135, 'Ness'],
    [20137, 'Norton'],
    [20139, 'Osage'],
    [20141, 'Osborne'],
    [20143, 'Ottawa'],
    [20145, 'Pawnee'],
    [20147, 'Phillips'],
    [20149, 'Pottawatomie'],
    [20151, 'Pratt'],
    [20153, 'Rawlins'],
    [20155, 'Reno'],
    [20157, 'Republic'],
    [20159, 'Rice'],
    [20161, 'Riley'],
    [20163, 'Rooks'],
    [20165, 'Rush'],
    [20167, 'Russell'],
    [20169, 'Saline'],
    [20171, 'Scott'],
    [20173, 'Sedgwick'],
    [20175, 'Seward'],
    [20177, 'Shawnee'],
    [20179, 'Sheridan'],
    [20181, 'Sherman'],
    [20183, 'Smith'],
    [20185, 'Stafford'],
    [20187, 'Stanton'],
    [20189, 'Stevens'],
    [20191, 'Sumner'],
    [20193, 'Thomas'],
    [20195, 'Trego'],
    [20197, 'Wabaunsee'],
    [20199, 'Wallace'],
    [20201, 'Washington'],
    [20203, 'Wichita'],
    [20205, 'Wilson'],
    [20207, 'Woodson'],
    [20209, 'Wyandotte'],
    [21000, 'Unknown County or County N/A'],                                                                      
    [21001, 'Adair'],
    [21003, 'Allen'],
    [21005, 'Anderson'],
    [21007, 'Ballard'],
    [21009, 'Barren'],
    [21011, 'Bath'],
    [21013, 'Bell'],
    [21015, 'Boone'],
    [21017, 'Bourbon'],
    [21019, 'Boyd'],
    [21021, 'Boyle'],
    [21023, 'Bracken'],
    [21025, 'Breathitt'],
    [21027, 'Breckinridge'],
    [21029, 'Bullitt'],
    [21031, 'Butler'],
    [21033, 'Caldwell'],
    [21035, 'Calloway'],
    [21037, 'Campbell'],
    [21039, 'Carlisle'],
    [21041, 'Carroll'],
    [21043, 'Carter'],
    [21045, 'Casey'],
    [21047, 'Christian'],
    [21049, 'Clark'],
    [21051, 'Clay'],
    [21053, 'Clinton'],
    [21055, 'Crittenden'],
    [21057, 'Cumberland'],
    [21059, 'Daviess'],
    [21061, 'Edmonson'],
    [21063, 'Elliott'],
    [21065, 'Estill'],
    [21067, 'Fayette'],
    [21069, 'Fleming'],
    [21071, 'Floyd'],
    [21073, 'Franklin'],
    [21075, 'Fulton'],
    [21077, 'Gallatin'],
    [21079, 'Garrard'],
    [21081, 'Grant'],
    [21083, 'Graves'],
    [21085, 'Grayson'],
    [21087, 'Green'],
    [21089, 'Greenup'],
    [21091, 'Hancock'],
    [21093, 'Hardin'],
    [21095, 'Harlan'],
    [21097, 'Harrison'],
    [21099, 'Hart'],
    [21101, 'Henderson'],
    [21103, 'Henry'],
    [21105, 'Hickman'],
    [21107, 'Hopkins'],
    [21109, 'Jackson'],
    [21111, 'Jefferson'],
    [21113, 'Jessamine'],
    [21115, 'Johnson'],
    [21117, 'Kenton'],
    [21119, 'Knott'],
    [21121, 'Knox'],
    [21123, 'Larue'],
    [21125, 'Laurel'],
    [21127, 'Lawrence'],
    [21129, 'Lee'],
    [21131, 'Leslie'],
    [21133, 'Letcher'],
    [21135, 'Lewis'],
    [21137, 'Lincoln'],
    [21139, 'Livingston'],
    [21141, 'Logan'],
    [21143, 'Lyon'],
    [21145, 'McCracken'],
    [21147, 'McCreary'],
    [21149, 'McLean'],
    [21151, 'Madison'],
    [21153, 'Magoffin'],
    [21155, 'Marion'],
    [21157, 'Marshall'],
    [21159, 'Martin'],
    [21161, 'Mason'],
    [21163, 'Meade'],
    [21165, 'Menifee'],
    [21167, 'Mercer'],
    [21169, 'Metcalfe'],
    [21171, 'Monroe'],
    [21173, 'Montgomery'],
    [21175, 'Morgan'],
    [21177, 'Muhlenberg'],
    [21179, 'Nelson'],
    [21181, 'Nicholas'],
    [21183, 'Ohio'],
    [21185, 'Oldham'],
    [21187, 'Owen'],
    [21189, 'Owsley'],
    [21191, 'Pendleton'],
    [21193, 'Perry'],
    [21195, 'Pike'],
    [21197, 'Powell'],
    [21199, 'Pulaski'],
    [21201, 'Robertson'],
    [21203, 'Rockcastle'],
    [21205, 'Rowan'],
    [21207, 'Russell'],
    [21209, 'Scott'],
    [21211, 'Shelby'],
    [21213, 'Simpson'],
    [21215, 'Spencer'],
    [21217, 'Taylor'],
    [21219, 'Todd'],
    [21221, 'Trigg'],
    [21223, 'Trimble'],
    [21225, 'Union'],
    [21227, 'Warren'],
    [21229, 'Washington'],
    [21231, 'Wayne'],
    [21233, 'Webster'],
    [21235, 'Whitley'],
    [21237, 'Wolfe'],
    [21239, 'Woodford'],
    [22000, 'Unknown County or County N/A'],                                                                      
    [22001, 'Acadia'],
    [22003, 'Allen'],
    [22005, 'Ascension'],
    [22007, 'Assumption'],
    [22009, 'Avoyelles'],
    [22011, 'Beauregard'],
    [22013, 'Bienville'],
    [22015, 'Bossier'],
    [22017, 'Caddo'],
    [22019, 'Calcasieu'],
    [22021, 'Caldwell'],
    [22023, 'Cameron'],
    [22025, 'Catahoula'],
    [22027, 'Claiborne'],
    [22029, 'Concordia'],
    [22031, 'De Soto'],
    [22033, 'East Baton Rouge'],
    [22035, 'East Carroll'],
    [22037, 'East Feliciana'],
    [22039, 'Evangeline'],
    [22041, 'Franklin'],
    [22043, 'Grant'],
    [22045, 'Iberia'],
    [22047, 'Iberville'],
    [22049, 'Jackson'],
    [22051, 'Jefferson'],
    [22053, 'Jefferson Davis'],
    [22055, 'Lafayette'],
    [22057, 'LaFourche'],
    [22059, 'La Salle'],
    [22061, 'Lincoln'],
    [22063, 'Livingston'],
    [22065, 'Madison'],
    [22067, 'Morehouse'],
    [22069, 'Natchitoches'],
    [22071, 'Orleans'],
    [22073, 'Ouachita'],
    [22075, 'Plaquemines'],
    [22077, 'Pointe Coupee'],
    [22079, 'Rapides'],
    [22081, 'Red River'],
    [22083, 'Richland'],
    [22085, 'Sabine'],
    [22087, 'St. Bernard'],
    [22089, 'St. Charles'],
    [22091, 'St. Helena'],
    [22093, 'St. James'],
    [22095, 'St. John the Baptist'],
    [22097, 'St. Landry'],
    [22099, 'St. Martin'],
    [22101, 'St. Mary'],
    [22103, 'St. Tammany'],
    [22105, 'Tangipahoa'],
    [22107, 'Tensas'],
    [22109, 'Terrebonne'],
    [22111, 'Union'],
    [22113, 'Vermilion'],
    [22115, 'Vernon'],
    [22117, 'Washington'],
    [22119, 'Webster'],
    [22121, 'West Baton Rouge'],
    [22123, 'West Carroll'],
    [22125, 'West Feliciana'],
    [22127, 'Winn'],
    [23000, 'Unknown County or County N/A'],                                                                      
    [23001, 'Androscoggin'],
    [23003, 'Aroostook'],
    [23005, 'Cumberland'],
    [23007, 'Franklin'],
    [23009, 'Hancock'],
    [23011, 'Kennebec'],
    [23013, 'Knox'],
    [23015, 'Lincoln'],
    [23017, 'Oxford'],
    [23019, 'Penobscot'],
    [23021, 'Piscataquis'],
    [23023, 'Sagadahoc'],
    [23025, 'Somerset'],
    [23027, 'Waldo'],
    [23029, 'Washington'],
    [23031, 'York'],
    [24000, 'Unknown County or County N/A'],                                                                      
    [24001, 'Allegany'],
    [24003, 'Anne Arundel'],
    [24005, 'Baltimore'],
    [24009, 'Calvert'],
    [24011, 'Caroline'],
    [24013, 'Carroll'],
    [24015, 'Cecil'],
    [24017, 'Charles'],
    [24019, 'Dorchester'],
    [24021, 'Frederick'],
    [24023, 'Garrett'],
    [24025, 'Harford'],
    [24027, 'Howard'],
    [24029, 'Kent'],
    [24031, 'Montgomery'],
    [24033, 'Prince Georges'],
    [24035, 'Queen Annes'],
    [24037, 'St. Marys'],
    [24039, 'Somerset'],
    [24041, 'Talbot'],
    [24043, 'Washington'],
    [24045, 'Wicomico'],
    [24047, 'Worcester'],
    [24510, 'Baltimore City'],
    [25000, 'Unknown County or County N/A'],                                                                      
    [25001, 'Barnstable'],
    [25003, 'Berkshire'],
    [25005, 'Bristol'],
    [25007, 'Dukes'],
    [25009, 'Essex'],
    [25011, 'Franklin'],
    [25013, 'Hampden'],
    [25015, 'Hampshire'],
    [25017, 'Middlesex'],
    [25019, 'Nantucket'],
    [25021, 'Norfolk'],
    [25023, 'Plymouth'],
    [25025, 'Suffolk'],
    [25027, 'Worcester'],
    [26000, 'Unknown County or County N/A'],                                                                      
    [26001, 'Alcona'],
    [26003, 'Alger'],
    [26005, 'Allegan'],
    [26007, 'Alpena'],
    [26009, 'Antrim'],
    [26011, 'Arenac'],
    [26013, 'Baraga'],
    [26015, 'Barry'],
    [26017, 'Bay'],
    [26019, 'Benzie'],
    [26021, 'Berrien'],
    [26023, 'Branch'],
    [26025, 'Calhoun'],
    [26027, 'Cass'],
    [26029, 'Charlevoix'],
    [26031, 'Cheboygan'],
    [26033, 'Chippewa'],
    [26035, 'Clare'],
    [26037, 'Clinton'],
    [26039, 'Crawford'],
    [26041, 'Delta'],
    [26043, 'Dickinson'],
    [26045, 'Eaton'],
    [26047, 'Emmet'],
    [26049, 'Genesee'],
    [26051, 'Gladwin'],
    [26053, 'Gogebic'],
    [26055, 'Grand Traverse'],
    [26057, 'Gratiot'],
    [26059, 'Hillsdale'],
    [26061, 'Houghton'],
    [26063, 'Huron'],
    [26065, 'Ingham'],
    [26067, 'Ionia'],
    [26069, 'Iosco'],
    [26071, 'Iron'],
    [26073, 'Isabella'],
    [26075, 'Jackson'],
    [26077, 'Kalamazoo'],
    [26079, 'Kalkaska'],
    [26081, 'Kent'],
    [26083, 'Keweenaw'],
    [26085, 'Lake'],
    [26087, 'Lapeer'],
    [26089, 'Leelanau'],
    [26091, 'Lenawee'],
    [26093, 'Livingston'],
    [26095, 'Luce'],
    [26097, 'Mackinac'],
    [26099, 'Macomb'],
    [26101, 'Manistee'],
    [26103, 'Marquette'],
    [26105, 'Mason'],
    [26107, 'Mecosta'],
    [26109, 'Menominee'],
    [26111, 'Midland'],
    [26113, 'Missaukee'],
    [26115, 'Monroe'],
    [26117, 'Montcalm'],
    [26119, 'Montmorency'],
    [26121, 'Muskegon'],
    [26123, 'Newaygo'],
    [26125, 'Oakland'],
    [26127, 'Oceana'],
    [26129, 'Ogemaw'],
    [26131, 'Ontonagon'],
    [26133, 'Osceola'],
    [26135, 'Oscoda'],
    [26137, 'Otsego'],
    [26139, 'Ottawa'],
    [26141, 'Presque Isle'],
    [26143, 'Roscommon'],
    [26145, 'Saginaw'],
    [26147, 'St. Clair'],
    [26149, 'St. Joseph'],
    [26151, 'Sanilac'],
    [26153, 'Schoolcraft'],
    [26155, 'Shiawassee'],
    [26157, 'Tuscola'],
    [26159, 'Van Buren'],
    [26161, 'Washtenaw'],
    [26163, 'Wayne'],
    [26165, 'Wexford'],
    [27000, 'Unknown County or County N/A'],                                                                      
    [27001, 'Aitkin'],
    [27003, 'Anoka'],
    [27005, 'Becker'],
    [27007, 'Beltrami'],
    [27009, 'Benton'],
    [27011, 'Big Stone'],
    [27013, 'Blue Earth'],
    [27015, 'Brown'],
    [27017, 'Carlton'],
    [27019, 'Carver'],
    [27021, 'Cass'],
    [27023, 'Chippewa'],
    [27025, 'Chisago'],
    [27027, 'Clay'],
    [27029, 'Clearwater'],
    [27031, 'Cook'],
    [27033, 'Cottonwood'],
    [27035, 'Crow Wing'],
    [27037, 'Dakota'],
    [27039, 'Dodge'],
    [27041, 'Douglas'],
    [27043, 'Faribault'],
    [27045, 'Fillmore'],
    [27047, 'Freeborn'],
    [27049, 'Goodhue'],
    [27051, 'Grant'],
    [27053, 'Hennepin'],
    [27055, 'Houston'],
    [27057, 'Hubbard'],
    [27059, 'Isanti'],
    [27061, 'Itasca'],
    [27063, 'Jackson'],
    [27065, 'Kanabec'],
    [27067, 'Kandiyohi'],
    [27069, 'Kittson'],
    [27071, 'Koochiching'],
    [27073, 'Lac Qui Parle'],
    [27075, 'Lake'],
    [27077, 'Lake of the Woods'],
    [27079, 'Le Sueur'],
    [27081, 'Lincoln'],
    [27083, 'Lyon'],
    [27085, 'McLeod'],
    [27087, 'Mahnomen'],
    [27089, 'Marshall'],
    [27091, 'Martin'],
    [27093, 'Meeker'],
    [27095, 'Mille Lacs'],
    [27097, 'Morrison'],
    [27099, 'Mower'],
    [27101, 'Murray'],
    [27103, 'Nicollet'],
    [27105, 'Nobles'],
    [27107, 'Norman'],
    [27109, 'Olmsted'],
    [27111, 'Otter Tail'],
    [27113, 'Pennington'],
    [27115, 'Pine'],
    [27117, 'Pipestone'],
    [27119, 'Polk'],
    [27121, 'Pope'],
    [27123, 'Ramsey'],
    [27125, 'Red Lake'],
    [27127, 'Redwood'],
    [27129, 'Renville'],
    [27131, 'Rice'],
    [27133, 'Rock'],
    [27135, 'Roseau'],
    [27137, 'St. Louis'],
    [27139, 'Scott'],
    [27141, 'Sherburne'],
    [27143, 'Sibley'],
    [27145, 'Stearns'],
    [27147, 'Steele'],
    [27149, 'Stevens'],
    [27151, 'Swift'],
    [27153, 'Todd'],
    [27155, 'Traverse'],
    [27157, 'Wabasha'],
    [27159, 'Wadena'],
    [27161, 'Waseca'],
    [27163, 'Washington'],
    [27165, 'Watonwan'],
    [27167, 'Wilkin'],
    [27169, 'Winona'],
    [27171, 'Wright'],
    [27173, 'Yellow Medicine'],
    [28000, 'Unknown County or County N/A'],                                                                      
    [28001, 'Adams'],
    [28003, 'Alcorn'],
    [28005, 'Amite'],
    [28007, 'Attala'],
    [28009, 'Benton'],
    [28011, 'Bolivar'],
    [28013, 'Calhoun'],
    [28015, 'Carroll'],
    [28017, 'Chickasaw'],
    [28019, 'Choctaw'],
    [28021, 'Claiborne'],
    [28023, 'Clarke'],
    [28025, 'Clay'],
    [28027, 'Coahoma'],
    [28029, 'Copiah'],
    [28031, 'Covington'],
    [28033, 'De Soto'],
    [28035, 'Forrest'],
    [28037, 'Franklin'],
    [28039, 'George'],
    [28041, 'Greene'],
    [28043, 'Grenada'],
    [28045, 'Hancock'],
    [28047, 'Harrison'],
    [28049, 'Hinds'],
    [28051, 'Holmes'],
    [28053, 'Humphreys'],
    [28055, 'Issaquena'],
    [28057, 'Itawamba'],
    [28059, 'Jackson'],
    [28061, 'Jasper'],
    [28063, 'Jefferson'],
    [28065, 'Jefferson Davis'],
    [28067, 'Jones'],
    [28069, 'Kemper'],
    [28071, 'Lafayette'],
    [28073, 'Lamar'],
    [28075, 'Lauderdale'],
    [28077, 'Lawrence'],
    [28079, 'Leake'],
    [28081, 'Lee'],
    [28083, 'Leflore'],
    [28085, 'Lincoln'],
    [28087, 'Lowndes'],
    [28089, 'Madison'],
    [28091, 'Marion'],
    [28093, 'Marshall'],
    [28095, 'Monroe'],
    [28097, 'Montgomery'],
    [28099, 'Neshoba'],
    [28101, 'Newton'],
    [28103, 'Noxubee'],
    [28105, 'Oktibbeha'],
    [28107, 'Panola'],
    [28109, 'Pearl River'],
    [28111, 'Perry'],
    [28113, 'Pike'],
    [28115, 'Pontotoc'],
    [28117, 'Prentiss'],
    [28119, 'Quitman'],
    [28121, 'Rankin'],
    [28123, 'Scott'],
    [28125, 'Sharkey'],
    [28127, 'Simpson'],
    [28129, 'Smith'],
    [28131, 'Stone'],
    [28133, 'Sunflower'],
    [28135, 'Tallahatchie'],
    [28137, 'Tate'],
    [28139, 'Tippah'],
    [28141, 'Tishomingo'],
    [28143, 'Tunica'],
    [28145, 'Union'],
    [28147, 'Walthall'],
    [28149, 'Warren'],
    [28151, 'Washington'],
    [28153, 'Wayne'],
    [28155, 'Webster'],
    [28157, 'Wilkinson'],
    [28159, 'Winston'],
    [28161, 'Yalobusha'],
    [28163, 'Yazoo'],
    [29000, 'Unknown County or County N/A'],                                                                      
    [29001, 'Adair'],
    [29003, 'Andrew'],
    [29005, 'Atchison'],
    [29007, 'Audrain'],
    [29009, 'Barry'],
    [29011, 'Barton'],
    [29013, 'Bates'],
    [29015, 'Benton'],
    [29017, 'Bollinger'],
    [29019, 'Boone'],
    [29021, 'Buchanan'],
    [29023, 'Butler'],
    [29025, 'Caldwell'],
    [29027, 'Callaway'],
    [29029, 'Camden'],
    [29031, 'Cape Girardeau'],
    [29033, 'Carroll'],
    [29035, 'Carter'],
    [29037, 'Cass'],
    [29039, 'Cedar'],
    [29041, 'Chariton'],
    [29043, 'Christian'],
    [29045, 'Clark'],
    [29047, 'Clay'],
    [29049, 'Clinton'],
    [29051, 'Cole'],
    [29053, 'Cooper'],
    [29055, 'Crawford'],
    [29057, 'Dade'],
    [29059, 'Dallas'],
    [29061, 'Daviess'],
    [29063, 'De Kalb'],
    [29065, 'Dent'],
    [29067, 'Douglas'],
    [29069, 'Dunklin'],
    [29071, 'Franklin'],
    [29073, 'Gasconade'],
    [29075, 'Gentry'],
    [29077, 'Greene'],
    [29079, 'Grundy'],
    [29081, 'Harrison'],
    [29083, 'Henry'],
    [29085, 'Hickory'],
    [29087, 'Holt'],
    [29089, 'Howard'],
    [29091, 'Howell'],
    [29093, 'Iron'],
    [29095, 'Jackson'],
    [29097, 'Jasper'],
    [29099, 'Jefferson'],
    [29101, 'Johnson'],
    [29103, 'Knox'],
    [29105, 'Laclede'],
    [29107, 'Lafayette'],
    [29109, 'Lawrence'],
    [29111, 'Lewis'],
    [29113, 'Lincoln'],
    [29115, 'Linn'],
    [29117, 'Livingston'],
    [29119, 'McDonald'],
    [29121, 'Macon'],
    [29123, 'Madison'],
    [29125, 'Maries'],
    [29127, 'Marion'],
    [29129, 'Mercer'],
    [29131, 'Miller'],
    [29133, 'Mississippi'],
    [29135, 'Moniteau'],
    [29137, 'Monroe'],
    [29139, 'Montgomery'],
    [29141, 'Morgan'],
    [29143, 'New Madrid'],
    [29145, 'Newton'],
    [29147, 'Nodaway'],
    [29149, 'Oregon'],
    [29151, 'Osage'],
    [29153, 'Ozark'],
    [29155, 'Pemiscot'],
    [29157, 'Perry'],
    [29159, 'Pettis'],
    [29161, 'Phelps'],
    [29163, 'Pike'],
    [29165, 'Platte'],
    [29167, 'Polk'],
    [29169, 'Pulaski'],
    [29171, 'Putnam'],
    [29173, 'Ralls'],
    [29175, 'Randolph'],
    [29177, 'Ray'],
    [29179, 'Reynolds'],
    [29181, 'Ripley'],
    [29183, 'St. Charles'],
    [29185, 'St. Clair'],
    [29186, 'Ste. Genevieve'],
    [29187, 'St. Francois'],
    [29189, 'St. Louis'],
    [29195, 'Saline'],
    [29197, 'Schuyler'],
    [29199, 'Scotland'],
    [29201, 'Scott'],
    [29203, 'Shannon'],
    [29205, 'Shelby'],
    [29207, 'Stoddard'],
    [29209, 'Stone'],
    [29211, 'Sullivan'],
    [29213, 'Taney'],
    [29215, 'Texas'],
    [29217, 'Vernon'],
    [29219, 'Warren'],
    [29221, 'Washington'],
    [29223, 'Wayne'],
    [29225, 'Webster'],
    [29227, 'Worth'],
    [29229, 'Wright'],
    [29510, 'St. Louis City'],
    [30000, 'Unknown County or County N/A'],                                                                      
    [30001, 'Beaverhead'],
    [30003, 'Big Horn'],
    [30005, 'Blaine'],
    [30007, 'Broadwater'],
    [30009, 'Carbon'],
    [30011, 'Carter'],
    [30013, 'Cascade'],
    [30015, 'Chouteau'],
    [30017, 'Custer'],
    [30019, 'Daniels'],
    [30021, 'Dawson'],
    [30023, 'Deer Lodge'],
    [30025, 'Fallon'],
    [30027, 'Fergus'],
    [30029, 'Flathead'],
    [30031, 'Gallatin'],
    [30033, 'Garfield'],
    [30035, 'Glacier'],
    [30037, 'Golden Valley'],
    [30039, 'Granite'],
    [30041, 'Hill'],
    [30043, 'Jefferson'],
    [30045, 'Judith Basin'],
    [30047, 'Lake'],
    [30049, 'Lewis and Clark'],
    [30051, 'Liberty'],
    [30053, 'Lincoln'],
    [30055, 'McCone'],
    [30057, 'Madison'],
    [30059, 'Meagher'],
    [30061, 'Mineral'],
    [30063, 'Missoula'],
    [30065, 'Musselshell'],
    [30067, 'Park'],
    [30069, 'Petroleum'],
    [30071, 'Phillips'],
    [30073, 'Pondera'],
    [30075, 'Powder River'],
    [30077, 'Powell'],
    [30079, 'Prairie'],
    [30081, 'Ravalli'],
    [30083, 'Richland'],
    [30085, 'Roosevelt'],
    [30087, 'Rosebud'],
    [30089, 'Sanders'],
    [30091, 'Sheridan'],
    [30093, 'Silver Bow'],
    [30095, 'Stillwater'],
    [30097, 'Sweet Grass'],
    [30099, 'Teton'],
    [30101, 'Toole'],
    [30103, 'Treasure'],
    [30105, 'Valley'],
    [30107, 'Wheatland'],
    [30109, 'Wibaux'],
    [30111, 'Yellowstone'],
    [31000, 'Unknown County or County N/A'],                                                                      
    [31001, 'Adams'],
    [31003, 'Antelope'],
    [31005, 'Arthur'],
    [31007, 'Banner'],
    [31009, 'Blaine'],
    [31011, 'Boone'],
    [31013, 'Box Butte'],
    [31015, 'Boyd'],
    [31017, 'Brown'],
    [31019, 'Buffalo'],
    [31021, 'Burt'],
    [31023, 'Butler'],
    [31025, 'Cass'],
    [31027, 'Cedar'],
    [31029, 'Chase'],
    [31031, 'Cherry'],
    [31033, 'Cheyenne'],
    [31035, 'Clay'],
    [31037, 'Colfax'],
    [31039, 'Cuming'],
    [31041, 'Custer'],
    [31043, 'Dakota'],
    [31045, 'Dawes'],
    [31047, 'Dawson'],
    [31049, 'Deuel'],
    [31051, 'Dixon'],
    [31053, 'Dodge'],
    [31055, 'Douglas'],
    [31057, 'Dundy'],
    [31059, 'Fillmore'],
    [31061, 'Franklin'],
    [31063, 'Frontier'],
    [31065, 'Furnas'],
    [31067, 'Gage'],
    [31069, 'Garden'],
    [31071, 'Garfield'],
    [31073, 'Gosper'],
    [31075, 'Grant'],
    [31077, 'Greeley'],
    [31079, 'Hall'],
    [31081, 'Hamilton'],
    [31083, 'Harlan'],
    [31085, 'Hayes'],
    [31087, 'Hitchcock'],
    [31089, 'Holt'],
    [31091, 'Hooker'],
    [31093, 'Howard'],
    [31095, 'Jefferson'],
    [31097, 'Johnson'],
    [31099, 'Kearney'],
    [31101, 'Keith'],
    [31103, 'Keya Paha'],
    [31105, 'Kimball'],
    [31107, 'Knox'],
    [31109, 'Lancaster'],
    [31111, 'Lincoln'],
    [31113, 'Logan'],
    [31115, 'Loup'],
    [31117, 'McPherson'],
    [31119, 'Madison'],
    [31121, 'Merrick'],
    [31123, 'Morrill'],
    [31125, 'Nance'],
    [31127, 'Nemaha'],
    [31129, 'Nuckolls'],
    [31131, 'Otoe'],
    [31133, 'Pawnee'],
    [31135, 'Perkins'],
    [31137, 'Phelps'],
    [31139, 'Pierce'],
    [31141, 'Platte'],
    [31143, 'Polk'],
    [31145, 'Red Willow'],
    [31147, 'Richardson'],
    [31149, 'Rock'],
    [31151, 'Saline'],
    [31153, 'Sarpy'],
    [31155, 'Saunders'],
    [31157, 'Scotts Bluff'],
    [31159, 'Seward'],
    [31161, 'Sheridan'],
    [31163, 'Sherman'],
    [31165, 'Sioux'],
    [31167, 'Stanton'],
    [31169, 'Thayer'],
    [31171, 'Thomas'],
    [31173, 'Thurston'],
    [31175, 'Valley'],
    [31177, 'Washington'],
    [31179, 'Wayne'],
    [31181, 'Webster'],
    [31183, 'Wheeler'],
    [31185, 'York'],
    [32000, 'Unknown County or County N/A'],                                                                      
    [32001, 'Churchill'],
    [32003, 'Clark'],
    [32005, 'Douglas'],
    [32007, 'Elko'],
    [32009, 'Esmeralda'],
    [32011, 'Eureka'],
    [32013, 'Humboldt'],
    [32015, 'Lander'],
    [32017, 'Lincoln'],
    [32019, 'Lyon'],
    [32021, 'Mineral'],
    [32023, 'Nye'],
    [32027, 'Pershing'],
    [32029, 'Storey'],
    [32031, 'Washoe'],
    [32033, 'White Pine'],
    [32510, 'Carson City'],
    [33000, 'Unknown County or County N/A'],                                                                      
    [33001, 'Belknap'],
    [33003, 'Carroll'],
    [33005, 'Cheshire'],
    [33007, 'Coos'],
    [33009, 'Grafton'],
    [33011, 'Hillsborough'],
    [33013, 'Merrimack'],
    [33015, 'Rockingham'],
    [33017, 'Strafford'],
    [33019, 'Sullivan'],
    [34000, 'Unknown County or County N/A'],                                                                      
    [34001, 'Atlantic'],
    [34003, 'Bergen'],
    [34005, 'Burlington'],
    [34007, 'Camden'],
    [34009, 'Cape May'],
    [34011, 'Cumberland'],
    [34013, 'Essex'],
    [34015, 'Gloucester'],
    [34017, 'Hudson'],
    [34019, 'Hunterdon'],
    [34021, 'Mercer'],
    [34023, 'Middlesex'],
    [34025, 'Monmouth'],
    [34027, 'Morris'],
    [34029, 'Ocean'],
    [34031, 'Passaic'],
    [34033, 'Salem'],
    [34035, 'Somerset'],
    [34037, 'Sussex'],
    [34039, 'Union'],
    [34041, 'Warren'],
    [35000, 'Unknown County or County N/A'],                                                                      
    [35001, 'Bernalillo'],
    [35003, 'Catron'],
    [35005, 'Chaves'],
    [35006, 'Cibola'],
    [35007, 'Colfax'],
    [35009, 'Curry'],
    [35011, 'De Baca'],
    [35013, 'Dona Ana'],
    [35015, 'Eddy'],
    [35017, 'Grant'],
    [35019, 'Guadalupe'],
    [35021, 'Harding'],
    [35023, 'Hidalgo'],
    [35025, 'Lea'],
    [35027, 'Lincoln'],
    [35028, 'Los Alamos'],
    [35029, 'Luna'],
    [35031, 'McKinley'],
    [35033, 'Mora'],
    [35035, 'Otero'],
    [35037, 'Quay'],
    [35039, 'Rio Arriba'],
    [35041, 'Roosevelt'],
    [35043, 'Sandoval'],
    [35045, 'San Juan'],
    [35047, 'San Miguel'],
    [35049, 'Santa Fe'],
    [35051, 'Sierra'],
    [35053, 'Socorro'],
    [35055, 'Taos'],
    [35057, 'Torrance'],
    [35059, 'Union'],
    [35061, 'Valencia'],
    [36000, 'Unknown County or County N/A'],                                                                      
    [36001, 'Albany'],
    [36003, 'Allegany'],
    [36005, 'Bronx'],
    [36007, 'Broome'],
    [36009, 'Cattaraugus'],
    [36011, 'Cayuga'],
    [36013, 'Chautauqua'],
    [36015, 'Chemung'],
    [36017, 'Chenango'],
    [36019, 'Clinton'],
    [36021, 'Columbia'],
    [36023, 'Cortland'],
    [36025, 'Delaware'],
    [36027, 'Dutchess'],
    [36029, 'Erie'],
    [36031, 'Essex'],
    [36033, 'Franklin'],
    [36035, 'Fulton'],
    [36037, 'Genesee'],
    [36039, 'Greene'],
    [36041, 'Hamilton'],
    [36043, 'Herkimer'],
    [36045, 'Jefferson'],
    [36047, 'Kings'],
    [36049, 'Lewis'],
    [36051, 'Livingston'],
    [36053, 'Madison'],
    [36055, 'Monroe'],
    [36057, 'Montgomery'],
    [36059, 'Nassau'],
    [36061, 'New York'],
    [36063, 'Niagara'],
    [36065, 'Oneida'],
    [36067, 'Onondaga'],
    [36069, 'Ontario'],
    [36071, 'Orange'],
    [36073, 'Orleans'],
    [36075, 'Oswego'],
    [36077, 'Otsego'],
    [36079, 'Putnam'],
    [36081, 'Queens'],
    [36083, 'Rensselaer'],
    [36085, 'Richmond'],
    [36087, 'Rockland'],
    [36089, 'St. Lawrence'],
    [36091, 'Saratoga'],
    [36093, 'Schenectady'],
    [36095, 'Schoharie'],
    [36097, 'Schuyler'],
    [36099, 'Seneca'],
    [36101, 'Steuben'],
    [36103, 'Suffolk'],
    [36105, 'Sullivan'],
    [36107, 'Tioga'],
    [36109, 'Tompkins'],
    [36111, 'Ulster'],
    [36113, 'Warren'],
    [36115, 'Washington'],
    [36117, 'Wayne'],
    [36119, 'Westchester'],
    [36121, 'Wyoming'],
    [36123, 'Yates'],
    [37000, 'Unknown County or County N/A'],                                                                      
    [37001, 'Alamance'],
    [37003, 'Alexander'],
    [37005, 'Alleghany'],
    [37007, 'Anson'],
    [37009, 'Ashe'],
    [37011, 'Avery'],
    [37013, 'Beaufort'],
    [37015, 'Bertie'],
    [37017, 'Bladen'],
    [37019, 'Brunswick'],
    [37021, 'Buncombe'],
    [37023, 'Burke'],
    [37025, 'Cabarrus'],
    [37027, 'Caldwell'],
    [37029, 'Camden'],
    [37031, 'Carteret'],
    [37033, 'Caswell'],
    [37035, 'Catawba'],
    [37037, 'Chatham'],
    [37039, 'Cherokee'],
    [37041, 'Chowan'],
    [37043, 'Clay'],
    [37045, 'Cleveland'],
    [37047, 'Columbus'],
    [37049, 'Craven'],
    [37051, 'Cumberland'],
    [37053, 'Currituck'],
    [37055, 'Dare'],
    [37057, 'Davidson'],
    [37059, 'Davie'],
    [37061, 'Duplin'],
    [37063, 'Durham'],
    [37065, 'Edgecombe'],
    [37067, 'Forsyth'],
    [37069, 'Franklin'],
    [37071, 'Gaston'],
    [37073, 'Gates'],
    [37075, 'Graham'],
    [37077, 'Granville'],
    [37079, 'Greene'],
    [37081, 'Guilford'],
    [37083, 'Halifax'],
    [37085, 'Harnett'],
    [37087, 'Haywood'],
    [37089, 'Henderson'],
    [37091, 'Hertford'],
    [37093, 'Hoke'],
    [37095, 'Hyde'],
    [37097, 'Iredell'],
    [37099, 'Jackson'],
    [37101, 'Johnston'],
    [37103, 'Jones'],
    [37105, 'Lee'],
    [37107, 'Lenoir'],
    [37109, 'Lincoln'],
    [37111, 'McDowell'],
    [37113, 'Macon'],
    [37115, 'Madison'],
    [37117, 'Martin'],
    [37119, 'Mecklenburg'],
    [37121, 'Mitchell'],
    [37123, 'Montgomery'],
    [37125, 'Moore'],
    [37127, 'Nash'],
    [37129, 'New Hanover'],
    [37131, 'Northampton'],
    [37133, 'Onslow'],
    [37135, 'Orange'],
    [37137, 'Pamlico'],
    [37139, 'Pasquotank'],
    [37141, 'Pender'],
    [37143, 'Perquimans'],
    [37145, 'Person'],
    [37147, 'Pitt'],
    [37149, 'Polk'],
    [37151, 'Randolph'],
    [37153, 'Richmond'],
    [37155, 'Robeson'],
    [37157, 'Rockingham'],
    [37159, 'Rowan'],
    [37161, 'Rutherford'],
    [37163, 'Sampson'],
    [37165, 'Scotland'],
    [37167, 'Stanly'],
    [37169, 'Stokes'],
    [37171, 'Surry'],
    [37173, 'Swain'],
    [37175, 'Transylvania'],
    [37177, 'Tyrrell'],
    [37179, 'Union'],
    [37181, 'Vance'],
    [37183, 'Wake'],
    [37185, 'Warren'],
    [37187, 'Washington'],
    [37189, 'Watauga'],
    [37191, 'Wayne'],
    [37193, 'Wilkes'],
    [37195, 'Wilson'],
    [37197, 'Yadkin'],
    [37199, 'Yancey'],
    [38000, 'Unknown County or County N/A'],                                                                      
    [38001, 'Adams'],
    [38003, 'Barnes'],
    [38005, 'Benson'],
    [38007, 'Billings'],
    [38009, 'Bottineau'],
    [38011, 'Bowman'],
    [38013, 'Burke'],
    [38015, 'Burleigh'],
    [38017, 'Cass'],
    [38019, 'Cavalier'],
    [38021, 'Dickey'],
    [38023, 'Divide'],
    [38025, 'Dunn'],
    [38027, 'Eddy'],
    [38029, 'Emmons'],
    [38031, 'Foster'],
    [38033, 'Golden Valley'],
    [38035, 'Grand Forks'],
    [38037, 'Grant'],
    [38039, 'Griggs'],
    [38041, 'Hettinger'],
    [38043, 'Kidder'],
    [38045, 'La Moure'],
    [38047, 'Logan'],
    [38049, 'McHenry'],
    [38051, 'McIntosh'],
    [38053, 'McKenzie'],
    [38055, 'McLean'],
    [38057, 'Mercer'],
    [38059, 'Morton'],
    [38061, 'Mountrial'],
    [38063, 'Nelson'],
    [38065, 'Oliver'],
    [38067, 'Pembina'],
    [38069, 'Pierce'],
    [38071, 'Ramsey'],
    [38073, 'Ransom'],
    [38075, 'Renville'],
    [38077, 'Richland'],
    [38079, 'Rolette'],
    [38081, 'Sargent'],
    [38083, 'Sheridan'],
    [38085, 'Sioux'],
    [38087, 'Slope'],
    [38089, 'Stark'],
    [38091, 'Steele'],
    [38093, 'Stutsman'],
    [38095, 'Towner'],
    [38097, 'Traill'],
    [38099, 'Walsh'],
    [38101, 'Ward'],
    [38103, 'Wells'],
    [38105, 'Williams'],
    [39000, 'Unknown County or County N/A'],                                                                      
    [39001, 'Adams'],
    [39003, 'Allen'],
    [39005, 'Ashland'],
    [39007, 'Ashtabula'],
    [39009, 'Athens'],
    [39011, 'Auglaize'],
    [39013, 'Belmont'],
    [39015, 'Brown'],
    [39017, 'Butler'],
    [39019, 'Carroll'],
    [39021, 'Champaign'],
    [39023, 'Clark'],
    [39025, 'Clermont'],
    [39027, 'Clinton'],
    [39029, 'Columbiana'],
    [39031, 'Coshocton'],
    [39033, 'Crawford'],
    [39035, 'Cuyahoga'],
    [39037, 'Darke'],
    [39039, 'Defiance'],
    [39041, 'Delaware'],
    [39043, 'Erie'],
    [39045, 'Fairfield'],
    [39047, 'Fayette'],
    [39049, 'Franklin'],
    [39051, 'Fulton'],
    [39053, 'Gallia'],
    [39055, 'Geauga'],
    [39057, 'Greene'],
    [39059, 'Guernsey'],
    [39061, 'Hamilton'],
    [39063, 'Hancock'],
    [39065, 'Hardin'],
    [39067, 'Harrison'],
    [39069, 'Henry'],
    [39071, 'Highland'],
    [39073, 'Hocking'],
    [39075, 'Holmes'],
    [39077, 'Huron'],
    [39079, 'Jackson'],
    [39081, 'Jefferson'],
    [39083, 'Knox'],
    [39085, 'Lake'],
    [39087, 'Lawrence'],
    [39089, 'Licking'],
    [39091, 'Logan'],
    [39093, 'Lorain'],
    [39095, 'Lucas'],
    [39097, 'Madison'],
    [39099, 'Mahoning'],
    [39101, 'Marion'],
    [39103, 'Medina'],
    [39105, 'Meigs'],
    [39107, 'Mercer'],
    [39109, 'Miami'],
    [39111, 'Monroe'],
    [39113, 'Montgomery'],
    [39115, 'Morgan'],
    [39117, 'Morrow'],
    [39119, 'Muskingum'],
    [39121, 'Noble'],
    [39123, 'Ottawa'],
    [39125, 'Paulding'],
    [39127, 'Perry'],
    [39129, 'Pickaway'],
    [39131, 'Pike'],
    [39133, 'Portage'],
    [39135, 'Preble'],
    [39137, 'Putnam'],
    [39139, 'Richland'],
    [39141, 'Ross'],
    [39143, 'Sandusky'],
    [39145, 'Scioto'],
    [39147, 'Seneca'],
    [39149, 'Shelby'],
    [39151, 'Stark'],
    [39153, 'Summit'],
    [39155, 'Trumbull'],
    [39157, 'Tuscarawas'],
    [39159, 'Union'],
    [39161, 'Van Wert'],
    [39163, 'Vinton'],
    [39165, 'Warren'],
    [39167, 'Washington'],
    [39169, 'Wayne'],
    [39171, 'Williams'],
    [39173, 'Wood'],
    [39175, 'Wyandot'],
    [40000, 'Unknown County or County N/A'],                                                                      
    [40001, 'Adair'],
    [40003, 'Alfalfa'],
    [40005, 'Atoka'],
    [40007, 'Beaver'],
    [40009, 'Beckham'],
    [40011, 'Blaine'],
    [40013, 'Bryan'],
    [40015, 'Caddo'],
    [40017, 'Canadian'],
    [40019, 'Carter'],
    [40021, 'Cherokee'],
    [40023, 'Choctaw'],
    [40025, 'Cimarron'],
    [40027, 'Cleveland'],
    [40029, 'Coal'],
    [40031, 'Comanche'],
    [40033, 'Cotton'],
    [40035, 'Craig'],
    [40037, 'Creek'],
    [40039, 'Custer'],
    [40041, 'Delaware'],
    [40043, 'Dewey'],
    [40045, 'Ellis'],
    [40047, 'Garfield'],
    [40049, 'Garvin'],
    [40051, 'Grady'],
    [40053, 'Grant'],
    [40055, 'Greer'],
    [40057, 'Harmon'],
    [40059, 'Harper'],
    [40061, 'Haskell'],
    [40063, 'Hughes'],
    [40065, 'Jackson'],
    [40067, 'Jefferson'],
    [40069, 'Johnston'],
    [40071, 'Kay'],
    [40073, 'Kingfisher'],
    [40075, 'Kiowa'],
    [40077, 'Latimer'],
    [40079, 'Le Flore'],
    [40081, 'Lincoln'],
    [40083, 'Logan'],
    [40085, 'Love'],
    [40087, 'McClain'],
    [40089, 'McCurtain'],
    [40091, 'McIntosh'],
    [40093, 'Major'],
    [40095, 'Marshall'],
    [40097, 'Mayes'],
    [40099, 'Murray'],
    [40101, 'Muskogee'],
    [40103, 'Noble'],
    [40105, 'Nowata'],
    [40107, 'Okfuskee'],
    [40109, 'Oklahoma'],
    [40111, 'Okmulgee'],
    [40113, 'Osage'],
    [40115, 'Ottawa'],
    [40117, 'Pawnee'],
    [40119, 'Payne'],
    [40121, 'Pittsburg'],
    [40123, 'Pontotoc'],
    [40125, 'Pottawatomie'],
    [40127, 'Pushmataha'],
    [40129, 'Roger Mills'],
    [40131, 'Rogers'],
    [40133, 'Seminole'],
    [40135, 'Sequoyah'],
    [40137, 'Stephens'],
    [40139, 'Texas'],
    [40141, 'Tillman'],
    [40143, 'Tulsa'],
    [40145, 'Wagoner'],
    [40147, 'Washington'],
    [40149, 'Washita'],
    [40151, 'Woods'],
    [40153, 'Woodward'],
    [41000, 'Unknown County or County N/A'],                                                                      
    [41001, 'Baker'],
    [41003, 'Benton'],
    [41005, 'Clackamas'],
    [41007, 'Clatsop'],
    [41009, 'Columbia'],
    [41011, 'Coos'],
    [41013, 'Crook'],
    [41015, 'Curry'],
    [41017, 'Deschutes'],
    [41019, 'Douglas'],
    [41021, 'Gilliam'],
    [41023, 'Grant'],
    [41025, 'Harney'],
    [41027, 'Hood River'],
    [41029, 'Jackson'],
    [41031, 'Jefferson'],
    [41033, 'Josephine'],
    [41035, 'Klamath'],
    [41037, 'Lake'],
    [41039, 'Lane'],
    [41041, 'Lincoln'],
    [41043, 'Linn'],
    [41045, 'Malheur'],
    [41047, 'Marion'],
    [41049, 'Morrow'],
    [41051, 'Multnomah'],
    [41053, 'Polk'],
    [41055, 'Sherman'],
    [41057, 'Tillamook'],
    [41059, 'Umatilla'],
    [41061, 'Union'],
    [41063, 'Wallowa'],
    [41065, 'Wasco'],
    [41067, 'Washington'],
    [41069, 'Wheeler'],
    [41071, 'Yamhill'],
    [42000, 'Unknown County or County N/A'],                                                                      
    [42001, 'Adams'],
    [42003, 'Allegheny'],
    [42005, 'Armstrong'],
    [42007, 'Beaver'],
    [42009, 'Bedford'],
    [42011, 'Berks'],
    [42013, 'Blair'],
    [42015, 'Bradford'],
    [42017, 'Bucks'],
    [42019, 'Butler'],
    [42021, 'Cambria'],
    [42023, 'Cameron'],
    [42025, 'Carbon'],
    [42027, 'Centre'],
    [42029, 'Chester'],
    [42031, 'Clarion'],
    [42033, 'Clearfield'],
    [42035, 'Clinton'],
    [42037, 'Columbia'],
    [42039, 'Crawford'],
    [42041, 'Cumberland'],
    [42043, 'Dauphin'],
    [42045, 'Delaware'],
    [42047, 'Elk'],
    [42049, 'Erie'],
    [42051, 'Fayette'],
    [42053, 'Forest'],
    [42055, 'Franklin'],
    [42057, 'Fulton'],
    [42059, 'Greene'],
    [42061, 'Huntingdon'],
    [42063, 'Indiana'],
    [42065, 'Jefferson'],
    [42067, 'Juniata'],
    [42069, 'Lackawanna'],
    [42071, 'Lancaster'],
    [42073, 'Lawrence'],
    [42075, 'Lebanon'],
    [42077, 'Lehigh'],
    [42079, 'Luzerne'],
    [42081, 'Lycoming'],
    [42083, 'McKean'],
    [42085, 'Mercer'],
    [42087, 'Mifflin'],
    [42089, 'Monroe'],
    [42091, 'Montgomery'],
    [42093, 'Montour'],
    [42095, 'Northampton'],
    [42097, 'Northumberland'],
    [42099, 'Perry'],
    [42101, 'Philadelphia'],
    [42103, 'Pike'],
    [42105, 'Potter'],
    [42107, 'Schuylkill'],
    [42109, 'Snyder'],
    [42111, 'Somerset'],
    [42113, 'Sullivan'],
    [42115, 'Susquehanna'],
    [42117, 'Tioga'],
    [42119, 'Union'],
    [42121, 'Venango'],
    [42123, 'Warren'],
    [42125, 'Washington'],
    [42127, 'Wayne'],
    [42129, 'Westmoreland'],
    [42131, 'Wyoming'],
    [42133, 'York'],
    [44000, 'Unknown County or County N/A'],                                                                      
    [44001, 'Bristol'],
    [44003, 'Kent'],
    [44005, 'Newport'],
    [44007, 'Providence'],
    [44009, 'Washington'],
    [45000, 'Unknown County or County N/A'],                                                                      
    [45001, 'Abbeville'],
    [45003, 'Aiken'],
    [45005, 'Allendale'],
    [45007, 'Anderson'],
    [45009, 'Bamberg'],
    [45011, 'Barnwell'],
    [45013, 'Beaufort'],
    [45015, 'Berkeley'],
    [45017, 'Calhoun'],
    [45019, 'Charleston'],
    [45021, 'Cherokee'],
    [45023, 'Chester'],
    [45025, 'Chesterfield'],
    [45027, 'Clarendon'],
    [45029, 'Colleton'],
    [45031, 'Darlington'],
    [45033, 'Dillon'],
    [45035, 'Dorchester'],
    [45037, 'Edgefield'],
    [45039, 'Fairfield'],
    [45041, 'Florence'],
    [45043, 'Georgetown'],
    [45045, 'Greenville'],
    [45047, 'Greenwood'],
    [45049, 'Hampton'],
    [45051, 'Horry'],
    [45053, 'Jasper'],
    [45055, 'Kershaw'],
    [45057, 'Lancaster'],
    [45059, 'Laurens'],
    [45061, 'Lee'],
    [45063, 'Lexington'],
    [45065, 'McCormick'],
    [45067, 'Marion'],
    [45069, 'Marlboro'],
    [45071, 'Newberry'],
    [45073, 'Oconee'],
    [45075, 'Orangeburg'],
    [45077, 'Pickens'],
    [45079, 'Richland'],
    [45081, 'Saluda'],
    [45083, 'Spartanburg'],
    [45085, 'Sumter'],
    [45087, 'Union'],
    [45089, 'Williamsburg'],
    [45091, 'York'],
    [46000, 'Unknown County or County N/A'],                                                                      
    [46003, 'Aurora'],
    [46005, 'Beadle'],
    [46007, 'Bennett'],
    [46009, 'Bon Homme'],
    [46011, 'Brookings'],
    [46013, 'Brown'],
    [46015, 'Brule'],
    [46017, 'Buffalo'],
    [46019, 'Butte'],
    [46021, 'Campbell'],
    [46023, 'Charles Mix'],
    [46025, 'Clark'],
    [46027, 'Clay'],
    [46029, 'Codington'],
    [46031, 'Corson'],
    [46033, 'Custer'],
    [46035, 'Davison'],
    [46037, 'Day'],
    [46039, 'Deuel'],
    [46041, 'Dewey'],
    [46043, 'Douglas'],
    [46045, 'Edmunds'],
    [46047, 'Fall River'],
    [46049, 'Faulk'],
    [46051, 'Grant'],
    [46053, 'Gregory'],
    [46055, 'Haakon'],
    [46057, 'Hamlin'],
    [46059, 'Hand'],
    [46061, 'Hanson'],
    [46063, 'Harding'],
    [46065, 'Hughes'],
    [46067, 'Hutchinson'],
    [46069, 'Hyde'],
    [46071, 'Jackson'],
    [46073, 'Jerauld'],
    [46075, 'Jones'],
    [46077, 'Kingsbury'],
    [46079, 'Lake'],
    [46081, 'Lawrence'],
    [46083, 'Lincoln'],
    [46085, 'Lyman'],
    [46087, 'McCook'],
    [46089, 'McPherson'],
    [46091, 'Marshall'],
    [46093, 'Meade'],
    [46095, 'Mellette'],
    [46097, 'Miner'],
    [46099, 'Minnehaha'],
    [46101, 'Moody'],
    [46103, 'Pennington'],
    [46105, 'Perkins'],
    [46107, 'Potter'],
    [46109, 'Roberts'],
    [46111, 'Sanborn'],
    [46113, 'Shannon'],
    [46115, 'Spink'],
    [46117, 'Stanley'],
    [46119, 'Sully'],
    [46121, 'Todd'],
    [46123, 'Tripp'],
    [46125, 'Turner'],
    [46127, 'Union'],
    [46129, 'Walworth'],
    [46135, 'Yankton'],
    [46137, 'Ziebach'],
    [47000, 'Unknown County or County N/A'],                                                                      
    [47001, 'Anderson'],
    [47003, 'Bedford'],
    [47005, 'Benton'],
    [47007, 'Bledsoe'],
    [47009, 'Blount'],
    [47011, 'Bradley'],
    [47013, 'Campbell'],
    [47015, 'Cannon'],
    [47017, 'Carroll'],
    [47019, 'Carter'],
    [47021, 'Cheatham'],
    [47023, 'Chester'],
    [47025, 'Claiborne'],
    [47027, 'Clay'],
    [47029, 'Cocke'],
    [47031, 'Coffee'],
    [47033, 'Crockett'],
    [47035, 'Cumberland'],
    [47037, 'Davidson'],
    [47039, 'Decatur'],
    [47041, 'De Kalb'],
    [47043, 'Dickson'],
    [47045, 'Dyer'],
    [47047, 'Fayette'],
    [47049, 'Fentress'],
    [47051, 'Franklin'],
    [47053, 'Gibson'],
    [47055, 'Giles'],
    [47057, 'Grainger'],
    [47059, 'Greene'],
    [47061, 'Grundy'],
    [47063, 'Hamblen'],
    [47065, 'Hamilton'],
    [47067, 'Hancock'],
    [47069, 'Hardeman'],
    [47071, 'Hardin'],
    [47073, 'Hawkins'],
    [47075, 'Haywood'],
    [47077, 'Henderson'],
    [47079, 'Henry'],
    [47081, 'Hickman'],
    [47083, 'Houston'],
    [47085, 'Humphreys'],
    [47087, 'Jackson'],
    [47089, 'Jefferson'],
    [47091, 'Johnson'],
    [47093, 'Knox'],
    [47095, 'Lake'],
    [47097, 'Lauderdale'],
    [47099, 'Lawrence'],
    [47101, 'Lewis'],
    [47103, 'Lincoln'],
    [47105, 'Loudon'],
    [47107, 'McMinn'],
    [47109, 'McNairy'],
    [47111, 'Macon'],
    [47113, 'Madison'],
    [47115, 'Marion'],
    [47117, 'Marshall'],
    [47119, 'Maury'],
    [47121, 'Meigs'],
    [47123, 'Monroe'],
    [47125, 'Montgomery'],
    [47127, 'Moore'],
    [47129, 'Morgan'],
    [47131, 'Obion'],
    [47133, 'Overton'],
    [47135, 'Perry'],
    [47137, 'Pickett'],
    [47139, 'Polk'],
    [47141, 'Putnam'],
    [47143, 'Rhea'],
    [47145, 'Roane'],
    [47147, 'Robertson'],
    [47149, 'Rutherford'],
    [47151, 'Scott'],
    [47153, 'Sequatchie'],
    [47155, 'Sevier'],
    [47157, 'Shelby'],
    [47159, 'Smith'],
    [47161, 'Stewart'],
    [47163, 'Sullivan'],
    [47165, 'Sumner'],
    [47167, 'Tipton'],
    [47169, 'Trousdale'],
    [47171, 'Unicoi'],
    [47173, 'Union'],
    [47175, 'Van Buren'],
    [47177, 'Warren'],
    [47179, 'Washington'],
    [47181, 'Wayne'],
    [47183, 'Weakley'],
    [47185, 'White'],
    [47187, 'Williamson'],
    [47189, 'Wilson'],
    [48000, 'Unknown County or County N/A'],                                                                      
    [48001, 'Anderson'],
    [48003, 'Andrews'],
    [48005, 'Angelina'],
    [48007, 'Aransas'],
    [48009, 'Archer'],
    [48011, 'Armstrong'],
    [48013, 'Atascosa'],
    [48015, 'Austin'],
    [48017, 'Bailey'],
    [48019, 'Bandera'],
    [48021, 'Bastrop'],
    [48023, 'Baylor'],
    [48025, 'Bee'],
    [48027, 'Bell'],
    [48029, 'Bexar'],
    [48031, 'Blanco'],
    [48033, 'Borden'],
    [48035, 'Bosque'],
    [48037, 'Bowie'],
    [48039, 'Brazoria'],
    [48041, 'Brazos'],
    [48043, 'Brewster'],
    [48045, 'Briscoe'],
    [48047, 'Brooks'],
    [48049, 'Brown'],
    [48051, 'Burleson'],
    [48053, 'Burnet'],
    [48055, 'Caldwell'],
    [48057, 'Calhoun'],
    [48059, 'Callahan'],
    [48061, 'Cameron'],
    [48063, 'Camp'],
    [48065, 'Carson'],
    [48067, 'Cass'],
    [48069, 'Castro'],
    [48071, 'Chambers'],
    [48073, 'Cherokee'],
    [48075, 'Childress'],
    [48077, 'Clay'],
    [48079, 'Cochran'],
    [48081, 'Coke'],
    [48083, 'Coleman'],
    [48085, 'Collin'],
    [48087, 'Collingsworth'],
    [48089, 'Colorado'],
    [48091, 'Comal'],
    [48093, 'Comanche'],
    [48095, 'Concho'],
    [48097, 'Cooke'],
    [48099, 'Coryell'],
    [48101, 'Cottle'],
    [48103, 'Crane'],
    [48105, 'Crockett'],
    [48107, 'Crosby'],
    [48109, 'Culberson'],
    [48111, 'Dallam'],
    [48113, 'Dallas'],
    [48115, 'Dawson'],
    [48117, 'Deaf Smith'],
    [48119, 'Delta'],
    [48121, 'Denton'],
    [48123, 'De Witt'],
    [48125, 'Dickens'],
    [48127, 'Dimmit'],
    [48129, 'Donley'],
    [48131, 'Duval'],
    [48133, 'Eastland'],
    [48135, 'Ector'],
    [48137, 'Edwards'],
    [48139, 'Ellis'],
    [48141, 'El Paso'],
    [48143, 'Erath'],
    [48145, 'Falls'],
    [48147, 'Fannin'],
    [48149, 'Fayette'],
    [48151, 'Fisher'],
    [48153, 'Floyd'],
    [48155, 'Foard'],
    [48157, 'Fort Bend'],
    [48159, 'Franklin'],
    [48161, 'Freestone'],
    [48163, 'Frio'],
    [48165, 'Gaines'],
    [48167, 'Galveston'],
    [48169, 'Garza'],
    [48171, 'Gillespie'],
    [48173, 'Glasscock'],
    [48175, 'Goliad'],
    [48177, 'Gonzales'],
    [48179, 'Gray'],
    [48181, 'Grayson'],
    [48183, 'Gregg'],
    [48185, 'Grimes'],
    [48187, 'Guadalupe'],
    [48189, 'Hale'],
    [48191, 'Hall'],
    [48193, 'Hamilton'],
    [48195, 'Hansford'],
    [48197, 'Hardeman'],
    [48199, 'Hardin'],
    [48201, 'Harris'],
    [48203, 'Harrison'],
    [48205, 'Hartley'],
    [48207, 'Haskell'],
    [48209, 'Hays'],
    [48211, 'Hemphill'],
    [48213, 'Henderson'],
    [48215, 'Hidalgo'],
    [48217, 'Hill'],
    [48219, 'Hockley'],
    [48221, 'Hood'],
    [48223, 'Hopkins'],
    [48225, 'Houston'],
    [48227, 'Howard'],
    [48229, 'Hudspeth'],
    [48231, 'Hunt'],
    [48233, 'Hutchinson'],
    [48235, 'Irion'],
    [48237, 'Jack'],
    [48239, 'Jackson'],
    [48241, 'Jasper'],
    [48243, 'Jeff Davis'],
    [48245, 'Jefferson'],
    [48247, 'Jim Hogg'],
    [48249, 'Jim Wells'],
    [48251, 'Johnson'],
    [48253, 'Jones'],
    [48255, 'Karnes'],
    [48257, 'Kaufman'],
    [48259, 'Kendall'],
    [48261, 'Kenedy'],
    [48263, 'Kent'],
    [48265, 'Kerr'],
    [48267, 'Kimble'],
    [48269, 'King'],
    [48271, 'Kinney'],
    [48273, 'Kleberg'],
    [48275, 'Knox'],
    [48277, 'Lamar'],
    [48279, 'Lamb'],
    [48281, 'Lampasas'],
    [48283, 'La Salle'],
    [48285, 'Lavaca'],
    [48287, 'Lee'],
    [48289, 'Leon'],
    [48291, 'Liberty'],
    [48293, 'Limestone'],
    [48295, 'Lipscomb'],
    [48297, 'Live Oak'],
    [48299, 'Llano'],
    [48301, 'Loving'],
    [48303, 'Lubbock'],
    [48305, 'Lynn'],
    [48307, 'McCulloch'],
    [48309, 'McLennan'],
    [48311, 'McMullen'],
    [48313, 'Madison'],
    [48315, 'Marion'],
    [48317, 'Martin'],
    [48319, 'Mason'],
    [48321, 'Matagorda'],
    [48323, 'Maverick'],
    [48325, 'Medina'],
    [48327, 'Menard'],
    [48329, 'Midland'],
    [48331, 'Milam'],
    [48333, 'Mills'],
    [48335, 'Mitchell'],
    [48337, 'Montague'],
    [48339, 'Montgomery'],
    [48341, 'Moore'],
    [48343, 'Morris'],
    [48345, 'Motley'],
    [48347, 'Nacogdoches'],
    [48349, 'Navarro'],
    [48351, 'Newton'],
    [48353, 'Nolan'],
    [48355, 'Nueces'],
    [48357, 'Ochiltree'],
    [48359, 'Oldham'],
    [48361, 'Orange'],
    [48363, 'Palo Pinto'],
    [48365, 'Panola'],
    [48367, 'Parker'],
    [48369, 'Parmer'],
    [48371, 'Pecos'],
    [48373, 'Polk'],
    [48375, 'Potter'],
    [48377, 'Presidio'],
    [48379, 'Rains'],
    [48381, 'Randall'],
    [48383, 'Reagan'],
    [48385, 'Real'],
    [48387, 'Red River'],
    [48389, 'Reeves'],
    [48391, 'Refugio'],
    [48393, 'Roberts'],
    [48395, 'Robertson'],
    [48397, 'Rockwall'],
    [48399, 'Runnels'],
    [48401, 'Rusk'],
    [48403, 'Sabine'],
    [48405, 'San Augustine'],
    [48407, 'San Jacinto'],
    [48409, 'San Patricio'],
    [48411, 'San Saba'],
    [48413, 'Schleicher'],
    [48415, 'Scurry'],
    [48417, 'Shackelford'],
    [48419, 'Shelby'],
    [48421, 'Sherman'],
    [48423, 'Smith'],
    [48425, 'Somervell'],
    [48427, 'Starr'],
    [48429, 'Stephens'],
    [48431, 'Sterling'],
    [48433, 'Stonewall'],
    [48435, 'Sutton'],
    [48437, 'Swisher'],
    [48439, 'Tarrant'],
    [48441, 'Taylor'],
    [48443, 'Terrell'],
    [48445, 'Terry'],
    [48447, 'Throckmorton'],
    [48449, 'Titus'],
    [48451, 'Tom Green'],
    [48453, 'Travis'],
    [48455, 'Trinity'],
    [48457, 'Tyler'],
    [48459, 'Upshur'],
    [48461, 'Upton'],
    [48463, 'Uvalde'],
    [48465, 'Val Verde'],
    [48467, 'Van Zandt'],
    [48469, 'Victoria'],
    [48471, 'Walker'],
    [48473, 'Waller'],
    [48475, 'Ward'],
    [48477, 'Washington'],
    [48479, 'Webb'],
    [48481, 'Wharton'],
    [48483, 'Wheeler'],
    [48485, 'Wichita'],
    [48487, 'Wilbarger'],
    [48489, 'Willacy'],
    [48491, 'Williamson'],
    [48493, 'Wilson'],
    [48495, 'Winkler'],
    [48497, 'Wise'],
    [48499, 'Wood'],
    [48501, 'Yoakum'],
    [48503, 'Young'],
    [48505, 'Zapata'],
    [48507, 'Zavala'],
    [49000, 'Unknown County or County N/A'],                                                                      
    [49001, 'Beaver'],
    [49003, 'Box Elder'],
    [49005, 'Cache'],
    [49007, 'Carbon'],
    [49009, 'Daggett'],
    [49011, 'Davis'],
    [49013, 'Duchesne'],
    [49015, 'Emery'],
    [49017, 'Garfield'],
    [49019, 'Grand'],
    [49021, 'Iron'],
    [49023, 'Juab'],
    [49025, 'Kane'],
    [49027, 'Millard'],
    [49029, 'Morgan'],
    [49031, 'Piute'],
    [49033, 'Rich'],
    [49035, 'Salt Lake'],
    [49037, 'San Juan'],
    [49039, 'Sanpete'],
    [49041, 'Sevier'],
    [49043, 'Summit'],
    [49045, 'Tooele'],
    [49047, 'Uintah'],
    [49049, 'Utah'],
    [49051, 'Wasatch'],
    [49053, 'Washington'],
    [49055, 'Wayne'],
    [49057, 'Weber'],
    [50000, 'Unknown County or County N/A'],                                                                      
    [50001, 'Addison'],
    [50003, 'Bennington'],
    [50005, 'Caledonia'],
    [50007, 'Chittenden'],
    [50009, 'Essex'],
    [50011, 'Franklin'],
    [50013, 'Grand Isle'],
    [50015, 'Lamoille'],
    [50017, 'Orange'],
    [50019, 'Orleans'],
    [50021, 'Rutland'],
    [50023, 'Washington'],
    [50025, 'Windham'],
    [50027, 'Windsor'],
    [51000, 'Unknown County or County N/A'],                                                                      
    [51001, 'Accomack'],
    [51003, 'Albemarle'],
    [51005, 'Alleghany'],
    [51007, 'Amelia'],
    [51009, 'Amherst'],
    [51011, 'Appomattox'],
    [51013, 'Arlington'],
    [51015, 'Augusta'],
    [51017, 'Bath'],
    [51019, 'Bedford'],
    [51021, 'Bland'],
    [51023, 'Botetourt'],
    [51025, 'Brunswick'],
    [51027, 'Buchanan'],
    [51029, 'Buckingham'],
    [51031, 'Campbell'],
    [51033, 'Caroline'],
    [51035, 'Carroll'],
    [51036, 'Charles City'],
    [51037, 'Charlotte'],
    [51041, 'Chesterfield'],
    [51043, 'Clarke'],
    [51045, 'Craig'],
    [51047, 'Culpeper'],
    [51049, 'Cumberland'],
    [51051, 'Dickenson'],
    [51053, 'Dinwiddie'],
    [51057, 'Essex'],
    [51059, 'Fairfax'],
    [51061, 'Fauquier'],
    [51063, 'Floyd'],
    [51065, 'Fluvanna'],
    [51067, 'Franklin'],
    [51069, 'Frederick'],
    [51071, 'Giles'],
    [51073, 'Gloucester'],
    [51075, 'Goochland'],
    [51077, 'Grayson'],
    [51079, 'Greene'],
    [51081, 'Greensville'],
    [51083, 'Halifax'],
    [51085, 'Hanover'],
    [51087, 'Henrico'],
    [51089, 'Henry'],
    [51091, 'Highland'],
    [51093, 'Isle of Wight'],
    [51095, 'James City'],
    [51097, 'King and Queen'],
    [51099, 'King George'],
    [51101, 'King William'],
    [51103, 'Lancaster'],
    [51105, 'Lee'],
    [51107, 'Loudoun'],
    [51109, 'Louisa'],
    [51111, 'Lunenburg'],
    [51113, 'Madison'],
    [51115, 'Mathews'],
    [51117, 'Mecklenburg'],
    [51119, 'Middlesex'],
    [51121, 'Montgomery'],
    [51125, 'Nelson'],
    [51127, 'New Kent'],
    [51131, 'Northampton'],
    [51133, 'Northumberland'],
    [51135, 'Nottoway'],
    [51137, 'Orange'],
    [51139, 'Page'],
    [51141, 'Patrick'],
    [51143, 'Pittsylvania'],
    [51145, 'Powhatan'],
    [51147, 'Prince Edward'],
    [51149, 'Prince George'],
    [51153, 'Prince William'],
    [51155, 'Pulaski'],
    [51157, 'Rappahannock'],
    [51159, 'Richmond'],
    [51161, 'Roanoke'],
    [51163, 'Rockbridge'],
    [51165, 'Rockingham'],
    [51167, 'Russell'],
    [51169, 'Scott'],
    [51171, 'Shenandoah'],
    [51173, 'Smyth'],
    [51175, 'Southampton'],
    [51177, 'Spotsylvania'],
    [51179, 'Stafford'],
    [51181, 'Surry'],
    [51183, 'Sussex'],
    [51185, 'Tazewell'],
    [51187, 'Warren'],
    [51191, 'Washington'],
    [51193, 'Westmoreland'],
    [51195, 'Wise'],
    [51197, 'Wythe'],
    [51199, 'York'],
    [51510, 'Alexandria'],
    [51515, 'Bedford City'],
    [51520, 'Bristol'],
    [51530, 'Buena Vista'],
    [51540, 'Charlottesville'],
    [51550, 'Chesapeake'],
    [51560, 'Clifton Forge'],
    [51570, 'Colonial Heights'],
    [51580, 'Covington'],
    [51590, 'Danville'],
    [51595, 'Emporia'],
    [51600, 'Fairfax City'],
    [51610, 'Falls Chruch'],
    [51620, 'Franklin City'],
    [51630, 'Fredericksburg'],
    [51640, 'Galax'],
    [51650, 'Hampton'],
    [51660, 'Harrisonburg'],
    [51670, 'Hopewell'],
    [51678, 'Lexington'],
    [51680, 'Lynchburg'],
    [51683, 'Manassas City'],
    [51685, 'Manassas Park City'],
    [51690, 'Martinsville'],
    [51700, 'Newport News'],
    [51710, 'Norfolk'],
    [51720, 'Norton'],
    [51730, 'Petersburg'],
    [51735, 'Poquoson City'],
    [51740, 'Portsmouth'],
    [51750, 'Radford'],
    [51760, 'Richmond City'],
    [51770, 'Roanoke City'],
    [51775, 'Salem'],
    [51780, 'South Boston'],
    [51790, 'Staunton'],
    [51800, 'Suffolk'],
    [51810, 'Virginia Beach'],
    [51820, 'Waynesboro'],
    [51830, 'Williamsburg'],
    [51840, 'Winchester'],
    [53000, 'Unknown County or County N/A'],                                                                      
    [53001, 'Adams'],
    [53003, 'Asotin'],
    [53005, 'Benton'],
    [53007, 'Chelan'],
    [53009, 'Clallam'],
    [53011, 'Clark'],
    [53013, 'Columbia'],
    [53015, 'Cowlitz'],
    [53017, 'Douglas'],
    [53019, 'Ferry'],
    [53021, 'Franklin'],
    [53023, 'Garfield'],
    [53025, 'Grant'],
    [53027, 'Grays Harbor'],
    [53029, 'Island'],
    [53031, 'Jefferson'],
    [53033, 'King'],
    [53035, 'Kitsap'],
    [53037, 'Kittitas'],
    [53039, 'Klickitat'],
    [53041, 'Lewis'],
    [53043, 'Lincoln'],
    [53045, 'Mason'],
    [53047, 'Okanogan'],
    [53049, 'Pacific'],
    [53051, 'Pend Oreille'],
    [53053, 'Pierce'],
    [53055, 'San Juan'],
    [53057, 'Skagit'],
    [53059, 'Skamania'],
    [53061, 'Snohomish'],
    [53063, 'Spokane'],
    [53065, 'Stevens'],
    [53067, 'Thurston'],
    [53069, 'Wahkiakum'],
    [53071, 'Walla Walla'],
    [53073, 'Whatcom'],
    [53075, 'Whitman'],
    [53077, 'Yakima'],
    [54000, 'Unknown County or County N/A'],                                                                      
    [54001, 'Barbour'],
    [54003, 'Berkeley'],
    [54005, 'Boone'],
    [54007, 'Braxton'],
    [54009, 'Brooke'],
    [54011, 'Cabell'],
    [54013, 'Calhoun'],
    [54015, 'Clay'],
    [54017, 'Doddridge'],
    [54019, 'Fayette'],
    [54021, 'Gilmer'],
    [54023, 'Grant'],
    [54025, 'Greenbrier'],
    [54027, 'Hampshire'],
    [54029, 'Hancock'],
    [54031, 'Hardy'],
    [54033, 'Harrison'],
    [54035, 'Jackson'],
    [54037, 'Jefferson'],
    [54039, 'Kanawha'],
    [54041, 'Lewis'],
    [54043, 'Lincoln'],
    [54045, 'Logan'],
    [54047, 'McDowell'],
    [54049, 'Marion'],
    [54051, 'Marshall'],
    [54053, 'Mason'],
    [54055, 'Mercer'],
    [54057, 'Mineral'],
    [54059, 'Mingo'],
    [54061, 'Monongalia'],
    [54063, 'Monroe'],
    [54065, 'Morgan'],
    [54067, 'Nicholas'],
    [54069, 'Ohio'],
    [54071, 'Pendleton'],
    [54073, 'Pleasants'],
    [54075, 'Pocahontas'],
    [54077, 'Preston'],
    [54079, 'Putnam'],
    [54081, 'Raleigh'],
    [54083, 'Randolph'],
    [54085, 'Ritchie'],
    [54087, 'Roane'],
    [54089, 'Summers'],
    [54091, 'Taylor'],
    [54093, 'Tucker'],
    [54095, 'Tyler'],
    [54097, 'Upshur'],
    [54099, 'Wayne'],
    [54101, 'Webster'],
    [54103, 'Wetzel'],
    [54105, 'Wirt'],
    [54107, 'Wood'],
    [54109, 'Wyoming'],
    [55000, 'Unknown County or County N/A'],                                                                      
    [55001, 'Adams'],
    [55003, 'Ashland'],
    [55005, 'Barron'],
    [55007, 'Bayfield'],
    [55009, 'Brown'],
    [55011, 'Buffalo'],
    [55013, 'Burnett'],
    [55015, 'Calumet'],
    [55017, 'Chippewa'],
    [55019, 'Clark'],
    [55021, 'Columbia'],
    [55023, 'Crawford'],
    [55025, 'Dane'],
    [55027, 'Dodge'],
    [55029, 'Door'],
    [55031, 'Douglas'],
    [55033, 'Dunn'],
    [55035, 'Eau Claire'],
    [55037, 'Florence'],
    [55039, 'Fond Du Lac'],
    [55041, 'Forest'],
    [55043, 'Grant'],
    [55045, 'Green'],
    [55047, 'Green Lake'],
    [55049, 'Iowa'],
    [55051, 'Iron'],
    [55053, 'Jackson'],
    [55055, 'Jefferson'],
    [55057, 'Juneau'],
    [55059, 'Kenosha'],
    [55061, 'Kewaunee'],
    [55063, 'La Crosse'],
    [55065, 'Lafayette'],
    [55067, 'Langlade'],
    [55069, 'Lincoln'],
    [55071, 'Manitowoc'],
    [55073, 'Marathon'],
    [55075, 'Marinette'],
    [55077, 'Marquette'],
    [55078, 'Menominee'],
    [55079, 'Milwaukee'],
    [55081, 'Monroe'],
    [55083, 'Oconto'],
    [55085, 'Oneida'],
    [55087, 'Outagamie'],
    [55089, 'Ozaukee'],
    [55091, 'Pepin'],
    [55093, 'Pierce'],
    [55095, 'Polk'],
    [55097, 'Portage'],
    [55099, 'Price'],
    [55101, 'Racine'],
    [55103, 'Richland'],
    [55105, 'Rock'],
    [55107, 'Rusk'],
    [55109, 'St. Croix'],
    [55111, 'Sauk'],
    [55113, 'Sawyer'],
    [55115, 'Shawano'],
    [55117, 'Sheboygan'],
    [55119, 'Taylor'],
    [55121, 'Trempealeau'],
    [55123, 'Vernon'],
    [55125, 'Vilas'],
    [55127, 'Walworth'],
    [55129, 'Washburn'],
    [55131, 'Washington'],
    [55133, 'Waukesha'],
    [55135, 'Waupaca'],
    [55137, 'Waushara'],
    [55139, 'Winnebago'],
    [55141, 'Wood'],
    [56000, 'Unknown County or County N/A'],                                                                      
    [56001, 'Albany'],
    [56003, 'Big Horn'],
    [56005, 'Campbell'],
    [56007, 'Carbon'],
    [56009, 'Converse'],
    [56011, 'Crook'],
    [56013, 'Fremont'],
    [56015, 'Goshen'],
    [56017, 'Hot Springs'],
    [56019, 'Johnson'],
    [56021, 'Laramie'],
    [56023, 'Lincoln'],
    [56025, 'Natrona'],
    [56027, 'Niobrara'],
    [56029, 'Park'],
    [56031, 'Platte'],
    [56033, 'Sheridan'],
    [56035, 'Sublette'],
    [56037, 'Sweetwater'],
    [56039, 'Teton'],
    [56041, 'Uinta'],
    [56043, 'Washakie'],
    [56045, 'Weston'],
]

#---------------#
# Sub-locations #
#---------------#
sys.stderr.write("Processing sub-locations.\n")
subLocations = [
    'Left-Fish Ladder',
    'Right-Fish Ladder',
    'Gate 1',
    'Gate 2',
    'Downstream-Gage',
    'Downstream',
    'Spillway',
    'Spillway-Gate 1',
    'Spillway-Gate 2',
    'Turbine 1',
    'Turbine 2',
]


#---------#
# Offices #
#---------#
sys.stderr.write("Processing offices.\n")
offices = [
# **WARNING!! DO NOT CHANGE The "ofc code" number!! You can add a new office to the
#                     bottom of the list, but it must have a new unique number.
#                     The max ofc code is 999.
#   **ofc**                                                                               
#     code   ofc    longName                                        reportTo  dbHost  eroc 
#     ----   ---    ----------------------------------------------  --------  ------  ---- 
    [   0,  'UNK',  'Corps of Engineers Office Unknown',            '',       '',     '00'],
    [   1,  'HQ',   'Headquarters, U.S. Army Corps of Engineers',   '',       'HQ',   'S0'],
    [   2,  'LRD',  'Great Lakes and Ohio River Division',          'HQ',     'LRD',  'H0'],
    [   3,  'LRDG', 'Great Lakes Region',                           'LRD',    'LRDG', 'H8'],
    [   4,  'LRC',  'Chicago District',                             'LRDG',   'LRC',  'H6'],
    [   5,  'LRE',  'Detroit District',                             'LRDG',   'LRE',  'H7'],
    [   6,  'LRB',  'Buffalo District',                             'LRDG',   'LRB',  'H5'],
    [   7,  'LRDO', 'Ohio River Region',                            'LRD',    'LRDO', 'H0'],
    [   8,  'LRH',  'Huntington District',                          'LRDO',   'LRH',  'H1'],
    [   9,  'LRL',  'Louisville District',                          'LRDO',   'LRL',  'H2'],
    [  10,  'LRN',  'Nashville District',                           'LRDO',   'LRN',  'H3'],
    [  11,  'LRP',  'Pittsburgh District',                          'LRDO',   'LRP',  'H4'],
    [  12,  'MVD',  'Mississippi Valley Division',                  'HQ',     'MVD',  'B0'],
    [  13,  'MVK',  'Vicksburg District',                           'MVD',    'MVK',  'B4'],
    [  14,  'MVM',  'Memphis District',                             'MVD',    'MVM',  'B1'],
    [  15,  'MVN',  'New Orleans District',                         'MVD',    'MVN',  'B2'],
    [  16,  'MVP',  'St. Paul District',                            'MVD',    'MVP',  'B6'],
    [  17,  'MVR',  'Rock Island District',                         'MVD',    'MVR',  'B5'],
    [  18,  'MVS',  'St. Louis District',                           'MVD',    'MVS',  'B3'],
    [  19,  'NAD',  'North Atlantic Division',                      'HQ',     'NAD',  'E0'],
    [  20,  'NAB',  'Baltimore District',                           'NAD',    'NAB',  'E1'],
    [  21,  'NAE',  'New England District',                         'NAD',    'NAE',  'E6'],
    [  22,  'NAN',  'New York District',                            'NAD',    'NAN',  'E3'],
    [  23,  'NAO',  'Norfolk District',                             'NAD',    'NAO',  'E4'],
    [  24,  'NAP',  'Philadelphia District',                        'NAD',    'NAP',  'E5'],
    [  25,  'NWD',  'Northwestern Division',                        'HQ',     'NWDP', 'G0'],
    [  26,  'NWDP', 'Pacific Northwest Region',                     'NWD',    'NWDP', 'G0'],
    [  27,  'NWP',  'Portland District',                            'NWDP',   'NWP', 'G2'],
    [  28,  'NWS',  'Seattle District',                             'NWDP',   'NWS', 'G3'],
    [  29,  'NWW',  'Walla Walla District',                         'NWDP',   'NWW', 'G4'],
    [  30,  'NWDM', 'Missouri River Region',                        'NWD',    'NWDM', 'G7'],
    [  31,  'NWK',  'Kansas City District',                         'NWDM',   'NWK',  'G5'],
    [  32,  'NWO',  'Omaha District',                               'NWDM',   'NWO',  'G6'],
    [  33,  'POD',  'Pacific Ocean Division',                       'HQ',     'POD',  'J0'],
    [  34,  'POA',  'Alaska District',                              'POD',    'POA',  'J4'],
    [  35,  'POH',  'Hawaii District',                              'POD',    'POH',  'J3'],
    [  36,  'SAD',  'South Atlantic Division',                      'HQ',     'SAD',  'K0'],
    [  37,  'SAC',  'Charleston District',                          'SAD',    'SAC',  'K2'],
    [  38,  'SAJ',  'Jacksonville District',                        'SAD',    'SAJ',  'K3'],
    [  39,  'SAM',  'Mobile District',                              'SAD',    'SAM',  'K5'],
    [  40,  'SAS',  'Savannah District',                            'SAD',    'SAS',  'K6'],
    [  41,  'SAW',  'Wilmington District',                          'SAD',    'SAW',  'K7'],
    [  42,  'SPD',  'South Pacific Division',                       'HQ',     'SPD',  'L0'],
    [  43,  'SPA',  'Albuquerque District',                         'SPD',    'SPA',  'L4'],
    [  44,  'SPK',  'Sacramento District',                          'SPD',    'SPK',  'L2'],
    [  45,  'SPL',  'Los Angeles District',                         'SPD',    'SPL',  'L1'],
    [  46,  'SPN',  'San Francisco District',                       'SPD',    'SPN',  'L3'],
    [  47,  'SWD',  'Southwestern Division',                        'HQ',     'SWD',  'M0'],
    [  48,  'SWF',  'Fort Worth District',                          'SWD',    'SWF',  'M2'],
    [  49,  'SWG',  'Galveston District',                           'SWD',    'SWG',  'M3'],
    [  50,  'SWL',  'Little Rock District',                         'SWD',    'SWL',  'M4'],
    [  51,  'SWT',  'Tulsa District',                               'SWD',    'SWT',  'M5'],
    [  52,  'LCRA', 'Lower Colorado River Authority',               '',       'LCRA', 'Z0'],
    [  53,  'CWMS', 'All CWMS Offices',                             '',       '',     'X0'],
    [  54,  'ERD',  'Engineer Research and Development Center',     'HQ',     'ERD',  'U0'],
    [  55,  'CRREL','Cold Regions Research and Engineering Lab',    'ERD',    'CRREL','U4'],
    [  56,  'CHL',  'Coastal and Hydraulics Laboratory',            'ERD',    'CHL',  'U1'],
    [  57,  'CERL', 'Construction Engineering Research Laboratory', 'ERD',    'CERL', 'U2'],
    [  58,  'EL',   'Environmental Laboratory',                     'ERD',    'EL',   'U3'],
    [  59,  'GSL',  'Geotechnical and Structures Laboratory',       'ERD',    'GSL',  'U5'],
    [  60,  'ITL',  'Information Technology Laboratory',            'ERD',    'ITL',  'U6'],
    [  61,  'TEC',  'Topographic Engineering Center',               'ERD',    'TEC',  'U7'],
    [  62,  'IWR',  'Institute for Water Resources',                'HQ',     'IWR',  'Q1'],
    [  63,  'NDC',  'Navigation Data Center',                       'IWR',    'NDC',  'Q2'],
    [  64,  'HEC',  'Hydrologic Engineering Cennter',               'IWR',    'HEC',  'Q0'],
    [  65,  'WCSC', 'Waterborne Commerce Statistics Center',        'IWR',    'WCSC', 'Q3'],
    [  66,  'CPC',  'Central Processing Center',                    '',       'CPC',  'X1'],
    [  67,  'WPC',  'Western Processing Center',                    '',       'WPC',  'X2'],
]

#-----------#
# Intervals #
#-----------#
sys.stderr.write("Processing intervals.\n")
intervals = [
    [29,    '0',             0,'Irregular recurrence interval'            ],
    [31,     '~1Minute',       0,'Local time irregular: expected recurrence interval of 1 minute'  ],
    [32,     '~2Minutes',      0,'Local time irregular: expected recurrence interval of 2 minutes' ],
    [33,     '~3Minutes',      0,'Local time irregular: expected recurrence interval of 3 minutes' ],
    [34,     '~4Minutes',      0,'Local time irregular: expected recurrence interval of 4 minutes' ],
    [35,     '~5Minutes',      0,'Local time irregular: expected recurrence interval of 5 minutes' ],
    [36,     '~6Minutes',      0,'Local time irregular: expected recurrence interval of 6 minutes' ],
    [37,     '~8Minutes',      0,'Local time irregular: expected recurrence interval of 8 minutes' ],
    [38,    '~10Minutes',     0,'Local time irregular: expected recurrence interval of 10 minutes'],
    [39,     '~12Minutes',     0,'Local time irregular: expected recurrence interval of 12 minutes'],
    [40,     '~15Minutes',     0,'Local time irregular: expected recurrence interval of 15 minutes'],
    [41,    '~20Minutes',     0,'Local time irregular: expected recurrence interval of 20 minutes'],
    [42,    '~30Minutes',     0,'Local time irregular: expected recurrence interval of 30 minutes'],
    [43,    '~1Hour',         0,'Local time irregular: expected recurrence interval of 1 hour'    ],
    [44,    '~2Hours',        0,'Local time irregular: expected recurrence interval of 2 hours'   ],
    [45,    '~3Hours',        0,'Local time irregular: expected recurrence interval of 3 hours'   ],
    [46,    '~4Hours',        0,'Local time irregular: expected recurrence interval of 4 hours'   ],
    [47,    '~6Hours',        0,'Local time irregular: expected recurrence interval of 6 hours'   ],
    [48,    '~8Hours',        0,'Local time irregular: expected recurrence interval of 8 hours'   ],
    [49,    '~12Hours',       0,'Local time irregular: expected recurrence interval of 12 hours'  ],
    [50,    '~1Day',          0,'Local time irregular: expected recurrence interval of 1 day'     ],
    [51,    '~2Days',         0,'Local time irregular: expected recurrence interval of 2 days'    ],
    [52,    '~3Days',         0,'Local time irregular: expected recurrence interval of 3 days'    ],
    [53,    '~4Days',         0,'Local time irregular: expected recurrence interval of 4 days'    ],
    [54,    '~5Days',         0,'Local time irregular: expected recurrence interval of 5 days'    ],
    [55,    '~6Days',         0,'Local time irregular: expected recurrence interval of 6 days'    ],
    [56,    '~1Week',         0,'Local time irregular: expected recurrence interval of 1 week'    ],
    [57,    '~1Month',        0,'Local time irregular: expected recurrence interval of 1 month'   ],
    [58,    '~1Year',         0,'Local time irregular: expected recurrence interval of 1 year'    ],
    [59,    '~1Decade',       0,'Local time irregular: expected recurrence interval of 1 decade'  ],
    [1,     '1Minute',       1,'Regular recurrence interval of 1 minute'  ],
    [2,     '2Minutes',      2,'Regular recurrence interval of 2 minutes' ],
    [3,     '3Minutes',      3,'Regular recurrence interval of 3 minutes' ],
    [4,     '4Minutes',      4,'Regular recurrence interval of 4 minutes' ],
    [5,     '5Minutes',      5,'Regular recurrence interval of 5 minutes' ],
    [6,     '6Minutes',      6,'Regular recurrence interval of 6 minutes' ],
    [7,     '8Minutes',      8,'Regular recurrence interval of 8 minutes' ],
    [30,    '10Minutes',    10,'Regular recurrence interval of 10 minutes'],
    [8,     '12Minutes',    12,'Regular recurrence interval of 12 minutes'],
    [9,     '15Minutes',    15,'Regular recurrence interval of 15 minutes'],
    [10,    '20Minutes',    20,'Regular recurrence interval of 20 minutes'],
    [11,    '30Minutes',    30,'Regular recurrence interval of 30 minutes'],
    [12,    '1Hour',        60,'Regular recurrence interval of 1 hour'    ],
    [13,    '2Hours',      120,'Regular recurrence interval of 2 hours'   ],
    [14,    '3Hours',      180,'Regular recurrence interval of 3 hours'   ],
    [15,    '4Hours',      240,'Regular recurrence interval of 4 hours'   ],
    [16,    '6Hours',      360,'Regular recurrence interval of 6 hours'   ],
    [17,    '8Hours',      480,'Regular recurrence interval of 8 hours'   ],
    [18,    '12Hours'     ,720,'Regular recurrence interval of 12 hours'  ],
    [19,    '1Day',       1440,'Regular recurrence interval of 1 day'     ],
    [20,    '2Days',      2880,'Regular recurrence interval of 2 days'    ],
    [21,    '3Days',      4320,'Regular recurrence interval of 3 days'    ],
    [22,    '4Days',      5760,'Regular recurrence interval of 4 days'    ],
    [23,    '5Days',      7200,'Regular recurrence interval of 5 days'    ],
    [24,    '6Days',      8640,'Regular recurrence interval of 6 days'    ],
    [25,    '1Week',     10080,'Regular recurrence interval of 1 week'    ],
    [26,    '1Month',    43200,'Regular recurrence interval of 1 month'   ],
    [27,    '1Year',    525600,'Regular recurrence interval of 1 year'    ],
    [28,    '1Decade', 5256000,'Regular recurrence interval of 1 decade'  ],
]

#-----------#
# Durations #
#-----------#
sys.stderr.write("Processing durations.\n")
durations = [
    [1,     '1Minute',      1,  'Measurement applies over 1 minute, time stamped at period end'],
    [2,     '2Minutes',     2,  'Measurement applies over 2 minutes, time stamped at period end'],
    [3,     '3Minutes',     3,  'Measurement applies over 3 minutes, time stamped at period end'],
    [4,     '4Minutes',     4,  'Measurement applies over 4 minutes, time stamped at period end'],
    [5,     '5Minutes',     5,  'Measurement applies over 5 minutes, time stamped at period end'],
    [6,     '6Minutes',     6,  'Measurement applies over 6 minutes, time stamped at period end'],
    [7,     '8Minutes',     8,  'Measurement applies over 8 minutes, time stamped at period end'],
    [8,     '12Minutes',    12, 'Measurement applies over 12 minutes, time stamped at period end'],
    [9,     '15Minutes',    15, 'Measurement applies over 15 minutes, time stamped at period end'],
    [10,    '20Minutes',    20, 'Measurement applies over 20 minutes, time stamped at period end'],
    [11,    '30Minutes',    30, 'Measurement applies over 30 minutes, time stamped at period end'],
    [12,    '1Hour',        60, 'Measurement applies over 1 hour, time stamped at period end'],
    [13,    '2Hours',       120,    'Measurement applies over 2 hours, time stamped at period end'],
    [14,    '3Hours',       180,    'Measurement applies over 3 hours, time stamped at period end'],
    [15,    '4Hours',       240,    'Measurement applies over 4 hours, time stamped at period end'],
    [16,    '6Hours',       360,    'Measurement applies over 6 hours, time stamped at period end'],
    [17,    '8Hours',       480,    'Measurement applies over 8 hours, time stamped at period end'],
    [18,    '12Hours',      720,    'Measurement applies over 12 hours, time stamped at period end'],
    [19,    '1Day',         1440,   'Measurement applies over 1 day, time stamped at period end'],
    [20,    '2Days',        2880,   'Measurement applies over 2 days, time stamped at period end'],
    [21,    '3Days',        4320,   'Measurement applies over 3 days, time stamped at period end'],
    [22,    '4Days',        5760,   'Measurement applies over 4 days, time stamped at period end'],
    [23,    '5Days',        7200,   'Measurement applies over 5 days, time stamped at period end'],
    [24,    '6Days',        8640,   'Measurement applies over 6 days, time stamped at period end'],
    [25,    '1Week',        10080,  'Measurement applies over 1 week, time stamped at period end'],
    [26,    '1Month',       43200,  'Measurement applies over 1 month, time stamped at period end'],
    [27,    '1Year',        525600, 'Measurement applies over 1 year, time stamped at period end'],
    [28,    '1Decade',      5256000,    'Measurement applies over 1 decade, time stamped at period end'],
    [29,    '0',            0,  'Measurement applies intantaneously at time stamp'],
    [30,    '1MinuteBOP',   1,  'Measurement applies over 1 minute, time stamped at period beginning'],
    [31,    '2MinutesBOP',  2,  'Measurement applies over 2 minutes, time stamped at period beginning'],
    [32,    '3MinutesBOP',  3,  'Measurement applies over 3 minutes, time stamped at period beginning'],
    [33,    '4MinutesBOP',  4,  'Measurement applies over 4 minutes, time stamped at period beginning'],
    [34,    '5MinutesBOP',  5,  'Measurement applies over 5 minutes, time stamped at period beginning'],
    [35,    '6MinutesBOP',  6,  'Measurement applies over 1 minutes, time stamped at period beginning'],
    [36,    '8MinutesBOP',  8,  'Measurement applies over 8 minutes, time stamped at period beginning'],
    [37,    '12MinutesBOP', 12, 'Measurement applies over 12 minutes, time stamped at period beginning'],
    [38,    '15MinutesBOP', 15, 'Measurement applies over 15 minutes, time stamped at period beginning'],
    [39,    '20MinutesBOP', 20, 'Measurement applies over 20 minutes, time stamped at period beginning'],
    [40,    '30MinutesBOP', 30, 'Measurement applies over 30 minutes, time stamped at period beginning'],
    [41,    '1HourBOP',     60, 'Measurement applies over 1 hour, time stamped at period beginnng'],
    [42,    '2HoursBOP',    120,    'Measurement applies over 2 hours, time stamped at period beginning'],
    [43,    '3HoursBOP',    180,    'Measurement applies over 3 hours, time stamped at period beginning'],
    [44,    '4HoursBOP',    240,    'Measurement applies over 4 hours, time stamped at period beginning'],
    [45,    '6HoursBOP',    360,    'Measurement applies over 6 hours, time stamped at period beginning'],
    [46,    '8HoursBOP',    480,    'Measurement applies over 8 hours, time stamped at period beginning'],
    [47,    '12HoursBOP',   720,    'Measurement applies over 12 hours, time stamped at period beginning'],
    [49,    '2DaysBOP',     2880,   'Measurement applies over 2 days, time stamped at period beginning'],
    [50,    '3DaysBOP',     4320,   'Measurement applies over 3 days, time stamped at period beginning'],
    [51,    '4DaysBOP',     5760,   'Measurement applies over 4 days, time stamped at period beginning'],
    [52,    '5DaysBOP',     7200,   'Measurement applies over 5 days, time stamped at period beginning'],
    [53,    '6DaysBOP',     8640,   'Measurement applies over 6 days, time stamped at period beginning'],
    [54,    '1WeekBOP',     10080,  'Measurement applies over 1 week, time stamped at period beginning'],
    [55,    '1MonthBOP',    43200,  'Measurement applies over 1 month, time stamped at period beginning'],
    [56,    '1YearBOP',     525600, 'Measurement applies over 1 year, time stamped at period beginning'],
    [57,    '1DecadeBOP',   5256000,    'Measurement applies over 1 decade, time stamped at period beginning'],
    [58,    '10Minutes',    10, 'Measurement applies over 10 minutes, time stamped at period end'],
    [59,    '10MinutesBOP', 10, 'Measurement applies over 10 minutes, time stamped at period beginning']
]

#---------------------#
# Abstract Parameters #
#---------------------#
sys.stderr.write("Processing abstract parameters.\n")
abstractParams = [
    "Angle",
    "Angular Speed",
    "Area",
    "Areal Volume Rate",
    "Conductance",
    "Conductivity",
    "Count",
    "Currency",
    "Elapsed Time",
    "Electromotive Potential",
    "Energy",
    "Force",
    "Hydrogen Ion Concentration Index",
    "Irradiance",
    "Irradiation",
    "Length",
    "Linear Speed",
    "Mass Concentration",
    "None",
    "Phase Change Rate Index",
    "Power",
    "Pressure",
    "Temperature",
    "Turbidity",
    "Volume",
    "Volume Rate",
]

#-------#
# Units #
#-------#
sys.stderr.write("Processing static unit definitions.\n")
unitDefs = [
#                                                       UNIT
#    ABSTRACT PARAMETER                  UNIT ID        SYSTEM  NAME                             DESCRIPTION
#    ----------------------------------- -------------- ------- -------------------------------- --------------------------------------------------------------------
    ["Angle",                            "deg",         "NULL", "Degrees",                       "Angle of 1 degree"                                                 ],
    ["Angle",                            "rev",         "NULL", "Revolution",                    "Angle of 360 degrees"                                              ],
    ["Angular Speed",                    "rpm",         "NULL", "Revolutions per minute",        "Angular speed of 1 revolution per minute"                          ],
    ["Area",                             "1000 m2",     "SI",   "Thousands of square meters",    "Area of 1E+03 square meters"                                       ],
    ["Area",                             "acre",        "EN",   "Acre",                          "Area of 1 acre"                                                    ],
    ["Area",                             "ft2",         "EN",   "Square feet",                   "Area of 1 square foot"                                             ],
    ["Area",                             "ha",          "SI",   "Hectares",                      "Area of 1 hectare"                                                 ],
    ["Area",                             "km2",         "SI",   "Square kilometers",             "Area of a square kilometer"                                        ],
    ["Area",                             "m2",          "SI",   "Square meters",                 "Area of 1 square meter"                                            ],
    ["Area",                             "mile2",       "EN",   "Square miles",                  "Area of 1 square mile"                                             ],
    ["Areal Volume Rate",                "cfs/mi2",     "EN",   "Cfs per square mile",           "Volume rate of 1 cfs per area of 1 square mile"                    ],
    ["Areal Volume Rate",                "cms/km2",     "SI",   "Cms per square kilometer",      "Volume rate of 1 cms per area of 1 square kilometer"               ],
    ["Conductance",                      "mho",         "NULL", "Mhos",                          "Conductance of 1 mho (1/ohm)"                                      ],
    ["Conductance",                      "S",           "NULL", "Siemens",                       "Conductance of 1 Siemens"                                          ],
    ["Conductance",                      "umho",        "NULL", "Micro-mhos",                    "Conductance of 1E-06 mhos"                                         ],
    ["Conductance",                      "uS",          "NULL", "Micro-Siemens",                 "Conductance of 1E-06 Siemens"                                      ],
    ["Conductivity",                     "umho/cm",     "NULL", "Micro-mhos per centimeter",     "Conductivity of 1 micro-mho per centimeter"                        ],
    ["Count",                            "unit",        "NULL", "Count",                         "Number of items counted"                                           ],
    ["Currency",                         "$",           "NULL", "Dollars",                       "Monetary value of 1 United States dollar"                          ],
    ["Elapsed Time",                     "hr",          "NULL", "Hours",                         "Time span of 1 hour"                                               ],
    ["Elapsed Time",                     "min",         "NULL", "Minutes",                       "Time span of 1 minute"                                             ],
    ["Elapsed Time",                     "sec",         "NULL", "Seconds",                       "Time span of 1 second"                                             ],
    ["Electromotive Potential",          "volt",        "NULL", "Volts",                         "Electromotive Potential of 1 volt"                                 ],
    ["Energy",                           "GWh",         "NULL", "Gigawatt-hours",                "Energy of 1E+09 watt-hours"                                        ],
    ["Energy",                           "kWh",         "NULL", "Kilowatt-hours",                "Energy of 1E+03 watt-hours"                                        ],
    ["Energy",                           "MWh",         "NULL", "Megawatt-hours",                "Energy of 1E+06 watt-hours"                                        ],
    ["Energy",                           "TWh",         "NULL", "Terawatt-hour",                 "Energy of 1E+12 watt-hours"                                        ],
    ["Energy",                           "Wh",          "NULL", "Watt-hours",                    "Energy of 3.6E+03 Kilogram-square meter per square second"         ],
    ["Force",                            "lb",          "EN",   "Pounds",                        "Force of 1 pound"                                                  ],
    ["Hydrogen Ion Concentration Index", "su",          "NULL", "Standard pH units",             "Potential of hydrogen (acidity/alkalinity)"                        ],
    ["Irradiance",                       "langley/min", "NULL", "Langley per minute",            "Radiant power of 1 langley per minute"                             ],
    ["Irradiance",                       "W/m2",        "NULL", "Watts per square meter",        "Radiant power of 1 watt per area of 1 square meter"                ],
    ["Irradiation",                      "J/m2",        "NULL", "Joules per square meters",      "Radiant energy 1 joule per area of 1 square meter"                 ],
    ["Irradiation",                      "langley",     "NULL", "Langley",                       "Radiant energy of 1 langley"                                       ],
    ["Length",                           "cm",          "SI",   "Centimeters",                   "Length of 1E-02 meter"                                             ],
    ["Length",                           "ft",          "EN",   "Feet",                          "Length of 1 foot"                                                  ],
    ["Length",                           "in",          "EN",   "Inches",                        "Length of 1 inch"                                                  ],
    ["Length",                           "km",          "SI",   "Kilometers",                    "Length of 1E+03 meters"                                            ],
    ["Length",                           "m",           "SI",   "Meters",                        "Length of 1 meter"                                                 ],
    ["Length",                           "mi",          "EN",   "Miles",                         "Length of 1 mile"                                                  ],
    ["Length",                           "mm",          "SI",   "Millimeters",                   "Length of 1 millimeter"                                            ],
    ["Linear Speed",                     "ft/s",        "EN",   "Feet per second",               "Velocity of 1 foot per second"                                     ],
    ["Linear Speed",                     "in/day",      "EN",   "Inches per day",                "Velocity of 1 inch per day"                                        ],
    ["Linear Speed",                     "in/hr",       "EN",   "Inches per hour",               "Velocity of 1 inch per hour"                                       ],
    ["Linear Speed",                     "kph",         "SI",   "Kilometers per hour",           "Velocity of 1 kilometer per Hour"                                  ],
    ["Linear Speed",                     "m/s",         "SI",   "Meters per second",             "Velocity of 1 meter per second"                                    ],
    ["Linear Speed",                     "mm/day",      "SI",   "Millimeters per day",           "Velocity of 1 millimeter per day"                                  ],
    ["Linear Speed",                     "mm/hr",       "SI",   "Millimeters per hour",          "Velocity of 1 millimeter per hour"                                 ],
    ["Linear Speed",                     "mph",         "EN",   "Miles per hour",                "Velocity of 1 mile per hour"                                       ],
    ["Mass Concentration",               "g/l",         "SI",   "Grams per liter",               "Mass concentration of 1 gram per liter"                            ],
    ["Mass Concentration",               "gm/cm3",      "SI",   "Grams per cubic centimeters",   "Mass concentration of 1 gram per cubic centimeter"                 ],
    ["Mass Concentration",               "mg/l",        "SI",   "Milligrams per liter",          "Mass concentration of 1E-03 gram per liter"                        ],
    ["Mass Concentration",               "ppm",         "NULL", "Parts per million",             "Mass concentration of 1 mg/l"                                      ],
    ["None",                             "%",           "NULL", "Percent",                       "Ratio of 1E-02"                                                    ],
    ["None",                             "n/a",         "NULL", "No unit applies",               "Unitless value such as a ratio or code"                            ],
    ["Phase Change Rate Index",          "in/deg-day",  "EN",   "Inches per degree-day",         "Phase change of 1 inch per day per Fahrenheit degree"              ],
    ["Phase Change Rate Index",          "mm/deg-day",  "SI",   "Millimeters per degree-day",    "Phase change of 1 millimeter per day per Celsius degree"           ],
    ["Power",                            "GW",          "NULL", "Gigawatts",                     "Power of 1E+09 watts"                                              ],
    ["Power",                            "kW",          "NULL", "Kilowatts",                     "Power of 1E+03 watts"                                              ],
    ["Power",                            "MW",          "NULL", "Megawatts",                     "Power of 1E+06 watts"                                              ],
    ["Power",                            "TW",          "NULL", "Terawatts",                     "Power of 1E+12 watts"                                              ],
    ["Power",                            "W",           "NULL", "Watts",                         "Power of 1 watt (kilogram-square meter per cubic second)"          ],
    ["Pressure",                         "in-hg",       "EN",   "Inches of mercury",             "Barometric pressure"                                               ],
    ["Pressure",                         "kPa",         "SI",   "Kilopascals",                   "Pressure of 1 kilonewton per square meter"                         ],
    ["Pressure",                         "mb",          "SI",   "Millibars",                     "Pressure of 1E-03 bar"                                             ],
    ["Pressure",                         "mm-hg",       "SI",   "Millimeters of mercury",        "Barometric pressure"                                               ],
    ["Pressure",                         "psi",         "EN",   "Pounds per square inch",        "Pressure of 1 pound per square inch"                               ],
    ["Temperature",                      "C",           "SI",   "Centigrade",                    "Celsius Degree"                                                    ],
    ["Temperature",                      "F",           "EN",   "Fahrenheit",                    "Fahrenheit Degree"                                                 ],
    ["Turbidity",                        "JTU",         "NULL", "Jackson Turbitiy Unit",         "Jackson Turbidity Unit (approximates nephelometric turbidity unit)"],
    ["Turbidity",                        "NTU",         "NULL", "Nephelometric Turbidity Unit",  "Measure of scattered light (90+/-30 deg) from a white light (540+/-140nm)"],
    ["Turbidity",                        "FNU",         "NULL", "Formazin Nephelometric Unit",   "Measure of scattered light (90+/-2.5 deg) from monochrome light (860+/-60 nm)"],
    ["Volume Rate",                      "cfs",         "EN",   "Cubic feet per second",         "Volume rate of 1 cubic foot per second"                            ],
    ["Volume Rate",                      "cms",         "SI",   "Cubic meters per second",       "Volume rate of 1 cubic meter per second"                           ],
    ["Volume Rate",                      "gpm",         "EN",   "Gallons per minute",            "Volume rate of 1 gallon per minute"                                ],
    ["Volume Rate",                      "kcfs",        "EN",   "Kilo-cubic feet per second",    "Volume rate of 1E+03 cfs"                                          ],
    ["Volume Rate",                      "mgd",         "EN",   "Millions of gallons per day",   "Volume rate of 1E+06 gallons per day"                              ],
    ["Volume",                           "1000 m3",     "SI",   "Thousands of cubic meters",     "Volume of 1E+03 cubic meters"                                      ],
    ["Volume",                           "ac-ft",       "EN",   "Acre-feet",                     "Volume equal to the area of 1 acre times the length of 1 foot"     ],
    ["Volume",                           "dsf",         "EN",   "day-second-foot",               "Volume of water accumulated in one day by a flow of one cfs"       ],
    ["Volume",                           "gal",         "EN",   "Gallons",                       "Volume of 1 United States Gallon"                                  ],
    ["Volume",                           "ft3",         "EN",   "Cubic feet",                    "Volume of 1 cubic foot"                                            ],
    ["Volume",                           "kaf",         "EN",   "Kiloacre-feet",                 "Volume equal to the area of 1E+03 acres times the length of 1 foot"],
    ["Volume",                           "kgal",        "EN",   "Kilogallons",                   "Volume of 1E+03 gallons"                                           ],
    ["Volume",                           "km3",         "SI",   "Cubic kilometers",              "Volume of a cubic kilometer"                                       ],
    ["Volume",                           "m3",          "SI",   "Cubic meters",                  "Volume of 1 cubic meter"                                           ],
    ["Volume",                           "mgal",        "EN",   "Millions of gallons",           "Volume of 1E+06 gallons"                                           ],
    ["Volume",                           "mile3",       "EN",   "Cubic miles",                   "Volume of 1 cubic mile"                                            ],
]

unitDefsById = {}
unitCode = 0
for abstractParam, id, system, name, description in unitDefs : 
    unitCode = unitCode + 1
    unitDefsById[abstractParam + "." + id] = {"CODE" : unitCode, "ID" : id, "SYSTEM" : system, "NAME" : name, "ABSTRACT" : abstractParam, "DESCRIPTION" : description}
unitDefIds = unitDefsById.keys()
unitDefIds.sort()




#---------#
# Aliases #
#---------#
sys.stderr.write("Processing units unitAliases.\n")
unitAliases = [
#    ABSTRACT PARAMETER         UNIT ID    ALIAS ID
#    -------------------------- ---------- ------------------------
    ["Angular Speed",           "rpm",     "rev/min"               ],
    ["Angular Speed",           "rpm",     "revolutions per minute"],
    ["Area",                    "1000 m2", "1000 sq m"             ],
    ["Area",                    "1000 m2", "1000 sq meters"        ],
    ["Area",                    "acre",    "acres"                 ],
    ["Area",                    "ft2",     "sq ft"                 ],
    ["Area",                    "ft2",     "square feet"           ],
    ["Area",                    "ha",      "hectare"               ],
    ["Area",                    "ha",      "hectares"              ],
    ["Area",                    "km2",     "sq km"                 ],
    ["Area",                    "km2",     "sq.km"                 ],
    ["Area",                    "km2",     "sqkm"                  ],
    ["Area",                    "m2",      "sq m"                  ],
    ["Area",                    "m2",      "sq meter"              ],
    ["Area",                    "m2",      "sq meters"             ],
    ["Area",                    "m2",      "square meters"         ],
    ["Area",                    "mile2",   "mi2"                   ],
    ["Area",                    "mile2",   "sq mi"                 ],
    ["Area",                    "mile2",   "sq mile"               ],
    ["Area",                    "mile2",   "sq miles"              ],
    ["Area",                    "mile2",   "square miles"          ],
    ["Conductivity",            "umho/cm", "umhos/cm"              ],
    ["Elapsed Time",            "hr",      "hour"                  ],
    ["Elapsed Time",            "hr",      "hours"                 ],
    ["Elapsed Time",            "min",     "minute"                ],
    ["Elapsed Time",            "min",     "minutes"               ],
    ["Elapsed Time",            "sec",     "second"                ],
    ["Elapsed Time",            "sec",     "seconds"               ],
    ["Electromotive Potential", "volt",    "VOLT"                  ],
    ["Electromotive Potential", "volt",    "Volt"                  ],
    ["Electromotive Potential", "volt",    "VOLTS"                 ],
    ["Electromotive Potential", "volt",    "Volts"                 ],
    ["Electromotive Potential", "volt",    "volts"                 ],
    ["Force",                   "lb",      "lbs"                   ],
    ["Length",                  "cm",      "centimeter"            ],
    ["Length",                  "cm",      "centimeters"           ],
    ["Length",                  "ft",      "FEET"                  ],
    ["Length",                  "ft",      "feet"                  ],
    ["Length",                  "ft",      "foot"                  ],
    ["Length",                  "in",      "inch"                  ],
    ["Length",                  "in",      "INCHES"                ],
    ["Length",                  "in",      "inches"                ],
    ["Length",                  "km",      "kilometer"             ],
    ["Length",                  "km",      "kilometers"            ],
    ["Length",                  "m",       "meter"                 ],
    ["Length",                  "m",       "meters"                ],
    ["Length",                  "m",       "metre"                 ],
    ["Length",                  "m",       "metres"                ],
    ["Length",                  "mi",      "mile"                  ],
    ["Length",                  "mi",      "miles"                 ],
    ["Length",                  "mm",      "millimeter"            ],
    ["Length",                  "mm",      "millimeters"           ],
    ["Linear Speed",            "ft/s",    "fps"                   ],
    ["Linear Speed",            "ft/s",    "ft/sec"                ],
    ["Mass Concentration",      "g/l",     "gm/l"                  ],
    ["Mass Concentration",      "g/l",     "grams per liter"       ],
    ["Mass Concentration",      "g/l",     "grams/liter"           ],
    ["Mass Concentration",      "mg/l",    "millgrams/liter"       ],
    ["Mass Concentration",      "mg/l",    "milligrams per liter"  ],
    ["None",                    "%",       "PERCENT"               ],
    ["None",                    "%",       "percent"               ],
    ["Pressure",                "kPa",     "kN/m2"                 ],
    ["Pressure",                "mb",      "mbar"                  ],
    ["Pressure",                "mb",      "mbars"                 ],
    ["Pressure",                "mb",      "millibar"              ],
    ["Pressure",                "mb",      "millibars"             ],
    ["Pressure",                "psi",     "lbs/sqin"              ],
    ["Temperature",             "C",       "Celcius"               ],
    ["Temperature",             "C",       "Centigrade"            ],
    ["Temperature",             "C",       "DEG C"                 ],
    ["Temperature",             "C",       "deg C"                 ],
    ["Temperature",             "C",       "DEG-C"                 ],
    ["Temperature",             "C",       "Deg-C"                 ],
    ["Temperature",             "C",       "DegC"                  ],
    ["Temperature",             "C",       "degC"                  ],
    ["Temperature",             "F",       "DEG F"                 ],
    ["Temperature",             "F",       "deg F"                 ],
    ["Temperature",             "F",       "DEG-F"                 ],
    ["Temperature",             "F",       "Deg-F"                 ],
    ["Temperature",             "F",       "DegF"                  ],
    ["Temperature",             "F",       "degF"                  ],
    ["Temperature",             "F",       "Fahrenheit"            ],
    ["Turbidity",               "JTU",     "jtu"                   ],
    ["Turbidity",               "NTU",     "ntu"                   ],
    ["Volume Rate",             "cfs",     "CFS"                   ],
    ["Volume Rate",             "cfs",     "cu-ft/sec"             ],
    ["Volume Rate",             "cfs",     "cuft/sec"              ],
    ["Volume Rate",             "cfs",     "cusecs"                ],
    ["Volume Rate",             "cfs",     "ft3/sec"               ],
    ["Volume Rate",             "cms",     "CMS"                   ],
    ["Volume Rate",             "cms",     "cu-meters/sec"         ],
    ["Volume Rate",             "cms",     "M3/S"                  ],
    ["Volume Rate",             "cms",     "m3/s"                  ],
    ["Volume Rate",             "cms",     "m3/sec"                ],
    ["Volume Rate",             "gpm",     "Gal/min"               ],
    ["Volume Rate",             "gpm",     "gallons per minute"    ],
    ["Volume Rate",             "gpm",     "GPM"                   ],
    ["Volume Rate",             "kcfs",    "1000 cfs"              ],
    ["Volume Rate",             "kcfs",    "1000 cu-ft/sec"        ],
    ["Volume Rate",             "kcfs",    "1000 m3/sec"           ],
    ["Volume Rate",             "mgd",     "MGD"                   ],
    ["Volume Rate",             "mgd",     "million gallons/day"   ],
    ["Volume",                  "1000 m3", "1000 cu m"             ],
    ["Volume",                  "ac-ft",   "acft"                  ],
    ["Volume",                  "ac-ft",   "acre-feet"             ],
    ["Volume",                  "ac-ft",   "acre-ft"               ],
    ["Volume",                  "dsf",     "day-second-foot"       ],
    ["Volume",                  "dsf",     "second-day-foot"       ],
    ["Volume",                  "dsf",     "sdf"                   ],    
    ["Volume",                  "gal",     "GAL"                   ],
    ["Volume",                  "gal",     "gallon"                ],
    ["Volume",                  "gal",     "gallons"               ],
    ["Volume",                  "kaf",     "1000 ac-ft"            ],
    ["Volume",                  "kgal",    "1000 gallon"           ],
    ["Volume",                  "kgal",    "1000 gallons"          ],
    ["Volume",                  "kgal",    "KGAL"                  ],
    ["Volume",                  "kgal",    "TGAL"                  ],
    ["Volume",                  "kgal",    "tgal"                  ],
    ["Volume",                  "km3",     "cu km"                 ],
    ["Volume",                  "m3",      "cu m"                  ],
    ["Volume",                  "m3",      "cu meter"              ],
    ["Volume",                  "m3",      "cu meters"             ],
    ["Volume",                  "m3",      "cubic meters"          ],
    ["Volume",                  "mgal",    "MGAL"                  ],
    ["Volume",                  "mgal",    "million gallon"        ],
    ["Volume",                  "mgal",    "millon gallons"        ],
    ["Volume",                  "mile3",   "cu mile"               ],
    ["Volume",                  "mile3",   "cu miles"              ],
]

unitAliasesByUnitId = {}
for abstract_param, unit_id, unitAlias_id in unitAliases :
    unitAlias = {"ABSTRACT" : abstract_param, "UNIT_ID" : unit_id, "ALIAS_ID" : unitAlias_id}
    if not unitAliasesByUnitId.has_key(unit_id) :  unitAliasesByUnitId[unit_id] = []
    unitAliasesByUnitId[unit_id].append(unitAlias)

#------------------#
# Unit conversions #
#------------------#
sys.stderr.write("Processing unit conversion definitions.\n")
unitConversions = [
#    ABSTRACT PARAMETER                  FROM UNIT ID   TO UNIT ID    OFFSET                FACTOR
#    ----------------------------------- -------------- ------------- --------------------- -----------------------
    ["Angle",                            "deg",         "deg",         0.0,                 1.0                    ],
    ["Angle",                            "deg",         "rev",         0.0,                 2.7777777777777779E-003],
    ["Angle",                            "rev",         "deg",         0.0,                 360.0                  ],
    ["Angular Speed",                    "rpm",         "rpm",         0.0,                 1.0                    ],
    ["Area",                             "1000 m2",     "1000 m2",     0.0,                 1.0                    ],
    ["Area",                             "1000 m2",     "acre",        0.0,                 0.24710538146716532    ],
    ["Area",                             "1000 m2",     "ft2",         0.0,                 10763.910416709721     ],
    ["Area",                             "1000 m2",     "ha",          0.0,                 0.1                    ],
    ["Area",                             "1000 m2",     "km2",         0.0,                 0.001                  ],
    ["Area",                             "1000 m2",     "m2",          0.0,                 1000.0                 ],
    ["Area",                             "1000 m2",     "mile2",       0.0,                 0.00038610215854244581 ],
    ["Area",                             "acre",        "1000 m2",     0.0,                 4.0468564224           ],
    ["Area",                             "acre",        "acre",        0.0,                 1.0                    ],
    ["Area",                             "acre",        "ft2",         0.0,                 43560.0                ],
    ["Area",                             "acre",        "ha",          0.0,                 0.40468564224          ],
    ["Area",                             "acre",        "km2",         0.0,                 0.0040468564224        ],
    ["Area",                             "acre",        "m2",          0.0,                 4046.8564224           ],
    ["Area",                             "acre",        "mile2",       0.0,                 0.0015625              ],
    ["Area",                             "ft2",         "1000 m2",     0.0,                 9.290304e-005          ],
    ["Area",                             "ft2",         "acre",        0.0,                 2.295684113865932e-005 ],
    ["Area",                             "ft2",         "ft2",         0.0,                 1.0                    ],
    ["Area",                             "ft2",         "ha",          0.0,                 9.290304e-6            ],
    ["Area",                             "ft2",         "km2",         0.0,                 9.290304e-008          ],
    ["Area",                             "ft2",         "m2",          0.0,                 0.09290304             ],
    ["Area",                             "ft2",         "mile2",       0.0,                 0.00024061776901406983 ],
    ["Area",                             "ha",          "1000 m2",     0.0,                 10.0                   ],
    ["Area",                             "ha",          "acre",        0.0,                 2.4710538146716536     ],
    ["Area",                             "ha",          "ft2",         0.0,                 107639.10416709723     ],
    ["Area",                             "ha",          "ha",          0.0,                 1.0                    ],
    ["Area",                             "ha",          "km2",         0.0,                 0.01                   ],
    ["Area",                             "ha",          "m2",          0.0,                 10000.0                ],
    ["Area",                             "ha",          "mile2",       0.0,                 0.0038610215854244585  ],
    ["Area",                             "km2",         "1000 m2",     0.0,                 1000.0                 ],
    ["Area",                             "km2",         "acre",        0.0,                 247.10538146716533     ],
    ["Area",                             "km2",         "ft2",         0.0,                 10763910.416709721     ],
    ["Area",                             "km2",         "ha",          0.0,                 100.0                  ],
    ["Area",                             "km2",         "km2",         0.0,                 1.0                    ],
    ["Area",                             "km2",         "m2",          0.0,                 1000000.0              ],
    ["Area",                             "km2",         "mile2",       0.0,                 2.589988110336         ],
    ["Area",                             "m2",          "1000 m2",     0.0,                 0.001                  ],
    ["Area",                             "m2",          "acre",        0.0,                 0.00024710538146716532 ],
    ["Area",                             "m2",          "ft2",         0.0,                 10.763910416709722     ],
    ["Area",                             "m2",          "ha",          0.0,                 0.0001                 ],
    ["Area",                             "m2",          "km2",         0.0,                 1.0e-006               ],
    ["Area",                             "m2",          "m2",          0.0,                 1.0                    ],
    ["Area",                             "m2",          "mile2",       0.0,                 0.002589988110336      ],
    ["Area",                             "mile2",       "1000 m2",     0.0,                 2589.988110336         ],
    ["Area",                             "mile2",       "acre",        0.0,                 640.0                  ],
    ["Area",                             "mile2",       "ft2",         0.0,                 4155.9690462491417     ],
    ["Area",                             "mile2",       "ha",          0.0,                 258.99881103359996     ],
    ["Area",                             "mile2",       "km2",         0.0,                 0.38610215854244589    ],
    ["Area",                             "mile2",       "m2",          0.0,                 386.10215854244586     ],
    ["Area",                             "mile2",       "mile2",       0.0,                 1.0                    ],
    ["Areal Volume Rate",                "cfs/mi2",     "cfs/mi2",     0.0,                 1.0                    ],
    ["Areal Volume Rate",                "cfs/mi2",     "cms/km2",     0.0,                 13.63506963024075      ],
    ["Areal Volume Rate",                "cms/km2",     "cfs/mi2",     0.0,                 0.073340292871122162   ],
    ["Areal Volume Rate",                "cms/km2",     "cms/km2",     0.0,                 1.0                    ],
    ["Conductance",                      "mho",         "mho",         0.0,                 1.0                    ],
    ["Conductance",                      "mho",         "S",           0.0,                 1.0                    ],
    ["Conductance",                      "mho",         "umho",        0.0,                 1000000.0              ],
    ["Conductance",                      "mho",         "uS",          0.0,                 1000000.0              ],
    ["Conductance",                      "S",           "mho",         0.0,                 1.0                    ],
    ["Conductance",                      "S",           "S",           0.0,                 1.0                    ],
    ["Conductance",                      "S",           "umho",        0.0,                 1000000.0              ],
    ["Conductance",                      "S",           "uS",          0.0,                 1000000.0              ],
    ["Conductance",                      "umho",        "mho",         0.0,                 1.0e-006               ],
    ["Conductance",                      "umho",        "S",           0.0,                 1.0e-006               ],
    ["Conductance",                      "umho",        "umho",        0.0,                 1.0                    ],
    ["Conductance",                      "umho",        "uS",          0.0,                 1.0                    ],
    ["Conductance",                      "uS",          "mho",         0.0,                 1.0e-006               ],
    ["Conductance",                      "uS",          "S",           0.0,                 1.0e-006               ],
    ["Conductance",                      "uS",          "umho",        0.0,                 1.0                    ],
    ["Conductance",                      "uS",          "uS",          0.0,                 1.0                    ],
    ["Conductivity",                     "umho/cm",     "umho/cm",     0.0,                 1.0                    ],
    ["Count",                            "unit",        "unit",        0.0,                 1.0                    ],
    ["Currency",                         "$",           "$",           0.0,                 1.0                    ],
    ["Elapsed Time",                     "hr",          "hr",          0.0,                 1.0                    ],
    ["Elapsed Time",                     "hr",          "min",         0.0,                 60.0                   ],
    ["Elapsed Time",                     "hr",          "sec",         0.0,                 3600.0                 ],
    ["Elapsed Time",                     "min",         "hr",          0.0,                 0.016666666666666666   ],
    ["Elapsed Time",                     "min",         "min",         0.0,                 1.0                    ],
    ["Elapsed Time",                     "min",         "sec",         0.0,                 60.0                   ],
    ["Elapsed Time",                     "sec",         "hr",          0.0,                 0.00027777777777777778 ],
    ["Elapsed Time",                     "sec",         "min",         0.0,                 0.016666666666666666   ],
    ["Elapsed Time",                     "sec",         "sec",         0.0,                 1.0                    ],
    ["Electromotive Potential",          "volt",        "volt",        0.0,                 1.0                    ],
    ["Energy",                           "GWh",         "GWh",         0.0,                 1.0                    ],
    ["Energy",                           "GWh",         "kWh",         0.0,                 1000000.0              ],
    ["Energy",                           "GWh",         "MWh",         0.0,                 1000.0                 ],
    ["Energy",                           "GWh",         "TWh",         0.0,                 0.001                  ],
    ["Energy",                           "GWh",         "Wh",          0.0,                 1000000000.0           ],
    ["Energy",                           "kWh",         "GWh",         0.0,                 1.0e-006               ],
    ["Energy",                           "kWh",         "kWh",         0.0,                 1.0                    ],
    ["Energy",                           "kWh",         "MWh",         0.0,                 0.001                  ],
    ["Energy",                           "kWh",         "TWh",         0.0,                 1.0e-009               ],
    ["Energy",                           "kWh",         "Wh",          0.0,                 1000.0                 ],
    ["Energy",                           "MWh",         "GWh",         0.0,                 0.001                  ],
    ["Energy",                           "MWh",         "kWh",         0.0,                 1000.0                 ],
    ["Energy",                           "MWh",         "MWh",         0.0,                 1.0                    ],
    ["Energy",                           "MWh",         "TWh",         0.0,                 1.0e-006               ],
    ["Energy",                           "MWh",         "Wh",          0.0,                 1000000.0              ],
    ["Energy",                           "TWh",         "GWh",         0.0,                 1000.0                 ],
    ["Energy",                           "TWh",         "kWh",         0.0,                 1000000000.0           ],
    ["Energy",                           "TWh",         "MWh",         0.0,                 1000000.0              ],
    ["Energy",                           "TWh",         "TWh",         0.0,                 1.0                    ],
    ["Energy",                           "TWh",         "Wh",          0.0,                 1000000000000.0        ],
    ["Energy",                           "Wh",          "GWh",         0.0,                 1.0e-009               ],
    ["Energy",                           "Wh",          "kWh",         0.0,                 0.001                  ],
    ["Energy",                           "Wh",          "MWh",         0.0,                 1.0e-006               ],
    ["Energy",                           "Wh",          "TWh",         0.0,                 1.0e-012               ],
    ["Energy",                           "Wh",          "Wh",          0.0,                 1.0                    ],
    ["Force",                            "lb",          "lb",          0.0,                 1.0                    ],
    ["Hydrogen Ion Concentration Index", "su",          "su",          0.0,                 1.0                    ],
    ["Irradiance",                       "langley/min", "langley/min", 0.0,                 1.0                    ],
    ["Irradiance",                       "langley/min", "W/m2",        0.0,                 697.333                ],
    ["Irradiance",                       "W/m2",        "langley/min", 0.0,                 0.0014340351023112345  ],
    ["Irradiance",                       "W/m2",        "W/m2",        0.0,                 1.0                    ],
    ["Irradiation",                      "J/m2",        "J/m2",        0.0,                 1.0                    ],
    ["Irradiation",                      "J/m2",        "langley",     0.0,                 2.390057361376673e-005 ],
    ["Irradiation",                      "langley",     "J/m2",        0.0,                 41840.0                ],
    ["Irradiation",                      "langley",     "langley",     0.0,                 1.0                    ],
    ["Length",                           "cm",          "cm",          0.0,                 1.0                    ],
    ["Length",                           "cm",          "ft",          0.0,                 0.032808398950131233   ],
    ["Length",                           "cm",          "in",          0.0,                 0.39370078740157477    ],
    ["Length",                           "cm",          "km",          0.0,                 1.0e-005               ],
    ["Length",                           "cm",          "m",           0.0,                 0.01                   ],
    ["Length",                           "cm",          "mi",          0.0,                 6.2137119223733393e-006],
    ["Length",                           "cm",          "mm",          0.0,                 10.0                   ],
    ["Length",                           "ft",          "cm",          0.0,                 30.48                  ],
    ["Length",                           "ft",          "ft",          0.0,                 1.0                    ],
    ["Length",                           "ft",          "in",          0.0,                 12.0                   ],
    ["Length",                           "ft",          "km",          0.0,                 0.0003048              ],
    ["Length",                           "ft",          "m",           0.0,                 0.3048                 ],
    ["Length",                           "ft",          "mi",          0.0,                 0.00018939393939393939 ],
    ["Length",                           "ft",          "mm",          0.0,                 304.8                  ],
    ["Length",                           "in",          "cm",          0.0,                 2.54                   ],
    ["Length",                           "in",          "ft",          0.0,                 0.08333333333333333    ],
    ["Length",                           "in",          "in",          0.0,                 1.0                    ],
    ["Length",                           "in",          "km",          0.0,                 3.9370078740157482e-006],
    ["Length",                           "in",          "m",           0.0,                 0.0254                 ],
    ["Length",                           "in",          "mi",          0.0,                 1.5782828282828283e-005],
    ["Length",                           "in",          "mm",          0.0,                 25.4                   ],
    ["Length",                           "km",          "cm",          0.0,                 100000.0               ],
    ["Length",                           "km",          "ft",          0.0,                 3280.8398950131232     ],
    ["Length",                           "km",          "in",          0.0,                 254000.0               ],
    ["Length",                           "km",          "km",          0.0,                 1.0                    ],
    ["Length",                           "km",          "m",           0.0,                 1000.0                 ],
    ["Length",                           "km",          "mi",          0.0,                 0.6213711922373339     ],
    ["Length",                           "km",          "mm",          0.0,                 1000000.0              ],
    ["Length",                           "m",           "cm",          0.0,                 100.0                  ],
    ["Length",                           "m",           "ft",          0.0,                 3.280839895013123      ],
    ["Length",                           "m",           "in",          0.0,                 39.370078740157474     ],
    ["Length",                           "m",           "km",          0.0,                 0.001                  ],
    ["Length",                           "m",           "m",           0.0,                 1.0                    ],
    ["Length",                           "m",           "mi",          0.0,                 0.0006213711922373339  ],
    ["Length",                           "m",           "mm",          0.0,                 1000.0                 ],
    ["Length",                           "mi",          "cm",          0.0,                 160934.4               ],
    ["Length",                           "mi",          "ft",          0.0,                 5280.0                 ],
    ["Length",                           "mi",          "in",          0.0,                 63360.0                ],
    ["Length",                           "mi",          "km",          0.0,                 1.609344               ],
    ["Length",                           "mi",          "m",           0.0,                 1609.344               ],
    ["Length",                           "mi",          "mi",          0.0,                 1.0                    ],
    ["Length",                           "mi",          "mm",          0.0,                 1609344.0              ],
    ["Length",                           "mm",          "cm",          0.0,                 0.1                    ],
    ["Length",                           "mm",          "ft",          0.0,                 0.0032808398950131233  ],
    ["Length",                           "mm",          "in",          0.0,                 0.03937007874015748    ],
    ["Length",                           "mm",          "km",          0.0,                 1.0e-006               ],
    ["Length",                           "mm",          "m",           0.0,                 0.001                  ],
    ["Length",                           "mm",          "mi",          0.0,                 6.2137119223733397e-007],
    ["Length",                           "mm",          "mm",          0.0,                 1.0                    ],
    ["Linear Speed",                     "ft/s",        "ft/s",        0.0,                 1.0                    ],
    ["Linear Speed",                     "ft/s",        "in/day",      0.0,                 1036800.0              ],
    ["Linear Speed",                     "ft/s",        "in/hr",       0.0,                 43200.0                ],
    ["Linear Speed",                     "ft/s",        "kph",         0.0,                 1.09728                ],
    ["Linear Speed",                     "ft/s",        "m/s",         0.0,                 0.3048                 ],
    ["Linear Speed",                     "ft/s",        "mm/day",      0.0,                 26334720.0             ],
    ["Linear Speed",                     "ft/s",        "mm/hr",       0.0,                 1097280.0              ],
    ["Linear Speed",                     "ft/s",        "mph",         0.0,                 6.8181818181818188E-001],
    ["Linear Speed",                     "in/day",      "ft/s",        0.0,                 9.645061728395062e-007 ],
    ["Linear Speed",                     "in/day",      "in/day",      0.0,                 1.0                    ],
    ["Linear Speed",                     "in/day",      "in/hr",       0.0,                 0.041666666666666664   ],
    ["Linear Speed",                     "in/day",      "kph",         0.0,                 2.1166666666666666e-006],
    ["Linear Speed",                     "in/day",      "m/s",         0.0,                 2.9398148148148149e-007],
    ["Linear Speed",                     "in/day",      "mm/day",      0.0,                 25.4                   ],
    ["Linear Speed",                     "in/day",      "mm/hr",       0.0,                 1.0583333333333333     ],
    ["Linear Speed",                     "in/day",      "mph",         0.0,                 6.5761784511784515e-007],
    ["Linear Speed",                     "in/hr",       "ft/s",        0.0,                 2.3148148148148147e-005],
    ["Linear Speed",                     "in/hr",       "in/day",      0.0,                 24.0                   ],
    ["Linear Speed",                     "in/hr",       "in/hr",       0.0,                 1.0                    ],
    ["Linear Speed",                     "in/hr",       "kph",         0.0,                 2.54e-005              ],
    ["Linear Speed",                     "in/hr",       "m/s",         0.0,                 7.055555555555555e-006 ],
    ["Linear Speed",                     "in/hr",       "mm/day",      0.0,                 609.6                  ],
    ["Linear Speed",                     "in/hr",       "mm/hr",       0.0,                 25.4                   ],
    ["Linear Speed",                     "in/hr",       "mph",         0.0,                 1.5782828282828283e-005],
    ["Linear Speed",                     "kph",         "ft/s",        0.0,                 0.91134441528142318    ],
    ["Linear Speed",                     "kph",         "in/day",      0.0,                 472440.94488188974     ],
    ["Linear Speed",                     "kph",         "in/hr",       0.0,                 39370.078740157485     ],
    ["Linear Speed",                     "kph",         "kph",         0.0,                 1.0                    ],
    ["Linear Speed",                     "kph",         "m/s",         0.0,                 0.27777777777777777    ],
    ["Linear Speed",                     "kph",         "mm/day",      0.0,                 24000000.0             ],
    ["Linear Speed",                     "kph",         "mm/hr",       0.0,                 1000000.0              ],
    ["Linear Speed",                     "kph",         "mph",         0.0,                 0.62137119223733395    ],
    ["Linear Speed",                     "m/s",         "ft/s",        0.0,                 3.280839895013123      ],
    ["Linear Speed",                     "m/s",         "in/day",      0.0,                 3401574.8031496066     ],
    ["Linear Speed",                     "m/s",         "in/hr",       0.0,                 141732.28346456692     ],
    ["Linear Speed",                     "m/s",         "kph",         0.0,                 3.6                    ],
    ["Linear Speed",                     "m/s",         "m/s",         0.0,                 1.0                    ],
    ["Linear Speed",                     "m/s",         "mm/day",      0.0,                 86400000.0             ],
    ["Linear Speed",                     "m/s",         "mm/hr",       0.0,                 3.6000000000000005E+006],
    ["Linear Speed",                     "m/s",         "mph",         0.0,                 2.2369362920544025     ],
    ["Linear Speed",                     "mm/day",      "ft/s",        0.0,                 3.7972683970059295e-008],
    ["Linear Speed",                     "mm/day",      "in/day",      0.0,                 0.03937007874015748    ],
    ["Linear Speed",                     "mm/day",      "in/hr",       0.0,                 0.0016404199475065617  ],
    ["Linear Speed",                     "mm/day",      "kph",         0.0,                 4.1666666666666669e-008],
    ["Linear Speed",                     "mm/day",      "m/s",         0.0,                 1.1574074074074074e-008],
    ["Linear Speed",                     "mm/day",      "mm/day",      0.0,                 1.0                    ],
    ["Linear Speed",                     "mm/day",      "mm/hr",       0.0,                 0.041666666666666666   ],
    ["Linear Speed",                     "mm/day",      "mph",         0.0,                 2.5890466343222249e-008],
    ["Linear Speed",                     "mm/hr",       "ft/s",        0.0,                 9.1134441528142313e-007],
    ["Linear Speed",                     "mm/hr",       "in/day",      0.0,                 0.94488188976377951    ],
    ["Linear Speed",                     "mm/hr",       "in/hr",       0.0,                 0.03937007874015748    ],
    ["Linear Speed",                     "mm/hr",       "kph",         0.0,                 1.0e-006               ],
    ["Linear Speed",                     "mm/hr",       "m/s",         0.0,                 2.7777777777777777e-007],
    ["Linear Speed",                     "mm/hr",       "mm/day",      0.0,                 24.0                   ],
    ["Linear Speed",                     "mm/hr",       "mm/hr",       0.0,                 1.0                    ],
    ["Linear Speed",                     "mm/hr",       "mph",         0.0,                 6.2137119223733397e-007],
    ["Linear Speed",                     "mph",         "ft/s",        0.0,                 1.4666666666666666     ],
    ["Linear Speed",                     "mph",         "in/day",      0.0,                 1520640.0              ],
    ["Linear Speed",                     "mph",         "in/hr",       0.0,                 63360.0                ],
    ["Linear Speed",                     "mph",         "kph",         0.0,                 1.609344               ],
    ["Linear Speed",                     "mph",         "m/s",         0.0,                 0.44704                ],
    ["Linear Speed",                     "mph",         "mm/day",      0.0,                 38624256.0             ],
    ["Linear Speed",                     "mph",         "mm/hr",       0.0,                 1609344.0              ],
    ["Linear Speed",                     "mph",         "mph",         0.0,                 1.0                    ],
    ["Mass Concentration",               "g/l",         "g/l",         0.0,                 1.0                    ],
    ["Mass Concentration",               "g/l",         "gm/cm3",      0.0,                 1000.0                 ],
    ["Mass Concentration",               "g/l",         "mg/l",        0.0,                 1000.0                 ],
    ["Mass Concentration",               "g/l",         "ppm",         0.0,                 1000.0                 ],
    ["Mass Concentration",               "gm/cm3",      "g/l",         0.0,                 0.001                  ],
    ["Mass Concentration",               "gm/cm3",      "gm/cm3",      0.0,                 1.0                    ],
    ["Mass Concentration",               "gm/cm3",      "mg/l",        0.0,                 1.0                    ],
    ["Mass Concentration",               "gm/cm3",      "ppm",         0.0,                 1.0                    ],
    ["Mass Concentration",               "mg/l",        "g/l",         0.0,                 0.001                  ],
    ["Mass Concentration",               "mg/l",        "gm/cm3",      0.0,                 1.0                    ],
    ["Mass Concentration",               "mg/l",        "mg/l",        0.0,                 1.0                    ],
    ["Mass Concentration",               "mg/l",        "ppm",         0.0,                 1.0                    ],
    ["Mass Concentration",               "ppm",         "g/l",         0.0,                 0.001                  ],
    ["Mass Concentration",               "ppm",         "gm/cm3",      0.0,                 1.0                    ],
    ["Mass Concentration",               "ppm",         "mg/l",        0.0,                 1.0                    ],
    ["Mass Concentration",               "ppm",         "ppm",         0.0,                 1.0                    ],
    ["None",                             "%",           "%",           0.0,                 1.0                    ],
    ["None",                             "n/a",         "n/a",         0.0,                 1.0                    ],
    ["Phase Change Rate Index",          "in/deg-day",  "in/deg-day",  0.0,                 1.0                    ],
    ["Phase Change Rate Index",          "in/deg-day",  "mm/deg-day",  0.0,                 45.72                  ],
    ["Phase Change Rate Index",          "mm/deg-day",  "in/deg-day",  0.0,                 0.021872265966754158   ],
    ["Phase Change Rate Index",          "mm/deg-day",  "mm/deg-day",  0.0,                 1.0                    ],
    ["Power",                            "GW",          "GW",          0.0,                 1.0                    ],
    ["Power",                            "GW",          "kW",          0.0,                 1000000.0              ],
    ["Power",                            "GW",          "MW",          0.0,                 1000.0                 ],
    ["Power",                            "GW",          "TW",          0.0,                 0.001                  ],
    ["Power",                            "GW",          "W",           0.0,                 1000000000.0           ],
    ["Power",                            "kW",          "GW",          0.0,                 1.0e-006               ],
    ["Power",                            "kW",          "kW",          0.0,                 1.0                    ],
    ["Power",                            "kW",          "MW",          0.0,                 0.001                  ],
    ["Power",                            "kW",          "TW",          0.0,                 1.0e-009               ],
    ["Power",                            "kW",          "W",           0.0,                 1000.0                 ],
    ["Power",                            "MW",          "GW",          0.0,                 0.001                  ],
    ["Power",                            "MW",          "kW",          0.0,                 1000.0                 ],
    ["Power",                            "MW",          "MW",          0.0,                 1.0                    ],
    ["Power",                            "MW",          "TW",          0.0,                 1.0e-006               ],
    ["Power",                            "MW",          "W",           0.0,                 1000000.0              ],
    ["Power",                            "TW",          "GW",          0.0,                 1000.0                 ],
    ["Power",                            "TW",          "kW",          0.0,                 1000000000.0           ],
    ["Power",                            "TW",          "MW",          0.0,                 1000000.0              ],
    ["Power",                            "TW",          "TW",          0.0,                 1.0                    ],
    ["Power",                            "TW",          "W",           0.0,                 1000000000000.0        ],
    ["Power",                            "W",           "GW",          0.0,                 1.0e-009               ],
    ["Power",                            "W",           "kW",          0.0,                 0.001                  ],
    ["Power",                            "W",           "MW",          0.0,                 1.0e-006               ],
    ["Power",                            "W",           "TW",          0.0,                 1.0e-012               ],
    ["Power",                            "W",           "W",           0.0,                 1.0                    ],
    ["Pressure",                         "in-hg",       "in-hg",       0.0,                 1.0                    ],
    ["Pressure",                         "in-hg",       "kPa",         0.0,                 3.386388               ],
    ["Pressure",                         "in-hg",       "mb",          0.0,                 33.86388               ],
    ["Pressure",                         "in-hg",       "mm-hg",       0.0,                 25.4                   ],
    ["Pressure",                         "in-hg",       "psi",         0.0,                 456.01986405511809     ],
    ["Pressure",                         "kPa",         "in-hg",       0.0,                 0.29529988884912184    ],
    ["Pressure",                         "kPa",         "kPa",         0.0,                 1.0                    ],
    ["Pressure",                         "kPa",         "mb",          0.0,                 10.0                   ],
    ["Pressure",                         "kPa",         "mm-hg",       0.0,                 7.5006375541921066     ],
    ["Pressure",                         "kPa",         "psi",         0.0,                 0.14503774389728311    ],
    ["Pressure",                         "mb",          "in-hg",       0.0,                 0.029529988884912182   ],
    ["Pressure",                         "mb",          "kPa",         0.0,                 0.1                    ],
    ["Pressure",                         "mb",          "mb",          0.0,                 1.0                    ],
    ["Pressure",                         "mb",          "mm-hg",       0.0,                 0.75006171767676932    ],
    ["Pressure",                         "mb",          "psi",         0.0,                 1.3466261516846803E+001],
    ["Pressure",                         "mm-hg",       "in-hg",       0.0,                 0.03937007874015748    ],
    ["Pressure",                         "mm-hg",       "kPa",         0.0,                 0.133322               ],
    ["Pressure",                         "mm-hg",       "mb",          0.0,                 1.3332236220472442     ],
    ["Pressure",                         "mm-hg",       "mm-hg",       0.0,                 1.0                    ],
    ["Pressure",                         "mm-hg",       "psi",         0.0,                 11582.904547           ],
    ["Pressure",                         "psi",         "in-hg",       0.0,                 0.0021928869306428551  ],
    ["Pressure",                         "psi",         "kPa",         0.0,                 6.894757               ],
    ["Pressure",                         "psi",         "mb",          0.0,                 0.074259659872857972   ],
    ["Pressure",                         "psi",         "mm-hg",       0.0,                 8.6334131127671455e-005],
    ["Pressure",                         "psi",         "psi",         0.0,                 1.0                    ],
    ["Temperature",                      "C",           "C",           0.0,                 1.0                    ],
    ["Temperature",                      "C",           "F",           32.0,                1.8                    ],
    ["Temperature",                      "F",           "C",           -17.777777777777777, 0.55555555555555555    ],
    ["Temperature",                      "F",           "F",           0.0,                 1.0                    ],
    ["Turbidity",                        "JTU",         "JTU",         0.0,                 1.0                    ],
    ["Turbidity",                        "NTU",         "NTU",         0.0,                 1.0                    ],
    ["Turbidity",                        "FNU",         "FNU",         0.0,                 1.0                    ],
    ["Volume Rate",                      "cfs",         "cfs",         0.0,                 1.0                    ],
    ["Volume Rate",                      "cfs",         "cms",         0.0,                 0.028316846592         ],
    ["Volume Rate",                      "cfs",         "gpm",         0.0,                 0.12467531666666666    ],
    ["Volume Rate",                      "cfs",         "kcfs",        0.0,                 0.001                  ],
    ["Volume Rate",                      "cfs",         "mgd",         0.0,                 0.64631503335444473    ],
    ["Volume Rate",                      "cms",         "cfs",         0.0,                 35.314666721488592     ],
    ["Volume Rate",                      "cms",         "cms",         0.0,                 1.0                    ],
    ["Volume Rate",                      "cms",         "gpm",         0.0,                 4.40286753             ],
    ["Volume Rate",                      "cms",         "kcfs",        0.0,                 0.035314666721488593   ],
    ["Volume Rate",                      "cms",         "mgd",         0.0,                 22.8244                ],
    ["Volume Rate",                      "gpm",         "cfs",         0.0,                 8.0208338485605104     ],
    ["Volume Rate",                      "gpm",         "cms",         0.0,                 0.22712470751987399    ],
    ["Volume Rate",                      "gpm",         "gpm",         0.0,                 1.0                    ],
    ["Volume Rate",                      "gpm",         "kcfs",        0.0,                 0.0080208338485605098  ],
    ["Volume Rate",                      "gpm",         "mgd",         0.0,                 5.1839851743166117     ],
    ["Volume Rate",                      "kcfs",        "cfs",         0.0,                 1000.0                 ],
    ["Volume Rate",                      "kcfs",        "cms",         0.0,                 28.316846592           ],
    ["Volume Rate",                      "kcfs",        "gpm",         0.0,                 124.67531666666666     ],
    ["Volume Rate",                      "kcfs",        "kcfs",        0.0,                 1.0                    ],
    ["Volume Rate",                      "kcfs",        "mgd",         0.0,                 646.31503335444472     ],
    ["Volume Rate",                      "mgd",         "cfs",         0.0,                 1.5472330804528744     ],
    ["Volume Rate",                      "mgd",         "cms",         0.0,                 0.043812761781251638   ],
    ["Volume Rate",                      "mgd",         "gpm",         0.0,                 0.19290178624629781    ],
    ["Volume Rate",                      "mgd",         "kcfs",        0.0,                 0.0015472330804528745  ],
    ["Volume Rate",                      "mgd",         "mgd",         0.0,                 1.0                    ],
    ["Volume",                           "1000 m3",     "1000 m3",     0.0,                 1.0                    ],
    ["Volume",                           "1000 m3",     "ac-ft",       0.0,                 0.81071319378991247    ],
    ["Volume",                           "1000 m3",     "dsf",         0.0,                 0.408734519343574      ],
    ["Volume",                           "1000 m3",     "ft3",         0.0,                 3.5314666721488589E+004],
    ["Volume",                           "1000 m3",     "gal",         0.0,                 264172.87472922285     ],
    ["Volume",                           "1000 m3",     "kaf",         0.0,                 0.00081071319378991252 ],
    ["Volume",                           "1000 m3",     "kgal",        0.0,                 264.17287472922277     ],
    ["Volume",                           "1000 m3",     "km3",         0.0,                 1.0e-006               ],
    ["Volume",                           "1000 m3",     "m3",          0.0,                 1000.0                 ],
    ["Volume",                           "1000 m3",     "mgal",        0.0,                 0.2641728747292228     ],
    ["Volume",                           "1000 m3",     "mile3",       0.0,                 2.3991275857892773e-007],
    ["Volume",                           "ac-ft",       "1000 m3",     0.0,                 1.2334818375475201     ],
    ["Volume",                           "ac-ft",       "ac-ft",       0.0,                 1.0                    ],
    ["Volume",                           "ac-ft",       "dsf",         0.0,                 0.504166666666667      ],
    ["Volume",                           "ac-ft",       "ft3",         0.0,                 4.356E+004             ],
    ["Volume",                           "ac-ft",       "gal",         0.0,                 325852.44295121258     ],
    ["Volume",                           "ac-ft",       "kaf",         0.0,                 0.001                  ],
    ["Volume",                           "ac-ft",       "kgal",        0.0,                 325.85244295121254     ],
    ["Volume",                           "ac-ft",       "km3",         0.0,                 1.23348183754752e-006  ],
    ["Volume",                           "ac-ft",       "m3",          0.0,                 1233.4818375475199     ],
    ["Volume",                           "ac-ft",       "mgal",        0.0,                 0.32585244295121252    ],
    ["Volume",                           "ac-ft",       "mile3",       0.0,                 2.959280303030303e-007 ],
    ["Volume",                           "dsf",         "1000 m3",     0.0,                 2.44657584             ],
    ["Volume",                           "dsf",         "ac-ft",       0.0,                 1.983471074380164      ],
    ["Volume",                           "dsf",         "dsf",         0.0,                 1.0                    ],
    ["Volume",                           "dsf",         "ft3",         0.0,                 86400                  ],
    ["Volume",                           "dsf",         "gal",         0.0,                 646316.8416            ],
    ["Volume",                           "dsf",         "kaf",         0.0,                 1.9834710743801653E-003],
    ["Volume",                           "dsf",         "kgal",        0.0,                 646.3168416            ],
    ["Volume",                           "dsf",         "km3",         0.0,                 2.44657554554881e-006  ],
    ["Volume",                           "dsf",         "m3",          0.0,                 2446.57584             ],
    ["Volume",                           "dsf",         "mgal",        0.0,                 0.6463168416           ],
    ["Volume",                           "dsf",         "mile3",       0.0,                 5.86964688204358e-007  ],
    ["Volume",                           "ft3",         "1000 m3",     0.0,                 2.8316846592000003E-005],
    ["Volume",                           "ft3",         "ac-ft",       0.0,                 2.295684113865932E-005 ],
    ["Volume",                           "ft3",         "dsf",         0.0,                 1.1574074074074082E-005],
    ["Volume",                           "ft3",         "ft3",         0.0,                 1.0                    ],
    ["Volume",                           "ft3",         "gal",         0.0,                 7.4805427674750362E+000],
    ["Volume",                           "ft3",         "kaf",         0.0,                 2.2956841138659321E-008],
    ["Volume",                           "ft3",         "kgal",        0.0,                 7.4805427674750355E-003],
    ["Volume",                           "ft3",         "km3",         0.0,                 2.8316846591999998E-011],
    ["Volume",                           "ft3",         "m3",          0.0,                 2.8316846591999997E-002],
    ["Volume",                           "ft3",         "mgal",        0.0,                 7.4805427674750352E-006],
    ["Volume",                           "ft3",         "mile3",       0.0,                 6.7935727801430279E-012],
    ["Volume",                           "gal",         "1000 m3",     0.0,                 3.7854e-006            ],
    ["Volume",                           "gal",         "ac-ft",       0.0,                 3.0688737237723353e-006],
    ["Volume",                           "gal",         "dsf",         0.0,                 1.54722875165133E-06   ],
    ["Volume",                           "gal",         "ft3",         0.0,                 1.3368013940752294E-001],
    ["Volume",                           "gal",         "gal",         0.0,                 1.0                    ],
    ["Volume",                           "gal",         "kaf",         0.0,                 3.0688737237723348e-009],
    ["Volume",                           "gal",         "kgal",        0.0,                 0.001                  ],
    ["Volume",                           "gal",         "km3",         0.0,                 3.7854e-012            ],
    ["Volume",                           "gal",         "m3",          0.0,                 0.0037854              ],
    ["Volume",                           "gal",         "mgal",        0.0,                 1.0e-006               ],
    ["Volume",                           "gal",         "mile3",       0.0,                 9.0816575632467307e-013],
    ["Volume",                           "kaf",         "1000 m3",     0.0,                 1233.4818375475199     ],
    ["Volume",                           "kaf",         "ac-ft",       0.0,                 1000.0                 ],
    ["Volume",                           "kaf",         "dsf",         0.0,                 504.166666666667       ],
    ["Volume",                           "kaf",         "ft3",         0.0,                 4.356E+007             ],
    ["Volume",                           "kaf",         "gal",         0.0,                 325852442.95121258     ],
    ["Volume",                           "kaf",         "kaf",         0.0,                 1.0                    ],
    ["Volume",                           "kaf",         "kgal",        0.0,                 325852.44295121252     ],
    ["Volume",                           "kaf",         "km3",         0.0,                 1.23348183754752e-006  ],
    ["Volume",                           "kaf",         "m3",          0.0,                 1233481.8375475199     ],
    ["Volume",                           "kaf",         "mgal",        0.0,                 325.85244295121248     ],
    ["Volume",                           "kaf",         "mile3",       0.0,                 0.00029592803030303031 ],
    ["Volume",                           "kgal",        "1000 m3",     0.0,                 0.0037854              ],
    ["Volume",                           "kgal",        "ac-ft",       0.0,                 0.0030688737237723352  ],
    ["Volume",                           "kgal",        "dsf",         0.0,                 1.54722875165133e-003  ],
    ["Volume",                           "kgal",        "ft3",         0.0,                 1.3368013940752292E+002],
    ["Volume",                           "kgal",        "gal",         0.0,                 1000.0                 ],
    ["Volume",                           "kgal",        "kaf",         0.0,                 3.0688737237723353e-006],
    ["Volume",                           "kgal",        "kgal",        0.0,                 1.0                    ],
    ["Volume",                           "kgal",        "km3",         0.0,                 3.7854e-009            ],
    ["Volume",                           "kgal",        "m3",          0.0,                 3.7854                 ],
    ["Volume",                           "kgal",        "mgal",        0.0,                 0.001                  ],
    ["Volume",                           "kgal",        "mile3",       0.0,                 9.0816575632467308e-010],
    ["Volume",                           "km3",         "1000 m3",     0.0,                 1000000.0              ],
    ["Volume",                           "km3",         "ac-ft",       0.0,                 810713.1937899125      ],
    ["Volume",                           "km3",         "dsf",         0.0,                 408734.568535746       ],
    ["Volume",                           "km3",         "ft3",         0.0,                 3.5314666721488586E+010],
    ["Volume",                           "km3",         "gal",         0.0,                 264172874729.22284     ],
    ["Volume",                           "km3",         "kaf",         0.0,                 810713.1937899125      ],
    ["Volume",                           "km3",         "kgal",        0.0,                 264172874.7292228      ],
    ["Volume",                           "km3",         "km3",         0.0,                 1.0                    ],
    ["Volume",                           "km3",         "m3",          0.0,                 1000000000.0           ],
    ["Volume",                           "km3",         "mgal",        0.0,                 264172.87472922279     ],
    ["Volume",                           "km3",         "mile3",       0.0,                 0.23991275857892772    ],
    ["Volume",                           "m3",          "1000 m3",     0.0,                 0.001                  ],
    ["Volume",                           "m3",          "ac-ft",       0.0,                 0.00081071319378991263 ],
    ["Volume",                           "m3",          "dsf",         0.0,                 4.08734519343574e-004  ],
    ["Volume",                           "m3",          "ft3",         0.0,                 3.5314666721488592E+001],
    ["Volume",                           "m3",          "gal",         0.0,                 264.17287472922283     ],
    ["Volume",                           "m3",          "kaf",         0.0,                 8.1071319378991257e-007],
    ["Volume",                           "m3",          "kgal",        0.0,                 0.2641728747292228     ],
    ["Volume",                           "m3",          "km3",         0.0,                 1.0e-009               ],
    ["Volume",                           "m3",          "m3",          0.0,                 1.0                    ],
    ["Volume",                           "m3",          "mgal",        0.0,                 0.00026417287472922278 ],
    ["Volume",                           "m3",          "mile3",       0.0,                 2.3991275857892774e-010],
    ["Volume",                           "mgal",        "1000 m3",     0.0,                 3.7854                 ],
    ["Volume",                           "mgal",        "ac-ft",       0.0,                 3.0688737237723354     ],
    ["Volume",                           "mgal",        "dsf",         0.0,                 1.54722875165133       ],
    ["Volume",                           "mgal",        "ft3",         0.0,                 1.3368013940752292E+005],
    ["Volume",                           "mgal",        "gal",         0.0,                 1000000.0              ],
    ["Volume",                           "mgal",        "kaf",         0.0,                 0.0030688737237723352  ],
    ["Volume",                           "mgal",        "kgal",        0.0,                 1000.0                 ],
    ["Volume",                           "mgal",        "km3",         0.0,                 3.7854e-006            ],
    ["Volume",                           "mgal",        "m3",          0.0,                 3785.4                 ],
    ["Volume",                           "mgal",        "mgal",        0.0,                 1.0                    ],
    ["Volume",                           "mgal",        "mile3",       0.0,                 9.0816575632467304e-007],
    ["Volume",                           "mile3",       "1000 m3",     0.0,                 4168181.8254405796     ],
    ["Volume",                           "mile3",       "ac-ft",       0.0,                 3379200.0              ],
    ["Volume",                           "mile3",       "dsf",         0.0,                 1703680.0              ],
    ["Volume",                           "mile3",       "ft3",         0.0,                 1.47197952E+011        ],
    ["Volume",                           "mile3",       "gal",         0.0,                 1101120575220.7375     ],
    ["Volume",                           "mile3",       "kaf",         0.0,                 3379.2                 ],
    ["Volume",                           "mile3",       "kgal",        0.0,                 1101120575.2207375     ],
    ["Volume",                           "mile3",       "km3",         0.0,                 4.1681818254405796     ],
    ["Volume",                           "mile3",       "m3",          0.0,                 4168181825.4405794     ],
    ["Volume",                           "mile3",       "mgal",        0.0,                 1101120.5752207374     ],
    ["Volume",                           "mile3",       "mile3",       0.0,                 1.0                    ],
]

unitConversionsByUnitIds = {}
for abstractParam, fromUnit, toUnit, offset, factor in unitConversions :
    unitConversionsByUnitIds[abstractParam, fromUnit, toUnit] = {"OFFSET" : offset, "FACTOR" : factor}

#--------------#
# Data quality #
#--------------#
'''
Data Quality Rules :

    1. Unless the Screened bit is set, no other bits can be set.
       
    2. Unused bits (22, 24, 27-31, 32+) must be reset (zero).       

    3. The Okay, Missing, Questioned and Rejected bits are mutually 
       exclusive.

    4. No replacement cause or replacement method bits can be set unless
       the changed (different) bit is also set, and if the changed (different)
       bit is set, one of the cause bits and one of the replacement
       method bits must be set.

    5. Replacement Cause integer is in range 0..4.

    6. Replacement Method integer is in range 0..4

    7. The Test Failed bits are not mutually exclusive (multiple tests can be
       marked as failed).

Bit Mappings :       
    
         3                   2                   1                     
     2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 

     P - - - - - T T - T - T T T T T T M M M M C C C D R R V V V V S 
     |           <---------+---------> <--+--> <-+-> | <+> <--+--> |
     |                     |              |      |   |  |     |    +------Screened T/F
     |                     |              |      |   |  |     +-----------Validity Flags
     |                     |              |      |   |  +--------------Value Range Integer
     |                     |              |      |   +-------------------Different T/F
     |                     |              |      +---------------Replacement Cause Integer
     |                     |              +---------------------Replacement Method Integer
     |                     +-------------------------------------------Test Failed Flags
     +-------------------------------------------------------------------Protected T/F
                                                              
'''

q_screened = {
    "shift"  : 0,
    "values" : [
        (0,    "UNSCREENED",     "The value has not been screened"),
        (1,    "SCREENED",       "The value has been screened"    )]}

q_validity = {
    "shift"  : 1,
    "values" : [      
        (0,    "UNKNOWN",        "The validity of the value has not been assessed"),
        (1,    "OKAY",           "The value is accepted as valid"                 ),
        (2,    "MISSING",        "The value has not been reported or computed"    ),
        (4,    "QUESTIONABLE",   "The validity of the value doubtful"             ),
        (8,    "REJECTED",       "The value is rejected as invalid"               )]}

q_value_range = {
    "shift"  : 5,
    "values" : [
        (0,    "NO_RANGE",       "The value is not greater than the 1st range limit or limits were not tested"),
        (1,    "RANGE_1",        "The value is greater than the 1st, but not the 2nd range limit"             ),
        (2,    "RANGE_2",        "The value is greater than the 2nd, but not the 3rd range limit"             ),
        (3,    "RANGE_3",        "The value is greater than the 3rd range limit"                              )]}

q_different = {
    "shift"  : 7,
    "values" : [
        (0,    "ORIGINAL",       "The value has not been changed from the original report or computation"),
        (1,    "MODIFIED",       "The value has been changed from the original report or computation")]}

q_replacement_cause = {
    "shift"  : 8,
    "values" : [
        (0,    "NONE",           "The value was not replaced"                                          ),
        (1,    "AUTOMATIC",      "The value was automatically replaced by a pre-set software condition"), # e.g. Interpolated by DATCHK
        (2,    "INTERACTIVE",    "The value was interactively replaced using a software tool"          ), # e.g. "Fill" operation in Data Validation Editor
        (3,    "MANUAL",         "The value was specified explicitly"                                  ), # e.g. Value typed in from keyboard
        (4,    "RESTORED",       "The value was restored to the original report or computation"        )]}

q_replacement_method = {
    "shift"  : 11,
    "values" : [
        (0,    "NONE",           "The value was not replaced"                    ),
        (1,    "LIN_INTERP",     "The value was replaced by linear interpolation"),
        (2,    "EXPLICIT",       "The value was replaced by manual change"       ),
        (3,    "MISSING",        "The value was replaced with missing"           ),
        (4,    "GRAPHICAL",      "The value was replaced graphically"            )]}

q_test_failed = {
    "shift"  : 15,
    "values" : [
        (0,    "NONE",           "The value passed all specified tests"              ),
        (1,    "ABSOLUTE_VALUE", "The value failed an absolute magnitude test"       ),
        (2,    "CONSTANT_VALUE", "The value failed a constant value test"            ),
        (4,    "RATE_OF_CHANGE", "The value failed a rate of change test"            ),
        (8,    "RELATIVE_VALUE", "The value failed a relative magnitude test"        ),
        (16,   "DURATION_VALUE", "The value failed a duration-magnitude test"        ),
        (32,   "NEG_INCREMENT",  "The value failed a negative incremental value test"),
        (128,  "SKIP_LIST",      "The value was specifically excluded from testing"  ),
        (512,  "USER_DEFINED",   "The value failed a user-defined test"              ),
        (1024, "DISTRIBUTION",   "The value failed a distribution test"              )]}
#
# rebuild q_test_failed["values"] to include all combinations of values listed
#
testFailedCombinations = uniqueCombinations(q_test_failed["values"][1:])
q_test_failed["values"] = q_test_failed["values"][:1] 
for items in testFailedCombinations :
    if len(items) == 0 :
        continue
    if len(items) == 1 :
        value = items[0][0]
        id    = items[0][1]
        desc  = items[0][2]
    else :
        values, ids, descriptions = zip(*items)
        value = sum(values)
        id    = "+".join(ids)
        desc  = "The value failed %d tests" % len(items)
    q_test_failed["values"].append((value, id, desc))        

q_protection = {
    "shift"  : 31,
    "values" : [
        (0,    "UNPROTECTED",    "The value is not protected"),
        (1,    "PROTECTED",      "The value is protected"    )]}

#------------#
# Parameters #
#------------#
sys.stderr.write("Processing parameter definitions.\n")
parameters = [
#    ------ ----------------------------------- ----------- --------------------- ---------- ---------- -------------- -----------------------------------------------------------------------------
#                                                                                  db        -----    Default  ------
#                                                                                 store      ------Display Units-----
#    CODE   ABSTRACT PARAMETER                  ID          NAME                  UNIT ID      SI       Non-SI         DESCRIPTION
#    ------ ----------------------------------- ----------- --------------------- ---------- ---------- -------------- -----------------------------------------------------------------------------
    [ 1,    "None",                             "%",        "Precent",            "%",       "%",       "%",           "Ratio expressed as hundredths"                                               ],
    [ 2,    "Area",                             "Area",     "Surface Area",       "m2",      "m2",      "ft2",         "Area of a surface"                                                           ],
    [ 7,    "Count",                            "Count",    "Count",              "unit",    "unit",    "unit",        "Progressive sum of items enumerated one by one or group by group."           ],
    [ 8,    "Currency",                         "Currency", "Currency",           "$",       "$",       "$",           "Economic value expressed as currency/money"                                  ],
    [44,    "None",                             "Coeff",    "Coefficient",        "n/a",     "n/a",     "n/a",         "Unitless coefficient for formulas"                                           ],
    [ 6,    "Conductivity",                     "Cond",     "Conductivity",       "umho/cm", "umho/cm", "umho/cm",     "Ability of an aqueous solution to conduct electricity"                       ],
    [ 4,    "None",                             "Code",     "Coded Information",  "n/a",     "n/a",     "n/a",         "Numeric code symbolically representing a phenomenon"                         ],
    [ 5,    "Mass Concentration",               "Conc",     "Concentration",      "mg/l",    "mg/l",    "ppm",         "Relative content of a component dissolved or dispersed in a volume of water" ],
    [36,    "Length",                           "Dist",     "Distance",           "km",      "km",      "mi",          "Distance between two points."                                                ],
    [ 3,    "Angle",                            "Dir",      "Direction",          "deg",     "deg",     "deg",         "Map direction specified clockwise from North"                                ],
    [ 9,    "Length",                           "Depth",    "Depth",              "mm",      "mm",      "in",          "Depth of any form of water above the ground surface"                         ],
    [13,    "Linear Speed",                     "EvapRate", "Evaporation Rate",   "mm/day",  "mm/day",  "in/day",      "Rate of liquid water evaporation"                                            ],
    [11,    "Energy",                           "Energy",   "Energy",             "MWh",     "MWh",     "MWh",         "Energy, work, or quantity of heat"                                           ],
    [10,    "Length",                           "Elev",     "Elevation",          "m",       "m",       "ft",          "The height of a surface above a datum which approximates sea level"          ],
    [12,    "Length",                           "Evap",     "Evaporation",        "mm",      "mm",      "in",          "Liquid water lost to vapor measured as an equivalent depth of liquid water"  ],
    [35,    "Count",                            "Fish",     "Fish Count",         "unit",    "unit",    "unit",        "Fish Count."                                                                 ],
    [15,    "Length",                           "Frost",    "Ground Frost",       "cm",      "cm",      "in",          "Depth of frost penetration into the ground (non-permafrost)"                 ],
    [14,    "Volume Rate",                      "Flow",     "Flow Rate",          "cms",     "cms",     "cfs",         "Volume rate of moving water"                                                 ],
    [40,    "Length",                           "Height",   "Height",             "m",       "m",       "ft",          "The height of a surface above an arbitrary datum"                            ],
    [32,    "Irradiance",                       "Irrad",    "Irradiance",         "W/m2",    "W/m2",    "langley/min", "Radiant Power on a unit area of irradiated surface."                         ],
    [42,    "Length",                           "Length",   "Length",             "m",       "m",       "ft",          "Linear displacement associated with the larger horizontal planar measurment" ],
    [16,    "Length",                           "Opening",  "Opening Height",     "m",       "m",       "ft",          "Height of opening controlling passage of water"                              ],
    [20,    "Pressure",                         "Pres",     "Pressure",           "kPa",     "kPa",     "in-hg",       "Pressure (force per unit area)"                                              ],
    [19,    "Length",                           "Precip",   "Precipitation",      "mm",      "mm",      "in",          "Deposit on the earth of hail, mist, rain, sleet, or snow"                    ],
    [17,    "Hydrogen Ion Concentration Index", "pH",       "pH",                 "su",      "su",      "su",          "Negative logarithm of hydrogen-ion concentration in a solution"              ],
    [18,    "Power",                            "Power",    "Power",              "MW",      "MW",      "MW",          "Energy rate, Radiant Flux"                                                   ],
    [21,    "Irradiation",                      "Rad",      "Irradiation",        "J/m2",    "J/m2",    "langley",     "Radiant energy on a unit area of irradiated surface."                        ],
    [41,    "Angle",                            "Rotation", "Rotation",           "deg",     "deg",     "deg",         "Angular displacement"                                                        ],
    [37,    "None",                             "Ratio",    "Ratio",              "n/a",     "n/a",     "n/a",         "Quotient of two numbers having the same units"                               ],
    [31,    "Angular Speed",                    "SpinRate", "Spin Rate",          "rpm",     "rpm",     "rpm",         "Number of revolutions made about an axis per unit of time"                   ],
    [24,    "Volume",                           "Stor",     "Storage",            "m3",      "m3",      "ac-ft",       "Volume of impounded water"                                                   ],
    [23,    "Length",                           "Stage",    "Stage",              "m",       "m",       "ft",          "The height of a water surface above a designated datum other than sea level" ],
    [22,    "Linear Speed",                     "Speed",    "Speed",              "kph",     "kph",     "mph",         "Rate of moving substance or object irrespective of direction"                ],
    [26,    "Length",                           "Thick",    "Thickness",          "cm",      "cm",      "in",          "Thickness of sheet of substance"                                             ],
    [38,    "Turbidity",                        "TurbF",    "Turbidity",          "FNU",     "FNU",     "FNU",         "Measurement of scattered light at an angle of 90+/-2.5 degrees to the incident light beam from a monochromatic light source (860+/-60 nm) (ISO 7027)"],
    [25,    "Temperature",                      "Temp",     "Temperature",        "C",       "C",       "F",           "Hotness or coldness of a substance based on measuring expansion of mercury"  ],
    [34,    "Turbidity",                        "TurbN",    "Turbidity",          "NTU",     "NTU",     "NTU",         "Measurement of scattered light at an angle of 90+/-30 degrees to the incident light beam from a white light source (540+/-140 nm) (EPA method 180.1)"],
    [33,    "Turbidity",                        "TurbJ",    "Turbidity",          "JTU",     "JTU",     "JTU",         "Measurement of interference to the passage of light by matter in suspension" ],
    [30,    "Length",                           "Travel",   "Accumulated Travel", "km",      "km",      "mi",          "Accumulated movement of a fluid past a point"                                ],
    [28,    "Turbidity",                        "Turb",     "Turbidity",          "JTU",     "JTU",     "JTU",         "Measurement of interference to the passage of light by matter in suspension" ],
    [27,    "Elapsed Time",                     "Timing",   "Timing",             "sec",     "sec",     "sec",         "A duration of a phenomenon"                                                  ],
    [29,    "Electromotive Potential",          "Volt",     "Voltage",            "volt",    "volt",    "volt",        "Electric Potential"                                                          ],
    [39,    "Volume",                           "Volume",   "Volume",             "m3",      "m3",      "ft3",         "Volume of anything other than impounded water"                               ],
    [43,    "Length",                           "Width",    "Width",              "m",       "m",       "ft",          "Linear displacement associated with the smaller horizontal planar measurment"],
]

cwmsUnitParamDefsById = {}
for paramCode, abstractParam, paramId, name, id, siId, enId, desc in parameters : 
#    uid = abstractParam + '.' + id
    cwmsUnitParamDefsById[abstractParam + '.' + id] = unitDefsById[abstractParam + '.' + id]["CODE"]
cwmsUnitParamIds = cwmsUnitParamDefsById.keys()

#------------------------#
# Default Sub-Parameters #
#------------------------#
sys.stderr.write("Processing default sub_parameter definitions.\n")
subParameters = [
#           --  DEFAULT Sub_Parameters -------------------------------    -- Display Units --  
#           Base        Sub                                       
#           Param       Param          Sub-Parameter Descripiton           SI         Non-SI
#     ----- ----------- -------------- ---------------------------------- ---------- ---------
    [ 301,  "%",        "ofArea-Snow", "Percent of Area Covered by Snow", "%",       "%"],                                         
    [ 302,  "%",        "Opening",     "Percent Open",                    "%",       "%"],                                             
    [ 303,  "Conc",     "Acidity",     "Acidity Concentration",           "mg/l",    "ppm"],                          
    [ 304,  "Conc",     "Alkalinity",  "Alkalinity Concentration",        "mg/l",    "ppm"],                      
    [ 305,  "Conc",     "DO",          "Disolved Oxygen Concentration",   "mg/l",    "ppm"],                              
    [ 306,  "Conc",     "Iron",        "Iron Concentration",              "mg/l",    "ppm"],                            
    [ 307,  "Conc",     "Sulfate",     "Sulfate Concentration",           "mg/l",    "ppm"],                         
    [ 308,  "Conc",     "Salinity",    "Salinity Concentration",          "g/l",     "g/l"],                         
    [ 309,  "Depth",    "Snow",        "Snow Depth",                      "mm",      "in"],                                         
    [ 310,  "Depth",    "SnowWE",      "Snow Water Equivalance",          "mm",      "in"],                                       
    [ 311,  "Flow",     "In",          "Inflow",                          "cms",     "cfs"],                                      
    [ 312,  "Flow",     "Out",         "Outflow",                         "cms",     "cfs"],                                     
    [ 313,  "Flow",     "Reg",         "Regulated Flow",                  "cms",     "cfs"],                                     
    [ 314,  "Flow",     "Spill",       "Spillway Flow",                   "cms",     "cfs"],                                   
    [ 315,  "Flow",     "Unreg",       "Unregulated Flow",                "cms",     "cfs"],                                   
    [ 316,  "Temp",     "Air",         "Air Temperature",                 "C",       "F"],                                       
    [ 317,  "Temp",     "Water",       "Water Temperature",               "C",       "F"],                                     
]

#-----------------#
# Parameter Types #
#-----------------#
sys.stderr.write("Processing parameter types.\n")
parameterTypes = [
    {"ID" : "Total", "DESCRIPTION" : "TOTAL"        },
    {"ID" : "Max",   "DESCRIPTION" : "MAXIMUM"      },
    {"ID" : "Min",   "DESCRIPTION" : "MINIMUM"      },
    {"ID" : "Const", "DESCRIPTION" : "CONSTANT"     },
    {"ID" : "Ave",   "DESCRIPTION" : "AVERAGE"      },
    {"ID" : "Inst",  "DESCRIPTION" : "INSTANTANEOUS"},
]

#---------------------#
# DSS Parameter Types #
#---------------------#
sys.stderr.write("Processing HEC-DSS parameter types.\n")
dssParameterTypes = [
    {"ID" : "PER-AVER", "DB_TYPE" : "Ave",   "DESCRIPTION" : "Average over a period"              },
    {"ID" : "PER-CUM",  "DB_TYPE" : "Total", "DESCRIPTION" : "Accumulation over a period"         },
    {"ID" : "INST-VAL", "DB_TYPE" : "Inst",  "DESCRIPTION" : "Value observed at an instant"       },
    {"ID" : "INST-CUM", "DB_TYPE" : "Inst",  "DESCRIPTION" : "Accumulation observed at an instant"},
    {"ID" : "PER-MIN",  "DB_TYPE" : "Min",   "DESCRIPTION" : "Minumum over a period"              },
    {"ID" : "PER-MAX",  "DB_TYPE" : "Max",   "DESCRIPTION" : "Maximum over a period"              }
]

#-------------------------#
# DSS Exchange Directions #
#-------------------------#
sys.stderr.write("Processing HEC-DSS exchange directions.\n")
dssXchgDirections = [
    {"DSS_XCHG_DIRECTION_ID" : "DssToOracle", "DESCRIPTION" : "Direction is incoming to database (post)"},
    {"DSS_XCHG_DIRECTION_ID" : "OracleToDss", "DESCRIPTION" : "Direction is outgoing from database (extract)"},
]

#-----------------#
# Time Zone Usage #
#-----------------#
sys.stderr.write("Processing time zone usage types.\n")
tzUsages = [
    {"ID" : "Standard",   "DESCRIPTION" : "Use constant offset for zone standard time"},
    {"ID" : "Daylight",   "DESCRIPTION" : "Use constant offset for zone daylight savings time"},
    {"ID" : "Local",      "DESCRIPTION" : "Use varying offset for zone local time" },
]

#----------------#
# Rating Methods #
#----------------#
sys.stderr.write("Processing rating methods.\n")
ratingMethods = [
    ['NULL'        , 'Return null if between values or outside range'                                            ],
    ['ERROR'       , 'Raise an exception if between values or outside range'                                     ],
    ['LINEAR'      , 'Linear interpolation or extrapolation of independent and dependent values'                 ],
    ['LOGARITHMIC' , 'Logarithmic interpolation or extrapolation of independent and dependent values'            ],
    ['LIN-LOG'     , 'Linear interpolation/extrapoloation of independent values, Logarithmic of dependent values'],
    ['LOG-LIN'     , 'Logarithmic interpolation/extrapoloation of independent values, Linear of dependent values'],
    ['PREVIOUS'    , 'Return the value that is lower in position'                                                ],
    ['NEXT'        , 'Return the value that is higher in position'                                               ],
    ['NEAREST'     , 'Return the value that is nearest in position'                                              ],
    ['LOWER'       , 'Return the value that is lower in magnitude'                                               ],
    ['HIGHER'      , 'Return the value that is higher in magnitude'                                              ],
    ['CLOSEST'     , 'Return the value that is closest in magnitude'                                             ],
]

#---------------#
# Catalog items #
#---------------#
sys.stderr.write("Processing catalog items.\n")
catalogItems = [
    ['CAT_COUNTY',       'COUNTY_ID',                   'CAT_COUNTY',       'COUNTY_ID'                  ],
    ['CAT_COUNTY',       'COUNTY_NAME',                 'CAT_COUNTY',       'COUNTY_NAME'                ],
    ['CAT_COUNTY',       'STATE_ID_UC',                 'CAT_COUNTY',       'STATE_ID_UC'                ],
    ['CAT_COUNTY',       'STATE_INITIAL',               'CAT_COUNTY',       'STATE_INITIAL'              ],
    ['CAT_GOES',         'GOES_ID',                     'CAT_GOES',         'GOES_ID'                    ],
    ['CAT_GOES',         'GOES_NAME',                   'CAT_GOES',         'GOES_NAME'                  ],
    ['CAT_LOCATION',     'GOES_ID',                     'CAT_LOCATION',     'GOES_ID'                    ],
    ['CAT_LOCATION',     'GOES_NAME',                   'CAT_LOCATION',     'GOES_NAME'                  ],
    ['CAT_LOCATION',     'LOCATION_ID',                 'CAT_LOCATION',     'LOCATION_ID'                ],
    ['CAT_LOCATION',     'NWS_HB5_ID',                  'CAT_LOCATION',     'NWS_HB5_ID'                 ],
    ['CAT_LOCATION',     'NWS_HB5_NAME',                'CAT_LOCATION',     'NWS_HB5_NAME'               ],
    ['CAT_LOCATION',     'OFFICE_ID',                   'CAT_LOCATION',     'OFFICE_ID'                  ],
    ['CAT_LOCATION',     'OTHER_ID',                    'CAT_LOCATION',     'OTHER_ID'                   ],
    ['CAT_LOCATION',     'OTHER_NAME',                  'CAT_LOCATION',     'OTHER_NAME'                 ],
    ['CAT_LOCATION',     'SHEF_ID',                     'CAT_LOCATION',     'SHEF_ID'                    ],
    ['CAT_LOCATION',     'SHEF_NAME',                   'CAT_LOCATION',     'SHEF_NAME'                  ],
    ['CAT_LOCATION',     'USGS_ID',                     'CAT_LOCATION',     'USGS_ID'                    ],
    ['CAT_LOCATION',     'USGS_NAME',                   'CAT_LOCATION',     'USGS_NAME'                  ],
    ['CAT_NWS_HB5',      'NWS_HB5_ID',                  'CAT_NWS_HB5',      'NWS_HB5_ID'                 ],
    ['CAT_NWS_HB5',      'NWS_NAME',                    'CAT_NWS_HB5',      'NWS_NAME'                   ],
    ['CAT_OFFICE',       'OFFICE_ID',                   'CAT_OFFICE',       'OFFICE_ID'                  ],
    ['CAT_OFFICE',       'OFFICE_NAME',                 'CAT_OFFICE',       'OFFICE_NAME'                ],
    ['CAT_OTHER',        'OTHER_ID',                    'CAT_OTHER',        'OTHER_ID'                   ],
    ['CAT_OTHER',        'OTHER_NAME',                  'CAT_OTHER',        'OTHER_NAME'                 ],
    ['CAT_SHEF',         'SHEF_ID',                     'CAT_SHEF',         'SHEF_ID'                    ],
    ['CAT_SHEF',         'SHEF_NAME',                   'CAT_SHEF',         'SHEF_NAME'                  ],
    ['CAT_STATE',        'STATE_ID_UC',                 'CAT_STATE',        'STATE_ID_UC'                ],
    ['CAT_STATE',        'STATE_INITIAL',               'CAT_STATE',        'STATE_INITIAL'              ],
    ['CAT_STATE',        'STATE_NAME',                  'CAT_STATE',        'STATE_NAME'                 ],
    ['CAT_SUBLOCATION',  'SUBLOCATION_DESC',            'CAT_SUBLOCATION',  'SUBLOCATION_DESC'           ],
    ['CAT_SUBLOCATION',  'SUBLOCATION_ID',              'CAT_SUBLOCATION',  'SUBLOCATION_ID'             ],
    ['CAT_SUBPARAMETER', 'PARAMETER_ID',                'CAT_SUBPARAMETER', 'PARAMETER_ID'               ],
    ['CAT_SUBPARAMETER', 'SUBPARAMETER_DESC',           'CAT_SUBPARAMETER', 'SUBPARAMETER_DESC'          ],
    ['CAT_SUBPARAMETER', 'SUBPARAMETER_ID',             'CAT_SUBPARAMETER', 'SUBPARAMETER_ID'            ],
    ['CAT_TS_DESC',      'DURATION_ID',                 'CAT_TS_DESC',      'DURATION_ID'                ],
    ['CAT_TS_DESC',      'INTERVAL_ID',                 'CAT_TS_DESC',      'INTERVAL_ID'                ],
    ['CAT_TS_DESC',      'LOCATION_ID',                 'CAT_TS_DESC',      'LOCATION_ID'                ],
    ['CAT_TS_DESC',      'OFFICE_ID',                   'CAT_TS_DESC',      'OFFICE_ID'                  ],
    ['CAT_TS_DESC',      'PARAMETER_ID',                'CAT_TS_DESC',      'PARAMETER_ID'               ],
    ['CAT_TS_DESC',      'PARAMETER_TYPE_ID',           'CAT_TS_DESC',      'PARAMETER_TYPE_ID'          ],
    ['CAT_TS_DESC',      'SUBCWMS_ID',                  'CAT_TS_DESC',      'SUBCWMS_ID'                 ],
    ['CAT_TS_DESC',      'SUBPARAMETER_ID',             'CAT_TS_DESC',      'SUBPARAMETER_ID'            ],
    ['CAT_TS_DESC',      'TS_GROUP',                    'CAT_TS_DESC',      'TS_GROUP'                   ],
    ['CAT_TS_DESC',      'VERSION',                     'CAT_TS_DESC',      'VERSION'                    ],
    ['CAT_USGS',         'USGS_ID',                     'CAT_USGS',         'USGS_ID'                    ],
    ['CAT_USGS',         'USGS_NAME',                   'CAT_USGS',         'USGS_NAME'                  ],
    ['WCV_RATING_DESC',  'LOCATION_ID',                 'WCV_RATING_DESC',  'LOCATION_ID'                ],
    ['WCV_RATING_DESC',  'MEASURED_1_PARAMETER_ID',     'WCV_RATING_DESC',  'MEASURED_1_PARAMETER_ID'    ],
    ['WCV_RATING_DESC',  'MEASURED_2_PARAMETER_ID',     'WCV_RATING_DESC',  'MEASURED_2_PARAMETER_ID'    ],
    ['WCV_RATING_DESC',  'OFFICE_ID',                   'WCV_RATING_DESC',  'OFFICE_ID'                  ],
    ['WCV_RATING_DESC',  'RATED_PARAMETER_ID',          'WCV_RATING_DESC',  'RATED_PARAMETER_ID'         ],
    ['WCV_RATING_DESC',  'RATING_CODE',                 'WCV_RATING_DESC',  'RATING_CODE'                ],
    ['WCV_RATING_DESC',  'RATING_TYPE_ID',              'WCV_RATING_DESC',  'RATING_TYPE_ID'             ],
    ['WCV_RATING_DESC',  'SUB_LOCATION_ID',             'WCV_RATING_DESC',  'SUB_LOCATION_ID'            ],
    ['WCV_RATING_DESC',  'SUB_MEASURED_1_PARAMETER_ID', 'WCV_RATING_DESC',  'SUB_MEASURED_1_PARAMETER_ID'],
    ['WCV_RATING_DESC',  'SUB_MEASURED_2_PARAMETER_ID', 'WCV_RATING_DESC',  'SUB_MEASURED_2_PARAMETER_ID'],
    ['WCV_RATING_DESC',  'SUB_RATED_PARAMETER_ID',      'WCV_RATING_DESC',  'SUB_RATED_PARAMETER_ID'     ],
    ['WCV_RATING_DESC',  'VERSION',                     'WCV_RATING_DESC',  'VERSION'                    ],
]


#------------------#
# CWMS ERROR CODES #
#------------------#
sys.stderr.write("Processing cwms error codes \n")

#     ERR_CODE  ERR_NAME                    ERR_MSG
#     --------  --------------------------- -----------------------------------------------------------------
errorCodes = [
    ['-20001', 'TS_ID_NOT_FOUND',       'The timeseries identifier "%1" was not found'                ],
    ['-20002', 'TS_IS_INVALID',         'The timeseries identifier "%1" is not valid %2'              ],
    ['-20003', 'TS_ALREADY_EXISTS',     'The timeseries identifier "%1" is already in use'            ],
    ['-20004', 'INVALID_INTERVAL_ID',   '"%1" is not a valid CWMS timeseries interval'                ],
    ['-20005', 'INVALID_DURATION_ID',   '"%1" is not a valid CWMS timeseries Duration'                ],
    ['-20006', 'INVALID_PARAM_ID',      '"%1" is not a valid CWMS timeseries Parameter'               ],
    ['-20007', 'INVALID_PARAM_TYPE',    '"%1" is not a valid CWMS timeseries Parameter Type'          ],
    ['-20010', 'INVALID_OFFICE_ID',     '"%1" is not a valid CWMS office id'                          ],
    ['-20011', 'INVALID_STORE_RULE',    '"%1" is not a recognized Store Rule'                         ],
    ['-20012', 'INVALID_DELETE_ACTION', '"%1" is not a recognized Delete Action'                      ],
    ['-20013', 'INVALID_UTC_OFFSET',    'The UTC Offset: "%1" is not valid for a "%2" Interval value' ],
    ['-20014', 'TS_ID_NOT_CREATED',     'Unable to create TS ID: "%1"'                                ],
    ['-20015', 'XCHG_TS_ERROR',         'Time series "%1" cannot be configured for realtime exchange in set "%2" in the opposite direction from its configuration in set "%3".'],
    ['-20016', 'XCHG_RATING_ERROR',     'Rating series "%1" cannot be configured for realtime exchange in set "%2" in the opposite direction from its configuration in set "%3".'],
    ['-20017', 'XCHG_TIME_VALUE',       'Error converting "%1" to timestamp. Required format is "%2".'],
    ['-20018', 'XCHG_NO_DATA',          'Table "%1" has no data for code "%2" at time "%3".'          ],
    ['-20019', 'INVALID_ITEM',          '"%1" is not a valid %2.'                                     ],
    ['-20020', 'ITEM_ALREADY_EXISTS',   '"%1" "%2" already exists.'                                   ],
    ['-20021', 'ITEM_NOT_CREATED',      'Unable to create %1 "%2".'                                   ],
    ['-20022', 'STATE_CANNOT_BE_NULL',  '"%1"-The State/Provence must be specified when specifying a County/Region.'],
    ['-20023', 'INVALID_T_F_FLAG',      '"%1" - Must be either T or F.'                               ],
    ['-20024', 'INVALID_T_F_FLAG_OLD',  '"%1" - Must be either 1 for True or 0 for False.'            ],
    ['-20025', 'LOCATION_ID_NOT_FOUND', 'The Location: "%1" does not exist.'                     ],
    ['-20026', 'LOCATION_ID_ALREADY_EXISTS', '"%1"-The Location: "%2" already exists.'                ],
    ['-20027', 'INVLAID_FULL_ID',       '"%1" is not a valid Location or Parameter id.'               ],
    ['-20028', 'RENAME_LOC_BASE_1',     'Unable to rename. An old Base Location: "%1" can not be renamed to a non-Base Location: "%2".' ],
    ['-20029', 'RENAME_LOC_BASE_2',     'Unable to rename. The new Location: "%1" already exists.' ],
    ['-20030', 'RENAME_LOC_BASE_3',     'Unable to rename. The new Location: "%1" matches the existing old location.' ],
    ['-20031', 'CAN_NOT_DELETE_LOC_1',  'Can not delete location: "%1" because Timeseries Identifiers exist.' ],
    ['-20032', 'CANNOT_DELETE_UNIT_1',  'Cannot delete or rename unit alias "%1"; it is in use by %2.'],
    ['-20033', 'DUPLICATE_XCHG_MAP',    'Mapping of "%1" to "%2 already exists in exchage set "%3", but with different parameters.'],
    ['-20034', 'ITEM_DOES_NOT_EXIST',   '%1 "%2" does not exist.'],
    ['-20035', 'DATA_STREAM_NOT_FOUND', 'The "%1" data stream was not found'                          ],
    ['-20036', 'PARAM_CANNOT_BE_NULL ', 'The "%1" parameter cannot be "NULL".'                        ],
    ['-20037', 'CANNOT_RENAME_1',       'Unable to rename. An old id of: "%1" was not found.'],
    ['-20038', 'CANNOT_RENAME_2',       'Unable to rename. The new id: "%1" already exists.'],
    ['-20039', 'CANNOT_RENAME_3',       'Unable to rename. The new id: "%1" matches the old.'],
    ['-20040', 'CANNOT_DELETE_DATA_STREAM','Cannot delete data stream: "%". It still has SHEF spec''s assigned to it.'],
    ['-20041', 'INVALID_FULL_ID',       '"%1" is an invalid id.'                                      ],
    ['-20042', 'CANNOT_CHANGE_OFFSET',  'Cannot change interval utc offset of time series with stored data: "%1"' ],
    ['-20043', 'INVALID_SNAP_WINDOW',   'Snap Window can not be greater than the cwms_ts_id Interval'],
    ['-20044', 'SHEF_DUP_TS_ID',        'CWMS_TS_ID "%1" has already been used.'],
    ['-20045', 'ITEM_OWNED_BY_CWMS',    'The %1: "%2" is owned by the system and cannot be changed or deleted.'],
    ['-20046', 'NO_CRIT_FILE_FOUND',    'A crit file for the %1 datastream was not found.'],
    ['-20102', 'UNIT_CONV_NOT_FOUND',   'The units conversion for "%1" was not found'                 ],
    ['-20103', 'INVALID_TIME_ZONE',     'The time zone "%1" is not a valid Oracle time zone region'   ],
    ['-20104', 'UNITS_NOT_SPECIFIED',   'You must specifiy the UNITS of your data'                    ],
    ['-20234', 'ITEMS_ARE_IDENTICAL',   '%1'                                                          ],
    ['-20244', 'NULL_ARGUMENT',         'Argument %1 is not allowed to be null'                       ],
    ['-20254', 'ARRAY_LENGTHS_DIFFER',  '%1 arrays must have identical lengths'                       ],
    ['-20997', 'GENERIC_ERROR',         '%1'                                                          ],
    ['-20998', 'ERROR',                 '%1'                                                          ],
    ['-20999', 'UNKNOWN_EXCEPTION',     'The requested exception is not in the CWMS_ERROR table: "%1"'],
]

#-------------------#
# LOG MESSAGE TYPES #
#-------------------#
sys.stderr.write("Processing log message types \n")
logMessageTypes = [
#      CODE  ID
#      ----  -----------------------
    [ 1, 'AcknowledgeAlarm'     ],
    [ 2, 'AcknowledgeRequest'   ],
    [ 3, 'Alarm'                ],
    [ 4, 'ControlMessage'       ],
    [ 5, 'DeactivateAlarm'      ],
    [ 6, 'Exception Thrown'     ],
    [ 7, 'Fatal Error'          ],
    [ 8, 'Initialization Error' ],
    [ 9, 'Initiated'            ],
    [10, 'Load Library Error'   ],
    [11, 'MissedHeartBeat'      ],
    [12, 'PreventAlarm'         ],
    [13, 'RequestAction'        ],
    [14, 'ResetAlarm'           ],
    [15, 'Runtime Exec Error'   ],
    [16, 'Shutting Down'        ],
    [17, 'State'                ],
    [18, 'Status'               ],
    [19, 'StatusIntervalMinutes'],
    [20, 'Terminated'           ],
]

#----------------------------#
# LOG MESSAGE PROPERTY TYPES #
#----------------------------#
sys.stderr.write("Processing log message property types \n")
logMessagePropTypes = [
#      CODE  ID
#      ----  --------
    [1, 'boolean'],
    [2, 'byte'   ],
    [3, 'short'  ],
    [4, 'int'    ],
    [5, 'long'   ],
    [6, 'float'  ],
    [7, 'double' ],
    [8, 'String' ],
]

#-------------------#
# INTERPOLATE UNITS #
#-------------------#
sys.stderr.write("Processing interpolate units \n")
interpolateUnits = [
#      CODE  ID
#      ----  --------
    [1, 'minutes'  ],
    [2, 'intervals'],
]

#---------------------#
# LOCATION CATEGORIES #
#---------------------#
sys.stderr.write("Processing location categories \n")
locationKinds = [
#   CODE  ID        DESCRIPTION
#   ----  --------  -----------------------------------------------------------------------------
    [1,   'POINT',        'A generic location that can be represented by a single lat/lon.'               ],
    [2,   'STREAM',       'A stream, the lat/lon represent the downstream-most point.'                    ],
    [3,   'BASIN',        'A basin, the lat/lon represent the point on the major stream draing the basin.'],
]

#--------------#
# GAGE METHODS #
#--------------#
sys.stderr.write("Processing gage methods \n")
gageMethods = [
#   CODE  ID             DESCRIPTION
#   ----  -----------    ---------------------------------------
    [1,   'MANUAL',      'No communication method'             ],
    [2,   'GOES',        'Gage communicates via GOES satellite'],
    [3,   'LOS',         'Line-of-site radio'                  ],
    [4,   'METEORBURST', 'Gage communicates via meteorburst'   ],
    [5,   'PHONE',       'Gage communicates via telephone'     ],
    [6,   'INTERNET',    'Gage communicates via internet'      ],
]

#------------#
# GAGE TYPES #
#------------#
sys.stderr.write("Processing gage types \n")
gageTypes = [
#   CODE  ID         MANNUALLY_READ   INQUIRY_METHOD TX_METHOD    DESCRIPTION
#   ----  ---------- ---------------  -------------- ------------ ------------------------
    [1,   'GOES_T',  'F',             'NULL',        'GOES',      'GOES TX-only'],
    [2,   'GOES_TI', 'F',             'GOES',        'GOES',      'GOES TX+INQ'],
    [3,   'LOS_T',   'F',             'NULL',        'LOS',       'LOS TX-only'],
    [4,   'LOS_TI',  'F',             'LOS',         'LOS',       'LOS TX+INQ'],
    [5,   'INET_T',  'F',             'NULL',        'INETERNET', 'INTERNET TX-only'],
    [6,   'INET_TI', 'F',             'INTERNET',    'INETERNET', 'INTERNET TX+INQ'],
]

#---------#
# NATIONS #
#---------#
nations = [
#    CODE   ID
#        ----   -------------   
    ["AF",  "AFGHANISTAN"],
    ["AX",  "ÅLAND ISLANDS"],
    ["AL",  "ALBANIA"],
    ["DZ",  "ALGERIA"],
    ["AS",  "AMERICAN SAMOA"],
    ["AD",  "ANDORRA"],
    ["AO",  "ANGOLA"],
    ["AI",  "ANGUILLA"],
    ["AQ",  "ANTARCTICA"],
    ["AG",  "ANTIGUA AND BARBUDA"],
    ["AR",  "ARGENTINA"],
    ["AM",  "ARMENIA"],
    ["AW",  "ARUBA"],
    ["AU",  "AUSTRALIA"],
    ["AT",  "AUSTRIA"],
    ["AZ",  "AZERBAIJAN"],
    ["BS",  "BAHAMAS"],
    ["BH",  "BAHRAIN"],
    ["BD",  "BANGLADESH"],
    ["BB",  "BARBADOS"],
    ["BY",  "BELARUS"],
    ["BE",  "BELGIUM"],
    ["BZ",  "BELIZE"],
    ["BJ",  "BENIN"],
    ["BM",  "BERMUDA"],
    ["BT",  "BHUTAN"],
    ["BO",  "BOLIVIA"],
    ["BA",  "BOSNIA AND HERZEGOVINA"],
    ["BW",  "BOTSWANA"],
    ["BV",  "BOUVET ISLAND"],
    ["BR",  "BRAZIL"],
    ["IO",  "BRITISH INDIAN OCEAN TERRITORY"],
    ["BN",  "BRUNEI DARUSSALAM"],
    ["BG",  "BULGARIA"],
    ["BF",  "BURKINA FASO"],
    ["BI",  "BURUNDI"],
    ["KH",  "CAMBODIA"],
    ["CM",  "CAMEROON"],
    ["CA",  "CANADA"],
    ["CV",  "CAPE VERDE"],
    ["KY",  "CAYMAN ISLANDS"],
    ["CF",  "CENTRAL AFRICAN REPUBLIC"],
    ["TD",  "CHAD"],
    ["CL",  "CHILE"],
    ["CN",  "CHINA"],
    ["CX",  "CHRISTMAS ISLAND"],
    ["CC",  "COCOS (KEELING) ISLANDS"],
    ["CO",  "COLOMBIA"],
    ["KM",  "COMOROS"],
    ["CG",  "CONGO"],
    ["CD",  "CONGO, THE DEMOCRATIC REPUBLIC OF THE"],
    ["CK",  "COOK ISLANDS"],
    ["CR",  "COSTA RICA"],
    ["CI",  "CÔTE D'IVOIRE"],
    ["HR",  "CROATIA"],
    ["CU",  "CUBA"],
    ["CY",  "CYPRUS"],
    ["CZ",  "CZECH REPUBLIC"],
    ["DK",  "DENMARK"],
    ["DJ",  "DJIBOUTI"],
    ["DM",  "DOMINICA"],
    ["DO",  "DOMINICAN REPUBLIC"],
    ["EC",  "ECUADOR"],
    ["EG",  "EGYPT"],
    ["SV",  "EL SALVADOR"],
    ["GQ",  "EQUATORIAL GUINEA"],
    ["ER",  "ERITREA"],
    ["EE",  "ESTONIA"],
    ["ET",  "ETHIOPIA"],
    ["FK",  "FALKLAND ISLANDS (MALVINAS)"],
    ["FO",  "FAROE ISLANDS"],
    ["FJ",  "FIJI"],
    ["FI",  "FINLAND"],
    ["FR",  "FRANCE"],
    ["GF",  "FRENCH GUIANA"],
    ["PF",  "FRENCH POLYNESIA"],
    ["TF",  "FRENCH SOUTHERN TERRITORIES"],
    ["GA",  "GABON"],
    ["GM",  "GAMBIA"],
    ["GE",  "GEORGIA"],
    ["DE",  "GERMANY"],
    ["GH",  "GHANA"],
    ["GI",  "GIBRALTAR"],
    ["GR",  "GREECE"],
    ["GL",  "GREENLAND"],
    ["GD",  "GRENADA"],
    ["GP",  "GUADELOUPE"],
    ["GU",  "GUAM"],
    ["GT",  "GUATEMALA"],
    ["GG",  "GUERNSEY"],
    ["GN",  "GUINEA"],
    ["GW",  "GUINEA-BISSAU"],
    ["GY",  "GUYANA"],
    ["HT",  "HAITI"],
    ["HM",  "HEARD ISLAND AND MCDONALD ISLANDS"],
    ["VA",  "HOLY SEE (VATICAN CITY STATE)"],
    ["HN",  "HONDURAS"],
    ["HK",  "HONG KONG"],
    ["HU",  "HUNGARY"],
    ["IS",  "ICELAND"],
    ["IN",  "INDIA"],
    ["ID",  "INDONESIA"],
    ["IR",  "IRAN, ISLAMIC REPUBLIC OF"],
    ["IQ",  "IRAQ"],
    ["IE",  "IRELAND"],
    ["IM",  "ISLE OF MAN"],
    ["IL",  "ISRAEL"],
    ["IT",  "ITALY"],
    ["JM",  "JAMAICA"],
    ["JP",  "JAPAN"],
    ["JE",  "JERSEY"],
    ["JO",  "JORDAN"],
    ["KZ",  "KAZAKHSTAN"],
    ["KE",  "KENYA"],
    ["KI",  "KIRIBATI"],
    ["KP",  "KOREA, DEMOCRATIC PEOPLE'S REPUBLIC OF"],
    ["KR",  "KOREA, REPUBLIC OF"],
    ["KW",  "KUWAIT"],
    ["KG",  "KYRGYZSTAN"],
    ["LA",  "LAO PEOPLE'S DEMOCRATIC REPUBLIC"],
    ["LV",  "LATVIA"],
    ["LB",  "LEBANON"],
    ["LS",  "LESOTHO"],
    ["LR",  "LIBERIA"],
    ["LY",  "LIBYAN ARAB JAMAHIRIYA"],
    ["LI",  "LIECHTENSTEIN"],
    ["LT",  "LITHUANIA"],
    ["LU",  "LUXEMBOURG"],
    ["MO",  "MACAO"],
    ["MK",  "MACEDONIA, THE FORMER YUGOSLAV REPUBLIC OF"],
    ["MG",  "MADAGASCAR"],
    ["MW",  "MALAWI"],
    ["MY",  "MALAYSIA"],
    ["MV",  "MALDIVES"],
    ["ML",  "MALI"],
    ["MT",  "MALTA"],
    ["MH",  "MARSHALL ISLANDS"],
    ["MQ",  "MARTINIQUE"],
    ["MR",  "MAURITANIA"],
    ["MU",  "MAURITIUS"],
    ["YT",  "MAYOTTE"],
    ["MX",  "MEXICO"],
    ["FM",  "MICRONESIA, FEDERATED STATES OF"],
    ["MD",  "MOLDOVA, REPUBLIC OF"],
    ["MC",  "MONACO"],
    ["MN",  "MONGOLIA"],
    ["ME",  "MONTENEGRO"],
    ["MS",  "MONTSERRAT"],
    ["MA",  "MOROCCO"],
    ["MZ",  "MOZAMBIQUE"],
    ["MM",  "MYANMAR"],
    ["NA",  "NAMIBIA"],
    ["NR",  "NAURU"],
    ["NP",  "NEPAL"],
    ["NL",  "NETHERLANDS"],
    ["AN",  "NETHERLANDS ANTILLES"],
    ["NC",  "NEW CALEDONIA"],
    ["NZ",  "NEW ZEALAND"],
    ["NI",  "NICARAGUA"],
    ["NE",  "NIGER"],
    ["NG",  "NIGERIA"],
    ["NU",  "NIUE"],
    ["NF",  "NORFOLK ISLAND"],
    ["MP",  "NORTHERN MARIANA ISLANDS"],
    ["NO",  "NORWAY"],
    ["OM",  "OMAN"],
    ["PK",  "PAKISTAN"],
    ["PW",  "PALAU"],
    ["PS",  "PALESTINIAN TERRITORY, OCCUPIED"],
    ["PA",  "PANAMA"],
    ["PG",  "PAPUA NEW GUINEA"],
    ["PY",  "PARAGUAY"],
    ["PE",  "PERU"],
    ["PH",  "PHILIPPINES"],
    ["PN",  "PITCAIRN"],
    ["PL",  "POLAND"],
    ["PT",  "PORTUGAL"],
    ["PR",  "PUERTO RICO"],
    ["QA",  "QATAR"],
    ["RE",  "RÉUNION"],
    ["RO",  "ROMANIA"],
    ["RU",  "RUSSIAN FEDERATION"],
    ["RW",  "RWANDA"],
    ["BL",  "SAINT BARTHÉLEMY"],
    ["SH",  "SAINT HELENA"],
    ["KN",  "SAINT KITTS AND NEVIS"],
    ["LC",  "SAINT LUCIA"],
    ["MF",  "SAINT MARTIN"],
    ["PM",  "SAINT PIERRE AND MIQUELON"],
    ["VC",  "SAINT VINCENT AND THE GRENADINES"],
    ["WS",  "SAMOA"],
    ["SM",  "SAN MARINO"],
    ["ST",  "SAO TOME AND PRINCIPE"],
    ["SA",  "SAUDI ARABIA"],
    ["SN",  "SENEGAL"],
    ["RS",  "SERBIA"],
    ["SC",  "SEYCHELLES"],
    ["SL",  "SIERRA LEONE"],
    ["SG",  "SINGAPORE"],
    ["SK",  "SLOVAKIA"],
    ["SI",  "SLOVENIA"],
    ["SB",  "SOLOMON ISLANDS"],
    ["SO",  "SOMALIA"],
    ["ZA",  "SOUTH AFRICA"],
    ["GS",  "SOUTH GEORGIA AND THE SOUTH SANDWICH ISLANDS"],
    ["ES",  "SPAIN"],
    ["LK",  "SRI LANKA"],
    ["SD",  "SUDAN"],
    ["SR",  "SURINAME"],
    ["SJ",  "SVALBARD AND JAN MAYEN"],
    ["SZ",  "SWAZILAND"],
    ["SE",  "SWEDEN"],
    ["CH",  "SWITZERLAND"],
    ["SY",  "SYRIAN ARAB REPUBLIC"],
    ["TW",  "TAIWAN, PROVINCE OF CHINA"],
    ["TJ",  "TAJIKISTAN"],
    ["TZ",  "TANZANIA, UNITED REPUBLIC OF"],
    ["TH",  "THAILAND"],
    ["TL",  "TIMOR-LESTE"],
    ["TG",  "TOGO"],
    ["TK",  "TOKELAU"],
    ["TO",  "TONGA"],
    ["TT",  "TRINIDAD AND TOBAGO"],
    ["TN",  "TUNISIA"],
    ["TR",  "TURKEY"],
    ["TM",  "TURKMENISTAN"],
    ["TC",  "TURKS AND CAICOS ISLANDS"],
    ["TV",  "TUVALU"],
    ["UG",  "UGANDA"],
    ["UA",  "UKRAINE"],
    ["AE",  "UNITED ARAB EMIRATES"],
    ["GB",  "UNITED KINGDOM"],
    ["US",  "UNITED STATES"],
    ["UM",  "UNITED STATES MINOR OUTLYING ISLANDS"],
    ["UY",  "URUGUAY"],
    ["UZ",  "UZBEKISTAN"],
    ["VU",  "VANUATU"],
    ["VE",  "VENEZUELA, BOLIVARIAN REPUBLIC OF"],
    ["VN",  "VIET NAM"],
    ["VG",  "VIRGIN ISLANDS, BRITISH"],
    ["VI",  "VIRGIN ISLANDS, U.S."],
    ["WF",  "WALLIS AND FUTUNA"],
    ["EH",  "WESTERN SAHARA"],
    ["YE",  "YEMEN"],
    ["ZM",  "ZAMBIA"],
    ["ZW",  "ZIMBABWE"],
]

#--------------#
# STREAM TYPES #
#--------------#
streamTypes = [
#    ID      CHANNELS    ENTRENCHMENT WIDTH/DEPTH        SINUOSITY          SLOPE           MATERIAL
#    --------------------------------------------------------------------------------------------------
    ['A1a+', 'SINGLE',   '< 1.4',     '< 12',            '< 1.2',           '> 0.10',       'BEDROCK'  ],   
    ['A2a+', 'SINGLE',   '< 1.4',     '< 12',            '< 1.2',           '> 0.10',       'BOULDERS' ],   
    ['A3a+', 'SINGLE',   '< 1.4',     '< 12',            '< 1.2',           '> 0.10',       'COBBLE'   ],   
    ['A4a+', 'SINGLE',   '< 1.4',     '< 12',            '< 1.2',           '> 0.10',       'GRAVEL'   ],   
    ['A5a+', 'SINGLE',   '< 1.4',     '< 12',            '< 1.2',           '> 0.10',       'SAND'     ],   
    ['A6a+', 'SINGLE',   '< 1.4',     '< 12',            '< 1.2',           '> 0.10',       'SILT/CLAY'],
    ['A1',   'SINGLE',   '< 1.4',     '< 12',            '< 1.2',           '0.04 - 0.10',  'BEDROCK'  ],   
    ['A2',   'SINGLE',   '< 1.4',     '< 12',            '< 1.2',           '0.04 - 0.10',  'BOULDERS' ],   
    ['A3',   'SINGLE',   '< 1.4',     '< 12',            '< 1.2',           '0.04 - 0.10',  'COBBLE'   ],   
    ['A4',   'SINGLE',   '< 1.4',     '< 12',            '< 1.2',           '0.04 - 0.10',  'GRAVEL'   ],   
    ['A5',   'SINGLE',   '< 1.4',     '< 12',            '< 1.2',           '0.04 - 0.10',  'SAND'     ],   
    ['A6',   'SINGLE',   '< 1.4',     '< 12',            '< 1.2',           '0.04 - 0.10',  'SILT/CLAY'],
    ['G1',   'SINGLE',   '< 1.4',     '< 12',            '> 1.2',           '0.02 - 0.039', 'BEDROCK'  ],   
    ['G2',   'SINGLE',   '< 1.4',     '< 12',            '> 1.2',           '0.02 - 0.039', 'BOULDERS' ],   
    ['G3',   'SINGLE',   '< 1.4',     '< 12',            '> 1.2',           '0.02 - 0.039', 'COBBLE'   ],   
    ['G4',   'SINGLE',   '< 1.4',     '< 12',            '> 1.2',           '0.02 - 0.039', 'GRAVEL'   ],   
    ['G5',   'SINGLE',   '< 1.4',     '< 12',            '> 1.2',           '0.02 - 0.039', 'SAND'     ],   
    ['G6',   'SINGLE',   '< 1.4',     '< 12',            '> 1.2',           '0.02 - 0.039', 'SILT/CLAY'],
    ['G1c',  'SINGLE',   '< 1.4',     '< 12',            '> 1.2',           '< 0.02',       'BEDROCK'  ],   
    ['G2c',  'SINGLE',   '< 1.4',     '< 12',            '> 1.2',           '< 0.02',       'BOULDERS' ],   
    ['G3c',  'SINGLE',   '< 1.4',     '< 12',            '> 1.2',           '< 0.02',       'COBBLE'   ],   
    ['G4c',  'SINGLE',   '< 1.4',     '< 12',            '> 1.2',           '< 0.02',       'GRAVEL'   ],   
    ['G5c',  'SINGLE',   '< 1.4',     '< 12',            '> 1.2',           '< 0.02',       'SAND'     ],   
    ['G6c',  'SINGLE',   '< 1.4',     '< 12',            '> 1.2',           '< 0.02',       'SILT/CLAY'],
    ['F1b',  'SINGLE',   '< 1.4',     '> 12',            '> 1.2',           '0.02 - 0.039', 'BEDROCK'  ],   
    ['F2b',  'SINGLE',   '< 1.4',     '> 12',            '> 1.2',           '0.02 - 0.039', 'BOULDERS' ],   
    ['F3b',  'SINGLE',   '< 1.4',     '> 12',            '> 1.2',           '0.02 - 0.039', 'COBBLE'   ],   
    ['F4b',  'SINGLE',   '< 1.4',     '> 12',            '> 1.2',           '0.02 - 0.039', 'GRAVEL'   ],   
    ['F5b',  'SINGLE',   '< 1.4',     '> 12',            '> 1.2',           '0.02 - 0.039', 'SAND'     ],   
    ['F6b',  'SINGLE',   '< 1.4',     '> 12',            '> 1.2',           '0.02 - 0.039', 'SILT/CLAY'],
    ['F1',   'SINGLE',   '< 1.4',     '> 12',            '> 1.2',           '< 0.02',       'BEDROCK'  ],   
    ['F2',   'SINGLE',   '< 1.4',     '> 12',            '> 1.2',           '< 0.02',       'BOULDERS' ],   
    ['F3',   'SINGLE',   '< 1.4',     '> 12',            '> 1.2',           '< 0.02',       'COBBLE'   ],   
    ['F4',   'SINGLE',   '< 1.4',     '> 12',            '> 1.2',           '< 0.02',       'GRAVEL'   ],   
    ['F5',   'SINGLE',   '< 1.4',     '> 12',            '> 1.2',           '< 0.02',       'SAND'     ],   
    ['F6',   'SINGLE',   '< 1.4',     '> 12',            '> 1.2',           '< 0.02',       'SILT/CLAY'],
    ['B1a',  'SINGLE',   '1.4 - 2.2', '> 12',            '> 1.2',           '0.04 - 0.099', 'BEDROCK'  ],   
    ['B2a',  'SINGLE',   '1.4 - 2.2', '> 12',            '> 1.2',           '0.04 - 0.099', 'BOULDERS' ],   
    ['B3a',  'SINGLE',   '1.4 - 2.2', '> 12',            '> 1.2',           '0.04 - 0.099', 'COBBLE'   ],   
    ['B4a',  'SINGLE',   '1.4 - 2.2', '> 12',            '> 1.2',           '0.04 - 0.099', 'GRAVEL'   ],   
    ['B5a',  'SINGLE',   '1.4 - 2.2', '> 12',            '> 1.2',           '0.04 - 0.099', 'SAND'     ],   
    ['B6a',  'SINGLE',   '1.4 - 2.2', '> 12',            '> 1.2',           '0.04 - 0.099', 'SILT/CLAY'],
    ['B1b',  'SINGLE',   '1.4 - 2.2', '> 12',            '> 1.2',           '0.02 - 0.039', 'BEDROCK'  ],   
    ['B2b',  'SINGLE',   '1.4 - 2.2', '> 12',            '> 1.2',           '0.02 - 0.039', 'BOULDERS' ],   
    ['B3b',  'SINGLE',   '1.4 - 2.2', '> 12',            '> 1.2',           '0.02 - 0.039', 'COBBLE'   ],   
    ['B4b',  'SINGLE',   '1.4 - 2.2', '> 12',            '> 1.2',           '0.02 - 0.039', 'GRAVEL'   ],   
    ['B5b',  'SINGLE',   '1.4 - 2.2', '> 12',            '> 1.2',           '0.02 - 0.039', 'SAND'     ],   
    ['B6b',  'SINGLE',   '1.4 - 2.2', '> 12',            '> 1.2',           '0.02 - 0.039', 'SILT/CLAY'],
    ['B1',   'SINGLE',   '1.4 - 2.2', '> 12',            '> 1.2',           '< 0.02',       'BEDROCK'  ],   
    ['B2',   'SINGLE',   '1.4 - 2.2', '> 12',            '> 1.2',           '< 0.02',       'BOULDERS' ],   
    ['B3',   'SINGLE',   '1.4 - 2.2', '> 12',            '> 1.2',           '< 0.02',       'COBBLE'   ],   
    ['B4',   'SINGLE',   '1.4 - 2.2', '> 12',            '> 1.2',           '< 0.02',       'GRAVEL'   ],   
    ['B5',   'SINGLE',   '1.4 - 2.2', '> 12',            '> 1.2',           '< 0.02',       'SAND'     ],   
    ['B6',   'SINGLE',   '1.4 - 2.2', '> 12',            '> 1.2',           '< 0.02',       'SILT/CLAY'],
    ['E3b',  'SINGLE',   '> 2.2',     '< 12',            '> 1.5',           '0.02 - 0.039', 'COBBLE'   ],   
    ['E4b',  'SINGLE',   '> 2.2',     '< 12',            '> 1.5',           '0.02 - 0.039', 'GRAVEL'   ],   
    ['E5b',  'SINGLE',   '> 2.2',     '< 12',            '> 1.5',           '0.02 - 0.039', 'SAND'     ],   
    ['E6b',  'SINGLE',   '> 2.2',     '< 12',            '> 1.5',           '0.02 - 0.039', 'SILT/CLAY'],
    ['E3',   'SINGLE',   '> 2.2',     '< 12',            '> 1.5',           '< 0.02',       'COBBLE'   ],   
    ['E4',   'SINGLE',   '> 2.2',     '< 12',            '> 1.5',           '< 0.02',       'GRAVEL'   ],   
    ['E5',   'SINGLE',   '> 2.2',     '< 12',            '> 1.5',           '< 0.02',       'SAND'     ],   
    ['E6',   'SINGLE',   '> 2.2',     '< 12',            '> 1.5',           '< 0.02',       'SILT/CLAY'],
    ['C1b',  'SINGLE',   '> 2.2',     '> 12',            '> 1.2',           '0.02 - 0.039', 'BEDROCK'  ],   
    ['C2b',  'SINGLE',   '> 2.2',     '> 12',            '> 1.2',           '0.02 - 0.039', 'BOULDERS' ],   
    ['C3b',  'SINGLE',   '> 2.2',     '> 12',            '> 1.2',           '0.02 - 0.039', 'COBBLE'   ],   
    ['C4b',  'SINGLE',   '> 2.2',     '> 12',            '> 1.2',           '0.02 - 0.039', 'GRAVEL'   ],   
    ['C5b',  'SINGLE',   '> 2.2',     '> 12',            '> 1.2',           '0.02 - 0.039', 'SAND'     ],   
    ['C6b',  'SINGLE',   '> 2.2',     '> 12',            '> 1.2',           '0.02 - 0.039', 'SILT/CLAY'],   
    ['C1',   'SINGLE',   '> 2.2',     '> 12',            '> 1.2',           '0.001 - 0.02', 'BEDROCK'  ],   
    ['C2',   'SINGLE',   '> 2.2',     '> 12',            '> 1.2',           '0.001 - 0.02', 'BOULDERS' ],   
    ['C3',   'SINGLE',   '> 2.2',     '> 12',            '> 1.2',           '0.001 - 0.02', 'COBBLE'   ],   
    ['C4',   'SINGLE',   '> 2.2',     '> 12',            '> 1.2',           '0.001 - 0.02', 'GRAVEL'   ],   
    ['C5',   'SINGLE',   '> 2.2',     '> 12',            '> 1.2',           '0.001 - 0.02', 'SAND'     ],   
    ['C6',   'SINGLE',   '> 2.2',     '> 12',            '> 1.2',           '0.001 - 0.02', 'SILT/CLAY'],   
    ['C1c-', 'SINGLE',   '> 2.2',     '> 12',            '> 1.2',           '< 0.001',      'BEDROCK'  ],   
    ['C2c-', 'SINGLE',   '> 2.2',     '> 12',            '> 1.2',           '< 0.001',      'BOULDERS' ],   
    ['C3c-', 'SINGLE',   '> 2.2',     '> 12',            '> 1.2',           '< 0.001',      'COBBLE'   ],   
    ['C4c-', 'SINGLE',   '> 2.2',     '> 12',            '> 1.2',           '< 0.001',      'GRAVEL'   ],   
    ['C5c-', 'SINGLE',   '> 2.2',     '> 12',            '> 1.2',           '< 0.001',      'SAND'     ],   
    ['C6c-', 'SINGLE',   '> 2.2',     '> 12',            '> 1.2',           '< 0.001',      'SILT/CLAY'],   
    ['D3b',  'MULTIPLE', None,        'VERY HIGH',       'VERY LOW',        '0.02 - 0.039', 'COBBLE'   ],   
    ['D4b',  'MULTIPLE', None,        'VERY HIGH',       'VERY LOW',        '0.02 - 0.039', 'GRAVEL'   ],   
    ['D5b',  'MULTIPLE', None,        'VERY HIGH',       'VERY LOW',        '0.02 - 0.039', 'SAND'     ],   
    ['D6b',  'MULTIPLE', None,        'VERY HIGH',       'VERY LOW',        '0.02 - 0.039', 'SILT/CLAY'],   
    ['D3',   'MULTIPLE', None,        'VERY HIGH',       'VERY LOW',        '0.001 - 0.02', 'COBBLE'   ],   
    ['D4',   'MULTIPLE', None,        'VERY HIGH',       'VERY LOW',        '0.001 - 0.02', 'GRAVEL'   ],   
    ['D5',   'MULTIPLE', None,        'VERY HIGH',       'VERY LOW',        '0.001 - 0.02', 'SAND'     ],   
    ['D6',   'MULTIPLE', None,        'VERY HIGH',       'VERY LOW',        '0.001 - 0.02', 'SILT/CLAY'],   
    ['D4c-', 'MULTIPLE', None,        'VERY HIGH',       'VERY LOW',        '< 0.001',      'GRAVEL'   ],   
    ['D5c-', 'MULTIPLE', None,        'VERY HIGH',       'VERY LOW',        '< 0.001',      'SAND'     ],   
    ['D6c-', 'MULTIPLE', None,        'VERY HIGH',       'VERY LOW',        '< 0.001',      'SILT/CLAY'],   
    ['DA4',  'MULTIPLE', None,        'HIGHLY VARIABLE', 'HIGHLY VARIABLE', '< 0.005',      'GRAVEL'   ],   
    ['DA5',  'MULTIPLE', None,        'HIGHLY VARIABLE', 'HIGHLY VARIABLE', '< 0.005',      'SAND'     ],   
    ['DA6',  'MULTIPLE', None,        'HIGHLY VARIABLE', 'HIGHLY VARIABLE', '< 0.005',      'SILT/CLAY'],   
]

#--------------------------------------------------#
# parse the offices into dbhost_offices dictionary #
#--------------------------------------------------#
office_names = {}
dbhost_offices = {}
office_erocs = {}
db_office_code = {}
for ofcCode, office_id, office_name, report_to, dbhost, eroc in offices :
    if dbhost == '' : continue
    office_erocs[office_id] = eroc
    db_office_code[office_id] = ofcCode
    if not dbhost : dbhost = office_id
    office_names[office_id] = office_name
    if not dbhost_offices.has_key(dbhost) : dbhost_offices[dbhost] = []
    dbhost_offices[dbhost].append(office_id);

dbhosts = dbhost_offices.keys()
dbhosts.sort()

#-------------------------------------------------------------------------------#
# make sure the user entered a schema before the office ids on the command line #
#-------------------------------------------------------------------------------#
if user in dbhosts :
    sys.stderr.write("No schema name was entered before the office id(s)\n\n")
    sys.stderr.write("Usage: python buildSqlScripts.py <schema name> [<host officeid> [<other officeid(s)>]] [/[no]testaccount]\n")
    sys.stderr.write("Ex:    python buildSqlScripts.py cwms SWF SWG /testaccount\n")
    sys.exit(-1)

#----------------------------------------------------------------------------------------#  
# prompt the user for the primary and sharing offices if not entered on the command line #
#----------------------------------------------------------------------------------------#  
if not db_office_id:
    print
    for dbhost in dbhosts :
        line = "%-5s : %s" % (dbhost, office_names[dbhost_offices[dbhost][0]])
        for i in range(1, len(dbhost_offices[dbhost])) : 
            line += ", %s" % office_names[dbhost_offices[dbhost][i]]
        print line

    #------------------------------------------------------------------------------
    # Ask for the db_office_id for this database, i.e., the primary office id
    # for this database.
    #------------------------------------------------------------------------------
    print
    print 'Enter the office id for this database. If your office is not listed'
    print 'or if your building a secondary COOP database for your office, then'
    print 'please contact HEC for a revised install script.'
    ok = False
    while not ok :
        print
        db_office_id = raw_input('Enter the primary office id for this database: ')
        if not db_office_id :
            print
            print "ERROR! You must enter your office id."
            continue
        else :
            ok = db_office_id in dbhosts

        if ok :
            print 'You have chosen the following office as the primary office for this'
            print "database: %s" % db_office_id
            line = raw_input("Is this correct? (y/n) [n] > ")
            if not line or line[0].upper() != 'Y' :
                ok = False
        else :
            print
            print "ERROR! Office %s does not host a database. Contact HEC if this" % db_office_id
            print "is no longer the case."
        
    #------------------------------------------------------------------------------
    # Ask if any other offices will be sharing this database - need to know so that
    # queues can be set-up for them.
    #------------------------------------------------------------------------------
    print
    for dbhost in dbhosts :
        if dbhost != db_office_id :
            line = "%-5s : %s" % (dbhost, office_names[dbhost_offices[dbhost][0]])
            for i in range(1, len(dbhost_offices[dbhost])) : 
                line += ", %s" % office_names[dbhost_offices[dbhost][i]]
            print line
    print
    print 'Will other offices share this database as either their primary database'
    print 'or as a backup database? If so, enter the office id(s) from the above'
    print 'list. If this datbase will only be used by your office, then simply'
    print 'press Enter.'
    print 
    ok = False
    while not ok :
        print
        line  = raw_input('Enter office id(s) of offices sharing this database: ')
        print
        office_ids = line.upper().replace(',', ' ').replace(';', ' ').split()
        if not office_ids :
            ok = True
        else :
            for office_id in office_ids :
                if office_id == db_office_id :
                    office_ids.remove(office_id)
                if office_id == 'CWMS' : 
                    office_ids = dbhosts[:]
                    office_ids.remove('LCRA')
                    ok = True
                    break
                if office_id not in dbhosts :
                    print "Office %s does not host a database." % office_id
                    break
            else :
                ok = True
                
        if ok :
            print 'You have made the follwing choices:'
            print "Primary office for this database: %s" % db_office_id
            if not office_ids :
                print "No other offices will share this database."
            else:
                print "Office(s) sharing this database: %s" % ','.join(office_ids)
            line = raw_input("Is this correct? (y/n) [n] > ")
            if not line or line[0].upper() != 'Y' :
                ok = False

#----------------------------------------------------------------------------------#        
# prompt the user about creating a test account if not entered on the command line #
#----------------------------------------------------------------------------------#        
if testAccount == None:
    print
    print '-----------TEST ACCOUNT-----------'
    print
    line = raw_input('--Do you want to create test accounts? [n]: ')
    testAccount = line.strip().upper().startswith('Y')
    print

if testAccount :
    db_office_eroc = office_erocs[db_office_id].lower()
    test_user_id = db_office_eroc +"hectest"
    print
    print "                                               ---------"
    print "-- The following test account will be created: %s" % test_user_id
    print "                                               ---------"
    print "-- This account will have write privileges on all -REV ts ids"
    print "-- and read privileges on all -RAW ts ids for the %s " % db_office_id
    print "-- database."
    print
    
#------------------------------------------------------------------------------
# Consolidate db_office_id and shared office_ids
#------------------------------------------------------------------------------
office_ids.insert(0, db_office_id)

test_user_template = '''
--
-- ignore errors
--
whenever sqlerror continue

drop user &eroc.hectest;
drop user &eroc.hectest_ro;
drop user &eroc.hectest_db;
drop user &eroc.hectest_ua;
drop user &eroc.hectest_dx;
drop user &eroc.hectest_da;
drop user &eroc.hectest_vt;
drop user &eroc.hectest_dv;

--
-- notice errors
--
whenever sqlerror exit sql.sqlcode

variable test_passwd varchar2(50)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
exec :test_passwd := '&test_passwd';

clear

DECLARE
    test_passwd  VARCHAR2 (50) := :test_passwd;
    group_list   "&cwms_schema"."CHAR_32_ARRAY_TYPE";
BEGIN
    -- hectest
    group_list := "&cwms_schema"."CHAR_32_ARRAY_TYPE" ('TS ID Creator', 'CWMS Users');
    "&cwms_schema"."CWMS_SEC"."CREATE_USER" ('&eroc.hectest', test_passwd, group_list, '&office_id');
    --
    -- hectest_ro
    group_list := "&cwms_schema"."CHAR_32_ARRAY_TYPE" ('TS ID Creator', 'CWMS Users', 'Viewer Users');
    "&cwms_schema"."CWMS_SEC"."CREATE_USER" ('&eroc.hectest_ro', test_passwd, group_list, '&office_id');
    --
    -- hectest_dba
    group_list := "&cwms_schema"."CHAR_32_ARRAY_TYPE" ('CWMS DBA Users');
    "&cwms_schema"."CWMS_SEC"."CREATE_USER" ('&eroc.hectest_db', test_passwd, group_list, '&office_id');
    --
    -- hectest_ua
    group_list := "&cwms_schema"."CHAR_32_ARRAY_TYPE" ('CWMS User Admins', 'TS ID Creator', 'Viewer Users');
    "&cwms_schema"."CWMS_SEC"."CREATE_USER" ('&eroc.hectest_ua', test_passwd, group_list, '&office_id');
    --
    -- hectest_dx
    group_list := "&cwms_schema"."CHAR_32_ARRAY_TYPE" ('Data Exchange Mgr', 'TS ID Creator', 'CWMS Users');
    "&cwms_schema"."CWMS_SEC"."CREATE_USER" ('&eroc.hectest_dx', test_passwd, group_list, '&office_id');
    --
    -- hectest_da
    group_list := "&cwms_schema"."CHAR_32_ARRAY_TYPE" ('Data Acquisition Mgr', 'TS ID Creator', 'CWMS Users');
    "&cwms_schema"."CWMS_SEC"."CREATE_USER" ('&eroc.hectest_da', test_passwd, group_list, '&office_id');
    --
    -- hectest_vt
    group_list := "&cwms_schema"."CHAR_32_ARRAY_TYPE" ('VT Mgr', 'TS ID Creator', 'CWMS Users');
    "&cwms_schema"."CWMS_SEC"."CREATE_USER" ('&eroc.hectest_vt', test_passwd, group_list, '&office_id');
    --
    -- hectest_dv
    group_list := "&cwms_schema"."CHAR_32_ARRAY_TYPE" ('Data Acquisition Mgr', 'VT Mgr', 'TS ID Creator', 'CWMS Users');
    "&cwms_schema"."CWMS_SEC"."CREATE_USER" ('&eroc.hectest_dv', test_passwd, group_list, '&office_id');

END;
/
'''

user_template = '''
--
-- ignore errors
--
whenever sqlerror continue

drop user &eroc.cwmspd;
drop user &eroc.cwmsdbi;

--
-- notice errors
--
whenever sqlerror exit sql.sqlcode

variable dbi_passwd varchar2(50)
exec :dbi_passwd := '&dbi_passwd';

clear

DECLARE
    dbi_passwd      VARCHAR2 (50) := :dbi_passwd;
    group_list      "&cwms_schema"."CHAR_32_ARRAY_TYPE" := "&cwms_schema"."CHAR_32_ARRAY_TYPE"('CWMS PD Users');
BEGIN
    "&cwms_schema"."CWMS_SEC"."CREATE_CWMSDBI_DB_USER"('&eroc.cwmsdbi', dbi_passwd, '&office_id');

    "&cwms_schema"."CWMS_SEC"."CREATE_USER" ('&eroc.cwmspd', NULL, group_list, '&office_id');
    
    "&cwms_schema"."CWMS_SEC"."ASSIGN_TS_GROUP_USER_GROUP" ('All Rev TS IDs', 'Viewer Users', 'Read', '&office_id');
    
    "&cwms_schema"."CWMS_SEC"."ASSIGN_TS_GROUP_USER_GROUP" ('All TS IDs', 'CWMS Users', 'Read-Write', '&office_id');

END;
/
'''

queue_template = '''
   dbms_aqadm.create_queue_table(
      queue_table        => '%s_%s_table', 
      queue_payload_type => 'sys.aq$_jms_map_message',
      multiple_consumers => true);
      
   dbms_aqadm.create_queue(
      queue_name  => '%s_%s',
      queue_table => '%s_%s_table');
      
   dbms_aqadm.start_queue(queue_name => '%s_%s');
'''

#==============================================================================

sys.stderr.write("Creating py_ErocUsers.sql\n");
f  = open("py_ErocUsers.sql", "w")
users_created = []
for dbhost_id in office_ids :
    for office_id in dbhost_offices[dbhost_id] :
        eroc = office_erocs[office_id].lower()
        if eroc not in users_created :
            f.write(user_template.replace("&eroc.", eroc).replace("&office_id", dbhost_id))
            user_id = eroc+"cwmspd"
            users_created.append(eroc)
if test_user_id : 
    db_ofc_code = db_office_code[db_office_id]
    db_ofc_eroc = office_erocs[db_office_id]
    f.write(test_user_template.replace("&eroc.", eroc).replace("&office_id", dbhost_id))
f.close()

#==============================================================================
#==
#====
#====== createQueues
#--------------------------------------------------------------------#
# generate a script to create and start queues for specified offices #
#--------------------------------------------------------------------#

sys.stderr.write("Creating py_Queues.sql\n")
f = open("py_Queues.sql", "w")
f.write("set define off\nbegin")
for office_id in office_ids :
    id = office_id.lower()
    for q in ("realtime_ops", "status", "ts_stored") : 
        f.write(queue_template % (id,q,id,q,id,q,id,q))
f.write("end;\n/\ncommit;\n")
f.close()

#==============================================================================

prompt_template = '''
prompt
accept echo_state  char prompt 'Enter ON or OFF for echo         : '
accept inst        char prompt 'Enter the database SID           : '
accept sys_passwd  char prompt 'Enter the password for SYS       : '
accept cwms_passwd char prompt 'Enter the password for &cwms_schema   : '
accept dbi_passwd  char prompt 'Enter the password for %scwmsdbi : '
'''

prompt_test_line_template = '''
accept test_passwd  char prompt 'Enter the password for %s : '
'''

sys.stderr.write("Creating py_prompt.sql\n")
f = open("py_prompt.sql","w")
f.write(prompt_template % (db_office_eroc))
if test_user_id : f.write(prompt_test_line_template % (test_user_id))
f.close()
#==============================================================================
#====== createQueues
#====
#==

#==
#====
#======
#---------------------------------------------------#
# Table construction templates and loading commands #
#---------------------------------------------------#

sys.stderr.write("Building cwmsOfficeCreationTemplate\n")
cwmsOfficeCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE 
   (
       OFFICE_CODE           NUMBER(10)   NOT NULL,
       OFFICE_ID             VARCHAR2(16) NOT NULL,
       PUBLIC_NAME           VARCHAR2(32) NULL,
       LONG_NAME             VARCHAR2(80) NULL,
       REPORT_TO_OFFICE_CODE NUMBER(10)   NOT NULL,
       DB_HOST_OFFICE_CODE   NUMBER(10)   NOT NULL,
       EROC                  VARCHAR2(2)  NOT NULL
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
       ( 
          INITIAL 200K
          NEXT 200K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );


-----------------------------
-- @TABLE constraints --
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK PRIMARY KEY (OFFICE_CODE);
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_UK UNIQUE      (OFFICE_ID);


-----------------------------
-- @TABLE comments --
--
COMMENT ON TABLE @TABLE IS 'Corps of Engineer''s district and division offices.';
COMMENT ON COLUMN @TABLE."OFFICE_CODE" IS 'Unique office identifier, primarily used for internal database processing. This code is automatically assigned by the system.';
COMMENT ON COLUMN @TABLE.OFFICE_ID IS 'USACE code or symbol for a district or division office.  Record identifier that is meaningful to the user, e.g. NWS, MVS.  This is user defined.  If not defined during data entry, it defaults to OFFICE_CODE.';
COMMENT ON COLUMN @TABLE.LONG_NAME IS 'Long name used to refer to an office.';
COMMENT ON COLUMN @TABLE.REPORT_TO_OFFICE_CODE IS 'Organizationally, the office to report to.';
COMMENT ON COLUMN @TABLE.DB_HOST_OFFICE_CODE IS 'The office hosting the database for this office.';
COMMENT ON COLUMN @TABLE.EROC IS 'Corps of Engineers Reporting Organization Codes as per ER-37-1-27.';
COMMIT;
'''

sys.stderr.write("Building cwmsOfficeLoadTemplate\n")
cwmsOfficeLoadTemplate = ''
code = 0
for ofcCode, ofc, longName, reportTo, dbHost, eroc in offices :
    if reportTo :
        cwmsOfficeLoadTemplate +="INSERT INTO @TABLE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC)\n"
        cwmsOfficeLoadTemplate +="\tSELECT %d, '%s', '%s', OFFICE_CODE, %d, '%s' FROM @TABLE WHERE OFFICE_ID='%s';\n" % (ofcCode, ofc, longName, ofcCode, eroc, reportTo)
    else :
        cwmsOfficeLoadTemplate +="INSERT INTO @TABLE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC)\n"
        cwmsOfficeLoadTemplate +="\tVALUES (%d, '%s', '%s', %d, %d, '%s');\n" % (ofcCode, ofc, longName, ofcCode, ofcCode, eroc)
    code += 1
    
cwmsOfficeLoadTemplate +="UPDATE @TABLE SET DB_HOST_OFFICE_CODE=\n"
cwmsOfficeLoadTemplate +="\t(SELECT OFFICE_CODE FROM @TABLE WHERE OFFICE_ID='NWDP')\n"
cwmsOfficeLoadTemplate +="\tWHERE OFFICE_ID IN ('NWD', 'NWD', 'NWP', 'NWS', 'NWW');\n"

cwmsOfficeLoadTemplate +="COMMIT;"

sys.stderr.write("Building subLocationCreationTemplate\n")
subLocationCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE
   (
       SUBCWMS_CODE    NUMBER(10)   NOT NULL,
       SUBCWMS_ID      VARCHAR2(32) NOT NULL,
       DESCRIPTION     VARCHAR2(80)
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
       (
          INITIAL 20K
          NEXT 20K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );

-----------------------------
-- @TABLE indicies
--
CREATE UNIQUE INDEX @TABLE_UI ON @TABLE
   (
       UPPER(SUBCWMS_ID)
   )
       PCTFREE 10
       INITRANS 2
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
       ( 
          INITIAL 20k
          NEXT 20k
          MINEXTENTS 1
          MAXEXTENTS 20
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );

COMMIT;
'''

sys.stderr.write("Building subLocationLoadTemplate\n")
subLocationLoadTemplate = ''
for i in range(len(subLocations)) :
    subLocationLoadTemplate +="INSERT INTO @TABLE (SUBCWMS_CODE, SUBCWMS_ID) VALUES (%d, '%s');\n" % (i+1, subLocations[i])
subLocationLoadTemplate +="COMMIT;"

sys.stderr.write("Building shefDurationCreationTemplate\n")
shefDurationCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE(
  SHEF_DURATION_CODE     VARCHAR2(1 BYTE),
  SHEF_DURATION_DESC     VARCHAR2(128 BYTE),
  SHEF_DURATION_NUMERIC  VARCHAR2(4 BYTE),
  CWMS_DURATION_CODE     NUMBER
)
TABLESPACE @DATASPACE
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/


CREATE UNIQUE INDEX @TABLE_PK ON @TABLE
(SHEF_DURATION_CODE)
LOGGING
TABLESPACE @DATASPACE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


ALTER TABLE @TABLE ADD (
  CONSTRAINT @TABLE_PK
 PRIMARY KEY
 (SHEF_DURATION_CODE)
    USING INDEX 
    TABLESPACE @DATASPACE
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/


ALTER TABLE @TABLE ADD (
  CONSTRAINT @TABLE_R01 
 FOREIGN KEY (CWMS_DURATION_CODE) 
 REFERENCES CWMS_DURATION (DURATION_CODE))
/
'''
sys.stderr.write("Building shefDurationLoadTemplate\n")
shefDurationLoadTemplate = ''
for durCode, desc, durNum, cwmsDurCode in shef_duration :
    if durNum == 'NULL' :
        shefDurationLoadTemplate +="INSERT INTO @TABLE VALUES ('%s', '%s', %s, %s);\n" % (durCode, desc, durNum, cwmsDurCode)
    else :
        shefDurationLoadTemplate +="INSERT INTO @TABLE VALUES ('%s', '%s', '%s', %s);\n" % (durCode, desc, durNum, cwmsDurCode)
shefDurationLoadTemplate +="COMMIT;\n"

sys.stderr.write("Building statesCreationTemplate\n")
statesCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE
   (
       STATE_CODE    NUMBER(10)  NOT NULL,
       STATE_INITIAL VARCHAR2(2) NOT NULL,
       NAME          VARCHAR2(40)
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
       ( 
          INITIAL 20K
          NEXT 20K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );

----------------------------
-- @TABLE constraints --
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK PRIMARY KEY (STATE_CODE);

-------------------------
-- CWMS STATE comments --
--
COMMENT ON TABLE @TABLE IS 'STATE_CODE uses FIPS state number.';

COMMIT;
'''

sys.stderr.write("Building statesLoadTemplate\n")
statesLoadTemplate = ''
for id, initial, name in states :
    statesLoadTemplate +="INSERT INTO @TABLE VALUES (%s, '%s', '%s');\n" % (id, initial, name)
statesLoadTemplate +="COMMIT;\n"

sys.stderr.write("Building countiesCreationTemplate\n")
countiesCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE 
   (
       COUNTY_CODE NUMBER(10)   NOT NULL,
       COUNTY_ID   VARCHAR2(3)  NOT NULL,
       STATE_CODE  NUMBER(10)   NOT NULL,
       COUNTY_NAME VARCHAR2(40)
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
       ( 
          INITIAL 100K
          NEXT 50K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );

-----------------------------
-- @TABLE constraints --
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK PRIMARY KEY(COUNTY_CODE);
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_FK FOREIGN KEY(STATE_CODE) REFERENCES @statesTableName (STATE_CODE);
--------------------------
-- @TABLE comments --
--
COMMENT ON TABLE @TABLE IS 'County code uses state and county FIPS number   01 - State FIPS number   053 - FIPS number thus, county code is 01053.';

COMMIT;
'''

sys.stderr.write("Building countiesLoadTemplate\n")
countiesLoadTemplate = ''
for county_code, countyName in counties :
    stateId = "%2.2d" % (county_code / 1000)
    stateName = stateNamesById[stateId]
    county_id = "%3.3d" % (county_code % 1000)
    countiesLoadTemplate +="INSERT INTO @TABLE VALUES (\n"
    countiesLoadTemplate +="\t%d,\n" % county_code
    countiesLoadTemplate +="\t'%s',\n" % county_id
    countiesLoadTemplate +="\t(SELECT STATE_CODE FROM @statesTableName WHERE NAME='%s'),\n" % stateName
    countiesLoadTemplate +="\t'%s'\n" % countyName
    countiesLoadTemplate +=");\n"
countiesLoadTemplate +="COMMIT;\n"


sys.stderr.write("Building intervalOffsetCreationTemplate\n")
intervalOffsetCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE
   (
       INTERVAL_OFFSET_CODE    NUMBER(10)   NOT NULL,
       INTERVAL_OFFSET_ID      VARCHAR2(16) NOT NULL,
       INTERVAL_OFFSET_VALUE   NUMBER(10)   NOT NULL,
       DESCRIPTION             VARCHAR2(80) 
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
       (
          INITIAL 20K
          NEXT 20K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       ); 

-----------------------------
-- @TABLE indicies
--
CREATE UNIQUE INDEX @TABLE_UI ON @TABLE
   (
       UPPER(INTERVAL_OFFSET_ID)
   )
       PCTFREE 10
       INITRANS 2
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
       ( 
          INITIAL 20k
          NEXT 20k
          MINEXTENTS 1
          MAXEXTENTS 20
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );
     
COMMIT;
'''

sys.stderr.write("Building validValuesCreationTemplate\n")
validValuesCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE
   (
        COL_CODE             VARCHAR2(15) NOT NULL,
        VALUE_CODE           VARCHAR2(16) NOT NULL,
        VALUE_CODE_DESC      VARCHAR2(70) NULL
   )
        PCTFREE 10
        PCTUSED 40
        MAXTRANS 255
        TABLESPACE @DATASPACE
        STORAGE 
        (
          INITIAL 20K
          NEXT 20K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
        );

COMMIT;
'''

sys.stderr.write("Building errorMessageCreationTemplate\n")
errorMessageCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE
   (
       ERROR_CODE VARCHAR2(15) NOT NULL,
       ERROR_DESC VARCHAR2(70)
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
       (
          INITIAL 20K
          NEXT 20K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );

COMMIT;
'''

sys.stderr.write("Building errorMessageNewCreationTemplate\n")
errorMessageNewCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE
(
  ERR_CODE  NUMBER(6)                           NOT NULL,
  ERR_NAME  VARCHAR2(32 BYTE)                   NOT NULL,
  ERR_MSG   VARCHAR2(240 BYTE)
)
TABLESPACE @DATASPACE
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;


CREATE UNIQUE INDEX @TABLE_PK ON @TABLE
(ERR_CODE)
LOGGING
TABLESPACE @DATASPACE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;


CREATE UNIQUE INDEX @TABLE_AK1 ON @TABLE
(ERR_NAME)
LOGGING
TABLESPACE @DATASPACE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;


CREATE OR REPLACE TRIGGER @TABLE_BIUR
before insert or update
on @TABLE
for each row
begin
   :new.err_name := upper(:new.err_name);
end;
/
SHOW ERRORS;



ALTER TABLE @TABLE ADD (
  CONSTRAINT ERR_CODE_VAL_CHECK
 CHECK (err_code <-20000 and err_code>=-20999));

ALTER TABLE @TABLE ADD (
  CONSTRAINT @TABLE_PK
 PRIMARY KEY
 (ERR_CODE)
    USING INDEX 
    TABLESPACE @DATASPACE
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ));

'''

sys.stderr.write("Building errorMessageNewLoadTemplate\n")
errorMessageNewLoadTemplate = ''
for err_code, err_name, err_msg in errorCodes :
    errorMessageNewLoadTemplate +="INSERT INTO @TABLE (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (%s, '%s', '%s');\n" % (err_code, err_name, err_msg)
errorMessageNewLoadTemplate +="COMMIT;\n"


sys.stderr.write("Building intervalCreationTemplate\n")
intervalCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE 
   (
       INTERVAL_CODE  NUMBER(10)   NOT NULL,
       INTERVAL_ID    VARCHAR2(16) NOT NULL,
       INTERVAL       NUMBER(10)   NOT NULL,
       DESCRIPTION    VARCHAR2(80)
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
       ( 
          INITIAL 20K
          NEXT 20K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );
-------------------------------
-- @TABLE constraints --
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK PRIMARY KEY(INTERVAL_CODE);

COMMIT;
'''


sys.stderr.write("Building intervalLoadTemplate\n")
intervalLoadTemplate = ''
for code, id, minutesSignature, description in intervals :
    intervalLoadTemplate +="INSERT INTO @TABLE VALUES (%d, '%s', %d, '%s');\n" % (code, id, minutesSignature, description)
intervalLoadTemplate +="COMMIT;\n"

sys.stderr.write("Building durationCreationTemplate\n")
durationCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE 
   (
       DURATION_CODE NUMBER(10)   NOT NULL,
       DURATION_ID   VARCHAR2(16) NOT NULL,
       DURATION      NUMBER(10)   NOT NULL,
       DESCRIPTION   VARCHAR2(80)
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
       ( 
          INITIAL 20K
          NEXT 20K
          MINEXTENTS 1
          MAXEXTENTS 100
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );

--------------------------------
-- @TABLE constratints --
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK PRIMARY KEY(DURATION_CODE);

COMMIT;
'''


sys.stderr.write("Building durationLoadTemplate\n")
durationLoadTemplate = ''
for code, id, minutesSignature, description in durations :
    durationLoadTemplate +="INSERT INTO @TABLE VALUES (%d, '%s', %d, '%s');\n" % (code, id, minutesSignature, description)
durationLoadTemplate +="COMMIT;\n"

sys.stderr.write("Building catalogCreationTemplate\n")
catalogCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE
   (
       OBJECT_NAME  VARCHAR2(50) NOT NULL,
       COLUMN_NAME VARCHAR2(50)  NOT NULL,
       OBJECT_DESC VARCHAR2(100),
       COLUMN_DESC VARCHAR2(100)
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
       ( 
          INITIAL 20K
          NEXT 20K
          MINEXTENTS 1
          MAXEXTENTS 100
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );

COMMIT;   
'''

sys.stderr.write("Building catalogLoadTemplate\n")
catalogLoadTemplate = ''
for objName, colName, objDesc, colDesc in catalogItems :
    catalogLoadTemplate +="INSERT INTO @TABLE VALUES ('%s', '%s', '%s', '%s');\n" % (objName, colName, objDesc, colDesc)
catalogLoadTemplate +="COMMIT;\n"

sys.stderr.write("Building abstractParamCreationTemplate\n")
abstractParamCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE
   (
       ABSTRACT_PARAM_CODE NUMBER(10)         NOT NULL,
       ABSTRACT_PARAM_ID   VARCHAR2(32 BYTE)  NOT NULL
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
       ( 
          INITIAL 200K
          NEXT 200K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );

-----------------------------
-- @TABLE indicies
--
CREATE UNIQUE INDEX @TABLE_UI ON @TABLE
   (
       UPPER(ABSTRACT_PARAM_ID)
   )
       PCTFREE 10
       INITRANS 2
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
       ( 
          INITIAL 200k
          NEXT 200k
          MINEXTENTS 1
          MAXEXTENTS 20
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );

-----------------------------
-- @TABLE constraints
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK PRIMARY KEY (ABSTRACT_PARAM_CODE);

-----------------------------
-- @TABLE comments
--
COMMENT ON TABLE @TABLE IS 'Contains abstract parameters used with CWMS';
COMMENT ON COLUMN @TABLE.ABSTRACT_PARAM_CODE IS 'Primary key used for relating abstract parameters to other entities';
COMMENT ON COLUMN @TABLE.ABSTRACT_PARAM_ID IS 'Text identifier of abstract parameter';
COMMIT;
'''

sys.stderr.write("Building abstractParamLoadTemplate\n")
abstractParamLoadTemplate = ""
for i in range(len(abstractParams)) :
    code = i+1
    id = abstractParams[i]
    abstractParamLoadTemplate +="INSERT INTO @abstractParamTableName (ABSTRACT_PARAM_CODE, ABSTRACT_PARAM_ID) VALUES(%d, '%s');\n" % (code, id)
abstractParamLoadTemplate +="COMMIT;\n"

sys.stderr.write("Building unitCreationTemplate\n")
unitCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE
   (
       UNIT_CODE           NUMBER(10)         NOT NULL,
       UNIT_ID             VARCHAR2(16 BYTE)  NOT NULL,
       ABSTRACT_PARAM_CODE NUMBER(10)         NOT NULL,
       UNIT_SYSTEM         VARCHAR2(2 BYTE),
       LONG_NAME           VARCHAR2(80 BYTE),
       DESCRIPTION         VARCHAR2(80 BYTE)
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
       ( 
          INITIAL 200K
          NEXT 200K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );

-----------------------------
-- @TABLE constraints
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK PRIMARY KEY (UNIT_CODE);
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_UK UNIQUE      (UNIT_ID, ABSTRACT_PARAM_CODE);
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_FK FOREIGN KEY (ABSTRACT_PARAM_CODE) REFERENCES @abstractParamTableName (ABSTRACT_PARAM_CODE);

-----------------------------
-- @TABLE comments
--
COMMENT ON TABLE @TABLE IS 'Contains all internal and external units used with CWMS';
COMMENT ON COLUMN @TABLE.UNIT_CODE IS 'Primary key used for relating units to other entities';
COMMENT ON COLUMN @TABLE.ABSTRACT_PARAM_CODE IS 'Foreign key referencing @abstractParamTableName table';
COMMENT ON COLUMN @TABLE.UNIT_ID IS 'Short text identifier of unit';
COMMENT ON COLUMN @TABLE.UNIT_SYSTEM IS 'SI deonotes SI, EN denotes English, Null denotes both SI and EN';
COMMENT ON COLUMN @TABLE.LONG_NAME IS 'Complete name of unit';
COMMENT ON COLUMN @TABLE.DESCRIPTION IS 'Description of unit';
COMMIT;

'''

sys.stderr.write("Building unitLoadTemplate\n")
unitLoadTemplate = ''
unitDefIds = unitDefsById.keys()
unitDefIds.sort()
for i in range(len(unitDefIds)) :
    id = unitDefIds[i]
    unitDef = unitDefsById[id]
    name = unitDef["NAME"]
    description = unitDef["DESCRIPTION"]
    code = unitDef["CODE"]
    id = unitDef["ID"]
    system = unitDef["SYSTEM"]
    abstractParam = unitDef["ABSTRACT"]
    unitLoadTemplate +="INSERT INTO @unitTableName (UNIT_CODE, UNIT_ID, ABSTRACT_PARAM_CODE, UNIT_SYSTEM, LONG_NAME, DESCRIPTION) VALUES (\n" 
    unitLoadTemplate +="\t%d,\n" % code 
    unitLoadTemplate +="\t'%s',\n" % id
    unitLoadTemplate +="\t(\tSELECT ABSTRACT_PARAM_CODE\n"
    unitLoadTemplate +="\t\tFROM   @abstractParamTableName \n"
    unitLoadTemplate +="\t\tWHERE  ABSTRACT_PARAM_ID='%s'\n" % abstractParam
    unitLoadTemplate +="\t),\n"
    if system == "NULL" :
      unitLoadTemplate +="\tNULL,\n"
    else :
      unitLoadTemplate +="\t'%s',\n" % system  
    unitLoadTemplate +="\t'%s',\n" % name
    unitLoadTemplate +="\t'%s'\n" % description
    unitLoadTemplate +=");\n"
unitLoadTemplate +="COMMIT;\n"

sys.stderr.write("Building cwmsUnitCreationTemplate\n")
cwmsUnitCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE
   (
       UNIT_CODE      NUMBER(10) NOT NULL
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
       ( 
          INITIAL 200K
          NEXT 200K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );

-----------------------------
-- @TABLE constraints
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK PRIMARY KEY (UNIT_CODE);
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_FK FOREIGN KEY (UNIT_CODE) REFERENCES @unitTableName (UNIT_CODE);

-----------------------------
-- @TABLE comments
--
COMMENT ON TABLE @TABLE IS 'Contains references to all units allowed in CWMS database';
COMMENT ON COLUMN @TABLE.UNIT_CODE IS 'Primary key used for relating cwms units to other entities';
COMMIT;

'''

sys.stderr.write("Building cwmsUnitLoadTemplate\n")
cwmsUnitLoadTemplate = ''
for i in range(len(cwmsUnitParamDefsById)) :
    cwmsUnitCode = cwmsUnitParamDefsById[cwmsUnitParamIds[i]]
    cwmsUnitLoadTemplate +="INSERT INTO @cwmsUnitTableName (UNIT_CODE) VALUES (\n"
    cwmsUnitLoadTemplate +="\t%d);\n" % cwmsUnitCode
cwmsUnitLoadTemplate +="COMMIT;\n"

sys.stderr.write("Building parameterTypeCreationTemplate\n")
parameterTypeCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE 
  (
       PARAMETER_TYPE_CODE  NUMBER(10)   NOT NULL,
       PARAMETER_TYPE_ID    VARCHAR2(16) NOT NULL,
       DESCRIPTION          VARCHAR2(80) NULL
  )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
       ( 
          INITIAL 20k
          NEXT 20k
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );

-----------------------------
-- @TABLE indicies
--
CREATE UNIQUE INDEX @TABLE_UI ON @TABLE
   (
       UPPER(PARAMETER_TYPE_ID)
   )
       PCTFREE 10
       INITRANS 2
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
       ( 
          INITIAL 20k
          NEXT 20k
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );

-------------------------------------
-- @TABLE constraints --
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK PRIMARY KEY (PARAMETER_TYPE_CODE);

----------------------------------
-- @TABLE comments --
--    
COMMENT ON TABLE  @TABLE IS 'Associated with a parameter to define the relationship of the data value to its duration.  The valid values include average, total, maximum, minimum, and constant.';
COMMENT ON COLUMN @TABLE.PARAMETER_TYPE_CODE IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.';
COMMENT ON COLUMN @TABLE.PARAMETER_TYPE_ID IS 'Record identifier that is meaningful to the user.  This is user defined.  If not defined during data entry, it defaults to PARAMETER_TYPE_CODE.';
COMMENT ON COLUMN @TABLE.DESCRIPTION IS 'Additional information.';
COMMIT;

'''

sys.stderr.write("Building parameterTypeLoadTemplate\n")
parameterTypeLoadTemplate = ''
for i in range(len(parameterTypes)) :
    code = i+1
    parameterTypeLoadTemplate +="INSERT INTO @parameterTypeTableName (PARAMETER_TYPE_CODE, PARAMETER_TYPE_ID, DESCRIPTION) VALUES (\n"
    parameterTypeLoadTemplate +="\t%d,\n"   % code
    parameterTypeLoadTemplate +="\t'%s',\n" % parameterTypes[i]["ID"]
    parameterTypeLoadTemplate +="\t'%s'\n"  % parameterTypes[i]["DESCRIPTION"]
    parameterTypeLoadTemplate +=");\n"
parameterTypeLoadTemplate +="COMMIT;\n"

sys.stderr.write("Building parameterCreationTemplate\n")
parameterCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE
   (
       BASE_PARAMETER_CODE      NUMBER(10)         NOT NULL, 
       BASE_PARAMETER_ID        VARCHAR2(16 BYTE)  NOT NULL,
       ABSTRACT_PARAM_CODE      NUMBER(10)         NOT NULL,
       UNIT_CODE                NUMBER(10)         NOT NULL,
       DISPLAY_UNIT_CODE_SI     NUMBER(10)         NOT NULL,
       DISPLAY_UNIT_CODE_EN     NUMBER(10)         NOT NULL,
       LONG_NAME                VARCHAR2(80 BYTE),
       DESCRIPTION              VARCHAR2(160 BYTE)
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
       ( 
          INITIAL 200K
          NEXT 200K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );

-----------------------------
-- @TABLE indicies
--
CREATE UNIQUE INDEX @TABLE_UI ON @TABLE
   (
       UPPER(BASE_PARAMETER_ID)
   )
       PCTFREE 10
       INITRANS 2
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
       ( 
          INITIAL 200k
          NEXT 200k
          MINEXTENTS 1
          MAXEXTENTS 20
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );

-----------------------------
-- @TABLE constraints
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK   PRIMARY KEY (BASE_PARAMETER_CODE);
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_FK1 FOREIGN KEY (ABSTRACT_PARAM_CODE) REFERENCES @abstractParamTableName (ABSTRACT_PARAM_CODE);
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_FK2 FOREIGN KEY (UNIT_CODE) REFERENCES @unitTableName (UNIT_CODE);
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_FK3 FOREIGN KEY (DISPLAY_UNIT_CODE_SI) REFERENCES @unitTableName (UNIT_CODE);
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_FK4 FOREIGN KEY (DISPLAY_UNIT_CODE_EN) REFERENCES @unitTableName (UNIT_CODE);

-----------------------------
-- @TABLE comments
--
COMMENT ON TABLE @TABLE IS 'List of parameters allowed in the CWMS database';
COMMENT ON COLUMN @TABLE.BASE_PARAMETER_CODE IS 'Primary key used to relate parameters other entities';
COMMENT ON COLUMN @TABLE.BASE_PARAMETER_ID IS 'Short identifier of parameter';
COMMENT ON COLUMN @TABLE.ABSTRACT_PARAM_CODE IS 'Foreign key referencing @abstractParamTableName table';
COMMENT ON COLUMN @TABLE.UNIT_CODE IS 'This is the db storage unit for this parameter. Foreign key referencing @cwmsUnitTableName table.';
COMMENT ON COLUMN @TABLE.DISPLAY_UNIT_CODE_SI IS 'This is the default SI display unit for this parameter. Foreign key referencing @cwmsUnitTableName table.';
COMMENT ON COLUMN @TABLE.DISPLAY_UNIT_CODE_EN IS 'This is the default Non-SI display unit for this parameter. Foreign key referencing @cwmsUnitTableName table.';
COMMENT ON COLUMN @TABLE.LONG_NAME IS 'Full name of parameter';
COMMENT ON COLUMN @TABLE.DESCRIPTION IS 'Description of parameter';

-----------------------------
-- @TABLE_UNIT trigger
--
CREATE OR REPLACE TRIGGER cwms_base_parameter_unit
   BEFORE INSERT OR UPDATE OF abstract_param_code, unit_code
   ON cwms_base_parameter
   REFERENCING NEW AS NEW OLD AS OLD
   FOR EACH ROW
DECLARE
   --
   -- This trigger ensures that the abstract parameter associated with the specified
   -- unit is the same as the abstract parameter associated with this parameter.
   --
   unit_abstract_code            cwms_abstract_parameter.abstract_param_code%TYPE;
   unit_abstract_id              cwms_abstract_parameter.abstract_param_id%TYPE;
   unit_id                       cwms_unit.unit_id%TYPE;
   unit_type                     VARCHAR (20);
   parameter_abstract_id         cwms_abstract_parameter.abstract_param_id%TYPE;
   inconsistent_abstract_codes   EXCEPTION;
   PRAGMA EXCEPTION_INIT (inconsistent_abstract_codes, -20000);
BEGIN
   SELECT u.abstract_param_code
     INTO unit_abstract_code
     FROM cwms_unit u
    WHERE u.unit_code = :NEW.unit_code;

   IF :NEW.abstract_param_code != unit_abstract_code
   THEN
      SELECT u.unit_id
        INTO unit_id
        FROM cwms_unit u
       WHERE u.unit_code = :NEW.unit_code;

      unit_type := 'DB Storage Unit';
      RAISE inconsistent_abstract_codes;
   END IF;

   --
   SELECT u.abstract_param_code
     INTO unit_abstract_code
     FROM cwms_unit u
    WHERE u.unit_code = :NEW.display_unit_code_si;

   IF :NEW.abstract_param_code != unit_abstract_code
   THEN
      SELECT u.unit_id
        INTO unit_id
        FROM cwms_unit u
       WHERE u.unit_code = :NEW.display_unit_code_si;

      unit_type := 'SI Display Unit';
      RAISE inconsistent_abstract_codes;
   END IF;

   --
   SELECT u.abstract_param_code
     INTO unit_abstract_code
     FROM cwms_unit u
    WHERE u.unit_code = :NEW.display_unit_code_en;

   IF :NEW.abstract_param_code != unit_abstract_code
   THEN
      SELECT u.unit_id
        INTO unit_id
        FROM cwms_unit u
       WHERE u.unit_code = :NEW.display_unit_code_en;

      unit_type := 'Non-SI Display Unit';
      RAISE inconsistent_abstract_codes;
   END IF;
EXCEPTION
   WHEN inconsistent_abstract_codes
   THEN
      SELECT abstract_param_id
        INTO unit_abstract_id
        FROM cwms_abstract_parameter
       WHERE abstract_param_code = unit_abstract_code;

      SELECT abstract_param_id
        INTO parameter_abstract_id
        FROM cwms_abstract_parameter
       WHERE abstract_param_code = :NEW.abstract_param_code;

      DBMS_OUTPUT.put_line (   'ERROR: Parameter "'
                            || :NEW.base_parameter_id
                            || '" has abstract parameter "'
                            || parameter_abstract_id
                            || '" but '
                            || unit_type
                            ||  ' "'
                            || unit_id
                            || '" has abstract parameter "'
                            || unit_abstract_id
                            || '".'
                           );
      RAISE;
   WHEN OTHERS
   THEN
      DBMS_OUTPUT.put_line (SQLERRM);
      RAISE;
END r_parameter_unit;
/
SHOW ERRORS
COMMIT;

'''

sys.stderr.write("Building parameterLoadTemplate\n")
parameterLoadTemplate = ''
for i in range(len(parameters)) :
    code, abstractParam, id, name, unitId, siUnitId, enUnitId, description = parameters[i]
    parameterLoadTemplate +="INSERT INTO @parameterTableName (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (\n"
    parameterLoadTemplate +="\t%d,\n" % code
    parameterLoadTemplate +="\t'%s',\n" % id
    parameterLoadTemplate +="\t(\tSELECT ABSTRACT_PARAM_CODE\n"
    parameterLoadTemplate +="\t\tFROM   @abstractParamTableName \n"
    parameterLoadTemplate +="\t\tWHERE  ABSTRACT_PARAM_ID='%s'\n" % abstractParam
    parameterLoadTemplate +="\t),\n"
    parameterLoadTemplate +="\t(\tSELECT U.UNIT_CODE\n"
    parameterLoadTemplate +="\t\tFROM @unitTableName U \n"
    parameterLoadTemplate +="\t\tWHERE U.UNIT_ID='%s'\n" % unitId
    parameterLoadTemplate +="\t),\n"
    parameterLoadTemplate +="\t(\tSELECT U.UNIT_CODE\n"
    parameterLoadTemplate +="\t\tFROM @unitTableName U \n"
    parameterLoadTemplate +="\t\tWHERE U.UNIT_ID='%s'\n" % siUnitId
    parameterLoadTemplate +="\t),\n"
    parameterLoadTemplate +="\t(\tSELECT U.UNIT_CODE\n"
    parameterLoadTemplate +="\t\tFROM @unitTableName U \n"
    parameterLoadTemplate +="\t\tWHERE U.UNIT_ID='%s'\n" % enUnitId
    parameterLoadTemplate +="\t),\n"
    parameterLoadTemplate +="\t'%s',\n" % name
    parameterLoadTemplate +="\t'%s'\n" % description
    parameterLoadTemplate +=");\n"
parameterLoadTemplate +="COMMIT;\n"

#-------------------------------------------------------
#-------------------------------------------------------
sys.stderr.write("Building subParameterCreationTemplate\n")
subParameterCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##

CREATE TABLE @TABLE
(
  PARAMETER_CODE       NUMBER,
  DB_OFFICE_CODE       NUMBER                     NOT NULL,
  BASE_PARAMETER_CODE  NUMBER                     NOT NULL,
  SUB_PARAMETER_ID     VARCHAR2(32 BYTE),
  SUB_PARAMETER_DESC   VARCHAR2(80 BYTE)
)
TABLESPACE @DATASPACE
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/

-----------------------------
-- @TABLE indicies
--
CREATE UNIQUE INDEX @TABLE_PK ON @TABLE
(PARAMETER_CODE)
LOGGING
TABLESPACE @DATASPACE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


CREATE UNIQUE INDEX @TABLE_UK1 ON @TABLE
(BASE_PARAMETER_CODE, SUB_PARAMETER_ID, DB_OFFICE_CODE)
LOGGING
TABLESPACE @DATASPACE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/

-----------------------------
-- @TABLE constraints
--
ALTER TABLE @TABLE ADD (
  CONSTRAINT @TABLE_PK
 PRIMARY KEY
 (PARAMETER_CODE)
    USING INDEX 
    TABLESPACE @DATASPACE
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

ALTER TABLE @TABLE ADD (
  CONSTRAINT @TABLE_UK1
 UNIQUE (BASE_PARAMETER_CODE, SUB_PARAMETER_ID, DB_OFFICE_CODE)
    USING INDEX 
    TABLESPACE @DATASPACE
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

ALTER TABLE @TABLE ADD (
  CONSTRAINT @TABLE_FK1 
 FOREIGN KEY (DB_OFFICE_CODE) 
 REFERENCES CWMS_OFFICE (OFFICE_CODE))
/

ALTER TABLE @TABLE ADD (
  CONSTRAINT @TABLE_FK2 
 FOREIGN KEY (BASE_PARAMETER_CODE) 
 REFERENCES CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE))
/

ALTER TABLE @TABLE ADD (
  CONSTRAINT @TABLE_CK_1 
       CHECK (TRIM(SUB_PARAMETER_ID)=SUB_PARAMETER_ID))
/
SHOW ERRORS

'''


sys.stderr.write("Building subParameterLoadTemplate\n")
subParameterLoadTemplate = \
'''
INSERT INTO at_parameter
   SELECT base_parameter_code, (SELECT office_code
                                  FROM cwms_office
                                 WHERE office_id = 'CWMS'),
          base_parameter_code, NULL, cbp.long_name
     FROM cwms_base_parameter cbp
/

'''
for i in range(len(subParameters)) :
    baseCode, baseParamId, subParamId, longName, siUnitId, enUnitId = subParameters[i]
    subParameterLoadTemplate +="INSERT INTO @subParameterTableName (PARAMETER_CODE, BASE_PARAMETER_CODE, SUB_PARAMETER_ID, DB_OFFICE_CODE, SUB_PARAMETER_DESC) VALUES (\n"
    subParameterLoadTemplate +="\t%d,\n" % baseCode
    subParameterLoadTemplate +="\t(\tSELECT BASE_PARAMETER_CODE\n"
    subParameterLoadTemplate +="\t\tFROM   @parameterTableName \n"
    subParameterLoadTemplate +="\t\tWHERE  BASE_PARAMETER_ID='%s'\n" % baseParamId
    subParameterLoadTemplate +="\t),\n"
    subParameterLoadTemplate +="\t'%s',\n" % subParamId
    subParameterLoadTemplate +="\t(\tSELECT OFFICE_CODE\n"
    subParameterLoadTemplate +="\t\tFROM @cwmsOfficeTableName U \n"
    subParameterLoadTemplate +="\t\tWHERE OFFICE_ID='CWMS'\n"
    subParameterLoadTemplate +="\t),\n"
    subParameterLoadTemplate +="\t'%s'\n" % longName
    subParameterLoadTemplate +=");\n"
subParameterLoadTemplate +="COMMIT;\n"


#-------------------------------------------------------
#-------------------------------------------------------

sys.stderr.write("Building ratingMethodCreationTemplate\n")
ratingMethodCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE
   (
       RATING_METHOD_CODE NUMBER(10),
       RATING_METHOD_ID   VARCHAR2(32),
       DESCRIPTION        VARCHAR2(256),
       CONSTRAINT @TABLE_PK PRIMARY KEY(RATING_METHOD_CODE)
   ) 
       ORGANIZATION INDEX
       TABLESPACE @DATASPACE;

-----------------------------
-- @TABLE indicies
--
CREATE UNIQUE INDEX @TABLE_UI ON @TABLE
   (
       UPPER(RATING_METHOD_ID)
   )
       PCTFREE 10
       INITRANS 2
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
       ( 
          INITIAL 20k
          NEXT 20k
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );
    
COMMIT;   
'''

sys.stderr.write("Building ratingMethodLoadTemplate\n")
ratingMethodLoadTemplate = ''
code = 1
for id, description in ratingMethods :
    ratingMethodLoadTemplate +="INSERT INTO @TABLE VALUES (%d, '%s', '%s');\n" % (code, id, description)
    code += 1
ratingMethodLoadTemplate +="COMMIT;\n"

sys.stderr.write("Building dssParameterTypeCreationTemplate\n")
dssParameterTypeCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE 
  (
       DSS_PARAMETER_TYPE_CODE NUMBER(10)   NOT NULL,
       DSS_PARAMETER_TYPE_ID   VARCHAR2(8)  NOT NULL,
       PARAMETER_TYPE_CODE     NUMBER(10)   NOT NULL,
       DESCRIPTION             VARCHAR2(40) NULL
  )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
       ( 
          INITIAL 200k
          NEXT 200k
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );

-----------------------------
-- @TABLE indicies
--
CREATE UNIQUE INDEX @TABLE_UI ON @TABLE
   (
       UPPER(DSS_PARAMETER_TYPE_ID)
   )
       PCTFREE 10
       INITRANS 2
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
       ( 
          INITIAL 200k
          NEXT 200k
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );

-------------------------------------
-- @TABLE constraints --
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK PRIMARY KEY (DSS_PARAMETER_TYPE_CODE);
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_FK FOREIGN KEY (PARAMETER_TYPE_CODE) REFERENCES @parameterTypeTableName (PARAMETER_TYPE_CODE);

----------------------------------
-- @TABLE comments --
--    
COMMENT ON TABLE  @TABLE IS 'List of valid HEC-DSS time series data types';
COMMENT ON COLUMN @TABLE.DSS_PARAMETER_TYPE_CODE IS 'Primary key for relating HEC-DSS parameter types to other entities';
COMMENT ON COLUMN @TABLE.DSS_PARAMETER_TYPE_ID IS 'HEC-DSS time series parameter type';
COMMENT ON COLUMN @TABLE.PARAMETER_TYPE_CODE IS 'CWMS parameter type associated with the HEC-DSS parameter type';
COMMENT ON COLUMN @TABLE.DESCRIPTION IS 'Description';
COMMIT;

'''

sys.stderr.write("Building dssParameterTypeLoadTemplate\n")
dssParameterTypeLoadTemplate = ''
for i in range(len(dssParameterTypes)) :
    code = i+1
    dssParameterTypeLoadTemplate +="INSERT INTO @dssParameterTypeTableName (DSS_PARAMETER_TYPE_CODE, DSS_PARAMETER_TYPE_ID, PARAMETER_TYPE_CODE, DESCRIPTION) VALUES (\n"
    dssParameterTypeLoadTemplate +="\t%d,\n"   % code
    dssParameterTypeLoadTemplate +="\t'%s',\n" % dssParameterTypes[i]["ID"]
    dssParameterTypeLoadTemplate +="\t(\tSELECT PARAMETER_TYPE_CODE\n"
    dssParameterTypeLoadTemplate +="\t\tFROM   @parameterTypeTableName\n"
    dssParameterTypeLoadTemplate +="\t\tWHERE  PARAMETER_TYPE_ID='%s'\n" % dssParameterTypes[i]["DB_TYPE"]
    dssParameterTypeLoadTemplate +="\t),\n"
    dssParameterTypeLoadTemplate +="\t'%s'\n"  % dssParameterTypes[i]["DESCRIPTION"]
    dssParameterTypeLoadTemplate +=");\n"
dssParameterTypeLoadTemplate +="COMMIT;\n"

sys.stderr.write("Building dssXchgDirectionCreationTemplate\n")
dssXchgDirectionCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE 
  (
       DSS_XCHG_DIRECTION_CODE NUMBER       NOT NULL,
       DSS_XCHG_DIRECTION_ID   VARCHAR2(16) NOT NULL,
       DESCRIPTION             VARCHAR2(80) NULL
  )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
       ( 
          INITIAL 200k
          NEXT 200k
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );

-----------------------------
-- @TABLE indicies
--
CREATE UNIQUE INDEX @TABLE_UI ON @TABLE
   (
       UPPER(DSS_XCHG_DIRECTION_ID)
   )
       PCTFREE 10
       INITRANS 2
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
       ( 
          INITIAL 200k
          NEXT 200k
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );

-------------------------------------
-- @TABLE constraints --
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK PRIMARY KEY (DSS_XCHG_DIRECTION_CODE);

----------------------------------
-- @TABLE comments --
--    
COMMENT ON TABLE  @TABLE IS 'List of valid Oracle/HEC-DSS exchange directions';
COMMENT ON COLUMN @TABLE.DSS_XCHG_DIRECTION_CODE IS 'Primary key for relating exchange directions to other entities';
COMMENT ON COLUMN @TABLE.DSS_XCHG_DIRECTION_ID IS 'Oracle/HEC-DSS exchange direction';
COMMENT ON COLUMN @TABLE.DESCRIPTION IS 'Description';
COMMIT;

'''

sys.stderr.write("Building dssXchgDirectionLoadTemplate\n")
dssXchgDirectionLoadTemplate = ''
for i in range(len(dssXchgDirections)) :
    code = i + 1
    dssXchgDirectionLoadTemplate +="INSERT INTO @dssXchgDirectionTableName (DSS_XCHG_DIRECTION_CODE, DSS_XCHG_DIRECTION_ID, DESCRIPTION) VALUES (\n"
    dssXchgDirectionLoadTemplate +="\t%d,\n"   % code
    dssXchgDirectionLoadTemplate +="\t'%s',\n" % dssXchgDirections[i]["DSS_XCHG_DIRECTION_ID"]
    dssXchgDirectionLoadTemplate +="\t'%s'\n"  % dssXchgDirections[i]["DESCRIPTION"]
    dssXchgDirectionLoadTemplate +=");\n"
dssParameterTypeLoadTemplate +="COMMIT;\n"

sys.stderr.write("Building conversionCreationTemplate\n")
conversionCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE
(
  FROM_UNIT_ID        VARCHAR2(16 BYTE)       NOT NULL,
  TO_UNIT_ID          VARCHAR2(16 BYTE)       NOT NULL,
  ABSTRACT_PARAM_CODE NUMBER(10)              NOT NULL,
  FROM_UNIT_CODE      NUMBER(10)              NOT NULL,
  TO_UNIT_CODE        NUMBER(10)              NOT NULL,
  FACTOR              BINARY_DOUBLE           NOT NULL,
  OFFSET              BINARY_DOUBLE           NOT NULL, 
  CONSTRAINT CWMS_UNIT_CONVERSION_PK
 PRIMARY KEY
 (FROM_UNIT_ID, TO_UNIT_ID)
)
ORGANIZATION INDEX
LOGGING
TABLESPACE @DATASPACE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
MONITORING
/

-----------------------------
-- @TABLE constraints
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_FK1 FOREIGN KEY (FROM_UNIT_CODE) REFERENCES @unitTableName (UNIT_CODE);
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_FK2 FOREIGN KEY (TO_UNIT_CODE) REFERENCES @unitTableName (UNIT_CODE);
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_FK3 FOREIGN KEY (FROM_UNIT_ID, ABSTRACT_PARAM_CODE) REFERENCES @unitTableName (UNIT_ID, ABSTRACT_PARAM_CODE);
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_FK4 FOREIGN KEY (TO_UNIT_ID, ABSTRACT_PARAM_CODE) REFERENCES @unitTableName (UNIT_ID, ABSTRACT_PARAM_CODE);


CREATE UNIQUE INDEX CWMS_UNIT_CONVERSION_U01 ON CWMS_UNIT_CONVERSION
(FROM_UNIT_CODE, TO_UNIT_CODE)
LOGGING
tablespace CWMS_20DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/

-----------------------------
-- @TABLE comments
--
COMMENT ON TABLE @TABLE IS 'Contains linear conversion factors for units';
COMMENT ON COLUMN @TABLE.FROM_UNIT_ID IS   'Source units      (x in y=mx+b)';
COMMENT ON COLUMN @TABLE.TO_UNIT_ID IS     'Destination units (y in y=mx+b)';
COMMENT ON COLUMN @TABLE.FROM_UNIT_CODE IS 'Source units      (x in y=mx+b)';
COMMENT ON COLUMN @TABLE.TO_UNIT_CODE IS   'Destination units (y in y=mx+b)';
COMMENT ON COLUMN @TABLE.FACTOR IS         'Ratio of units    (m in y=mx+b)';
COMMENT ON COLUMN @TABLE.OFFSET IS         'Offset of units   (b in y=mx+b)';

-----------------------------
-- @TABLE_UNIT trigger
--
CREATE OR REPLACE TRIGGER @TABLE_UNIT
BEFORE INSERT OR UPDATE OF FROM_UNIT_CODE, TO_UNIT_CODE
ON @TABLE 
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
   --
   -- This trigger ensures that the abstract parameter associated with the source unit
   -- is the same as the abstract parameter associated with the destination unit.
   --
   FROM_ABSTRACT_CODE          @abstractParamTableName.ABSTRACT_PARAM_CODE%TYPE;
   FROM_ABSTRACT_ID            @abstractParamTableName.ABSTRACT_PARAM_ID%TYPE;
   FROM_ID                     @unitTableName.UNIT_ID%TYPE;
   TO_ABSTRACT_CODE            @abstractParamTableName.ABSTRACT_PARAM_CODE%TYPE;
   TO_ABSTRACT_ID              @abstractParamTableName.ABSTRACT_PARAM_ID%TYPE;
   TO_ID                       @unitTableName.UNIT_ID%TYPE;
   INCONSISTENT_ABSTRACT_CODES EXCEPTION;
   PRAGMA EXCEPTION_INIT(INCONSISTENT_ABSTRACT_CODES, -20000);
BEGIN
   SELECT ABSTRACT_PARAM_CODE
      INTO   FROM_ABSTRACT_CODE 
      FROM   @unitTableName
      WHERE  UNIT_CODE = :NEW.FROM_UNIT_CODE;
   SELECT ABSTRACT_PARAM_CODE
      INTO   TO_ABSTRACT_CODE 
      FROM   @unitTableName
      WHERE  UNIT_CODE = :NEW.TO_UNIT_CODE;
   IF FROM_ABSTRACT_CODE != TO_ABSTRACT_CODE
   THEN
      RAISE INCONSISTENT_ABSTRACT_CODES;
   END IF;
EXCEPTION
   WHEN INCONSISTENT_ABSTRACT_CODES THEN
      SELECT UNIT_ID
         INTO   FROM_ID
         FROM   @unitTableName
         WHERE  UNIT_CODE = :NEW.FROM_UNIT_CODE;
      SELECT UNIT_ID
         INTO   TO_ID
         FROM   @unitTableName
         WHERE  UNIT_CODE = :NEW.TO_UNIT_CODE;
      SELECT ABSTRACT_PARAM_ID
         INTO   FROM_ABSTRACT_ID 
         FROM   @abstractParamTableName
         WHERE  ABSTRACT_PARAM_CODE=FROM_ABSTRACT_CODE;
      SELECT ABSTRACT_PARAM_ID
         INTO   TO_ABSTRACT_ID 
         FROM   @abstractParamTableName
         WHERE  ABSTRACT_PARAM_CODE=TO_ABSTRACT_CODE;
      DBMS_OUTPUT.PUT_LINE(
         'ERROR: From-unit "' 
         || FROM_ID
         || '" has abstract parameter "' 
         || FROM_ABSTRACT_ID
         || '" but To-unit "'
         || TO_ID
         || '" has abstract parameter "'
         || TO_ABSTRACT_ID
         || '".');
      RAISE;                                    
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
      RAISE;                                    
END R_PARAMETER_UNIT;
/
SHOW ERRORS
COMMIT;

'''

sys.stderr.write("Building conversionLoadTemplate\n")
conversionLoadTemplate = ''
conversionUnitIds = unitConversionsByUnitIds.keys()
conversionUnitIds.sort()
for abstractParam, fromUnit, toUnit in conversionUnitIds :
    conversion = unitConversionsByUnitIds[abstractParam, fromUnit, toUnit]
    conversionLoadTemplate +="INSERT INTO %s (FROM_UNIT_ID, TO_UNIT_ID, ABSTRACT_PARAM_CODE, FROM_UNIT_CODE, TO_UNIT_CODE, FACTOR, OFFSET) VALUES (\n" % conversionTableName
    conversionLoadTemplate +="\t\t'%s',\n" % fromUnit
    conversionLoadTemplate +="\t\t'%s',\n" % toUnit
    conversionLoadTemplate +="\t\t(SELECT ABSTRACT_PARAM_CODE\n"
    conversionLoadTemplate +="\t\tFROM   %s \n" % abstractParamTableName
    conversionLoadTemplate +="\t\tWHERE  ABSTRACT_PARAM_ID='%s'),\n" % abstractParam
    conversionLoadTemplate +="\t(\tSELECT UNIT_CODE\n"
    conversionLoadTemplate +="\t\tFROM   %s\n" % unitTableName
    conversionLoadTemplate +="\t\tWHERE  UNIT_ID='%s'\n" % fromUnit
    conversionLoadTemplate +="\t\tAND    ABSTRACT_PARAM_CODE=\n"
    conversionLoadTemplate +="\t\t(\tSELECT ABSTRACT_PARAM_CODE\n"
    conversionLoadTemplate +="\t\t\tFROM   %s \n" % abstractParamTableName
    conversionLoadTemplate +="\t\t\tWHERE  ABSTRACT_PARAM_ID='%s'\n" % abstractParam
    conversionLoadTemplate +="\t\t)\n"
    conversionLoadTemplate +="\t),\n"
    conversionLoadTemplate +="\t(\tSELECT UNIT_CODE\n"
    conversionLoadTemplate +="\t\tFROM   %s\n" % unitTableName
    conversionLoadTemplate +="\t\tWHERE  UNIT_ID='%s'\n" % toUnit
    conversionLoadTemplate +="\t\tAND    ABSTRACT_PARAM_CODE=\n"
    conversionLoadTemplate +="\t\t(\tSELECT ABSTRACT_PARAM_CODE\n"
    conversionLoadTemplate +="\t\t\tFROM   %s \n" % abstractParamTableName
    conversionLoadTemplate +="\t\t\tWHERE  ABSTRACT_PARAM_ID='%s'\n" % abstractParam
    conversionLoadTemplate +="\t\t)\n"
    conversionLoadTemplate +="\t),\n"
    conversionLoadTemplate +="\t%s,\n" % `conversion["FACTOR"]`
    conversionLoadTemplate +="\t%s\n" % `conversion["OFFSET"]`
    conversionLoadTemplate +=");\n"
conversionLoadTemplate +="COMMIT;\n"

sys.stderr.write("Building conversionTestTemplate\n")
conversionTestTemplate = \
'''
CREATE OR REPLACE PROCEDURE @TABLE_TEST
IS
   L_PARAM @abstractParamTableName%ROWTYPE;
   L_FROM  @unitTableName%ROWTYPE;
   L_TO    @unitTableName%ROWTYPE;
   L_CONV  @TABLE%ROWTYPE;
   L_COUNT PLS_INTEGER := 0;
   L_TOTAL PLS_INTEGER := 0;
BEGIN
   DBMS_OUTPUT.PUT_LINE('*** CHECKING UNIT CONVERSIONS ***');
   FOR L_PARAM IN (SELECT * FROM @abstractParamTableName)
   LOOP
      L_COUNT := 0;
      DBMS_OUTPUT.PUT_LINE('.');
      DBMS_OUTPUT.PUT_LINE('.  Checking abstract parameter ' || L_PARAM.ABSTRACT_PARAM_ID);
      FOR L_FROM IN (SELECT * FROM @unitTableName WHERE ABSTRACT_PARAM_CODE=L_PARAM.ABSTRACT_PARAM_CODE)
      LOOP
         FOR L_TO IN (SELECT * FROM @unitTableName WHERE ABSTRACT_PARAM_CODE=L_PARAM.ABSTRACT_PARAM_CODE)
         LOOP
            BEGIN
               SELECT * 
                  INTO  L_CONV
                  FROM @conversionTableName
                  WHERE FROM_UNIT_CODE = L_FROM.UNIT_CODE
                  AND   TO_UNIT_CODE = L_TO.UNIT_CODE;
               DBMS_OUTPUT.PUT_LINE(
                   '.    "'
                   || L_FROM.UNIT_ID
                   || '","'
                   || L_TO.UNIT_ID
                   || '",'
                   || L_CONV.OFFSET
                   || ','
                   || L_CONV.FACTOR);
               L_COUNT := L_COUNT + 1;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  DBMS_OUTPUT.PUT_LINE(
                   '.    >>> No conversion from "'
                   || L_FROM.UNIT_ID
                   || '" to "'
                   || L_TO.UNIT_ID
                   || '".');
               WHEN OTHERS THEN
                  RAISE;
            END;
         END LOOP;
      END LOOP;
      DBMS_OUTPUT.PUT_LINE('.  ' || L_COUNT || ' unit conversion entries.');
      L_TOTAL := L_TOTAL + L_COUNT;
   END LOOP;
   DBMS_OUTPUT.PUT_LINE('.');
   DBMS_OUTPUT.PUT_LINE('' || L_TOTAL || ' unit conversion entries.');
END @TABLE_TEST;
/
SHOW ERRORS
COMMIT;

BEGIN @TABLE_TEST; END;
/

DROP PROCEDURE @TABLE_TEST;
COMMIT;

'''

sys.stderr.write("Building timezoneCreationTemplate\n")
timezoneCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE
   (
       TIME_ZONE_CODE NUMBER(10)             NOT NULL,
       TIME_ZONE_NAME VARCHAR2(28)           NOT NULL,
       UTC_OFFSET    INTERVAL DAY TO SECOND NOT NULL,
       DST_OFFSET    INTERVAL DAY TO SECOND NOT NULL
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
       ( 
          INITIAL 200K
          NEXT 200K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );

-----------------------------
-- @TABLE constraints
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK  PRIMARY KEY  (TIME_ZONE_CODE);
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_UK  UNIQUE       (TIME_ZONE_NAME);
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_CK1 CHECK       (UTC_OFFSET >= INTERVAL '-18:00' HOUR TO MINUTE);
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_CK2 CHECK       (UTC_OFFSET <= INTERVAL ' 18:00' HOUR TO MINUTE);
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_CK3 CHECK       (DST_OFFSET >= INTERVAL  ' 0:00' HOUR TO MINUTE);
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_CK4 CHECK       (DST_OFFSET <= INTERVAL   '1:00' HOUR TO MINUTE);

-----------------------------
-- @TABLE comments
--
COMMENT ON TABLE @TABLE IS 'Contains timezone information.';
COMMENT ON COLUMN @TABLE.TIME_ZONE_CODE IS 'Primary key used to relate parameters other entities';
COMMENT ON COLUMN @TABLE.TIME_ZONE_NAME IS 'Region name or abbreviation of timezone';
COMMENT ON COLUMN @TABLE.UTC_OFFSET    IS 'Amount of time the timezone is ahead of UTC';
COMMENT ON COLUMN @TABLE.DST_OFFSET    IS 'Amount of time the UTC_OFFSET increases during DST';
COMMIT;

'''

sys.stderr.write("Building timezoneLoadTemplate\n")
timezoneLoadTemplate = \
'''
CREATE OR REPLACE PROCEDURE LOAD_@TABLE IS
   L_UTC_BEG  CONSTANT TIMESTAMP := TO_TIMESTAMP('2005-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS');
   L_UTC_MID  CONSTANT TIMESTAMP := TO_TIMESTAMP('2005-07-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS');
   L_TSZ_BEG  TIMESTAMP WITH TIME ZONE;
   L_TSZ_MID  TIMESTAMP WITH TIME ZONE;
   L_OFF_BEG  INTERVAL DAY TO SECOND;
   L_OFF_MID  INTERVAL DAY TO SECOND;
   L_OFF_UTC  INTERVAL DAY TO SECOND;
   L_OFF_DST  INTERVAL DAY TO SECOND;
   L_CODE     NUMBER(10) := 0;
   L_TZROW    V$TIMEZONE_NAMES%ROWTYPE;
   L_TZREGION VARCHAR2(64);
   CURSOR L_TZNAME_CUR IS SELECT DISTINCT TZNAME FROM V$TIMEZONE_NAMES ORDER BY TZNAME;
BEGIN
   INSERT INTO @timezoneTableName
      (
         TIME_ZONE_CODE, 
         TIME_ZONE_NAME, 
         UTC_OFFSET, 
         DST_OFFSET
      ) VALUES 
      (
         L_CODE,
         'Unknown or Not Applicable',
         '+00 00:00:00.000000',
         '+00 00:00:00.000000'
      );
   FOR L_TZROW IN L_TZNAME_CUR LOOP
      L_CODE := L_CODE + 1;
      L_TZREGION := L_TZROW.TZNAME;
      L_TSZ_BEG := TO_TIMESTAMP_TZ('2005-01-01 00:00:00 ' || L_TZREGION, 'YYYY-MM-DD HH24:MI:SS TZR');
      L_TSZ_MID := TO_TIMESTAMP_TZ('2005-07-01 00:00:00 ' || L_TZREGION, 'YYYY-MM-DD HH24:MI:SS TZR');
      L_OFF_BEG := L_UTC_BEG - SYS_EXTRACT_UTC(L_TSZ_BEG);
      L_OFF_MID := L_UTC_MID - SYS_EXTRACT_UTC(L_TSZ_MID);
      IF L_OFF_MID < L_OFF_BEG THEN
         -- 
         -- SOUTHERN HEMISPHERE AND DST 
         -- 
         L_OFF_UTC := L_OFF_MID;
         L_OFF_DST := L_OFF_BEG - L_OFF_MID;
      ELSE
         -- 
         -- NORTHERN HEMISPHERE OR NO DST 
         -- 
         L_OFF_UTC := L_OFF_BEG;
         L_OFF_DST := L_OFF_MID - L_OFF_BEG;
      END IF;
      BEGIN
         INSERT INTO @timezoneTableName
            (
               TIME_ZONE_CODE, 
               TIME_ZONE_NAME, 
               UTC_OFFSET, 
               DST_OFFSET
            ) VALUES 
            (
               L_CODE,
               L_TZREGION,
               L_OFF_UTC,
               L_OFF_DST
            );
      EXCEPTION
         WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('>>> ERROR INSERTING ' || L_TZREGION || ' ' || L_OFF_UTC || ', ' || L_OFF_DST);
      END;
   END LOOP;
   COMMIT;
END LOAD_@TABLE;
/
SHOW ERRORS
COMMIT;

BEGIN LOAD_@TABLE; END;
/

 DROP PROCEDURE LOAD_@TABLE;
 COMMIT;

'''

sys.stderr.write("Building timezoneAliasCreationTemplate\n")
timezoneAliasCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE
   (
       TIME_ZONE_ALIAS VARCHAR2(9)  NOT NULL,
       TIME_ZONE_NAME  VARCHAR2(28) NOT NULL
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE
       (
          INITIAL 20K
          NEXT 20K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );

-----------------------------
-- @TABLE constraints
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK  PRIMARY KEY (TIME_ZONE_ALIAS);
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_FK1 FOREIGN KEY (TIME_ZONE_NAME) REFERENCES @timezoneTableName (TIME_ZONE_NAME);

-----------------------------
-- @TABLE comments
--
COMMENT ON TABLE @TABLE IS 'Contains timezone aliases for Java custom time zones.';
COMMENT ON COLUMN @TABLE.TIME_ZONE_ALIAS IS 'Time zone alias.';
COMMENT ON COLUMN @TABLE.TIME_ZONE_NAME IS 'References propert time zone name.';
COMMIT;

'''
sys.stderr.write("Building timezoneAliasLoadTemplate\n")
timezoneAliasLoadTemplate = ''
base_tzs = ['GMT', 'UTC']
signs    = ['-', '+']
seps     = [':', '']
for base_tz in range(len(base_tzs)) :
   for hour in range(13) :
      for sign in range(len(signs)) :
         oppositeSign = signs[(sign+1) % len(signs)]
         tz = 'Etc/GMT%s%d' % (oppositeSign, hour)
         for sep in range(len(seps)) :
            alias = '%s%s%2.2d%s00' % (base_tzs[base_tz], signs[sign], hour, seps[sep])
            timezoneAliasLoadTemplate += ("INSERT INTO %s VALUES ('%s', '%s');\n" % (timezoneAliasTableName, alias, tz))
            if hour < 10 :
               alias = '%s%s%d%s00' % (base_tzs[base_tz], signs[sign], hour, seps[sep])
               timezoneAliasLoadTemplate += ("INSERT INTO %s VALUES ('%s', '%s');\n" % (timezoneAliasTableName, alias, tz))
timezoneAliasLoadTemplate += 'COMMIT;\n'

sys.stderr.write("Building tzUsageCreationTemplate\n")
tzUsageCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE
   (
       TZ_USAGE_CODE NUMBER(10)   NOT NULL,
       TZ_USAGE_ID   VARCHAR2(8)  NOT NULL,
       DESCRIPTION   VARCHAR2(80)
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
       ( 
          INITIAL 200K
          NEXT 200K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );

-----------------------------
-- @TABLE indicies
--
CREATE UNIQUE INDEX @TABLE_UI ON @TABLE
   (
       UPPER(TZ_USAGE_ID)
   )
       PCTFREE 10
       INITRANS 2
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
       ( 
          INITIAL 200k
          NEXT 200k
          MINEXTENTS 1
          MAXEXTENTS 20
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
       );

-----------------------------
-- @TABLE constraints
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK  PRIMARY KEY (TZ_USAGE_CODE);

-----------------------------
-- @TABLE comments
--
COMMENT ON TABLE @TABLE IS 'Contains timezone usage information.';
COMMENT ON COLUMN @TABLE.TZ_USAGE_CODE IS 'Primary key used to relate parameters other entities';
COMMENT ON COLUMN @TABLE.TZ_USAGE_ID   IS 'Timezone usage text identifier';
COMMENT ON COLUMN @TABLE.DESCRIPTION   IS 'Timezone usage text description';
COMMIT;

'''

sys.stderr.write("Building tzUsageLoadTemplate\n")
tzUsageLoadTemplate = ''
for i in range(len(tzUsages)) :
    code = i+1
    tzUsageLoadTemplate +="INSERT INTO @tzUsageTableName (TZ_USAGE_CODE, TZ_USAGE_ID, DESCRIPTION) VALUES (\n"
    tzUsageLoadTemplate +="\t%d,\n" % code
    tzUsageLoadTemplate +="\t'%s',\n" % tzUsages[i]["ID"]
    tzUsageLoadTemplate +="\t'%s'\n" % tzUsages[i]["DESCRIPTION"]
    tzUsageLoadTemplate +=");\n"
tzUsageLoadTemplate +="COMMIT;\n"

sys.stderr.write("Building qScreenedCreationTemplate\n")
qScreenedCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE 
   (
       SCREENED_ID   VARCHAR2(16)  NOT NULL,
       DESCRIPTION   VARCHAR2(80)
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
   ( 
          INITIAL 10K
          NEXT 10K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
   );
   
-------------------------------
-- @TABLE constraints  --
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK PRIMARY KEY (SCREENED_ID);

---------------------------
-- @TABLE comments --
--
COMMENT ON TABLE  @TABLE               IS 'Contains valid values for the screened component of CWMS data quality flags';
COMMENT ON COLUMN @TABLE.SCREENED_ID   IS 'Text identifier of screened component and primary key';
COMMENT ON COLUMN @TABLE.DESCRIPTION   IS 'Text description of screened component';

COMMIT;
'''
sys.stderr.write("Building qScreenedLoadTemplate\n")
qScreenedLoadTemplate = ''
for code, id, description in q_screened["values"] :
    qScreenedLoadTemplate += "INSERT INTO @TABLE VALUES('%s', '%s');\n" % (id, description)
qScreenedLoadTemplate += "COMMIT;\n"

sys.stderr.write("Building qValidityCreationTemplate\n")
qValidityCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE 
   (
       VALIDITY_ID   VARCHAR2(16)  NOT NULL,
       DESCRIPTION   VARCHAR2(80)
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
   ( 
          INITIAL 10K
          NEXT 10K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
   );
   
-------------------------------
-- @TABLE constraints  --
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK PRIMARY KEY (VALIDITY_ID);

---------------------------
-- @TABLE comments --
--
COMMENT ON TABLE  @TABLE               IS 'Contains valid values for the validity component of CWMS data quality flags';
COMMENT ON COLUMN @TABLE.VALIDITY_ID   IS 'Text identifier of validity component and primary key';
COMMENT ON COLUMN @TABLE.DESCRIPTION   IS 'Text description of validity component';

COMMIT;
'''
sys.stderr.write("Building qValidityLoadTemplate\n")
qValidityLoadTemplate = ''
for code, id, description in q_validity["values"] :
    qValidityLoadTemplate += "INSERT INTO @TABLE VALUES('%s', '%s');\n" % (id, description)
qValidityLoadTemplate += "COMMIT;\n"

sys.stderr.write("Building qRangeCreationTemplate\n")
qRangeCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE 
   (
       RANGE_ID    VARCHAR2(16)  NOT NULL,
       DESCRIPTION VARCHAR2(80)
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
   ( 
          INITIAL 10K
          NEXT 10K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
   );
   
-------------------------------
-- @TABLE constraints  --
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK PRIMARY KEY (RANGE_ID);

---------------------------
-- @TABLE comments --
--
COMMENT ON TABLE  @TABLE             IS 'Contains valid values for the range component of CWMS data quality flags';
COMMENT ON COLUMN @TABLE.RANGE_ID    IS 'Text identifier of range component and primary key';
COMMENT ON COLUMN @TABLE.DESCRIPTION IS 'Text description of range component';

COMMIT;
'''
sys.stderr.write("Building qRangeLoadTemplate\n")
qRangeLoadTemplate = ''
for code, id, description in q_value_range["values"] :
    qRangeLoadTemplate += "INSERT INTO @TABLE VALUES('%s', '%s');\n" % (id, description)
qRangeLoadTemplate += "COMMIT;\n"

sys.stderr.write("Building qChangedCreationTemplate\n")
qChangedCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE 
   (
       CHANGED_ID   VARCHAR2(16)  NOT NULL,
       DESCRIPTION  VARCHAR2(80)
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
   ( 
          INITIAL 10K
          NEXT 10K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
   );
   
-------------------------------
-- @TABLE constraints  --
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK PRIMARY KEY (CHANGED_ID);

---------------------------
-- @TABLE comments --
--
COMMENT ON TABLE  @TABLE              IS 'Contains valid values for the changed component of CWMS data quality flags';
COMMENT ON COLUMN @TABLE.CHANGED_ID   IS 'Text identifier of changed component and primary key';
COMMENT ON COLUMN @TABLE.DESCRIPTION  IS 'Text description of changed component';

COMMIT;
'''
sys.stderr.write("Building qChangedLoadTemplate\n")
qChangedLoadTemplate = ''
for code, id, description in q_different["values"] :
    qChangedLoadTemplate += "INSERT INTO @TABLE VALUES('%s', '%s');\n" % (id, description)
qChangedLoadTemplate += "COMMIT;\n"

sys.stderr.write("Building qReplCauseCreationTemplate\n")
qReplCauseCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE 
   (
       REPL_CAUSE_ID   VARCHAR2(16)  NOT NULL,
       DESCRIPTION     VARCHAR2(80)
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
   ( 
          INITIAL 10K
          NEXT 10K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
   );
   
-------------------------------
-- @TABLE constraints  --
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK PRIMARY KEY (REPL_CAUSE_ID);

---------------------------
-- @TABLE comments --
--
COMMENT ON TABLE  @TABLE                 IS 'Contains valid values for the replacement cause component of CWMS data quality flags';
COMMENT ON COLUMN @TABLE.REPL_CAUSE_ID   IS 'Text identifier of replacement cause component and primary key';
COMMENT ON COLUMN @TABLE.DESCRIPTION     IS 'Text description of replacement cause component';

COMMIT;
'''
sys.stderr.write("Building qReplCauseLoadTemplate\n")
qReplCauseLoadTemplate = ''
for code, id, description in q_replacement_cause["values"] :
    qReplCauseLoadTemplate += "INSERT INTO @TABLE VALUES('%s', '%s');\n" % (id, description)
qReplCauseLoadTemplate += "COMMIT;\n"

sys.stderr.write("Building qReplMethodCreationTemplate\n")
qReplMethodCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE 
   (
       REPL_METHOD_ID   VARCHAR2(16)  NOT NULL,
       DESCRIPTION      VARCHAR2(80)
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
   ( 
          INITIAL 10K
          NEXT 10K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
   );
   
-------------------------------
-- @TABLE constraints  --
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK PRIMARY KEY (REPL_METHOD_ID);

---------------------------
-- @TABLE comments --
--
COMMENT ON TABLE  @TABLE                  IS 'Contains valid values for the replacement method component of CWMS data quality flags';
COMMENT ON COLUMN @TABLE.REPL_METHOD_ID   IS 'Text identifier of replacement method component and primary key';
COMMENT ON COLUMN @TABLE.DESCRIPTION      IS 'Text description of replacement method component';

COMMIT;
'''
sys.stderr.write("Building qReplMethodLoadTemplate\n")
qReplMethodLoadTemplate = ''
for code, id, description in q_replacement_method["values"] :
    qReplMethodLoadTemplate += "INSERT INTO @TABLE VALUES('%s', '%s');\n" % (id, description)
qReplMethodLoadTemplate += "COMMIT;\n"
        
sys.stderr.write("Building qTestFailedCreationTemplate\n")
qTestFailedCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE 
   (
       TEST_FAILED_ID   VARCHAR2(125)  NOT NULL,
       DESCRIPTION      VARCHAR2(80)
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
   ( 
          INITIAL 10K
          NEXT 10K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
   );
   
-------------------------------
-- @TABLE constraints  --
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK PRIMARY KEY (TEST_FAILED_ID);

---------------------------
-- @TABLE comments --
--
COMMENT ON TABLE  @TABLE                  IS 'Contains valid values for the test failed component of CWMS data quality flags';
COMMENT ON COLUMN @TABLE.TEST_FAILED_ID   IS 'Text identifier of test failed component and primary key';
COMMENT ON COLUMN @TABLE.DESCRIPTION      IS 'Text description of test failed component';

COMMIT;
'''

sys.stderr.write("Building qTestFailedLoadTemplate\n")
qTestFailedLoadTemplate = ''
for code, id, description in q_test_failed["values"] :
    qTestFailedLoadTemplate += "INSERT INTO @TABLE VALUES('%s', '%s');\n" % (id, description)
qTestFailedLoadTemplate += "COMMIT;\n"
        
sys.stderr.write("Building qProtectionCreationTemplate\n")
qProtectionCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE 
   (
       PROTECTION_ID   VARCHAR2(16)  NOT NULL,
       DESCRIPTION     VARCHAR2(80)
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
   ( 
          INITIAL 10K
          NEXT 10K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
   );
   
-------------------------------
-- @TABLE constraints  --
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK PRIMARY KEY (PROTECTION_ID);

---------------------------
-- @TABLE comments --
--
COMMENT ON TABLE  @TABLE                 IS 'Contains valid values for the protection component of CWMS data quality flags';
COMMENT ON COLUMN @TABLE.PROTECTION_ID   IS 'Text identifier of protection component and primary key';
COMMENT ON COLUMN @TABLE.DESCRIPTION     IS 'Text description of protection component';

COMMIT;
'''
sys.stderr.write("Building qProtectionLoadTemplate\n")
qProtectionLoadTemplate = ''
for code, id, description in q_protection["values"] :
    qProtectionLoadTemplate += "INSERT INTO @TABLE VALUES('%s', '%s');\n" % (id, description)
qProtectionLoadTemplate += "COMMIT;\n"

sys.stderr.write("Building qualityCreationTemplate\n")
qualityCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE 
   (
       QUALITY_CODE   NUMBER(10)    NOT NULL,
       SCREENED_ID    VARCHAR2(16)  NOT NULL,
       VALIDITY_ID    VARCHAR2(16)  NOT NULL,
       RANGE_ID       VARCHAR2(16)  NOT NULL,
       CHANGED_ID     VARCHAR2(16)  NOT NULL,
       REPL_CAUSE_ID  VARCHAR2(16)  NOT NULL,
       REPL_METHOD_ID VARCHAR2(16)  NOT NULL,
       TEST_FAILED_ID VARCHAR2(125) NOT NULL,
       PROTECTION_ID  VARCHAR2(16)  NOT NULL
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
   ( 
          INITIAL 300K
          NEXT 300K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
   );
   
-------------------------------
-- @TABLE constraints  --
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK   PRIMARY KEY (QUALITY_CODE    );
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_FK1 FOREIGN KEY (SCREENED_ID   ) REFERENCES @qScreenedTableName   (SCREENED_ID   );
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_FK2 FOREIGN KEY (PROTECTION_ID ) REFERENCES @qProtectionTableName (PROTECTION_ID );
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_FK3 FOREIGN KEY (VALIDITY_ID   ) REFERENCES @qValidityTableName   (VALIDITY_ID   );
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_FK4 FOREIGN KEY (RANGE_ID      ) REFERENCES @qRangeTableName      (RANGE_ID      );
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_FK5 FOREIGN KEY (CHANGED_ID    ) REFERENCES @qChangedTableName    (CHANGED_ID    );
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_FK6 FOREIGN KEY (REPL_CAUSE_ID ) REFERENCES @qReplCauseTableName  (REPL_CAUSE_ID );
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_FK7 FOREIGN KEY (REPL_METHOD_ID) REFERENCES @qReplMethodTableName (REPL_METHOD_ID);
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_FK8 FOREIGN KEY (TEST_FAILED_ID) REFERENCES @qTestFailedTableName (TEST_FAILED_ID);

---------------------------
-- @TABLE comments --
--
COMMENT ON TABLE  @TABLE                IS 'Contains CWMS data quality flags';
COMMENT ON COLUMN @TABLE.QUALITY_CODE   IS 'Quality value as an unsigned integer and primary key for relating quality to other entities';
COMMENT ON COLUMN @TABLE.SCREENED_ID    IS 'Foreign key referencing @qScreenedTableName table by its primary key';
COMMENT ON COLUMN @TABLE.VALIDITY_ID    IS 'Foreign key referencing @qValidityTableName table by its primary key';
COMMENT ON COLUMN @TABLE.RANGE_ID       IS 'Foreign key referencing @qRangeTableName table by its primary key';
COMMENT ON COLUMN @TABLE.CHANGED_ID     IS 'Foreign key referencing @qChangedTableName table by its primary key';
COMMENT ON COLUMN @TABLE.REPL_CAUSE_ID  IS 'Foreign key referencing @qReplCauseTableName table by its primary key';
COMMENT ON COLUMN @TABLE.REPL_METHOD_ID IS 'Foreign key referencing @qReplMethodTableName table by its primary key';
COMMENT ON COLUMN @TABLE.TEST_FAILED_ID IS 'Foreign key referencing @qTestFailedTableName table by its primary key';
COMMENT ON COLUMN @TABLE.PROTECTION_ID  IS 'Foreign key referencing @qProtectionTableName table by its primary key';
COMMIT;
'''
sys.stderr.write("Building qualityLoadFile\n")
qualityLoadFilename = "qualityLoader.ctl"
qualityLoadFile = open(qualityLoadFilename, "w")
qualityLoadFile.write('''load data
  infile *
  into table cwms_data_quality
  fields terminated by ","
  (QUALITY_CODE,SCREENED_ID,VALIDITY_ID,RANGE_ID,CHANGED_ID,REPL_CAUSE_ID,REPL_METHOD_ID,TEST_FAILED_ID,PROTECTION_ID)
begindata
''')

qualityLoadFile.write("%lu,%s,%s,%s,%s,%s,%s,%s,%s\n" % (
    0,                                    # unsigned value
    q_screened["values"][0][1],           # screened code
    q_validity["values"][0][1],           # validity code
    q_value_range["values"][0][1],        # range code
    q_different["values"][0][1],          # changed code
    q_replacement_cause["values"][0][1],  # replacement cause code
    q_replacement_method["values"][0][1], # replacement method code
    q_test_failed["values"][0][1],        # test failed code
    q_protection["values"][0][1]))        # protection code
    
for v in range(len(q_validity["values"])) :
    for r in range(len(q_value_range["values"])) :
        for d in range(len(q_different["values"])) :
            for c in range(len(q_replacement_cause["values"])) :
                if (d > 0) != (c > 0) : continue
                for m in range(len(q_replacement_method["values"])) :
                    if (d > 0) != (m > 0) : continue
                    for t in range(len(q_test_failed["values"])) :
                        for p in range(len(q_protection["values"])) :
                            value = 0L \
                                | (q_screened["values"][1][0] << q_screened["shift"]) \
                                | (q_validity["values"][v][0] << q_validity["shift"]) \
                                | (q_value_range["values"][r][0] << q_value_range["shift"]) \
                                | (q_different["values"][d][0] << q_different["shift"]) \
                                | (q_replacement_cause["values"][c][0] << q_replacement_cause["shift"]) \
                                | (q_replacement_method["values"][m][0] << q_replacement_method["shift"]) \
                                | (q_test_failed["values"][t][0] << q_test_failed["shift"]) \
                                | (q_protection["values"][p][0] << q_protection["shift"])
                            qualityLoadFile.write("%lu,%s,%s,%s,%s,%s,%s,%s,%s\n" % (
                                value,                                # unsigned value
                                q_screened["values"][1][1],           # screened code
                                q_validity["values"][v][1],           # validity code
                                q_value_range["values"][r][1],        # range code
                                q_different["values"][d][1],          # changed code
                                q_replacement_cause["values"][c][1],  # replacement cause code
                                q_replacement_method["values"][m][1], # replacement method code
                                q_test_failed["values"][t][1],        # test failed code
                                q_protection["values"][p][1]))        # protection code
        
qualityLoadFile.close()

sys.stderr.write("Building logMessageTypesCreationTemplate\n")
logMessageTypesCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE 
   (
       MESSAGE_TYPE_CODE NUMBER(2)    NOT NULL,
       MESSAGE_TYPE_ID   VARCHAR2(32) NOT NULL
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
   ( 
          INITIAL 1K
          NEXT 1K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
   );
   
-------------------------------
-- @TABLE constraints  --
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK PRIMARY KEY (MESSAGE_TYPE_CODE);

---------------------------
-- @TABLE comments --
--
COMMENT ON TABLE  @TABLE                   IS 'Contains valid values for the MSG_TYPE field of logged status messages';
COMMENT ON COLUMN @TABLE.MESSAGE_TYPE_CODE IS 'Numeric code corresponding to the message type name';
COMMENT ON COLUMN @TABLE.MESSAGE_TYPE_ID   IS 'The message type name';

COMMIT;
'''
sys.stderr.write("Building logMessageTypesLoadTemplate\n")
logMessageTypesLoadTemplate = ''
for code, id in logMessageTypes :
    logMessageTypesLoadTemplate += "INSERT INTO @TABLE VALUES (%d, '%s');\n" % (code, id)
logMessageTypesLoadTemplate += "COMMIT;\n"

sys.stderr.write("Building logMessagePropTypesCreationTemplate\n")
logMessagePropTypesCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE 
   (
       PROP_TYPE_CODE NUMBER(1)   NOT NULL,
       PROP_TYPE_ID   VARCHAR2(8) NOT NULL
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
   ( 
          INITIAL 1K
          NEXT 1K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
   );
   
-------------------------------
-- @TABLE constraints  --
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK PRIMARY KEY (PROP_TYPE_CODE);

---------------------------
-- @TABLE comments --
--
COMMENT ON TABLE  @TABLE                IS 'Contains valid values for the PROP_TYPE field of logged status message properties';
COMMENT ON COLUMN @TABLE.PROP_TYPE_CODE IS 'Numeric code corresponding to the property type name';
COMMENT ON COLUMN @TABLE.PROP_TYPE_ID   IS 'The property type name';

COMMIT;
'''
sys.stderr.write("Building logMessagePropTypesLoadTemplate\n")
logMessagePropTypesLoadTemplate = ''
for code, id in logMessagePropTypes :
    logMessagePropTypesLoadTemplate += "INSERT INTO @TABLE VALUES (%d, '%s');\n" % (code, id)
logMessagePropTypesLoadTemplate += "COMMIT;\n"

sys.stderr.write("Building intpolateUnitsCreationTemplate\n")
interpolateUnitsCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE 
   (
       INTERPOLATE_UNITS_CODE NUMBER(1)   NOT NULL,
       INTERPOLATE_UNITS_ID   VARCHAR2(16) NOT NULL
   )
       PCTFREE 10
       PCTUSED 40
       INITRANS 1
       MAXTRANS 255
       TABLESPACE @DATASPACE
       STORAGE 
   ( 
          INITIAL 1K
          NEXT 1K
          MINEXTENTS 1
          MAXEXTENTS 200
          PCTINCREASE 25
          FREELISTS 1
          FREELIST GROUPS 1
          BUFFER_POOL DEFAULT
   );
   
-------------------------------
-- @TABLE constraints  --
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK PRIMARY KEY (INTERPOLATE_UNITS_CODE);

---------------------------
-- @TABLE comments --
--
COMMENT ON TABLE  @TABLE                       IS 'Contains valid values for time series interpolation units';
COMMENT ON COLUMN @TABLE.INTERPOLATE_UNITS_CODE IS 'Numeric code corresponding to the interpolation units';
COMMENT ON COLUMN @TABLE.INTERPOLATE_UNITS_ID   IS 'The interpolation units';

COMMIT;
'''
sys.stderr.write("Building interpolateUnitsLoadTemplate\n")
interpolateUnitsLoadTemplate = ''
for code, id in interpolateUnits :
    interpolateUnitsLoadTemplate += "INSERT INTO @TABLE VALUES (%d, '%s');\n" % (code, id)
interpolateUnitsLoadTemplate += "COMMIT;\n"

sys.stderr.write("Building displayUnitsCreationTemplate\n")
displayUnitsCreationTemplate = \
'''
---------------------------------
-- AT_DISPLAY_UNITS table
-- 
CREATE TABLE AT_DISPLAY_UNITS
(
  DB_OFFICE_CODE     NUMBER                     NOT NULL,
  PARAMETER_CODE     NUMBER                     NOT NULL,
  UNIT_SYSTEM        VARCHAR2(2 BYTE)           NOT NULL,
  DISPLAY_UNIT_CODE  NUMBER                     NOT NULL
)
TABLESPACE @DATASPACE
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;


CREATE UNIQUE INDEX AT_DISPLAY_UNITS_PK1 ON AT_DISPLAY_UNITS
(DB_OFFICE_CODE, PARAMETER_CODE, UNIT_SYSTEM)
LOGGING
TABLESPACE @DATASPACE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;


ALTER TABLE AT_DISPLAY_UNITS ADD (
  CONSTRAINT AT_DISPLAY_UNITS_PK1
 PRIMARY KEY
 (DB_OFFICE_CODE, PARAMETER_CODE, UNIT_SYSTEM)
    USING INDEX 
    tablespace CWMS_20DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ));


ALTER TABLE AT_DISPLAY_UNITS ADD (
  CONSTRAINT AT_DISPLAY_UNITS_FK02 
 FOREIGN KEY (DISPLAY_UNIT_CODE) 
 REFERENCES CWMS_UNIT (UNIT_CODE));

ALTER TABLE AT_DISPLAY_UNITS ADD (
  CONSTRAINT AT_DISPLAY_UNITS_FK01 
 FOREIGN KEY (PARAMETER_CODE) 
 REFERENCES AT_PARAMETER (PARAMETER_CODE));
'''

sys.stderr.write("Building displayUnitsLoadTemplate\n")
displayUnitsLoadTemplate = ''

for k in range(len(office_ids)) :
    dbOfcCode = db_office_code[office_ids[k]]
    displayUnitsLoadTemplate +="DECLARE\n"
    displayUnitsLoadTemplate +="BEGIN\n"
    displayUnitsLoadTemplate +="   INSERT INTO at_display_units\n"
    displayUnitsLoadTemplate +="      SELECT %s, a.parameter_code, 'EN', b.display_unit_code_en\n" % (dbOfcCode)
    displayUnitsLoadTemplate +="        FROM at_parameter a, cwms_base_parameter b\n"
    displayUnitsLoadTemplate +="       WHERE a.base_parameter_code = b.base_parameter_code\n"
    displayUnitsLoadTemplate +="         AND a.sub_parameter_id IS NULL;\n"
    displayUnitsLoadTemplate +="\n"
    displayUnitsLoadTemplate +="   INSERT INTO at_display_units\n"
    displayUnitsLoadTemplate +="      SELECT %s, a.parameter_code, 'SI', b.display_unit_code_si\n" % (dbOfcCode)
    displayUnitsLoadTemplate +="        FROM at_parameter a, cwms_base_parameter b\n"
    displayUnitsLoadTemplate +="       WHERE a.base_parameter_code = b.base_parameter_code\n"
    displayUnitsLoadTemplate +="         AND a.sub_parameter_id IS NULL;\n"
    displayUnitsLoadTemplate +="END;\n"
    displayUnitsLoadTemplate +="/\n"
    #
    unitSys = ['SI', 'EN']
    for i in range(len(subParameters)) :
        baseCode, baseParamId, subParamId, longName, siUnitId, enUnitId = subParameters[i]
        dispUnitId =[siUnitId, enUnitId]
        for j in range(len(unitSys)) :
            displayUnitsLoadTemplate +="INSERT INTO at_display_units\n"
            displayUnitsLoadTemplate +="            (db_office_code, parameter_code, unit_system,\n"
            displayUnitsLoadTemplate +="             display_unit_code\n"
            displayUnitsLoadTemplate +="            )\n"
            displayUnitsLoadTemplate +="     VALUES (%s, %s, '%s',\n" % (dbOfcCode, baseCode, unitSys[j])
            displayUnitsLoadTemplate +="             (SELECT a.unit_code\n"
            displayUnitsLoadTemplate +="                FROM cwms_unit a, at_parameter b, cwms_base_parameter c\n"
            displayUnitsLoadTemplate +="               WHERE unit_id = '%s'\n" % dispUnitId[j]
            displayUnitsLoadTemplate +="                 AND b.base_parameter_code = c.base_parameter_code\n"
            displayUnitsLoadTemplate +="                 AND a.abstract_param_code = c.abstract_param_code\n"
            displayUnitsLoadTemplate +="                 AND b.parameter_code = %s)\n" % (baseCode)
            displayUnitsLoadTemplate +="            )\n"
            displayUnitsLoadTemplate +="/\n"
displayUnitsLoadTemplate +="COMMIT;\n"



sys.stderr.write("Building locationKindCreationTemplate\n")
locationKindCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE
(
   LOCATION_KIND_CODE NUMBER(10)     NOT NULL,
   OFFICE_CODE        NUMBER(10)     NOT NULL,
   LOCATION_KIND_ID   VARCHAR2(32)   NOT NULL,
   DESCRIPTION        VARCHAR2(256)
)
tablespace CWMS_20DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
        INITIAL          10K
        NEXT             10K
        MINEXTENTS       1
        MAXEXTENTS       UNLIMITED
        PCTINCREASE      0
        BUFFER_POOL      DEFAULT
       )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;

-------------------------------
-- @TABLE constraints  --
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK  PRIMARY KEY (LOCATION_KIND_CODE) USING INDEX;
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_U1  UNIQUE (OFFICE_CODE, LOCATION_KIND_ID);
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_CK1 CHECK(TRIM(UPPER(LOCATION_KIND_ID)) = LOCATION_KIND_ID);
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_FK1 FOREIGN KEY (OFFICE_CODE) REFERENCES CWMS_OFFICE (OFFICE_CODE);

---------------------------
-- @TABLE comments --
--
COMMENT ON TABLE  @TABLE                    IS 'Contains location kinds.';
COMMENT ON COLUMN @TABLE.LOCATION_KIND_CODE IS 'Primary key relating location kinds to other entities.';
COMMENT ON COLUMN @TABLE.OFFICE_CODE        IS 'Office that generated/owns this kind code';
COMMENT ON COLUMN @TABLE.LOCATION_KIND_ID   IS 'Text name used as an input to the lookup.';
COMMENT ON COLUMN @TABLE.DESCRIPTION        IS 'Optional description or comments.';

COMMIT;
'''
sys.stderr.write("Building locationKindLoadTemplate\n")
locationKindLoadTemplate = ''
for code, id, description in locationKinds :
    locationKindLoadTemplate += "INSERT INTO @TABLE VALUES (%d, 53, '%s', '%s');\n" % (code, id, description)
locationKindLoadTemplate += "COMMIT;\n"

sys.stderr.write("Building gageMethodCreationTemplate\n")
gageMethodCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE
(
   METHOD_CODE NUMBER(10)    NOT NULL,
   METHOD_ID   VARCHAR2(32)  NOT NULL,
   DESCRIPTION VARCHAR2(256)
)
tablespace CWMS_20DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          10K
            NEXT             10K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;

-------------------------------
-- @TABLE constraints  --
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK  PRIMARY KEY(METHOD_CODE) USING INDEX;
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_U1  UNIQUE (METHOD_ID) USING INDEX;
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_CK1 CHECK (TRIM(METHOD_ID) = METHOD_ID);
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_CK2 CHECK (UPPER(METHOD_ID) = METHOD_ID);

---------------------------
-- @TABLE comments --
--
COMMENT ON TABLE  @TABLE             IS 'Contains inquiry and transmission methods gages.';
COMMENT ON COLUMN @TABLE.METHOD_CODE IS 'Primary key relating methods to other entities.'; 
COMMENT ON COLUMN @TABLE.METHOD_ID   IS 'Name of method (''MANUAL'', ''PHONE'', ''INTERNET'', ''GOES'', etc...).'; 
COMMENT ON COLUMN @TABLE.DESCRIPTION IS 'Optional description.';

COMMIT;
'''
sys.stderr.write("Building gageMethodLoadTemplate\n")
gageMethodLoadTemplate = ''
for code, id, description in gageMethods :
    gageMethodLoadTemplate += "INSERT INTO @TABLE VALUES (%d, '%s', '%s');\n" % (code, id, description)
gageMethodLoadTemplate += "COMMIT;\n"

sys.stderr.write("Building gageTypeCreationTemplate\n")
gageTypeCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE
(
   GAGE_TYPE_CODE      NUMBER(10)    NOT NULL,
   GAGE_TYPE_ID        VARCHAR2(32)  NOT NULL,
   MANUALLY_READ       VARCHAR2(1)   NOT NULL,
   INQUIRY_METHOD      NUMBER(10),
   TRANSMIT_METHOD     NUMBER(10), 
   DESCRIPTION         VARCHAR2(256)
)
tablespace CWMS_20DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          10K
            NEXT             10K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;


-------------------------------
-- @TABLE constraints  --
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK  PRIMARY KEY (GAGE_TYPE_CODE) USING INDEX;
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_CK1 CHECK (TRIM(GAGE_TYPE_ID) = GAGE_TYPE_ID);
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_FK1 FOREIGN KEY (INQUIRY_METHOD) REFERENCES CWMS_GAGE_METHOD (METHOD_CODE);
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_FK2 FOREIGN KEY (TRANSMIT_METHOD) REFERENCES CWMS_GAGE_METHOD (METHOD_CODE);

-------------------------------
-- @TABLE indicies  --
--
CREATE UNIQUE INDEX @TABLE_U1 ON @TABLE (UPPER(GAGE_TYPE_ID))
LOGGING
tablespace CWMS_20DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          10K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;

---------------------------
-- @TABLE comments --
--
COMMENT ON TABLE  @TABLE                 IS 'Contains pre-defined gage types.';
COMMENT ON COLUMN @TABLE.GAGE_TYPE_CODE  IS 'Primary key used to relate gage types to other entities.';
COMMENT ON COLUMN @TABLE.GAGE_TYPE_ID    IS 'Name of gage type.';
COMMENT ON COLUMN @TABLE.MANUALLY_READ   IS 'Indicator of whether gage is manually read.';
COMMENT ON COLUMN @TABLE.INQUIRY_METHOD  IS 'Reference to method of inquiry.';
COMMENT ON COLUMN @TABLE.TRANSMIT_METHOD IS 'Reference to method of data transmission.';
COMMENT ON COLUMN @TABLE.DESCRIPTION     IS 'Optional description.';

COMMIT;
'''
sys.stderr.write("Building gageTypeLoadTemplate\n")
gageTypeLoadTemplate = ''
for code, id, manually_read, inquiry_method, tx_method, description in gageTypes :
    if inquiry_method != 'NULL' :
        inquiry_method = "(SELECT METHOD_CODE FROM CWMS_GAGE_METHOD WHERE METHOD_ID='%s')" % inquiry_method
    if tx_method != 'NULL' :
        tx_method = "(SELECT METHOD_CODE FROM CWMS_GAGE_METHOD WHERE METHOD_ID='%s')" % tx_method
    gageTypeLoadTemplate += "INSERT INTO @TABLE VALUES (%d, '%s', '%s', %s, %s, '%s');\n" % \
        (code, id, manually_read, inquiry_method, tx_method, description)
gageTypeLoadTemplate += "COMMIT;\n"
gageTypeLoadTemplate = gageTypeLoadTemplate.replace("'NULL'", "NULL")

sys.stderr.write("Building nationCreationTemplate\n")
nationCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE
(
   NATION_CODE VARCHAR2(2)  NOT NULL,
   NATION_ID   VARCHAR2(48) NOT NULL
)
tablespace CWMS_20DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          10K
            NEXT             10K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;

-------------------------------
-- @TABLE constraints  --
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK  PRIMARY KEY (NATION_CODE) USING INDEX;
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_CK1 CHECK (TRIM(NATION_ID) = NATION_ID);

-------------------------------
-- @TABLE indicies  --
--
CREATE UNIQUE INDEX @TABLE_U1 ON @TABLE (UPPER(NATION_ID))
LOGGING
TABLESPACE CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          10K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;

---------------------------
-- @TABLE comments --
--
COMMENT ON TABLE  @TABLE             IS 'Contains names of nations';
COMMENT ON COLUMN @TABLE.NATION_CODE IS 'Primary key used to relate nation to other entities';
COMMENT ON COLUMN @TABLE.NATION_ID   IS 'Name of nation';

COMMIT;
'''
sys.stderr.write("Building nationLoadTemplate\n")
nationLoadTemplate = ''
for code, id,  in nations :
    nationLoadTemplate += "INSERT INTO @TABLE VALUES ('%s', '%s');\n" % (code, id.replace("'", "''"))
nationLoadTemplate += "COMMIT;\n"

sys.stderr.write("Building streamTypeCreationTemplate\n")
streamTypeCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE
(
  STREAM_TYPE_ID       VARCHAR2(4)  NOT NULL,
  NUMBER_OF_CHANNELS   VARCHAR2(8)  NOT NULL,
  ENTRENCHMENT_RATIO   VARCHAR2(32) NOT NULL,
  WIDTH_TO_DEPTH_RATIO VARCHAR2(32) NOT NULL,
  SINUOSITY            VARCHAR2(32) NOT NULL,
  SLOPE                VARCHAR2(32) NOT NULL,
  CHANNEL_MATERIAL     VARCHAR2(32) NOT NULL
)
tablespace CWMS_20DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          10K
            NEXT             10K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;

-------------------------------
-- @TABLE constraints  --
--
ALTER TABLE @TABLE ADD CONSTRAINT @TABLE_PK  PRIMARY KEY (STREAM_TYPE_ID) USING INDEX;

---------------------------
-- @TABLE comments --
--
COMMENT ON TABLE  @TABLE                      IS 'Contains pre-defined stream types based on Rosgen Classification (see http://www.wildlandhydrology.com/assets/ARM_5-3.pdf)';
COMMENT ON COLUMN @TABLE.STREAM_TYPE_ID       IS 'Rosgen Classification identifier';
COMMENT ON COLUMN @TABLE.NUMBER_OF_CHANNELS   IS 'Single or multiple channels';
COMMENT ON COLUMN @TABLE.ENTRENCHMENT_RATIO   IS 'Channel entrenchment ratio range';
COMMENT ON COLUMN @TABLE.WIDTH_TO_DEPTH_RATIO IS 'Channel width/Depth ratio range';
COMMENT ON COLUMN @TABLE.SINUOSITY            IS 'Channel sinuosity range';
COMMENT ON COLUMN @TABLE.SLOPE                IS 'Channel slope';
COMMENT ON COLUMN @TABLE.CHANNEL_MATERIAL     IS 'Channel material';

COMMIT;
'''
sys.stderr.write("Building streamTypeLoadTemplate\n")
streamTypeLoadTemplate = ''
for v1, v2, v3, v4, v5, v6, v7 in streamTypes :
    streamTypeLoadTemplate += "INSERT INTO @TABLE VALUES ('%s', '%s', '%s', '%s', '%s', '%s', '%s');\n" % (v1, v2, v3, v4, v5, v6, v7)
streamTypeLoadTemplate += "COMMIT;\n"

sys.stderr.write("Building msgIdCreationTemplate\n")
msgIdCreationTemplate = \
'''
-- ## TABLE ###############################################
-- ## @TABLE
-- ##
CREATE TABLE @TABLE
(
   LAST_MILLIS INTEGER,
   LAST_SEQ    INTEGER
)
tablespace CWMS_20DATA
/

---------------------------
-- @TABLE comments --
--
COMMENT ON TABLE  @TABLE             IS 'Contains data to generate message ids based on millisecond and sequence within millisecond';
COMMENT ON COLUMN @TABLE.LAST_MILLIS IS 'Millisecond of last message id generated';
COMMENT ON COLUMN @TABLE.LAST_SEQ    IS 'Sequence number within millisecond for last message id generated';

COMMIT;
'''
sys.stderr.write("Building msgIdLoadTemplate\n")
msgIdLoadTemplate = '''
   INSERT INTO @TABLE VALUES (0, 0);
   COMMIT;
'''

sys.stderr.write("Building schemaObjVersionCreationTemplate\n")
schemaObjVersionCreationTemplate = \
'''
CREATE TABLE @TABLE (
   HASH_CODE      VARCHAR2(40) NOT NULL,
   OBJECT_TYPE    VARCHAR2(30) NOT NULL,
   OBJECT_NAME    VARCHAR2(30) NOT NULL,
   SCHEMA_VERSION VARCHAR2(32) NOT NULL,
   COMMENTS       VARCHAR2(256),
   CONSTRAINT CWMS_SCHEMA_VERSION_PK PRIMARY KEY (HASH_CODE, OBJECT_TYPE, OBJECT_NAME, SCHEMA_VERSION)
)
TABLESPACE CWMS_20DATA
/
CREATE INDEX @TABLE_IDX ON @TABLE (SCHEMA_VERSION)
TABLESPACE CWMS_20DATA
/

COMMIT;
'''

#==
#====
#======
#-----------------------------------------------------------------#
# output commands to drop and re-create, populate and test tables #
#-----------------------------------------------------------------#
tables_rev = tables[:]
tables_rev.reverse()

sys.stderr.write("Outputting commands to drop and re-create tables.\n")
for table1 in tables :
    for table2 in tables :
        tableName = eval("%sTableName" % table2)
        try :
            cmdStr = "%sCreationTemplate = %sCreationTemplate.replace('@%sTableName', '%s')" % (table1, table1, table2, tableName)
            #sys.stderr.write("%s\n" % cmdStr);
            exec(cmdStr)
        except : 
            sys.stderr.write("\nERROR : Variable %sCreationTemplate does not exist, cannot continue.\n" % table1)
            sys.exit(-1)
        try : 
            cmdStr = "%sLoadTemplate  = %sLoadTemplate.replace('@%sTableName', '%s')" % (table1, table1, table2, tableName)
            #sys.stderr.write("%s\n" % cmdStr);
            exec(cmdStr)
        except : 
            pass
        try : 
            cmdStr = "%sTestTemplate  = %sTestTemplate.replace('@%sTableName', '%s')" % (table1, table1, table2, tableName)
            #sys.stderr.write("%s\n" % cmdStr);
            exec(cmdStr)
        except : 
            pass
            


#------------------------------------------------------------------------------
# Redirect stdout to the temp file
#------------------------------------------------------------------------------
sys.stdout = open(tempFilename, "w")

#print prefix[ALL] + "SET TIME ON"
#print "BUILDCWMS~SPOOL %s" % logFileName["BUILDCWMS"]
#print "BUILDUSER~SPOOL %s" % logFileName["BUILDUSER"]
#print "DROPCWMS~SPOOL %s"  % logFileName["DROPCWMS"]
#print "DROPUSER~SPOOL %s"  % logFileName["DROPUSER"]
#print prefix[ALL] + "SELECT SYSDATE FROM DUAL;"
#print prefix[ALL] + "SET ECHO ON"
print prefix[ALL] + "SET SERVEROUTPUT ON"
#print prefix[ALL] + "BEGIN DBMS_OUTPUT.ENABLE(20000); END;"
#print prefix[ALL] + "/"

for table in tables_rev :
    tableName = eval("%sTableName" % table)
    if schema[table] == "CWMS"  :
        tableSpaceName = cwmsTableSpaceName
        thisPrefix = prefix[CWMS]
    else :
        thisPrefix = prefix[USER]
        if tableName.find("TSV") != -1 :
            tableSpaceName = tsTableSpaceName
        else :
            tableSpaceName = userTableSpaceName
    dropPrefix = thisPrefix.replace("BUILD", "DROP")
    lines = eval("%sCreationTemplate.split('\\n')" % table)
    for i in range(len(lines)) : lines[i] = thisPrefix + lines[i]
    exec("%sCreationTemplate = '\\n'.join(lines)" % table)
    exec("%sCreationStr = %sCreationTemplate.replace('@TABLE', '%s')" % (table, table, tableName))
    exec("%sCreationStr = %sCreationStr.replace('@DATASPACE', '%s')" % (table, table, tableSpaceName))
    try :
        lines = eval("%sLoadTemplate.split('\\n')" % table)
        for i in range(len(lines)) : lines[i] = thisPrefix + lines[i]
        exec("%sLoadTemplate = '\\n'.join(lines)" % table)
        exec("%sLoadStr = %sLoadTemplate.replace('@TABLE', '%s')" % (table, table, tableName))
    except Exception, e:
        pass
    try :
        lines = eval("%sTestTemplate.split('\\n')" % table)
        for i in range(len(lines)) : lines[i] = thisPrefix + lines[i]
        exec("%sTestTemplate = '\\n'.join(lines)" % table)
        exec("%sTestStr = %sTestTemplate.replace('@TABLE', '%s')" % (table, table, tableName))
    except :
        pass
    print dropPrefix
    print "%sDROP TABLE %s;" % (dropPrefix, tableName)
    print "%sCOMMIT;" % dropPrefix

#==============================================================================
# Create CWMS_SEQ for the specified db_office_id's offset...
#==============================================================================
dropPrefix = prefix[CWMS].replace('BUILD', 'DROP')
print dropPrefix + "DROP SEQUENCE CWMS_SEQ;"
print prefix[CWMS] + "CREATE SEQUENCE CWMS_SEQ"
print prefix[CWMS] + "\tSTART WITH %s" % db_office_code[db_office_id]
print prefix[CWMS] + "\tINCREMENT BY 1000"
print prefix[CWMS] + "\tMINVALUE %s" % db_office_code[db_office_id]
print prefix[CWMS] + "\tMAXVALUE 1.0e38"
print prefix[CWMS] + "\tNOCYCLE"
print prefix[CWMS] + "\tCACHE 20"
print prefix[CWMS] + "\tORDER;"

#==============================================================================
# Create any other sequences...
#==============================================================================
cycleStr = ['NOCYCLE', 'CYCLE']
if len(cwmsSequences) :
    dropPrefix = prefix[CWMS].replace('BUILD', 'DROP')
    for name, start, increment, minimum, maximum, cycle, cache in cwmsSequences : 
        print dropPrefix + "DROP SEQUENCE %s;" % name
        print prefix[CWMS] + "CREATE SEQUENCE %s" % name
        print prefix[CWMS] + "\tSTART WITH %s" % `start`
        print prefix[CWMS] + "\tINCREMENT BY %s" % `increment`
        print prefix[CWMS] + "\tMINVALUE %s" % `minimum`
        print prefix[CWMS] + "\tMAXVALUE %s" % `maximum`
        print prefix[CWMS] + "\t%s" % cycleStr[cycle]
        print prefix[CWMS] + "\tCACHE %s" % `cache`
        print prefix[CWMS] + "\tORDER;"

print dropPrefix + "COMMIT;"
print prefix[CWMS] + "COMMIT;"

dropPrefix = prefix[USER].replace('BUILD', 'DROP')
for table in tables :
    print eval("%sCreationStr" % table)
#    if schema[table] == "CWMS" and userAccess[table] :
#        tableName = eval("%sTableName" % table)
#        print prefix[CWMS] + "GRANT SELECT ON %s TO %s;" % (tableName, userSchema)
#        print prefix[CWMS] + "GRANT REFERENCES ON %s TO %s;" % (tableName, userSchema)
        # generate private synonyms in the user schema
#        print prefix[USER] + "CREATE OR REPLACE SYNONYM %s FOR %s.%s;" % (tableName, schema[table], tableName)
#        print dropPrefix + "DROP SYNONYM %s;" % (tableName)
print dropPrefix + "COMMIT;"

for table in tables :
    try :
        print eval("%sLoadStr" % table)
    except :
        pass
for table in tables :
    try :
        print eval("%sTestStr" % table)
    except :
        pass

#print prefix[ALL] + "SPOOL OFF"
#print prefix[ALL] + "SET ECHO OFF"
#print prefix[ALL] + "SET TIME OFF"

#--------------------------------------------------------------------#
# read in the output we just generated and parse to individual files #
#--------------------------------------------------------------------#
sys.stderr.write("Splitting output in to files.")
sys.stdout.close()
sys.stdout = sys.__stdout__
sys.stderr.write("Reading from file %s\n" % tempFilename)
tempFile = open(tempFilename, "r")
lines = tempFile.readlines()
tempFile.close()
sys.stderr.write("Writing to files %s\n" % sqlFileName.values())
buildCwms = open(sqlFileName["BUILDCWMS"], "w")
#buildUser = open(sqlFileName["BUILDUSER"], "w")
dropCwms  = open(sqlFileName["DROPCWMS"], "w")
#dropUser  = open(sqlFileName["DROPUSER"], "w")
for line in lines :
    prefix, line = line.split("~", 1)
    if prefix.find("BUILDCWMS") != -1 : buildCwms.write(line)
    #if prefix.find("BUILDUSER") != -1 : buildUser.write(line)
    if prefix.find("DROPCWMS")  != -1 : dropCwms.write(line)
    #if prefix.find("DROPUSER")  != -1 : dropUser.write(line)
buildCwms.close()
#buildUser.close()
dropCwms.close()
#dropUser.close()
os.remove(tempFilename)

