provider "aws" {
  region = var.region
}

provider "cato" {
  baseurl    = var.baseurl
  token      = var.token
  account_id = var.account_id
}

resource "cato_socket_site" "aws-site" {
  connection_type = var.connection_type
  description     = var.site_description
  name            = var.site_name
  native_range = {
    native_network_range = var.native_network_range
    local_ip             = var.lan_local_ip
  }
  site_location = var.site_location
  site_type     = var.site_type
}

data "cato_accountSnapshotSite" "aws-site" {
  id = cato_socket_site.aws-site.id
}

# AWS HA IAM role configuration
resource "aws_iam_role" "cato_ha_role" {
  name        = "${var.site_name}-Cato-HA-Role"
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
  name = "${var.site_name}-Cato-HA-Role-Policy"
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
  name = "${var.site_name}-Cato-HA-Role"
  role = aws_iam_role.cato_ha_role.name
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.site_name}-Internet-Gateway"
  }
}


## Lookup data from region and VPC
data "aws_ami" "vsocket" {
  most_recent = true
  name_regex  = "VSOCKET_AWS"
  owners      = ["aws-marketplace"]
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Create Primary vSocket Virtual Machine
resource "aws_instance" "primary_vsocket" {
  tenancy              = "default"
  ami                  = data.aws_ami.vsocket.id
  key_name             = var.key_pair
  instance_type        = var.instance_type
  user_data            = base64encode(local.primary_serial[0])
  iam_instance_profile = aws_iam_instance_profile.cato_ha_instance_profile.name
  # Network Interfaces
  # MGMTENI
  network_interface {
    device_index         = 0
    network_interface_id = var.mgmt_eni_id
  }
  # WANENI
  network_interface {
    device_index         = 1
    network_interface_id = var.wan_eni_id
  }
  # LANENI
  network_interface {
    device_index         = 2
    network_interface_id = var.lan_eni_id
  }
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = var.ebs_disk_size
    volume_type = var.ebs_disk_type
  }
  tags = merge(var.tags, {
    Name = "${var.site_name}-vSocket-Primary"
  })
  depends_on = [aws_route_table_association.lan_secondary_subnet_association]
}

resource "aws_eip" "mgmt_eip" {
  domain            = "vpc"
}

resource "aws_eip" "wan_eip" {
  domain            = "vpc"
}

# Elastic IP Addresses Association - Required to properly destroy 
resource "aws_eip_association" "primary_mgmt_eip_assoc" {
  network_interface_id = var.mgmt_eni_id
  allocation_id        = aws_eip.wan_eip.id
}

resource "aws_eip_association" "primary_wan_eip_assoc" {
  network_interface_id = var.wan_eni_id
  allocation_id        = aws_eip.mgmt_eip.id
}

# Route tables for MGMT, WAN and both LAN subnets
resource "aws_route_table" "route_table" {
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table" "route_table_lan" {
  vpc_id = var.vpc_id
  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = var.lan_eni_id
  }
}

# Route table associations
resource "aws_route_table_association" "wan_subnet_association" {
  subnet_id      = var.wan_subnet_id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "mgmt_subnet_association" {
  subnet_id      = var.mgmt_subnet_id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "lan_subnet_association" {
  subnet_id      = var.lan_subnet_id
  route_table_id = aws_route_table.route_table_lan.id
}

resource "aws_route_table_association" "lan_secondary_subnet_association" {
  subnet_id      = var.lan_secondary_subnet_id
  route_table_id = aws_route_table.route_table_lan.id
}

# To allow socket to upgrade so secondary socket can be added
resource "null_resource" "sleep_300_seconds" {
  provisioner "local-exec" {
    command = "sleep 300"
  }
  depends_on = [ aws_instance.primary_vsocket ]
}

#################################################################################
# Add secondary socket to site via API until socket_site resource is updated to natively support
resource "null_resource" "configure_secondary_aws_vsocket" {
  depends_on = [null_resource.sleep_300_seconds]

  provisioner "local-exec" {
    command = <<EOF
      # Execute the GraphQL mutation to get the site id
      response=$(curl -k -X POST \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -H "x-API-Key: ${var.token}" \
        "${var.baseurl}" \
        --data '{
          "query": "mutation siteAddSecondaryAwsVSocket($accountId: ID!, $addSecondaryAwsVSocketInput: AddSecondaryAwsVSocketInput!) { site(accountId: $accountId) { addSecondaryAwsVSocket(input: $addSecondaryAwsVSocketInput) { id } } }",
          "variables": {
            "accountId": "${var.account_id}",
            "addSecondaryAwsVSocketInput": {
              "eniIpAddress": "${var.lan_secondary_local_ip}",
              "eniIpSubnet": "${var.secondary_native_network_range}",
               "routeTableId": "${aws_route_table.route_table_lan.id}",
              "site": {
                "by": "ID",
                "input": "${cato_socket_site.aws-site.id}"
              }
            }
          },
          "operationName": "siteAddSecondaryAwsVSocket"
        }' )
    EOF
  }

  triggers = {
    account_id = var.account_id
    site_id    = cato_socket_site.aws-site.id
  }
}


# Retrieve Secondary vSocket Virtual Machine serial
data "cato_accountSnapshotSite" "aws-site-secondary" {
  depends_on = [ null_resource.configure_secondary_aws_vsocket ]
  id = cato_socket_site.aws-site.id
}

locals {
  primary_serial = [for s in data.cato_accountSnapshotSite.aws-site.info.sockets : s.serial if s.is_primary == true]
}

# Sleep to allow Secondary vSocket serial retrieval
resource "null_resource" "sleep_10_seconds" {
  provisioner "local-exec" {
    command = "sleep 10"
  }
  depends_on = [ data.cato_accountSnapshotSite.aws-site-secondary ]
}

locals {
  secondary_serial = [for s in data.cato_accountSnapshotSite.aws-site-secondary.info.sockets : s.serial if s.is_primary == false]
  depends_on = [null_resource.configure_secondary_aws_vsocket]
}

## vSocket Instance
resource "aws_instance" "vSocket_Secondary" {
  tenancy              = "default"
  ami                  = data.aws_ami.vsocket.id
  key_name             = var.key_pair
  instance_type        = var.instance_type
  user_data            = base64encode(local.secondary_serial[0])
  iam_instance_profile = aws_iam_instance_profile.cato_ha_instance_profile.name
  # Network Interfaces
  # MGMTENI
  network_interface {
    device_index         = 0
    network_interface_id = var.secondary_mgmt_eni_id
  }
  # WANENI
  network_interface {
    device_index         = 1
    network_interface_id = var.secondary_wan_eni_id
  }
  # LANENI
  network_interface {
    device_index         = 2
    network_interface_id = var.secondary_lan_eni_id
  }
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = var.ebs_disk_size
    volume_type = var.ebs_disk_type
  }
  tags = merge(var.tags, {
    Name = "${var.site_name}-vSocket-Secondary"
  })
  depends_on = [null_resource.sleep_10_seconds]
}

resource "aws_eip" "secondary_mgmt_eip" {
  domain            = "vpc"
}

resource "aws_eip" "secondary_wan_eip" {
  domain            = "vpc"
}

# Elastic IP Addresses Association - Required to properly destroy 
resource "aws_eip_association" "secondary_mgmt_eip_assoc" {
  network_interface_id = var.secondary_mgmt_eni_id
  allocation_id        = aws_eip.secondary_wan_eip.id
}

resource "aws_eip_association" "secondary_wan_eip_assoc" {
  network_interface_id = var.secondary_wan_eni_id
  allocation_id        = aws_eip.secondary_mgmt_eip.id
}
