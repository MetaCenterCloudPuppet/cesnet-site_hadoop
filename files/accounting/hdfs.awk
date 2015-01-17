#
# Parsing output of:
#
# hdfs dfsadmin -report
#

function dbstr(s) {
	if (s) { return "'" s "'" }
	else { return "NULL" }
}

function dbi(i) {
	if (i >= 0) { return i }
	else { return "NULL" }
}

function reset() {
	name="(none)";
	full=-1;
	disk=-1;
	disk_free=-1;
	disk_used=-1;
	block_under=-1;
	block_corrupt=-1;
	block_missing=-1;
#	cache=-1;
#	cache_used=-1;
#	cache_free=-1;
}

BEGIN {
	reset();
	name="all";
	state=-1;

	FS="[: ]+";
	CONVFMT="%d";

	print "INSERT INTO measure (name) VALUES ('hdfs');";
}

/^Live datanodes.*/		{state=1}
/^Dead datanodes.*/		{state=2}
/^Decommissioned .*/		{state=3}

/^Hostname:.*/			{name=$2}
/^Name:.*/			{ip=$2}
/^Configured Capacity:.*/	{full=$3}
/^Present Capacity:.*/		{disk=$3}
/^DFS Remaining:.*/		{disk_free=$3}
/^DFS Used:.*/			{disk_used=$3}
/^Under replicated blocks:.*/	{block_under=$4}
/^Blocks with corrupt replicas:.*/	{block_corrupt=$5}
/^Missing blocks:.*/		{block_missing=$3}
#/^Configured Cache Capacity:.*/{cache=$4}
#/^Cache Used:.*/		{cache_used=$3}
#/^Cache Remaining:.*/		{cache_free=$3}

/^$/ {
	if (name != "(none)" && ip !~ /^10\./) {
		print "INSERT INTO hdfs (id_measure, hostname, state, full, disk, disk_free, disk_used, block_under, block_corrupt, block_missing) VALUES (last_insert_id(), " dbstr(name) ", " dbi(state) ", " dbi(full) ", IFNULL(" dbi(disk) ", " dbi(disk_free) " + " dbi(disk_used) "), " dbi(disk_free) ", " dbi(disk_used) ", " dbi(block_under) ", " dbi(block_corrupt) ", " dbi(block_missing) ");";
	}
	reset()
}
