# The following attributes are exported:
output "socket_site_id" { value = cato_socket_site.aws-site.id }
output "socket_site_serial" { value = local.primary_serial[0] }
output "secondary_socket_site_serial" { value = data.cato_accountSnapshotSite.aws-site-secondary.info.sockets[1].serial }
output "aws_iam_role_name" { value = aws_iam_role.cato_ha_role.name }
output "aws_iam_policy_arn" { value = aws_iam_policy.cato_ha_policy.arn }
output "aws_iam_instance_profile_name" { value = aws_iam_instance_profile.cato_ha_instance_profile.name }
output "aws_availability_zones" { value = data.aws_availability_zones.available.names }
output "aws_instance_id" { value = aws_instance.primary_vsocket.id }
output "cato_account_snapshot_site_secondary_id" { value = data.cato_accountSnapshotSite.aws-site-secondary.id }
output "aws_instance_vSocket_Secondary_id" { value = aws_instance.vSocket_Secondary.id }
