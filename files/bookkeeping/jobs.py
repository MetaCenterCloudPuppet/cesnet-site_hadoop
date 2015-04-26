#! /usr/bin/python2

import pycurl, json
from io import BytesIO

import getopt
import errno
import re
import sys
import socket

import MySQLdb

class Job:
	name = None
	status = None
	user = None
	queue = None
	start = None
	finish = None
	mapred = None
	yarn = None

class JobNode:
	elapsed = 0
	map = 0
	reduce = 0

class Node:
	host = None

class Counter:
	group = None
	counter = None

base_mapred_url=''
base_yarn_url=''
base_yarn_urls=list()
db = None
dbhost = 'localhost'
dbname = 'bookkeeping'
dbuser = 'bookkeeping'
dbpassword = ''
debug=0
gss=None
https=0
query=''
host=socket.getfqdn()
id = None

node_hosts = dict()
node_ids = dict()
counter_list=dict()
jobs = dict()

curl = pycurl.Curl()


def get_rest(base_url, url):
	if debug >= 3:
		print '# %s%s' % (base_url, url)

	b = BytesIO()
	curl.setopt(pycurl.URL, str(base_url + url))
	#curl.setopt(pycurl.WRITEDATA, b)
	curl.setopt(pycurl.WRITEFUNCTION, b.write)
	curl.perform()
	s = b.getvalue().decode('utf-8')

	if curl.getinfo(curl.RESPONSE_CODE) != 200:
		print s
		print 'Status: %d' % curl.getinfo(curl.RESPONSE_CODE)
		curl.close()
		b.close()
		raise Exception()

	j = json.loads(s)

	if debug >= 4:
		print json.dumps(j, indent=4)

	return j


def get_cluster_status(base_url):
	try:
		j = get_rest(base_url, '/ws/v1/cluster/info')
	except pycurl.error:
		if curl.getinfo(pycurl.OS_ERRNO) == errno.ECONNREFUSED:
			j = json.loads('{"clusterInfo":{"state":"NO CONNETION"}}')
		else:
			raise

	if not j['clusterInfo']:
		if debug >= 3:
			print 'Error with YARN RM'
		return None

	ci = j['clusterInfo']
	if not 'haState' in ci.keys():
		ci['haState'] = 'NONE'
	if debug >= 3:
		print '[YARN] state=%s, haState=%s' % (ci['state'], ci['haState'])
	if ci['state'] != 'STARTED':
		return None
	if ci['haState'] != 'ACTIVE':
		return None

	return j


def gen_url(base_url, port_nossl, port_ssl):
	if https:
		schema = 'https://'
		port = port_ssl
	else:
		schema = 'http://'
		port = port_nossl

	if not base_url:
		base_url = host
	if not '://' in base_url:
		base_url = schema + base_url
	if not re.match(r'.*:\d+$', base_url):
		base_url = base_url + ':%d' % port

	return base_url


try:
	opts, args = getopt.getopt(sys.argv[1:], 'hb:c:d:g:j:m:y:sq:', ['help', 'base=', 'config=', 'db', 'dbhost=', 'dbname=', 'dbuser=', 'dbpassword=', 'debug=', 'gss=', 'jobid=', 'mapred=', 'yarn=', 'ssl', 'query='])
except getopt.GetoptError:
	print 'Args error'
	sys.exit(2)
