import cx_Oracle, datetime, getpass, os, sys


host = raw_input("Database Host     > ")
sid  = raw_input("Database SID      > ")
pwd  = getpass.getpass("CWMS_20 Password  > ")
port = 1521
usr  = "CWMS_20"

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
logfile = "%s_data.log" % sid
try    : os.remove(logfile)
except : pass
os.rename("CWMS_NID_DATA_TABLE.log", logfile)
print("\nLog is in %s" % logfile)
t2 = datetime.datetime.now()
print("Data loaded in %s" % (t2-t1))

