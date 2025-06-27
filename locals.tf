locals {
  primary_serial = [for s in data.cato_accountSnapshotSite.aws-site-primary.info.sockets : s.serial if s.is_primary == true]
  sanitized_name = replace(replace(replace(replace(replace(replace(
    var.site_name,
    "/", ""),
    ":", ""),
    "#", ""),
    "(", ""),
    ")", ""),
  " ", "-")

  secondary_serial = [for s in data.cato_accountSnapshotSite.aws-site-secondary.info.sockets : s.serial if s.is_primary == false]
}