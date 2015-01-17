#
# Parsing output of:
#
# hdfs dfs -du -s '/user/*'
#

function dbstr(s) {
	if (s) { return "'" s "'" }
	else { return "NULL" }
}

function dbi(i) {
	if (i >= 0) { return i }
	else { return "NULL" }
}

BEGIN {
	FS="[ \t/]+"
	print "INSERT INTO measure (name) VALUES ('quota');";
}

{
	used=$1
	user=$4
	print "INSERT INTO quota (id_measure, user, used) VALUES (last_insert_id(), " dbstr(user) ", " dbi(used) ");"
}
