# terraform-cato-vsocket-aws-ha

Terraform module which an Aws Socket HA Site in the Cato Management Application (CMA), and deploys a primary and secondary virtual socket EC2 instance in Aws and configures them as HA.

## Usage

```hcl
module "vsocket-aws-ha" {
  source                         = "catonetworks/vsocket-aws-ha/cato"
  token                          = "xxxxxxx"
  account_id                     = "xxxxxxx"
  vpc_id                         = "vpc-12345abcde6789fg"
  key_pair                       = "Your key pair"
  native_network_range           = "172.19.102.0/24"
  secondary_native_network_range = "172.19.103.0/24"
  region                         = "eu-north-1"
  mgmt_eni_id                    = "eni-12345abcde6789fg"
  wan_eni_id                     = "eni-12345abcde6789fg"
  lan_eni_id                     = "eni-12345abcde6789fg"
  secondary_mgmt_eni_id          = "eni-12345abcde6789fg"
  secondary_wan_eni_id           = "eni-12345abcde6789fg6"
  secondary_lan_eni_id           = "eni-012345abcde6789fg"
  lan_local_ip                   = "172.19.102.5"
  lan_secondary_local_ip         = "172.19.103.5"
  site_name                      = "Your-Cato-site-name-here"
  site_description               = "Your Cato site desc here"
  site_location = {
    city         = "Aarau"
    country_code = "CH"
    state_code   = null
    timezone     = "Europe/Zurich"
  }
  wan_subnet_id           = "subnet-12345abcde6789fg"
  mgmt_subnet_id          = "subnet-12345abcde6789fg"
  lan_subnet_id           = "subnet-12345abcde6789fg"
  lan_secondary_subnet_id = "subnet-12345abcde6789fg"
}
```

## Site Location Reference

For more information on site_location syntax, use the [Cato CLI](https://github.com/catonetworks/cato-cli) to lookup values.

```bash
$ pip3 install catocli
$ export CATO_TOKEN="your-api-token-here"
$ export CATO_ACCOUNT_ID="your-account-id"
$ catocli query siteLocation -h
$ catocli query siteLocation '{"filters":[{"search": "San Diego","field":"city","operation":"exact"}]}' -p
```

## Authors

Module is maintained by [Cato Networks](https://github.com/catonetworks) with help from [these awesome contributors](https://github.com/catonetworks/terraform-cato-vsocket-aws-ha/graphs/contributors).

## License

Apache 2 Licensed. See [LICENSE](https://github.com/catonetworks/terraform-cato-vsocket-aws-ha/tree/master/LICENSE) for full details.
