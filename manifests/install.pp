class site_hadoop::install {
  include stdlib

  ensure_packages($site_hadoop::packages)

  if $site_hadoop::java_packages {
    ensure_packages($site_hadoop::java_packages)
  }
}