for opt, arg in opts:
	if opt in ('-h', '--help'):
		print "jobs.py [OPTIONS]\n\
OPTIONS are:\n\
  -h, --help ........ help message\n\
  -b, --base ........ default hostname for YARN ans MapReduce\n\
  -c, --config ...... config file\n\
  -d, --debug LEVEL . debug output (2=progress, 3=trace, 4=json dumps)\n\
  --db .............. enable database\n\
  --dbhost\n\
  --dbname\n\
  --dbuser\n\
  --dbpassword\n\
  -g, --gss=0/1 ..... enable SPNEGO (default: according to ssl)\n\
  -j, --jobid ....... single job query istead of list all\n\
  -m, --mapred URL .. MapReduce Job History server\n\
  -y, --yarn URL .... YARN Resource Manager\n\
  -s, --ssl ......... enable default HTTPS schema and ports\n\
  -q, --query ....... initial query parameter (only if -j is not used)"
		sys.exit(0)
	elif opt in ('-b', '--base'):
		host = arg
	elif opt in ('-c', '--config'):
		f = open(arg, 'r')
		for line in f:
			cfg=line.rstrip().split('=')
			if cfg[0] == 'base':
				host = cfg[1]
			elif cfg[0] == 'dbhost':
				dbhost = cfg[1]
			elif cfg[0] == 'db':
				db = 1
			elif cfg[0] == 'dbname':
				dbname = cfg[1]
			elif cfg[0] == 'dbuser':
				dbuser = cfg[1]
			elif cfg[0] == 'dbpassword':
				dbpassword = cfg[1]
			elif cfg[0] == 'debug':
				debug = int(cfg[1])
			elif cfg[0] == 'gss':
				gss = int(cfg[1])
			elif cfg[0] == 'mapred':
				base_mapred_url = cfg[1]
			elif cfg[0] == 'yarn':
				base_yarn_urls.append(cfg[1])
			elif cfg[0] == 'ssl':
				https = int(cfg[1])
	elif opt in ('-d', '--debug'):
		debug = int(arg)
	elif opt in ('--db'):
		db = 1
	elif opt in ('--dbhost'):
		dbhost = arg
	elif opt in ('--dbname'):
		dbname = arg
	elif opt in ('--dbuser'):
		dbuser = arg
	elif opt in ('--dbpassword'):
		dbpassword = arg
	elif opt in ('-g', '--gss'):
		gss = int(arg)
	elif opt in ('-j', '--jobid'):
		id = arg
	elif opt in ('-m', '--mapred'):
		base_mapred_url = arg
	elif opt in ('-y', '--yarn'):
		base_yarn_urls.append(arg)
	elif opt in ('-s', '--ssl'):
		https=1
	elif opt in ('-q', '--query'):
		query='?%s' % arg
	else:
		print 'Args error'
		sys.exit(2)

if gss is None:
	gss = https

if gss:
	if debug >= 2:
		print '[CURL] SPNEGO enabled'
	curl.setopt(pycurl.HTTPAUTH, pycurl.HTTPAUTH_GSSNEGOTIATE)
	curl.setopt(pycurl.USERPWD, ":")

for i in range(len(base_yarn_urls)):
	base_yarn_urls[i] = gen_url(base_yarn_urls[i], 8088, 8090)
	if debug >= 2:
		print '[YARN] URL %d: %s' % (i, base_yarn_urls[i])

for i in range(len(base_yarn_urls)):
	j = get_cluster_status(base_yarn_urls[i])
	if j:
		base_yarn_url = base_yarn_urls[i]
		break
if not base_yarn_url:
	print '[YARN] probem with RM'
	sys.exit(2)

base_mapred_url = gen_url(base_mapred_url, 19888, 19890)

if debug >= 2:
	print '[MR] URL: ' + base_mapred_url
	print '[YARN] URL: ' + base_yarn_url

regJob = re.compile('^job_')
regApp = re.compile('^application_')
regAtt = re.compile('^attempt_')
if id:
	if regJob.match(id): id = regJob.sub('', id)
	if regApp.match(id): id = regApp.sub('', id)

	mapred_url = base_mapred_url + '/ws/v1/history/mapreduce/jobs/job_%s' % id
	yarn_url = base_yarn_url + '/ws/v1/cluster/apps/application_%s' % id

	try:
		j1 = get_rest(mapred_url, '')
	except Exception:
		j1 = None

	try:
		j2 = get_rest(yarn_url, '')
	except Exception:
		j2 = None

	jcounter = 0
	if j1 and j1['job']:
		if id not in jobs:
			job  = Job()
			jobs[id] = job
		else:
			job = jobs[id]
		job.mapred = j1['job'];
		jcounter += 1
	if debug >= 2: print '[MR] %d jobs' % jcounter

	jcounter = 0
	if j2 and j2['app']:
		if id not in jobs:
			job  = Job()
			jobs[id] = job
		else:
			job = jobs[id]
		job.yarn = j2['app'];
		jcounter += 1
	if debug >= 2: print '[YARN] %d jobs' % jcounter
