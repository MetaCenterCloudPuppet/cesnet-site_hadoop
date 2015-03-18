CREATE TABLE jobs (
	id CHAR(80) PRIMARY KEY,
	name CHAR(128),
	user CHAR(20),
	status CHAR(20),
	queue CHAR(80),
	submit BIGINT,
	start BIGINT,
	finish BIGINT,

	memory_seconds BIGINT,
	cpu_seconds INTEGER,
	map INTEGER,
	reduce INTEGER,

	changed TIMESTAMP,

	INDEX (user)
);


CREATE TABLE subjobs (
	id CHAR(80) PRIMARY KEY,
	jobid CHAR(80),
	nodeid INTEGER,
	state CHAR(20),
	type CHAR(20),
	start BIGINT,
	finish BIGINT,

	INDEX(id),
	INDEX(jobid),
	INDEX(start),
	INDEX(finish)
);


CREATE TABLE jobnodes (
	jobid CHAR(80) NOT NULL,
	nodeid INTEGER,
	elapsed INTEGER,
	map INTEGER,
	reduce INTEGER,

	INDEX (jobid)
);


CREATE TABLE jobcounters (
	jobid CHAR(80) NOT NULL,
	counterid INTEGER,

	reduce BIGINT,
	map BIGINT,
	total BIGINT,

	INDEX(jobid),
	INDEX(counterid)
);


CREATE TABLE counters (
	id INTEGER PRIMARY KEY AUTO_INCREMENT,
	groupName CHAR(128),
	name CHAR(128)
);


CREATE TABLE nodes (
	id INTEGER PRIMARY KEY AUTO_INCREMENT,
	host VARCHAR(256),

	INDEX(host)
);

DELIMITER //

CREATE TRIGGER bi_measure BEFORE INSERT ON jobs
FOR EACH ROW BEGIN
  SET NEW.changed = NOW();
END; //

CREATE TRIGGER bu_measure BEFORE UPDATE ON jobs
FOR EACH ROW BEGIN
  SET NEW.changed = NOW();
END; //

DELIMITER ;
