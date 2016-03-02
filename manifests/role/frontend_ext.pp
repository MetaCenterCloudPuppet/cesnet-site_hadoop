# = Class site_hadoop::role::frontend_ext
#
# Hadoop External Frontend.
#
# Like full frontend, without NFS daemon and mounts.
#
# services:
# * Hadoop Frontend + basic packages
# * HBase Frontend (optional)
# * Hive Frontend (optional)
# * Pig Frontend (optional)
# * Spark Frontend (optional)
#
class site_hadoop::role::frontend_ext {
  include ::site_hadoop::role::common::frontend
}