else:
	mapred_url = base_mapred_url + '/ws/v1/history/mapreduce/jobs' + query
	yarn_url = base_yarn_url + '/ws/v1/cluster/apps' + query

	j1 = get_rest(mapred_url, '')
	j2 = get_rest(yarn_url, '')

	jcounter = 0
	if j1["jobs"]:
		for j in j1["jobs"]["job"]:
			id = regJob.sub('', j['id'])
			if id not in jobs:
				job  = Job()
				jobs[id] = job
			else:
				job = jobs[id]
			job.mapred = j;
			jcounter += 1
	if debug >= 2: print '[MR] %d jobs' % jcounter

	jcounter = 0
	if j2["apps"]:
		for j in j2["apps"]["app"]:
			id = regApp.sub('', j['id'])
			if id not in jobs:
				job  = Job()
				jobs[id] = job
			else:
				job = jobs[id]
			job.yarn = j;
			jcounter += 1
	if debug >= 2: print '[YARN] %d jobs' % jcounter

if db:
	db = MySQLdb.connect(dbhost, dbuser, dbpassword, dbname)
	st = db.cursor()

	data = st.execute('SELECT id, host FROM nodes')
	while 1:
		data = st.fetchone()
		if data:
			node = Node()
			node.id = data[0]
			node.host = data[1]
			node_ids[node.id] = node
			node_hosts[node.host] = node
		else:
			break

	data = st.execute('SELECT id, groupName, name FROM counters')
	while 1:
		data = st.fetchone()
		if data:
			counter_name = '%s/%s' % (data[1], data[2])
			counter_list[counter_name] = data[0]
		else:
			break

