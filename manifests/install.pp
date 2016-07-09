# == Class site_hadoop::install
#
# Installation of packages required by Hadoop.
#
class site_hadoop::install {
  include ::stdlib

  if $site_hadoop::packages {
    ensure_packages($site_hadoop::packages)
  }
}
