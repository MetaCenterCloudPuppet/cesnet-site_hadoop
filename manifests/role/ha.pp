# = Class site_hadoop::role::ha
#
# Hadoop HA quorum server
#
# There should be at least 3 servers.
#
# services:
# * HDFS Journalnode
# * Zookeeper server
#
class site_hadoop::role::ha {
  include ::site_hadoop::role::common
  include ::hadoop::journalnode
  include ::zookeeper
}
