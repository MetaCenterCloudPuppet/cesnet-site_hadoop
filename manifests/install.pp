# == Class site_hadoop::install
#
# Installation of packages required by site\_hadoop module (helper admin packages, Java for Hadoop, ...).
#
class site_hadoop::install {
  include stdlib

  if $site_hadoop::packages {
    ensure_packages($site_hadoop::packages)
  }
}
