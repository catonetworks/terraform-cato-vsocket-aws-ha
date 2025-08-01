resource "cato_socket_site" "aws-site" {
  connection_type = var.connection_type
  description     = var.site_description
  name            = var.site_name
  native_range = {
    native_network_range = var.native_network_range_primary
    local_ip             = var.lan_local_primary_ip
  }
  site_location = local.cur_site_location
  site_type     = var.site_type
}

# AWS HA IAM role configuration
resource "aws_iam_role" "cato_ha_role" {
  name        = "Cato-HA-Role-${local.sanitized_name}"
  description = "To allow vSocket HA route management"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "cato_ha_policy" {
  name = "Cato-HA-Role-Policy-${local.sanitized_name}"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateRoute",
          "ec2:DescribeRouteTables",
          "ec2:ReplaceRoute"
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cato_ha_attach" {
  role       = aws_iam_role.cato_ha_role.name
  policy_arn = aws_iam_policy.cato_ha_policy.arn
}

resource "aws_iam_instance_profile" "cato_ha_instance_profile" {
  name = "Cato-HA-Role-${local.sanitized_name}"
  role = aws_iam_role.cato_ha_role.name
}

# Create Primary vSocket Virtual Machine
resource "aws_instance" "primary_vsocket" {
  tenancy              = "default"
  ami                  = data.aws_ami.vsocket.id
  key_name             = var.key_pair
  instance_type        = var.instance_type
  user_data_base64     = base64encode(local.primary_serial[0])
  iam_instance_profile = aws_iam_instance_profile.cato_ha_instance_profile.name
  # Network Interfaces
  # MGMTENI
  network_interface {
    device_index         = 0
    network_interface_id = var.mgmt_eni_primary_id
  }
  # WANENI
  network_interface {
    device_index         = 1
    network_interface_id = var.wan_eni_primary_id
  }
  # LANENI
  network_interface {
    device_index         = 2
    network_interface_id = var.lan_eni_primary_id
  }
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = var.ebs_disk_size
    volume_type = var.ebs_disk_type
  }
  tags = merge(var.tags, {
    Name = "${var.site_name}-vSocket-Primary"
  })
}

# To allow socket to upgrade so secondary socket can be added
resource "null_resource" "sleep_300_seconds" {
  provisioner "local-exec" {
    command = "sleep 300"
  }
  depends_on = [aws_instance.primary_vsocket]
}

#################################################################################
# Add secondary socket to site via API until socket_site resource is updated to natively support
resource "terraform_data" "configure_secondary_aws_vsocket" {
  depends_on = [null_resource.sleep_300_seconds]

  # The `input` block serves as the trigger for this resource.
  # If any of these values change, Terraform will replace the resource,
  # causing the provisioner to run again. This is the modern replacement
  # for the `triggers` argument in null_resource.
  input = {
    account_id     = var.account_id
    site_id        = cato_socket_site.aws-site.id
    eni_ip_address = var.lan_local_secondary_ip
    eni_ip_subnet  = var.native_network_range_secondary
    route_table_id = var.lan_route_table_id
  }

  provisioner "local-exec" {
    # The command is now cleaner. It calls the curl command and uses the
    # templatefile() function to dynamically generate the JSON payload from
    # an external template file. This avoids the large, hard-to-read heredoc.
    command = templatefile("${path.module}/templates/secondary_socket_payload.json.tftpl", {
      account_id     = self.input.account_id,
      site_id        = self.input.site_id,
      eni_ip_address = self.input.eni_ip_address,
      eni_ip_subnet  = self.input.eni_ip_subnet,
      route_table_id = self.input.route_table_id
      api_token      = var.token
      baseurl        = var.baseurl
    })
  }
}

# Sleep to allow Secondary vSocket serial retrieval
resource "null_resource" "sleep_30_seconds" {
  provisioner "local-exec" {
    command = "sleep 30"
  }
  depends_on = [terraform_data.configure_secondary_aws_vsocket]
}

## vSocket Instance
resource "aws_instance" "secondary_vsocket" {
  tenancy              = "default"
  ami                  = data.aws_ami.vsocket.id
  key_name             = var.key_pair
  instance_type        = var.instance_type
  user_data_base64     = base64encode(local.secondary_serial[0])
  iam_instance_profile = aws_iam_instance_profile.cato_ha_instance_profile.name
  # Network Interfaces
  # MGMTENI
  network_interface {
    device_index         = 0
    network_interface_id = var.mgmt_eni_secondary_id
  }
  # WANENI
  network_interface {
    device_index         = 1
    network_interface_id = var.wan_eni_secondary_id
  }
  # LANENI
  network_interface {
    device_index         = 2
    network_interface_id = var.lan_eni_secondary_id
  }
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = var.ebs_disk_size
    volume_type = var.ebs_disk_type
  }
  tags = merge(var.tags, {
    Name = "${var.site_name}-vSocket-Secondary"
  })
  depends_on = [null_resource.sleep_30_seconds]
}

# To allow sockets to configure HA
resource "null_resource" "sleep_300_seconds-HA" {
  provisioner "local-exec" {
    command = "sleep 300"
  }
  depends_on = [aws_instance.secondary_vsocket]
}

resource "cato_license" "license" {
  depends_on = [aws_instance.secondary_vsocket]
  count      = var.license_id == null ? 0 : 1
  site_id    = cato_socket_site.aws-site.id
  license_id = var.license_id
  bw         = var.license_bw == null ? null : var.license_bw
}

resource "cato_network_range" "routedNetworks" {
  for_each        = var.routed_networks
  site_id         = cato_socket_site.aws-site.id
  name            = each.key # The name is the key from the map item.
  range_type      = "Routed"
  subnet          = each.value.subnet # The subnet is the value from the map item.
  interface_index = each.value.interface_index
  depends_on      = [data.cato_accountSnapshotSite.aws-site-2]
}