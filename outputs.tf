output "socket_site_id" {
  description = "The ID of the Cato Socket Site created."
  value       = cato_socket_site.aws-site.id
}
output "socket_site_serial" {
  description = "The serial number of the primary Cato vSocket."
  value       = local.primary_serial[0]
}
output "secondary_socket_site_serial" {
  description = "The serial number of the secondary Cato vSocket."
  value       = data.cato_accountSnapshotSite.aws-site-secondary.info.sockets[1].serial
}
output "aws_iam_role_name" {
  description = "The name of the IAM role created for the vSocket HA."
  value       = aws_iam_role.cato_ha_role.name
}
output "aws_iam_policy_arn" {
  description = "The ARN of the IAM policy created for the vSocket HA."
  value       = aws_iam_policy.cato_ha_policy.arn
}
output "aws_iam_instance_profile_name" {
  description = "The name of the IAM instance profile created for the vSocket HA."
  value       = aws_iam_instance_profile.cato_ha_instance_profile.name
}
output "aws_availability_zones" {
  description = "A list of available AWS availability zones in the region."
  value       = data.aws_availability_zones.available.names
}
output "aws_instance_primary_vsocket_id" {
  description = "The ID of the primary vSocket EC2 instance."
  value       = aws_instance.primary_vsocket.id
}
output "aws_instance_secondary_vsocket_id" {
  description = "The ID of the secondary vSocket EC2 instance."
  value       = aws_instance.secondary_vsocket.id
}
output "cato_license_site" {
  description = "The details of the license applied to the site, if any."
  value = var.license_id == null ? null : {
    id           = cato_license.license[0].id
    license_id   = cato_license.license[0].license_id
    license_info = cato_license.license[0].license_info
    site_id      = cato_license.license[0].site_id
  }
}