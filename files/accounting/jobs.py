#! /usr/bin/python2

import pycurl, json
from io import BytesIO

import time
import calendar
import datetime
import sys
import getopt
import socket

base_url = "http://" + socket.getfqdn() + ":19888"
begin_rel = 24 * 3600
end_rel = 0

try:
	opts, args = getopt.getopt(sys.argv[1:], "hm:b:e:", ["help", "mapred-url=", "begin=", "end="])
except getopt.GetoptError:
	print 'Args error'
	sys.exit(2)
for opt, arg in opts:
	if opt in ('-h', '--help'):
		print('jobs.py [-h|--help] [-m|--mapred-url URL] [-b|--begin] [-e|--end]')
	elif opt in ('-m', '--mapred-url'):
		base_url = arg
	elif opt in ('-b', '--begin'):
		begin_rel = int(arg)
	elif opt in ('-e', '--end'):
		end_rel = int(arg)
	else:
		print 'Args error'
		sys.exit(2)

# epoch time of local date
#now = datetime.date.today().strftime('%s')

# epoch time of GMT date
now0 = datetime.date.today()
now = calendar.timegm(datetime.datetime(now0.year, now0.month, now0.day, 0, 0).timetuple())
print '# ' + str(now0)

begin = now - begin_rel
end = now - end_rel
url = base_url + "/ws/v1/history/mapreduce/jobs?finishedTimeBegin=" + str(1000 * begin) + "&finishedTimeEnd=" + str(1000 * end)
print '# ' + url

b = BytesIO()
c = pycurl.Curl()
c.setopt(pycurl.URL, url)
#c.setopt(pycurl.WRITEDATA, b)
c.setopt(pycurl.WRITEFUNCTION, b.write)
c.setopt(pycurl.HTTPAUTH, pycurl.HTTPAUTH_GSSNEGOTIATE)
c.setopt(pycurl.USERPWD, ":")
c.perform()
s = b.getvalue().decode('utf-8')

if c.getinfo(c.RESPONSE_CODE) != 200:
	print s
	print 'Status: %d' % c.getinfo(c.RESPONSE_CODE)
	c.close()
	b.close()
	raise Exception()

c.close()

j = json.loads(s)
#print json.dumps(j, indent=4)

class User:
	jobs = 0
	total = 0
	completed = 0
	wait = 0
	time = 0
	wait_min = -1
	wait_max = -1

users = dict()
if j["jobs"]:
	for job in j["jobs"]["job"]:
		username = job["user"]

		if username not in users:
			users[username] = User()

		user = users[username]
		wait = job["startTime"] - job["submitTime"]

		user.jobs += 1
		user.total += job['reducesTotal'] + job['mapsTotal']
		user.completed += job['reducesCompleted'] + job['mapsCompleted']
		user.wait += wait
		user.time += job["finishTime"] - job["startTime"]
		if user.wait_min == -1 or wait < user.wait_min:
			user.wait_min = wait
		if user.wait_max == -1 or wait > user.wait_max:
			user.wait_max = wait

#		print '#[progress]', username, users[username].total, user.completed, user.wait, user.time

sql_begin = datetime.datetime.fromtimestamp(begin).strftime('%Y-%m-%d %H:%M:%S')
sql_end = datetime.datetime.fromtimestamp(end).strftime('%Y-%m-%d %H:%M:%S')
print "INSERT INTO measure (name, start, end) VALUES ('jobs', '%s', '%s');" % (sql_begin, sql_end)
for username, user in users.iteritems():
	print "INSERT INTO jobs (id_measure, user, jobs, done, fail, real_wait, real_time, wait_min, wait_max) VALUES (last_insert_id(), '%s', %d, %d, %d, %d, %d, %d, %d);" % (username, user.jobs, user.completed, user.total - user.completed, user.wait, user.time, user.wait_min, user.wait_max)
