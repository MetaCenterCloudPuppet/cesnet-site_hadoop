class site_hadoop::kdc::install {
  if $site_hadoop::kdc::kdc_packages {
    ensure_packages($site_hadoop::kdc::kdc_packages)
  }
}