regHost = re.compile(':\d+')
jcounter=0
for id, job in jobs.iteritems():

	jcounter += 1

	if job.mapred:
		job.name = job.mapred['name']
		job.status = job.mapred['state']
		job.user = job.mapred['user']
		job.queue = job.mapred['queue']
		job.start = job.mapred['startTime']
		job.finish = job.mapred['finishTime']

	if db:
		changed = 0
		changed_counters = 0
		ID=0
		NAME=1
		USER=2
		STATUS=3
		QUEUE=4
		SUBMIT=5
		START=6
		FINISH=7
		MEMORY=8
		CPU=9
		MAP=10
		REDUCE=11
		st.execute("SELECT id, name, user, status, queue, submit, start, finish, memory_seconds, cpu_seconds, map, reduce FROM jobs WHERE id=%s", id)
		data = st.fetchone()
		if data:
			if not job.name:
				job.name = data[NAME]
			if not job.status or job.status == 'UNDEFINED':
				job.status = data[STATUS]
			if not job.user:
				job.user = data[USER]
			if not job.queue:
				job.queue = data[QUEUE]
			if not job.start:
				job.start = data[START]
			if not job.finish:
				job.finish = data[FINISH]

	if job.yarn:
		if not job.name:
			job.name = job.yarn['name']
		if not job.status or job.status == 'UNDEFINED':
			job.status = job.yarn['state']
		if not job.user:
			job.user = job.yarn['user']
		if not job.queue:
			job.queue = job.yarn['queue']
		if not job.start:
			job.start = job.yarn['startedTime']
			if debug >= 2: print '[MR] missing start time of %s completed from YARN (%d)' % (id, job.start)
		if not job.finish:
			job.finish = job.yarn['finishedTime']
			if debug >= 2: print '[MR] missing finish time of %s completed from YARN (%d)' % (id, job.finish)

	if debug >= 1:
		print 'job %s (%d):' % (id, jcounter)
		print '  name: %s' % job.name
		print '  status: %s' % job.status
		print '  user: %s' % job.user
		print '  queue: %s' % job.queue

		if job.mapred:
			print '  submit: %d, start: %d, finish: %d' % (job.mapred['submitTime'], job.mapred['startTime'], job.mapred['finishTime'])
			print '  elapsed: %.3f s' % ((job.mapred['finishTime'] - job.mapred['startTime']) / 1000.0)
			print '  finished: %.3f s' % ((job.mapred['finishTime'] - job.mapred['submitTime']) / 1000.0)

		if job.yarn and 'memorySeconds' in job.yarn.keys():
			print '  MB x s: %d' % job.yarn['memorySeconds']
			print '  CPU x s: %d' % job.yarn['vcoreSeconds']

	if db:
		if data:
			if data[NAME] == job.name and data[USER] == job.user and data[STATUS] == job.status and data[QUEUE] == job.queue and data[START] == job.start and data[FINISH] == job.finish:
				if debug >= 3: print '[db] job %s found' % id
			else:
				st.execute("UPDATE jobs SET name=%s, user=%s, status=%s, queue=%s, start=%s, finish=%s WHERE id=%s", (job.name, job.user, job.status, job.queue, job.start, job.finish, id))
				if debug >= 3: print '[db] job %s updated' % id
				changed = 1
		else:
			st.execute("INSERT INTO jobs (id, name, user, status, queue, start, finish) VALUES(%s, %s, %s, %s, %s, %s, %s)", (id, job.name, job.user, job.status, job.queue, job.start, job.finish))
			if debug >= 3: print '[db] job %s inserted' % id
			changed = 1
		if job.mapred:
			if data and data[SUBMIT] == job.mapred['submitTime'] and data[MAP] == job.mapred['mapsTotal'] and data[REDUCE] == job.mapred['reducesTotal']:
				if debug >= 3: print '[db] job %s mapred is actual' % id
			else:
				st.execute("UPDATE jobs SET submit=%s, map=%s, reduce=%s WHERE id=%s", (job.mapred['submitTime'], job.mapred['mapsTotal'], job.mapred['reducesTotal'], id))
				if debug >= 3: print '[db] job %s mapred updated' % id
				changed = 1
		if job.yarn and 'memorySeconds' in job.yarn.keys():
			if data and data[MEMORY] == job.yarn['memorySeconds'] and data[CPU] == job.yarn['vcoreSeconds']:
				if debug >= 3: print '[db] job %s yarn is actual' % id
			else:
				st.execute("UPDATE jobs SET memory_seconds=%s, cpu_seconds=%s WHERE id=%s", (job.yarn['memorySeconds'], job.yarn['vcoreSeconds'], id))
				if debug >= 3: print '[db] job %s yarn updated' % id
				changed = 1

		# check for details in DB, set changed flag if missing
		st.execute('SELECT * FROM jobnodes WHERE jobid=%s', id)
		data = st.fetchone()
		if data:
			st.execute('SELECT * FROM subjobs WHERE jobid=%s', id)
			data = st.fetchone()
		if not data:
			changed = 1

		st.execute('SELECT * FROM jobcounters WHERE jobid=%s', id)
		data = st.fetchone()
		if not data:
			changed_counters = 1

	# get details (intensive!), if new job or any other difference
	jobnodes = dict()
	subjobs = list()
	if job.mapred and (not db or changed):
		t = get_rest(base_mapred_url, '/ws/v1/history/mapreduce/jobs/job_%s/tasks' % id)
		if t['tasks']:
			aggregate=0
			for task in t['tasks']['task']:
#				print 'taskid: %s, elapsed: %d' % (task['id'], task['elapsedTime'])
				aggregate += task['elapsedTime']
				a = get_rest(base_mapred_url, '/ws/v1/history/mapreduce/jobs/job_%s/tasks/%s/attempts' % (id, task['id']))
				if a['taskAttempts']:
					for attempt in a['taskAttempts']['taskAttempt']:
						if regAtt.match(attempt['id']): attempt['id'] = regAtt.sub('', attempt['id'])

						nodeHost = regHost.sub('', attempt['nodeHttpAddress'])
						attempt['nodeHttpAddress'] = nodeHost
						if nodeHost not in jobnodes:
							jobnodes[nodeHost] = JobNode()
						jobnodes[nodeHost].elapsed += attempt['elapsedTime']
						if attempt['type'] == 'MAP':
							jobnodes[nodeHost].map += 1
						elif attempt['type'] == 'REDUCE':
							jobnodes[nodeHost].reduce += 1
						else:
							raise Exception('unknown type %s' %  attempt['type'])
