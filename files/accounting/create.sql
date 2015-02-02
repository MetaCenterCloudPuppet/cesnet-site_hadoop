--
-- Accounting for Hadoop
--
-- How to add values:
--
-- INSERT INTO measure (name) VALUES ('quota');
-- INSERT INTO quota (id_measure, user, used) VALUES (last_insert_id(), 'valtri', 17);
-- INSERT INTO quota (id_measure, user, used) VALUES (last_insert_id(), 'nemo', 1);
--
-- INSERT INTO hdfs (full, disk, disk_used) VALUES (1024, 1023, 10);
-- or:
-- INSERT INTO measure (name) VALUES ('hdfs');
-- INSERT INTO hdfs (id_measure, full, disk, disk_used, block_under, block_corrupt, block_missing) VALUES (last_insert_id(), 10240, 10230, 100, 0, 0, 0);
-- INSERT INTO hdfs (id_measure, hostname, state, full, disk, disk_used) VALUES (last_insert_id(), 'hador1', 1, 1024, 1023, 10);
--
-- INSERT INTO measure (name, start, end) VALUES ('jobs', '2015-01-16', '2015-01-17');
-- INSERT INTO jobs (id_measure, user, jobs, fails, subjobs, real_wait, real_time, wait_min, wait_max) VALUES (last_insert_id(), 'valtri', 6, 10, 2, 1000, 500, 10, 100);
-- INSERT INTO jobs (id_measure, user, jobs, fails, subjobs, wait_min, wait_max) VALUES (last_insert_id(), 'nemo', 0, 0, 0, NULL, NULL);
--
-- How to read values:
--
-- a) all history
--
-- SELECT * FROM view_hdfs;
-- SELECT * FROM view_quotas;
--
-- b) current values
--
-- SELECT h.* FROM view_hdfs h, statistic s WHERE h.seq=s.last_seq;
-- SELECT h.* FROM view_hdfs h, statistic s WHERE h.seq=s.last_seq;
--

CREATE TABLE statistic (
	name CHAR(8) NOT NULL,
	last_id_measure INTEGER,
	last_seq INTEGER,

	INDEX (last_id_measure),
	INDEX (last_seq)
);

CREATE TABLE measure (
	id_measure INTEGER AUTO_INCREMENT PRIMARY KEY,
	name CHAR(8) NOT NULL,
	seq INTEGER NOT NULL,
	time TIMESTAMP DEFAULT NOW(),
	start TIMESTAMP NULL DEFAULT NULL,
	end TIMESTAMP NULL DEFAULT NULL,

	INDEX (id_measure),
	INDEX (name),
	INDEX (seq)
);

CREATE TABLE hdfs (
	id_measure INTEGER NOT NULL,
	hostname CHAR(50),
	state INTEGER,
	full BIGINT,
	disk BIGINT,
	disk_used BIGINT,
	disk_free BIGINT,
	block_under INTEGER,
	block_corrupt INTEGER,
	block_missing INTEGER,

	CONSTRAINT PRIMARY KEY (id_measure, hostname),
	INDEX(id_measure),
	INDEX(hostname)
);

CREATE TABLE quota (
	id_measure INTEGER NOT NULL,
	user CHAR(20) NOT NULL,
	used BIGINT,

	CONSTRAINT PRIMARY KEY (id_measure, user),
	INDEX(id_measure),
	INDEX(user)
);

CREATE TABLE jobs (
	id_measure INTEGER NOT NULL,
	user CHAR(20) NULL,
	jobs INTEGER,
	fails INTEGER,
	subjobs INTEGER,
	real_wait INTEGER,
	real_time INTEGER,
	wait_min INTEGER,
	wait_max INTEGER,

	CONSTRAINT PRIMARY KEY (id_measure, user),
	INDEX(id_measure),
	INDEX(user)
);

INSERT INTO statistic (name, last_seq) VALUES ('hdfs', 0);
INSERT INTO statistic (name, last_seq) VALUES ('quota', 0);
INSERT INTO statistic (name, last_seq) VALUES ('jobs', 0);

DELIMITER //

CREATE TRIGGER bi_measure BEFORE INSERT ON measure
FOR EACH ROW BEGIN
  SET NEW.seq=(SELECT last_seq+1 FROM statistic s WHERE NEW.name=s.name);
END; //

CREATE TRIGGER ai_measure AFTER INSERT ON measure
FOR EACH ROW BEGIN
  UPDATE statistic s SET s.last_seq=s.last_seq+1, s.last_id_measure=NEW.id_measure WHERE s.name=NEW.name;
END; //

-- not needed, id_measure should be always specified
CREATE TRIGGER ai_hdfs BEFORE INSERT ON hdfs
FOR EACH ROW BEGIN
  IF NEW.id_measure IS NULL OR NEW.id_measure=0 THEN
    INSERT INTO measure (name) VALUES ('hdfs');
    SET NEW.id_measure=last_insert_id();
  END IF;
END; //

DELIMITER ;

CREATE VIEW view_measures AS SELECT m.* FROM measure m, statistic s WHERE s.last_id_measure = m.id_measure;
CREATE VIEW view_hdfs AS SELECT m.seq, m.time, h.hostname, h.full, h.disk, h.disk_used, h.disk_free, h.block_under, h.block_corrupt, h.block_missing FROM hdfs h, measure m WHERE h.id_measure=m.id_measure;
CREATE VIEW view_quota AS SELECT m.seq, m.time, q.user, q.used FROM quota q, measure m WHERE q.id_measure=m.id_measure;
CREATE VIEW view_jobs AS SELECT m.seq, m.time, m.start, m.end, j.user, j.jobs, j.fails, j.subjobs, j.real_wait, j.real_time, j.wait_min, j.wait_max FROM jobs j, measure m WHERE j.id_measure=m.id_measure;
