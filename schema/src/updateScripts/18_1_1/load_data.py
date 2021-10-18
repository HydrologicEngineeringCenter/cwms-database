import cx_Oracle, datetime, getpass, os, sys


host = raw_input("Database Host      > ")
sid  = raw_input("Database SID       > ")
usr  = raw_input("Database User      > ")
pwd  = getpass.getpass("Database Password  > ")
port = 1521

conn = cx_Oracle.connect(dsn = cx_Oracle.makedsn(host, port, sid), user=usr, password=pwd)
crsr = conn.cursor()
print("Truncating table CWMS_NID")
crsr.execute("truncate table cwms_nid")
conn.close()
t1 = datetime.datetime.now()
print("Loading new data for CWMS_NID")
if pwd.find("^") != -1 :
	pwd2 = '"%s"' % pwd
else :
	pwd2 = pwd
os.system("sqlldr %s/%s@%s:%s/%s control=CWMS_NID_DATA_TABLE.ctl" % (usr, pwd2, host, port, sid))
logfile = "%s_NID_data.log" % sid
try    : os.remove(logfile)
except : pass
os.rename("CWMS_NID_DATA_TABLE.log", logfile)
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

