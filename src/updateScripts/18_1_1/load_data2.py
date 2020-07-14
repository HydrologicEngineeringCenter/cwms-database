import cx_Oracle, datetime, getpass, os, sys


host = raw_input("Database Host      > ")
sid  = raw_input("Database SID       > ")
usr  = raw_input("Database User      > ")
pwd  = getpass.getpass("Database Password  > ")
port = 1521

conn = cx_Oracle.connect(dsn = cx_Oracle.makedsn(host, port, sid), user=usr, password=pwd)
crsr = conn.cursor()
print("Creating table CWMS_NID2")
crsr.execute("create table CWMS_NID2 as select * from CWMS_NID where 1=0")
conn.close()
t1 = datetime.datetime.now()
print("Loading new data for CWMS_NID2")
cmd = 'echo %s/"%s"@%s:%s/%s | sqlldr control=CWMS_NID2_DATA_TABLE.ctl' % (usr, pwd, host, port, sid)
# print(cmd)
os.system(cmd)
logfile = "%s_NID2_data.log" % sid
try    : os.remove(logfile)
except : pass
os.rename("CWMS_NID2_DATA_TABLE.log", logfile)
print("\nNID log is in %s" % logfile)
t2 = datetime.datetime.now()
print("NID data loaded in %s" % (t2-t1))
t1 = datetime.datetime.now()
print("Loading Ratings XSLT data")
os.system("sqlldr %s/%s@%s:%s/%s control=radar_xslt_clobs.ctl" % (usr, pwd2, host, port, sid))
t2 = datetime.datetime.now()
logfile = "%s_XSLT_data.log" % sid
try    : os.remove(logfile)
except : pass
os.rename("radar_xslt_clobs.log", logfile)
print("\nXSLT log is in %s" % logfile)
print("Ratings XSLT data loaded in %s" % (t2-t1))