#			print 'tasks elapsed: %d' % aggregate
					subjobs.append(attempt)

		aggregate=0
		for nodename, jobnode in jobnodes.iteritems():
			if debug >= 1: print '  node %s: %d' % (nodename, jobnode.elapsed)
			aggregate += jobnode.elapsed
		if debug >= 1:
			print '  subjobs: %d' % len(subjobs)
			print '  ==> aggregated %d' % aggregate

	counters = list()
	counters_print = list()
	if job.mapred and (not db or changed_counters or changed):
		cs = get_rest(base_mapred_url, '/ws/v1/history/mapreduce/jobs/job_%s/counters' % id)
		if cs and 'jobCounters' in cs.keys():
			if 'counterGroup' in cs['jobCounters'].keys():
				for cg in cs['jobCounters']['counterGroup']:
					for c in cg['counter']:
						counter = Counter()
						counter.group = cg['counterGroupName']
						counter.counter = c
						counters.append(counter)
						counters_print.append('(%s=%d,%d,%d)' % (c['name'], c['reduceCounterValue'], c['mapCounterValue'], c['totalCounterValue']))
		if counters_print and debug >= 1:
			print '  counters: ' + ''.join(counters_print)

	if jobnodes and db:
		st.execute("DELETE FROM jobnodes WHERE jobid=%s", id)
		for nodename, jobnode in jobnodes.iteritems():
			if not nodename in node_hosts.keys():
				st.execute('INSERT INTO nodes (host) VALUES (%s)', nodename)
				node = Node()
				node.id = db.insert_id()
				node.host = nodename
				node_hosts[nodename] = node
				node_ids[node.id] = node
			st.execute("INSERT INTO jobnodes (jobid, nodeid, elapsed, map, reduce) VALUES (%s, %s, %s, %s, %s)", (id, node_hosts[nodename].id, jobnode.elapsed, jobnode.map, jobnode.reduce))
		if debug >= 3: print '[db] job %s nodes updated' % id

		st.execute("DELETE FROM subjobs WHERE jobid=%s", id)
		for subjob in subjobs:
			nodename = subjob['nodeHttpAddress']
			st.execute('INSERT INTO subjobs (id, jobid, nodeid, state, type, start, finish) VALUES (%s, %s, %s, %s, %s, %s, %s)', (subjob['id'], id, node_hosts[nodename].id, subjob['state'], subjob['type'], subjob['startTime'], subjob['finishTime']))
		if debug >= 3: print '[db] job %s subjobs updated' % id

	if counters and db:
		st.execute('DELETE FROM jobcounters WHERE jobid=%s', id)
		for counter in counters:
			counter_name = '%s/%s' % (counter.group, counter.counter['name'])
			if not counter_name in counter_list.keys():
				st.execute('INSERT INTO counters (groupName, name) VALUES (%s, %s)', (counter.group, counter.counter['name']))
				counter_list[counter_name] = db.insert_id()
				if debug >= 3: print '[db] new counter %s inserted' % counter_name
			st.execute('INSERT INTO jobcounters (jobid, counterid, reduce, map, total) VALUES (%s, %s, %s, %s, %s)', (id, counter_list[counter_name], counter.counter['reduceCounterValue'], counter.counter['mapCounterValue'], counter.counter['totalCounterValue']))
		if debug >= 3: print '[db] job %s counters updated' % id

	# better to update timestamp again explicitly on the end of the transaction
	if db and (jobnodes or counters):
		st.execute('UPDATE jobs SET changed=NOW() WHERE id=%s', id);


	if db:
		db.commit()

	if debug >= 1: print

if db:
	db.close()

curl.close()
